#!/usr/bin/env bash

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REPO="https://theVale46@github.com/theVale46/agent-skills.git"
FAILED=()

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
  local pkg="$1"
  if [ "$PLATFORM" = "macos" ]; then
    brew install "$pkg" >/dev/null 2>&1
  else
    sudo apt-get install -y "$pkg" >/dev/null 2>&1
  fi
}

# prereq <label> <install-pkg> <cmd1> [cmd2 ...]
# Passes if any cmd exists; tries installing pkg if none found.
prereq() {
  local label="$1" pkg="$2"; shift 2
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null && { echo "  [ok] $label"; return 0; }
  done
  echo "  [missing] $label — trying to install $pkg..."
  if try_install "$pkg"; then
    for cmd in "$@"; do
      command -v "$cmd" &>/dev/null && { echo "  [installed] $label"; return 0; }
    done
  fi
  echo "  [FAIL] $label"
  FAILED+=("$label")
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
  echo "ERROR: The following prerequisites could not be installed:"
  for f in "${FAILED[@]}"; do
    echo "  - $f"
  done
  echo ""
  echo "Install them manually and re-run install.sh."
  echo "No dotfile changes were made."
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
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
else
  echo "  Already installed: $OMZ_DIR"
fi

P10K_DIR="$OMZ_DIR/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "  Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "  Already installed: Powerlevel10k"
fi

# ── TPM ──────────────────────────────────────────────────────
echo ""
echo "── Tmux Plugin Manager ──────────────────────────────────"
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "  Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "  Already installed: TPM"
fi

# ── win32yank (WSL2 only) ─────────────────────────────────────
if [ "$PLATFORM" = "windows/wsl" ]; then
  echo ""
  echo "── win32yank (WSL2 clipboard) ───────────────────────────"
  if ! command -v win32yank.exe &>/dev/null; then
    echo "  Installing win32yank..."
    curl -sLo /tmp/win32yank.zip \
      "https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip"
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
  git clone "$SKILLS_REPO" "$SKILLS_DIR"
else
  echo "  Already cloned: agent-skills"
fi

echo ""
echo "Done! Next steps:"
echo "  1. Reload shell:          exec \$SHELL"
echo "  2. Install tmux plugins:  tmux, then Ctrl-b I"
echo "  3. Open nvim:             nvim  (LazyVim auto-installs on first run)"
