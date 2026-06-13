#Requires -Version 5.1
<#
.SYNOPSIS
    Dotfiles bootstrap for Windows native (PowerShell, Windows Terminal, Tabby, etc.)
    Run from the dotfiles directory: .\install.ps1
    Requires Administrator for symlink creation.
#>

$DOTFILES = $PSScriptRoot
$script:FAILED     = [System.Collections.Generic.List[string]]::new()
$script:FailNotes  = [System.Collections.Generic.List[string]]::new()

# ── Helpers ───────────────────────────────────────────────────

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Has-Command([string]$Cmd) {
    return [bool](Get-Command $Cmd -ErrorAction SilentlyContinue)
}

function Has-Module([string]$Name) {
    return [bool](Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue)
}

function Is-NetworkError([string]$Msg) {
    return $Msg -match "network|timed?\s?out|blocked|proxy|ssl|certificate|download|403|404|connect|unreachable|raw\.github|github\.com"
}

function Mark-Failed([string]$Label, [string]$Note) {
    Write-Host "  [FAIL] $Label"
    if ($Note) { Write-Host "         ^ $Note" }
    $script:FAILED.Add($Label)
    $script:FailNotes.Add($Note)
}

function Check-Tool {
    param([string]$Label, [string]$WingetId, [string[]]$Cmds)
    foreach ($cmd in $Cmds) {
        if (Has-Command $cmd) { Write-Host "  [ok] $Label"; return }
    }
    Write-Host "  [missing] $Label — trying to install $WingetId..."
    try {
        $out = winget install --id $WingetId --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-String
        Refresh-Path
        foreach ($cmd in $Cmds) {
            if (Has-Command $cmd) { Write-Host "  [installed] $Label"; return }
        }
        if (Is-NetworkError $out) {
            Mark-Failed $Label "network error — GitHub download URLs may be blocked on this network"
        } else {
            Mark-Failed $Label "installed but command not found — check PATH"
        }
    } catch {
        $errMsg = $_.Exception.Message
        if (Is-NetworkError $errMsg) {
            Mark-Failed $Label "network error — GitHub/raw.githubusercontent.com may be blocked"
        } else {
            Mark-Failed $Label "winget failed: $($errMsg.Split([Environment]::NewLine)[0])"
        }
    }
}

function Check-PSModule([string]$Name) {
    if (Has-Module $Name) { Write-Host "  [ok] PS:$Name"; return }
    Write-Host "  [missing] PS:$Name — trying to install..."
    try {
        Install-Module -Name $Name -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop 2>&1 | Out-Null
        if (Has-Module $Name) { Write-Host "  [installed] PS:$Name"; return }
        Mark-Failed "PS:$Name" "installed but module not found"
    } catch {
        $errMsg = $_.Exception.Message
        if (Is-NetworkError $errMsg) {
            Mark-Failed "PS:$Name" "network error — PowerShell Gallery may be blocked"
        } else {
            Mark-Failed "PS:$Name" "Install-Module failed: $($errMsg.Split([Environment]::NewLine)[0])"
        }
    }
}

function Link-Config {
    param([string]$Src, [string]$Dst)
    $srcFull = Join-Path $DOTFILES $Src
    $parent  = Split-Path $Dst -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if ((Test-Path $Dst) -and -not ((Get-Item $Dst -ErrorAction SilentlyContinue).LinkType -eq 'SymbolicLink')) {
        $backup = "$Dst.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Move-Item $Dst $backup -Force
        Write-Host "  Backed up: $Dst"
    }
    New-Item -ItemType SymbolicLink -Path $Dst -Target $srcFull -Force | Out-Null
    Write-Host "  Linked: $Dst"
}

# ── Hard requirement: winget ──────────────────────────────────
if (-not (Has-Command "winget")) {
    Write-Host ""
    Write-Host "ERROR: winget is not available." -ForegroundColor Red
    Write-Host "  Install 'App Installer' from the Microsoft Store, or" -ForegroundColor Red
    Write-Host "  ask IT to install the tools listed in README.md manually." -ForegroundColor Red
    Write-Host "  No changes were made." -ForegroundColor Red
    exit 1
}

# ── Check prerequisites ────────────────────────────────────────
Write-Host ""
Write-Host "── Checking prerequisites ───────────────────────────────"

Check-Tool "oh-my-posh"   "JanDeDobbeleer.OhMyPosh"    @("oh-my-posh")
Check-Tool "bat"          "sharkdp.bat"                 @("bat")
Check-Tool "eza"          "eza-community.eza"           @("eza")
Check-Tool "zoxide"       "ajeetdsouza.zoxide"          @("zoxide")
Check-Tool "fzf"          "junegunn.fzf"                @("fzf")
Check-Tool "gh"           "GitHub.cli"                  @("gh")
Check-Tool "nvim"         "Neovim.Neovim"               @("nvim")

Check-PSModule "PSReadLine"
Check-PSModule "Terminal-Icons"
Check-PSModule "posh-git"
Check-PSModule "PSFzf"

if ($script:FAILED.Count -gt 0) {
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Red
    Write-Host "│  ERROR: prerequisites missing — no changes were made    │" -ForegroundColor Red
    Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Red
    Write-Host ""
    Write-Host "Failed tools:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $script:FAILED.Count; $i++) {
        Write-Host "  • $($script:FAILED[$i])" -ForegroundColor Yellow
        if ($script:FailNotes[$i]) {
            Write-Host "    reason: $($script:FailNotes[$i])" -ForegroundColor DarkYellow
        }
    }
    Write-Host ""
    Write-Host "Common cause on work machines:" -ForegroundColor Cyan
    Write-Host "  raw.githubusercontent.com or GitHub release/download URLs"
    Write-Host "  may be blocked by your corporate firewall or proxy."
    Write-Host "  winget pulls packages from GitHub; PSGallery may also be"
    Write-Host "  restricted."
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  1. Connect via VPN and re-run .\install.ps1"
    Write-Host "  2. Ask IT to allowlist winget sources / PowerShell Gallery"
    Write-Host "  3. Install tools manually using an internal mirror, then"
    Write-Host "     re-run .\install.ps1"
    Write-Host ""
    Write-Host "See README.md > Prerequisites > Windows native for the"
    Write-Host "full list of winget IDs and PS module names."
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "All prerequisites met. Proceeding with install..."

# ── Symlinks ──────────────────────────────────────────────────

Write-Host ""
Write-Host "── PowerShell profile ───────────────────────────────"
Link-Config "windows\native\config\powershell\profile.ps1" `
            "$HOME\.config\powershell\profile.ps1"
Link-Config "windows\native\home\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" `
            "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

Write-Host ""
Write-Host "── Oh-My-Posh theme ─────────────────────────────────"
Link-Config "windows\native\config\oh-my-posh\p10k.omp.json" `
            "$HOME\.config\oh-my-posh\p10k.omp.json"

Write-Host ""
Write-Host "── bat config ───────────────────────────────────────"
Link-Config "shared\config\bat\config" `
            "$HOME\.config\bat\config"

Write-Host ""
Write-Host "── gh config ────────────────────────────────────────"
Link-Config "windows\native\config\gh\config.yml" `
            "$HOME\.config\gh\config.yml"

Write-Host ""
Write-Host "── git config ───────────────────────────────────────"
Link-Config "windows\native\home\.gitconfig" `
            "$HOME\.gitconfig"

Write-Host ""
Write-Host "── Windows Terminal ─────────────────────────────────"
$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path (Split-Path $wtPath -Parent)) {
    Link-Config "windows\native\terminal\windows-terminal-settings.json" $wtPath
} else {
    Write-Host "  Skipped: Windows Terminal not installed"
}

Write-Host ""
Write-Host "── Tabby ────────────────────────────────────────────"
$tabbyPath = "$env:APPDATA\tabby\config.yaml"
if (Test-Path (Split-Path $tabbyPath -Parent)) {
    Link-Config "windows\native\terminal\tabby-config.yaml" $tabbyPath
} else {
    Write-Host "  Skipped: Tabby not installed"
}

Write-Host ""
Write-Host "── .wslconfig ───────────────────────────────────────"
$defaultMemory = "4294967296"
$defaultSwap   = "8485076992"

$memory = Read-Host "WSL2 memory limit in bytes [$defaultMemory]"
if ([string]::IsNullOrWhiteSpace($memory)) { $memory = $defaultMemory }

$swap = Read-Host "WSL2 swap size in bytes [$defaultSwap]"
if ([string]::IsNullOrWhiteSpace($swap)) { $swap = $defaultSwap }

@"
[wsl2]
memory=$memory
swap=$swap
"@ | Set-Content "$HOME\.wslconfig" -Encoding UTF8
Write-Host "  Written: $HOME\.wslconfig"

Write-Host ""
Write-Host "Done! Restart your terminal to load the new profile."
