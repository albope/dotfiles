# dotfiles

Mi setup de terminal productiva para Windows 11 con PowerShell 7, Starship y herramientas modernas de CLI.

![PowerShell](https://img.shields.io/badge/PowerShell-7-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-11-0078D6?logo=windows11)
![Starship](https://img.shields.io/badge/Starship-prompt-DD0B78?logo=starship)

## Que incluye

| Archivo | Descripcion |
|---------|-------------|
| `profile.ps1` | Profile de PowerShell 7 con aliases, funciones y atajos |
| `starship.toml` | Configuracion del prompt Starship |
| `windows-terminal.json` | Settings de Windows Terminal (tema, fuente, atajos) |
| `setup.ps1` | Script de instalacion automatica de todo |

## Instalacion rapida

```powershell
# 1. Clonar el repo
git clone https://github.com/albope/dotfiles.git
cd dotfiles

# 2. Ejecutar setup (como administrador)
Set-ExecutionPolicy Bypass -Scope Process -Force; .\setup.ps1
```

El script `setup.ps1` instala automaticamente:
- **PowerShell 7** - Shell moderno
- **Starship** - Prompt rapido y personalizable
- **fzf** - Buscador fuzzy para historial
- **zoxide** - Navegacion inteligente (`z` en vez de `cd`)
- **eza** - Reemplazo moderno de `ls` (con iconos)
- **bat** - Reemplazo de `cat` (con syntax highlighting)
- **fd** - Reemplazo rapido de `find`
- **ripgrep** - Reemplazo rapido de `grep`
- **JetBrains Mono Nerd Font** - Fuente con iconos para la terminal

Despues copia automaticamente `profile.ps1`, `starship.toml` y `windows-terminal.json` a sus rutas correspondientes.

## Comandos disponibles

Escribe `help` en la terminal para ver todos los comandos. Aqui el desglose completo:

### Proyecto (NPM)

| Comando | Descripcion |
|---------|-------------|
| `run` | Arranca el proyecto (detecta `dev` o `start` automaticamente) |
| `build` | `npm run build` |
| `lint` | `npm run lint` |
| `nuke` | Borra `node_modules` + `.next` y reinstala desde cero |

### Git

| Comando | Descripcion |
|---------|-------------|
| `gs` | `git status` |
| `ga <archivo>` | `git add` |
| `gc <mensaje>` | `git commit -m` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gl` | `git log --oneline` (ultimos 20) |
| `gd` | `git diff` |
| `gco <rama>` | `git checkout` |
| `gb` | `git branch` |

### Archivos (reemplazos modernos)

| Comando | Reemplaza | Herramienta |
|---------|-----------|-------------|
| `ls` | `Get-ChildItem` | eza (con iconos y colores) |
| `ll` | `ls -la` | eza (detallado + info git) |
| `lt` | `tree` | eza (arbol de 2 niveles) |
| `cat <archivo>` | `Get-Content` | bat (con syntax highlighting) |
| `ff <nombre>` | `find` | fd (busqueda rapida por nombre) |
| `grep <texto>` | `Select-String` | ripgrep (busqueda rapida en contenido) |

### Navegacion

| Comando | Descripcion |
|---------|-------------|
| `..` | Subir un directorio |
| `...` | Subir dos directorios |
| `mkcd <dir>` | Crear carpeta y entrar en ella |
| `z <dir>` | Navegar inteligente con zoxide (aprende tus rutas frecuentes) |

### Utilidades

| Comando | Descripcion |
|---------|-------------|
| `which <cmd>` | Mostrar la ruta de un comando |
| `touch <archivo>` | Crear archivo vacio (o actualizar timestamp) |
| `ports` | Ver puertos en uso (LISTENING) |
| `killport <num>` | Matar el proceso que usa un puerto |
| `reload` | Recargar el profile sin reiniciar terminal |

### Claude Code

Funciones especificas para trabajar con [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (asistente de IA para programacion):

| Comando | Descripcion |
|---------|-------------|
| `claude-stats` | Ver estadisticas de uso (mensajes, sesiones, modelos, actividad) |
| `claude-tips` | Tips para gestionar el contexto de Claude Code |
| `fin` | Copia al portapapeles un mensaje para que Claude actualice el CLAUDE.md antes de cerrar |
| `gfin` | Copia al portapapeles una instruccion para que Claude haga commit+push de todos los cambios |
| `continuar` | Copia al portapapeles un mensaje de continuacion para retomar en una nueva ventana |

**Flujo recomendado al llegar al limite de contexto:**
1. Escribe `fin` en la terminal y pega en Claude Code -> Claude actualiza el CLAUDE.md con el estado actual
2. Abre una nueva ventana/sesion de Claude Code
3. Escribe `continuar` en la terminal y pega -> Claude lee los archivos de estado y retoma donde lo dejaste

### Atajos de teclado

| Atajo | Descripcion |
|-------|-------------|
| `Ctrl+R` | Buscar en historial con fzf (fuzzy search) |
| `Tab` | Autocompletado con menu interactivo |
| `↑` / `↓` | Buscar en historial segun lo que ya escribiste |

## Starship prompt

El prompt muestra informacion contextual sin ser intrusivo:

```
  ~/Projects/mi-app  main 2mod 1new  v20.16.0 🤖          14:30
❯
```

**Elementos del prompt:**
- Directorio (truncado a 3 niveles)
- Rama de git + estado (modified, staged, new, deleted, ahead/behind)
- Version de Node.js / Python / Rust (si hay proyecto detectado)
- Indicador 🤖 cuando estas dentro de Claude Code (VSCode)
- Duracion del ultimo comando (si tardo mas de 2 segundos)
- Uso de RAM (solo si supera el 70%)
- Hora actual (alineada a la derecha)

## Mensaje de bienvenida

Al abrir la terminal en un directorio con `package.json`, muestra automaticamente:

```
  ⚡ PowerShell 7.x  |  jueves 20 feb 2026
  ────────────────────────────────
  📦 mi-app@0.1.0  🔀 main (ok)
  ⚡ run · build · lint · nuke · claude-stats · help
  ⚠️  Antes de cerrar → dile a Claude: 'Actualiza el CLAUDE.md'
```

## Estructura de archivos

```
dotfiles/
├── profile.ps1           # PowerShell profile (~330 lineas)
│   ├── PATH & integraciones (WinGet, Starship, zoxide, fzf)
│   ├── PSReadLine (prediccion, historial, edicion)
│   ├── Aliases (archivos, git, navegacion, utilidades)
│   ├── NPM shortcuts (run, build, lint, nuke)
│   ├── Claude Code (stats, tips, fin, continuar)
│   └── Bienvenida contextual (Show-Welcome)
├── starship.toml         # Prompt config
├── windows-terminal.json # Terminal visual config
└── setup.ps1             # Instalacion automatica
```

## Requisitos

- Windows 10/11
- [WinGet](https://learn.microsoft.com/windows/package-manager/winget/) (viene preinstalado en Windows 11)
- El `setup.ps1` instala todo lo demas automaticamente

## Actualizacion manual

Si ya tienes todo instalado y solo quieres actualizar las configs:

```powershell
# Desde el directorio del repo
Copy-Item profile.ps1 "$HOME\Documents\PowerShell\profile.ps1" -Force
Copy-Item starship.toml "$HOME\.config\starship.toml" -Force
reload  # o reiniciar terminal
```
