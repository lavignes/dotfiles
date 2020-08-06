# PATHY STUFF
export PATH="$HOME/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH=$HOME/.cargo/bin/:$PATH
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# ALIAI?
alias ls="ls -GFh"
alias l="ls -a"
alias ll="ls -al"

# Load plugins
autoload -Uz colors
autoload -Uz compinit
autoload -Uz promptinit
compinit
colors
promptinit
prompt adam1

# allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# history
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Goto dir when typed
setopt AUTO_CD

# automatically decide when to page a list of completions
LISTMAX=0

# completions
setopt completealiases
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

autoload bashcompinit && bashcompinit

