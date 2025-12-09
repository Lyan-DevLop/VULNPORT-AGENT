import logging
from core.config import config
import os

os.makedirs(os.path.dirname(config.log_file), exist_ok=True)

logging.basicConfig(
    filename=config.log_file,
    level=logging.INFO if config.log_level == "info" else logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

log = logging.getLogger("agent")


