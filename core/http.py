import requests
from core.config import config
from core.logger import log
from core.system_info import get_real_ip


def send_request(method, endpoint, json=None):
    url = f"{config.api_url}{endpoint}"

    headers = {
        "X-Agent-ID": config.agent_id,
    }

    if getattr(config, "api_key", None):
        headers["X-API-Key"] = config.api_key

    # ============================================================
    # Añadir ip_address al reporte SOLO si no se envió antes
    # ============================================================
    if endpoint.endswith("/report"):
        if json is None:
            json = {}

        if "ip_address" not in json:
            json["ip_address"] = get_real_ip()

        log.debug(f"[REPORT] IP REAL enviada: {json['ip_address']}")

    try:
        response = requests.request(
            method=method,
            url=url,
            json=json,
            headers=headers,
            timeout=10
        )

        if response.status_code >= 400:
            log.error(f"[HTTP ERROR {response.status_code}] {response.text}")
            return None

        try:
            return response.json()
        except ValueError:
            log.warning("⚠ Respuesta sin JSON válido.")
            return None

    except Exception as e:
        log.error(f"🚨 Error HTTP: {e}")
        return None
