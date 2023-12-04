#!/bin/bash
source /foundryssl/variables.sh

echo $PATH > /var/log/foundrycron/certbot_renew.log 2>&1

if [[ "${enable_letsencrypt}" == "False" ]]; then
    echo "LetsEncrypt is disabled - check /foundryssl/variables.sh; exiting..."
    exit 0
fi

if [[ -z "${email}" ]]; then
    echo "Email address is not configured; exiting..."
    exit 1
fi

if [[ -z "${subdomain}" ]]; then
    echo "Subdomain is not configured; exiting..."
    exit 1
fi

if [[ -z "${fqdn}" ]]; then
    echo "Fully qualified domain name is not configured; exiting..."
    exit 1
fi

if [[ -d "/etc/letsencrypt/live/${subdomain}.${fqdn}" ]]; then
    echo "Checking TLS certificate for renewal..."

    # Certificate exists, we can check if it needs renewal
    certbot renew --nginx --no-random-sleep-on-renew
    # --post-hook "systemctl restart nginx"
else
    echo "TLS certificate not found, attempting to set it up..."

    # Try to fetch the certificates
    certbot --agree-tos -n --nginx -d ${subdomain}.${fqdn} -m ${email} --no-eff-email

    # Install certificates for optional webserver
    if [[ ${webserver_bool} == 'True' ]]; then
        certbot --agree-tos -n --nginx -d ${fqdn},www.${fqdn} -m ${email} --no-eff-email
    fi
fi

# Force a hacky upgrade to http2 for SSL only
# I'm assuming this won't be reset by certbot, but just in case...
# This can likely be negated once nginx 1.25.x+ is available for Amazon Linux
# 2023 as it has a separate http2 option instead of under `listen`
sudo sed -i 's/:443 ssl ipv6only=on;/:443 ssl http2 ipv6only=on;/g' /etc/nginx/conf.d/foundryvtt.conf
sudo sed -i 's/443 ssl;/443 ssl http2;/g' /etc/nginx/conf.d/foundryvtt.conf

systemctl restart nginx