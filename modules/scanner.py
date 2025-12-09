import psutil

def scan_open_ports():
    ports = []

    for conn in psutil.net_connections():
        if conn.laddr and conn.status == "LISTEN":
            try:
                proc = psutil.Process(conn.pid) if conn.pid else None
                ports.append({
                    "port": conn.laddr.port,
                    "pid": conn.pid,
                    "process_name": proc.name() if proc else None,
                    "user": proc.username() if proc else None,
                })
            except Exception:
                ports.append({
                    "port": conn.laddr.port,
                    "pid": conn.pid,
                    "process_name": None,
                    "user": None,
                })

    return ports
