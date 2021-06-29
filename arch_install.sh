#!/bin/bash

echo -e "                     .__         .__                 __         .__  .__   "
echo -e "_____ _______   ____ |  |__      |__| ____   _______/  |______  |  | |  |  "
echo -e "\__  \\_  __ \_/ ___\|  |  \     |  |/    \ /  ___/\   __\__  \ |  | |  |  "
echo -e " / __ \|  | \/\  \___|   Y  \    |  |   |  \\___ \  |  |  / __ \|  |_|  |__"
echo -e "(____  /__|    \___  >___|  /____|__|___|  /____  > |__| (____  /____/____/"
echo -e "     \/            \/     \/_____/       \/     \/            \/           "
echo ""

base_user=${SUDO_USER:-${USER}}
base_home=$(eval echo ~$base_user)

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_CYAN='\033[0;36m'
COLOR_NONE='\033[0m'

printf_space ()
{
  for i in $(seq $1)
  do
    echo -n "  "
  done
}

log_step ()
{
  printf_space $1
  echo -e "$COLOR_GREEN> $2$COLOR_NONE"
}

log_list ()
{
  printf_space $1
  echo -e "$COLOR_CYAN- $2$COLOR_NONE"
}

# --- Basic setup ---------------------------------------------------------------------------------

log_step 0 "Running basic setup processes..."

set -euo pipefail

# --- Syncing system clock ------------------------------------------------------------------------

log_step 0 "Syncing system clock..."

log_list 1 "Creating symlink to zoneinfo"
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

log_list 1 "Setting hardware clock"
hwclock --systohc

log_list 1 "Enabling NTP"
timedatectl set-ntp true

# --- Localization --------------------------------------------------------------------------------

log_step 0 "Managing localization..."

log_list 1 "Modifying locale.gen"
sed -i  's/#en_US.UTF-8 UTF-8/#en_US.UTF-8 UTF-8/' /etc/locale.gen

log_list 1 "Running locale generation"
locale-gen &> /dev/null

log_list 1 "Modifying locale.conf"
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# --- Network Management --------------------------------------------------------------------------

log_step 0 "Setting up networking..."

hostname=$(cat /etc/hostname)

log_list 1 "Modifying hosts"
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

log_list 1 "Installing networkmanager"
pacman -Sq --noconfirm --needed networkmanager &> /dev/null

log_list 1 "Enabling networking service"
systemctl enable NetworkManager &> /dev/null

# --- User management -----------------------------------------------------------------------------

log_step 0 "User management..."

log_list 1 "Installing sudo"
pacman -Sq --noconfirm --needed sudo &> /dev/null

log_list 1 "Editing sudoers file"
sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers

# --- Boot ----------------------------------------------------------------------------------------

log_step 0 "Installing GRUB..."
pacman -Sq --noconfirm grub &> /dev/null

echo ""
echo -e "  _         _        _ _                     _     _       "
echo -e " (_)_ _  __| |_ __ _| | |  __ ___ _ __  _ __| |___| |_ ___ "
echo -e " | | ' \(_-<  _/ _` | | | / _/ _ \ '  \| '_ \ / -_)  _/ -_)"
echo -e " |_|_||_/__/\__\__,_|_|_| \__\___/_|_|_| .__/_\___|\__\___|"
echo -e "                                       |_|                 "
