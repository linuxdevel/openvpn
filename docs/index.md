---
layout: default
title: "OpenVPN Bridge Mode Setup Guide"
description: "Complete step-by-step guide for setting up OpenVPN server in bridge mode on Raspberry Pi/Linux"
---

# Raspberry Pi/Linux OpenVPN Server in Bridge Mode

This guide provides step-by-step instructions to set up an OpenVPN server in bridge mode on a Raspberry Pi or Linux device. Bridged networking allows VPN clients to appear as if they are on the same local network as the server, enabling seamless communication.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Network Planning](#network-planning)
- [Why Bridge Mode?](#why-bridge-mode)
- [Installation Steps](#installation-steps)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [References](#references)

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

**⚠️ Critical: Plan Your IP Addressing Before Setup**

One of the most common issues with VPN setups is subnet conflicts. When your home network and the remote network you're connecting from use the same IP range, the VPN will not work properly.

### Common Network Conflicts

Most home routers use these default IP ranges:
- `192.168.1.0/24` (192.168.1.1 - 192.168.1.254)
- `192.168.0.0/24` (192.168.0.1 - 192.168.0.254)
- `10.0.0.0/24` (10.0.0.1 - 10.0.0.254)

### Recommended Solution: Use Unique Private IP Ranges

To avoid conflicts, choose a unique private IP range for your home network that is unlikely to be used elsewhere:

**Recommended ranges:**
- `10.99.99.0/24` (10.99.99.1 - 10.99.99.254) - Excellent choice, rarely used
- `172.16.100.0/24` (172.16.100.1 - 172.16.100.254) - Good alternative
- `10.11.12.0/24` (10.11.12.1 - 10.11.12.254) - Another good option

### Example Network Configuration

If you choose `10.99.99.0/24` for your home network:
- **Router IP**: `10.99.99.1`
- **Raspberry Pi IP**: `10.99.99.134`
- **DHCP Range**: `10.99.99.100` - `10.99.99.199`
- **VPN Client Range**: `10.99.99.200` - `10.99.99.210`

### Alternative Network Examples

**10.11.12.0/24 Network** (recommended for avoiding conflicts):
- **Router IP**: `10.11.12.1`
- **OpenVPN Server IP**: `10.11.12.2`
- **DHCP Range**: `10.11.12.100` - `10.11.12.199`
- **VPN Client Range**: `10.11.12.200` - `10.11.12.210`

### Network Planning Assumptions

When setting up your VPN, consider these typical scenarios:
- **Client's network**: `192.168.0.1/24` (common in hotels, offices, public WiFi)
- **Your home network**: Choose one of the recommended ranges above
- **DNS setup**: Consider configuring a DNS record like `myvpn-63864.duckdns.org`
- **Port configuration**: Default port 1194 or custom port like 11194

### Why This Matters

When you connect to your home VPN from a remote location (hotel, office, etc.), if both networks use the same IP range like `192.168.1.0/24`, your device won't know whether to route traffic locally or through the VPN. Using a unique range like `10.99.99.0/24` eliminates this confusion.

---

## Why Bridge Mode?

Bridge mode is particularly useful for applications like ham radio (e.g., ExpertSDR3), where devices need to communicate as if they are on the same local network. Unlike routed mode, bridge mode allows broadcast and multicast traffic, which is essential for some applications.

---

## Installation Steps

### Step 1: Install Raspberry Pi OS

#### Option 1: Using Raspberry Pi Imager (Recommended)

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

#### Option 2: Manual Configuration

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

### Step 2: Configure Raspberry Pi

#### Initial Access

1. **Boot the Raspberry Pi**:
   - Insert the SD card and power on the Raspberry Pi
   - Wait 2-3 minutes for the initial boot process

2. **Find the IP address**:
   ```bash
   # Use nmap to scan your network
   nmap -sn 192.168.1.0/24
   
   # Or check your router's admin panel for connected devices
   ```

3. **Connect via SSH**:
   ```bash
   ssh pi@192.168.1.x
   # Use the username and password you configured
   ```

#### Essential Configuration Steps

1. **Update the system**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Configure static IP** (if not done during imaging):
   ```bash
   sudo raspi-config
   ```
   - Navigate to "Advanced Options" → "Network Config"
   - Or manually edit `/etc/dhcpcd.conf`

3. **Set timezone**:
   ```bash
   sudo raspi-config
   ```
   - Navigate to "Localisation Options" → "Timezone"

4. **Enable SSH permanently**:
   ```bash
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

5. **Install essential packages**:
   ```bash
   sudo apt install bridge-utils net-tools curl wget -y
   ```

#### Verify Configuration

Check network configuration:
```bash
ip addr show
ip route show
```

---

For the complete installation guide including all remaining steps, configuration details, and troubleshooting information, please refer to the [full documentation](https://github.com/linuxdevel/openvpn/blob/main/README.md).

## Quick Navigation

- [Step 3: Enable Automatic Updates](https://github.com/linuxdevel/openvpn/blob/main/README.md#step-3-enable-automatic-updates)
- [Step 4: Configure Static IP](https://github.com/linuxdevel/openvpn/blob/main/README.md#step-4-configure-static-ip)
- [Step 5: Install OpenVPN](https://github.com/linuxdevel/openvpn/blob/main/README.md#step-5-install-openvpn)
- [Step 6: Configure OpenVPN for Bridge Mode](https://github.com/linuxdevel/openvpn/blob/main/README.md#step-6-configure-openvpn-for-bridge-mode)
- [Step 7: Configure the Bridge Script](https://github.com/linuxdevel/openvpn/blob/main/README.md#step-7-configure-the-bridge-script)
- [Step 8: Test the Configuration](https://github.com/linuxdevel/openvpn/blob/main/README.md#step-8-test-the-configuration)
- [Step 9: Configure the Client](https://github.com/linuxdevel/openvpn/blob/main/README.md#step-9-configure-the-client)
- [Step 10: Configure Router Port Forwarding](https://github.com/linuxdevel/openvpn/blob/main/README.md#step-10-configure-router-port-forwarding)

## Troubleshooting

For comprehensive troubleshooting information including:
- Subnet Conflicts
- OpenVPN Service Issues
- Bridge Configuration Issues
- Client Connection Issues
- Network Connectivity Tests
- Performance Issues
- Log Analysis

Please visit the [Troubleshooting Section](https://github.com/linuxdevel/openvpn/blob/main/README.md#troubleshooting) in the main documentation.

## References

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

---

## Contributing

Found an issue or want to improve this documentation? Please visit our [GitHub repository](https://github.com/linuxdevel/openvpn) to contribute.

## License

This documentation is available under the MIT License. See the repository for full license details.