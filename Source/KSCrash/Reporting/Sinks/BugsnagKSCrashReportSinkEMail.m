//
//  BugsnagKSCrashReportSinkEMail.m
//
//  Created by Karl Stenerud on 2012-05-06.
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


#import "BugsnagKSCrashReportSinkEMail.h"

#import "ARCSafe_MemMgmt.h"
#import "BugsnagKSCrashCallCompletion.h"
#import "BugsnagKSCrashReportFilterAppleFmt.h"
#import "BugsnagKSCrashReportFilterBasic.h"
#import "BugsnagKSCrashReportFilterGZip.h"
#import "BugsnagKSCrashReportFilterJSON.h"
#import "NSError+SimpleConstructor.h"

//#define BugsnagKSLogger_LocalLevel TRACE
#import "BugsnagKSLogger.h"

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import <MessageUI/MessageUI.h>


@interface BugsnagKSCrashMailProcess : NSObject <MFMailComposeViewControllerDelegate>

@property(nonatomic,readwrite,retain) NSArray* reports;
@property(nonatomic,readwrite,copy) BugsnagKSCrashReportFilterCompletion onCompletion;

@property(nonatomic,readwrite,retain) UIViewController* dummyVC;

+ (BugsnagKSCrashMailProcess*) process;

- (void) startWithController:(MFMailComposeViewController*) controller
                     reports:(NSArray*) reports
                 filenameFmt:(NSString*) filenameFmt
                onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion;

- (void) presentModalVC:(UIViewController*) vc;
- (void) dismissModalVC;

@end

@implementation BugsnagKSCrashMailProcess

@synthesize reports = _reports;
@synthesize onCompletion = _onCompletion;
@synthesize dummyVC = _dummyVC;

+ (BugsnagKSCrashMailProcess*) process
{
    return as_autorelease([[self alloc] init]);
}

- (void) dealloc
{
    as_release(_reports);
    as_release(_onCompletion);
    as_release(_dummyVC);
    as_superdealloc();
}

- (void) startWithController:(MFMailComposeViewController*) controller
                     reports:(NSArray*) reports
                 filenameFmt:(NSString*) filenameFmt
                onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    self.reports = reports;
    self.onCompletion = onCompletion;

    controller.mailComposeDelegate = self;

    int i = 1;
    for(NSData* report in reports)
    {
        if(![report isKindOfClass:[NSData class]])
        {
            BugsnagKSLOG_ERROR(@"Report was of type %@", [report class]);
        }
        else
        {
            [controller addAttachmentData:report
                                 mimeType:@"binary"
                                 fileName:[NSString stringWithFormat:filenameFmt, i++]];
        }
    }

    [self presentModalVC:controller];
}

- (void) mailComposeController:(__unused MFMailComposeViewController*) mailController
           didFinishWithResult:(MFMailComposeResult) result
                         error:(NSError*) error
{
    [self dismissModalVC];

    switch (result)
    {
        case MFMailComposeResultSent:
            kscrash_i_callCompletion(self.onCompletion, self.reports, YES, nil);
            break;
        case MFMailComposeResultSaved:
            kscrash_i_callCompletion(self.onCompletion, self.reports, YES, nil);
            break;
        case MFMailComposeResultCancelled:
            kscrash_i_callCompletion(self.onCompletion, self.reports, NO,
                                     [NSError errorWithDomain:[[self class] description]
                                                         code:0
                                                  description:@"User cancelled"]);
            break;
        case MFMailComposeResultFailed:
            kscrash_i_callCompletion(self.onCompletion, self.reports, NO, error);
            break;
        default:
        {
            kscrash_i_callCompletion(self.onCompletion, self.reports, NO,
                                     [NSError errorWithDomain:[[self class] description]
                                                         code:0
                                                  description:@"Unknown MFMailComposeResult: %d", result]);
        }
    }
}

- (void) presentModalVC:(UIViewController*) vc
{
	self.dummyVC = as_autorelease([[UIViewController alloc] initWithNibName:nil bundle:nil]);
	self.dummyVC.view = as_autorelease([[UIView alloc] init]);

    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    [window addSubview:self.dummyVC.view];

    if([self.dummyVC respondsToSelector:@selector(presentViewController:animated:completion:)])
    {
        [self.dummyVC presentViewController:vc animated:YES completion:nil];
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.dummyVC presentModalViewController:vc animated:YES];
#pragma clang diagnostic pop
    }
}

- (void) dismissModalVC
{
    if([self.dummyVC respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
    {
        [self.dummyVC dismissViewControllerAnimated:YES completion:^
         {
             [self.dummyVC.view removeFromSuperview];
             self.dummyVC = nil;
         }];
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.dummyVC dismissModalViewControllerAnimated:NO];
#pragma clang diagnostic pop
        [self.dummyVC.view removeFromSuperview];
        self.dummyVC = nil;
    }
}

@end


@interface BugsnagKSCrashReportSinkEMail ()

@property(nonatomic,readwrite,retain) NSArray* recipients;

@property(nonatomic,readwrite,retain) NSString* subject;

@property(nonatomic,readwrite,retain) NSString* message;

@property(nonatomic,readwrite,retain) NSString* filenameFmt;

@end


@implementation BugsnagKSCrashReportSinkEMail

@synthesize recipients = _recipients;
@synthesize subject = _subject;
@synthesize message = _message;
@synthesize filenameFmt = _filenameFmt;

+ (BugsnagKSCrashReportSinkEMail*) sinkWithRecipients:(NSArray*) recipients
                                       subject:(NSString*) subject
                                       message:(NSString*) message
                                   filenameFmt:(NSString*) filenameFmt
{
    return as_autorelease([[self alloc] initWithRecipients:recipients
                                                   subject:subject
                                                   message:message
                                               filenameFmt:filenameFmt]);
}

- (id) initWithRecipients:(NSArray*) recipients
                  subject:(NSString*) subject
                  message:(NSString*) message
              filenameFmt:(NSString*) filenameFmt
{
    if((self = [super init]))
    {
        self.recipients = recipients;
        self.subject = subject;
        self.message = message;
        self.filenameFmt = filenameFmt;
    }
    return self;
}

- (void) dealloc
{
    as_release(_recipients);
    as_release(_subject);
    as_release(_message);
    as_release(_filenameFmt);
    as_superdealloc();
}

- (id <BugsnagKSCrashReportFilter>) defaultCrashReportFilterSet
{
    return [BugsnagKSCrashReportFilterPipeline filterWithFilters:
            [BugsnagKSCrashReportFilterJSONEncode filterWithOptions:BugsnagKSJSONEncodeOptionSorted | BugsnagKSJSONEncodeOptionPretty],
            [BugsnagKSCrashReportFilterGZipCompress filterWithCompressionLevel:-1],
            self,
            nil];
}

- (id <BugsnagKSCrashReportFilter>) defaultCrashReportFilterSetAppleFmt
{
    return [BugsnagKSCrashReportFilterPipeline filterWithFilters:
            [BugsnagKSCrashReportFilterAppleFmt filterWithReportStyle:BugsnagKSAppleReportStyleSymbolicatedSideBySide],
            [BugsnagKSCrashReportFilterStringToData filter],
            [BugsnagKSCrashReportFilterGZipCompress filterWithCompressionLevel:-1],
            self,
            nil];
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    if(![MFMailComposeViewController canSendMail])
    {
        [as_autorelease([[UIAlertView alloc] initWithTitle:@"Email Error"
                                                   message:@"This device is not configured to send email."
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil]) show];

        kscrash_i_callCompletion(onCompletion, reports, NO,
                                 [NSError errorWithDomain:[[self class] description]
                                                     code:0
                                              description:@"E-Mail not enabled on device"]);
        return;
    }

    MFMailComposeViewController* mailController = as_autorelease([[MFMailComposeViewController alloc] init]);
    [mailController setToRecipients:self.recipients];
    [mailController setSubject:self.subject];
    if(self.message != nil)
    {
        [mailController setMessageBody:self.message isHTML:NO];
    }
    NSString* filenameFmt = self.filenameFmt;

    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       __block BugsnagKSCrashMailProcess* process = [[BugsnagKSCrashMailProcess alloc] init];
                       [process startWithController:mailController
                                            reports:reports
                                        filenameFmt:filenameFmt
                                       onCompletion:^(NSArray* filteredReports,
                                                      BOOL completed,
                                                      NSError* error)
                        {
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

#else

#import "NSData+GZip.h"

@implementation BugsnagKSCrashReportSinkEMail

+ (BugsnagKSCrashReportSinkEMail*) sinkWithRecipients:(NSArray*) recipients
                                       subject:(NSString*) subject
                                       message:(NSString*) message
                                   filenameFmt:(NSString*) filenameFmt
{
    return as_autorelease([[self alloc] initWithRecipients:recipients
                                                   subject:subject
                                                   message:message
                                               filenameFmt:filenameFmt]);
}

- (id) initWithRecipients:(__unused NSArray*) recipients
                  subject:(__unused NSString*) subject
                  message:(__unused NSString*) message
              filenameFmt:(__unused NSString*) filenameFmt
{
    return [super init];
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(BugsnagKSCrashReportFilterCompletion) onCompletion
{
    for(NSData* reportData in reports)
    {
        NSString* report = [[NSString alloc] initWithData:[reportData gunzippedWithError:nil] encoding:NSUTF8StringEncoding];
        NSLog(@"Report\n%@", report);
    }
    kscrash_i_callCompletion(onCompletion, reports, NO,
                             [NSError errorWithDomain:[[self class] description]
                                                 code:0
                                          description:@"Cannot send mail on Mac OS X"]);
}

- (id <BugsnagKSCrashReportFilter>) defaultCrashReportFilterSet
{
    return [BugsnagKSCrashReportFilterPipeline filterWithFilters:
            [BugsnagKSCrashReportFilterJSONEncode filterWithOptions:BugsnagKSJSONEncodeOptionSorted | BugsnagKSJSONEncodeOptionPretty],
            [BugsnagKSCrashReportFilterGZipCompress filterWithCompressionLevel:-1],
            self,
            nil];
}

- (id <BugsnagKSCrashReportFilter>) defaultCrashReportFilterSetAppleFmt
{
    return [BugsnagKSCrashReportFilterPipeline filterWithFilters:
            [BugsnagKSCrashReportFilterAppleFmt filterWithReportStyle:BugsnagKSAppleReportStyleSymbolicatedSideBySide],
            [BugsnagKSCrashReportFilterStringToData filter],
            [BugsnagKSCrashReportFilterGZipCompress filterWithCompressionLevel:-1],
            self,
            nil];
}

@end

#endif
