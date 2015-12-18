//
//  BugsnagKSSystemInfo.h
//
//  Created by Karl Stenerud on 2012-02-05.
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


#define BugsnagKSSystemField_AppStartTime "app_start_time"
#define BugsnagKSSystemField_AppUUID "app_uuid"
#define BugsnagKSSystemField_BootTime "boot_time"
#define BugsnagKSSystemField_BundleID "CFBundleIdentifier"
#define BugsnagKSSystemField_BundleName "CFBundleName"
#define BugsnagKSSystemField_BundleShortVersion "CFBundleShortVersionString"
#define BugsnagKSSystemField_BundleVersion "CFBundleVersion"
#define BugsnagKSSystemField_CPUArch "cpu_arch"
#define BugsnagKSSystemField_CPUType "cpu_type"
#define BugsnagKSSystemField_CPUSubType "cpu_subtype"
#define BugsnagKSSystemField_BinaryCPUType "binary_cpu_type"
#define BugsnagKSSystemField_BinaryCPUSubType "binary_cpu_subtype"
#define BugsnagKSSystemField_DeviceAppHash "device_app_hash"
#define BugsnagKSSystemField_Executable "CFBundleExecutable"
#define BugsnagKSSystemField_ExecutablePath "CFBundleExecutablePath"
#define BugsnagKSSystemField_Jailbroken "jailbroken"
#define BugsnagKSSystemField_KernelVersion "kernel_version"
#define BugsnagKSSystemField_Machine "machine"
#define BugsnagKSSystemField_Memory "memory"
#define BugsnagKSSystemField_Model "model"
#define BugsnagKSSystemField_OSVersion "os_version"
#define BugsnagKSSystemField_ParentProcessID "parent_process_id"
#define BugsnagKSSystemField_ParentProcessName "parent_process_name"
#define BugsnagKSSystemField_ProcessID "process_id"
#define BugsnagKSSystemField_ProcessName "process_name"
#define BugsnagKSSystemField_Size "size"
#define BugsnagKSSystemField_SystemName "system_name"
#define BugsnagKSSystemField_SystemVersion "system_version"
#define BugsnagKSSystemField_TimeZone "time_zone"


/**
 * Provides system information useful for a crash report.
 */
@interface BugsnagKSSystemInfo : NSObject

/** Get the system info.
 *
 * @return The system info.
 */
+ (NSDictionary*) systemInfo;

@end
