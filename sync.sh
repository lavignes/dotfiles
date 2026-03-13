#!/bin/sh

set -e

dotfiles_url="https://raw.githubusercontent.com/lavignes/dotfiles/mainline"
workdir="$(mktemp -d)"
curdir="$(pwd)"
echo "The temp working directory will be $workdir"

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib64:$LD_LIBRARY_PATH"

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

sync_gcc() {
    if [ "$os_pkg_manager" = "apt" ]; then
        return
    fi
    if [ -x "$HOME/.local/bin/gcc" ]; then
        return
    fi

    yum_install "texinfo"

    git clone --depth 1 --branch binutils-2_44 \
        "https://sourceware.org/git/binutils-gdb.git" "$workdir/binutils"
    cd "$workdir/binutils"
    mkdir build && cd build
    CC=gcc10-gcc CXX=gcc10-g++ ../configure --prefix="$HOME/.local" \
        --disable-gprofng --disable-gdb --disable-gdbserver
    make -j
    make install
    cd "$curdir"

    git clone --depth 1 --branch releases/gcc-15 \
        "https://gcc.gnu.org/git/gcc.git" "$workdir/gcc"
    cd "$workdir/gcc"
    ./contrib/download_prerequisites
    mkdir build && cd build
    CC=gcc10-gcc CXX=gcc10-g++ ../configure --prefix="$HOME/.local" \
        --enable-languages=c,c++ --disable-multilib --disable-bootstrap
    make -j
    make install
    cd "$curdir"
}

sync_node() {
    if confirm "I will now install nvm and update to the latest nodejs."; then
        curl -sSL "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh" | bash
        NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        if [ "$os_pkg_manager" = "apt" ]; then
            nvm install 24
            nvm use 24
            nvm alias default 24
            return
        fi

        nvm install 16
        nvm use 16
        nvm alias default 16
        #
        #if ! [ -x "$(command -v "node")" ]; then
        #    git clone --depth 1 --branch "v24.14.0" \
        #        "https://github.com/nodejs/node.git" "$workdir/node"
        #    cd "$workdir/node"
        #    CC="$HOME/.local/bin/gcc" CXX="$HOME/.local/bin/g++" \
        #        ./configure --prefix="$HOME/.nvm/versions/node/v24.10.0"
        #    make -j
        #    make install
        #    cd "$curdir"
        #fi
    fi
}

sync_rust() {
    if confirm "I will now install rustup and cargo."; then
        curl -sSL "https://sh.rustup.rs" | sh -s -- --no-modify-path -y
    fi
}

alacritty_install() {
    if [ -x "$(command -v "alacritty")" ]; then
        return
    fi
    apt_install "cmake"
    apt_install "g++"
    apt_install "pkg-config"
    apt_install "libfontconfig1-dev"
    apt_install "libxcb-xfixes0-dev"
    apt_install "libxkbcommon-dev"
    apt_install "python3"
    apt_install "libegl1-mesa-dev"
    git clone --depth 1 "https://github.com/alacritty/alacritty.git" "$workdir/alacritty"
    cd "$workdir/alacritty"
    cargo build --release
    if ! infocmp alacritty; then
        sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
    fi
    sudo cp target/release/alacritty /usr/local/bin
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
    cd "$curdir"
}

sync_cmake() {
    if [ "$os_pkg_manager" = "apt" ]; then
        apt_install "libssl-dev"
        apt_install "cmake"
        return
    fi
    if [ -x "$(command -v "$HOME/.local/bin/cmake")" ]; then
        return
    fi

    yum_install "perl-core"

    if ! [ -x "$(command -v "$HOME/.local/bin/openssl")" ]; then
        git clone --depth 1 "https://github.com/openssl/openssl.git" "$workdir/openssl"
        cd "$workdir/openssl"
        ./Configure --prefix="$HOME/.local"
        make -j CC=gcc10-gcc
        make install
        cd "$curdir"
    fi

    git clone --depth 1 "https://github.com/Kitware/CMake.git" "$workdir/cmake"
    cd "$workdir/cmake"
    ./bootstrap --prefix="$HOME/.local" -- -DOPENSSL_ROOT_DIR="$HOME/.local"
    make -j
    make install
    cd "$curdir"
}

sync_vim() {
    if [ "$os_pkg_manager" = "apt" ]; then
        sudo apt-add-repository -y ppa:neovim-ppa/unstable
        apt_install "neovim"
    fi

    if ! [ -x "$(command -v "nvim")" ]; then
        git clone --depth 1 "https://github.com/neovim/neovim.git" "$workdir/neovim"
        cd "$workdir/neovim"
        make -j CC="$HOME/.local/bin/gcc" CXX="$HOME/.local/bin/g++" \
            CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$HOME/.local"
        make install
        cd "$curdir"
    fi

    require_command "nvim"

    apt_install "clangd"
    yum_install "clang-tools-extra"

    cargo install ripgrep

    if confirm "I will now replace your vim configuration."; then
        rm -rf "$HOME/.config/nvim"
        curl -sSLo "$HOME/.config/nvim/init.lua" --create-dirs \
            "$dotfiles_url/home/.config/nvim/init.lua"
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
        sudo apt update

        apt_install "papirus-icon-theme"
        apt_install "neovim"

        papirus-folders -t Papirus -C nordic -u
        papirus-folders -t Papirus-Dark -C nordic -u

        mkdir -p "$HOME/.local/share/fonts"
        curl -sSLo "$workdir/PerfectDOSVGA437Win.tar.xz" --create-dirs \
            "$dotfiles_url/home/.local/share/fonts/PerfectDOSVGA437Win.tar.xz"
        tar xf "$workdir/PerfectDOSVGA437Win.tar.xz" -C "$HOME/.local/share/fonts"

        curl -sSLo "$workdir/AcPlus_IBM_BIOS.tar.xz" --create-dirs \
            "$dotfiles_url/home/.local/share/fonts/AcPlus_IBM_BIOS.tar.xz"
        tar xf "$workdir/AcPlus_IBM_BIOS.tar.xz" -C "$HOME/.local/share/fonts"

        fc-cache -f

        alacritty_install
        rm -rf "$HOME/.config/alacritty"
        curl -sSLo "$HOME/.config/alacritty/alacritty.toml" --create-dirs \
            "$dotfiles_url/home/.config/alacritty/alacritty.toml"
    fi
    if confirm "If you're using an apple keyboard driver, I can configure it to act right on linux"; then
        echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode
        echo "options hid_apple fnmode=2" | sudo tee -a /etc/modprobe.d/hid_apple.conf
        sudo update-initramfs -u -k all
    fi
    echo "That's it! You should log out and log back in."
}

sync_bin() {
    set -- "ssh-tunnel" "modplay" "xsig"
    for f in "$@"; do
        curl -sSLo "$HOME/bin/$f" --create-dirs "$dotfiles_url/home/bin/$f"
        chmod +x "$HOME/bin/$f"
    done
}

sync_gdb() {
    rm -f "$HOME/.gdbinit"
    curl -sSLo "$HOME/.gdbinit" "$dotfiles_url/home/.gdbinit"
}

require_command "curl"
sync_git
sync_shell
sync_rust
sync_bin
sync_gcc
sync_cmake
sync_node
sync_vim
sync_gdb
sync_gui
