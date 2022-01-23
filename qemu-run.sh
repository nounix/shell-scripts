#!/bin/bash

# qemu-img create -f raw image_name 4G
# mount -t 9p -o trans=virtio,version=9p2000.L hostshare /path/to/mount
# ssh user@localhost -p10022

# -drive file="$2",media=cdrom
# -drive if=pflash,format=raw,readonly,file=/usr/share/ovmf/x64/OVMF_CODE.fd

IMG_PATH="$HOME/qemu/"

options=(
    -enable-kvm
	-cpu host
	-smp cores=4
	-machine type=pc,accel=kvm
	-soundhw hda
	-usb -device usb-kbd -device usb-tablet
	-rtc base=localtime
	-net user,hostfwd=tcp::10022-:22
	-net nic
	-drive file="$(find $IMG_PATH -name $1)",format=raw,index=0,media=disk,if=virtio,cache=none
)

args=$#
for (( i=1; i<=$args; i++ )); do
	[ ${!i} == "-usb" ] && let i++ && USB_PATH="${!i}"
	[ ${!i} == "-cd" ] && let i++ && CD_PATH="${!i}"
	[ ${!i} == "-sf" ] && let i++ && SHARED_DIR_PATH="${!i}"
	[ ${!i} == "-ng" ] && NO_GRAPHIC=true
done

[ ! -z "$USB_PATH" ] && options+=(-drive file="$USB_PATH",format=raw,index=1)
[ ! -z "$CD_PATH" ] && options+=(-cdrom $CD_PATH -boot menu=on)
[ ! -z "$SHARED_DIR_PATH" ] && options+=(-fsdev local,security_model=passthrough,id=fsdev0,path="$SHARED_DIR_PATH")
[ ! -z "$SHARED_DIR_PATH" ] && options+=(-device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare)
[ "$NO_GRAPHIC" = true ] && options+=(-m 1G -nographic) || options+=(-m 4G -vga virtio -full-screen)

qemu-system-x86_64 "${options[@]}"
