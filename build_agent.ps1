Write-Host "=== VULNPORTS AGENT BUILD ==========================================" -ForegroundColor Cyan

# ============================================================
# 1) Activar entorno virtual
# ============================================================
Write-Host "> Activando entorno virtual..." -ForegroundColor Yellow
$venvPath = ".\venv\Scripts\Activate.ps1"

if (Test-Path $venvPath) {
    & $venvPath
} else {
    Write-Host "ERROR: No se encontró el entorno virtual en .\venv\" -ForegroundColor Red
    exit 1
}

# ============================================================
# 2) Instalar dependencias
# ============================================================
Write-Host "> Instalando dependencias..." -ForegroundColor Yellow
pip install --upgrade pip
pip install -r requirements.txt
pip install pyinstaller

# ============================================================
# 3) Compilar agente EXE
# ============================================================
Write-Host "> Compilando agente con PyInstaller..." -ForegroundColor Yellow

if (Test-Path "build") { Remove-Item "build" -Recurse -Force }
if (Test-Path "dist") { Remove-Item "dist" -Recurse -Force }

pyinstaller agent.spec --clean

if (!(Test-Path "dist\VulnPortsAgent.exe")) {
    Write-Host "ERROR: PyInstaller no generó el ejecutable." -ForegroundColor Red
    exit 1
}

# ============================================================
# 4) Copiar EXE al instalador
# ============================================================
Write-Host "> Copiando VulnPortsAgent.exe al directorio installer..." -ForegroundColor Yellow
Copy-Item "dist\VulnPortsAgent.exe" "installer\VulnPortsAgent.exe" -Force

# ============================================================
# 5) Generar config.yaml BASE (SOLO SI NO EXISTE)
# ============================================================
Write-Host "> Verificando config.yaml base..." -ForegroundColor Yellow

$configPath = "installer\config.yaml"

if (!(Test-Path $configPath)) {

    Write-Host "config.yaml no existe. Creando archivo base..." -ForegroundColor Yellow

    @'
# ============================================================
# VulnPorts Agent - Archivo base
# Este archivo será completado automáticamente por el INSTALADOR
# y luego el BACKEND enviará el api_key real al registrar el agente.
# ============================================================

agent_id: ""
api_url: ""
interval: 60
log_file: "C:\\ProgramData\\VulnPortsAgent\\agent.log"
log_level: "info"
api_key: ""
'@ | Set-Content -Encoding UTF8 $configPath

    Write-Host "> config.yaml generado." -ForegroundColor Green
}
else {
    Write-Host "> config.yaml existente conservado (NO se sobrescribe)." -ForegroundColor Cyan
}

# ============================================================
# 6) Generar ZIP final del instalador completo
# ============================================================
Write-Host "> Generando ZIP del instalador..." -ForegroundColor Yellow

$zipName = "VulnPortsAgentInstaller.zip"
if (Test-Path $zipName) { Remove-Item $zipName -Force }

Compress-Archive -Path "installer\*" -DestinationPath $zipName

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "BUILD FINALIZADO CORRECTAMENTE" -ForegroundColor Green
Write-Host "Archivo generado: $zipName" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
