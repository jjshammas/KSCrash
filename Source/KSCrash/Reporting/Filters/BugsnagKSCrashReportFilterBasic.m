//
//  BugsnagKSCrashReportFilterBasic.m
//
//  Created by Karl Stenerud on 2012-05-11.
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


#import "BugsnagKSCrashReportFilterBasic.h"
#import "ARCSafe_MemMgmt.h"
#import "BugsnagKSCrashCallCompletion.h"
#import "NSError+SimpleConstructor.h"

//#define BugsnagKSLogger_LocalLevel TRACE
#import "BugsnagKSLogger.h"


@implementation BugsnagKSCrashReportFilterDataToString

+ (BugsnagKSCrashReportFilterDataToString*) filter
{
    return as_autorelease([[self alloc] init]);
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion)onCompletion
{
    NSMutableArray* filteredReports = [NSMutableArray arrayWithCapacity:[reports count]];
    for(NSData* report in reports)
    {
        NSString* converted = as_autorelease([[NSString alloc] initWithData:report
                                                                   encoding:NSUTF8StringEncoding]);
        [filteredReports addObject:converted];
    }

    kscrash_i_callCompletion(onCompletion, filteredReports, YES, nil);
}

@end


@implementation BugsnagKSCrashReportFilterStringToData

+ (BugsnagKSCrashReportFilterStringToData*) filter
{
    return as_autorelease([[self alloc] init]);
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion)onCompletion
{
    NSMutableArray* filteredReports = [NSMutableArray arrayWithCapacity:[reports count]];
    for(NSString* report in reports)
    {
        NSData* converted = [report dataUsingEncoding:NSUTF8StringEncoding];
        if(converted == nil)
        {
            kscrash_i_callCompletion(onCompletion, filteredReports, NO,
                                     [NSError errorWithDomain:[[self class] description]
                                                         code:0
                                                  description:@"Could not convert report to UTF-8"]);
            return;
        }
        else
        {
            [filteredReports addObject:converted];
        }
    }

    kscrash_i_callCompletion(onCompletion, filteredReports, YES, nil);
}

@end
