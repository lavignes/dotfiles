export PATH="$HOME/bin:/usr/local/bin:$PATH"
export PATH="$HOME/cargo/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="fwalch"
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
