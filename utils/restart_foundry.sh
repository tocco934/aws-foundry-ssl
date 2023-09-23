#!/bin/bash

if [ "${EUID}" -ne 0 ]; then
    echo "Please run this script as root (sudo sh ./restart_foundry.sh)"
    exit 1
fi

echo "Restarting the Foundry service..."
systemctl restart foundry

echo "Done!"
