#!/bin/bash

# Print the iptables rule to allow established and related TCP connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Get a comma-separated list of all TCP ports that are currently open and store them in a variable
open_ports=$(netstat -ntlp | awk 'NR > 2 && $6 == "LISTEN" { split($4, a, ":"); printf "%s\n", a[length(a)] }' | sort -u |  tr '\n' ','| sed 's/,$//')
# Print a single iptables rule that allows incoming traffic on all the open TCP ports
iptables -A INPUT -p tcp -m multiport --dports $open_ports -j ACCEPT

# Print a final rule that drops any other incoming TCP connections
iptables -A INPUT -p tcp -j DROP
