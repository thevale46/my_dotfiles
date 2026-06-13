[ -z "$PS1" ] && return

# ---- History ------------------------------------------------
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend checkwinsize

# ---- Prompt (git-aware) -------------------------------------
parse_git_branch() { git branch 2>/dev/null | sed -n '/\* /s///p'; }
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(b=$(parse_git_branch); [ -n "$b" ] && echo " ($b)")\[\033[00m\]\$ '

# ---- PATH ---------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# ---- Aliases ------------------------------------------------
alias ls='eza --icons=always --color=always -s name'
alias ll='eza -l --icons=always --color=always -s name'
alias la='eza -a --icons=always --color=always -s name'
alias lla='eza -la --icons=always --color=always -s name'
alias llt='eza -la --icons=always --color=always -T'
alias cat='bat'
alias cd='z'
alias python=python3
alias pip=pip3
alias vf='nvim "$(fzf)"'

# ---- tmux wrapper -------------------------------------------
export TMUX_CONF="$HOME/.config/tmux/tmux.conf"
tmux() {
  if [ -f "$TMUX_CONF" ]; then
    command tmux -f "$TMUX_CONF" "$@"
  else
    command tmux "$@"
  fi
}

# ---- FZF ----------------------------------------------------
[ -f "$(brew --prefix)/opt/fzf/shell/key-bindings.bash" ] && \
  source "$(brew --prefix)/opt/fzf/shell/key-bindings.bash"
[ -f "$(brew --prefix)/opt/fzf/shell/completion.bash" ] && \
  source "$(brew --prefix)/opt/fzf/shell/completion.bash"

# ---- Zoxide -------------------------------------------------
eval "$(zoxide init bash)"

# ---- NVM ----------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---- Bash completion ----------------------------------------
[ -f "$(brew --prefix)/etc/bash_completion" ] && \
  source "$(brew --prefix)/etc/bash_completion"
