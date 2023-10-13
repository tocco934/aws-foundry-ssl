#!/bin/bash

# -------------------------------------
# Manually restart FoundryVTT if needed
# -------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this script as root (sudo ./restart_foundry.sh)"
    exit 1
fi

echo "Restarting the Foundry service..."
systemctl restart foundry

echo "Done!"
