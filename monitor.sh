#!/bin/bash

# DEBUG
#set -x

## PARAMS
## Device resolution using [width]x[height], without bracets. Sample 800x600
## -v - VIRTUAL display to be used. Sample v1, v2, v3
## -left  - If our device is on the left
## -right - If our device is on the right
## -hst	  - Subtract status bar size from virtual display
## -hsb	  - Subtract system bar size from virtual display

## Primary physical screen name
physical=$(xrandr | grep primary | awk '{print $1}')

## ADB path
# TODO: require adb in the path?
adb=$(which adb 2>/dev/null || echo "~/android-sdk-linux/platform-tools/adb")

#echo $@
## Regex to understand params
virtual=$(echo $@ | grep -Po '\-v\d' | grep -Po '\d')
device=$(echo $@ | grep -Po '\d+x\d+')
position=$(echo $@ | grep -Po '\-(left|right)' | grep -Po '\w+')
hide_statusbar=$(echo $@ | grep -Po '\-hst')
hide_systembar=$(echo $@ | grep -Po '\-hsb')



## Use VIRTUAL1 if none was passed
if [ -z "$virtual" ] ; then
	virtual="VIRTUAL1"
else
	virtual="VIRTUAL${virtual}"
fi

diagonal() {
  printf '%.0f' $(bc <<< "scale=2; sqrt($1^2+$2^2)")
}



#******** HOST ********

## Find host resolution
h_res=$(xrandr | grep \* | awk '{print $1}')
h_width=$(echo $h_res | cut -d'x' -f 1)
h_height=$(echo $h_res | cut -d'x' -f 2)
h_diag=$(diagonal $h_width $h_height)
echo "h_diag = $h_diag"

## Calculate host dpi (XORG reports wrong dpi, since it always defualts to 96 dpi)
#h_dpi=$(xdpyinfo | grep resolution | awk '{print $2}' | cut -d"x" -f1)
h_psize=$(xrandr | grep eDP | awk '{print $(NF-2), $(NF)}' | sed "s/mm//g")
h_pwidth=$(echo "$h_psize" | cut -d' ' -f1)
h_pheight=$(echo "$h_psize" | cut -d' ' -f2)
h_pdiag=$(bc <<< "scale=0; $(diagonal $h_pwidth $h_pheight)/25.4")
h_dpi=$(bc <<< "scale=2; $h_diag/$h_pdiag" | xargs printf '%.0f')

echo "HOST"
echo "h_res    = $h_res"
echo "h_width   = $h_width"
echo "h_height  = $h_height"
echo "h_psize = $h_psize"
echo "h_pwidth = $h_pwidth"
echo "h_pheight = $h_pheight"
echo "h_pdiag = $h_pdiag"
echo "h_dpi = $h_dpi"



#******** DEVICE ********

## Find Android device resolution with the current orientation
if [ -z "$device" ] ; then
  device=$($adb shell dumpsys window displays | grep init | awk '{print $3}' | cut -d'=' -f2)
fi
if [ -z "$device" ] ; then
	echo "Can't read device resolution using adb"
	exit 1
else
	## Device width and height
	d_width=$(echo $device | cut -d'x' -f 1)
	d_height=$(echo $device | cut -d'x' -f 2)
fi

# TODO: keep windows size looking the same on the virtual monitor.... HOW? --> DPI+SCALE
#d_dpi=$(adb shell wm density | cut -d' ' -f 3)  # Slower and working only on newer android versions
d_dpi=$(adb shell dumpsys display | grep DisplayDeviceInfo  | sed -n -e 's/^.*density \([0-9]\+\).*/\1/p')
d_orientation=$(adb shell dumpsys input | grep 'SurfaceOrientation' | awk '{ print $2 }')

echo
echo
echo "DEVICE"
echo "d_width = $d_width"
echo "d_height = $d_height"
echo "d_dpi = $d_dpi"
echo "d_orientation = $d_orientation"



#******** VIRTUAL ********

# TODO: proportion needed?
## Proportion, bash don't handle float, only integers so we use bc to do that operation
proportion=$(bc <<< "scale=2; $d_height / $h_height")
v_width=$(bc <<< "scale=0; $d_width / $proportion")
v_height=$h_height
#v_scale=$(bc <<< "scale=2; 1/$proportion" | awk '{printf "%f", $0}')  # TODO: we need to take the resoultion difference in account for the scale. For now, we ignore this (same res)

# TODO: STATUS BAR - NAVIGATION BAR 
status_bar=32
system_bar=48
## Remove status bar height
if [ ! -z "$hide_statusbar" ] ; then
	v_height=$(($v_height - $status_bar))
fi
## Remove navigation bar height
if [ ! -z "$hide_systembar" ] ; then
	v_height=$(($v_height - $system_bar))
fi

## Check param position, this position is where the user want the new screen
if [ -z "$position" ] ; then
	position="right"
fi
if [ "$position" = "left" ] ; then
	xinerama="xinerama0"
else
	xinerama="xinerama1"
fi


# Add traling zero to bc output
v_scale=$(bc <<< "scale=2; $h_dpi / $d_dpi" | awk '{printf "%f", $0}')
v_width=$(bc <<< "$d_width*$v_scale")
v_height=$(bc <<< "$d_height*$v_scale")

v_width=$d_width
v_height=$d_height


## Build the modeline, the display configurations
modeline=$(cvt $v_width $v_height 60.00 | grep "Modeline" | cut -d' ' -f 2-17)
mode=$(echo "$modeline" | cut -d' ' -f 1)

echo
echo "Display = $virtual"
echo "v_scale   = $v_scale"
echo "mode = $mode"
echo "modeline = $modeline"

## Create Virtual Display
xrandr --newmode $modeline
xrandr --addmode $virtual $mode
xrandr --output $virtual --mode $mode --${position}-of ${physical} --scale ${v_scale}x${v_scale}

## Start VNC
x11vnc --auth guess -rfbauth /home/$USER/.vnc/passwd -once \
  -clip ${xinerama} -xrandr -nosel -viewonly -fixscreen \"V=2\" -noprimary -nosetclipboard -noclipboard -cursor most -nopw -nowf -nonap -noxdamage -sb 0 \
  -display :0

## Turn VirtualDisplay off
xrandr --output $virtual --off
xrandr --delmode $virtual $mode
xrandr --rmmode $mode
# TODO: set size to 0.. is it needed?
#xrandr -s :0
