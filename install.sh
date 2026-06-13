#!/usr/bin/env bash

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REPO="https://theVale46@github.com/theVale46/agent-skills.git"
FAILED=()       # tool labels that could not be satisfied
FAIL_NOTES=()   # parallel: reason or hint for each failure

# ── Platform detection ────────────────────────────────────────
OS=$(uname -s)
if uname -r 2>/dev/null | grep -qi microsoft; then
  PLATFORM="windows/wsl"
elif [ "$OS" = "Darwin" ]; then
  PLATFORM="macos"
else
  PLATFORM="linux"
fi
echo "Platform: $PLATFORM"

# ── Prerequisite helpers ──────────────────────────────────────

try_install() {
  # Attempt install; print captured stderr to stdout so caller can inspect it
  local pkg="$1"
  if [ "$PLATFORM" = "macos" ]; then
    brew install "$pkg" 2>&1
  else
    sudo apt-get install -y "$pkg" 2>&1
  fi
}

is_network_error() {
  # Return true if the message looks like a connectivity / download block
  echo "$1" | grep -qiE \
    "could not connect|failed to connect|network|timed? ?out|curl.*error|download.*fail|403|404|blocked|ssl|certificate|proxy|resolve|unreachable|raw\.github"
}

mark_failed() {
  local label="$1" note="$2"
  echo "  [FAIL] $label"
  [ -n "$note" ] && echo "         ^ $note"
  FAILED+=("$label")
  FAIL_NOTES+=("$note")
}

# prereq <label> <install-pkg> <cmd1> [cmd2 ...]
prereq() {
  local label="$1" pkg="$2"; shift 2
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null && { echo "  [ok] $label"; return 0; }
  done

  echo "  [missing] $label — trying to install $pkg..."
  local out
  out=$(try_install "$pkg" 2>&1)
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    for cmd in "$@"; do
      command -v "$cmd" &>/dev/null && { echo "  [installed] $label"; return 0; }
    done
    mark_failed "$label" "installed but command not found — check PATH"
    return 1
  fi

  if is_network_error "$out"; then
    mark_failed "$label" "network error — GitHub/raw.githubusercontent.com may be blocked"
  else
    mark_failed "$label" "install failed ($(echo "$out" | tail -1 | tr -s ' '))"
  fi
}

echo ""
echo "── Checking prerequisites ───────────────────────────────"

prereq "git"     "git"     git
prereq "curl"    "curl"    curl
prereq "zsh"     "zsh"     zsh
prereq "nvim"    "neovim"  nvim
prereq "tmux"    "tmux"    tmux
prereq "gh"      "gh"      gh
prereq "fzf"     "fzf"     fzf
prereq "zoxide"  "zoxide"  zoxide

if [ "$PLATFORM" = "macos" ]; then
  prereq "eza"  "eza"      eza
  prereq "bat"  "bat"      bat
  prereq "fd"   "fd"       fd
else
  prereq "eza"  "eza"      eza
  prereq "bat"  "bat"      bat batcat
  prereq "fd"   "fd-find"  fd fdfind
fi

[ "$PLATFORM" = "windows/wsl" ] && prereq "unzip" "unzip" unzip

# ── Abort if any prereq failed ────────────────────────────────
if [ ${#FAILED[@]} -gt 0 ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────────────┐"
  echo "│  ERROR: prerequisites missing — no changes were made    │"
  echo "└─────────────────────────────────────────────────────────┘"
  echo ""
  echo "Failed tools:"
  for i in "${!FAILED[@]}"; do
    echo "  • ${FAILED[$i]}"
    [ -n "${FAIL_NOTES[$i]}" ] && echo "    reason: ${FAIL_NOTES[$i]}"
  done
  echo ""
  echo "Common cause on work machines:"
  echo "  raw.githubusercontent.com or GitHub release URLs may be"
  echo "  blocked by your corporate firewall/proxy. Package managers"
  echo "  (brew, apt) often pull installers from these URLs."
  echo ""
  echo "Install the missing tools through your company's approved"
  echo "channel (internal mirror, IT helpdesk, VPN + retry), then"
  echo "re-run: ./install.sh"
  echo ""

  if [ "$PLATFORM" = "macos" ]; then
    echo "Quick reference (if brew works):"
    for f in "${FAILED[@]}"; do
      echo "  brew install $f"
    done
  else
    echo "Quick reference (if apt/snap works):"
    for f in "${FAILED[@]}"; do
      case "$f" in
        eza)    echo "  sudo apt install eza  OR  snap install eza" ;;
        gh)     echo "  sudo apt install gh   OR  https://cli.github.com" ;;
        zoxide) echo "  sudo apt install zoxide" ;;
        nvim)   echo "  sudo apt install neovim  OR  snap install nvim --classic" ;;
        *)      echo "  sudo apt install $f" ;;
      esac
    done
  fi
  echo ""
  exit 1
fi

echo ""
echo "All prerequisites met. Proceeding with install..."

# ── Symlink helper ────────────────────────────────────────────
link() {
  local src="$DOTFILES/$1"
  local dst="$HOME/$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "${dst}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  Backed up: ~/$2"
  fi
  ln -sfn "$src" "$dst"
  echo "  Linked: ~/$2"
}

echo ""
echo "── Shared configs ───────────────────────────────────────"
link shared/config/nvim          .config/nvim
link shared/config/bat           .config/bat
link shared/config/gh            .config/gh
link shared/home/.p10k.zsh       .p10k.zsh
link shared/home/.zshrc.shared   .zshrc.shared

echo ""
echo "── Platform configs ($PLATFORM) ─────────────────────────"
link "$PLATFORM/config/tmux"     .config/tmux
link "$PLATFORM/home/.zshrc"     .zshrc
link "$PLATFORM/home/.bashrc"    .bashrc
link "$PLATFORM/home/.gitconfig" .gitconfig

if [ "$PLATFORM" = "windows/wsl" ]; then
  link windows/wsl/home/.wslconfig .wslconfig
fi

if [ "$PLATFORM" = "macos" ]; then
  link macos/config/gh .config/gh
fi

# ── Oh My Zsh ────────────────────────────────────────────────
echo ""
echo "── Oh My Zsh ────────────────────────────────────────────"
OMZ_DIR="$HOME/.config/.oh-my-zsh"
if [ ! -d "$OMZ_DIR" ]; then
  echo "  Installing Oh My Zsh..."
  if ! git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR" 2>&1; then
    echo ""
    echo "ERROR: Failed to clone Oh My Zsh."
    echo "  github.com may be blocked on this network."
    echo "  Clone manually: git clone https://github.com/ohmyzsh/ohmyzsh.git $OMZ_DIR"
    echo "No further changes were made."
    exit 1
  fi
else
  echo "  Already installed: $OMZ_DIR"
fi

P10K_DIR="$OMZ_DIR/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "  Installing Powerlevel10k..."
  if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" 2>&1; then
    echo ""
    echo "ERROR: Failed to clone Powerlevel10k."
    echo "  github.com may be blocked on this network."
    echo "  Clone manually: git clone https://github.com/romkatv/powerlevel10k.git $P10K_DIR"
    echo "No further changes were made."
    exit 1
  fi
else
  echo "  Already installed: Powerlevel10k"
fi

# ── TPM ──────────────────────────────────────────────────────
echo ""
echo "── Tmux Plugin Manager ──────────────────────────────────"
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "  Installing TPM..."
  if ! git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>&1; then
    echo ""
    echo "ERROR: Failed to clone TPM."
    echo "  github.com may be blocked on this network."
    echo "  Clone manually: git clone https://github.com/tmux-plugins/tpm $TPM_DIR"
    echo "No further changes were made."
    exit 1
  fi
else
  echo "  Already installed: TPM"
fi

# ── win32yank (WSL2 only) ─────────────────────────────────────
if [ "$PLATFORM" = "windows/wsl" ]; then
  echo ""
  echo "── win32yank (WSL2 clipboard) ───────────────────────────"
  if ! command -v win32yank.exe &>/dev/null; then
    echo "  Downloading win32yank..."
    if ! curl -sLo /tmp/win32yank.zip \
      "https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip"; then
      echo ""
      echo "ERROR: Failed to download win32yank."
      echo "  GitHub release URLs may be blocked on this network."
      echo "  Download manually from: https://github.com/equalsraf/win32yank/releases"
      echo "  Then run: sudo install /path/to/win32yank.exe /usr/local/bin/win32yank.exe"
      echo "No further changes were made."
      exit 1
    fi
    unzip -o /tmp/win32yank.zip win32yank.exe -d /tmp/
    sudo install /tmp/win32yank.exe /usr/local/bin/win32yank.exe
    rm -f /tmp/win32yank.zip /tmp/win32yank.exe
    echo "  win32yank installed"
  else
    echo "  Already installed: win32yank"
  fi
fi

# ── Agent skills repo ─────────────────────────────────────────
echo ""
echo "── Agent skills ─────────────────────────────────────────"
SKILLS_DIR="$HOME/.config/opencode/skills"
if [ ! -d "$SKILLS_DIR/.git" ]; then
  echo "  Cloning agent-skills..."
  mkdir -p "$(dirname "$SKILLS_DIR")"
  if ! git clone "$SKILLS_REPO" "$SKILLS_DIR" 2>&1; then
    echo ""
    echo "WARNING: Failed to clone agent-skills repo."
    echo "  github.com may be blocked on this network."
    echo "  Clone manually later: git clone $SKILLS_REPO $SKILLS_DIR"
    echo "  (Dotfile symlinks above were already applied.)"
  fi
else
  echo "  Already cloned: agent-skills"
fi

echo ""
echo "Done! Next steps:"
echo "  1. Reload shell:          exec \$SHELL"
echo "  2. Install tmux plugins:  tmux, then Ctrl-b I"
echo "  3. Open nvim:             nvim  (LazyVim auto-installs on first run)"
