#!/bin/sh

set -e

dotfiles_url="https://raw.githubusercontent.com/lavignes/dotfiles/mainline"
workdir="$(mktemp -d)"
curdir="$(pwd)"
echo "The temp working directory will be $workdir"

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib64:$LD_LIBRARY_PATH"

# Detect OS
if [ "$(uname)" = "Darwin" ]; then
    os="macos"
elif [ -x "$(command -v "apt")" ]; then
    os="apt"
elif [ -x "$(command -v "yum")" ]; then
    os="yum"
else
    os="unknown"
fi

require_command() {
    if ! [ -x "$(command -v "$1")" ]; then
        echo "Couldn't find $1 on your system. I cannot continue..."
        exit 1
    fi
}

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

sync_git() {
    if [ "$os" = "apt" ]; then
        sudo apt -y install git
    elif [ "$os" = "yum" ]; then
        sudo yum -y install git
    fi
    require_command "git"

    if confirm "I will now replace your git configuration."; then
        rm -f "$HOME/.gitconfig"
        curl -sSLo "$HOME/.gitconfig" "$dotfiles_url/home/.gitconfig"
    fi
}

sync_shell() {
    if [ "$os" = "apt" ]; then
        sudo apt -y install zsh
    elif [ "$os" = "yum" ]; then
        sudo yum -y install zsh
    fi
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
    fi
}

sync_tmux() {
    if confirm "I will now replace your tmux configuration."; then
        if [ "$os" = "apt" ]; then
            sudo apt -y install tmux
        elif [ "$os" = "yum" ]; then
            sudo yum -y install tmux
        fi
        rm -f "$HOME/.tmux.conf"
        curl -sSLo "$HOME/.tmux.conf" "$dotfiles_url/home/.tmux.conf"
    fi
}

sync_gcc() {
    if [ "$os" != "yum" ]; then
        return
    fi
    if [ -x "$HOME/.local/bin/gcc" ]; then
        return
    fi

    if confirm "I will now build and install gcc from source."; then
        sudo yum -y install texinfo

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
    fi
}

sync_node() {
    if confirm "I will now install nvm and update to the latest nodejs."; then
        curl -sSL "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh" | bash
        NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        if [ "$os" = "apt" ]; then
            nvm install 24
            nvm use 24
            nvm alias default 24
            return
        fi

        nvm install 16
        nvm use 16
        nvm alias default 16
    fi
}

sync_rust() {
    if confirm "I will now install rustup and cargo."; then
        curl -sSL "https://sh.rustup.rs" | sh -s -- --no-modify-path -y
    fi
}

sync_alacritty() {
    if [ "$os" = "yum" ]; then
        return
    fi
    if confirm "I will now replace your alacritty configuration."; then
        if [ "$os" = "apt" ]; then
            sudo apt -y install alacritty
        fi
        rm -rf "$HOME/.config/alacritty"
        curl -sSLo "$HOME/.config/alacritty/alacritty.toml" --create-dirs \
            "$dotfiles_url/home/.config/alacritty/alacritty.toml"
    fi
}

sync_cmake() {
    if [ "$os" = "apt" ]; then
        sudo apt -y install libssl-dev cmake
        return
    fi
    if [ "$os" != "yum" ]; then
        return
    fi
    if [ -x "$HOME/.local/bin/cmake" ]; then
        return
    fi

    if confirm "I will now build and install cmake from source."; then
        sudo yum -y install perl-core

        if ! [ -x "$HOME/.local/bin/openssl" ]; then
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
    fi
}

sync_ripgrep() {
    if [ "$os" = "macos" ]; then
        return
    fi
    cargo install ripgrep
}

sync_tree_sitter() {
    if [ "$os" = "apt" ]; then
        sudo apt -y install libgcc-14-dev
        BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/14/include" \
            cargo install --locked tree-sitter-cli
    elif [ "$os" = "yum" ]; then
        BINDGEN_EXTRA_CLANG_ARGS="-I$HOME/.local/lib/gcc/x86_64-pc-linux-gnu/15.2.1/include" \
            cargo install --locked tree-sitter-cli
    fi
}

sync_nvim_config() {
    if confirm "I will now replace your vim configuration."; then
        rm -rf "$HOME/.config/nvim"
        curl -sSLo "$HOME/.config/nvim/init.lua" --create-dirs \
            "$dotfiles_url/home/.config/nvim/init.lua"
    fi
}

nvim_min_version="0.11.2"
nvim_tag="v$nvim_min_version"

nvim_needs_update() {
    if ! [ -x "$(command -v "nvim")" ]; then
        return 0
    fi
    current="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    printf '%s\n%s\n' "$nvim_min_version" "$current" | sort -V -C
    # sort -V -C returns 0 if already sorted (current >= min), 1 otherwise
    test $? -ne 0
}

sync_vim() {
    if [ "$os" = "apt" ]; then
        sudo apt-add-repository -y ppa:neovim-ppa/unstable
        sudo apt -y install neovim clangd
    elif [ "$os" = "yum" ]; then
        sudo yum -y install clang-tools-extra
    fi

    if nvim_needs_update; then
        if confirm "I will now build and install neovim $nvim_tag."; then
            git clone --depth 1 --branch "$nvim_tag" \
                "https://github.com/neovim/neovim.git" "$workdir/neovim"
            cd "$workdir/neovim"
            make -j CC="$HOME/.local/bin/gcc" CXX="$HOME/.local/bin/g++" \
                CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$HOME/.local"
            make install
            cd "$curdir"
        fi
    fi

    require_command "nvim"

    sync_ripgrep
    sync_tree_sitter
    sync_nvim_config
}

sync_themes() {
    if [ "$os" != "apt" ]; then
        return
    fi
    if confirm "I will now install papirus icon themes."; then
        sudo add-apt-repository -y ppa:papirus/papirus
        sudo apt update
        sudo apt -y install papirus-icon-theme

        papirus-folders -t Papirus -C nordic -u
        papirus-folders -t Papirus-Dark -C nordic -u
    fi
}

sync_fonts() {
    if [ "$os" = "yum" ]; then
        return
    fi
    if confirm "I will now install custom fonts."; then
        if [ "$os" = "macos" ]; then
            fonts_dir="$HOME/Library/Fonts"
        else
            fonts_dir="$HOME/.local/share/fonts"
        fi
        mkdir -p "$fonts_dir"

        curl -sSLo "$workdir/PerfectDOSVGA437Win.tar.xz" --create-dirs \
            "$dotfiles_url/home/.local/share/fonts/PerfectDOSVGA437Win.tar.xz"
        tar xf "$workdir/PerfectDOSVGA437Win.tar.xz" -C "$fonts_dir"

        curl -sSLo "$workdir/AcPlus_IBM_BIOS.tar.xz" --create-dirs \
            "$dotfiles_url/home/.local/share/fonts/AcPlus_IBM_BIOS.tar.xz"
        tar xf "$workdir/AcPlus_IBM_BIOS.tar.xz" -C "$fonts_dir"

        if [ "$os" != "macos" ]; then
            fc-cache -f
        fi
    fi
}

sync_apple_keyboard() {
    if [ "$os" != "apt" ]; then
        return
    fi
    if confirm "If you're using an apple keyboard driver, I can configure it to act right on linux"; then
        echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode
        echo "options hid_apple fnmode=2" | sudo tee -a /etc/modprobe.d/hid_apple.conf
        sudo update-initramfs -u -k all
    fi
}

sync_bin() {
    if confirm "I will now replace your ~/bin scripts."; then
        set -- "ssh-tunnel" "modplay" "xsig" "kiro-acp-proxy"
        for f in "$@"; do
            curl -sSLo "$HOME/bin/$f" --create-dirs "$dotfiles_url/home/bin/$f"
            chmod +x "$HOME/bin/$f"
        done
    fi
}

sync_gdb() {
    if confirm "I will now replace your gdb configuration."; then
        rm -f "$HOME/.gdbinit"
        curl -sSLo "$HOME/.gdbinit" "$dotfiles_url/home/.gdbinit"
    fi
}

require_command "curl"
sync_git
sync_shell
sync_tmux
sync_rust
sync_bin
sync_gcc
sync_cmake
sync_node
sync_vim
sync_gdb
sync_alacritty
sync_themes
sync_fonts
sync_apple_keyboard
