#!/bin/bash

: <<'EOMD'
# Setup for a performance optimized qemu+kvm based vm, using the intel gvt-g technology.

# Setup host
1. Check if needed kernel modules are loaded
    + `$ lsmod | grep -i -E "kvm|vfio"`
        - kvmgt
        - vfio
        - vfio_mdev
        - vfio-pci
        - vfio_virqfd
        - vfio_iommu_type1
    
    + (Optional) check if the kernel modules exists
        - `$ find /lib/modules/$(uname -r) -type f -name '*.ko*' | grep -i -E "kvm|vfio"`
    
    + Add the modules, which are not already loaded to /etc/mkinitcpio.conf
        - ```
          MODULES=(... kvmgt vfio vfio_mdev vfio-pci vfio_virqfd vfio_iommu_type1 ...)
          ```
    + Build ramdisk TODO
        - `$ mkinitcpio -p linux`
2. Set the needed [kernel](https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html) and [kernel module parameters](https://www.github.com/nounix/TODO) via boot loader options. TODO add path

    + ```
      options ... intel_iommu=on iommu=pt i915.enable_gvt=1 i915.enable_guc=0 kvm.ignore_msrs=1 ...
      ```
3. Create a vGPU
    + Find the slot of your intel graphics device (slot = [domain:]bus:device.function, e.g.: "**00:02.0**")
        - `$ lspci`
    + Choose mdev type (e.g: "**i915-GVTg_V5_4**")
        - `$ find /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/*/description -exec sh -c "echo {} && cat {}" \;`
    + Create a vGPU device:
        - `$ echo "$(cat /proc/sys/kernel/random/uuid)" | tee -a /sys/devices/pci0000:00/0000:**00:02.0**/mdev_supported_types/**i915-GVTg_V5_4**/create`
4. Create disk img
    + qemu-img create -f raw win.raw 300G
    + qemu-img create -f qcow2 -b win.raw -F raw -o preallocation=metadata,compat=1.1,lazy_refcounts=on,cluster_size=2M,extended_l2=on win-bsi.qcow2
EOMD

# Create vgpu
# VGPU="$(cat /proc/sys/kernel/random/uuid)"
VGPU="71595408-5e2e-4235-b146-70e80c4fa463"
echo "$VGPU" | tee -a /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create

options=(
	-machine type=q35,accel=kvm,kernel_irqchip=on
	-smp sockets=1,threads=2,cores=6,maxcpus=12
	-cpu host,l3-cache=on,kvm=off,hv_relaxed,hv_vpindex,hv_time,hv_synic,hv_stimer,hv_vapic,hv_spinlocks=0x1fff,vmx=on
	-no-hpet
	-nodefaults
	-m 8G -mem-prealloc
	-rtc clock=host,base=localtime
	-nic user,model=virtio-net-pci
	-device virtio-input-host-pci,evdev=/dev/input/event7
	-device virtio-input-host-pci,evdev=/dev/input/event10
	-display gtk,gl=on -full-screen
	-device intel-iommu,caching-mode=on
	-device vfio-pci,sysfsdev=/sys/devices/pci0000:00/0000:00:02.0/"$VGPU",display=on,ramfb=on,driver=vfio-pci-nohotplug,x-igd-opregion=on
	-object iothread,id=io1
	-device virtio-blk-pci,drive=disk0,iothread=io1
	-drive if=none,id=disk0,aio=threads,cache=none,format=raw,discard=unmap,file="$HOME"/qemu/win-work.raw
)

qemu-system-x86_64 "${options[@]}"

exit
### TODO:
# guest agent from /guest-agent/qemu-ga-x64.msi??
# trim base raw image (QCOW2 Image Tips reddit: https://www.reddit.com/r/VFIO/comments/8h352p/guide_running_windows_via_qemukvm_and_intel_gvtg/)
# install all vritio driver (http://www.zeta.systems/blog/2018/07/03/Installing-Virtio-Drivers-In-Windows-On-KVM/ & https://github.com/QaidVoid/Complete-Single-GPU-Passthrough)
# optimize vm (https://leduccc.medium.com/improving-the-performance-of-a-windows-10-guest-on-qemu-a5b3f54d9cf5)
# /etc/mkinitcpio.conf: MODULES=(...kvmgt vfio vfio-iommu-type1 vfio-mdev vfio_pci vfio vfio_iommu_type1 vfio_virqfd ...) (lsmod UNDDDD find /lib/modules/$(uname -r) -type f -name '*.ko*' | g vfio)
# fix sound
# pass mouse keyboard (evdev passthrough: https://gist.github.com/hflw/ed9590f4c79daaeb482c2419f74ed897)
# activate in windows max performance
# pin cpus
# add iommu=pt (dmesg | grep 'IOMMU enabled')
# -display gtk,gl=on,zoom-to-fit=off usefull?
# add steps/script for host config
###

### INFOS
# qemu-img create -f raw image_name 4G

# -device usb-host,vendorid=0x046d,productid=0xc52b
# -net nic
# -net user
# -nic user,model=virtio-net-pci
# -drive file=/home/martin/downloads/virt/virtio-win-0.1.185.iso,media=cdrom
# -nodefaults
# -drive file=/home/martin/qemu/win-snap.qcow2,if=virtio,aio=native,cache=none,format=qcow2
# -cpu host,hv_relaxed,hv_vpindex,hv_time,hv_synic,hv_stimer,hv_vapic,hv_spinlocks=0x1fff,hv_vendor_id=koniva
# -no-hpet
# -rtc base=localtime
# -drive file=/home/martin/downloads/Win10_20H2_v2_German_x64.iso,index=2,media=cdrom
# -boot menu=on
# -bios /home/martin/qemu/bios.bin
# -set device.hostdev0.romfile=/home/martin/qemu/vbios_gvt_uefi.rom
# -net user,hostfwd=tcp::10022-:22
# -drive file=/home/martin/downloads/virtio-win-0.1.185.iso,index=1,media=cdrom
# -drive if=pflash,format=raw,readonly,file=/usr/share/ovmf/x64/OVMF_CODE.fd
# -drive ,l2-cache-size=8M (1MB cache per 1GB disk space)
# aio=threads better on ext4 else native
# xres=1920,yres=1080 (xres and yres properties need edid support)
# -display gtk,gl=on,zoom-to-fit=off | usefull?
# -device ich9-intel-hda
# -cpu ,hv_vendor_id=blabla

# KVMGT is the open source implementation of Intel® GVT-g for KVM

# -cpu host,kvm=off
# As of QEMU 2.1 we now have a new -cpu option, kvm=on|off which controls
# whether we expose KVM as the hypervisor via the MSR hypervisor nodes.
# The default is on.  The off state is meant to hide kvm from standard
# detection routines.  This allows us to disable paravirtualization
# detection in the guest and can be used to bypass hypervisor checks in
# certain guest drivers

# -enable-kvm , not needed cuz -machine type=q35,accel=kvm,kernel_irqchip=on

# -machine type=q35
# Add emulation of the ICH9 host chipset as an alternative to the current I440FX emulation. This will allow for better support of PCI-E passthrough since ICH9 uses a PCI-E bus whereas the I440FX only supports a PCI bus. 

# -device intel-iommu,caching-mode=on
# VM can use IOMMU to have exclusive access to a device, the IOMMU ensures memory safety, and optimizes the interrupt-to-cpu delivery. SR-IOV improves scalability, it makes a physical device appear as multiple virtual devices. Combing SR-IOV and IOMMU, each running VM can have exclusive access to a virtual function, no VMM involved, even if there is just one physical PCIe device. Note that, a) IOMMU can be used without SR-IOV, that means a physical device can be used by one VM only, b) in theory, SR-IOV-capable device can be used without IOMMU, as long as the guest VM can see host physical address. However, the usual practice is always use SR-IOV with IOMMU, thus it can translate guest physical address to host physical address.
# https://gdoc.pub/doc/e/2PACX-1vSsskD0A2XgHoZhaYLAkS7lmCOrfxkGXk1WTovWEAyeoELVdBjrE-NzD8h-NvJfKhxMpUg2aXzaD-XG

# Windows needed some help in identifying the C: drive as SSD. Typing winsat formal in a Windows administrator shell did the trick

# rombar=0
# https://github.com/qemu/qemu/blob/master/docs/igd-assign.txt

# x-igd-opregion=on
# multimonitor support

# the ramfb device, specified by ramfb and vfio-pci-nohotplug, is used as boot display, to show screen content during early boot phase, before Intel guest driver is initialized.
# xres and yres are used to set EDID of the mdev device, otherwise it will be default to 1920x1200, changing resolution in Guest OS may cause mouse position out of sync issue 

# There is also a variant of this technology called GVT-d - it is essentially Intel's name for full device passthrough with the vfio-pci driver. With GVT-d, the host cannot use the virtualized GPU.
# Intel GVT-g is a technology that provides mediated device passthrough for Intel GPUs (Broadwell and newer). It can be used to virtualize the GPU for multiple guest virtual machines, effectively providing near-native graphics performance in the virtual machine and still letting your host use the virtualized GPU normally

# OVMF "is a project to enable UEFI support for Virtual Machines".
# http://www.linux-kvm.org/downloads/lersek/ovmf-whitepaper-c770f8c.txt
# Intel_GVT works just with legacy bios not uefi/ovmf

# hv­_tlbflush: qemu-system-x86_64: can't apply global host-x86_64-cpu.hv­-tlbflush=on: Property 'host-x86_64-cpu.hv­-tlbflush' not found
# hv_­ipi
# hv­_frequencies
# hv­_reenlightenment

# xres=1920,yres=1080 (-> error: xres and yres properties need edid support)
###

### LINKS
# https://github.com/intel/gvt-linux/issues/143
# https://github.com/intel/gvt-linux/issues
# https://fossies.org/linux/qemu/docs/hyperv.txt
# https://wiki.archlinux.org/index.php/Intel_GVT-g
# https://www.reddit.com/r/VFIO/comments/8h352p/guide_running_windows_via_qemukvm_and_intel_gvtg/
# https://www.kraxel.org/blog/2019/09/display-devices-in-qemu/
# https://gist.github.com/hflw/ed9590f4c79daaeb482c2419f74ed897
# WINDOWS driver: https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/index.html
###
