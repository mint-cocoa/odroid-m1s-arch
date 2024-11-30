setenv bootargs "root=/dev/mmcblk0p2 rw console=ttyS2,1500000"
load mmc 0:1 ${kernel_addr_r} Image
load mmc 0:1 ${ramdisk_addr_r} uInitrd
load mmc 0:1 ${fdt_addr_r} rk3566-odroid-m1s.dtb
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
