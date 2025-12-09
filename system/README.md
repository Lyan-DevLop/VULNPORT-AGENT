# VulnPorts Agent

Agente remoto para cerrar puertos y reportar estado al sistema VULNPORTS.

## Ejecutar local

1. Instalar dependencias:
   ```
   pip install -r requirements.txt
   ```

2. Configurar `config.yaml` con la URL del servidor y el ID del agente.

3. Ejecutar el agente:
   ```
   python agent.py
   ```