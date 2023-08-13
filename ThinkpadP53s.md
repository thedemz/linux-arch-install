# Thinkpad P53s

**Arch Linux: 2019.10.01**

## Checklist:

UEFI Motherboard
64 bit x86 CPU
GPT Partition: 512 fat32 with boot and esp flag set. For GRUB2.
GRUB 2
Wired connection
BIOS Secure Boot disabled
archlinux.iso on USB

# Installing Arch Linux

## 1. Show the storage medias.

Find the sdX name of the storage media that was partitioned with GPT. In this guide the X = a

```
fdisk -l
```

### format partitions

https://wiki.archlinux.org/title/EFI_system_partition

```
mkfs.fat -F 32 /dev/nvme0n1p1
```

https://wiki.archlinux.org/title/ext4

```
mkfs.ext4 /dev/nvme0n1p2
```

## 2. Mount the partitions.

First the main storage partition then the boot partition referred as the $esp.

```
mount /dev/nvme0n1p2 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

> The simplest option is to mount it at /boot, since this allows pacman to directly
> update the kernel that the EFI firmware will read.

> If the ESP is other than /boot then you need to set up a copy hook when
> pacman updates the kernel in the future. https://wiki.archlinux.org/index.php/EFISTUB

> `grub-install --target=x86_64-efi --efi-directory=/boot`
> will install on the location `/boot/EFI`

## 3. Check that there is an internet connection.

https://wiki.archlinux.org/title/Iwd#iwctl

```
iwctl
```

```
[iwd]# device list
```

```
[iwd]# device wlan0 show
```

```
[iwd]# device wlan0 set-property Powered on
```

```
[iwd]# adapter list
```

```
[iwd]# adapter phy0 show
```

```
[iwd]# adapter phy0 set-property Powered on
```

```
[iwd]# station wlan0 scan
```

You can then list all available networks:

```
[iwd]# station wlan0 get-networks
```

Finally, to connect to a network:

```
[iwd]# station wlan0 connect SSID
```

```
iwctl --passphrase <password> <station> wlan0 connect <SSID>
```

 `ping -c 3 www.google.com`


 ## 4. Dowload the base installation on the storage partition.

```
pacstrap -K /mnt base linux linux-firmware
```

> `pacstrap -G /mnt grub efibootmgr curl dhcpcd iwd vim`

https://geo.mirror.pkgbuild.com/iso/latest/arch/pkglist.x86_64.txt


https://archlinux.org/packages/core/any/base/

https://archlinux.org/packages/core/x86_64/linux/

https://archlinux.org/packages/core/any/linux-firmware/


https://archlinux.org/packages/core/x86_64/grub/

https://archlinux.org/packages/core/x86_64/efibootmgr/

https://archlinux.org/packages/core/x86_64/curl/

https://archlinux.org/packages/core/x86_64/dhcpcd/

https://archlinux.org/packages/extra/x86_64/iwd/

https://archlinux.org/packages/extra/x86_64/vim/

## 5. Create a file system table.

https://wiki.archlinux.org/title/Fstab

```
genfstab -U /mnt >> /mnt/etc/fstab
```

## 6. SSD

Then add the discard option to /mnt/etc/fstab
    
```
vim /mnt/etc/fstab
```

https://mvysny.github.io/ssd-discard/

```
/dev/nvme0n1  /       ext4   defaults,relatime,discard   0  1
```    

>The last column defines if the fsck should check the system.
>By default, fsck checks a filesystem every 30 boots (counted individually for each partition).
> 0 = Do not check
> 1 = The first partition to check, the root partition should be set to this.
> 2 = Check this partition, this is not the root partition.

## 7.A Change to arch on the storage partition as root user.

```
arch-chroot /mnt
```

## 7.B Install grub packages

```
pacman -S grub efibootmgr dhcpcd ntp xf86-video-intel
```

> GRUB is the bootloader while efibootmgr creates bootable .efi stub entries used by the GRUB installation script.


## 8. Create the initcpio file, which is the initial RAM disk filesystem.

```
mkinitcpio -p linux
```

## 9. Install GRUB 2 boot loader

```
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
```

```
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck --debug
```

## 10. Make a grub config file.

```
grub-mkconfig -o /boot/grub/grub.cfg
```

> /etc/default/grub
    
## 11. Create a EFI fallback .efi file (as defined in the EFI standard.)

```
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/GRUB/grubx64.efi /boot/EFI/BOOT/bootx64.efi
```

### UEFI and GRUB

Lenovo T480 is tied in with Microsoft and will only boot to Windows EFI file or default EFI fallback file.

Verified on firmware version 1.14.

When GRUB is used, it is needed to rename the GRUB .efi to one of these specific file names. Please remember to repeat these steps (or use a pacman hook) when the GRUB package was updated.

```
mount /dev/sdXY /mnt
``` 

The Windows .efi file

```
mkdir -p /mnt/EFI/Microsoft/Boot
cp /mnt/EFI/grub/grubx64.efi /mnt/EFI/Microsoft/Boot/bootmgfw.efi
```

EFI fallback .efi file (as defined in the EFI standard.)

```
mkdir -p /mnt/EFI/BOOT
cp /mnt/EFI/grub/grub64.efi /mnt/EFI/BOOT/bootx64.efi
```

> Source: http://www.rodsbooks.com/efi-bootloaders/installation.html#alternative-naming


## 12. Set a password for the root.

passwd


## 13. Install Wired Connection and other tools.

```
pacmam -S dhcpcd ntp sudo vim neovim networkmanager nmap rsync git openssh
```

```
systemctl enable NetworkManager.service
```

## 14. Create a new user with sudo rights.

> To add a new user, use the useradd command.
> `useradd -m -g [initial_group] -G [additional_groups] -s [login_shell] [username]`
    
```
useradd -m -s /bin/bash USER_NAME
```

```
passwd USER_NAME
```

```
visudo
```

>`USER_NAME   ALL=(ALL) ALL`


## 15. Exit the arch-root user.

```
exit
```

## 16. Unmount the storage media.

```
umount -R /mnt/boot /mnt
```

## 17. Reboot the computer with the systemd command.

```
systemctl reboot
```


## 18. Install mesa graphics driver.

```
pacman -S mesa
```

Check available video cards.

```
lspci | grep VGA
```

Show a list of available drivers.

```
pacman -Ss xf86-video | less
```

```
pacman -S xf86-video-intel
```

```
pacman -S nvidia nvidia-settings
```



## 19. Install Gnome desktop environment.

```
pacman -S gdm gnome-shell gnome-control-center gnome-tweak-tool
```

```
pacmam -S nautilus chromium
```

```
systemctl enable gdm.service
```

```
systemctl start gdm.service
```

## 20. Configure Arch Linux

**Set the hostname**

> The name of the computer in this example it is set to box.

```
hostnamectl set-hostname box
```

**Find the right timezone**

> This lists available zones and each have subzones.

```
cd /usr/share/zoneinfo
ls -al
```

**Set the timezone**

```
timedatectl set-timezone Europe/Stockholm
```

**Set the locale**

> The info about the language and keyboardlayout to be used.

```
vim /etc/locale.gen
```

> Uncomment the lines corresponding to the encoding and the language that can be used on the system.

```
locale-gen
localectl set-locale LANG="en_US.UTF-8"
```

# Appendix Installation Media

## Make a Arch Linux USB drive

```
lsusb
dmesg
sudo fdisk -l
```

> Do not append a partition number, so do not use something like `/dev/sdb1`

umount before!

```
dd bs=4M if=/path/to/archlinux.iso of=/dev/sdx && sync
```

## Make a GParted Live USB drive

```
sudo dd if=/path-to-gparted-live.x.y.z-w.iso of=/dev/sde bs=4M; sync
```

## Check if the motherboard supports UEFI.

```
efivar -l
```

If efivar lists the UEFI variables properly, then you have booted in UEFI mode.

## Boot Partition for GRUB

Boot loaders reside as ordinary files on a FAT partition known as the EFI System Partition - ESP
    
> GParted and parted identify the ESP as having its "boot flag" set,
> (although that terminology means something completely different on MBR disks.)
    
An ESP can exist on either a GPT disk or an MBR disk, but the former is much more common on EFI-based computers.

The EFI approach is much safer and much more flexible than the BIOS approach, since it doesn't tuck raw code away in weird places.
    
With ESP the boot loaders reside in files, just like OS-level programs.
This makes them easier to identify and manipulate.


# Appendix Use GNUParted Live CD or USB

1. In advanced settings choose GPT and make the storage use GPT.

2. Manage the partition scheme.

    #Note:  This is a basic partition scheme:

    sdX1 @ FAT32 partition - 512 MB
    ==== - Make 1 MB of spare space for security reasons
    sdX2 @ Ext4 - Can be the rest of the space
    ==== - Make 1 MB of spare space for security reasons
    
    #Note:  More advanced partitions using swap partitions and other filesystems like btrfs can be set up.

4. Do the partitioning.

5. Set the FAT32 to have the flag "boot"


# Appendix Network

## Find available internet interfaces

> This can be shown like eth0, enp2s0 or something else.
> This changes if there is another PCI express card added or removed.

```
ls /sys/class/net
```

## Start the wired connection.

> In this example the internet interface was named enp2s0.

```
dhcpcd enp2s0
```

```
ping -c 3 www.google.com
```

## Make the wired connection start at boot with systemd.

> In this example the internet interface was named enp2s0.

```
systemctl enable dhcpcd@enp2s0.service
```

```
systemctl start dhcpcd@enp2s0.service
```

## Install NTP to get the correct time from the internet.

```
pacman -S ntp
systemctl enable ntpd.service
```

# Appendix Fonts

```
sudo pacman -S ttf-droid noto-fonts
```

# Appendix EFI

EFI - is the boot partition, there is defined what bootloaders to boot.

efibootmgr can add or remove entries to bootloaders, where on the system they are located.

```
efibootmgr -v
```

shows the order of bootloader entries.
