# p10k instant prompt — must be first
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Shared config (sets ZSH, ZSH_THEME, SHARED_ZSH_PLUGINS, aliases, NVM)
source ~/.zshrc.shared

# macOS-specific plugins
plugins=($SHARED_ZSH_PLUGINS battery macos marked2)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ---- PATH ---------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# ---- Tool names (macOS via Homebrew use standard names) -----
alias cat='bat'
# fd and eza are already named correctly via Homebrew

# ---- FZF (via Homebrew) -------------------------------------
source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
source "$(brew --prefix)/opt/fzf/shell/completion.zsh"

# ---- Zoxide -------------------------------------------------
# zoxide is already initialized last, but powerlevel10k's instant-prompt +
# async hooks re-register precmd after this line, tripping zoxide's doctor
# self-check (false positive). Disable the check rather than the hook.
export _ZO_DOCTOR=0
eval "$(zoxide init zsh)"
