# p10k instant prompt — must be first
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Shared config
source ~/.zshrc.shared

plugins=($SHARED_ZSH_PLUGINS)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ---- PATH ---------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# ---- Debian package name aliases ----------------------------
alias cat='batcat'
alias bat='batcat'
alias fd='fdfind'

# ---- FZF (system package) -----------------------------------
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh

# ---- Zoxide -------------------------------------------------
# zoxide is already initialized last, but powerlevel10k's instant-prompt +
# async hooks re-register precmd after this line, tripping zoxide's doctor
# self-check (false positive). Disable the check rather than the hook.
export _ZO_DOCTOR=0
eval "$(zoxide init zsh)"
