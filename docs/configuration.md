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
- [Certificate Management](#certificate-management)

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
   server-bridge 10.11.12.2 255.255.255.0 10.11.12.200 10.11.12.210
   
   # Bridge scripts
   up "/etc/openvpn/bridge_start.sh"
   down "/etc/openvpn/bridge_stop.sh"
   
   # Additional bridge settings
   script-security 2
   ```

### Example Configurations

#### For network 10.11.12.0/24:
```conf
server-bridge 10.11.12.2 255.255.255.0 10.11.12.200 10.11.12.210
```

#### For network 172.16.100.0/24:
```conf
server-bridge 172.16.100.134 255.255.255.0 172.16.100.200 172.16.100.210
```

### Cipher Configuration

Modern OpenVPN installations may require `data-ciphers` instead of `ncp-ciphers`:

```conf
# Add or update these lines in your server configuration
cipher AES-256-CBC
data-ciphers AES-256-CBC

# For compatibility, you might also use:
# data-ciphers AES-256-CBC:AES-256-GCM
# cipher AES-256-CBC
```

**Note**: If you encounter "Cannot negotiate cipher" errors, ensure both server and client use `data-ciphers AES-256-CBC` and `cipher AES-256-CBC`.

### Understanding the Configuration

- **`dev tap0`**: Creates a TAP (Layer 2) interface instead of TUN (Layer 3)
- **`dev-type tap`**: Explicitly specifies TAP mode
- **`server-bridge`**: Defines the bridge configuration:
  - `10.11.12.2`: Server IP address (your Raspberry Pi's IP)
  - `255.255.255.0`: Subnet mask
  - `10.11.12.200`: Start of VPN client IP range
  - `10.11.12.210`: End of VPN client IP range
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
   eth_ip="10.11.12.2"          # Your Raspberry Pi's IP
   eth_netmask="255.255.255.0"  # Your network mask
   eth_broadcast="10.11.12.255" # Your broadcast address
   eth_gateway="10.11.12.1"     # Your router's IP
   eth_mac="e4:5f:01:75:0b:9e"  # Your Pi's MAC address
   ```

### Example Configurations

#### For network 10.11.12.0/24:
```bash
eth="eth0"
eth_ip="10.11.12.2"
eth_netmask="255.255.255.0"
eth_broadcast="10.11.12.255"
eth_gateway="10.11.12.1"
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
   ping 10.11.12.1  # Your router
   ```

### Common Issues and Solutions

- **Bridge not created**: Check bridge script permissions and syntax
- **No network connectivity**: Verify IP addresses and gateway settings
- **OpenVPN won't start**: Check configuration syntax and log files

---

## Step 9: Configure the Client

### Modify Client Template (Before Creating Users)

**Important**: The client template file is automatically installed at `/etc/openvpn/client-template.txt` during the initial OpenVPN setup. You need to modify this template **before** creating any client configurations, as it's used to generate each user's `.ovpn` file.

1. **Edit the client template file**:
   ```bash
   sudo nano /etc/openvpn/client-template.txt
   ```

2. **Make these essential changes for bridge mode**:

   **Change the device setting**:
   ```conf
   # Find the line that says 'dev tun' or 'dev tap' and change it to:
   dev tap0
   ```

   **Update the remote server setting**:
   ```conf
   # Find the line starting with 'remote' and change it to your server:
   remote myvpn-63864.duckdns.org 11194
   # OR use your public IP if not using Dynamic DNS:
   # remote YOUR_PUBLIC_IP 11194
   ```

   **Update cipher configuration**:
   ```conf
   # Find the line starting with 'cipher' and change it to:
   data-ciphers AES-256-CBC
   ```

### After Template Modification

3. **Create client configurations**:
   Once the template is modified, run the OpenVPN installer script to add users:
   ```bash
   sudo ./openvpn-install.sh
   # Choose option 1 to add a client
   ```

   The generated `.ovpn` files will automatically include your bridge mode settings.

### Modify Existing Client Configurations

If you already have client configurations that need to be updated:

4. **Download existing client configuration files** from your Raspberry Pi:
   ```bash
   scp pi@10.11.12.2:~/client-name.ovpn ./
   ```

5. **Edit each existing client configuration file**:
   Open the `.ovpn` file in a text editor and make the same changes as above:

   **Change device setting**:
   ```conf
   # Change from 'dev tun' to 'dev tap0'
   dev tap0
   ```

   **Update remote server**:
   ```conf
   remote myvpn-63864.duckdns.org 11194
   ```

   **Update cipher configuration**:
   ```conf
   # Change 'cipher' to 'data-ciphers'
   data-ciphers AES-256-CBC
   ```

   **Add device type for bridge mode**:
   ```conf
   # Add this line for bridge mode:
   dev-type tap
   ```

### Additional Client Settings

3. **Optional: Add specific routes** if you only want to access certain networks:
   ```conf
   # Route only specific networks through VPN
   route 10.11.12.0 255.255.255.0
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
   - You receive an IP in the range 10.11.12.200-210
   - You can ping devices on the local network
   - You can access local services (file shares, printers, etc.)

---

## Step 10: Configure Router Port Forwarding

### Access Router Configuration

1. **Open your router's admin interface**:
   - Usually accessible at `http://10.11.12.1` or `http://192.168.1.1`
   - Login with your router's admin credentials

### Configure Port Forwarding

2. **Navigate to Port Forwarding settings**:
   - Look for "Port Forwarding", "Virtual Servers", or "NAT" settings
   - The exact menu location varies by router brand

3. **Create a new port forwarding rule**:
   - **Service Name**: OpenVPN
   - **External Port**: 1194 (default) or custom port like 11194
   - **Internal IP**: 10.11.12.2 (your Raspberry Pi's IP)
   - **Internal Port**: 1194 (or matching custom port)
   - **Protocol**: UDP

### Example Configurations

**Standard Configuration**:
- External: 1194 UDP → Internal: 10.11.12.2:1194

**Custom Port with Different Networks**:
- External: 11194 UDP → Internal: 10.11.12.2:11194

**DNS Recommendation**: Set up a DNS record like `myvpn-63864.duckdns.org` pointing to your public IP for easier client configuration.

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
   - Enter your external IP and port (1194 or your custom port like 11194)
   - Should show "Open" if configured correctly

5. **Test from external network**:
   - Try connecting to your VPN from a mobile hotspot or different network
   - Should be able to connect and access local resources

### Dynamic DNS Setup (Recommended)

Dynamic DNS allows you to access your VPN using a domain name like `myvpn-63864.duckdns.org` instead of remembering your changing public IP address.

#### Why You Need Dynamic DNS

Most residential internet connections have dynamic (changing) IP addresses. Without Dynamic DNS:
- Your public IP changes periodically
- You'd need to update client configurations every time
- Connection becomes unreliable and inconvenient

#### Step 1: Choose a Dynamic DNS Provider

**Recommended: DuckDNS (Free and Simple)**
- Visit [duckdns.org](https://www.duckdns.org)
- Sign in with Google, Reddit, or GitHub
- Create a subdomain like `myvpn-63864` (full domain: `myvpn-63864.duckdns.org`)
- Note your token for configuration

**Alternatives:**
- **No-IP**: Free with limitations, requires monthly confirmation
- **CloudFlare**: Free tier with advanced features
- **Dynu**: Free with good features

#### Step 2: Configure Dynamic DNS Client

**Option A: Router Configuration (Recommended)**

Most modern routers support Dynamic DNS natively:

1. **Access router admin panel**:
   ```
   http://10.11.12.1 (or your router's IP)
   ```

2. **Navigate to Dynamic DNS settings**:
   - **Linksys**: Smart Wi-Fi Setup → Internet Settings → Dynamic DNS
   - **Netgear**: Dynamic DNS → DDNS Service
   - **TP-Link**: Advanced → Network → Dynamic DNS
   - **ASUS**: WAN → DDNS → Enable the DDNS Client
   - **D-Link**: Setup → Network Settings → Dynamic DNS

3. **Configure DuckDNS settings**:
   ```
   Service Provider: DuckDNS (or Custom/Other)
   Hostname: myvpn-63864.duckdns.org
   Username: nouser (DuckDNS doesn't use username)
   Password: your_duckdns_token
   ```

4. **Save and apply** the configuration

**Option B: Raspberry Pi Configuration**

If your router doesn't support Dynamic DNS, configure it on the Raspberry Pi:

1. **Install Dynamic DNS client**:
   ```bash
   sudo apt update
   sudo apt install ddclient curl -y
   ```

2. **Create DuckDNS update script**:
   ```bash
   sudo nano /usr/local/bin/duckdns-update.sh
   ```

3. **Add script content**:
   ```bash
   #!/bin/bash
   # DuckDNS Dynamic IP Update Script
   
   DOMAIN="myvpn-63864"
   TOKEN="your_duckdns_token_here"
   
   # Get current public IP
   CURRENT_IP=$(curl -s ifconfig.me)
   
   # Update DuckDNS
   curl -s "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=$CURRENT_IP"
   
   # Log the update
   echo "$(date): Updated $DOMAIN.duckdns.org to $CURRENT_IP" >> /var/log/duckdns.log
   ```

4. **Make script executable**:
   ```bash
   sudo chmod +x /usr/local/bin/duckdns-update.sh
   ```

5. **Test the script**:
   ```bash
   sudo /usr/local/bin/duckdns-update.sh
   ```

6. **Set up automatic updates with cron**:
   ```bash
   sudo crontab -e
   ```
   
   Add this line to update every 5 minutes:
   ```
   */5 * * * * /usr/local/bin/duckdns-update.sh >/dev/null 2>&1
   ```

**Option C: Alternative No-IP Setup**

If using No-IP instead of DuckDNS:

1. **Install No-IP client**:
   ```bash
   cd /usr/local/src
   sudo wget http://www.no-ip.com/client/linux/noip-duc-linux.tar.gz
   sudo tar xzf noip-duc-linux.tar.gz
   cd noip-2.1.9-1
   sudo make install
   ```

2. **Configure No-IP**:
   ```bash
   sudo /usr/local/bin/noip2 -C
   ```
   Enter your No-IP credentials and hostname

3. **Set up as service**:
   ```bash
   sudo systemctl enable noip2
   sudo systemctl start noip2
   ```

#### Step 3: Verify Dynamic DNS Setup

1. **Check current public IP**:
   ```bash
   curl ifconfig.me
   ```

2. **Verify DNS resolution**:
   ```bash
   nslookup myvpn-63864.duckdns.org
   dig myvpn-63864.duckdns.org
   ```

3. **Test from external network**:
   - Use a different network (mobile hotspot)
   - Try to resolve your domain name
   - Should return your current public IP

#### Step 4: Update OpenVPN Configuration

Once Dynamic DNS is working, update your client configurations:

1. **Edit client template for future users**:
   ```bash
   sudo nano /etc/openvpn/client-template.txt
   ```
   
   Update the remote line:
   ```conf
   remote myvpn-63864.duckdns.org 11194
   ```

#### Troubleshooting Dynamic DNS

**Common Issues:**

1. **DNS not resolving**:
   ```bash
   # Wait a few minutes after initial setup
   # Check provider status page
   # Verify token/credentials
   ```

2. **IP not updating**:
   ```bash
   # Check router logs
   # Verify internet connectivity
   # Manual update via provider website
   ```

3. **Script not running**:
   ```bash
   # Check script permissions
   sudo chmod +x /usr/local/bin/duckdns-update.sh
   
   # Check cron service
   sudo systemctl status cron
   
   # View cron logs
   sudo journalctl -u cron
   ```

#### Advanced Configuration

**Multiple Domains**: Set up different subdomains for different services:
- `vpn.yourdomain.duckdns.org` - OpenVPN
- `ssh.yourdomain.duckdns.org` - SSH access
- `web.yourdomain.duckdns.org` - Web services

**Custom Domain**: Use your own domain with CloudFlare:
- Configure CloudFlare as DNS provider
- Use CloudFlare API for automatic updates
- Better customization and features

**Backup Providers**: Set up multiple Dynamic DNS providers for redundancy

#### Security Considerations

- **Keep tokens secure**: Don't share your Dynamic DNS tokens
- **Use HTTPS**: Always use HTTPS URLs for updates
- **Monitor logs**: Regularly check update logs
- **Backup configuration**: Save your Dynamic DNS settings

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

## Certificate Management

### Checking Certificate Expiry

It's important to monitor your certificates and renew them before they expire to avoid service interruption.

#### Check Server Certificate Expiry

```bash
# Check server certificate expiry date
sudo openssl x509 -in /etc/openvpn/easy-rsa/pki/issued/server.crt -noout -dates

# Alternative: Check with more details
sudo openssl x509 -in /etc/openvpn/easy-rsa/pki/issued/server.crt -noout -text | grep -A 2 Validity
```

#### Check Client Certificate Expiry

```bash
# Check specific client certificate expiry
sudo openssl x509 -in /etc/openvpn/easy-rsa/pki/issued/CLIENT_NAME.crt -noout -dates

# List all client certificates with expiry dates
for cert in /etc/openvpn/easy-rsa/pki/issued/*.crt; do
    if [[ "$cert" != *"server.crt"* ]] && [[ "$cert" != *"ca.crt"* ]]; then
        echo "Certificate: $(basename "$cert")"
        sudo openssl x509 -in "$cert" -noout -dates
        echo "---"
    fi
done
```

#### Check CA Certificate Expiry

```bash
# Check CA certificate expiry (most critical)
sudo openssl x509 -in /etc/openvpn/easy-rsa/pki/ca.crt -noout -dates
```

### Regenerating Server Certificate

**⚠️ Warning**: Regenerating the server certificate will temporarily interrupt VPN service and require updating all client configurations.

#### Steps to Regenerate Server Certificate

1. **Stop the OpenVPN service**:
   ```bash
   sudo systemctl stop openvpn-server@server
   ```

2. **Backup existing certificates**:
   ```bash
   sudo cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/easy-rsa/pki/issued/server.crt.backup
   sudo cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/easy-rsa/pki/private/server.key.backup
   ```

3. **Revoke the old server certificate**:
   ```bash
   cd /etc/openvpn/easy-rsa/
   sudo ./easyrsa --batch revoke server
   ```

4. **Generate new server certificate**:
   ```bash
   # Generate new server certificate with 10-year expiry
   sudo EASYRSA_CERT_EXPIRE=3650 ./easyrsa --batch build-server-full server nopass
   ```

5. **Copy certificates to OpenVPN directory**:
   ```bash
   sudo cp pki/issued/server.crt /etc/openvpn/
   sudo cp pki/private/server.key /etc/openvpn/
   ```

6. **Update CRL (Certificate Revocation List)**:
   ```bash
   sudo EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
   sudo cp pki/crl.pem /etc/openvpn/
   sudo chmod 644 /etc/openvpn/crl.pem
   ```

7. **Start OpenVPN service**:
   ```bash
   sudo systemctl start openvpn-server@server
   sudo systemctl status openvpn-server@server
   ```

8. **Verify the new certificate**:
   ```bash
   sudo openssl x509 -in /etc/openvpn/server.crt -noout -dates
   ```

### Regenerating Client Certificates

Client certificate regeneration is simpler and doesn't affect other clients or require service restart.

#### Steps to Regenerate a Client Certificate

1. **Revoke the existing client certificate**:
   ```bash
   cd /etc/openvpn/easy-rsa/
   sudo ./easyrsa --batch revoke CLIENT_NAME
   ```

2. **Update the CRL**:
   ```bash
   sudo EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
   sudo cp pki/crl.pem /etc/openvpn/
   sudo chmod 644 /etc/openvpn/crl.pem
   ```

3. **Generate new client certificate**:
   ```bash
   # For passwordless certificate
   sudo EASYRSA_CERT_EXPIRE=3650 ./easyrsa --batch build-client-full CLIENT_NAME nopass
   
   # For password-protected certificate
   sudo EASYRSA_CERT_EXPIRE=3650 ./easyrsa --batch build-client-full CLIENT_NAME
   ```

4. **Generate new client configuration file**:
   
   You can either run the original Angristan script again to create a new client configuration:
   ```bash
   sudo ./openvpn-install.sh
   # Choose option 1 to add a new client
   ```
   
   Or manually create the configuration file:
   ```bash
   # Copy template and customize
   sudo cp /etc/openvpn/client-template.txt /root/CLIENT_NAME.ovpn
   
   # Add certificates to the configuration file
   {
       echo "<ca>"
       sudo cat /etc/openvpn/easy-rsa/pki/ca.crt
       echo "</ca>"
       echo "<cert>"
       sudo openssl x509 -in /etc/openvpn/easy-rsa/pki/issued/CLIENT_NAME.crt
       echo "</cert>"
       echo "<key>"
       sudo cat /etc/openvpn/easy-rsa/pki/private/CLIENT_NAME.key
       echo "</key>"
       echo "<tls-crypt>"
       sudo cat /etc/openvpn/tls-crypt.key
       echo "</tls-crypt>"
   } >> /root/CLIENT_NAME.ovpn
   ```

5. **Modify the client configuration for bridge mode** (as described in [Step 9](#step-9-configure-the-client)):
   ```bash
   # Edit the .ovpn file to change from tun to tap
   sudo sed -i 's/dev tun/dev tap/' /root/CLIENT_NAME.ovpn
   echo "dev-type tap" | sudo tee -a /root/CLIENT_NAME.ovpn
   ```

### Best Practices for Certificate Management

1. **Set Calendar Reminders**: Create reminders 3-6 months before certificate expiry
2. **Monitor Regularly**: Check certificate expiry dates monthly
3. **Backup Certificates**: Always backup certificates before making changes
4. **Test New Certificates**: Test new client certificates before distributing them
5. **Coordinate Renewals**: Plan server certificate renewals during maintenance windows
6. **Keep Documentation**: Document when certificates were renewed and why

### Certificate Renewal Automation

For advanced users, consider creating a script to monitor certificate expiry:

```bash
#!/bin/bash
# Certificate monitoring script
# Place in /usr/local/bin/check-openvpn-certs.sh

CERT_DIR="/etc/openvpn/easy-rsa/pki"
WARN_DAYS=90

echo "Checking OpenVPN certificate expiry dates..."

# Check CA certificate
ca_expiry=$(openssl x509 -in "$CERT_DIR/ca.crt" -noout -enddate | cut -d= -f2)
ca_expiry_epoch=$(date -d "$ca_expiry" +%s)
current_epoch=$(date +%s)
days_until_ca_expiry=$(( (ca_expiry_epoch - current_epoch) / 86400 ))

echo "CA Certificate expires in $days_until_ca_expiry days ($ca_expiry)"

if [ $days_until_ca_expiry -lt $WARN_DAYS ]; then
    echo "WARNING: CA certificate expires in less than $WARN_DAYS days!"
fi

# Check server certificate
server_expiry=$(openssl x509 -in "$CERT_DIR/issued/server.crt" -noout -enddate | cut -d= -f2)
server_expiry_epoch=$(date -d "$server_expiry" +%s)
days_until_server_expiry=$(( (server_expiry_epoch - current_epoch) / 86400 ))

echo "Server Certificate expires in $days_until_server_expiry days ($server_expiry)"

if [ $days_until_server_expiry -lt $WARN_DAYS ]; then
    echo "WARNING: Server certificate expires in less than $WARN_DAYS days!"
fi
```

**To use this script**:
```bash
sudo chmod +x /usr/local/bin/check-openvpn-certs.sh
sudo /usr/local/bin/check-openvpn-certs.sh
```

**Add to crontab for monthly checks**:
```bash
# Edit root's crontab
sudo crontab -e

# Add this line for monthly certificate checks
0 0 1 * * /usr/local/bin/check-openvpn-certs.sh | mail -s "OpenVPN Certificate Status" admin@yourdomain.com
```

---

## Next Steps

Once your VPN is working correctly:

1. **Create additional client certificates** for other devices
2. **Set up monitoring** to track VPN usage and performance
3. **Configure automatic backups** of your certificates and configuration
4. **Consider additional security measures** like two-factor authentication
5. **Implement certificate expiry monitoring** as described above

For ongoing maintenance and troubleshooting, see the [Troubleshooting Guide](troubleshooting.html).