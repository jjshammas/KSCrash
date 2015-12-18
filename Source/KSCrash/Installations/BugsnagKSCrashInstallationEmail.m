//
//  BugsnagKSCrashInstallationEmail.m
//
//  Created by Karl Stenerud on 2013-03-02.
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


#import "BugsnagKSCrashInstallationEmail.h"
#import "BugsnagKSCrashInstallation+Private.h"
#import "ARCSafe_MemMgmt.h"
#import "BugsnagKSCrashReportSinkEMail.h"
#import "BugsnagKSCrashReportFilterAlert.h"
#import "BugsnagKSSingleton.h"


@interface BugsnagKSCrashInstallationEmail ()

@property(nonatomic,readwrite,retain) NSDictionary* defaultFilenameFormats;

@end


@implementation BugsnagKSCrashInstallationEmail

IMPLEMENT_EXCLUSIVE_SHARED_INSTANCE(BugsnagKSCrashInstallationEmail)

@synthesize recipients = _recipients;
@synthesize subject = _subject;
@synthesize message = _message;
@synthesize filenameFmt = _filenameFmt;
@synthesize reportStyle = _reportStyle;
@synthesize defaultFilenameFormats = _defaultFilenameFormats;

- (id) init
{
    if((self = [super initWithRequiredProperties:[NSArray arrayWithObjects:
                                                  @"recipients",
                                                  @"subject",
                                                  @"filenameFmt",
                                                  nil]]))
    {
        NSString* bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        self.subject = [NSString stringWithFormat:@"Crash Report (%@)", bundleName];
        self.defaultFilenameFormats = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSString stringWithFormat:@"crash-report-%@-%%d.txt.gz", bundleName],
                                       [NSNumber numberWithInt:BugsnagKSCrashEmailReportStyleApple],
                                       [NSString stringWithFormat:@"crash-report-%@-%%d.json.gz", bundleName],
                                       [NSNumber numberWithInt:BugsnagKSCrashEmailReportStyleJSON],
                                       nil];
        [self setReportStyle:BugsnagKSCrashEmailReportStyleJSON useDefaultFilenameFormat:YES];
    }
    return self;
}

- (void) dealloc
{
    as_release(_recipients);
    as_release(_subject);
    as_release(_message);
    as_release(_filenameFmt);
    as_release(_defaultFilenameFormats);
    as_superdealloc();
}

- (void) setReportStyle:(BugsnagKSCrashEmailReportStyle)reportStyle
useDefaultFilenameFormat:(BOOL) useDefaultFilenameFormat
{
    self.reportStyle = reportStyle;

    if(useDefaultFilenameFormat)
    {
        self.filenameFmt = [self.defaultFilenameFormats objectForKey:[NSNumber numberWithInt:reportStyle]];
    }
}

- (id<BugsnagKSCrashReportFilter>) sink
{
    BugsnagKSCrashReportSinkEMail* sink = [BugsnagKSCrashReportSinkEMail sinkWithRecipients:self.recipients
                                                                      subject:self.subject
                                                                      message:self.message
                                                                  filenameFmt:self.filenameFmt];
    
    switch(self.reportStyle)
    {
        case BugsnagKSCrashEmailReportStyleApple:
            return [sink defaultCrashReportFilterSetAppleFmt];
            break;
        case BugsnagKSCrashEmailReportStyleJSON:
            return [sink defaultCrashReportFilterSet];
            break;
    }
}

@end
