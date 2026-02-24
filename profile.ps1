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

# --- PSReadLine ---
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# --- Aliases: Herramientas modernas ---
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ls { eza --icons --group-directories-first @args }
function ll { eza -la --icons --group-directories-first --git @args }
function lt { eza --tree --level=2 --icons @args }

Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
function cat { bat --style=auto @args }

function ff { fd @args }
function grep { rg @args }

# --- Aliases: Git ---
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
function mkcd { param($dir) New-Item -ItemType Directory -Path $dir -Force; Set-Location $dir }

# --- Aliases: Utiles ---
function which { Get-Command @args | Select-Object -ExpandProperty Source }
function touch { param($file) if (Test-Path $file) { (Get-Item $file).LastWriteTime = Get-Date } else { New-Item $file -ItemType File } }
function reload { . $PROFILE }
function ports { netstat -ano | Select-String "LISTENING" }
function killport { param($port) $pid = (netstat -ano | Select-String ":$port\s" | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -First 1); if ($pid) { Stop-Process -Id $pid -Force; Write-Host "Killed process $pid on port $port" } else { Write-Host "No process on port $port" } }

# --- NPM shortcuts ---
# "run" detecta automaticamente si usar dev o start
function run {
    if (!(Test-Path "package.json")) { Write-Host "  No hay package.json aqui" -ForegroundColor Red; return }
    $pkg = Get-Content package.json -Raw | ConvertFrom-Json
    if ($pkg.scripts.PSObject.Properties["dev"]) {
        Write-Host "  ▶ npm run dev (modo desarrollo con hot-reload)" -ForegroundColor Green
        npm run dev
    } elseif ($pkg.scripts.PSObject.Properties["start"]) {
        Write-Host "  ▶ npm run start (modo produccion)" -ForegroundColor Cyan
        npm run start
    } else {
        Write-Host "  No hay script 'dev' ni 'start'" -ForegroundColor Red
    }
}
function build { npm run build }
function lint { npm run lint }
function nuke {
    Write-Host ""
    Write-Host "  🗑️  Eliminando node_modules y .next..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force node_modules, .next -ErrorAction SilentlyContinue
    Write-Host "  📦 Reinstalando dependencias..." -ForegroundColor Cyan
    npm install
    Write-Host "  ✅ Listo! Ejecuta 'run' para arrancar" -ForegroundColor Green
    Write-Host ""
}

# --- Indicador Claude Code para Starship ---
if ($env:TERM_PROGRAM -eq "vscode") {
    $env:CLAUDE_CODE = "on"
}

# --- Claude Code stats (lee datos de la extension) ---
function claude-stats {
    $statsFile = "$HOME\.claude\stats-cache.json"
    if (!(Test-Path $statsFile)) {
        Write-Host "  No se encontraron stats de Claude Code" -ForegroundColor Red
        return
    }

    $stats = Get-Content $statsFile -Raw | ConvertFrom-Json
    $firstDate = ([datetime]$stats.firstSessionDate).ToString("dd MMM yyyy")

    Write-Host ""
    Write-Host "  🤖 CLAUDE CODE STATS" -ForegroundColor Magenta
    Write-Host "  ────────────────────────────────" -ForegroundColor DarkGray

    # Totales
    Write-Host "  💬 $($stats.totalMessages) mensajes en $($stats.totalSessions) sesiones" -ForegroundColor White
    Write-Host "  📅 Usando desde $firstDate" -ForegroundColor DarkGray

    # Sesion mas larga
    if ($stats.longestSession) {
        $durMin = [math]::Round($stats.longestSession.duration / 60000)
        $durH = [math]::Floor($durMin / 60)
        $durM = $durMin % 60
        Write-Host "  🏆 Sesion mas larga: ${durH}h ${durM}m ($($stats.longestSession.messageCount) msgs)" -ForegroundColor Yellow
    }

    # Modelos usados
    Write-Host "  🧠 Modelos:" -ForegroundColor Cyan
    foreach ($prop in $stats.modelUsage.PSObject.Properties) {
        $model = $prop.Name -replace "claude-", "" -replace "-\d{8}$", ""
        $tokens = $prop.Value.outputTokens
        $tokensK = [math]::Round($tokens / 1000, 1)
        Write-Host "     $model  →  ${tokensK}K tokens generados" -ForegroundColor DarkGray
    }

    # Actividad reciente
    $recent = $stats.dailyActivity | Select-Object -Last 5
    if ($recent) {
        Write-Host "  📈 Actividad reciente:" -ForegroundColor Cyan
        foreach ($day in $recent) {
            $bar = "█" * [math]::Min([math]::Ceiling($day.messageCount / 200), 15)
            Write-Host "     $($day.date)  $bar $($day.messageCount) msgs" -ForegroundColor DarkGray
        }
    }

    # Hora favorita
    $peakHour = $stats.hourCounts.PSObject.Properties | Sort-Object { [int]$_.Value } -Descending | Select-Object -First 1
    if ($peakHour) {
        Write-Host "  🕐 Hora pico: $($peakHour.Name):00h" -ForegroundColor DarkGray
    }

    Write-Host ""
}

# --- Claude Code tips ---
function claude-tips {
    Write-Host ""
    Write-Host "  🤖 CLAUDE CODE - GESTION DEL CONTEXTO" -ForegroundColor Magenta
    Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  Cuando el contexto se llena, Claude va mas lento" -ForegroundColor White
    Write-Host "  y puede olvidar cosas del principio de la conversacion." -ForegroundColor White

    Write-Host ""
    Write-Host "  SEÑALES de que el contexto esta lleno:" -ForegroundColor Yellow
    Write-Host "    - Las respuestas tardan mas de lo normal" -ForegroundColor DarkGray
    Write-Host "    - Claude repite preguntas que ya respondiste" -ForegroundColor DarkGray
    Write-Host "    - Pierde el hilo de lo que estabais haciendo" -ForegroundColor DarkGray
    Write-Host "    - Ves un aviso de 'context window' en la extension" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  COMANDOS dentro de Claude Code:" -ForegroundColor Cyan
    Write-Host "    /compact         Compacta el historial (mantiene lo importante)" -ForegroundColor White
    Write-Host "    /clear           Limpia todo y empieza de cero" -ForegroundColor White
    Write-Host "    /cost            Ver cuanto contexto has consumido" -ForegroundColor White

    Write-Host ""
    Write-Host "  BUENAS PRACTICAS:" -ForegroundColor Green
    Write-Host "    1. Usa /compact cuando notes lentitud (no esperes al limite)" -ForegroundColor DarkGray
    Write-Host "    2. Una conversacion por tarea: termina y abre nueva" -ForegroundColor DarkGray
    Write-Host "    3. Usa CLAUDE.md para instrucciones permanentes" -ForegroundColor DarkGray
    Write-Host "       (asi no gastas contexto repitiendole cosas)" -ForegroundColor DarkGray
    Write-Host "    4. Antes de /clear, pide un resumen de lo pendiente" -ForegroundColor DarkGray

    Write-Host ""
}

# --- Help: todos los comandos disponibles ---
function help {
    Write-Host ""
    Write-Host "  📖 COMANDOS DISPONIBLES" -ForegroundColor Cyan
    Write-Host "  ════════════════════════════════════════" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  ▶ PROYECTO" -ForegroundColor Green
    Write-Host "    run             Arranca el proyecto (detecta dev o start)" -ForegroundColor White
    Write-Host "    build           Compila el proyecto (npm run build)" -ForegroundColor White
    Write-Host "    lint            Ejecuta el linter (npm run lint)" -ForegroundColor White
    Write-Host "    nuke            Borra node_modules + .next y reinstala" -ForegroundColor White

    Write-Host ""
    Write-Host "  🔀 GIT" -ForegroundColor Magenta
    Write-Host "    gs              git status" -ForegroundColor White
    Write-Host "    ga <archivo>    git add" -ForegroundColor White
    Write-Host "    gc <mensaje>    git commit -m" -ForegroundColor White
    Write-Host "    gp              git push" -ForegroundColor White
    Write-Host "    gpl             git pull" -ForegroundColor White
    Write-Host "    gl              git log (ultimos 20)" -ForegroundColor White
    Write-Host "    gd              git diff" -ForegroundColor White
    Write-Host "    gco <rama>      git checkout" -ForegroundColor White
    Write-Host "    gb              git branch" -ForegroundColor White

    Write-Host ""
    Write-Host "  📂 ARCHIVOS" -ForegroundColor Yellow
    Write-Host "    ls              Listar archivos (con iconos)" -ForegroundColor White
    Write-Host "    ll              Listar detallado + info git" -ForegroundColor White
    Write-Host "    lt              Arbol de directorios" -ForegroundColor White
    Write-Host "    cat <archivo>   Ver archivo (con syntax highlighting)" -ForegroundColor White
    Write-Host "    ff <nombre>     Buscar archivos por nombre" -ForegroundColor White
    Write-Host "    grep <texto>    Buscar texto en archivos" -ForegroundColor White

    Write-Host ""
    Write-Host "  🛠️  UTILIDADES" -ForegroundColor Cyan
    Write-Host "    ports           Ver puertos en uso" -ForegroundColor White
    Write-Host "    killport <num>  Matar proceso en un puerto" -ForegroundColor White
    Write-Host "    mkcd <dir>      Crear carpeta y entrar" -ForegroundColor White
    Write-Host "    touch <file>    Crear archivo vacio" -ForegroundColor White
    Write-Host "    reload          Recargar este profile" -ForegroundColor White

    Write-Host ""
    Write-Host "  🤖 CLAUDE CODE" -ForegroundColor Magenta
    Write-Host "    claude-stats    Ver estadisticas de uso" -ForegroundColor White
    Write-Host "    claude-tips     Tips para gestionar el contexto" -ForegroundColor White
    Write-Host "    fin             Copia 'Actualiza el CLAUDE.md' al portapapeles" -ForegroundColor White
    Write-Host "    gfin            Copia instruccion de commit+push para Claude" -ForegroundColor White
    Write-Host "    continuar       Copia mensaje de continuacion para nueva ventana" -ForegroundColor White
    Write-Host ""
    Write-Host "    Skills (dentro de Claude Code):" -ForegroundColor DarkCyan
    Write-Host "    /informe-tecnico       Genera informes HTML profesionales desde .docx" -ForegroundColor DarkGray
    Write-Host "    /revisar-ortografia    Revisa ortografia española y maquetacion HTML" -ForegroundColor DarkGray
    Write-Host "    /configurar-workflow   Configura Claude Code integral para un proyecto" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Agentes (dentro de Claude Code):" -ForegroundColor DarkCyan
    Write-Host "    @frontend-designer     Diseño UI/UX premium (Linear/Stripe/Vercel)" -ForegroundColor DarkGray
    Write-Host "    @backend-architect     Arquitectura de APIs modernas y escalables" -ForegroundColor DarkGray
    Write-Host "    @security-auditor      Auditoria de seguridad (OWASP Top 10)" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  ⌨️  ATAJOS DE TECLADO" -ForegroundColor DarkCyan
    Write-Host "    Ctrl+R          Buscar en historial (fzf)" -ForegroundColor White
    Write-Host "    Tab             Autocompletado con menu" -ForegroundColor White
    Write-Host "    ↑ / ↓           Buscar historial segun lo escrito" -ForegroundColor White

    Write-Host ""
}

# --- Bienvenida con contexto ---
function Show-Welcome {
    $version = $PSVersionTable.PSVersion
    $date = Get-Date -Format "dddd dd MMM yyyy"

    Write-Host ""
    Write-Host "  ⚡ PowerShell $version  |  $date" -ForegroundColor DarkGray

    # Si estamos en un proyecto, mostrar info
    if (Test-Path "package.json") {
        $pkg = Get-Content package.json -Raw | ConvertFrom-Json
        $branch = git branch --show-current 2>$null
        $status = git status --porcelain 2>$null
        $dirty = if ($status) { "!$($status.Count)" } else { "ok" }

        Write-Host "  ────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  📦 $($pkg.name)@$($pkg.version)" -ForegroundColor Yellow -NoNewline
        if ($branch) {
            Write-Host "  🔀 $branch ($dirty)" -ForegroundColor Magenta
        } else {
            Write-Host ""
        }
        Write-Host "  ⚡ run · build · lint · nuke · claude-stats · help" -ForegroundColor DarkGray
    }

    # Recordatorio Claude Code
    if ($env:TERM_PROGRAM -eq "vscode") {
        Write-Host "  ⚠️  Antes de cerrar → dile a Claude: 'Actualiza el CLAUDE.md'" -ForegroundColor DarkYellow
    }
    Write-Host ""
}

# --- Fin de sesion: copia recordatorio al portapapeles ---
function fin {
    "Actualiza el CLAUDE.md con el estado actual del proyecto" | Set-Clipboard
    Write-Host ""
    Write-Host "  📋 Copiado al portapapeles! Pegalo en Claude Code (Ctrl+V)" -ForegroundColor Green
    Write-Host ""
}

# --- Guardar sesion: copia instruccion de commit+push al portapapeles ---
function gfin {
    "Haz commit de todos los cambios pendientes con un mensaje descriptivo en español y haz push" | Set-Clipboard
    Write-Host ""
    Write-Host "  📋 Copiado! Pegalo en Claude Code (Ctrl+V)" -ForegroundColor Green
    Write-Host ""
}

# --- Continuar sesion: copia mensaje de continuacion al portapapeles ---
function continuar {
    @"
CONTINUACION DE SESION ANTERIOR (limite de contexto alcanzado)

Lee estos archivos para entender el estado completo del proyecto:
1. CLAUDE.md (raiz del proyecto) - plan maestro, stack, convenciones, estado actual
2. C:\Users\alber\.claude\projects\c--Users-alber-Desktop-Projects-padel-club-os\memory\MEMORY.md - memoria persistente
3. C:\Users\alber\.claude\plans\jaunty-tumbling-sunrise.md - plan completo de 5 fases

Revisa las secciones de estado en CLAUDE.md y MEMORY.md para ver que esta COMPLETADO y que esta PENDIENTE. Identifica la fase actual y continua desde donde lo dejamos con la siguiente tarea pendiente. Preguntame si no tienes claro por donde seguir.
"@ | Set-Clipboard
    Write-Host ""
    Write-Host "  📋 Copiado al portapapeles! Abre nueva ventana de Claude Code y pega (Ctrl+V)" -ForegroundColor Green
    Write-Host ""
}

# --- Recordatorio al cerrar terminal ---
if ($env:TERM_PROGRAM -eq "vscode") {
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Write-Host ""
        Write-Host "  ⚠️  Has actualizado el CLAUDE.md?" -ForegroundColor Yellow
        Write-Host ""
    } | Out-Null
}

Show-Welcome
