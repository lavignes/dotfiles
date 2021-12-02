export PATH="$HOME/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/cargo/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="fwalch"
plugins=(git history-substring-search)

source $ZSH/oh-my-zsh.sh

# User configuration

bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

## Put host-local stuff in ~/.zshlocal :-)
[ -s "$HOME/.zshlocal" ] && \. "$HOME/.zshlocal"
