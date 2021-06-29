# Arch

## Installing Arch

### User-required Setup

Go through the basic installation process for Arch:
1. Check for UEFI boot: `ls /sys/firmware/efi/efivars`
2. `timedatectl set-ntp true`
3. Partition your drive(s)
    - Create the filesystems
        - `mkfs.ext4`
        - `mkswap`
        - `swapon`
     - Make sure to create 550M EFI partition if booting with UEFI
        - `mkfs.fat -F32`
4. `mount /dev/root_partition /mnt`
5. `pacstrap /mnt base linux linux-firmware`
6. `genfstab -U /mnt >> /mnt/etc/fstab`
7. `arch-chroot /mnt`

### Installation

Execute the installation script:

1. Add your hostname to `/etc/hostname`
2. `curl -sLf https://raw.githubusercontent.com/Tetrago/linux/master/arch/install.sh | bash`

Setup users:
1. `passwd`
2. `useradd -m [user]`
3. `usermod -aG wheel,optical,video,audio,storage [user]`
4. `passwd [user]`

Setup grub:

- BIOS
    1. `grub-install /dev/sda`
        - This may vary when using UEFI
    2. `grub-mkconfig -o /boot/grub/grub.cfg`

- UEFI
    1. Install `efibootmgr`, `dosfstools`, `os-prober`, and `mtools`
    2. `mkdir /boot/EFI`
    3. `mount /dev/efi_partition /boot/EFI`
    4. `grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck`
    5. `grub-mkconfig -o /boot/grub/grub.cfg`
    6. `umount /boot/EFI`

Quit:
1. `exit`
2. `umount /mnt`
3. `shutdown now`

### Post-installation Setup

After rebooting, execute the setup script:

`curl -sLf https://raw.githubusercontent.com/Tetrago/linux/master/arch/setup.sh | sudo bash`

Beware that XDG Autostart make cause tray icons to run twice. [Arch Wiki](https://wiki.archlinux.org/title/XDG_Autostart)

### Managing dotfiles

Dotfiles can be updated:
- `dotfiles pull`
- `dotfiles checkout`
