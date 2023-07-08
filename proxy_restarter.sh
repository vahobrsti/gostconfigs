#!/bin/bash
set -xe
current_time=$(date +"%B %d, %Y %H:%M:%S")
echo "Current Time : $current_time"

# Stop the proxy service
systemctl stop haproxy

# Wait for 4 minutes
sleep 240

# Start the proxy service
systemctl start haproxy