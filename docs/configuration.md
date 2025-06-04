---
layout: default
title: "Configuration Guide"
description: "Configure OpenVPN for bridge mode operation"
nav_order: 3
---

# Configuration Guide

This page covers the configuration steps needed to set up OpenVPN in bridge mode after the initial installation.

## Table of Contents
- [Step 6: Configure OpenVPN for Bridge Mode](#step-6-configure-openvpn-for-bridge-mode)
- [Step 7: Configure the Bridge Script](#step-7-configure-the-bridge-script)
- [Step 8: Test the Configuration](#step-8-test-the-configuration)
- [Step 9: Configure the Client](#step-9-configure-the-client)
- [Step 10: Configure Router Port Forwarding](#step-10-configure-router-port-forwarding)

---

## Step 6: Configure OpenVPN for Bridge Mode

### Modify Server Configuration

1. **Backup the original configuration**:
   ```bash
   sudo cp /etc/openvpn/server/server.conf /etc/openvpn/server/server.conf.backup
   ```

2. **Edit the server configuration**:
   ```bash
   sudo nano /etc/openvpn/server/server.conf
   ```

3. **Make these changes**:

   **Comment out or remove these lines** (add `#` at the beginning):
   ```conf
   #server 10.8.0.0 255.255.255.0
   #push "redirect-gateway def1 bypass-dhcp"
   #push "dhcp-option DNS 176.103.130.130"
   #push "dhcp-option DNS 176.103.130.131"
   ```

   **Add these lines** (adjust IP addresses for your network):
   ```conf
   # Bridge mode configuration
   dev tap0
   dev-type tap
   server-bridge 10.99.99.134 255.255.255.0 10.99.99.200 10.99.99.210
   
   # Bridge scripts
   up "/etc/openvpn/bridge_start.sh"
   down "/etc/openvpn/bridge_stop.sh"
   
   # Additional bridge settings
   script-security 2
   ```

### Example Configurations

#### For network 10.99.99.0/24:
```conf
server-bridge 10.99.99.134 255.255.255.0 10.99.99.200 10.99.99.210
```

#### For network 172.16.100.0/24:
```conf
server-bridge 172.16.100.134 255.255.255.0 172.16.100.200 172.16.100.210
```

### Understanding the Configuration

- **`dev tap0`**: Creates a TAP (Layer 2) interface instead of TUN (Layer 3)
- **`dev-type tap`**: Explicitly specifies TAP mode
- **`server-bridge`**: Defines the bridge configuration:
  - `10.99.99.134`: Server IP address (your Raspberry Pi's IP)
  - `255.255.255.0`: Subnet mask
  - `10.99.99.200`: Start of VPN client IP range
  - `10.99.99.210`: End of VPN client IP range
- **`up/down`**: Scripts to run when the VPN starts/stops
- **`script-security 2`**: Allows execution of bridge scripts

### Important Considerations

- Ensure the VPN client IP range (200-210) doesn't conflict with your DHCP range
- The server IP should be your Raspberry Pi's static IP
- All IPs must be in the same subnet as your local network

---

## Step 7: Configure the Bridge Script

The bridge script creates a network bridge that connects your physical network interface with the VPN's TAP interface.

### Install the Bridge Script

1. **Download the bridge scripts**:
   ```bash
   sudo wget -O /etc/openvpn/bridge_start.sh https://raw.githubusercontent.com/linuxdevel/openvpn/main/bridge_start.sh
   sudo wget -O /etc/openvpn/bridge_stop.sh https://raw.githubusercontent.com/linuxdevel/openvpn/main/bridge_stop.sh
   ```

2. **Make scripts executable**:
   ```bash
   sudo chmod +x /etc/openvpn/bridge_start.sh
   sudo chmod +x /etc/openvpn/bridge_stop.sh
   ```

### Configure Network Settings

3. **Edit the bridge start script**:
   ```bash
   sudo nano /etc/openvpn/bridge_start.sh
   ```

4. **Modify these variables** to match your network:
   ```bash
   # Define physical ethernet interface to be bridged
   eth="eth0"                    # Your network interface name
   eth_ip="10.99.99.134"        # Your Raspberry Pi's IP
   eth_netmask="255.255.255.0"  # Your network mask
   eth_broadcast="10.99.99.255" # Your broadcast address
   eth_gateway="10.99.99.1"     # Your router's IP
   eth_mac="e4:5f:01:75:0b:9e"  # Your Pi's MAC address
   ```

### Example Configurations

#### For network 10.99.99.0/24:
```bash
eth="eth0"
eth_ip="10.99.99.134"
eth_netmask="255.255.255.0"
eth_broadcast="10.99.99.255"
eth_gateway="10.99.99.1"
eth_mac="aa:bb:cc:dd:ee:ff"  # Replace with your actual MAC
```

#### For network 172.16.100.0/24:
```bash
eth="eth0"
eth_ip="172.16.100.134"
eth_netmask="255.255.255.0"
eth_broadcast="172.16.100.255"
eth_gateway="172.16.100.1"
eth_mac="aa:bb:cc:dd:ee:ff"  # Replace with your actual MAC
```

### Finding Your Network Information

**Get your interface name**:
```bash
ip link show
```

**Get your MAC address**:
```bash
ip link show eth0 | grep ether
```

**Get your current network settings**:
```bash
ip addr show eth0
ip route show default
```

### Verify Script Configuration

5. **Test the bridge script manually**:
   ```bash
   sudo /etc/openvpn/bridge_start.sh
   ```

6. **Check if bridge was created**:
   ```bash
   brctl show
   ip addr show br0
   ```

7. **Stop the bridge for now**:
   ```bash
   sudo /etc/openvpn/bridge_stop.sh
   ```

---

## Step 8: Test the Configuration

### Start OpenVPN Service

1. **Start the OpenVPN service**:
   ```bash
   sudo systemctl start openvpn-server@server
   ```

2. **Check service status**:
   ```bash
   sudo systemctl status openvpn-server@server
   ```

3. **Check logs for errors**:
   ```bash
   sudo journalctl -u openvpn-server@server -f
   ```

### Verify Bridge Creation

4. **Check if bridge interfaces are created**:
   ```bash
   brctl show
   ip addr show br0
   ip addr show tap0
   ```

5. **Verify network connectivity**:
   ```bash
   ping google.com
   ping 10.99.99.1  # Your router
   ```

### Common Issues and Solutions

- **Bridge not created**: Check bridge script permissions and syntax
- **No network connectivity**: Verify IP addresses and gateway settings
- **OpenVPN won't start**: Check configuration syntax and log files

---

## Step 9: Configure the Client

### Modify Client Configuration

1. **Download the client configuration file** from your Raspberry Pi:
   ```bash
   scp pi@10.99.99.134:~/client-name.ovpn ./
   ```

2. **Edit the client configuration file**:
   Open the `.ovpn` file in a text editor and make these changes:

   **Add or modify these lines**:
   ```conf
   # Change from 'dev tun' to 'dev tap'
   dev tap
   
   # Remove or comment out these lines if present:
   #pull
   #redirect-gateway def1
   
   # Add these lines for bridge mode:
   dev-type tap
   ```

### Additional Client Settings

3. **Optional: Add specific routes** if you only want to access certain networks:
   ```conf
   # Route only specific networks through VPN
   route 10.99.99.0 255.255.255.0
   ```

4. **Optional: Configure DNS** (add these lines if you want to use specific DNS servers):
   ```conf
   dhcp-option DNS 8.8.8.8
   dhcp-option DNS 8.8.4.4
   ```

### Client Installation

**Windows**: Use OpenVPN GUI or OpenVPN Connect
**macOS**: Use Tunnelblick or OpenVPN Connect  
**Linux**: Use NetworkManager or command line OpenVPN
**Android/iOS**: Use OpenVPN Connect app

### Test the Configuration

5. **Connect with the client** and verify:
   - You receive an IP in the range 10.99.99.200-210
   - You can ping devices on the local network
   - You can access local services (file shares, printers, etc.)

---

## Step 10: Configure Router Port Forwarding

### Access Router Configuration

1. **Open your router's admin interface**:
   - Usually accessible at `http://10.99.99.1` or `http://192.168.1.1`
   - Login with your router's admin credentials

### Configure Port Forwarding

2. **Navigate to Port Forwarding settings**:
   - Look for "Port Forwarding", "Virtual Servers", or "NAT" settings
   - The exact menu location varies by router brand

3. **Create a new port forwarding rule**:
   - **Service Name**: OpenVPN
   - **External Port**: 1194 (or the port you chose during installation)
   - **Internal IP**: 10.99.99.134 (your Raspberry Pi's IP)
   - **Internal Port**: 1194
   - **Protocol**: UDP

### Security Considerations

- **Change the default port**: Consider using a non-standard port like 443 or 8080
- **Enable fail2ban**: Install fail2ban to prevent brute force attacks
- **Use strong certificates**: The Angristan script already provides this
- **Regular updates**: Keep your system updated

### Common Router Interfaces

**Linksys**: Advanced → Security → Firewall → Port Forwarding
**Netgear**: Dynamic DNS → Port Forwarding / Port Triggering  
**TP-Link**: Advanced → NAT Forwarding → Port Forwarding
**ASUS**: Adaptive QoS → Traditional QoS → Port Forwarding
**D-Link**: Advanced → Port Forwarding

### Test Port Forwarding

4. **Use an online port checker**:
   - Visit a port checking website like portchecker.co
   - Enter your external IP and port 1194
   - Should show "Open" if configured correctly

5. **Test from external network**:
   - Try connecting to your VPN from a mobile hotspot or different network
   - Should be able to connect and access local resources

### Dynamic DNS (Optional but Recommended)

If your ISP assigns dynamic IP addresses, consider setting up Dynamic DNS:

6. **Choose a Dynamic DNS provider**:
   - **DuckDNS**: Free and simple
   - **No-IP**: Free with limitations
   - **CloudFlare**: Free tier available

7. **Configure Dynamic DNS** on your router or Raspberry Pi to automatically update your hostname when your IP changes.

---

## Verification Checklist

After completing all configuration steps, verify:

- [ ] OpenVPN service starts without errors
- [ ] Bridge interface (br0) is created and has correct IP
- [ ] TAP interface (tap0) is created and bridged
- [ ] Port forwarding is configured correctly
- [ ] Client can connect and receive bridge mode IP
- [ ] Client can access local network resources
- [ ] Client can browse internet through VPN

If any step fails, refer to the [Troubleshooting Guide](troubleshooting.html) for solutions.

---

## Next Steps

Once your VPN is working correctly:

1. **Create additional client certificates** for other devices
2. **Set up monitoring** to track VPN usage and performance
3. **Configure automatic backups** of your certificates and configuration
4. **Consider additional security measures** like two-factor authentication

For ongoing maintenance and troubleshooting, see the [Troubleshooting Guide](troubleshooting.html).