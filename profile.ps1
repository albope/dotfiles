# ============================================================
# PowerShell 7 Profile - Terminal Productivo
# ============================================================

# --- Asegurar PATH de WinGet ---
$wingetLinks = "$HOME\AppData\Local\Microsoft\WinGet\Links"
if (Test-Path $wingetLinks) {
    if ($env:PATH -notlike "*$wingetLinks*") {
        $env:PATH = "$wingetLinks;$env:PATH"
    }
}

# --- Starship Prompt ---
$ENV:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# --- Zoxide (smart cd) ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# --- Fzf integration ---
# Ctrl+R = buscar historial con fzf
# Ctrl+T = buscar archivos con fzf
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $history = Get-Content (Get-PSReadLineOption).HistorySavePath |
        Select-Object -Unique |
        & fzf --height=40% --reverse --no-sort
    if ($history) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($history)
    }
}

# --- PSReadLine (mejor edicion de linea) ---
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Flechas arriba/abajo buscan en historial basado en lo que ya escribiste
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# --- Aliases: Herramientas modernas ---
# ls -> eza (con iconos y colores)
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ls { eza --icons --group-directories-first @args }
function ll { eza -la --icons --group-directories-first --git @args }
function lt { eza --tree --level=2 --icons @args }

# cat -> bat (con syntax highlighting)
Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
function cat { bat --style=auto @args }

# find -> fd
function ff { fd @args }

# grep -> ripgrep (ya instalado)
function grep { rg @args }

# --- Aliases: Git (rapidos) ---
function gs { git status }
function ga { git add @args }
function gc { git commit -m @args }
function gp { git push }
function gl { git log --oneline -20 }
function gd { git diff @args }
function gco { git checkout @args }
function gb { git branch @args }
function gpl { git pull }

# --- Aliases: Navegacion ---
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function mkcd { param($dir) New-Item -ItemType Directory -Path $dir -Force; Set-Location $dir }

# --- Aliases: Utiles ---
function which { Get-Command @args | Select-Object -ExpandProperty Source }
function touch { param($file) if (Test-Path $file) { (Get-Item $file).LastWriteTime = Get-Date } else { New-Item $file -ItemType File } }
function reload { . $PROFILE }
function path { $env:PATH -split ';' | ForEach-Object { $_ } }
function ports { netstat -ano | Select-String "LISTENING" }
function killport { param($port) $pid = (netstat -ano | Select-String ":$port\s" | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -First 1); if ($pid) { Stop-Process -Id $pid -Force; Write-Host "Killed process $pid on port $port" } else { Write-Host "No process on port $port" } }

# --- Utilidades dev ---
function dev { Set-Location ~/Desktop }
function projects { Set-Location ~/Desktop }

# --- Mensaje de bienvenida (sutil) ---
Write-Host "PowerShell $($PSVersionTable.PSVersion) | $(Get-Date -Format 'dddd dd MMM yyyy')" -ForegroundColor DarkGray
