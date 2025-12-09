; ============================================================
; VulnPorts Agent - Instalador Profesional (NSIS)
; ============================================================

!define APPNAME "VulnPorts Agent"
!define INSTALLDIR "$PROGRAMFILES64\VulnPortsAgent"

!addplugindir "C:\Program Files (x86)\NSIS\Plugins\x86-unicode"

; ---------------------------
; Includes
; ---------------------------
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"

!define MUI_ABORTWARNING

; ============================
; Páginas del instalador
; ============================
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "installer\license.txt"
!insertmacro MUI_PAGE_DIRECTORY
Page custom AgentConfigPage AgentConfigPageLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; ============================
; Páginas de desinstalación
; ============================
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ============================
; General
; ============================
Name "${APPNAME}"
OutFile "VulnPortsAgentSetup.exe"
InstallDir "${INSTALLDIR}"
ShowInstDetails show
ShowUninstDetails show

; ============================
; Variables
; ============================
Var AgentID
Var ApiURL
Var AgentIDField
Var ApiURLField

; ============================================================
; FORMULARIO PERSONALIZADO
; ============================================================
Function AgentConfigPage
    nsDialogs::Create 1018
    Pop $0

    ${NSD_CreateLabel} 0 0 100% 12u "Configurar parámetros del agente:"

    ${NSD_CreateLabel} 0 20 30% 12u "Agent ID:"
    ${NSD_CreateText} 35% 20 60% 12u ""
    Pop $AgentIDField
    ${NSD_SetText} $AgentIDField "HOST-001"

    ${NSD_CreateLabel} 0 50 120u 20u "API URL (ej: http://192.168.1.10:8000/api/v1/agent):"
    ${NSD_CreateText} 35% 50 60% 12u ""
    Pop $ApiURLField
    ${NSD_SetText} $ApiURLField "http://127.0.0.1:8000/api/v1/agent"

    nsDialogs::Show
FunctionEnd

Function AgentConfigPageLeave
    ${NSD_GetText} $AgentIDField $AgentID
    ${NSD_GetText} $ApiURLField  $ApiURL

    ; Validaciones básicas
    StrCmp $AgentID "" emptyAgent 0
    StrCmp $ApiURL "" emptyURL 0
    Goto done

emptyAgent:
    MessageBox MB_ICONSTOP "Debes ingresar un Agent ID."
    Abort

emptyURL:
    MessageBox MB_ICONSTOP "Debes ingresar la URL del backend."
    Abort

done:
FunctionEnd

; ============================================================
; INSTALACIÓN
; ============================================================
Section "Install VulnPorts Agent"

    MessageBox MB_YESNO|MB_ICONQUESTION "¿Deseas instalar VulnPorts Agent?" IDYES continueInstall
    Abort "Instalación cancelada por el usuario."

continueInstall:

    ; --- Eliminar instalación previa ---
    nsExec::ExecToLog 'taskkill /IM VulnPortsAgent.exe /F'
    nsExec::ExecToLog 'sc stop VulnPortsAgent'
    nsExec::ExecToLog 'sc delete VulnPortsAgent'
    RMDir /r "${INSTALLDIR}"

    ; --- Copiar archivos ---
    SetOutPath "${INSTALLDIR}"
    File "installer\VulnPortsAgent.exe"
    File "installer\config.yaml"
    File "installer\nssm.exe"
    File "installer\install.ps1"
    File "installer\uninstall.ps1"

    ; ========================================================
    ; NORMALIZAR API URL → remover "/" final si existe
    ; ========================================================
    StrLen $R0 $ApiURL
    IntOp $R1 $R0 - 1
    StrCpy $R2 $ApiURL 1 $R1
    StrCmp $R2 "/" 0 +2
    StrCpy $ApiURL $ApiURL $R1

    ; ========================================================
    ; REESCRIBIR CONFIG.YAML
    ; ========================================================
    FileOpen $0 "${INSTALLDIR}\config.yaml" "w"

    FileWrite $0 "# ============================================================ $\r$\n"
    FileWrite $0 "# VulnPorts Agent - Configuración generada automáticamente $\r$\n"
    FileWrite $0 "# ============================================================ $\r$\n$\r$\n"

    FileWrite $0 'agent_id: "'
    FileWrite $0 $AgentID
    FileWrite $0 '"$\r$\n'

    FileWrite $0 'api_url: "'
    FileWrite $0 $ApiURL
    FileWrite $0 '"$\r$\n'

    FileWrite $0 "interval: 60$\r$\n"
    FileWrite $0 'log_file: "C:\\ProgramData\\VulnPortsAgent\\agent.log"$\r$\n'
    FileWrite $0 'log_level: "info"$\r$\n'
    FileWrite $0 'api_key: ""$\r$\n'

    FileClose $0

    ; ========================================================
    ; CREAR SERVICIO NSSM
    ; ========================================================
    nsExec::ExecToLog '"${INSTALLDIR}\nssm.exe" install VulnPortsAgent "${INSTALLDIR}\VulnPortsAgent.exe"'
    nsExec::ExecToLog '"${INSTALLDIR}\nssm.exe" set VulnPortsAgent Start SERVICE_AUTO_START'
    nsExec::ExecToLog '"${INSTALLDIR}\nssm.exe" start VulnPortsAgent'

SectionEnd

; ============================================================
; DESINSTALACIÓN
; ============================================================
Section "Uninstall"

    MessageBox MB_YESNO|MB_ICONQUESTION "¿Deseas desinstalar VulnPorts Agent?" IDYES continueUninstall
    Abort "Desinstalación cancelada por el usuario."

continueUninstall:

    nsExec::ExecToLog 'taskkill /IM VulnPortsAgent.exe /F'
    nsExec::ExecToLog 'sc stop VulnPortsAgent'
    nsExec::ExecToLog 'sc delete VulnPortsAgent'

    nsExec::ExecToLog 'powershell.exe -ExecutionPolicy Bypass -File "${INSTALLDIR}\uninstall.ps1"'

    RMDir /r "${INSTALLDIR}"

SectionEnd

