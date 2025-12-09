import platform
import socket
import psutil

def get_real_ip():
    """
    Obtiene la IP REAL evitando adaptadores virtuales.
    """
    try:
        gateways = psutil.net_if_addrs()
        for iface, addrs in gateways.items():
            # Ignorar adaptadores virtuales de VM, docker o host-only
            if "Virtual" in iface or "VMware" in iface or "VirtualBox" in iface or "Host-Only" in iface:
                continue

            for addr in addrs:
                if addr.family == socket.AF_INET:
                    ip = addr.address
                    if ip.startswith("192.168.") or ip.startswith("10.") or ip.startswith("172.16"):
                        return ip
    except:
        pass

    # fallback
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"


def get_system_info():
    hostname = socket.gethostname()

    return {
        "hostname": hostname,
        "os": platform.platform(),
        "arch": platform.machine(),
        "ip": get_real_ip(), 
    }

