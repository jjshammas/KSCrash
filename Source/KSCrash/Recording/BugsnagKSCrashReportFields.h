//
//  BugsnagKSCrashReportFields.h
//
//  Created by Karl Stenerud on 2012-10-07.
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


#ifndef HDR_BugsnagKSCrashReportFields_h
#define HDR_BugsnagKSCrashReportFields_h


#pragma mark - Report Types -

#define BugsnagKSCrashReportType_Minimal          "minimal"
#define BugsnagKSCrashReportType_Standard         "standard"


#pragma mark - Memory Types -

#define BugsnagKSCrashMemType_Block               "objc_block"
#define BugsnagKSCrashMemType_Class               "objc_class"
#define BugsnagKSCrashMemType_NullPointer         "null_pointer"
#define BugsnagKSCrashMemType_Object              "objc_object"
#define BugsnagKSCrashMemType_String              "string"
#define BugsnagKSCrashMemType_Unknown             "unknown"


#pragma mark - Exception Types -

#define BugsnagKSCrashExcType_CPPException        "cpp_exception"
#define BugsnagKSCrashExcType_Deadlock            "deadlock"
#define BugsnagKSCrashExcType_Mach                "mach"
#define BugsnagKSCrashExcType_NSException         "nsexception"
#define BugsnagKSCrashExcType_Signal              "signal"
#define BugsnagKSCrashExcType_User                "user"


#pragma mark - Common -

#define BugsnagKSCrashField_Address               "address"
#define BugsnagKSCrashField_Contents              "contents"
#define BugsnagKSCrashField_Exception             "exception"
#define BugsnagKSCrashField_FirstObject           "first_object"
#define BugsnagKSCrashField_Index                 "index"
#define BugsnagKSCrashField_Ivars                 "ivars"
#define BugsnagKSCrashField_Name                  "name"
#define BugsnagKSCrashField_ReferencedObject      "referenced_object"
#define BugsnagKSCrashField_Type                  "type"
#define BugsnagKSCrashField_UUID                  "uuid"
#define BugsnagKSCrashField_Value                 "value"

#define BugsnagKSCrashField_Error                 "error"
#define BugsnagKSCrashField_JSONData              "json_data"


#pragma mark - Notable Address -

#define BugsnagKSCrashField_Class                 "class"
#define BugsnagKSCrashField_LastDeallocObject     "last_deallocated_obj"


#pragma mark - Backtrace -

#define BugsnagKSCrashField_InstructionAddr       "instruction_addr"
#define BugsnagKSCrashField_LineOfCode            "line_of_code"
#define BugsnagKSCrashField_ObjectAddr            "object_addr"
#define BugsnagKSCrashField_ObjectName            "object_name"
#define BugsnagKSCrashField_SymbolAddr            "symbol_addr"
#define BugsnagKSCrashField_SymbolName            "symbol_name"


#pragma mark - Stack Dump -

#define BugsnagKSCrashField_DumpEnd               "dump_end"
#define BugsnagKSCrashField_DumpStart             "dump_start"
#define BugsnagKSCrashField_GrowDirection         "grow_direction"
#define BugsnagKSCrashField_Overflow              "overflow"
#define BugsnagKSCrashField_StackPtr              "stack_pointer"


#pragma mark - Thread Dump -

#define BugsnagKSCrashField_Backtrace             "backtrace"
#define BugsnagKSCrashField_Basic                 "basic"
#define BugsnagKSCrashField_Crashed               "crashed"
#define BugsnagKSCrashField_CurrentThread         "current_thread"
#define BugsnagKSCrashField_DispatchQueue         "dispatch_queue"
#define BugsnagKSCrashField_NotableAddresses      "notable_addresses"
#define BugsnagKSCrashField_Registers             "registers"
#define BugsnagKSCrashField_Skipped               "skipped"
#define BugsnagKSCrashField_Stack                 "stack"


#pragma mark - Binary Image -

#define BugsnagKSCrashField_CPUSubType            "cpu_subtype"
#define BugsnagKSCrashField_CPUType               "cpu_type"
#define BugsnagKSCrashField_ImageAddress          "image_addr"
#define BugsnagKSCrashField_ImageVmAddress        "image_vmaddr"
#define BugsnagKSCrashField_ImageSize             "image_size"


#pragma mark - Memory -

#define BugsnagKSCrashField_Free                  "free"
#define BugsnagKSCrashField_Usable                "usable"


#pragma mark - Error -

#define BugsnagKSCrashField_Backtrace             "backtrace"
#define BugsnagKSCrashField_Code                  "code"
#define BugsnagKSCrashField_CodeName              "code_name"
#define BugsnagKSCrashField_CPPException          "cpp_exception"
#define BugsnagKSCrashField_ExceptionName         "exception_name"
#define BugsnagKSCrashField_Mach                  "mach"
#define BugsnagKSCrashField_NSException           "nsexception"
#define BugsnagKSCrashField_Reason                "reason"
#define BugsnagKSCrashField_Signal                "signal"
#define BugsnagKSCrashField_Subcode               "subcode"
#define BugsnagKSCrashField_UserReported          "user_reported"


#pragma mark - Process State -

#define BugsnagKSCrashField_LastDeallocedNSException "last_dealloced_nsexception"
#define BugsnagKSCrashField_ProcessState             "process"


#pragma mark - App Stats -

#define BugsnagKSCrashField_ActiveTimeSinceCrash  "active_time_since_last_crash"
#define BugsnagKSCrashField_ActiveTimeSinceLaunch "active_time_since_launch"
#define BugsnagKSCrashField_AppActive             "application_active"
#define BugsnagKSCrashField_AppInFG               "application_in_foreground"
#define BugsnagKSCrashField_BGTimeSinceCrash      "background_time_since_last_crash"
#define BugsnagKSCrashField_BGTimeSinceLaunch     "background_time_since_launch"
#define BugsnagKSCrashField_LaunchesSinceCrash    "launches_since_last_crash"
#define BugsnagKSCrashField_SessionsSinceCrash    "sessions_since_last_crash"
#define BugsnagKSCrashField_SessionsSinceLaunch   "sessions_since_launch"


#pragma mark - Report -

#define BugsnagKSCrashField_Crash                 "crash"
#define BugsnagKSCrashField_Diagnosis             "diagnosis"
#define BugsnagKSCrashField_ID                    "id"
#define BugsnagKSCrashField_Major                 "major"
#define BugsnagKSCrashField_Minor                 "minor"
#define BugsnagKSCrashField_ProcessName           "process_name"
#define BugsnagKSCrashField_Report                "report"
#define BugsnagKSCrashField_Timestamp             "timestamp"
#define BugsnagKSCrashField_Version               "version"

#pragma mark Minimal
#define BugsnagKSCrashField_CrashedThread         "crashed_thread"

#pragma mark Standard
#define BugsnagKSCrashField_AppStats              "application_stats"
#define BugsnagKSCrashField_BinaryImages          "binary_images"
#define BugsnagKSCrashField_SystemAtCrash         "system_atcrash"
#define BugsnagKSCrashField_System                "system"
#define BugsnagKSCrashField_Memory                "memory"
#define BugsnagKSCrashField_Threads               "threads"
#define BugsnagKSCrashField_User                  "user"
#define BugsnagKSCrashField_UserAtCrash           "user_atcrash"

#pragma mark Incomplete
#define BugsnagKSCrashField_Incomplete            "incomplete"
#define BugsnagKSCrashField_RecrashReport         "recrash_report"

#endif
