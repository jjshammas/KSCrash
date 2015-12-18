//
//  BugsnagKSLogger.h
//
//  Created by Karl Stenerud on 11-06-25.
//
//  Copyright (c) 2011 Karl Stenerud. All rights reserved.
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


/**
 * BugsnagKSLogger
 * ========
 *
 * Prints log entries to the console consisting of:
 * - Level (Error, Warn, Info, Debug, Trace)
 * - File
 * - Line
 * - Function
 * - Message
 *
 * Allows setting the minimum logging level in the preprocessor.
 *
 * Works in C or Objective-C contexts, with or without ARC, using CLANG or GCC.
 *
 *
 * =====
 * USAGE
 * =====
 *
 * Set the log level in your "Preprocessor Macros" build setting. You may choose
 * TRACE, DEBUG, INFO, WARN, ERROR. If nothing is set, it defaults to INFO.
 *
 * Example: BugsnagKSLogger_Level=WARN
 *
 * Anything below the level specified for BugsnagKSLogger_Level will not be compiled
 * or printed.
 * 
 *
 * Next, include the header file:
 *
 * #include "BugsnagKSLogger.h"
 *
 *
 * Next, call the logger functions from your code (using objective-c strings
 * in objective-C files and regular strings in regular C files):
 *
 * Code:
 *    BugsnagKSLOG_ERROR(@"Some error message");
 *
 * Prints:
 *    2011-07-16 05:41:01.379 TestApp[4439:f803] ERROR: SomeClass.m (21): -[SomeFunction]: Some error message 
 *
 * Code:
 *    BugsnagKSLOG_INFO(@"Info about %@", someObject);
 *
 * Prints:
 *    2011-07-16 05:44:05.239 TestApp[4473:f803] INFO : SomeClass.m (20): -[SomeFunction]: Info about <NSObject: 0xb622840>
 *
 *
 * The "BASIC" versions of the macros behave exactly like NSLog() or printf(),
 * except they respect the BugsnagKSLogger_Level setting:
 *
 * Code:
 *    BugsnagKSLOGBASIC_ERROR(@"A basic log entry");
 *
 * Prints:
 *    2011-07-16 05:44:05.916 TestApp[4473:f803] A basic log entry
 *
 *
 * NOTE: In C files, use "" instead of @"" in the format field. Logging calls
 *       in C files do not print the NSLog preamble:
 *
 * Objective-C version:
 *    BugsnagKSLOG_ERROR(@"Some error message");
 *
 *    2011-07-16 05:41:01.379 TestApp[4439:f803] ERROR: SomeClass.m (21): -[SomeFunction]: Some error message
 *
 * C version:
 *    BugsnagKSLOG_ERROR("Some error message");
 *
 *    ERROR: SomeClass.c (21): SomeFunction(): Some error message
 *
 *
 * =============
 * LOCAL LOGGING
 * =============
 *
 * You can control logging messages at the local file level using the
 * "BugsnagKSLogger_LocalLevel" define. Note that it must be defined BEFORE
 * including BugsnagKSLogger.h
 *
 * The BugsnagKSLOG_XX() and BugsnagKSLOGBASIC_XX() macros will print out based on the LOWER
 * of BugsnagKSLogger_Level and BugsnagKSLogger_LocalLevel, so if BugsnagKSLogger_Level is DEBUG
 * and BugsnagKSLogger_LocalLevel is TRACE, it will print all the way down to the trace
 * level for the local file where BugsnagKSLogger_LocalLevel was defined, and to the
 * debug level everywhere else.
 *
 * Example:
 *
 * // BugsnagKSLogger_LocalLevel, if defined, MUST come BEFORE including BugsnagKSLogger.h
 * #define BugsnagKSLogger_LocalLevel TRACE
 * #import "BugsnagKSLogger.h"
 *
 *
 * ===============
 * IMPORTANT NOTES
 * ===============
 *
 * The C logger changes its behavior depending on the value of the preprocessor
 * define BugsnagKSLogger_CBufferSize.
 *
 * If BugsnagKSLogger_CBufferSize is > 0, the C logger will behave in an async-safe
 * manner, calling write() instead of printf(). Any log messages that exceed the
 * length specified by BugsnagKSLogger_CBufferSize will be truncated.
 *
 * If BugsnagKSLogger_CBufferSize == 0, the C logger will use printf(), and there will
 * be no limit on the log message length.
 *
 * BugsnagKSLogger_CBufferSize can only be set as a preprocessor define, and will
 * default to 1024 if not specified during compilation.
 */


// ============================================================================
#pragma mark - (internal) -
// ============================================================================


#ifndef HDR_KSLogger_h
#define HDR_KSLogger_h

#ifdef __cplusplus
extern "C" {
#endif


#include <stdbool.h>


#ifdef __OBJC__

void i_kslog_logObjC(const char* level,
                     const char* file,
                     int line,
                     const char* function,
                     NSString* fmt, ...);

void i_kslog_logObjCBasic(NSString* fmt, ...);

#define i_KSLOG_FULL i_kslog_logObjC
#define i_KSLOG_BASIC i_kslog_logObjCBasic

#else // __OBJC__

void i_kslog_logC(const char* level,
                  const char* file,
                  int line,
                  const char* function,
                  const char* fmt, ...);

void i_kslog_logCBasic(const char* fmt, ...);

#define i_KSLOG_FULL i_kslog_logC
#define i_KSLOG_BASIC i_kslog_logCBasic

#endif // __OBJC__


/* Back up any existing defines by the same name */
#ifdef NONE
    #define BugsnagKSLOG_BAK_NONE NONE
    #undef NONE
#endif
#ifdef ERROR
    #define BugsnagKSLOG_BAK_ERROR ERROR
    #undef ERROR
#endif
#ifdef WARN
    #define BugsnagKSLOG_BAK_WARN WARN
    #undef WARN
#endif
#ifdef INFO
    #define BugsnagKSLOG_BAK_INFO INFO
    #undef INFO
#endif
#ifdef DEBUG
    #define BugsnagKSLOG_BAK_DEBUG DEBUG
    #undef DEBUG
#endif
#ifdef TRACE
    #define BugsnagKSLOG_BAK_TRACE TRACE
    #undef TRACE
#endif


#define BugsnagKSLogger_Level_None   0
#define BugsnagKSLogger_Level_Error 10
#define BugsnagKSLogger_Level_Warn  20
#define BugsnagKSLogger_Level_Info  30
#define BugsnagKSLogger_Level_Debug 40
#define BugsnagKSLogger_Level_Trace 50

#define NONE  BugsnagKSLogger_Level_None
#define ERROR BugsnagKSLogger_Level_Error
#define WARN  BugsnagKSLogger_Level_Warn
#define INFO  BugsnagKSLogger_Level_Info
#define DEBUG BugsnagKSLogger_Level_Debug
#define TRACE BugsnagKSLogger_Level_Trace


#ifndef BugsnagKSLogger_Level
    #define BugsnagKSLogger_Level BugsnagKSLogger_Level_Info
#endif

#ifndef BugsnagKSLogger_LocalLevel
    #define BugsnagKSLogger_LocalLevel BugsnagKSLogger_Level_None
#endif

#define a_KSLOG_FULL(LEVEL, FMT, ...) \
    i_KSLOG_FULL(LEVEL, \
                 __FILE__, \
                 __LINE__, \
                 __PRETTY_FUNCTION__, \
                 FMT, \
                 ##__VA_ARGS__)



// ============================================================================
#pragma mark - API -
// ============================================================================

/** Set the filename to log to.
 *
 * @param filename The file to write to (NULL = write to stdout).
 *
 * @param overwrite If true, overwrite the log file.
 */
bool kslog_setLogFilename(const char* filename, bool overwrite);

/** Tests if the logger would print at the specified level.
 *
 * @param LEVEL The level to test for. One of:
 *            BugsnagKSLogger_Level_Error,
 *            BugsnagKSLogger_Level_Warn,
 *            BugsnagKSLogger_Level_Info,
 *            BugsnagKSLogger_Level_Debug,
 *            BugsnagKSLogger_Level_Trace,
 *
 * @return TRUE if the logger would print at the specified level.
 */
#define BugsnagKSLOG_PRINTS_AT_LEVEL(LEVEL) \
    (BugsnagKSLogger_Level >= LEVEL || BugsnagKSLogger_LocalLevel >= LEVEL)

/** Log a message regardless of the log settings.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#define BugsnagKSLOG_ALWAYS(FMT, ...) a_KSLOG_FULL("FORCE", FMT, ##__VA_ARGS__)
#define BugsnagKSLOGBASIC_ALWAYS(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)


/** Log an error.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if BugsnagKSLOG_PRINTS_AT_LEVEL(BugsnagKSLogger_Level_Error)
    #define BugsnagKSLOG_ERROR(FMT, ...) a_KSLOG_FULL("ERROR", FMT, ##__VA_ARGS__)
    #define BugsnagKSLOGBASIC_ERROR(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define BugsnagKSLOG_ERROR(FMT, ...)
    #define BugsnagKSLOGBASIC_ERROR(FMT, ...)
#endif

/** Log a warning.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if BugsnagKSLOG_PRINTS_AT_LEVEL(BugsnagKSLogger_Level_Warn)
    #define BugsnagKSLOG_WARN(FMT, ...)  a_KSLOG_FULL("WARN ", FMT, ##__VA_ARGS__)
    #define BugsnagKSLOGBASIC_WARN(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define BugsnagKSLOG_WARN(FMT, ...)
    #define BugsnagKSLOGBASIC_WARN(FMT, ...)
#endif

/** Log an info message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if BugsnagKSLOG_PRINTS_AT_LEVEL(BugsnagKSLogger_Level_Info)
    #define BugsnagKSLOG_INFO(FMT, ...)  a_KSLOG_FULL("INFO ", FMT, ##__VA_ARGS__)
    #define BugsnagKSLOGBASIC_INFO(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define BugsnagKSLOG_INFO(FMT, ...)
    #define BugsnagKSLOGBASIC_INFO(FMT, ...)
#endif

/** Log a debug message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if BugsnagKSLOG_PRINTS_AT_LEVEL(BugsnagKSLogger_Level_Debug)
    #define BugsnagKSLOG_DEBUG(FMT, ...) a_KSLOG_FULL("DEBUG", FMT, ##__VA_ARGS__)
    #define BugsnagKSLOGBASIC_DEBUG(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define BugsnagKSLOG_DEBUG(FMT, ...)
    #define BugsnagKSLOGBASIC_DEBUG(FMT, ...)
#endif

/** Log a trace message.
 * Normal version prints out full context. Basic version prints directly.
 *
 * @param FMT The format specifier, followed by its arguments.
 */
#if BugsnagKSLOG_PRINTS_AT_LEVEL(BugsnagKSLogger_Level_Trace)
    #define BugsnagKSLOG_TRACE(FMT, ...) a_KSLOG_FULL("TRACE", FMT, ##__VA_ARGS__)
    #define BugsnagKSLOGBASIC_TRACE(FMT, ...) i_KSLOG_BASIC(FMT, ##__VA_ARGS__)
#else
    #define BugsnagKSLOG_TRACE(FMT, ...)
    #define BugsnagKSLOGBASIC_TRACE(FMT, ...)
#endif



// ============================================================================
#pragma mark - (internal) -
// ============================================================================

/* Put everything back to the way we found it. */
#undef ERROR
#ifdef BugsnagKSLOG_BAK_ERROR
    #define ERROR BugsnagKSLOG_BAK_ERROR
    #undef BugsnagKSLOG_BAK_ERROR
#endif
#undef WARNING
#ifdef BugsnagKSLOG_BAK_WARN
    #define WARNING BugsnagKSLOG_BAK_WARN
    #undef BugsnagKSLOG_BAK_WARN
#endif
#undef INFO
#ifdef BugsnagKSLOG_BAK_INFO
    #define INFO BugsnagKSLOG_BAK_INFO
    #undef BugsnagKSLOG_BAK_INFO
#endif
#undef DEBUG
#ifdef BugsnagKSLOG_BAK_DEBUG
    #define DEBUG BugsnagKSLOG_BAK_DEBUG
    #undef BugsnagKSLOG_BAK_DEBUG
#endif
#undef TRACE
#ifdef BugsnagKSLOG_BAK_TRACE
    #define TRACE BugsnagKSLOG_BAK_TRACE
    #undef BugsnagKSLOG_BAK_TRACE
#endif


#ifdef __cplusplus
}
#endif

#endif // HDR_KSLogger_h
