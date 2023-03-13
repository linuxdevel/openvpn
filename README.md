# Raspberry PI openvpn server in bridge mode
A very brief instruction on how to make a bridged network over openvpn.
PS.. The examples on openvpn website are missing some important steps in the bridge_start.sh script.. Those steps are included in this version of the script.

Install RPI OS on your device memory card

logon to your RPI

install bridge-utils:

user@rpi:~/vpn# sudo apt install bridge-utils

install openvpn-install script:
Download script:
user@rpi:~/vpn# curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
Set execute bit:
user@rpi:~/vpn# chmod +x openvpn-install.sh
Run it:
user@rpi:~/vpn# ./openvpn-install.sh

Select options as wanted. Not described here. If not sure, use defaults. But do protect your key with a password.

Edit server.conf manually and change line 
dev tun
to
dev tap0

Copy script bridge_start.sh to e.g. /etc/openvpn
Make it executable with chmod +x /etc/openvpn/bridge_start.sh
Edit the script to suit your network settings.

edit /etc/rc.local, add a line:
sudo /etc/openvpn/bridge_start.sh
just before the exit 0 at the bottom.
The script will then run when the RPI is starting up and it will create necessary network devices for bridging the VPN connection.

