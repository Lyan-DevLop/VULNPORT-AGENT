param(
    [string]$AgentId = "",
    [string]$ApiUrl = ""
)

#   LOGGING
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$configPath = Join-Path $ScriptDir "config.yaml"
$exePath = Join-Path $ScriptDir "VulnPortsAgent.exe"

$logDir = "C:\ProgramData\VulnPortsAgent"
$logFile = "$logDir\install.log"

if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }

function Log {
    param([string]$msg)
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg"
}

Log "=== INICIO DE INSTALACIÓN ==="
Log "AgentId recibido = $AgentId"
Log "ApiUrl recibido   = $ApiUrl"

#   VALIDACIÓN DE PARÁMETROS=
if ($AgentId -eq "" -or $ApiUrl -eq "") {
    Log "ERROR: Parámetros vacíos. Instalación cancelada."
    exit 1
}
#   ACTUALIZAR CONFIG.YAML
try {
    if (!(Test-Path $configPath)) {
        throw "No existe config.yaml en $configPath"
    }

    Log "Actualizando config.yaml..."

    $yaml = Get-Content $configPath
    $yaml = $yaml `
        -replace 'agent_id:.*',  "agent_id: `"$AgentId`"" `
        -replace 'api_url:.*',   "api_url: `"$ApiUrl`""

    $yaml | Set-Content $configPath

    Log "config.yaml actualizado correctamente"
}
catch {
    Log "ERROR al actualizar config.yaml: $_"
}
#   ELIMINAR SERVICIO ANTERIOR (si existe)
try {
    $svc = Get-Service -Name "VulnPortsAgent" -ErrorAction SilentlyContinue
    if ($svc) {
        Log "Servicio previo encontrado. Eliminando..."
        Stop-Service VulnPortsAgent -Force -ErrorAction SilentlyContinue
        sc.exe delete VulnPortsAgent | Out-Null
    }
}
catch {
    Log "ERROR eliminando servicio previo: $_"
}
#   CREAR SERVICIO NUEVO
try {
    Log "Creando servicio VulnPortsAgent..."

    New-Service -Name "VulnPortsAgent" `
        -BinaryPathName "`"$exePath`"" `
        -DisplayName "VulnPortsAgent" `
        -StartupType Automatic

    Log "Servicio creado correctamente"
}
catch {
    Log "ERROR al crear el servicio: $_"
}
#   INICIAR SERVICIO
try {
    Start-Service VulnPortsAgent
    Log "Servicio iniciado correctamente"
}
catch {
    Log "ERROR al iniciar el servicio: $_"
}

Log "=== INSTALACIoN FINALIZADA ==="
