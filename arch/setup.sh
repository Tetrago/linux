#!/bin/bash

echo -e "                     .__                        __                "
echo -e "_____ _______   ____ |  |__        ______ _____/  |_ __ ________  "
echo -e "\__  \\_  __ \_/ ___\|  |  \      /  ___// __ \   __\  |  \____ \ "
echo -e " / __ \|  | \/\  \___|   Y  \     \___ \\  ___/|  | |  |  /  |_> >"
echo -e "(____  /__|    \___  >___|  /____/____  >\___  >__| |____/|   __/ "
echo -e "     \/            \/     \/_____/    \/     \/           |__|    "
echo ""

base_user=${SUDO_USER:-${USER}}
base_home=$(eval echo ~$base_user)

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

as_base ()
{
  sudo -u $base_user $1
}

# --- Basic setup ---------------------------------------------------------------------------------

log_step 0 "Running basic setup processes..."

sudo -n true
set -euo pipefail

# --- Packages  -----------------------------------------------------------------------------------

log_step 0 "Installing packages from pacman..."

pacman_install ()
{
  log_list $1 "$2"
  pacman -Sq --noconfirm --needed $2 &> /dev/null
}

packages=( neovim git base-devel xorg-server make cmake emacs xmonad xmonad-contrib xmobar fish picom nitrogen lightdm alacritty xterm dmenu dunst tldr man exa procs bat ripgrep fd neofetch trayer lxsession network-manager-applet pcmanfm-gtk3 lxappearance feh xfce4-power-manager ufw slock gvfs alsa-utils playerctl pulseaudio pulseaudio-alsa )

for i in "${packages[@]}"
do
  pacman_install 1 $i
done

# --- AUR -----------------------------------------------------------------------------------------

log_step 0 "Installing AUR's..."

log_step 1 "Installing AUR helper..."

if ! command -v yay &> /dev/null
then
  log_list 2 "Cloning 'yay' repository"
  as_base "git clone -q https://aur.archlinux.org/yay.git $base_home/yay"

  log_list 2 "Building"
  cd $base_home/yay
  sudo -u $base_user makepkg -si --noconfirm &> /dev/null
  cd ..
  
  log_list 2 "Cleaning"
  rm -rf $base_home/yay
else
  log_list 2 "'yay' found, skipping..."
fi

log_step 1 "Installing AUR packages..."

yay_install ()
{
  log_list $1 "$2"
  sudo -u $base_user yay -Sq --noconfirm $2 &> /dev/null
}

packages=( caffeine-ng neovim-symlinks pnmixer archlinux-wallpaper google-chrome dtrx dmscripts-git shell-color-scripts )

for i in "${packages[@]}"
do
  yay_install 2 $i
done

# --- Confirguring lightdm ------------------------------------------------------------------------

log_step 0 "Configuring lightdm..."

log_list 1 "Enabling display manager"
systemctl enable lightdm &> /dev/null

log_list 1 "Installing packages"
pacman_install 2 lightdm-webkit2-greeter
pacman_install 2 lightdm-webkit-theme-litarvan

log_list 1 "Modifing configuration"
sed -i 's/greeter-session=.*/greeter-session=lightdm-webkit2-greeter/g' /etc/lightdm/lightdm.conf
sed -i 's/#greeter-session=.*/greeter-session=lightdm-webkit2-greeter/g' /etc/lightdm/lightdm.conf
sed -i 's/webkit_theme.*/webkit_theme=litarvan/g' /etc/lightdm/lightdm-webkit2-greeter.conf

# --- Replicating configuration ------------------------------------------------------------------

log_step 0 "Replicating configuration..."

log_list 1 "Changing shell"
chsh -s /bin/fish $base_user &> /dev/null

if [ ! -d "$base_home/dotfiles" ]
then
  log_list 1 "Cloning dotfiles"
  as_base "git clone -q --bare https://github.com/Tetrago/dotfiles.git $base_home/dotfiles"
else
  log_list 1 "'dotfiles' found, skipping clone"
fi

git_cmd="git --git-dir=$base_home/dotfiles --work-tree=$base_home"

log_list 1 "Checkout dotfiles"
as_base "$git_cmd fetch --all"
as_base "$git_cmd reset --hard"
as_base "$git_cmd checkout"

# --- Installing SpaceVim -------------------------------------------------------------------------

log_step 0 "Installiong SpaceVim..."

sudo -u $base_user curl -sLf https://spacevim.org/install.sh | sudo -u $base_user bash

# --- Installing Doom Emacs -----------------------------------------------------------------------

log_step 0 "Installing Doom Emacs..."

if [ ! -d "$base_home/.doom.d" ]
then
  log_list 1 "Cloning"
  as_base "git clone -q --depth 1 https://github.com/hlissner/doom-emacs $base_home/.emacs.d"

  log_list 1 "Installing"
  as_base "$base_home/.emacs.d/bin/doom -y install"
else
  log_list 1 "'.doom.d' found, skipping"
fi

init_el="$base_home/.doom.d/init.el"

log_list 1 "Modifing configuration"
sed -i 's/;;neotree/neotree/' ${init_el}
sed -i 's/;;vterm/vterm/' ${init_el}
sed -i 's/;;make/make/' ${init_el}
sed -i 's/;;cc/cc/' ${init_el}
sed -i 's/;;csharp/csharp/' ${init_el}
sed -i 's/;;json/json/' ${init_el}
sed -i 's/;;javascript/javascript/' ${init_el}
sed -i 's/;;lua/lua/' ${init_el}
sed -i 's/;;php/php/' ${init_el}
sed -i 's/;;python/python/' ${init_el}
sed -i 's/;;rust/rust/' ${init_el}
sed -i 's/;;yaml/yaml/' ${init_el}

log_list 1 "Syncing"
as_base "$base_home/.emacs.d/bin/doom -y sync"

# --- Installing Starship -------------------------------------------------------------------------

log_step 0 "Installing Starship..."

log_list 1 "Fetching installer"
curl -fsSL https://starship.rs/install.sh > starship_install.sh

log_list 1 "Making executable"
chmod +x starship_install.sh

log_list 1 "Installing"
as_base "./starship_install.sh --yes"

log_list 1 "Cleaning"
rm starship_install.sh

# --- Remaining settings --------------------------------------------------------------------------

log_step 0 "Remaining settings..."

log_list 1 "Enabling UFW"
systemctl enable ufw

# --- Finializing setup process -------------------------------------------------------------------

log_step 0 "Finializing setup..."

echo -e "          _                                 _     _       "
echo -e "  ___ ___| |_ _  _ _ __   __ ___ _ __  _ __| |___| |_ ___ "
echo -e " (_-</ -_)  _| || | '_ \ / _/ _ \ '  \| '_ \ / -_)  _/ -_)"
echo -e " /__/\___|\__|\_,_| .__/ \__\___/_|_|_| .__/_\___|\__\___|"
echo -e "                  |_|                 |_|                 "
