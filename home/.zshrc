# Put host-local stuff in ~/.zshlocal :-)
[ -s "$HOME/.zshlocal" ] && \. "$HOME/.zshlocal"

# Auto-attach to tmux on interactive login
if [[ -z "$TMUX" && $- == *i* ]]; then
    tmux attach -t $(tmux ls 2>/dev/null | grep -v attached | head -1 | cut -d: -f1) 2>/dev/null || tmux
fi

export PATH="$HOME/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib64:$LD_LIBRARY_PATH"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="sunaku"
plugins=(git history-substring-search)
source $ZSH/oh-my-zsh.sh

bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word


# Added by AIM CLI
export PATH="/local/home/lavignes/.aim/mcp-servers:$PATH"

# if you wish to use IMDS set AWS_EC2_METADATA_DISABLED=false

export AWS_EC2_METADATA_DISABLED=true

