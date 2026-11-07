#!/usr/bin/env bash
# Home SOC Lab - Wazuh all-in-one server (Ubuntu 24.04) install + stability fixes
# Learned the hard way on a 5-6 GB RAM VM: default systemd timeouts are too short.
set -euo pipefail

# --- Install (all-in-one: indexer + manager + dashboard) ---------------------
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
sudo bash ./wazuh-install.sh -a

# Pin the version so apt upgrades can't break the stack
sudo sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list
sudo systemctl disable --now unattended-upgrades || true

# --- Stability fixes ---------------------------------------------------------
# 1. Indexer & manager need longer than systemd's default start timeout
for svc in wazuh-indexer wazuh-manager; do
  sudo mkdir -p /etc/systemd/system/${svc}.service.d
  printf '[Service]\nTimeoutStartSec=900\n' | sudo tee /etc/systemd/system/${svc}.service.d/timeout.conf
done
sudo systemctl daemon-reload

# 2. Dashboard: wait 2 min for the indexer instead of 20 s
echo 'opensearch.requestTimeout: 120000' | sudo tee -a /etc/wazuh-dashboard/opensearch_dashboards.yml

# 3. 2 GB swap so memory spikes don't kill wazuh-modulesd
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# --- Deploy lab content ------------------------------------------------------
# sudo cp rules/local_rules.xml /var/ossec/etc/rules/local_rules.xml
# sudo cp config/agent.conf     /var/ossec/etc/shared/default/agent.conf
# Safe restart (stop dashboard first to avoid API login lockout):
# sudo /var/ossec/bin/wazuh-analysisd -t && sudo systemctl stop wazuh-dashboard \
#   && sudo systemctl restart wazuh-manager && sleep 60 && sudo systemctl start wazuh-dashboard
