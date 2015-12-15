//
//  BugsnagKSCrashSentry_User.c
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

#include "BugsnagKSCrashSentry_User.h"
#include "BugsnagKSCrashSentry_Private.h"
#include "BugsnagKSMach.h"

//#define BugsnagKSLogger_LocalLevel TRACE
#include "BugsnagKSLogger.h"

#include <execinfo.h>
#include <stdlib.h>


/** Context to fill with crash information. */
static BugsnagKSCrash_SentryContext* g_context;


bool kscrashsentry_installUserExceptionHandler(BugsnagKSCrash_SentryContext* const context)
{
    BugsnagKSLOG_DEBUG("Installing user exception handler.");
    g_context = context;
    return true;
}

void kscrashsentry_uninstallUserExceptionHandler(void)
{
    BugsnagKSLOG_DEBUG("Uninstalling user exception handler.");
    g_context = NULL;
}

void kscrashsentry_reportUserException(const char* name,
                                       const char* reason,
                                       const char* lineOfCode,
                                       const char** stackTrace,
                                       size_t stackTraceCount,
                                       bool terminateProgram)
{
    if(g_context != NULL)
    {
        kscrashsentry_beginHandlingCrash(g_context);
        
        if(g_context->suspendThreadsForUserReported)
        {
            BugsnagKSLOG_DEBUG("Suspending all threads");
            kscrashsentry_suspendThreads();
        }

        BugsnagKSLOG_DEBUG("Fetching call stack.");
        int callstackCount = 100;
        uintptr_t callstack[callstackCount];
        callstackCount = backtrace((void**)callstack, callstackCount);
        if(callstackCount <= 0)
        {
            BugsnagKSLOG_ERROR("backtrace() returned call stack length of %d", callstackCount);
            callstackCount = 0;
        }

        BugsnagKSLOG_DEBUG("Filling out context.");
        g_context->crashType = BugsnagKSCrashTypeUserReported;
        g_context->offendingThread = ksmach_thread_self();
        g_context->registersAreValid = false;
        g_context->crashReason = reason;
        g_context->stackTrace = callstack;
        g_context->stackTraceLength = callstackCount;
        g_context->userException.name = name;
        g_context->userException.lineOfCode = lineOfCode;
        g_context->userException.customStackTrace = stackTrace;
        g_context->userException.customStackTraceLength = (int)stackTraceCount;

        BugsnagKSLOG_DEBUG("Calling main crash handler.");
        g_context->onCrash();

        if(terminateProgram)
        {
            kscrashsentry_uninstall(BugsnagKSCrashTypeAll);
            kscrashsentry_resumeThreads();
            abort();
        }
        else
        {
            kscrashsentry_clearContext(g_context);
            kscrashsentry_resumeThreads();
        }
    }
}
