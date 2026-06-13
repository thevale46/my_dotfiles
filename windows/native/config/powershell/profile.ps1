# =====================================================================
#  Main PowerShell profile - lives under ~/.config/powershell/
#  Loaded by $PROFILE shim.  Reload with:   . $PROFILE   (or:  reload)
#
#  Layout (Linux-style):
#    ~/.config/powershell/profile.ps1     <- this file
#    ~/.config/oh-my-posh/p10k.omp.json   <- prompt theme
#    ~/.config/bat/config                 <- bat options (if present)
# =====================================================================

# Common config root, exposed as XDG_CONFIG_HOME so tools (bat, etc.)
# look in the same place they do on Linux.
$XDG_CONFIG_HOME = Join-Path $HOME '.config'
$env:XDG_CONFIG_HOME = $XDG_CONFIG_HOME

# ---------------------------------------------------------------------
# 1) Force a modern PSReadLine (WinPS 5.1 ships 2.0.0 which lacks
#    -PredictionSource and positional -Chord that Oh My Posh needs)
# ---------------------------------------------------------------------
if ((Get-Module PSReadLine).Version -lt [version]'2.2.0') {
    Remove-Module PSReadLine -Force -ErrorAction SilentlyContinue
    Import-Module PSReadLine -MinimumVersion 2.2.0 -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------
# 1b) Refresh PATH from User+Machine env vars so newly-installed CLIs
#     (zoxide/fzf/bat/eza) work in sessions that started before install.
# ---------------------------------------------------------------------
$persistedPath = (
    [Environment]::GetEnvironmentVariable('Path','Machine'),
    [Environment]::GetEnvironmentVariable('Path','User')
) -join ';'
foreach ($p in ($persistedPath -split ';' | Where-Object { $_ -and (Test-Path $_) })) {
    if (($env:Path -split ';') -notcontains $p) { $env:Path = "$env:Path;$p" }
}

# ---------------------------------------------------------------------
# 1c) UTF-8 everywhere so Nerd Font icons from eza/bat/git survive pipes
# ---------------------------------------------------------------------
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding           = [System.Text.UTF8Encoding]::new()
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# ---------------------------------------------------------------------
# 2) Oh My Posh (Powerlevel10k-style theme)
# ---------------------------------------------------------------------
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $theme = Join-Path $XDG_CONFIG_HOME 'oh-my-posh\p10k.omp.json'
    if (Test-Path $theme) {
        oh-my-posh init pwsh --config $theme | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
}

# ---------------------------------------------------------------------
# 3) Modules
# ---------------------------------------------------------------------
if (Get-Module -ListAvailable Terminal-Icons) { Import-Module Terminal-Icons }
if (Get-Module -ListAvailable posh-git)       { Import-Module posh-git }

# ---------------------------------------------------------------------
# 4) PSReadLine - zsh-like behaviour
# ---------------------------------------------------------------------
if ((Get-Module PSReadLine).Version -ge [version]'2.2.0') {
    Set-PSReadLineOption -EditMode Emacs
    # HistoryAndPlugin requires PowerShell 7.2+; fall back to History on 5.1
    $predSource = if ($PSVersionTable.PSVersion -ge [version]'7.2') { 'HistoryAndPlugin' } else { 'History' }
    Set-PSReadLineOption -PredictionSource $predSource
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -BellStyle None

    # Arrow-up / down = prefix history search (zsh substring-search style)
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Tab = menu complete, Shift+Tab = reverse
    Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious

    # RightArrow / End = accept inline prediction
    Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar
    Set-PSReadLineKeyHandler -Key End        -Function EndOfLine
}

# ---------------------------------------------------------------------
# 5) zoxide  (smarter cd:  z foo, zi)
# ---------------------------------------------------------------------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    # Disable zoxide's doctor self-check: it false-positives when a prompt
    # framework (oh-my-posh) re-registers the prompt after this line.
    $env:_ZO_DOCTOR = '0'
    Invoke-Expression (& { (zoxide init powershell --cmd z) -join "`n" })
}

# ---------------------------------------------------------------------
# 6) PSFzf  (Ctrl+T = file picker, Ctrl+R = history, Alt+C = cd)
# ---------------------------------------------------------------------
if ((Get-Module -ListAvailable PSFzf) -and (Get-Command fzf -EA SilentlyContinue)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+t' `
                    -PSReadLineChordReverseHistory 'Ctrl+r' `
                    -PSReadLineChordSetLocation 'Alt+c' `
                    -PSReadLineChordReverseHistoryArgs 'Alt+a'
    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border --info=inline'
}

# ---------------------------------------------------------------------
# 7) Aliases - oh-my-zsh feel
# ---------------------------------------------------------------------
if (Get-Command eza -ErrorAction SilentlyContinue) {
    # Aliases outrank functions in PS name resolution; remove built-ins first.
    foreach ($n in 'ls','ll','la','lt','l') {
        if (Test-Path "Alias:$n") { Remove-Item -LiteralPath "Alias:$n" -Force }
    }
    function ls   { eza --icons --group-directories-first @args }
    function ll   { eza -l  --icons --group-directories-first --git @args }
    function la   { eza -la --icons --group-directories-first --git @args }
    function lt   { eza --tree --level=2 --icons --group-directories-first @args }
    function l    { eza -lah --icons --group-directories-first --git @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    foreach ($n in 'cat','less','more') {
        if (Test-Path "Alias:$n") { Remove-Item -LiteralPath "Alias:$n" -Force }
    }
    function cat  { bat --paging=never @args }
    function less { bat @args }
    # bat reads ~/.config/bat/config automatically via $env:BAT_CONFIG_DIR
    $env:BAT_CONFIG_DIR = Join-Path $XDG_CONFIG_HOME 'bat'
}

# Git shortcuts (oh-my-zsh git plugin essentials)
function gst  { git status @args }
function gco  { git checkout @args }
function gcb  { git checkout -b @args }
function gpl  { git pull @args }
function gps  { git push @args }
function gd   { git diff @args }
function ga   { git add @args }
function gcm  { git commit -m @args }
function gl   { git log --oneline --graph --decorate --all @args }
function glog { git log --oneline --graph --decorate -20 @args }

# Quality of life
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function mkcd  { param($p) New-Item -ItemType Directory -Force -Path $p | Out-Null; Set-Location $p }
function which { param($cmd) (Get-Command $cmd -ErrorAction SilentlyContinue).Source }
function reload { . $PROFILE }
