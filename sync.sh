#!/bin/sh

set -e

dotfiles_url="https://raw.githubusercontent.com/lavignes/dotfiles/mainline"
workdir="$(mktemp -d)"
echo "The temp working directory will be $workdir"

require_command() {
    if ! [ -x "$(command -v "$1")" ]; then
        echo "Couldn't find $1 on your system. I cannot continue..."
        exit 1
    fi
}

if [ -x "$(command -v "apt")" ]; then
    os_pkg_manager="apt"
fi

if [ -x "$(command -v "yum")" ]; then
    os_pkg_manager="yum"
fi

confirm() {
    echo "$1" 
    echo "Is this ok (y/n)?"
    read -r choice
    case "$choice" in 
        y|yes|Y)
            ;;

        *)
            echo "Exiting..."
            exit 1
            ;;
    esac
}

apt_install() {
    if [ -x "$(command -v "$1")" ]; then
        return
    fi
    if [ "$os_pkg_manager" != "apt" ]; then
        return
    fi
    echo "Couldn't find $1. I'll try to install it..."
    sudo apt -y install "$1"
}

yum_install() {
    if [ -x "$(command -v "$1")" ]; then
        return
    fi
    if [ "$os_pkg_manager" != "yum" ]; then
        return
    fi
    echo "Couldn't find $1. I'll try to install it..."
    sudo yum -y install "$1"
}

sync_git() {
    apt_install "git"
    yum_install "git"
    require_command "git"

    confirm "I will now replace your git configuration."
    
    rm -f "$HOME/.gitconfig"
    curl -sSLo "$HOME/.gitconfig" "$dotfiles_url/home/.gitconfig"
}

sync_shell() {
    apt_install "zsh"
    yum_install "zsh"
    require_command "zsh"
 
    confirm "I will now reinstall oh-my-zsh and replace your zsh configuration."

    rm -rf "$HOME/.oh-my-zsh" 
    rm -f "$HOME/.zshrc"

    curl -sSLo "$workdir/install.sh" "https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    chmod +x "$workdir/install.sh"
    "$workdir/install.sh" "" "--unattended"
    curl -sSLo "$HOME/.zshrc" "$dotfiles_url/home/.zshrc"

    if [ "$(basename "$SHELL")" != "zsh" ]; then
        echo "The current shell does not seem like zsh. I can fix that..."
        echo "You'll probably have to provide a password :("
        chsh -s "$(which zsh)"
    fi
}

sync_node() {
    confirm "I will now install nvm and update to the latest nodejs."
    
    eval "$(curl -sSL "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh")"
    NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install node
    nvm use node
    nvm alias default node
}

sync_vim() {
    apt_install "vim"
    yum_install "vim" 
    sync_node

    confirm "I will now replace your vim configuration."
    rm -rf "$HOME/.vim"
    rm -f "$HOME/.vimrc"

    curl -sSLo "$HOME/.vimrc" "$dotfiles_url/home/.vimrc"
    curl -sSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    echo "This will look weird. But in 5 seconds I will start vim and set it up."
    echo "Don't worry, it will close right afterward..."
    sleep 5
    vim -c ":PlugInstall" -c ":qall!"
    vim -c ":CocInstall -sync coc-rust-analyzer" -c ":qall!"
}

install_picom() {
    if [ -x "$(command -v "picom")" ]; then
        return
    fi

    apt_install "build-essential"
    apt_install "ninja-build"
    apt_install "meson"

    apt_install "libxext-dev"
    apt_install "libxcb1-dev"
    apt_install "libxcb-damage0-dev"
    apt_install "libxcb-xfixes0-dev"
    apt_install "libxcb-shape0-dev"
    apt_install "libxcb-render-util0-dev"
    apt_install "libxcb-render0-dev"
    apt_install "libxcb-randr0-dev"
    apt_install "libxcb-composite0-dev"
    apt_install "libxcb-image0-dev"
    apt_install "libxcb-present-dev"
    apt_install "libxcb-xinerama0-dev"
    apt_install "libxcb-glx0-dev"
    apt_install "libpixman-1-dev"
    apt_install "libdbus-1-dev"
    apt_install "libconfig-dev"
    apt_install "libgl1-mesa-dev"
    apt_install "libpcre2-dev"
    apt_install "libpcre3-dev"
    apt_install "libevdev-dev"
    apt_install "uthash-dev"
    apt_install "libev-dev"
    apt_install "libx11-xcb-dev"
    
    git clone "https://github.com/yshui/picom.git" "$workdir/picom"
    thisdir="$(pwd)"
    cd "$workdir/picom"
    git submodule update --init --recursive
    meson --buildtype=release . build
    ninja -C build
    sudo ninja -C build install
    cd "$thisdir"
}

install_qtile() {
    apt_install "libxcb-render0-dev"
    apt_install "libpangocairo-1.0-0"
    apt_install "python3-pip"
    
    pip install dbus-next
    pip install xcffib
    pip install cairocffi
    git clone "git://github.com/qtile/qtile.git" "$workdir/qtile"
    pip install "$workdir/qtile"
}

sync_gui() {
    if [ -z "$XDG_SESSION_TYPE" ]; then
        echo "I don't think you have a gui..."
        return 
    fi

    confirm "All the basic stuff is done. I can now setup the gui."

    sudo add-apt-repository -y ppa:papirus/papirus
    sudo add-apt-repository -y ppa:agornostal/ulauncher
    sudo add-apt-repository -y ppa:aslatter/ppa
    sudo apt update
    
    install_picom
    install_qtile

    apt_install "alacritty"
    apt_install "papirus-icon-theme"
    apt_install "i3lock-fancy"
    apt_install "network-manager-gnome"
    apt_install "pavucontrol"
    apt_install "volumeicon-alsa"
    apt_install "ulauncher"
    apt_install "cbatticon"
    apt_install "arandr"
    apt_install "autorandr"
    apt_install "dunst"

    rm -rf "$HOME/.themes/Nordic-darker"
    curl -sSLo "$workdir/Nordic-darker.tar.xz" "https://github.com/EliverLara/Nordic/releases/download/2.0.0/Nordic-darker.tar.xz"
    mkdir -p "$HOME/.themes"
    tar xf "$workdir/Nordic-darker.tar.xz" -C "$HOME/.themes"

    rm -f "$HOME/.config/gtk-2.0/settings.ini"
    rm -f "$HOME/.config/gtk-3.0/settings.ini"
    curl -sSLo "$HOME/.config/gtk-2.0/settings.ini" \
        --create-dirs "$dotfiles_url/home/.config/gtk-2.0/settings.ini"
    curl -sSLo "$HOME/.config/gtk-3.0/settings.ini" \
        --create-dirs "$dotfiles_url/home/.config/gtk-3.0/settings.ini"
    
    rm -rf "$HOME/.config/qtile"
    curl -sSLo "$HOME/.config/qtile/config.py" \
        --create-dirs "$dotfiles_url/home/.config/qtile/config.py"
    curl -sSLo "$HOME/.config/qtile/autostart.sh" \
        --create-dirs "$dotfiles_url/home/.config/qtile/autostart.sh"
    chmod +x "$HOME/.config/qtile/autostart.sh"
  
    sudo rm -f /usr/share/xsessions/qtile.desktop
    sudo curl -sSLo /usr/share/xsessions/qtile.desktop \
        --create-dirs "$dotfiles_url/usr/share/xsessions/qtile.desktop"

    rm -rf "$HOME/.config/volumeicon"
    curl -sSLo "$HOME/.config/volumeicon/volumeicon" \
        --create-dirs "$dotfiles_url/home/.config/volumeicon/volumeicon"

    rm -rf "$HOME/.config/alacritty"
    curl -sSLo "$HOME/.config/alacritty/alacritty.yml" \
        --create-dirs "$dotfiles_url/home/.config/alacritty/alacritty.yml"

    rm -rf "$HOME/.config/dunst/dunstrc"
    curl -sSLo "$HOME/.config/dunst/dunstrc" \
        --create-dirs "$dotfiles_url/home/.config/dunst/dunstrc"

    rm -f "$HOME/.Xresources"
    curl -sSLo "$HOME/.Xresources" "$dotfiles_url/home/.Xresources"
}

require_command "curl"
sync_git
sync_shell
sync_vim
sync_gui

echo "That's it! You should log out and log back in to qtile."
