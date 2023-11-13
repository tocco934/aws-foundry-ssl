#!/bin/bash
source /foundryssl/variables.sh

# NOTE: This script doesn't take into account if the hosting is behind CloudFront (*.cloudfront.net)
# @TODO: Make this stuff work for IPv6 AAAA (though how often will an IPv6 address change? :shrug:)
# @TODO: Investigate the timer setup as to whether it's triggering when an instance is restarted

# Retrieve public IP
public_ip="$(dig +short myip.opendns.com @resolver1.opendns.com)"

# Get IP for subdomain record
aws_sub_ip=`aws route53 list-resource-record-sets --hosted-zone-id ${zone_id} | jq ".ResourceRecordSets[] | select(.Name==\"${subdomain}.${fqdn}.\") | select(.Type==\"A\") | .ResourceRecords[] | .Value" | cut -d '"' -f2`

echo "Public IP: ${public_ip}"
echo "AWS Route53 subdomain IP: ${aws_sub_ip}"

if [[ "${aws_sub_ip}" != "" ]]; then
    # If it doesn't match then create temp dns_block.json replacing domain_here and ip_here with values
    if [[ "${public_ip}" != "${aws_sub_ip}" ]]; then
        echo "Requesting change for subdomain IP"
        # Change subdomain record
        aws route53 change-resource-record-sets --hosted-zone-id ${zone_id} --change-batch "{ \"Comment\": \"Dynamic DNS change\", \"Changes\": [ { \"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${subdomain}.${fqdn}.\", \"Type\": \"A\", \"TTL\": 120, \"ResourceRecords\": [ { \"Value\": \"${public_ip}\" } ] } } ] }"
    else
        echo "${subdomain}.${fqdn} IP ${public_ip} matches EC2 IP ${aws_sub_ip}, nothing to do here..."
    fi
else
    echo "${subdomain}.${fqdn} IP doesn't exist yet, probably waiting for CloudFormation..."
fi

# Webserver additional
if [[ "${webserver_bool}" == "True" ]]; then
    # Get IP for subdomain record
    aws_ip=`aws route53 list-resource-record-sets --hosted-zone-id ${zone_id} | jq ".ResourceRecordSets[] | select(.Name==\"${fqdn}.\") | select(.Type==\"A\") | .ResourceRecords[] | .Value" | cut -d '"' -f2`

    echo "AWS Route53 primary domain IP: ${aws_ip}"

    if [[ "${aws_ip}" != "" ]]; then
        if [[ "${public_ip}" != "${aws_ip}" ]]; then
            echo "Requesting change for primary domain IP"

            aws route53 change-resource-record-sets --hosted-zone-id ${zone_id} --change-batch "{ \"Comment\": \"Dynamic DNS change\", \"Changes\": [ { \"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"${fqdn}.\", \"Type\": \"A\", \"TTL\": 120, \"ResourceRecords\": [ { \"Value\": \"${public_ip}\" } ] } } ] }"
        else
            echo "${fqdn} IP ${public_ip} matches EC2 IP ${aws_ip}, nothing to do here..."
        fi
    else
        echo "${fqdn} IP doesn't exist yet, probably waiting for CloudFormation..."
    fi
fi