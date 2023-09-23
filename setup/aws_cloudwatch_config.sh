#!/bin/bash
sudo cp /aws-foundry-ssl/setup/amazon/cloudwatch_logs.json /opt/aws/amazon-cloudwatch-agent/bin/config.json

# Let's start the agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
