import yaml
import platform
import os
import sys
from pathlib import Path


class AgentConfig:
    def __init__(self):
        # ============================================================
        # Localización del config.yaml
        # ============================================================

        # Permite override desde variable de entorno
        env_path = os.environ.get("VULNPORTS_CONFIG_PATH")
        if env_path:
            config_path = Path(env_path)

        else:
            # Si está congelado (EXE), cargar desde el mismo directorio del ejecutable
            if getattr(sys, "frozen", False):
                config_path = Path(sys.executable).parent / "config.yaml"

            else:
                # En desarrollo → directorio raíz del proyecto
                project_root = Path(__file__).resolve().parent.parent
                config_path = project_root / "config.yaml"

        if not config_path.exists():
            raise FileNotFoundError(f"[CONFIG ERROR] Archivo no encontrado: {config_path}")

        # ============================================================
        # Cargar YAML correctamente
        # ============================================================
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f) or {}
        except Exception as e:
            raise ValueError(f"[CONFIG ERROR] No se pudo leer config.yaml → {e}")

        # ============================================================
        # Validar y asignar parámetros
        # ============================================================

        # Agent ID
        self.agent_id = str(data.get("agent_id", "")).strip()
        if not self.agent_id:
            raise ValueError("[CONFIG ERROR] 'agent_id' no puede estar vacío.")

        # API URL (sin slash final)
        self.api_url = str(data.get("api_url", "")).strip()
        if not self.api_url or not self.api_url.startswith("http"):
            raise ValueError("[CONFIG ERROR] api_url inválida o ausente en config.yaml")

        if self.api_url.endswith("/"):
            self.api_url = self.api_url[:-1]

        # Intervalo
        self.interval = int(data.get("interval", 60))

        # Logging
        self.log_file = data.get("log_file", "C:\\ProgramData\\VulnPortsAgent\\agent.log")
        self.log_level = data.get("log_level", "info").lower()

        # API KEY (opcional — la completa el backend después del registro)
        self.api_key = data.get("api_key")

        # ============================================================
        # Detectar OS real
        # ============================================================
        system = platform.system().lower()

        if "windows" in system:
            self.os_type = "windows"
        elif "linux" in system:
            self.os_type = "linux"
        elif "darwin" in system:
            self.os_type = "macos"
        else:
            self.os_type = "unknown"

        # Debug útil en logs
        print(f"[CONFIG] Cargado desde: {config_path}")
        print(f"[CONFIG] Agent ID: {self.agent_id}")
        print(f"[CONFIG] API URL: {self.api_url}")
        print(f"[CONFIG] Interval: {self.interval}")
        print(f"[CONFIG] OS: {self.os_type}")


config = AgentConfig()

