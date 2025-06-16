# Raspberry Pi/Linux OpenVPN Server in Bridge Mode

This guide provides step-by-step instructions to set up an OpenVPN server in bridge mode on a Raspberry Pi or Linux device. Bridged networking allows VPN clients to appear as if they are on the same local network as the server, enabling seamless communication.

## Prerequisites

1. **Static IP Address**: Ensure your Raspberry Pi has a static IP address. This can be configured:
   - Directly on the Raspberry Pi using `raspi-config`
   - By reserving an IP address for the Raspberry Pi in your router's DHCP settings

2. **Network Planning**: Plan your IP addressing to avoid conflicts:
   - Choose a unique private IP range for your home network
   - Ensure the range doesn't conflict with common remote networks
   - See the **Network Planning** section below for detailed guidance

3. **Bridge Utilities**: Install `bridge-utils` for managing network bridges

4. **OpenVPN**: Install and configure OpenVPN using the provided script

---

## Network Planning

**Critical: Plan Your IP Addressing Before Setup**

One of the most common issues with VPN setups is subnet conflicts. When your home network and the remote network you're connecting from use the same IP range, the VPN will not work properly.

## Common Network Conflicts

Most home routers use these default IP ranges:
- `192.168.1.0/24` (192.168.1.1 - 192.168.1.254)
- `192.168.0.0/24` (192.168.0.1 - 192.168.0.254)
- `10.0.0.0/24` (10.0.0.1 - 10.0.0.254)

## Recommended Solution: Use Unique Private IP Ranges

To avoid conflicts, choose a unique private IP range for your home network that is unlikely to be used elsewhere:

**Recommended ranges:**
- `10.99.99.0/24` (10.99.99.1 - 10.99.99.254) - Excellent choice, rarely used
- `172.16.100.0/24` (172.16.100.1 - 172.16.100.254) - Good alternative
- `10.11.12.0/24` (10.11.12.1 - 10.11.12.254) - Another good option
- `192.168.73.0/24` (192.168.73.1 - 192.168.73.254) - Less common 192.168.x range

## Example Network Configuration

If you choose `10.99.99.0/24` for your home network:
- **Router IP**: `10.99.99.1`
- **Raspberry Pi IP**: `10.99.99.134`
- **DHCP Range**: `10.99.99.100` - `10.99.99.199`
- **VPN Client Range**: `10.99.99.200` - `10.99.99.210`

## Alternative Network Examples

### 10.11.12.0/24 Network (Recommended for avoiding conflicts)
- **Router IP**: `10.11.12.1` (gateway)
- **OpenVPN Server IP**: `10.11.12.2`
- **DHCP Range**: `10.11.12.100` - `10.11.12.199`
- **VPN Client Range**: `10.11.12.200` - `10.11.12.210`
- **DNS**: Consider setting up `vpn.mydnsdomain.biz` pointing to your public IP

### 192.168.73.0/24 Network (Less common 192.168.x range)
- **Router IP**: `192.168.73.1`
- **OpenVPN Server IP**: `192.168.73.18`
- **DHCP Range**: `192.168.73.100` - `192.168.73.199`
- **VPN Client Range**: `192.168.73.230` - `192.168.73.240`

### Network Assumptions
When setting up your VPN, consider these common scenarios:
- **Client's network**: `192.168.0.1/24` (typical hotel, office, or public WiFi)
- **Your home network**: `10.11.12.0/24` or `192.168.73.0/24` (to avoid conflicts)
- **Custom DNS**: Set up a DNS record like `vpn.mydnsdomain.biz` for easy connection

## Why This Matters

When you connect to your home VPN from a remote location (hotel, office, etc.), if both networks use the same IP range like `192.168.1.0/24`, your device won't know whether to route traffic locally or through the VPN. Using a unique range like `10.99.99.0/24` eliminates this confusion.

---

## Why Bridge Mode?

Bridge mode is particularly useful for applications like ham radio (e.g., ExpertSDR3), where devices need to communicate as if they are on the same local network. Unlike routed mode, bridge mode allows broadcast and multicast traffic, which is essential for some applications.

---

## Step 1: Install Raspberry Pi OS

### Option 1: Using Raspberry Pi Imager (Recommended)

1. **Download Raspberry Pi Imager**:
   - Visit [rpi.org](https://www.raspberrypi.org/software/) and download the imager for your operating system

2. **Prepare SD Card**:
   - Insert a microSD card (16GB or larger recommended) into your computer
   - Launch Raspberry Pi Imager

3. **Configure the Image**:
   - Click "Choose OS" and select "Raspberry Pi OS (32-bit)" or "Raspberry Pi OS Lite" for headless setup
   - Click the gear icon for advanced options:
     - **Enable SSH**: Check this box
     - **Set username and password**: Use a strong password
     - **Configure WiFi**: Enter your network credentials if using WiFi
     - **Set locale settings**: Configure your timezone and keyboard layout

4. **Write to SD Card**:
   - Select your SD card
   - Click "Write" and wait for the process to complete

### Option 2: Manual Configuration

If you prefer manual setup or need to enable SSH on an existing installation:

1. **Enable SSH**:
   - Create an empty file named `ssh` in the boot partition of the SD card
   ```bash
   # On Linux/macOS
   touch /path/to/boot/ssh
   ```

2. **Configure WiFi** (if needed):
   - Create `wpa_supplicant.conf` in the boot partition:
   ```conf
   country=US
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1
   
   network={
       ssid="YourNetworkName"
       psk="YourPassword"
   }
   ```

3. **Insert SD card** into Raspberry Pi and power on

---

## Step 2: Configure Raspberry Pi

### Initial Access

1. **Find Your Raspberry Pi's IP Address**:
   - Check your router's admin panel for connected devices
   - Use network scanning: `nmap -sn 192.168.1.0/24` (adjust for your network)
   - Or connect a monitor and keyboard to see the IP address

2. **Connect via SSH**:
   ```bash
   ssh pi@<raspberry-pi-ip>
   # Example: ssh pi@192.168.1.100
   ```
   - Default username: `pi`
   - Use the password you set during imaging

### Essential Configuration Steps

3. **Update System Packages**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

4. **Run Configuration Tool**:
   ```bash
   sudo raspi-config
   ```

5. **Configure Static IP Address**:
   - In `raspi-config`: Navigate to `Network Options` > `N8 IP Version` > `N1 Enable/Disable automatic IP configuration`
   - Or manually edit `/etc/dhcpcd.conf`:
   ```bash
   sudo nano /etc/dhcpcd.conf
   ```
   Add these lines (adjust for your chosen network range):
   ```conf
   interface eth0
   static ip_address=10.99.99.134/24
   static routers=10.99.99.1
   static domain_name_servers=8.8.8.8 8.8.4.4
   ```

6. **Optional: Disable GUI Mode**:
   - In `raspi-config`: `System Options` > `Boot / Auto Login` > `Console`
   - This saves resources if using the Pi only as a server

7. **Change Default Password**:
   ```bash
   passwd
   ```
   Use a strong, unique password.

8. **Enable SSH (if not already enabled)**:
   - In `raspi-config`: `Interface Options` > `SSH` > `Enable`

9. **Reboot to Apply Changes**:
   ```bash
   sudo reboot
   ```

### Verify Configuration

After reboot, verify your static IP is working:
```bash
ip addr show eth0
ping google.com
```

---

## Step 3: Enable Automatic Updates

**Important**: Keeping your system updated is crucial for security, especially for a device exposed to the internet.

### Install Unattended Upgrades

1. **Install the package**:
   ```bash
   sudo apt install unattended-upgrades apt-listchanges -y
   ```

2. **Configure automatic updates**:
   ```bash
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```
   Select "Yes" when prompted.

### Configure Update Settings

3. **Edit the configuration file**:
   ```bash
   sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
   ```

4. **Recommended configuration** (uncomment and modify these lines):
   ```conf
   // Automatically upgrade packages from these origins:
   Unattended-Upgrade::Origins-Pattern {
       "origin=Debian,codename=${distro_codename},label=Debian-Security";
       "origin=Raspbian,codename=${distro_codename},label=Raspbian";
   };
   
   // Remove unused automatically installed kernel-related packages
   Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
   
   // Remove unused dependencies
   Unattended-Upgrade::Remove-Unused-Dependencies "true";
   
   // Automatically reboot if required
   Unattended-Upgrade::Automatic-Reboot "true";
   Unattended-Upgrade::Automatic-Reboot-Time "02:00";
   ```

5. **Enable automatic updates**:
   ```bash
   sudo nano /etc/apt/apt.conf.d/20auto-upgrades
   ```
   Ensure it contains:
   ```conf
   APT::Periodic::Update-Package-Lists "1";
   APT::Periodic::Unattended-Upgrade "1";
   ```

### Verify Configuration

6. **Test the configuration**:
   ```bash
   sudo unattended-upgrades --dry-run
   ```

7. **Check status**:
   ```bash
   sudo systemctl status unattended-upgrades
   ```

---

## Step 4: Install Bridge Utilities

Bridge utilities are essential for creating network bridges that allow the VPN to operate in bridge mode.

```bash
sudo apt update
sudo apt install bridge-utils -y
```

**Verify installation**:
```bash
brctl --version
```

You should see output similar to: `bridge-utils, 1.6`

---

## Step 5: Install OpenVPN

We'll use the Angristan OpenVPN installation script, which provides a secure, modern OpenVPN setup.

### Download and Run Installation Script

1. **Download the installation script**:
   ```bash
   curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
   ```

2. **Make the script executable**:
   ```bash
   chmod +x openvpn-install.sh
   ```

3. **Run the installation script**:
   ```bash
   sudo ./openvpn-install.sh
   ```

### Configuration Options During Installation

When prompted, use these recommended settings:

- **IP address**: Accept the detected IP (your Raspberry Pi's IP)
- **Public IPv4/IPv6 address**: Your public IP or Dynamic DNS hostname
- **Port**: `1194` (default) or choose a custom port like `11194` for security
- **Protocol**: `UDP` (recommended for performance)
- **DNS**: Choose `8` for Google DNS (8.8.8.8, 8.8.4.4)
- **Compression**: `n` (disable for better security)
- **Customize encryption settings**: `n` (defaults are secure)
- **Client name**: Enter a descriptive name (e.g., "home-client")

### Port Configuration Notes

**Using Custom Ports**: Many users prefer using non-standard ports like `11194` instead of the default `1194` for additional security through obscurity. If you choose a custom port:
- Update your router's port forwarding to forward external port `11194` to internal port `11194`
- Ensure your firewall forwards UDP traffic from port `11194` to the OpenVPN server on port `11194`
- Update client configurations to connect to the custom port

### Key Security Recommendations

- **Elliptic Curve**: The script will automatically use secure curves (P-521 or similar)
- **Cipher**: AES-256-GCM is used by default
- **Authentication**: SHA-512 is used by default
- **TLS version**: Minimum TLS 1.2

### Post-Installation

After installation completes:
- The server configuration will be at `/etc/openvpn/server.conf`
- Client configuration will be generated (e.g., `home-client.ovpn`)
- OpenVPN service will start automatically

**Verify OpenVPN is running**:
```bash
sudo systemctl status openvpn-server@server
```

---

## Step 6: Configure OpenVPN for Bridge Mode

### Modify Server Configuration

1. **Stop OpenVPN service**:
   ```bash
   sudo systemctl stop openvpn-server@server
   ```

2. **Edit the server configuration**:
   ```bash
   sudo nano /etc/openvpn/server.conf
   ```

3. **Make the following changes**:

   **a) Change from TUN to TAP device**:
   
   Find this line:
   ```conf
   dev tun
   ```
   Replace with:
   ```conf
   dev tap0
   ```

   **b) Configure bridge mode**:
   
   Find and comment out the `server` line:
   ```conf
   #server 10.8.0.0 255.255.255.0
   ```
   
   Add the `server-bridge` configuration:
   ```conf
   server-bridge <RPI_IP> <NETMASK> <START_IP> <END_IP>
   ```

### Example Configurations

**For 10.99.99.0/24 network (recommended)**:
```conf
server-bridge 10.99.99.134 255.255.255.0 10.99.99.200 10.99.99.210
```

**For traditional 192.168.1.0/24 network**:
```conf
server-bridge 192.168.1.134 255.255.255.0 192.168.1.200 192.168.1.210
```

**For 10.11.12.0/24 network**:
```conf
server-bridge 10.11.12.2 255.255.255.0 10.11.12.200 10.11.12.210
```

**For 192.168.73.0/24 network**:
```conf
server-bridge 192.168.73.18 255.255.255.0 192.168.73.230 192.168.73.240
```

### Cipher Configuration

Modern OpenVPN versions use `data-ciphers` instead of the older `ncp-ciphers`. Your configuration may need:

```conf
# Modern approach (OpenVPN 2.5+)
data-ciphers AES-256-CBC:AES-256-GCM
cipher AES-256-CBC

# Or for maximum compatibility
data-ciphers AES-256-CBC
cipher AES-256-CBC
```

**Note**: If you encounter cipher negotiation issues, using `AES-256-CBC` with `data-ciphers` instead of `AES-256-GCM` may provide better compatibility with various clients.

### Understanding the Configuration

- `<RPI_IP>`: Your Raspberry Pi's static IP address
- `<NETMASK>`: Network mask (usually 255.255.255.0 for /24 networks)
- `<START_IP>` to `<END_IP>`: IP range reserved for VPN clients

### Important Considerations

4. **Ensure no DHCP conflicts**:
   - The VPN client IP range must not overlap with your router's DHCP range
   - Check your router settings to see what range it uses
   - Reserve the VPN range or adjust your router's DHCP scope accordingly

5. **Additional recommended settings**:
   
   Add these lines if not present:
   ```conf
   # Improve compatibility with bridged networking
   client-to-client
   duplicate-cn
   comp-lzo no
   ```

6. **Save and exit** the file (Ctrl+X, then Y, then Enter in nano)

---

## Step 7: Configure the Bridge Script

The bridge script creates a network bridge that connects your physical network interface with the VPN's TAP interface.

### Install the Bridge Script

1. **Copy the bridge script to OpenVPN directory**:
   ```bash
   sudo cp bridge_start.sh /etc/openvpn/
   ```

2. **Make it executable**:
   ```bash
   sudo chmod +x /etc/openvpn/bridge_start.sh
   ```

### Configure Network Settings

3. **Find your current network configuration**:
   ```bash
   ifconfig eth0
   ip route show default
   ```

4. **Edit the bridge script**:
   ```bash
   sudo nano /etc/openvpn/bridge_start.sh
   ```

### Example Configurations

**For 10.99.99.0/24 network (recommended)**:
```bash
eth="eth0"
eth_ip="10.99.99.134"
eth_netmask="255.255.255.0"
eth_broadcast="10.99.99.255"
eth_gateway="10.99.99.1"
eth_mac="e4:5f:01:75:0b:9e"  # Use your actual MAC address
```

**For traditional 192.168.1.0/24 network**:
```bash
eth="eth0"
eth_ip="192.168.1.134"
eth_netmask="255.255.255.0"
eth_broadcast="192.168.1.255"
eth_gateway="192.168.1.1"
eth_mac="e4:5f:01:75:0b:9e"  # Use your actual MAC address
```

### Finding Your Network Information

To get the correct values for your setup:

**Get MAC address**:
```bash
cat /sys/class/net/eth0/address
```

**Get current IP configuration**:
```bash
ip addr show eth0
ip route show default
```

**Calculate broadcast address** (for /24 networks):
- For 10.99.99.0/24 → broadcast is 10.99.99.255
- For 192.168.1.0/24 → broadcast is 192.168.1.255

### Verify Script Configuration

5. **Check your script configuration**:
   ```bash
   cat /etc/openvpn/bridge_start.sh | grep "eth_"
   ```

The script will:
- Create a bridge interface (br0)
- Add your physical ethernet interface to the bridge
- Add the TAP interface to the bridge
- Configure iptables rules for proper packet forwarding

---

## Step 8: Enable Auto Startup of the Bridge Script

### Method 1: Using rc.local (Simple)

1. **Edit the rc.local file**:
   ```bash
   sudo nano /etc/rc.local
   ```

2. **Add the bridge script before `exit 0`**:
   ```bash
   # Start bridge for OpenVPN
   /etc/openvpn/bridge_start.sh
   
   exit 0
   ```

### Method 2: Using systemd (Recommended)

For better control and logging, create a systemd service:

1. **Create a systemd service file**:
   ```bash
   sudo nano /etc/systemd/system/openvpn-bridge.service
   ```

2. **Add this configuration**:
   ```ini
   [Unit]
   Description=OpenVPN Bridge Setup
   Before=openvpn-server@server.service
   Wants=network-online.target
   After=network-online.target
   
   [Service]
   Type=oneshot
   ExecStart=/etc/openvpn/bridge_start.sh
   RemainAfterExit=yes
   StandardOutput=journal
   StandardError=journal
   
   [Install]
   WantedBy=multi-user.target
   ```

3. **Enable and start the service**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable openvpn-bridge.service
   ```

### Test the Bridge Setup

4. **Test the bridge script manually**:
   ```bash
   sudo /etc/openvpn/bridge_start.sh
   ```

5. **Verify bridge creation**:
   ```bash
   brctl show
   ip addr show br0
   ```

You should see output showing the bridge interface (br0) with your ethernet interface attached.

6. **Check for errors**:
   ```bash
   sudo systemctl status openvpn-bridge.service
   journalctl -u openvpn-bridge.service
   ```

---

## Step 9: Configure the Client

### Modify Client Configuration

1. **Locate the client configuration file**:
   The OpenVPN installation script creates a `.ovpn` file in your home directory, typically named something like `client.ovpn` or with the name you specified during installation.

2. **Edit the client configuration**:
   ```bash
   nano client.ovpn
   ```

3. **Change from TUN to TAP**:
   
   Find this line:
   ```conf
   dev tun
   ```
   Replace with:
   ```conf
   dev tap0
   ```
   
   **Note**: Use `tap0` (not just `tap`) to match the server configuration for bridge mode.

4. **Update cipher configuration** (if needed):
   
   If you encounter connection issues, you may need to update the cipher configuration:
   ```conf
   # Replace 'cipher' line with 'data-ciphers' if present
   data-ciphers AES-256-CBC
   ```

5. **Verify the remote server address**:
   
   Ensure the `remote` line contains your correct public IP or Dynamic DNS hostname:
   ```conf
   remote your-public-ip-or-ddns 1194
   ```
   
   **For custom ports**, update accordingly:
   ```conf
   remote vpn.mydnsdomain.biz 11194
   ```

### Additional Client Settings

6. **Optional: Add Windows-specific settings** (if using Windows clients):
   ```conf
   # Windows-specific TAP adapter settings
   route-method exe
   route-delay 2
   ```

7. **Optional: Add DNS push settings** (if not already present):
   ```conf
   # Ensure clients use proper DNS
   dhcp-option DNS 8.8.8.8
   dhcp-option DNS 8.8.4.4
   ```

### Client Installation

8. **Transfer the client file** to your client device:
   - Use `scp` to copy from your Pi: `scp pi@<pi-ip>:client.ovpn .`
   - Or copy the content and paste into a new file

9. **Import into OpenVPN client**:
   - **Windows**: Use OpenVPN GUI or OpenVPN Connect
   - **macOS**: Use Tunnelblick or OpenVPN Connect
   - **Linux**: Use NetworkManager or command line
   - **Mobile**: Use OpenVPN Connect app

### Test the Configuration

10. **Start OpenVPN server** (if not already running):
    ```bash
    sudo systemctl start openvpn-server@server
    sudo systemctl enable openvpn-server@server
    ```

11. **Verify server status**:
    ```bash
    sudo systemctl status openvpn-server@server
    sudo journalctl -u openvpn-server@server -f
    ```

---

## Step 10: Configure Router Port Forwarding

### Access Router Configuration

1. **Find your router's IP address**:
   ```bash
   ip route show default
   ```
   The gateway IP is your router's address (e.g., 10.99.99.1 or 192.168.1.1)

2. **Access router admin panel**:
   - Open a web browser and navigate to your router's IP
   - Log in with admin credentials (often found on router label)

### Configure Port Forwarding

3. **Locate port forwarding settings**:
   - Look for "Port Forwarding", "Virtual Servers", or "NAT" in router settings
   - Different router brands use different terminology

4. **Create a new forwarding rule**:
   - **Service Name**: OpenVPN or VPN Server
   - **Protocol**: UDP (recommended) or TCP (if you changed it during installation)
   - **External Port**: 1194 (default) or custom port like 11194
   - **Internal IP**: Your Raspberry Pi's IP (e.g., 10.99.99.134, 10.11.12.2, or 192.168.73.18)
   - **Internal Port**: 1194 (default) or custom port like 11194

### Example Port Forwarding Configurations

**Standard Configuration**:
- External Port: 1194 UDP → Internal IP: 10.99.99.134 Port: 1194

**Custom Port Configuration**:
- External Port: 11194 UDP → Internal IP: 10.11.12.2 Port: 11194

**Firewall Note**: Ensure your router's firewall forwards UDP traffic from the external port to the OpenVPN server on the same port number.

### Security Considerations

5. **Use a non-standard port** (recommended):
   - Change from default 1194 to a custom port (e.g., 11194, 21194, 443, 8080)
   - Update both router forwarding rule and OpenVPN configuration
   - Edit `/etc/openvpn/server.conf`:
     ```conf
     port 11194
     ```
   - Update client configuration accordingly:
     ```conf
     remote vpn.mydnsdomain.biz 11194
     ```

6. **Restrict access by IP** (if supported):
   - Some routers allow restricting port forwarding to specific source IPs
   - Useful if you only connect from known locations

### Common Router Interfaces

**For popular router brands**:
- **Linksys**: Advanced → Port Forwarding
- **Netgear**: Dynamic DNS → Port Forwarding
- **ASUS**: Adaptive QoS → Port Forwarding
- **TP-Link**: Advanced → NAT Forwarding → Port Forwarding
- **D-Link**: Advanced → Port Forwarding

### Test Port Forwarding

7. **Test from external network**:
   - Use online port checker tools (search "port checker online")
   - Or test from mobile data: `telnet your-public-ip 1194`

8. **Find your public IP**:
   ```bash
   curl ifconfig.me
   # or
   curl ipinfo.io/ip
   ```

### Dynamic DNS (Optional but Recommended)

If your ISP changes your IP address frequently:

9. **Set up Dynamic DNS**:
   - Services: No-IP, DuckDNS, Cloudflare, etc.
   - Configure on your router or Raspberry Pi
   - Use the hostname in client configuration instead of IP address

---

## Troubleshooting

### Subnet Conflicts

**Problem**: VPN connects but no internet access or can't reach local devices.

**Cause**: Local and remote networks use the same IP range.

**Solutions**:

1. **Change your home network to a unique range** (recommended):
   - Reconfigure your router to use `10.99.99.0/24`
   - Update all static device configurations
   - Update Raspberry Pi and OpenVPN configurations accordingly

2. **Alternative network ranges**:
   - `172.16.100.0/24` - Another good choice
   - `10.11.12.0/24` - Less commonly used range  
   - `192.168.73.0/24` - Alternative 192.168.x range
   - Avoid common ranges like `192.168.1.0/24`, `192.168.0.0/24`, `10.0.0.0/24`

3. **Quick test for conflicts**:
   ```bash
   # On VPN client, check for conflicting routes
   ip route show
   # Look for duplicate network ranges
   ```

### OpenVPN Service Issues

**Check service status**:
```bash
sudo systemctl status openvpn-server@server
sudo journalctl -u openvpn-server@server -f
```

**Common issues**:

1. **Port already in use**:
   ```bash
   sudo netstat -tulpn | grep :1194
   sudo ss -tulpn | grep :1194
   ```

2. **Certificate problems**:
   ```bash
   sudo openvpn --config /etc/openvpn/server.conf --verb 4
   ```

3. **Restart services**:
   ```bash
   sudo systemctl restart openvpn-server@server
   sudo systemctl restart openvpn-bridge.service
   ```

### Bridge Configuration Issues

**Check bridge status**:
```bash
brctl show
ip addr show br0
```

**Common problems**:

1. **Bridge not created**:
   ```bash
   # Manually run bridge script to see errors
   sudo /etc/openvpn/bridge_start.sh
   ```

2. **Network interface issues**:
   ```bash
   # Check if ethernet interface exists
   ip link show
   # Check for correct interface name (might be enp0s3, ens33, etc.)
   ```

3. **Permission issues**:
   ```bash
   sudo chmod +x /etc/openvpn/bridge_start.sh
   sudo chown root:root /etc/openvpn/bridge_start.sh
   ```

### Client Connection Issues

**Check client logs**:
- Windows: `C:\Program Files\OpenVPN\log\`
- macOS: Console app → search for "openvpn"
- Linux: `journalctl | grep openvpn`

**Common client problems**:

1. **TAP adapter issues (Windows)**:
   - Install/reinstall TAP-Windows driver
   - Run OpenVPN client as administrator

2. **Firewall blocking**:
   - Allow OpenVPN through Windows Firewall
   - Check antivirus software blocking

3. **DNS issues**:
   ```bash
   # Test DNS resolution on client
   nslookup google.com
   ```

### Network Connectivity Tests

**From Raspberry Pi**:
```bash
# Test internet connectivity
ping google.com

# Test local network
ping 10.99.99.1  # Your router

# Check listening ports
sudo netstat -tulpn | grep openvpn
```

**From client (when connected)**:
```bash
# Test VPN server
ping 10.99.99.134  # Your Pi's IP

# Test other local devices
ping 10.99.99.1    # Your router

# Test internet through VPN
ping google.com
```

### Performance Issues

1. **Check CPU usage**:
   ```bash
   top
   htop
   ```

2. **Network bandwidth test**:
   ```bash
   # Install iperf3
   sudo apt install iperf3
   
   # On server
   iperf3 -s
   
   # On client
   iperf3 -c <server-ip>
   ```

3. **Optimize OpenVPN settings** (add to server.conf):
   ```conf
   # Increase buffer sizes
   sndbuf 524288
   rcvbuf 524288
   
   # Use fast cipher
   cipher AES-128-GCM
   
   # Reduce compression overhead
   comp-lzo no
   ```

### Log Analysis

**Enable verbose logging**:
```bash
sudo nano /etc/openvpn/server.conf
# Change: verb 3
# To: verb 4 or verb 5
```

**Key log locations**:
- OpenVPN server: `/var/log/openvpn/status.log`
- System logs: `journalctl -u openvpn-server@server`
- Bridge script: `journalctl -u openvpn-bridge.service`

**Common error patterns**:
- "TLS handshake failed" → Certificate/key issues
- "Cannot allocate TUN/TAP" → TAP driver or permissions
- "RESOLVE: Cannot resolve host" → DNS or network issues
- "Connection reset by peer" → Firewall or port forwarding

---

## Useful Links and References

### OpenVPN Documentation
- [OpenVPN Official Documentation](https://openvpn.net/community-resources/)
- [OpenVPN TAP Bridge Mode Guide](https://www.aaflalo.me/2015/01/openvpn-tap-bridge-mode/)
- [OpenVPN Ethernet Bridging](https://openvpn.net/community-resources/ethernet-bridging/)
- [OpenVPN Security Hardening](https://openvpn.net/community-resources/hardening-openvpn-security/)

### Dynamic DNS Services
- [No-IP](https://www.noip.com) - Free dynamic DNS with limited features
- [DuckDNS](https://www.duckdns.org) - Free and simple dynamic DNS
- [CloudNS](https://www.cloudns.net) - Professional DNS services
- [Cloudflare](https://www.cloudflare.com) - Free tier includes dynamic DNS

### Raspberry Pi Resources
- [Set Static IP on Raspberry Pi](https://raspberrytips.com/set-static-ip-address-raspberry-pi/)
- [Raspberry Pi Configuration Guide](https://www.raspberrypi.org/documentation/configuration/)
- [SSH Setup for Raspberry Pi](https://www.raspberrypi.org/documentation/remote-access/ssh/)

### Network Tools and Testing
- [Online Port Checker](https://portchecker.co/)
- [What's My IP](https://whatismyipaddress.com/)
- [Network Calculator](https://www.subnet-calculator.com/)

### OpenVPN Clients
- [OpenVPN Connect](https://openvpn.net/client-connect-vpn-for-windows/) - Official client for Windows/macOS/mobile
- [Tunnelblick](https://tunnelblick.net/) - macOS OpenVPN client
- [NetworkManager](https://wiki.gnome.org/Projects/NetworkManager/VPN) - Linux integration

---

## Final Thoughts

Bridge mode VPN setup provides powerful network extension capabilities, allowing remote devices to seamlessly integrate with your home network. However, it requires careful planning and configuration to ensure security and avoid conflicts.

### Key Success Factors

1. **Network Planning**: Choose unique IP ranges to avoid conflicts with remote networks
2. **Security**: Keep your system updated and use strong authentication
3. **Testing**: Thoroughly test the setup from different locations and networks
4. **Monitoring**: Regularly check logs and system status
5. **Documentation**: Keep notes of your specific configuration for future reference

### When to Use Bridge Mode vs Routed Mode

**Use Bridge Mode when**:
- Applications require broadcast/multicast traffic (e.g., network discovery, gaming, media streaming)
- You need devices to appear on the same network segment
- Legacy applications expect local network behavior
- You want to access network services like file sharing, printers, etc.

**Use Routed Mode when**:
- You only need internet access through the VPN
- You want better security isolation
- You have limited IP address space
- Performance is more critical than full network integration

### Security Considerations

- Change default passwords and use strong authentication
- Consider using certificate-based authentication for clients
- Regularly update both server and client software
- Monitor connection logs for unusual activity
- Use non-standard ports when possible
- Consider setting up fail2ban for additional protection

### Maintenance

- Monitor system resources (CPU, memory, network)
- Check logs regularly for errors or security issues
- Test VPN connectivity periodically
- Keep client configurations backed up
- Document any configuration changes
- **Monitor certificate expiry dates** and renew before expiration
- Regularly check for OpenVPN and system updates

For detailed certificate management procedures, see the [Certificate Management section](docs/configuration.md#certificate-management) in the Configuration Guide.

By following this guide, you should have a robust OpenVPN bridge mode server that provides secure, seamless access to your home network from anywhere in the world.

