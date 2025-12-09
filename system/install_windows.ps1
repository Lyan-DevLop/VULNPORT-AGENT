param(
    [string]$AgentId,
    [string]$ApiUrl
)

Write-Host "Instalando VulnPorts Agent (Windows)..."

$root = Split-Path $MyInvocation.MyCommand.Path
$configPath = "$root\config.yaml"

(Get-Content $configPath) |
    ForEach-Object {
        $_ -replace '^agent_id:.*', "agent_id: `"$AgentId`"" `
           -replace '^api_url:.*', "api_url: `"$ApiUrl`""
    } | Set-Content $configPath

$exePath = "$root\VulnPortsAgent.exe"

try {
    New-Service -Name "VulnPortsAgent" `
        -BinaryPathName "`"$exePath`"" `
        -StartupType Automatic
}
catch {
    Write-Host "El servicio ya existe. Continuando..."
}

Start-Service VulnPortsAgent -ErrorAction SilentlyContinue

Write-Host "Agente iniciado correctamente."
