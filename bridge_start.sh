#!/bin/bash

#################################
# Set up Ethernet bridge on Linux
# Requires: bridge-utils
#################################

# Define Bridge Interface
br="br0"

# Define list of TAP interfaces to be bridged,
# for example tap="tap0 tap1 tap2".
tap="tap0"

# Define physical ethernet interface to be bridged
# with TAP interface(s) above.
# Update according to your network setup. Below is just example
eth="eth0"
eth_ip="192.168.1.134"
eth_netmask="255.255.255.0"
eth_broadcast="192.168.1.255"
eth_gateway="192.168.1.1"
eth_mac="e4:5f:01:75:0b:9e"

for t in $tap; do
    openvpn --mktun --dev $t
done

brctl addbr $br
brctl addif $br $eth

for t in $tap; do
    brctl addif $br $t
done

for t in $tap; do
    ifconfig $t 0.0.0.0 promisc up
    iptables -A INPUT -i $t -j ACCEPT
done

iptables -A INPUT -i $br -j ACCEPT
iptables -A FORWARD -i $br -j ACCEPT

ifconfig $eth 0.0.0.0 promisc up

ifconfig $br $eth_ip netmask $eth_netmask broadcast $eth_broadcast


#iptables -A INPUT -i tap0 -j ACCEPT
#iptables -A INPUT -i br0 -j ACCEPT
#iptables -A FORWARD -i br0 -j ACCEPT

ip link set $br address $eth_mac
route add default gw $eth_gateway $br
