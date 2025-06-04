---
layout: default
title: "Complete Installation Guide"
description: "Step-by-step installation guide for OpenVPN Bridge Mode setup"
nav_order: 2
---

# Complete Installation Guide

This page provides detailed step-by-step instructions for setting up OpenVPN in bridge mode on a Raspberry Pi or Linux device.

## Table of Contents
- [Step 1: Install Raspberry Pi OS](#step-1-install-raspberry-pi-os)
- [Step 2: Configure Raspberry Pi](#step-2-configure-raspberry-pi)
- [Step 3: Enable Automatic Updates](#step-3-enable-automatic-updates)
- [Step 4: Configure Static IP](#step-4-configure-static-ip)
- [Step 5: Install OpenVPN](#step-5-install-openvpn)
- [Next Steps](#next-steps)

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

## Step 4: Configure Static IP

If you haven't configured a static IP yet, or need to change your network configuration:

### Method 1: Using dhcpcd.conf (Recommended)

1. **Edit the configuration file**:
   ```bash
   sudo nano /etc/dhcpcd.conf
   ```

2. **Add static IP configuration** (adjust for your network):
   ```conf
   # Example static IP configuration for unique network range
   interface eth0
   static ip_address=10.99.99.134/24
   static routers=10.99.99.1
   static domain_name_servers=8.8.8.8 8.8.4.4
   ```

3. **Restart networking**:
   ```bash
   sudo systemctl restart dhcpcd
   ```

### Method 2: Using NetworkManager (if available)

```bash
sudo nmcli con mod "Wired connection 1" ipv4.addresses 10.99.99.134/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 10.99.99.1
sudo nmcli con mod "Wired connection 1" ipv4.dns "8.8.8.8 8.8.4.4"
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con up "Wired connection 1"
```

---

## Step 5: Install OpenVPN

We'll use the Angristan OpenVPN installation script, which provides a secure, modern OpenVPN setup.

### Download and Run Installation Script

1. **Download the script**:
   ```bash
   curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
   chmod +x openvpn-install.sh
   ```

2. **Run the installation script**:
   ```bash
   sudo ./openvpn-install.sh
   ```

### Configuration Options During Installation

When prompted, choose the following options:

1. **IP address**: Confirm the detected IP (should be your static IP)
2. **Public IP**: This should be your external IP address (the script usually detects this correctly)
3. **Port**: Use `1194` (default) or choose a different port if needed
4. **Protocol**: Choose `UDP` (recommended for performance)
5. **DNS**: Choose a reliable DNS provider:
   - `1` for current system resolvers
   - `3` for Cloudflare
   - `4` for Quad9
   - `5` for Google

6. **Compression**: Choose `n` (no compression) for better security
7. **Customization**: Choose `n` for default settings initially
8. **Client name**: Enter a name for your first client certificate

### Key Security Recommendations

The Angristan script automatically implements several security best practices:
- Uses modern encryption (AES-256-GCM)
- Enables TLS authentication
- Uses strong DH parameters
- Configures proper certificate settings

### Post-Installation

1. **Verify OpenVPN is running**:
   ```bash
   sudo systemctl status openvpn-server@server
   ```

2. **Check that the service is enabled**:
   ```bash
   sudo systemctl is-enabled openvpn-server@server
   ```

3. **Locate the client configuration file**:
   The script creates a `.ovpn` file in the home directory. This file contains all the necessary configuration and certificates for your VPN client.

---

## Next Steps

After completing the installation, you'll need to:

1. **[Configure OpenVPN for Bridge Mode](configuration.html)** - Modify the server configuration for bridge networking
2. **[Set up the Bridge Script](configuration.html#bridge-script)** - Create the network bridge
3. **[Configure Client Settings](configuration.html#client-configuration)** - Modify client configuration for bridge mode
4. **[Set up Port Forwarding](configuration.html#port-forwarding)** - Configure your router
5. **[Test the Setup](troubleshooting.html)** - Verify everything works correctly

Continue to the [Configuration Guide](configuration.html) for the next steps.

---

## Troubleshooting

If you encounter issues during installation:

- **SSH Connection Issues**: Verify the Pi is powered on and connected to the network
- **Package Installation Errors**: Run `sudo apt update` and try again
- **Static IP Not Working**: Double-check your network configuration and router settings
- **OpenVPN Script Fails**: Ensure you have internet connectivity and try running the script again

For more detailed troubleshooting, see the [Troubleshooting Guide](troubleshooting.html).