# linux-second-screen
Open source solution to use any android device as second monitor on linux.

# The power of the script
Take a look at the [monitor.sh](https://github.com/Dlimaun/linux-second-screen/blob/master/monitor.sh).   
This script will create the virtual monitor and start x11vnc server for you.   
You only need to pass those parameters, if you want. The parameters could be passed in any order   
* Device resolution using [width]x[height], without bracets. Sample 800x600
* `-v` - VIRTUAL display to be used. Sample v1, v2, v3
* `-left` or `-right  - the position of your device, related to you display
* `-hst` - Subtract status bar size from virtual display
* `-hsb` - Subtract system bar size from virtual display

## Mixing with ADB?
Some Android device return can return the resolution throught command line.   
To use that you will need to enable developer mode on your device. [Check this](http://developer.android.com/tools/help/adb.html#Enabling) to enable.   
With this you don't need to pass any parameters to the script.   

## if you still want to do it by hand
Follow this [tutorial](https://github.com/Dlimaun/linux-second-screen/blob/master/tutorial.md).   

# Open source android VNC client
* [bVNC](https://play.google.com/store/apps/details?id=com.iiordanov.freebVNC)
