# dotfiles

Personal dotfiles for macOS, Linux, and Windows (WSL2 + native). One `main` branch — platform differences are handled by directory structure, not by branches.

---

## Structure

```
dotfiles/
├── install.sh                          # Bootstrap for macOS / Linux / WSL2
├── install.ps1                         # Bootstrap for Windows native (PowerShell)
├── .gitignore
│
├── shared/                             # Identical across all platforms
│   ├── config/
│   │   ├── nvim/                       # Neovim — LazyVim + Catppuccin Mocha
│   │   ├── bat/config                  # bat syntax highlighter (OneHalfDark)
│   │   └── gh/config.yml              # GitHub CLI settings
│   └── home/
│       ├── .zshrc.shared              # Common zsh config (sourced by platform .zshrc)
│       └── .p10k.zsh                  # Powerlevel10k prompt config
│
├── macos/
│   ├── config/tmux/tmux.conf          # tmux — pbcopy clipboard
│   └── home/
│       ├── .zshrc                     # Homebrew paths, macOS plugins
│       ├── .bashrc
│       └── .gitconfig                 # name: biswa-mac
│
├── linux/
│   ├── config/tmux/tmux.conf          # tmux — xclip clipboard
│   └── home/
│       ├── .zshrc                     # batcat/fdfind aliases
│       ├── .bashrc
│       └── .gitconfig                 # name: biswa-linux
│
└── windows/
    ├── wsl/
    │   ├── config/tmux/tmux.conf      # tmux — win32yank clipboard
    │   └── home/
    │       ├── .zshrc                 # batcat/fdfind + /mnt/c paths
    │       ├── .bashrc
    │       ├── .gitconfig             # name: biswa-wsl
    │       └── .wslconfig             # WSL2 memory/swap limits
    └── native/
        ├── config/
        │   ├── powershell/profile.ps1         # PS7 profile (PSReadLine, zoxide, fzf, eza)
        │   ├── oh-my-posh/p10k.omp.json       # Powerlevel10k-style PS prompt
        │   └── gh/config.yml
        ├── terminal/
        │   ├── windows-terminal-settings.json
        │   └── tabby-config.yaml
        └── home/
            ├── .gitconfig                     # name: biswa-win
            ├── .wslconfig                     # WSL2 limits (written by install.ps1)
            └── Documents/WindowsPowerShell/
                └── Microsoft.PowerShell_profile.ps1  # PS5 shim → PS7 profile
```

---

## Installation

### macOS / Linux / WSL2

```bash
git clone git@github.com:theVale46/my_dot_files.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` will:
- Detect the platform automatically (macOS / Linux / WSL2)
- Symlink all shared and platform-specific configs to the right locations
- Install Oh My Zsh into `~/.config/.oh-my-zsh` if not present
- Install Powerlevel10k theme if not present
- Install TPM (Tmux Plugin Manager) if not present
- Install `win32yank.exe` on WSL2 for clipboard support
- Clone the `agent-skills` repo into `~/.config/opencode/skills/`

After install:
```bash
exec $SHELL                  # reload shell
# open tmux, then:
Ctrl-b I                     # install tmux plugins (first time only)
nvim                         # LazyVim auto-installs all plugins on first launch
```

### Windows native (PowerShell)

```powershell
git clone git@github.com:theVale46/my_dot_files.git $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1
```

`install.ps1` will:
- Symlink the PS7 profile, oh-my-posh theme, bat config, gh config
- Place the PS5 shim in `Documents\WindowsPowerShell\`
- Symlink Windows Terminal and Tabby configs to their AppData locations
- Prompt for WSL2 memory and swap limits (with current values as defaults) and write `.wslconfig`

> **Note:** Run PowerShell as Administrator the first time — symlinks require elevated permissions on Windows.

---

## What's configured

### Shell (zsh + bash)

All platforms share a common base (`shared/home/.zshrc.shared`) that defines:

| Setting | Value |
|---------|-------|
| Framework | Oh My Zsh (`~/.config/.oh-my-zsh`) |
| Theme | Powerlevel10k |
| Shared plugins | `git docker docker-compose python ansible kubectl colored-man-pages colorize command-not-found tmux` |
| macOS extras | `battery macos marked2` |

Common aliases across all platforms:

| Alias | Command |
|-------|---------|
| `ls/ll/la/lla/llt` | `eza` with icons and colours |
| `cd` | `z` (zoxide smart jump) |
| `cdi` | `zi` (zoxide interactive) |
| `cat` | `bat` / `batcat` |
| `fd` | `fd` / `fdfind` |
| `vf` | `nvim "$(fzf)"` — fuzzy open in nvim |
| `python` | `python3` |
| `pip` | `pip3` |

Platform differences:

| Tool | macOS | Linux | WSL2 |
|------|-------|-------|------|
| `bat` | `bat` (Homebrew) | `batcat` (apt) | `batcat` (apt) |
| `fd` | `fd` (Homebrew) | `fdfind` (apt) | `fdfind` (apt) |
| fzf source | `$(brew --prefix)/opt/fzf/` | `/usr/share/fzf/` | `/usr/share/fzf/` |
| Obsidian | native app | — | `/mnt/c/Users/.../Obsidian.exe` |

### tmux

9 plugins managed via [TPM](https://github.com/tmux-plugins/tpm). Install with `Ctrl-b I` inside tmux.

| Plugin | Purpose |
|--------|---------|
| `tmux-sensible` | Sensible baseline defaults |
| `tmux-yank` | Copy to system clipboard from copy mode (`y`) |
| `tmux-resurrect` | Save/restore sessions across reboots (`Ctrl-b Ctrl-s` / `Ctrl-b Ctrl-r`) |
| `tmux-continuum` | Auto-saves session every 15 minutes |
| `vim-tmux-navigator` | `Ctrl-h/j/k/l` moves between tmux panes and nvim splits seamlessly |
| `tmux-fzf` | Fuzzy session/window/pane switcher (`Ctrl-b F`) |
| `catppuccin/tmux` | Catppuccin Mocha theme with modular status bar |
| `tmux-thumbs` | Hint-mode copy for IPs, hostnames, paths — press `f` in a pane |
| `tmux-floax` | Floating scratch terminal (`Ctrl-b p`) |

Clipboard is the only platform difference:

| Platform | Clipboard backend |
|----------|------------------|
| macOS | `pbcopy` / `pbpaste` |
| Linux | `xclip` |
| WSL2 | `win32yank.exe` (installed by `install.sh`) |

Key custom bindings (prefix is `Ctrl-b`):

| Key | Action |
|-----|--------|
| `Ctrl-b \|` | Split pane vertically |
| `Ctrl-b -` | Split pane horizontally |
| `Ctrl-b h/j/k/l` | Navigate panes (also works across nvim splits) |
| `Ctrl-b Enter` | Enter copy mode |
| `v` (copy mode) | Begin selection |
| `y` (copy mode) | Yank to system clipboard |
| `Ctrl-b p` | Open floating scratch terminal |
| `f` (any pane) | tmux-thumbs hint mode |
| `Ctrl-b r` | Reload tmux config |

### Neovim (LazyVim)

[LazyVim](https://lazyvim.org) distribution with:

| Plugin/Feature | Detail |
|---------------|--------|
| Colorscheme | Catppuccin Mocha (matches tmux theme) |
| LSP servers | pyright, jsonls, html, lemminx, yamlls, ansiblels, marksman |
| LSP installer | Mason (auto-installs on first launch) |
| Tmux navigation | `Ctrl-h/j/k/l` seamlessly cross nvim↔tmux |
| Everything else | LazyVim defaults (Telescope, Neo-tree, Treesitter, Lualine, etc.) |

Leader key: `<Space>`

LazyVim installs all plugins automatically on the first `nvim` launch.

### Git

Platform-specific name, shared email and settings:

| Platform | `user.name` |
|----------|------------|
| macOS | `biswa-mac` |
| Linux | `biswa-linux` |
| WSL2 | `biswa-wsl` |
| Windows native | `biswa-win` |

All platforms: `user.email = biswajit.p@outlook.com`, editor = `nvim`, `defaultBranch = main`.

### Windows native (PowerShell)

The PS7 profile (`~/.config/powershell/profile.ps1`) provides a zsh-like experience in PowerShell:

- **Oh-My-Posh** — Powerlevel10k-style two-line prompt
- **PSReadLine** — zsh substring history search, menu completion, inline prediction
- **zoxide** — `z` / `zi` smart directory jumping
- **PSFzf** — `Ctrl-t` file picker, `Ctrl-r` history, `Alt-c` directory jump
- **eza** — `ls/ll/la/lt` with icons and git status
- **bat** — `cat` / `less` replacement
- **Terminal-Icons** — file type icons in directory listings
- **posh-git** — git status in prompt
- Git shortcuts: `gst`, `gco`, `gcb`, `gpl`, `gps`, `gd`, `ga`, `gcm`, `gl`

A PS5 shim (`Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`) simply loads the PS7 profile for backward compatibility.

---

## Prerequisites

### macOS
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install eza bat fd fzf zoxide nvim tmux gh git
```

### Linux / WSL2
```bash
sudo apt update && sudo apt install -y \
  eza bat fd-find fzf zoxide neovim tmux gh git xclip curl unzip
```

### Windows native
Install via [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/):
```powershell
winget install JanDeDobbeleer.OhMyPosh
winget install sharkdp.bat
winget install eza-community.eza
winget install ajeetdsouza.zoxide
winget install junegunn.fzf
winget install GitHub.cli
winget install Neovim.Neovim
# Then install PowerShell modules:
Install-Module -Name PSReadLine -Force -SkipPublisherCheck
Install-Module -Name Terminal-Icons -Force
Install-Module -Name posh-git -Force
Install-Module -Name PSFzf -Force
```

---

## Security

The following are **never committed** (enforced by `.gitignore`):
- `gh/hosts.yml` — GitHub OAuth tokens (managed by `gh auth login`)
- `.kube/config` — Kubernetes credentials
- `.docker/config.json` — Docker credentials
- `.claude.json` — Claude Code session tokens
- Any file matching `*token*`, `*secret*`, `*.env`

---

## Related repos

| Repo | Purpose |
|------|---------|
| [`theVale46/agent-skills`](https://github.com/theVale46/agent-skills) | OpenCode agent skills, prompts, and commands (cloned by `install.sh` into `~/.config/opencode/skills/`) |
| [`theVale46/my_dot_files`](https://github.com/theVale46/my_dot_files) | This repo |
