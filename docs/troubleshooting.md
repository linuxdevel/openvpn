---
layout: default
title: "Troubleshooting Guide"
description: "Solutions for common OpenVPN bridge mode issues"
nav_order: 4
---

# Troubleshooting Guide

This page provides solutions for common issues encountered when setting up and running OpenVPN in bridge mode.

## Table of Contents
- [Subnet Conflicts](#subnet-conflicts)
- [OpenVPN Service Issues](#openvpn-service-issues)
- [Bridge Configuration Issues](#bridge-configuration-issues)
- [Client Connection Issues](#client-connection-issues)
- [Network Connectivity Tests](#network-connectivity-tests)
- [Performance Issues](#performance-issues)
- [Log Analysis](#log-analysis)

---

## Subnet Conflicts

### Problem: VPN doesn't work from certain locations

**Symptoms**: VPN connects but you can't access local resources or internet

**Cause**: The remote network uses the same IP range as your home network

**Solution**:
1. **Identify the conflict**:
   ```bash
   # On client, check local IP before connecting
   ipconfig  # Windows
   ifconfig  # macOS/Linux
   ```

2. **Change your home network IP range**:
   - Choose a unique range like `10.99.99.0/24`
   - Update your router's DHCP settings
   - Update Raspberry Pi static IP
   - Update bridge script configuration
   - Update OpenVPN server configuration

3. **Alternative: Use specific routes**:
   Add to client configuration:
   ```conf
   # Only route home network traffic through VPN
   route 10.99.99.0 255.255.255.0
   route-nopull
   ```

---

## OpenVPN Service Issues

### Problem: OpenVPN service won't start

**Check service status**:
```bash
sudo systemctl status openvpn-server@server
sudo journalctl -u openvpn-server@server
```

**Common causes and solutions**:

1. **Configuration syntax errors**:
   ```bash
   # Test configuration
   sudo openvpn --config /etc/openvpn/server/server.conf --verb 4
   ```

2. **Port already in use**:
   ```bash
   sudo netstat -tulpn | grep 1194
   sudo lsof -i :1194
   ```

3. **Bridge script permissions**:
   ```bash
   sudo chmod +x /etc/openvpn/bridge_start.sh
   sudo chmod +x /etc/openvpn/bridge_stop.sh
   sudo chown root:root /etc/openvpn/bridge_*.sh
   ```

4. **Missing bridge-utils**:
   ```bash
   sudo apt install bridge-utils
   ```

### Problem: Service starts but clients can't connect

1. **Check firewall settings**:
   ```bash
   # UFW
   sudo ufw allow 1194/udp
   
   # iptables
   sudo iptables -I INPUT -p udp --dport 1194 -j ACCEPT
   ```

2. **Verify port forwarding** on your router

3. **Check external connectivity**:
   Use an online port checker to verify port 1194 is open

---

## Bridge Configuration Issues

### Problem: Bridge not created

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

4. **Wrong network configuration** in bridge script:
   ```bash
   sudo nano /etc/openvpn/bridge_start.sh
   # Verify eth, eth_ip, eth_gateway match your network
   ```

### Problem: Bridge created but no network connectivity

1. **Check IP configuration**:
   ```bash
   ip addr show br0
   ip route show
   ```

2. **Verify MAC address**:
   ```bash
   # Bridge should use the same MAC as physical interface
   ip link show eth0
   ip link show br0
   ```

3. **Test basic connectivity**:
   ```bash
   ping 10.99.99.1  # Your router
   ping google.com
   ```

---

## Client Connection Issues

### Problem: Client can't connect to server

**Check client logs**:
- Windows: Check OpenVPN GUI log window
- macOS: Check Console.app for OpenVPN messages  
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

4. **Wrong server address**:
   - Verify the server IP/hostname in client config
   - Test connectivity: `ping your-server-ip`

### Problem: Client connects but gets no IP address

1. **Check server-bridge configuration**:
   ```bash
   sudo nano /etc/openvpn/server/server.conf
   # Verify server-bridge line is correct
   ```

2. **Verify IP pool range**:
   - Ensure client IP range doesn't conflict with DHCP
   - Check if IP pool is exhausted

3. **Bridge interface issues**:
   ```bash
   # Ensure bridge is properly configured
   brctl show
   ip addr show br0
   ```

---

## Network Connectivity Tests

### From Raspberry Pi

```bash
# Test internet connectivity
ping google.com

# Test local network
ping 10.99.99.1  # Your router

# Check listening ports
sudo netstat -tulpn | grep openvpn

# Test OpenVPN management interface (if enabled)
telnet localhost 7505
```

### From client (when connected)

```bash
# Test VPN server
ping 10.99.99.134  # Your Pi's IP

# Test other local devices
ping 10.99.99.1    # Your router

# Test internet through VPN
ping google.com

# Check assigned IP
ipconfig /all  # Windows
ifconfig       # macOS/Linux
```

### Connectivity Troubleshooting Steps

1. **Layer by layer testing**:
   - Physical connectivity (cables, WiFi)
   - Network layer (ping gateway)
   - Transport layer (telnet to port)
   - Application layer (web browser, specific apps)

2. **Trace route analysis**:
   ```bash
   # From client
   traceroute google.com
   traceroute 10.99.99.1
   ```

3. **DNS resolution testing**:
   ```bash
   nslookup google.com
   dig google.com
   ```

---

## Performance Issues

### Problem: Slow VPN speeds

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
   
   # Optimize fragment size
   fragment 1300
   mssfix 1300
   ```

4. **Check network interface speed**:
   ```bash
   sudo ethtool eth0
   ```

### Problem: High latency

1. **Check server location** - Use a VPN server geographically closer
2. **Test direct connection** vs VPN connection latency
3. **Router QoS settings** - Prioritize VPN traffic
4. **ISP throttling** - Test at different times of day

---

## Log Analysis

### Enable Verbose Logging

```bash
sudo nano /etc/openvpn/server/server.conf
# Change: verb 3
# To: verb 4 or verb 5
```

### Key Log Locations

- **OpenVPN server**: `journalctl -u openvpn-server@server`
- **System logs**: `/var/log/syslog`
- **OpenVPN status**: `/var/log/openvpn/status.log` (if enabled)

### Common Error Patterns

| Error Message | Cause | Solution |
|---------------|--------|----------|
| "TLS handshake failed" | Certificate/key issues | Check certificates, regenerate if needed |
| "Cannot allocate TUN/TAP" | TAP driver or permissions | Install TAP driver, check permissions |
| "RESOLVE: Cannot resolve host" | DNS or network issues | Check DNS settings, network connectivity |
| "Connection reset by peer" | Firewall or port forwarding | Check firewall rules, router config |
| "AUTH_FAILED" | Authentication problems | Verify username/password, certificates |
| "TLS Error: cannot locate HMAC" | Key configuration mismatch | Check ta.key configuration |

### Useful Log Analysis Commands

```bash
# Follow OpenVPN logs in real-time
sudo journalctl -u openvpn-server@server -f

# Show only errors
sudo journalctl -u openvpn-server@server -p err

# Show logs from last boot
sudo journalctl -u openvpn-server@server -b

# Show logs from specific time
sudo journalctl -u openvpn-server@server --since "2023-01-01 10:00:00"
```

---

## Advanced Troubleshooting

### Network Packet Analysis

1. **Install tcpdump**:
   ```bash
   sudo apt install tcpdump
   ```

2. **Capture VPN traffic**:
   ```bash
   # Capture on UDP port 1194
   sudo tcpdump -i any -nn port 1194
   
   # Capture on bridge interface
   sudo tcpdump -i br0 -nn
   
   # Capture on TAP interface
   sudo tcpdump -i tap0 -nn
   ```

3. **Analyze with Wireshark** for detailed packet inspection

### System Resource Monitoring

```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check network statistics
cat /proc/net/dev

# Check OpenVPN process
ps aux | grep openvpn
```

### Reset to Working State

If you need to start over:

1. **Stop OpenVPN**:
   ```bash
   sudo systemctl stop openvpn-server@server
   ```

2. **Remove bridge**:
   ```bash
   sudo /etc/openvpn/bridge_stop.sh
   ```

3. **Restore original config**:
   ```bash
   sudo cp /etc/openvpn/server/server.conf.backup /etc/openvpn/server/server.conf
   ```

4. **Restart networking**:
   ```bash
   sudo systemctl restart networking
   sudo systemctl restart dhcpcd
   ```

---

## Getting Help

If you're still experiencing issues:

1. **Collect information**:
   - OpenVPN version: `openvpn --version`
   - OS version: `lsb_release -a`
   - Network configuration: `ip addr show`
   - Error logs: `journalctl -u openvpn-server@server`

2. **Check online resources**:
   - [OpenVPN Community Forums](https://forums.openvpn.net/)
   - [OpenVPN Documentation](https://openvpn.net/community-resources/)
   - [Raspberry Pi Forums](https://www.raspberrypi.org/forums/)

3. **Consider professional support** for critical deployments

Remember to sanitize any logs or configurations before sharing them publicly (remove IP addresses, certificates, keys, etc.).