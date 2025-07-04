#!/system/bin/sh

#
# Copyright (C) 2024-2025 Zexshia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Wait for boot to Complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do  
    sleep 40
done

# Cleanup old Logs
rm -f /data/adb/.config/AZenith/AZenith.log
rm -f /data/adb/.config/AZenith/AZenithVerbose.log
rm -f /data/adb/.config/AZenith/AZenithPR.log

# Fallback to schedutil if default governor is Performance 
chmod 644 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
default_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
[ "$default_gov" = "performance" ] && default_gov="schedutil"


# Run Daemon
AZenith
