# Raspberry PI/Linux openvpn server in bridge mode
A very brief instruction on how to make a bridged network over openvpn.
PS.. The examples on openvpn website are missing some important steps in the bridge_start.sh script.. Those steps are included in this version of the script.

P/S, this works very well with ExpertSDR3 if you are into ham-radio, you dont have to use the eesdr cloud solution at all! 

## Install RPI OS on your device memory card

## logon to your RPI

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
user@rpi:~/vpn# ./openvpn-install.sh
```
Select options as wanted. Not described here. If not sure, use defaults. But do protect your key with a password.

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
server-bridge <IP address of RPI> 255.255.255.0 <start IP address of VPN clients> <end IP address of VPN clients>
```
example:
```
  server-bridge 10.98.99.2 255.255.255.0 10.98.99.250 10.98.99.254
```
For Example values above. Make sure that the IP range for VPN clients are outside the range that your DHCP server serves to its local clients!

## bridge_start script
Copy script bridge_start.sh to e.g. /etc/openvpn

Make it executable with 
```
chmod +x /etc/openvpn/bridge_start.sh
```

Edit the script to suit your network settings.

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

Import the client.ovpn file in the client and play around with your new vpn

## Useful links
https://www.aaflalo.me/2015/01/openvpn-tap-bridge-mode/

https://openvpn.net/community-resources/ethernet-bridging/  (PS, the bridge startup script on this page is missing some commands)

## Thoughts
Sometimes when using a VPN from/to a private network you could end up in this example scenario:

```
client (address 192.168.1.y) -> openvpn -> remote openvpn server (address 192.168.1.x) -> remote vlan (addr: 192.168.1...)
```
Where your local network has the same subnet as the remote. This will cause issues. 


If you have control of the remote network, select a private IP range that is unlikely to be used from a remote client.. 
```
TODO find examples of ranges unlikely to be used by routers
```

