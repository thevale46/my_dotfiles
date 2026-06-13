#Requires -Version 5.1
<#
.SYNOPSIS
    Dotfiles bootstrap for Windows native (PowerShell, Windows Terminal, Tabby, etc.)
    Run from the dotfiles directory: .\install.ps1
    Requires Administrator for symlink creation.
#>

$DOTFILES = $PSScriptRoot
$script:FAILED = [System.Collections.Generic.List[string]]::new()

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

function Check-Tool {
    param([string]$Label, [string]$WingetId, [string[]]$Cmds)
    foreach ($cmd in $Cmds) {
        if (Has-Command $cmd) { Write-Host "  [ok] $Label"; return }
    }
    Write-Host "  [missing] $Label — trying to install $WingetId..."
    try {
        winget install --id $WingetId --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        Refresh-Path
        foreach ($cmd in $Cmds) {
            if (Has-Command $cmd) { Write-Host "  [installed] $Label"; return }
        }
    } catch {}
    Write-Host "  [FAIL] $Label"
    $script:FAILED.Add($Label)
}

function Check-PSModule([string]$Name) {
    if (Has-Module $Name) { Write-Host "  [ok] PS:$Name"; return }
    Write-Host "  [missing] PS:$Name — trying to install..."
    try {
        Install-Module -Name $Name -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop 2>&1 | Out-Null
        if (Has-Module $Name) { Write-Host "  [installed] PS:$Name"; return }
    } catch {}
    Write-Host "  [FAIL] PS:$Name"
    $script:FAILED.Add("PS:$Name")
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
    Write-Host "ERROR: winget is not available. Install 'App Installer' from the Microsoft Store." -ForegroundColor Red
    Write-Host "No changes were made." -ForegroundColor Red
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
    Write-Host "ERROR: The following prerequisites could not be installed:" -ForegroundColor Red
    foreach ($f in $script:FAILED) { Write-Host "  - $f" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Install them manually and re-run install.ps1." -ForegroundColor Red
    Write-Host "No dotfile changes were made." -ForegroundColor Red
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
