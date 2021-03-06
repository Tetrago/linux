#!/usr/bin/env bash

error()
{
    printf "$1\\n" >&2
    exit 1
}

status()
{
    printf "\\033[1;32m>> $1\\033[0m\\n"
}

if [ "$(id -u)" = 0 ]; then
    error "DO NOT execute this scrip as the root user"
fi

sudo -v
( while true; do sudo -v; sleep 10; done; ) &
SUDO_PID=$!
trap "kill $SUDO_PID; sudo -k" 0

sudo pacman -S --noconfirm --needed dialog &> /dev/null

declare -a additional_software_options=(
    "libreoffice-fresh" "LibreOffice" "off"
    "code" "Open-Source Visual Studio Code" "off"
    "mpd" "Music Player Daemon" "off"
    "mpdris2" "MPD playerctl layer" "off"
    "zeal" "Office Dev Docs" "off"
    "cups" "Printer Server" "off"
    "jetbrains-toolbox" "Jetbrains Toolbox" "off"
    "okular" "Fully Featured PDF Viewer" "off"
    "clipit" "Clipboard Manager" "off"
)

dialog --colors --backtitle "\Zb\Z2Arch Setup" --title "\Zb\Z2User Environment Setup Script" --msgbox "This script will install and configure a user environment. Any existing configuration files and packages are not guaranteed to remain intact." 0 0
dialog --colors --backtitle "\Zb\Z2Arch Setup" --title "\Zb\Z2Additional Software" --ok-label "Add" --cancel-label "None" --checklist "Select any additional software you'd like to install" 0 0 0 "${additional_software_options[@]}" 2>/tmp/arch_setup
additional_software=($(cat /tmp/arch_setup))

confirm_setup()
{
    dialog --colors --backtitle "\Zb\Z2Arch Setup" --title "\Zb\Z2Procedure" --yes-label "Continue" --no-label "Abort" --yesno "You will now be prompted for root privileges." 0 0
}

confirm_setup || error "Setup script aborted"

declare -a pacman_packages=(
    "neovim"
    "git"
    "base-devel"
    "xorg-server"
    "xorg-xinit"
    "xorg-xrandr"
    "xorg-xsetroot"
    "make"
    "cmake"
    "emacs"
    "fish"
    "picom"
    "nitrogen"
    "lightdm"
    "alacritty"
    "dunst"
    "tldr"
    "man"
    "exa"
    "procs"
    "bat"
    "ripgrep"
    "fd"
    "neofetch"
    "network-manager-applet"
    "pasystray"
    "pcmanfm-gtk3"
    "lxappearance"
    "qt5ct"
    "feh"
    "xfce4-power-manager"
    "gvfs"
    "alsa-utils"
    "playerctl"
    "pulseaudio"
    "pulseaudio-alsa"
    "pavucontrol"
    "zathura"
    "zathura-pdf-mupdf"
    "thefuck"
    "ranger"
    "kmon"
    "zoxide"
    "scrot"
    "xclip"
    "acpi"
    "lightdm-slick-greeter"
    "speedcrunch"
    "numlockx"
    "ttf-dejavu"
    "ttf-liberation"
    "noto-fonts"
    "noto-fonts-emoji"
    "noto-fonts-extra"
    "ttf-font-awesome"
    "ttf-hack"
    "ttf-jetbrains-mono"
    "ttf-roboto"
    "inter-font"
    "noto-fonts-cjk"
    "lxsession"
    "light-locker"
    "man-pages"
    "arc-icon-theme"
    "arc-gtk-theme"
    "kvantum-qt5"
)

status "Installing pacman packages..."

for package in "${pacman_packages[@]}"; do
    sudo pacman -S --noconfirm --needed "$package"
done

if [ ! pacman -Qi paru > /dev/null ]; then
    status "Installing paru..."

    git clone -q https://aur.archlinux.org/paru.git $HOME/paru
    cd $HOME/paru && makepkg -si --noconfirm
    rm -rf $HOME/paru
fi

declare -a aur_packages=(
    "nerd-fonts-complete"
    "faba-icon-theme" # Needed by dunst volume controller in dwm.
    "consolas-font"
    "ttf-windows"
    "ttf-ms-fonts"
    "archlinux-wallpaper"
    "google-chrome"
    "glow"
    "ark"
    "bashtop"
    "xinit-xsession"
)

status "Installing AUR packages..."

for package in "${aur_packages[@]}"; do
    sudo paru -S --noconfirm --sudoloop "$package"
done

status "Installing additional software..."

for package in "${additional_software[@]}"; do
    sudo paru -S --noconfirm --sudoloop "$package"
done

status "Configuring lightdm..."

sudo systemctl enable lightdm
sudo sed -i 's/greeter-session=.*/greeter-session=lightdm-slick-greeter/g' /etc/lightdm/lightdm.conf
sudo sed -i 's/#greeter-session=.*/greeter-session=lightdm-slick-greeter/g' /etc/lightdm/lightdm.conf

echo -e "[Greeter]\nshow-a11y=false\ntheme-name=Arc-Dark\nicon-theme-name=Arc\nfont-name=Inter-Regular\nbackground=/usr/share/backgrounds/gnome/adwaita-day.png\nclock-format=%l:%m %p" | sudo tee /etc/lightdm/slick-greeter.conf

status "Changing shell..."

sudo chsh -s /bin/fish $USER

status "Updating mandb..."

sudo mandb

status "Updating dotfiles..."

if [ ! -d "$HOME/dotfiles" ]; then
    git clone -q --bare https://github.com/Tetrago/dotfiles.git $HOME/dotfiles
fi

git --git-dir=$HOME/dotfiles --work-tree=$HOME fetch --all
git --git-dir=$HOME/dotfiles --work-tree=$HOME reset --hard FETCH_HEAD
git --git-dir=$HOME/dotfiles --work-tree=$HOME checkout
git --git-dir=$HOME/dotfiles --work-tree=$HOME submodule update --recursive --init

status "Installing SpaceVim..."

curl -sLf https://spacevim.org/install.sh | bash

if [ ! -d "$HOME/.doom.d" ]; then
    status "Installing Doom Emacs..."

    git clone -q --depth 1 https://github.com/hlissner/doom-emacs $HOME/.emacs.d
    $HOME/.emacs.d/bin/doom -y install
fi

status "Modifying Doom Emacs configuration..."

sed -i 's/;;neotree/neotree/' "$HOME/.doom.d/init.el"
sed -i 's/;;vterm/vterm/' "$HOME/.doom.d/init.el"
sed -i 's/;;lsp/lsp/' "$HOME/.doom.d/init.el"
sed -i 's/;;make/make/' "$HOME/.doom.d/init.el"
sed -i 's/;;cc/(cc +lsp)/' "$HOME/.doom.d/init.el"
sed -i 's/;;csharp/csharp/' "$HOME/.doom.d/init.el"
sed -i 's/;;json/json/' "$HOME/.doom.d/init.el"
sed -i 's/;;javascript/javascript/' "$HOME/.doom.d/init.el"
sed -i 's/;;lua/lua/' "$HOME/.doom.d/init.el"
sed -i 's/;;php/php/' "$HOME/.doom.d/init.el"
sed -i 's/;;python/python/' "$HOME/.doom.d/init.el"
sed -i 's/;;rust/rust/' "$HOME/.doom.d/init.el"
sed -i 's/;;yaml/yaml/' "$HOME/.doom.d/init.el"

$HOME/.emacs.d/bin/doom -y sync

status "Installing Starship..."

curl -fsSL https://starship.rs/install.sh > starship_install.sh
chmod +x starship_install.sh
./starship_install.sh --yes
rm starship_install.sh

status "Building dwm..."

make -C $HOME/.dwm install

status "Building dmenu..."

make -C $HOME/.dmenu install

status "Enabling UFW..."
sudo systemctl enable ufw

status "Linking neovim..."
sudo ln -sf /usr/bin/nvim /usr/local/bin/vim

dialog --colors --title "\ZbSetup Complete" --msgbox "The setup script completed without errors." 16 60
