#!/bin/bash 

allWin=( $(wmctrl -l | grep -o '\b0x\w*') )
actWin=( $(xdotool getwindowfocus) )

C=0

for i in ${allWin[@]}; do
	printf -v allWin[$C] "%d" $i
	((C++))
done

C=0

for one_thing in ${allWin[@]}; do
	if [ $one_thing = $actWin ]; then
    	break
    fi
    ((C++))
done

function switchWin {
    wmctrl -i -a ${allWin[$C+$1]}
}

switchWin $1
