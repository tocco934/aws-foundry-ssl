#!/bin/bash
exec > /tmp/foundry-setup.log 2>&1
set -x

source /foundryssl/variables.sh
source /foundryssl/variables_temp.sh

# amazon domain registrar
sleep 20s
source /aws-foundry-ssl/scripts/amazon/hosted_zone_id.sh

# install foundry
source /aws-foundry-ssl/scripts/global/foundry.sh

# install nginx
source /aws-foundry-ssl/scripts/global/nginx.sh

# set up certificates
source /aws-foundry-ssl/scripts/global/certbot.sh

# clean up install files
# Do not do this during testing
chmod 700 /tmp/foundry-setup.log
sudo rm -r /aws-foundry-ssl
sudo rm /foundryssl/variables_temp.sh

#Restart Foundry So AWS.json is fully loaded
sudo systemctl restart foundry
