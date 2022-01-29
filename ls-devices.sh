#!/bin/bash

for sysdevpath in $(find /sys/bus/usb/devices/usb*/ -name dev); do
    (
        syspath="${sysdevpath%/dev}"
        devname="$(udevadm info -q name -p $syspath)"
        [[ "$devname" == "bus/"* ]] && continue
        eval "$(udevadm info -q property --export -p $syspath)"
        [[ -z "$ID_SERIAL" ]] && continue
        echo "/dev/$devname - $ID_SERIAL"
    )
done

exit

Explanation:

find /sys/bus/usb/devices/usb*/ -name dev

Devices which show up in /dev have a dev file in their /sys directory. So we search for directories matching this criteria.
 

syspath="${sysdevpath%/dev}"

We want the directory path, so we strip off /dev.
 

devname="$(udevadm info -q name -p $syspath)"

This gives us the path in /dev that corresponds to this /sys device.
 

[[ "$devname" == "bus/"* ]] && continue

This filters out things which aren't actual devices. Otherwise you'll get things like USB controllers & hubs.
 

eval "$(udevadm info -q property --export -p $syspath)"

The udevadm info -q property --export command lists all the device properties in a format that can be parsed by the shell into variables. So we simply call eval on this. This is also the reason why we wrap the code in the parenthesis, so that we use a subshell, and the variables get wiped on each loop.
 

[[ -z "$ID_SERIAL" ]] && continue

More filtering of things that aren't actual devices.
 

echo "/dev/$devname - $ID_SERIAL"

I hope you know what this line does :-)
