import subprocess
import psutil
from core.logger import log


def find_pid_by_port_linux(port):
    """Busca el PID que está usando un puerto TCP."""
    try:
        for conn in psutil.net_connections(kind="tcp"):
            if conn.laddr.port == port and conn.pid not in (0, None):
                return conn.pid
    except Exception as e:
        log.error(f"[LINUX] Error buscando PID para puerto {port}: {e}")
    return None


def close_port_linux(port):
    log.info(f"[LINUX] Intentando cerrar puerto {port}...")

    # Encontrar PID
    pid = find_pid_by_port_linux(port)

    if not pid:
        log.warning(f"[LINUX] No se encontró proceso asociado al puerto {port}")
        return False

    log.info(f"[LINUX] Puerto {port} está asociado al PID {pid}. Terminando proceso...")

    # 2Matar proceso
    try:
        subprocess.run(["sudo", "kill", "-9", str(pid)], check=True)
        log.info(f"[LINUX] Proceso {pid} eliminado. Puerto {port} cerrado.")
    except Exception as e:
        log.error(f"[LINUX] Error al matar el proceso {pid}: {e}")
        return False

    # Reglas iptables (opcional)
    try:
        subprocess.run(
            ["sudo", "iptables", "-A", "INPUT", "-p", "tcp", "--dport", str(port), "-j", "DROP"],
            check=False
        )
        log.info(f"[LINUX] Regla iptables aplicada para bloquear futuras conexiones al puerto {port}.")
    except Exception as e:
        log.warning(f"[LINUX] No se pudo aplicar iptables: {e}")

    return True


