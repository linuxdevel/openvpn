#!/bin/bash

#################################
# Tear down Ethernet bridge on Linux
# Requires: bridge-utils
#################################

# Define Bridge Interface
br="br0"

# Define list of TAP interfaces to be bridged,
# for example tap="tap0 tap1 tap2".
tap="tap0"

# Define physical ethernet interface
eth="eth0"
eth_ip="192.168.1.134"
eth_netmask="255.255.255.0"
eth_broadcast="192.168.1.255"
eth_gateway="192.168.1.1"

# Remove default route
route del default gw $eth_gateway

# Remove iptables rules
iptables -D FORWARD -i $br -j ACCEPT 2>/dev/null
iptables -D INPUT -i $br -j ACCEPT 2>/dev/null

for t in $tap; do
    iptables -D INPUT -i $t -j ACCEPT 2>/dev/null
done

# Bring down bridge interface
ifconfig $br down

# Remove interfaces from bridge
for t in $tap; do
    brctl delif $br $t 2>/dev/null
done

brctl delif $br $eth 2>/dev/null

# Delete bridge
brctl delbr $br 2>/dev/null

# Remove TAP interfaces
for t in $tap; do
    openvpn --rmtun --dev $t 2>/dev/null
done

# Restore original ethernet interface
ifconfig $eth $eth_ip netmask $eth_netmask broadcast $eth_broadcast up
route add default gw $eth_gateway