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
    echo "Is this ok [y]es/[n]o/[s]kip ?"
    read -r choice
    case "$choice" in
        y|yes|Y)
            return 0
            ;;

        s|skip|S)
            return 1
            ;;
        *)
            echo "Exiting..."
            exit 1
            ;;
    esac
}

apt_install() {
    if [ -x "$(command -v "$2")" ]; then
        return
    fi
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

    if confirm "I will now replace your git configuration."; then
        rm -f "$HOME/.gitconfig"
        curl -sSLo "$HOME/.gitconfig" "$dotfiles_url/home/.gitconfig"
    fi
}

sync_shell() {
    apt_install "zsh"
    yum_install "zsh"
    require_command "zsh"

    if confirm "I will now reinstall oh-my-zsh and replace your zsh configuration."; then
        rm -rf "$HOME/.oh-my-zsh"
        rm -f "$HOME/.zshrc"

        curl -sSLo "$workdir/install.sh" "https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
        chmod +x "$workdir/install.sh"
        "$workdir/install.sh" "" "--unattended"
        curl -sSLo "$HOME/.zshrc" "$dotfiles_url/home/.zshrc"

        if [ "$(basename "$SHELL")" != "zsh" ]; then
            echo "The current shell does not seem like zsh. I can fix that..."
            echo "You'll probably have to provide a password :("
            chsh -s "$(command -v zsh)"
        fi

        apt_install "tmux"
        yum_install "tmux"
        rm -f "$HOME/.tmux.conf"
        curl -sSLo "$HOME/.tmux.conf" "$dotfiles_url/home/.tmux.conf"
    fi
}

sync_node() {
    if confirm "I will now install nvm and update to the latest nodejs."; then
        eval "$(curl -sSL "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh")"
        NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install 16
        nvm use 16
        nvm alias default 16
    fi
}

sync_rust() {
    if confirm "I will now install rustup and cargo."; then
        curl -sSL "https://sh.rustup.rs" | sh -s -- --no-modify-path -y
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
}

ag_install() {
    if [ -x "$(command -v "ag")" ]; then
        return
    fi
    if [ "$os_pkg_manager" != "yum" ]; then
        return
    fi
    yum_install "pkgconfig"
    yum_install "automake"
    yum_install "gcc"
    yum_install "zlib-devel"
    yum_install "pcre-devel"
    yum_install "xz-devel"
    git clone "https://github.com/ggreer/the_silver_searcher.git" "$workdir/the_silver_searcher"
    pushd "$workdir/the_silver_searcher"
    ./build.sh
    sudo make install
    popd
}

sync_vim() {
    apt_install "vim"
    yum_install "vim"
    require_command "vim"
    sync_node

    apt_install "clangd"

    apt_install "silversearcher-ag" "ag"
    ag_install

    if confirm "I will now replace your vim configuration."; then
        rm -rf "$HOME/.vim"
        rm -f "$HOME/.vimrc"
        rm -rf "$HOME/.config/nvim"

        curl -sSLo "$HOME/.vimrc" "$dotfiles_url/home/.vimrc"
        curl -sSLo "$HOME/.config/nvim/init.vim" --create-dirs \
            "$dotfiles_url/home/.config/nvim/init.vim"
        curl -sSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

        set -- "coc-settings.json"
        for f in "$@"; do
            curl -sSLo "$HOME/.vim/$f" "$dotfiles_url/home/.vim/$f"
        done

        cargo install --git https://github.com/wgsl-analyzer/wgsl-analyzer wgsl_analyzer

        echo "This will look weird. But in 5 seconds I will start vim and set it up."
        echo "Don't worry, it will close right afterward..."
        sleep 5
        vim -c ":PlugInstall" -c ":qall!"
        vim -c ":CocInstall -sync coc-rust-analyzer" -c ":qall!"
        vim -c ":CocInstall -sync coc-clangd" -c ":qall!"
    fi
}

sync_gui() {
    if [ -z "$XDG_SESSION_TYPE" ]; then
        echo "I don't think you have a gui..."
        echo "That's it! Everything is up to date!"
        return
    fi

    if confirm "All the basic stuff is done. I can now setup the gui."; then
        sudo add-apt-repository -y ppa:papirus/papirus
        sudo add-apt-repository -y ppa:aslatter/ppa
        sudo apt-add-repository -y ppa:neovim-ppa/unstable
        sudo apt update

        apt_install "papirus-icon-theme"
        apt_install "alacritty"
        apt_install "neovim"

        papirus-folders -t Papirus-Dark -C violet

        rm -rf "$HOME/.config/alacritty"
        mkdir -p "$HOME/.config/alacritty"
        curl -sSLo "$HOME/.config/alacritty/alacritty.toml" "$dotfiles_url/home/.config/alacritty/alacritty.toml"

        rm -f "$HOME/.gtkrc-2.0"
        rm -rf "$HOME/.config/gtk-3.0"
        curl -sSLo "$HOME/.gtkrc-2.0" "$dotfiles_url/home/.gtkrc-2.0"
        curl -sSLo "$HOME/.config/gtk-3.0" "$dotfiles_url/home/.config/gtk-3.0/settings.ini"

        # set the STB background color
        gsettings set org.gnome.desktop.background picture-options 'none'
        gsettings set org.gnome.desktop.background primary-color '#554770'
    fi
    if confirm "If you're using an apple keyboard driver, I can configure it to act right on linux"; then
        echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode
        echo "options hid_apple fnmode=2" | sudo tee -a /etc/modprobe.d/hid_apple.conf
        sudo update-initramfs -u -k all
    fi
    echo "That's it! You should log out and log back in."
}

sync_bin() {
    mkdir -p "$HOME/bin"

    set -- "ssh-tunnel" "modplay"
    for f in "$@"; do
        curl -sSLo "$HOME/bin/$f" "$dotfiles_url/home/bin/$f"
        chmod +x "$HOME/bin/$f"
    done
}

require_command "curl"
sync_git
sync_shell
sync_rust
sync_vim
sync_bin
sync_gui
