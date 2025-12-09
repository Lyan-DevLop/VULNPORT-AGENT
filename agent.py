import time
from core.config import config
from core.logger import log
from core.http import send_request
from modules.scanner import scan_open_ports
from modules.firewall_windows import close_port_windows
from modules.firewall_linux import close_port_linux
from core.system_info import get_system_info


def process_commands():
    """
    Consulta si hay comandos pendientes para este agente
    y los ejecuta localmente (cerrar puertos).
    """
    endpoint = f"/command/{config.agent_id}"
    response = send_request("GET", endpoint)

    if not response or "command_id" not in response:
        return

    cmd_id = response["command_id"]
    port = response["port"]

    log.info(f"[COMMAND] Received command to close port {port}")

    if config.os_type == "windows":
        success = close_port_windows(port)
    else:
        success = close_port_linux(port)

    if success:
        log.info(f"[COMMAND] Port {port} closed successfully")
        send_request("POST", "/confirm", {"command_id": cmd_id})
    else:
        log.error(f"[COMMAND] Failed to close port {port}")


def main():
    log.info("Starting VulnPorts Agent...")
    system_info = get_system_info()
    log.info(f"[DEBUG] System info loaded: {system_info}")

    # =========================================================
    # REGISTRO DEL AGENTE (reintenta hasta lograrlo)
    # =========================================================
    while True:
        payload = {
            "agent_id": config.agent_id,
            "hostname": system_info["hostname"],
            "os_type": config.os_type,
        }

        result = send_request("POST", "/register", payload)

        if result:
            # Guardar api_key en memoria si el backend la envía
            if "api_key" in result:
                config.api_key = result["api_key"]
                log.info(f"[REGISTER] API key asignada: {config.api_key}")
            log.info("[REGISTER] Agent registered successfully.")
            break

        log.error("[REGISTER] Failed to register agent. Retrying in 5 seconds...")
        time.sleep(5)

    # =========================================================
    # BUCLE PRINCIPAL
    # =========================================================
    while True:
        ports = scan_open_ports()

        payload = {
            "agent_id": config.agent_id,
            "ip_address": system_info["ip"],  # la IP real de esta máquina
            "ports": ports,
        }

        log.info(f"[DEBUG] Sending report: {payload}")
        send_request("POST", "/report", payload)

        process_commands()
        time.sleep(config.interval)


if __name__ == "__main__":
    main()

