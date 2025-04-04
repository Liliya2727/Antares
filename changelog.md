## Changelog V2.0 (V2044)
- Increase Loop delay to 35 Seconds when Using GamePreload to reduce usage
- Fix bootloop issue on some devices
- Fix Bypass Charge Checking when Installing Module
- Adjust Surfaceflinger Value
- Removed System.prop 
- Bypass charge now only supports Specific Devices!


## Changelog V1.9 (V1927)
- Introducing Game Preload, Preload game libs to memory to reduce load time and minimize lag
- Ram Freed, Kill background apps when entering performance profiles to reduce ram usage
- WebUi: added loading screen on WebUI, let everything to load before accessing WebUI
- WebUi: Now chipset automatically detect name, it'll use it's marketing name instead using the codename
- Removed the script to kill mlbb when it's in the background for too long
- Adjust the monitoring loops to 15 S
- Drop PID detection and using dumpsys activity recents instead
- Refining Module Logging, now it has 2 logging files, /data/AZenith/AZenith.log && /data/AZenith/AZenithMon.log thanks to @kanaochar


## Changelog V1.8 (1825)
- Fix Profiler, some settings wouldn't work without this one


## Changelog V1.8 (1824)
- Optimizing Script
- Added a script to clear background apps on Performance Profiles


## Changelog V1.7 (1723)
- Optimize Performance Script and Tweak
- Added Feature to Underclock CPU Frequency
- Rebrand to Universal MediaTek Modules
- Optimize Monitoring Service
- Fix a bug where service won't start after being restarted
- Added KillLogger
- Fix a bug where ML High Prior always killed the Monitoring Service


## Changelog V1.2 Release (1216)
- Fix a bug where service won't start again after being disabled
- Fix Volt Opt wont save the Value before Disabling it
- Adjust monitoring loop to 10 Seconds
- Change some shell Notification
- Reworked Something in WebUI
- Droped Kill Logger
- Some rework on Monitoring Service (Background Service)


## Changelog V1.0 Release (1014)
- Initial Release on Github
- Sync with Encore 2.3 WebUi
- Added FSTrim (Adjustable in Webui)
- Fixed Bypass Charge won't active in Perf Mode
- Add Zenith Thermal (Adjustable in Webui)
- Add Disable Vsync (Can be Applied in Webui)
- Add Kill Logger
- Adjustable Performance mode (Automatically kill the Service)
- Fix a bug PID is running twice when restarting services
- Restarting Service now will took 15 Seconds until its start the service.
