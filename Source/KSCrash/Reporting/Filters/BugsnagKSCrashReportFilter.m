//
//  BugsnagKSCrashReportFilter.m
//
//  Created by Karl Stenerud on 2012-05-10.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import "BugsnagKSCrashReportFilter.h"
#import "ARCSafe_MemMgmt.h"
#import "Container+DeepSearch.h"
#import "BugsnagKSCrashCallCompletion.h"
#import "BugsnagKSVarArgs.h"
#import "NSError+SimpleConstructor.h"

//#define BugsnagKSLogger_LocalLevel TRACE
#import "BugsnagKSLogger.h"


@implementation BugsnagKSCrashReportFilterPassthrough

+ (BugsnagKSCrashReportFilterPassthrough*) filter
{
    return as_autorelease([[self alloc] init]);
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    kscrash_i_callCompletion(onCompletion, reports, YES, nil);
}

@end


@interface BugsnagKSCrashReportFilterCombine ()

@property(nonatomic,readwrite,retain) NSArray* filters;
@property(nonatomic,readwrite,retain) NSArray* keys;

- (id) initWithFilters:(NSArray*) filters keys:(NSArray*) keys;

@end


@implementation BugsnagKSCrashReportFilterCombine

@synthesize filters = _filters;
@synthesize keys = _keys;

- (id) initWithFilters:(NSArray*) filters keys:(NSArray*) keys
{
    if((self = [super init]))
    {
        self.filters = filters;
        self.keys = keys;
    }
    return self;
}

+ (BugsnagKSVA_Block) argBlockWithFilters:(NSMutableArray*) filters andKeys:(NSMutableArray*) keys
{
    __block BOOL isKey = FALSE;
    BugsnagKSVA_Block block = ^(id entry)
    {
        if(isKey)
        {
            if(entry == nil)
            {
                BugsnagKSLOG_ERROR(@"key entry was nil");
            }
            else
            {
                [keys addObject:entry];
            }
        }
        else
        {
            if([entry isKindOfClass:[NSArray class]])
            {
                entry = [BugsnagKSCrashReportFilterPipeline filterWithFilters:entry, nil];
            }
            if(![entry conformsToProtocol:@protocol(BugsnagKSCrashReportFilter)])
            {
                BugsnagKSLOG_ERROR(@"Not a filter: %@", entry);
                // Cause next key entry to fail as well.
                return;
            }
            else
            {
                [filters addObject:entry];
            }
        }
        isKey = !isKey;
    };
    return as_autorelease([block copy]);
}

+ (BugsnagKSCrashReportFilterCombine*) filterWithFiltersAndKeys:(id) firstFilter, ...
{
    NSMutableArray* filters = [NSMutableArray array];
    NSMutableArray* keys = [NSMutableArray array];
    ksva_iterate_list(firstFilter, [self argBlockWithFilters:filters andKeys:keys]);
    return as_autorelease([[self alloc] initWithFilters:filters keys:keys]);
}

- (id) initWithFiltersAndKeys:(id) firstFilter, ...
{
    NSMutableArray* filters = [NSMutableArray array];
    NSMutableArray* keys = [NSMutableArray array];
    ksva_iterate_list(firstFilter, [[self class] argBlockWithFilters:filters andKeys:keys]);
    return [self initWithFilters:filters keys:keys];
}

- (void) dealloc
{
    as_release(_filters);
    as_release(_keys);
    as_superdealloc();
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    NSArray* filters = self.filters;
    NSArray* keys = self.keys;
    NSUInteger filterCount = [filters count];

    if(filterCount == 0)
    {
        kscrash_i_callCompletion(onCompletion, reports, YES, nil);
        return;
    }
    
    if(filterCount != [keys count])
    {
        kscrash_i_callCompletion(onCompletion, reports, NO,
                                 [NSError errorWithDomain:[[self class] description]
                                                     code:0
                                              description:@"Key/filter mismatch (%d keys, %d filters",
                                  [keys count], filterCount]);
        return;
    }

    NSMutableArray* reportSets = [NSMutableArray arrayWithCapacity:filterCount];

    __block NSUInteger iFilter = 0;
    __block BugsnagKSCrashReportFilterCompletion filterCompletion = nil;
    __block as_weak BugsnagKSCrashReportFilterCompletion weakFilterCompletion = nil;
    dispatch_block_t disposeOfCompletion = as_autorelease([^
    {
        // Release self-reference on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           as_release(filterCompletion);
                           filterCompletion = nil;
                       });
    } copy]);
    filterCompletion = [^(NSArray* filteredReports,
                          BOOL completed,
                          NSError* filterError)
                        {
                            if(!completed || filteredReports == nil)
                            {
                                if(!completed)
                                {
                                    kscrash_i_callCompletion(onCompletion,
                                                   filteredReports,
                                                   completed,
                                                   filterError);
                                }
                                else if(filteredReports == nil)
                                {
                                    kscrash_i_callCompletion(onCompletion, filteredReports, NO,
                                                             [NSError errorWithDomain:[[self class] description]
                                                                                 code:0
                                                                          description:@"filteredReports was nil"]);
                                }
                                disposeOfCompletion();
                                return;
                            }

                            // Normal run until all filters exhausted.
                            [reportSets addObject:filteredReports];
                            if(++iFilter < filterCount)
                            {
                                id<BugsnagKSCrashReportFilter> filter = [filters objectAtIndex:iFilter];
                                [filter filterReports:reports onCompletion:weakFilterCompletion];
                                return;
                            }

                            // All filters complete, or a filter failed.
                            // Build final "filteredReports" array.
                            NSUInteger reportCount = [(NSArray*)[reportSets objectAtIndex:0] count];
                            NSMutableArray* combinedReports = [NSMutableArray arrayWithCapacity:reportCount];
                            for(NSUInteger iReport = 0; iReport < reportCount; iReport++)
                            {
                                NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:filterCount];
                                for(NSUInteger iSet = 0; iSet < filterCount; iSet++)
                                {
                                    NSArray* reportSet = [reportSets objectAtIndex:iSet];
                                    NSDictionary* report = [reportSet objectAtIndex:iReport];
                                    [dict setObject:report
                                             forKey:[keys objectAtIndex:iSet]];
                                }
                                [combinedReports addObject:dict];
                            }

                            kscrash_i_callCompletion(onCompletion, combinedReports, completed, filterError);
                            disposeOfCompletion();
                        } copy];
    weakFilterCompletion = filterCompletion;

    // Initial call with first filter to start everything going.
    id<BugsnagKSCrashReportFilter> filter = [filters objectAtIndex:iFilter];
    [filter filterReports:reports onCompletion:filterCompletion];
}


@end


@interface BugsnagKSCrashReportFilterPipeline ()

@property(nonatomic,readwrite,retain) NSArray* filters;

@end


@implementation BugsnagKSCrashReportFilterPipeline

@synthesize filters = _filters;

+ (BugsnagKSCrashReportFilterPipeline*) filterWithFilters:(id) firstFilter, ...
{
    ksva_list_to_nsarray(firstFilter, filters);
    return as_autorelease([[self alloc] initWithFiltersArray:filters]);
}

- (id) initWithFilters:(id) firstFilter, ...
{
    ksva_list_to_nsarray(firstFilter, filters);
    return [self initWithFiltersArray:filters];
}

- (id) initWithFiltersArray:(NSArray*) filters
{
    if((self = [super init]))
    {
        NSMutableArray* expandedFilters = [NSMutableArray array];
        for(id<BugsnagKSCrashReportFilter> filter in filters)
        {
            if([filter isKindOfClass:[NSArray class]])
            {
                [expandedFilters addObjectsFromArray:(NSArray*)filter];
            }
            else
            {
                [expandedFilters addObject:filter];
            }
        }
        self.filters = expandedFilters;
    }
    return self;
}

- (void) dealloc
{
    as_release(_filters);
    as_superdealloc();
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    NSArray* filters = self.filters;
    NSUInteger filterCount = [filters count];

    if(filterCount == 0)
    {
        kscrash_i_callCompletion(onCompletion, reports, YES,  nil);
        return;
    }

    __block NSUInteger iFilter = 0;
    __block BugsnagKSCrashReportFilterCompletion filterCompletion;
    __block as_weak BugsnagKSCrashReportFilterCompletion weakFilterCompletion = nil;
    dispatch_block_t disposeOfCompletion = as_autorelease([^
    {
        // Release self-reference on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           as_release(filterCompletion);
                           filterCompletion = nil;
                       });
    } copy]);
    filterCompletion = [^(NSArray* filteredReports,
                          BOOL completed,
                          NSError* filterError)
                        {
                            if(!completed || filteredReports == nil)
                            {
                                if(!completed)
                                {
                                    kscrash_i_callCompletion(onCompletion,
                                                   filteredReports,
                                                   completed,
                                                   filterError);
                                }
                                else if(filteredReports == nil)
                                {
                                    kscrash_i_callCompletion(onCompletion, filteredReports, NO,
                                                             [NSError errorWithDomain:[[self class] description]
                                                                                 code:0
                                                                          description:@"filteredReports was nil"]);
                                }
                                disposeOfCompletion();
                                return;
                            }

                            // Normal run until all filters exhausted or one
                            // filter fails to complete.
                            if(++iFilter < filterCount)
                            {
                                id<BugsnagKSCrashReportFilter> filter = [filters objectAtIndex:iFilter];
                                [filter filterReports:filteredReports onCompletion:weakFilterCompletion];
                                return;
                            }

                            // All filters complete, or a filter failed.
                            kscrash_i_callCompletion(onCompletion, filteredReports, completed, filterError);
                            disposeOfCompletion();
                        } copy];
    weakFilterCompletion = filterCompletion;

    // Initial call with first filter to start everything going.
    id<BugsnagKSCrashReportFilter> filter = [filters objectAtIndex:iFilter];
    [filter filterReports:reports onCompletion:filterCompletion];
}

@end


@interface BugsnagKSCrashReportFilterObjectForKey ()

@property(nonatomic, readwrite, retain) id key;
@property(nonatomic, readwrite, assign) BOOL allowNotFound;

@end

@implementation BugsnagKSCrashReportFilterObjectForKey

@synthesize key = _key;
@synthesize allowNotFound = _allowNotFound;

+ (BugsnagKSCrashReportFilterObjectForKey*) filterWithKey:(id)key
                                     allowNotFound:(BOOL) allowNotFound
{
    return as_autorelease([[self alloc] initWithKey:key
                                      allowNotFound:allowNotFound]);
}

- (id) initWithKey:(id)key
     allowNotFound:(BOOL) allowNotFound
{
    if((self = [super init]))
    {
        self.key = as_retain(key);
        self.allowNotFound = allowNotFound;
    }
    return self;
}

- (void) dealloc
{
    as_release(_key);
    as_superdealloc();
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    NSMutableArray* filteredReports = [NSMutableArray arrayWithCapacity:[reports count]];
    for(NSDictionary* report in reports)
    {
        id object = nil;
        if([self.key isKindOfClass:[NSString class]])
        {
            object = [report objectForKeyPath:self.key];
        }
        else
        {
            object = [report objectForKey:self.key];
        }
        if(object == nil)
        {
            if(!self.allowNotFound)
            {
                kscrash_i_callCompletion(onCompletion, filteredReports, NO,
                                         [NSError errorWithDomain:[[self class] description]
                                                             code:0
                                                      description:@"Key not found: %@", self.key]);
                return;
            }
            [filteredReports addObject:[NSDictionary dictionary]];
        }
        else
        {
            [filteredReports addObject:object];
        }
    }
    kscrash_i_callCompletion(onCompletion, filteredReports, YES, nil);
}

@end


@interface BugsnagKSCrashReportFilterConcatenate ()

@property(nonatomic, readwrite, retain) NSString* separatorFmt;
@property(nonatomic, readwrite, retain) NSArray* keys;

@end

@implementation BugsnagKSCrashReportFilterConcatenate

@synthesize separatorFmt = _separatorFmt;
@synthesize keys = _keys;

+ (BugsnagKSCrashReportFilterConcatenate*) filterWithSeparatorFmt:(NSString*) separatorFmt keys:(id) firstKey, ...
{
    ksva_list_to_nsarray(firstKey, keys);
    return as_autorelease([[self alloc] initWithSeparatorFmt:separatorFmt keysArray:keys]);
}

- (id) initWithSeparatorFmt:(NSString*) separatorFmt keys:(id) firstKey, ...
{
    ksva_list_to_nsarray(firstKey, keys);
    return [self initWithSeparatorFmt:separatorFmt keysArray:keys];
}

- (id) initWithSeparatorFmt:(NSString*) separatorFmt keysArray:(NSArray*) keys
{
    if((self = [super init]))
    {
        NSMutableArray* realKeys = [NSMutableArray array];
        for(id key in keys)
        {
            if([key isKindOfClass:[NSArray class]])
            {
                [realKeys addObjectsFromArray:(NSArray*)key];
            }
            else
            {
                [realKeys addObject:key];
            }
        }

        self.separatorFmt = separatorFmt;
        self.keys = realKeys;
    }
    return self;
}

- (void) dealloc
{
    as_release(_separatorFmt);
    as_release(_keys);
    as_superdealloc();
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    NSMutableArray* filteredReports = [NSMutableArray arrayWithCapacity:[reports count]];
    for(NSDictionary* report in reports)
    {
        BOOL firstEntry = YES;
        NSMutableString* concatenated = [NSMutableString string];
        for(NSString* key in self.keys)
        {
            if(firstEntry)
            {
                firstEntry = NO;
            }
            else
            {
                [concatenated appendFormat:self.separatorFmt, key];
            }
            id object = [report objectForKeyPath:key];
            [concatenated appendFormat:@"%@", object];
        }
        [filteredReports addObject:concatenated];
    }
    kscrash_i_callCompletion(onCompletion, filteredReports, YES, nil);
}

@end


@interface BugsnagKSCrashReportFilterSubset ()

@property(nonatomic, readwrite, retain) NSArray* keyPaths;

@end

@implementation BugsnagKSCrashReportFilterSubset

@synthesize keyPaths = _keyPaths;

+ (BugsnagKSCrashReportFilterSubset*) filterWithKeys:(id) firstKeyPath, ...
{
    ksva_list_to_nsarray(firstKeyPath, keyPaths);
    return as_autorelease([[self alloc] initWithKeysArray:keyPaths]);
}

- (id) initWithKeys:(id) firstKeyPath, ...
{
    ksva_list_to_nsarray(firstKeyPath, keyPaths);
    return [self initWithKeysArray:keyPaths];
}

- (id) initWithKeysArray:(NSArray*) keyPaths
{
    if((self = [super init]))
    {
        NSMutableArray* realKeyPaths = [NSMutableArray array];
        for(id keyPath in keyPaths)
        {
            if([keyPath isKindOfClass:[NSArray class]])
            {
                [realKeyPaths addObjectsFromArray:(NSArray*)keyPath];
            }
            else
            {
                [realKeyPaths addObject:keyPath];
            }
        }
        
        self.keyPaths = realKeyPaths;
    }
    return self;
}

- (void) dealloc
{
    as_release(_keyPaths);
    as_superdealloc();
}


- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    NSMutableArray* filteredReports = [NSMutableArray arrayWithCapacity:[reports count]];
    for(NSDictionary* report in reports)
    {
        NSMutableDictionary* subset = [NSMutableDictionary dictionary];
        for(NSString* keyPath in self.keyPaths)
        {
            id object = [report objectForKeyPath:keyPath];
            if(object == nil)
            {
                kscrash_i_callCompletion(onCompletion, filteredReports, NO,
                                         [NSError errorWithDomain:[[self class] description]
                                                             code:0
                                                      description:@"Report did not have key path %@", keyPath]);
                return;
            }
            [subset setObject:object forKey:[keyPath lastPathComponent]];
        }
        [filteredReports addObject:subset];
    }
    kscrash_i_callCompletion(onCompletion, filteredReports, YES, nil);
}

@end
