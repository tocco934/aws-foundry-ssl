#!/bin/bash
source /foundryssl/variables.sh

echo $PATH > /var/log/foundrycron/path.log 2>&1

if [ "${enable_letsencrypt}" == "False" ]; then
    echo "LetsEncrypt is disabled; exiting..."
    exit 0
fi

if [ "${email}" == "" ]; then
    echo "Email address is not configured; exiting..."
    exit 1
fi

if [ -d "/etc/letsencrypt/live/${subdomain}.${fqdn}" ]; then
    echo "Checking SSL certificate for renewal..."

    # Certificate exists, we can check if it needs renewal
    certbot renew --nginx --no-random-sleep-on-renew --post-hook "systemctl restart nginx" > /var/log/foundrycron/certbot_renew.log 2>&1
else
    echo "SSL certificate not found, attempting to set it up..."

    # Try to fetch the certificates
    certbot --agree-tos -n --nginx -d ${subdomain}.${fqdn} -m ${email} --no-eff-email

    # Install certificates for optional webserver
    if [[ ${webserver_bool} == 'True' ]]; then
        certbot --agree-tos -n --nginx -d ${fqdn},www.${fqdn} -m ${email} --no-eff-email
    fi
fi
