#!/bin/bash

set -e

dotfiles_url="https://raw.githubusercontent.com/lavignes/dotfiles/mainline"
workdir="$(mktemp -d)"
echo "The temp working directory will be $workdir"

is_command() {
    if [ -x "$(command -v "$1")" ]; then
        return 1
    fi
    return 0
}

require_command() {
    if [ "$(is_command "$1")" -eq "1" ]; then
        echo "Couldn't find $1 on your system. I cannot continue..."
        exit 1
    fi
}

if [ "$(is_command "apt")" -eq "1" ]; then
    os_pkg_manager="apt"
fi

if [ "$(is_command "yum")" -eq "1" ]; then
    os_pkg_manager="yum"
fi

confirm() {
    echo "$1" 
    read -rp "Is this ok (y/n)?" choice
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
    if [ "$(is_command "$1")" -eq "1" ]; then
        return
    fi
    if ! [ "$os_pkg_manager" -eq "apt" ]; then
        return
    fi
    echo "Couldn't find $1. I'll try to install it..."
    sudo apt -y install "$1"
}

yum_install() {
    if [ "$(is_command "$1")" -eq "1" ]; then
        return
    fi
    if ! [ "$os_pkg_manager" -eq "yum" ]; then
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

    if ! [ "$(basename "$SHELL")" -eq "zsh" ]; then
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

sync_gui() {
    if [ -z "$XDG_SESSION_TYPE" ]; then
        echo "I don't think you have a gui..."
        return 
    fi

    confirm "All the basic stuff is done. I can now setup the gui."

    sudo add-apt-repository -y ppa:papirus/papirus
    sudo apt update
    
    apt_install "libxcb-render0-dev"
    apt_install "libpangocairo-1.0-0"

    apt_install "picom"
    apt_install "papirus-icon-theme"
    apt_install "network-manager-gnome"
    apt_install "alsamixer"
    apt_install "volumeicon-alsa"
    apt_install "ulauncher"

    confirm "I'm going to install the desktop environment."

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
    pip install dbus-next
    pip install cairocffi
    pip install xcffib
    git clone "git://github.com/qtile/qtile.git" "$workdir/qtile"
    pip install "$workdir/qtile"
    curl -sSLo "$HOME/.config/qtile/config.py" \
        --create-dirs "$dotfiles_url/home/.config/qtile/config.py"
    curl -sSLo "$HOME/.config/qtile/autostart.sh" \
        --create-dirs "$dotfiles_url/home/.config/qtile/autostart.sh"
    chmod +x "$dotfiles_url/home/.config/qtile/autostart.sh"
   
    rm -rf "$HOME/.config/volumeicon"
    curl -sSLo "$HOME/.config/volumeicon/volumeicon" \
        --create-dirs "$dotfiles_url/home/.config/volumeicon/volumeicon"
    
    rm -f "$HOME/.Xresources"
    curl -sSLo "$HOME/.Xresources" "$dotfiles_url/home/.Xresources"
}

if [ "$(sudo -n true)" -eq "0" ]; then
    echo "You aren't able to run commands as root right now."
    echo "I need you to provide your password upfront to save time later."
    sudo -v
    echo "OK. Let's start..."
fi

require_command "finger"
require_command "curl"
sync_shell
sync_git
sync_vim
sync_gui

echo "That's it! You should log out and log back in to qtile."