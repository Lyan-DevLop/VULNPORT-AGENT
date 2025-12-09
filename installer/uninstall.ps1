$ErrorActionPreference = "Stop"

$ServiceName = "VulnPortsAgent"
$InstallDir  = "C:\Program Files\VulnPortsAgent"

# Log file
$logDir = "C:\ProgramData\VulnPortsAgent"
$logFile = "$logDir\uninstall.log"

if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }

function Log {
    param([string]$msg)
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg"
}

Log "=== INICIANDO DESINSTALACIÓN ==="
#   DETENER SERVICIO (si existe)
Log "Deteniendo servicio si existe..."

try {
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Stopped') {
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Log "Servicio detenido."
    }
} catch {
    Log "ERROR deteniendo servicio: $_"
}
#   ELIMINAR SERVICIO (incluso si está corrupto)
Log "Eliminando servicio..."

try {
    sc.exe delete $ServiceName | Out-Null
    Log "Servicio eliminado correctamente."
} catch {
    Log "ERROR eliminando servicio: $_"
}

Start-Sleep -Seconds 1
#   FINALIZAR PROCESO HUÉRFANO
Log "Eliminando procesos activos del agente..."

try {
    $proc = Get-Process "VulnPortsAgent" -ErrorAction SilentlyContinue
    if ($proc) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Log "Proceso del agente finalizado."
    }
} catch {
    Log "ERROR finalizando proceso: $_"
}
#   ELIMINAR CARPETA DE INSTALACIÓN
Log "Eliminando carpeta de instalación..."

try {
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        Log "Carpeta eliminada correctamente."
    }
} catch {
    Log "ERROR eliminando carpeta: $_"
}


Log "=== DESINSTALACIÓN COMPLETADA ==="
