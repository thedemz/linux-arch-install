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

    EFI boot loaders are not stored:
    
        in the Master Boot Record - MBR,
        in officially-unallocated post-MBR sectors,
        or in BIOS Boot Partitions.
    
    GParted and parted identify the ESP as having its "boot flag" set,
    (although that terminology means something completely different on MBR disks.)
    
    An ESP can exist on either a GPT disk or an MBR disk,
    but the former is much more common on EFI-based computers.
    
    The EFI approach is much safer and much more flexible than the BIOS approach,
    since it doesn't tuck raw code away in weird places.
    
    With ESP the boot loaders reside in files, just like OS-level programs.
    This makes them easier to identify and manipulate.

#### ===================================================================

### Use GNUParted Live CD or USB. ###

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

### Using GNU Parted ###

    Parted has two modes: command line and interactive. Parted should always be started with:
    
$   parted device

    where device is the hard disk device to edit (for example /dev/sda).
    If you omit the DEVICE argument, Parted will attempt to guess which device you want.
    
Interactive mode
In interactive mode, commands are entered one at a time at a prompt, and modify the disk immediately.

For example:

    (parted) mklabel gpt
    (parted) mkpart P1 ext3 1MiB 8MiB     
    
    Create a mebibyte partition {+1MiB with gdisk) on the disk with no file system and type ef02 (or bios_grub in parted).

    parted /dev/hda
    set 1 boot on
    quit
    
# Installing Arch Linux

## 1. Show the storage medias.

Find the sdX name of the storage media that was partitioned with GPT. In this guide the X = a

```
fdisk -l
```

## 2. Mount the partitions.

First the main storage partition then the boot partition referred as the $esp.

```
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
```

> The simplest option is to mount it at /boot, since this allows pacman to directly
> update the kernel that the EFI firmware will read.

> If the ESP is other than /boot then you need to set up a copy hook when
> pacman updates the kernel in the future. https://wiki.archlinux.org/index.php/EFISTUB

> `grub-install --target=x86_64-efi --efi-directory=/boot`
> will install on the location `/boot/EFI`


 ## 3. Check that there is an internet connection.

 `ping -c 3 www.google.com`


 ## 4. Dowload the base installation on the storage partition.

```
pacstrap /mtn base linux linux-firmware
```

> `pacstrap /mnt grub-efi-x86_64 efibootmgr`


## 5. Create a file system table.

```
genfstab -p /mnt >> /mnt/etc/fstab
```

## 6. SSD

Then add the discard option to /mnt/etc/fstab
    
```
vim /mnt/etc/fstab
```

```
/dev/sda1  /       ext4   defaults,noatime,discard   0  1
/dev/sda2  /home   ext4   defaults,noatime,discard   0  2
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
cp /mnt/EFI/GRUB/grubx64.efi /mnt/EFI/BOOT/bootx64.efi
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






11. Set a password for the root.

passwd


12. Install Wired Connection and other tools.

```
pacmam -S dhcpcd ntp sudo vim
```

13. Create a new user with sudo rights.

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


14. Exit the arch-root user.

```
exit
```

15. Unmount the storage media.

```
umount -R /mnt/boot /mnt
```

16. Reboot the computer with the systemd command.

```
systemctl reboot
```

### Configure Arch Linux

1. Set a hostname with sytemd. The name of the computer in this example it is set to box.

$   hostnamectl set-hostname box

2. Find the right timezone.

$   cd /usr/share/zoneinfo
$   ls -al

    #Note: This lists available zones and each have subzones.

3. Set the timezone. In this example the zone is US and the subzone is Pacific.

$   timedatectl set-timezone US/Pacific

    #Note: Europe/Stockholm

4. Set the locale. The info about the language and keyboardlayout to be used.

$   vi  /etc/locale.gen

    Uncomment the lines corresponding to the encoding and the language that can be used on the system.
    In this example the encoding is UTF-8 and the language is en_US.

$   locale-gen

$   localectl set-locale LANG="en_US.UTF-8"

5. Find available internet interfaces. This can be shown like eth0, enp2s0 or something else.

    #Note: This changes if there is another PCI express card added or removed.

$   ls /sys/class/net

6. Start the wired connection. In this example the internet interface was named enp2s0.

$   dhcpcd enp2s0

$   ping -c 3 www.google.com

7. Make the wired connection start at boot with systemd. In this example the internet interface was named enp2s0.

$   systemctl enable dhcpcd@enp2s0.service

$   systemctl start dhcpcd@enp2s0.service

8. Install NTP to get the correct time from the internet.

$   pacman -S ntp

$   systemctl enable ntpd.service

9. Reboot the system

$   systemctl reboot


### Add a new user

    #Note:  To add a new user, use the useradd command.
    #       useradd -m -g [initial_group] -G [additional_groups] -s [login_shell] [username]

1. Adding a user named archie specifying bash as the login shell.

$   useradd -m -s /bin/bash archie

    #Note:  To later add the user to other groups use.
    #       usermod -aG [additional_groups] [username]

### ###############################################
### Make the user able to use sudo
### ###############################################

1. Install sudo.

$   pacman -S sudo

2. Use visudo to alter the sudo file /etc/sudoers.

$   visudo

    #Note: Add the line. Where USER_NAME is the name of the user.

>   USER_NAME   ALL=(ALL) ALL

### ############################################
#E# Install graphical interfaces

    X11 server
    GNOME Desktop environment

### ############################################

1. Install X.

$   pacman -S xorg-server xorg-server-utils xorg-xinit xterm

2. Install mesa graphics driver.

$   pacman -S mesa

3. Check available video cards.

$   lspci | grep VGA

4. Show a list of available drivers.

$   pacman -Ss xf86-video | less

5. Install vesa driver | intel driver | ati driver.

#NOTE:  The default graphics driver is xf86-video-vesa, which handles a large number of chipsets
#       but does not include any 2D or 3D acceleration.
#       If a better driver cannot be found or fails to load, Xorg will fall back to vesa.

$   pacman -S xf86-video-vesa

$   pacman -S xf86-video-intel

$   pacman -S xf86-video-ati

##6.  Install some basic X applications.
##
##$   pacman -S xorg-twm xorg-xclock xterm

7X. If Xorg was installed before creating the non-root user
    there will be a template .xinitrc file in your home directory
    that needs to be either deleted or commented out.

$   rm ~/.xinitrc

7. Test the X11 environment

$   startx

$   exit

7X. If exit doesnt work try

$   pkill X
$   reboot

8. Install Gnome 3 desktop environment.

$   pacman -S gdm gnome-shell gnome-control-center gnome-tweak-tool

$   systemctl enable gdm.service

$   systemctl start gdm.service



### ##############################################
### Install web browser and get info files
### ##############################################

1. Install gnome web browser.

$   pacman -S epiphany

2. Install git and vim.

$   pacman -S git vim

3. Get the linux-arch-install repository

$   cd
$   git clone https://github.com/thedemz/linux-arch-install


### Install fonts

ttf-droid
noto-fonts

### ############################################
#F# Partition examples
### ############################################


Use GParted live disk for GPT disks.

a) download from http://sourceforge.net/projects/gparted/
b) then write the .iso to CD or USB.
c) Documentation http://gparted.org/documentation.php


#####
/boot 512 MB - Set flag bootable 
#####
This will be used for thee bootloader GRUB2 or syslinux etc.

#####
/
#####
The main partition where the systemfiles will be stored.

#####
/home
#####
The main partition where the users files are to be stored.

#####
/swap
#####
If the system have more than 8 GB om RAM, this partition is mostly not needed. Can be replaced by a file instead in another partition if skipped, this option is easier to resize also. If this partition is wanted the size is often recomended to be twice as large as the available RAM.
MBR partition:  mkswap /dev/sdXY
            swapon /dev/sdXY
            swapon -s

#####
/var 12288 MB
#####
This node stores cache files such as logs. Often frequent read and writes. Place this on a disk hard drive to spare the SSD. 

#####
/tmp
#####



### ############################################
#G# SSD - Solid State Disk
### ############################################

A Trim command (commonly typeset as TRIM) allows an operating system to inform a solid-state drive (SSD)
which blocks of data are no longer considered in use and can be wiped internally.

Most SSDs support the ATA_TRIM command for sustained long-term performance and wear-leveling.

As of linux kernel version 3.7, the following filesystems support TRIM:

    Ext4
    Btrfs
    JFS
    XFS


Using partitions that are aligned with the erase block size is highly recommended.
In past, this required manual calculation and intervention when partitioning.

Many of the common partition tools handle partition alignment automatically
(assuming users are using an up-to-date version):

    fdisk
    gdisk
    gparted
    parted


1. Verify a partition is aligned, query it using /usr/bin/blockdev as shown below

if a '0' is returned, the partition is aligned:

$   blockdev --getalignoff /dev/sdX

>   0


2. Verify TRIM Support

$   hdparm -I /dev/sda | grep TRIM

>   Data Set Management TRIM supported (limit 1 block)
>   Deterministic read data after TRIM

The output could be limit 1 block or limit 8 block

3. Enable TRIM by Mount Flags

Using this flag in one's /etc/fstab enables the benefits of the TRIM command

Edit /etc/fstab and add the discard option for the SDD partitions:

>   /dev/sda1  /       ext4   defaults,noatime,discard   0  1
>   /dev/sda2  /home   ext4   defaults,noatime,discard   0  2


4. Check that the SSD have the latest firmware to further improve the lifetime of the storage media.


### ###################################################
#H# Dual boot, like windows or more OS:es
### ###################################################

1. To make grub automatically add other systems to boot meny install os-prober

$   pacman -S os-prober

2. regenerate the grub config

$   grub-mkconfig -o /boot/efi/EFI/GRUB/grub.cfg

    #Note:  for BIOS system
    #$      grub-mkconfig -o /boot/grub/grub.cfg
    
### ###################################################    
### How GRUB 2 works
### ###################################################

GRUB 2 works like this:

/etc/default/grub contains customization;

/etc/grub.d/ scripts contain GRUB menu information and operating system boot scripts.

When the grub-mkconfig command is run,
it reads the contents of the grub file and the grub.d scripts and creates the grub.cfg file.

That's all.

### ###################################################    
### /etc/grub.d/ scripts
### ###################################################

Let's review the scripts:

00_header           The script that loads GRUB settings from /etc/default/grub,
                    including timeout, default boot entry, and others.

05_debian_theme     Defines the background, colors and themes.
                    The name of this script is definitely going to change,
                    when other distributions adopt GRUB 2.

10_linux            Loads the menu entries for the installed distribution.

20_memtest86+       Loads the memtest utility.

30_os-prober        Is the script that will scan the hard disks for other operating systems
                    and add them to the boot menu.

40_custom           Is a template that you can use to create additional entries to be added to the boot menu.

The numbering in the script names is somewhat similar to the order of Start/Kill scripts used in different runlevels.

The numbering defines precedence.
This means that 10_linux will be executed before 20_memtest86+ and therefore placed higher in the boot menu order.

Be very careful when working with these scripts!
Like the grub.cfg file, they are not intended to be edited, save custom edits for the 40_custom script.





### ###########################################################
#I# Troubleshooting
### ############################################################

?   Can not run fsck on a separate /usr partition

1. Make sure you have the required hooks in

/etc/mkinitcpio.conf

   #Note: Remembered to re-generate your initramfs image after editing this file.

2. Check your fstab file!

    #Note:  Only the root partition needs "1" at the end.
    #       Everything else should have either "2" or "0".
    
    
?   There are times (due to power failure) in which an ext(3/4) file system can corrupt beyond normal repair.
?   Normally, there will be a prompt from fsck indicating that it cannot find an external journal.

1. Unmount the partition based on its directory

$   umount <directory>

    #Note:  finde the mounted partitions and their directories with
    #$      #TODO
    
2. Write a new journal to the partition

$   tune2fs -j /dev/<partition>

3. Run an fsck to repair the partition

$   fsck -p /dev/<partition>


### ##########################################################
#J# Tips
### ##########################################################

Changing the fsck check frequency to 20

$   tune2fs -c 20 /dev/sda1

    #Note:  In this example, 20 is the number of boots between two checks.
    #       If set to 1 makes it scan at every boot, while 0 would stop scanning altogether.

To see the frequency number and the current mount count for a specific partition

$   dumpe2fs -h /dev/sda1 | grep -i 'mount count'


### EFI

EFI - is the boot partition, there is defined what bootloaders to boot.

efibootmgr can add or remove entries to bootloaders, where on the system they are located.

efibootmgr -v

shows the order of bootloader entries.

EFI/BOOT/bootx64.efi
EFI/Microsoft/Boot/bootmgfw.efi

http://www.rodsbooks.com/efi-bootloaders/installation.html#alternative-naming







### Bootloader configuration

This should be in some FAQ. Obviously, your /boot partition or bootloader is not configured properly. Thus, during update, the new kernel is installed, but not to the place where your bootloader looks for it. Thus, you boot the old kernel, but your hard drive only has the new modules.

Your inability to mount vfat partitions is only one of many failures that you will see until you fix this.
It might be advisable for people on EFI systems to add vfat to their MODULES array in mkinitcpio.conf, so that when this happens, they can still mount their ESP and sync the correct kernel+initrd.

mkinitcpio, defaults to place vmlinux and .img files in /boot.


