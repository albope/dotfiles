# ============================================================
# Setup automatico de terminal productiva
# Ejecutar en PowerShell como administrador:
#   Set-ExecutionPolicy Bypass -Scope Process -Force; .\setup.ps1
# ============================================================

Write-Host "`n=== SETUP TERMINAL PRODUCTIVA ===" -ForegroundColor Cyan
Write-Host "Esto instalara: PowerShell 7, Starship, fzf, zoxide, eza, bat, fd, ripgrep, JetBrains Mono Nerd Font`n"

# --- 1. Instalar herramientas ---
$tools = @(
    @{ Name = "PowerShell 7";       Id = "Microsoft.PowerShell" },
    @{ Name = "Starship";           Id = "Starship.Starship" },
    @{ Name = "fzf";                Id = "junegunn.fzf" },
    @{ Name = "zoxide";             Id = "ajeetdsouza.zoxide" },
    @{ Name = "eza";                Id = "eza-community.eza" },
    @{ Name = "bat";                Id = "sharkdp.bat" },
    @{ Name = "fd";                 Id = "sharkdp.fd" },
    @{ Name = "ripgrep";            Id = "BurntSushi.ripgrep.MSVC" },
    @{ Name = "JetBrains Mono NF";  Id = "DEVCOM.JetBrainsMonoNerdFont" }
)

foreach ($tool in $tools) {
    Write-Host "  Instalando $($tool.Name)..." -ForegroundColor Yellow -NoNewline
    winget install --id $tool.Id --source winget --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
    Write-Host " OK" -ForegroundColor Green
}

# --- 2. Copiar configuraciones ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Starship config
$starshipDir = "$HOME\.config"
if (!(Test-Path $starshipDir)) { New-Item -ItemType Directory -Path $starshipDir -Force | Out-Null }
Copy-Item "$scriptDir\starship.toml" "$starshipDir\starship.toml" -Force
Write-Host "  Starship config copiado" -ForegroundColor Green

# PowerShell profile
$profileDir = "$HOME\Documents\PowerShell"
if (!(Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
Copy-Item "$scriptDir\profile.ps1" "$profileDir\profile.ps1" -Force
Write-Host "  PowerShell profile copiado" -ForegroundColor Green

# Windows Terminal settings
$wtDir = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $wtDir) {
    Copy-Item "$scriptDir\windows-terminal.json" "$wtDir\settings.json" -Force
    Write-Host "  Windows Terminal config copiado" -ForegroundColor Green
} else {
    Write-Host "  Windows Terminal no encontrado, instalar desde Microsoft Store" -ForegroundColor Yellow
}

# Cursor/VSCode settings (merge, no overwrite)
$cursorSettings = "$HOME\AppData\Roaming\Cursor\User\settings.json"
if (Test-Path $cursorSettings) {
    Write-Host "  Cursor detectado - configura manualmente terminal.integrated en Settings" -ForegroundColor Yellow
}

Write-Host "`n=== SETUP COMPLETO ===" -ForegroundColor Green
Write-Host "Cierra y abre Windows Terminal para ver los cambios.`n"
