#!/bin/bash
source /foundryssl/variables.sh

# Install augeas
sudo dnf install -y augeas-libs

# Setup and install python env for certbot and then certbot
sudo python3 -m venv /opt/certbot/
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Set up autorenew SSL certs
sudo cp /aws-foundry-ssl/files/certbot/certbot.sh /foundrycron/certbot.sh
sudo cp /aws-foundry-ssl/files/certbot/certbot_start.service /etc/systemd/system/
sudo cp /aws-foundry-ssl/files/certbot/certbot_start.timer /etc/systemd/system/
sudo cp /aws-foundry-ssl/files/certbot/certbot_renew.service /etc/systemd/system/
sudo cp /aws-foundry-ssl/files/certbot/certbot_renew.timer /etc/systemd/system/

# Not sure what this does?
sudo sed -i -e "s|location / {|include conf.d/drop;\n\n\tlocation / {|g" /etc/nginx/conf.d/foundryvtt.conf
sudo cp /aws-foundry-ssl/files/nginx/drop /etc/nginx/conf.d/drop

# Configure Foundry to use SSL
sudo sed -i 's/"proxyPort":.*/"proxyPort": "443",/g' /foundrydata/Config/options.json
sudo sed -i 's/"proxySSL":.*/"proxySSL": true,/g' /foundrydata/Config/options.json

# Kick off certbot
sudo touch /var/log/foundrycron/certbot_renew.log

# Run the script in another process
sudo systemctl daemon-reload
sudo systemctl enable --now certbot_start.timer
sudo systemctl enable --now certbot_renew.timer
