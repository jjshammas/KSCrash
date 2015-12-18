//
//  BugsnagKSCrashReportFilterAlert.m
//
//  Created by Karl Stenerud on 2012-08-24.
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


#import "BugsnagKSCrashReportFilterAlert.h"

#import "ARCSafe_MemMgmt.h"
#import "BugsnagKSCrashCallCompletion.h"

//#define BugsnagKSLogger_LocalLevel TRACE
#import "BugsnagKSLogger.h"

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import <UIKit/UIKit.h>
#endif


@interface BugsnagKSCrashAlertViewProcess : NSObject
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
<UIAlertViewDelegate>
#endif

@property(nonatomic,readwrite,retain) NSArray* reports;
@property(nonatomic,readwrite,copy) BugsnagKSCrashReportFilterCompletion onCompletion;
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
@property(nonatomic,readwrite,retain) UIAlertView* alertView;
#endif
@property(nonatomic,readwrite,assign) NSInteger expectedButtonIndex;

+ (BugsnagKSCrashAlertViewProcess*) process;

- (void) startWithTitle:(NSString*) title
                message:(NSString*) message
              yesAnswer:(NSString*) yesAnswer
               noAnswer:(NSString*) noAnswer
                reports:(NSArray*) reports
           onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion;

@end

@implementation BugsnagKSCrashAlertViewProcess

@synthesize reports = _reports;
@synthesize onCompletion = _onCompletion;
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
@synthesize alertView = _alertView;
#endif
@synthesize expectedButtonIndex = _expectedButtonIndex;

+ (BugsnagKSCrashAlertViewProcess*) process
{
    return as_autorelease([[self alloc] init]);
}

- (void) dealloc
{
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    as_release(_alertView);
#endif
    as_release(_reports);
    as_release(_onCompletion);
    as_superdealloc();
}

- (void) startWithTitle:(NSString*) title
                message:(NSString*) message
              yesAnswer:(NSString*) yesAnswer
               noAnswer:(NSString*) noAnswer
                reports:(NSArray*) reports
           onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    BugsnagKSLOG_TRACE(@"Starting alert view process");
    self.reports = reports;
    self.onCompletion = onCompletion;
    self.expectedButtonIndex = noAnswer == nil ? 0 : 1;

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    self.alertView = as_autorelease([[UIAlertView alloc] init]);
    self.alertView.title = title;
    self.alertView.message = message;
    if(noAnswer != nil)
    {
        [self.alertView addButtonWithTitle:noAnswer];
    }
    [self.alertView addButtonWithTitle:yesAnswer];
    self.alertView.delegate = self;
    
    BugsnagKSLOG_TRACE(@"Showing alert view");
    [self.alertView show];
#else
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:yesAnswer];
    if(noAnswer != nil)
    {
        [alert addButtonWithTitle:noAnswer];
    }
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSInformationalAlertStyle];
    BOOL success = NO;
    if([alert runModal] == NSAlertFirstButtonReturn)
    {
        success = noAnswer != nil;
    }
    kscrash_i_callCompletion(self.onCompletion, self.reports, success, nil);
#endif
}

- (void) alertView:(__unused id) alertView clickedButtonAtIndex:(NSInteger) buttonIndex
{
    BOOL success = buttonIndex == self.expectedButtonIndex;
    kscrash_i_callCompletion(self.onCompletion, self.reports, success, nil);
}

@end


@interface BugsnagKSCrashReportFilterAlert ()

@property(nonatomic, readwrite, retain) NSString* title;
@property(nonatomic, readwrite, retain) NSString* message;
@property(nonatomic, readwrite, retain) NSString* yesAnswer;
@property(nonatomic, readwrite, retain) NSString* noAnswer;

@end

@implementation BugsnagKSCrashReportFilterAlert

@synthesize title = _title;
@synthesize message = _message;
@synthesize yesAnswer = _yesAnswer;
@synthesize noAnswer = _noAnswer;

+ (BugsnagKSCrashReportFilterAlert*) filterWithTitle:(NSString*) title
                                      message:(NSString*) message
                                    yesAnswer:(NSString*) yesAnswer
                                     noAnswer:(NSString*) noAnswer
{
    return as_autorelease([[self alloc] initWithTitle:title
                                              message:message
                                            yesAnswer:yesAnswer
                                             noAnswer:noAnswer]);
}

- (id) initWithTitle:(NSString*) title
             message:(NSString*) message
           yesAnswer:(NSString*) yesAnswer
            noAnswer:(NSString*) noAnswer
{
    if((self = [super init]))
    {
        self.title = title;
        self.message = message;
        self.yesAnswer = yesAnswer;
        self.noAnswer = noAnswer;
    }
    return self;
}

- (void) dealloc
{
    as_release(_title);
    as_release(_message);
    as_release(_yesAnswer);
    as_release(_noAnswer);
    as_superdealloc();
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       BugsnagKSLOG_TRACE(@"Launching new alert view process");
                       __block BugsnagKSCrashAlertViewProcess* process = [[BugsnagKSCrashAlertViewProcess alloc] init];
                       [process startWithTitle:self.title
                                       message:self.message
                                     yesAnswer:self.yesAnswer
                                      noAnswer:self.noAnswer
                                       reports:reports
                                  onCompletion:^(NSArray* filteredReports,
                                                 BOOL completed,
                                                 NSError* error)
                        {
                            BugsnagKSLOG_TRACE(@"alert process complete");
                            kscrash_i_callCompletion(onCompletion, filteredReports, completed, error);
                            dispatch_async(dispatch_get_main_queue(), ^
                                           {
                                               as_release(process);
                                               process = nil;
                                           });
                        }];
                   });
}

@end
