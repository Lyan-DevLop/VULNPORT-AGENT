import subprocess
import psutil
from core.logger import log


def find_pid_by_port(port):
    """Encuentra el PID asociado a un puerto TCP."""
    try:
        for conn in psutil.net_connections(kind="tcp"):
            if conn.laddr.port == port and conn.pid not in (0, None):
                return conn.pid
    except Exception as e:
        log.error(f"[FIREWALL] Error buscando PID para puerto {port}: {e}")
    return None


def close_port_windows(port):
    """
    Cierra REALMENTE el puerto:
    1. Localiza el PID asociado
    2. Mata el proceso
    3. Agrega regla de firewall opcional (bloqueo futuro)
    """
    log.info(f"[FIREWALL] Intentando cerrar puerto {port}...")

    # 1. Buscar PID asociado
    pid = find_pid_by_port(port)
    if not pid:
        log.warning(f"[FIREWALL] No se encontró proceso asociado al puerto {port}")
        return False

    log.info(f"[FIREWALL] Puerto {port} está asociado al PID {pid}. Terminando proceso...")

    # 2. Matar proceso (cierre real del puerto)
    try:
        subprocess.run(["taskkill", "/PID", str(pid), "/F"], check=True)
        log.info(f"[FIREWALL] Proceso {pid} terminado correctamente. Puerto {port} cerrado.")
    except Exception as e:
        log.error(f"[FIREWALL] Error al terminar proceso {pid}: {e}")
        return False

    # 3. Opcional: agregar regla de firewall para evitar que vuelva a abrirse
    try:
        subprocess.run(
            [
                "netsh", "advfirewall", "firewall", "add", "rule",
                f"name=VulnPorts_{port}",
                "dir=in",
                "action=block",
                f"localport={port}",
                "protocol=TCP"
            ],
            check=False
        )
        log.info(f"[FIREWALL] Regla de firewall agregada para bloquear futuras conexiones en el puerto {port}.")
    except Exception as e:
        log.warning(f"[FIREWALL] No se pudo agregar regla de firewall: {e}")

    return True


