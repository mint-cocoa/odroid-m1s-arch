# Install Arch Linux on Odroid M1S

This is a little guide on how to install the shizzle on your device. But i made that primarily
for fun and myself, so i decided it may be better for all of us when i don't share my built images.
Yes, they're kinda tested and they worked, so i lost interest in fiddling around ^^ 
So i don't steal you all the fun, go and build it yourself, it's pretty straightforward! 
But i keep the instructions/workflow here and hope it helps someone.

## A Word Of Caution

You really should have a serial connection to your M1S, because it makes things a lot easier when
something wents wrong. And using my advice may turn things **terribly** wrong, so don't blame me
when you brick your device! Although it's not so easy to **really** brick your device, it's still possible. 
Check [Recovery steps](README.md#recovery-steps).

<!-- TOC -->
* [Install Arch Linux on Odroid M1S](#install-arch-linux-on-odroid-m1s)
  * [A Word Of Caution](#a-word-of-caution)
  * [Start Odroid M1S in UMS Mode](#start-odroid-m1s-in-ums-mode)
  * [The Easy Way](#the-easy-way)
  * [The Extended Way](#the-extended-way)
    * [Install U-Boot](#install-u-boot)
    * [Create Partitions](#create-partitions)
    * [Create Filesystems](#create-filesystems)
    * [Copy Additional Files](#copy-additional-files)
    * [Generate U-Boot Boot.scr](#generate-u-boot-bootscr)
    * [Final Steps](#final-steps)
<!-- TOC -->

## Start Odroid M1S in UMS Mode

Insert an SD card with the Odroid UMS image into your Odroid and boot the device.
You find the needed `ODROID-M1S_EMMC2UMS.img`
here: [wiki.odroid.com](https://wiki.odroid.com/odroid-m1s/getting_started/os_installation_guide?redirect=1#install_over_usb_from_pc)

> **Note:** Be root or use sudo

## The Easy Way

1. Download my Arch Linux Image
   image: ~~[arch_image.img.gz]()~~ (215M). Yes, there is an easy way that involves
   writing a tar.gz with dd on your device. But hey, it may install ransomware and
   whatnot, so why take the risk?

2. Write the image to your device using the following command:

   > **Note:** If you already installed my image, you can skip step 3 and start the
   U-Boot console directly on the device. Run `ums mmc 0` and connect the Odroid
   microUSB port to your host computer.

    ```bash
    gzip -dc arch_image.img.gz | dd of=/dev/sdX bs=4M status=progress
    ```

3. Unplug the SD card (If you used the UMS boot SD) and reboot the device.
4. Enjoy your Arch Linux setup!

## The Extended Way

Aka. "I like typing commands i never used before in a shell".

> **Note:** Be aware that you have more possibilities to rescue your Odroid M1S when
> you attach a serial console to it!

### Install U-Boot

1. Download and extract U-Boot:

    - ~~[u-boot_rk3566-odroid-m1s.zip]()~~ Again, you should not write a random image from
    some github account you never heard before on a device you like and love.

   **Note:** A `boot.scr` file should be present in `/dev/mmcblk0p1` where you set
   your bootflow. You'll find instructions on how to generate a
   `boot.scr` [here](README.md#save-boot-commands-generate-bootscr).

2. Write the U-Boot image to your USB storage device:

   ```bash
   dd if=u-boot-rockchip.bin of=/dev/<your usb storage device> bs=32k seek=1 conv=fsync
   ```

### Create Partitions

Create two partitions: `BOOT` and `rootfs`. The BOOT partition starts at 16MB to leave
enough room for the U-Boot blob.

1. Use the following `gdisk` commands to create the partitions:

   ```bash
   d               # Delete partition 1
   d               # Delete partition 2 (if present)

   n               # Create a new partition
   1               # Partition number 1
   32768           # Start sector at 16MB
   +256M           # Size of the first partition
   8300            # Set type to Linux filesystem
   n               # Create a new partition
   2               # Partition number 2
   557056          # Start sector (right after the first partition)
   <Enter>         # End sector (uses the remaining space)
   8300            # Set type to Linux filesystem

   p               # Display the current partition table (for verification)
   w               # Save the changes and exit fdisk
   ```

### Create Filesystems

1. Create the filesystems for the partitions:

   ```bash
   mkfs.ext4 /dev/<your usb storage device partition 1> -L BOOT
   mkfs.ext4 /dev/<your usb storage device partition 2> -L rootfs
   ```

2. Extract the ArchLinuxARM-aarch64 root filesystem to the mounted rootfs partition:

   ```bash
   mount /dev/<your usb storage device partition 2> /mnt
   bsdtar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /mnt
   ```

### Copy Additional Files

1. Copy the contents of ~~[dist.tar.gz]()~~ to the
   partitions.

- For the rootfs partition run:

  ```bash
  cp -r 6.11.0-rc5-odroid-arm64+ /mnt/lib/modules/
  # sync is invoked on unmounting so no need to sync every now and then..
  umount /mnt
  ```

- For the BOOT partition run:

  ```bash
  mount /dev/<your usb storage device partition 1> /mnt
  cp Image uInitrd rk3566-odroid-m1s.dtb boot.* /mnt
  umount /mnt
  ```

### Generate U-Boot Boot.scr

> **Note:** We mount the root filesystem read-write because we can, and it's a
> deliberate choice. With an initrd in place, `fsck` can run properly from there,
> mitigating potential issues. We acknowledge the risk of eMMC wear, which is acceptable
> given the expected device lifespan.

> **Info:** There is a ready to use `boot.scr` in [scripts/u-boot](scripts/u-boot)

Create the file [boot.cmd](scripts/u-boot/boot.cmd) and generate boot.scr:

```bash
mkimage -C none -A arm -T script -d boot.cmd boot.scr
cp boot.scr <odroid mmcblk0p1>/
```

### Final Steps

1. Reboot the device.

2. You're done. Enjoy your Arch Linux installation on the Odroid M1S 