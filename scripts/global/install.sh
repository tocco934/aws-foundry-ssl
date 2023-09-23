#!/bin/bash

# These files are created in the CloudFormation script
source /foundryssl/variables.sh
source /foundryssl/variables_tmp.sh

# Set up logging to the logfile
exec > /tmp/foundry-setup.log 2>&1
set -x

# Install foundry
echo "======= INSTALLING DEPENDENCIES ======="
sudo dnf install https://rpm.nodesource.com/pub_18.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
sudo dnf install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1
sudo dnf install -y openssl-devel
sudo dnf install -y amazon-cloudwatch-agent

# Install foundry
echo "======= INSTALLING FOUNDRY ======="
source /aws-foundry-ssl/scripts/global/foundry.sh

# Install nginx
echo "======= INSTALLING NGINX ======="
source /aws-foundry-ssl/scripts/global/nginx.sh

# Amazon Cloudwatch logs and domain registrar and
echo "===== INSTALLING AWS CLOUDWATCH AND HOSTED ZONE CRON ====="
source /aws-foundry-ssl/scripts/amazon/cloudwatch_config.sh
source /aws-foundry-ssl/scripts/amazon/hosted_zone_id.sh

# Set up SSL certificates with LetsEncrypt
echo "======= INSTALLING LETSENCRYPT CERTBOT ======="
source /aws-foundry-ssl/scripts/global/certbot.sh

# Restart Foundry so AWS.json is fully loaded
echo "===== RESTARTING FOUNDRY ====="
sudo systemctl restart foundry

# Clean up install files (Comment out during testing)
echo "===== CLEANUP AND USER PERMISSIONS ====="
sudo usermod -a -G foundry ec2-user
sudo chmod 700 /tmp/foundry-setup.log
sudo rm /foundryssl/variables_temp.sh
# sudo rm -r /aws-foundry-ssl

echo "===== DONE ====="
echo "Finished setting up Foundry!"
