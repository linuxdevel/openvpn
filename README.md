# Raspberry PI/Linux openvpn server in bridge mode
A very brief instruction on how to make a bridged network over openvpn. Keep in mind it is good to use a static IP on your PI for this setup to work smooth, this can be achieved by either configuring it with a static address (e.g. using raspi-config) outside the range of your local DHCP server -  or configure your DHCP server (in your router) to reserve a static IP from the DHCP pool for the PI.

PS.. The examples on openvpn website are missing some important steps in the bridge_start.sh script.. Those steps are included in this version of the script.
Remember to update the bridge_start.sh script to math your network setup.

Bridge mode works very well with ExpertSDR3 if you are into ham-radio, you dont have to use the eesdr cloud solution at all! 

## Install RPI OS on your device memory card
https://raspberrytips.com/install-raspberry-pi-os/

## logon to your RPI
https://raspberrypi-guide.github.io/getting-started/raspberry-pi-configuration

If this raspberry PI is only going to be used as an openvpn server, I reccommend disabling GUI mode. It can be done in a console using the command raspi-config:
- Start raspi-config in a terminal window
- select menu 1 (System config),
- Select menu S5
- Select B1 Console

If you also want to enable ssh access to your raspberry, go into menu 3 Interface options (in main menu)
Select I2 SSH and enable SSH remote commandline access.

Save and quit raspi-config

Please also remember to change the default password for the "pi" user, use a more complicated/hard to guess password.. And you could also setup authentication with SSH key... 

Enter command to reboot the device : 
- user@raspberry~: sudo reboot -h now

## Enable automatic update of your PI
In order for your raspberry PI to stay up to date and secure I recommend enabling automatic update of the different software packages installed.
Follow the instructions here :
```
https://www.zealfortechnology.com/2018/08/configure-unattended-upgrades-on-raspberry-pi.html 
```
or here 
```
https://www.seancarney.ca/2021/02/06/secure-your-raspberry-pi-by-enabling-automatic-software-updates/#:~:text=sudo%20dpkg-reconfigure%20--priority%3Dlow%20unattended-upgrades%20You%E2%80%99ll%20be%20presented%20with,the%20latest%20software%20updates%20as%20they%20become%20available.
```
## install bridge-utils
```
user@rpi:~/vpn# sudo apt install bridge-utils
```
## install openvpn-install script
Download script:
```
user@rpi:~/vpn# curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
```
Set execute bit:
```
user@rpi:~/vpn# chmod +x openvpn-install.sh
```
Run it:
```
user@rpi:~/vpn# sudo ./openvpn-install.sh
```
Select options as wanted. Not described here. If not sure, use defaults. But do protect your key with a password.
(Select elliptic curve key, e.g. a key based on curve P-521.. 

Edit server.conf manually and change line 
```
dev tun
```
to
```
dev tap0
```

And

Change the line starting with server to:
```
server-bridge <IP address of RPI> <netmask> <start IP address of VPN clients> <end IP address of VPN clients>
```
example:
```
  server-bridge 10.98.99.2 255.255.255.0 10.98.99.250 10.98.99.254
```
For Example values above. Make sure that the IP range for VPN clients are outside the range that your DHCP server serves to its local clients!
See also example server.conf here:
```
port 1194
proto udp6
dev tap0
user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
topology subnet
server-bridge 10.98.99.134 255.255.255.0 10.98.99.230 10.98.99.231
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "redirect-gateway def1 bypass-dhcp"
dh none
ecdh-curve secp521r1
tls-crypt tls-crypt.key
crl-verify crl.pem
ca ca.crt
cert server_pDpSWqj8rGdh6zsK.crt
key server_pDpSWqj8rGdh6zsK.key
auth SHA512
cipher AES-256-GCM
#ncp-ciphers AES-256-GCM
data-ciphers AES-256-GCM
tls-server
tls-version-min 1.2
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384
client-config-dir /etc/openvpn/ccd
status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3
```
## bridge_start script
Copy script bridge_start.sh to /etc/openvpn

Make it executable with 
```
chmod +x /etc/openvpn/bridge_start.sh
```
Edit the script to suit your network settings using your favourite text editor - personally I love "vi".
Note that the eth_ip IP address and the eth_mac in bridge_start.sh must be identical to your RPI. You can find the values by running the command shown below:
root@raspberrypi:~# ifconfig
Look for the info in the section named eth0 (if your PI is connected with cable, otherwise look at the values in the section named wlan0.
IP address and netmask is listed at the line starting with "inet" and the mac address of your PI is listed right after the word "ether". 

## Auto startup of script
edit /etc/rc.local, add a line:
```
sudo /etc/openvpn/bridge_start.sh
```

just before the exit 0 at the bottom.

The script will then run when the RPI is starting up and it will create necessary network devices for bridging the VPN connection.

## client
Edit the client.ovpn file that was created by the openvpn-install.sh script. Change the line that starts with:
```
dev tun
```
to 
```
dev tap
```
The client configuration should also contain your public IP address in the line starting with "remote". Here you have to decide if you want to use your IP (The public IP will most likely change every now and then unless you have a static public IP) or if you want to use e.g. dyndns and a hostname instead. Latter is better.
Import the client.ovpn file in the client and play around with your new vpn
## Router port forwarding
In order for the VPN server to be used, you need to forward a UDP port from internet to your raspberry PI device. The openvpn server defaults to UDP port 1194 but it is probably better to change it to a different value, e.g. 21194 or any other high value.
In your router you then need to setup UDP portforwarding from internet to your PI IP/PORT. How this is done varies from router to router.

## Useful links
https://www.aaflalo.me/2015/01/openvpn-tap-bridge-mode/

https://openvpn.net/community-resources/ethernet-bridging/  (PS, the bridge startup script on this page is missing some commands)

https://www.noip.com (Dynamic DNS)

https://www.cloudns.net (Dynamic DNS)

https://raspberrytips.com/set-static-ip-address-raspberry-pi/

## Thoughts
Sometimes when using a VPN from/to a private network you could end up in this example scenario:

```
client (address 192.168.1.y) -> openvpn -> remote openvpn server (address 192.168.1.x) -> remote vlan (addr: 192.168.1...)
```
Where your local network has the same subnet as the remote. This will cause issues and the VPN will not work. 

If you have control of the network where you raspberry openvpn server is installed, select a private IP range that is unlikely to be used from a remote client.. 
```
Example: 
Private network not likely to be used in any commercial home routers: 10.11,12.0/24 
Address range: 10.11.12.1 -> 10.11.12.254

```

