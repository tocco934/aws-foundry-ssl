#!/bin/bash
exec > /tmp/foundry-setup.log 2>&1
set -x

# These files are created in the CloudFormation script
source /foundryssl/variables.sh
source /foundryssl/variables_temp.sh

# Install foundry
source /aws-foundry-ssl/scripts/global/foundry.sh

# Install nginx
source /aws-foundry-ssl/scripts/global/nginx.sh

# Set up SSL certificates with LetsEncrypt
source /aws-foundry-ssl/scripts/global/certbot.sh

# Amazon Cloudwatch logs and domain registrar and
source /aws-foundry-ssl/scripts/amazon/cloudwatch_config.sh
source /aws-foundry-ssl/scripts/amazon/hosted_zone_id.sh

# Restart Foundry so AWS.json is fully loaded
sudo systemctl restart foundry

# Clean up install files (Comment out during testing)
sudo chmod 700 /tmp/foundry-setup.log
sudo rm -r /aws-foundry-ssl
sudo rm /foundryssl/variables_temp.sh

echo "Finished!"
