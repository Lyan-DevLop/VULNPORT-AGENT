#!/bin/bash

echo "Instalando VulnPorts Agent en Linux..."

AGENT_DIR="/opt/vulnports-agent"

sudo mkdir -p $AGENT_DIR
sudo cp VulnPortsAgent $AGENT_DIR/
sudo cp config.yaml $AGENT_DIR/

sudo bash -c "cat > /etc/systemd/system/vulnports-agent.service <<EOF
[Unit]
Description=VulnPorts Agent
After=network.target

[Service]
ExecStart=$AGENT_DIR/VulnPortsAgent
Restart=always
User=root
WorkingDirectory=$AGENT_DIR

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable vulnports-agent
sudo systemctl start vulnports-agent

echo "VulnPorts Agent instalado y ejecutándose."

