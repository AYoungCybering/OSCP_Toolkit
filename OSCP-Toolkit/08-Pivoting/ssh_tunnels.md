# SSH Tunneling Guide

## Local Port Forwarding (-L)

Access remote service through local port.

```
Attacker → SSH → Pivot → Target
Access target through localhost on attacker
```

### Syntax

```bash
ssh -L LOCAL_PORT:TARGET_IP:TARGET_PORT user@PIVOT_HOST
```

### Examples

```bash
# Access internal web server (192.168.1.100:80) via localhost:8080
ssh -L 8080:192.168.1.100:80 user@pivot.host
# Now: curl http://localhost:8080

# Access internal RDP (192.168.1.100:3389) via localhost:3389
ssh -L 3389:192.168.1.100:3389 user@pivot.host
# Now: rdesktop localhost

# Access internal SSH
ssh -L 2222:192.168.1.100:22 user@pivot.host
# Now: ssh -p 2222 localhost

# Access internal database
ssh -L 3306:192.168.1.100:3306 user@pivot.host
# Now: mysql -h 127.0.0.1 -P 3306
```

---

## Remote Port Forwarding (-R)

Expose local service to remote network.

```
Target → SSH → Pivot → Attacker
Target can access attacker's service through pivot
```

### Syntax

```bash
ssh -R REMOTE_PORT:LOCAL_IP:LOCAL_PORT user@PIVOT_HOST
```

### Examples

```bash
# Expose your web server to pivot network
ssh -R 8080:127.0.0.1:80 user@pivot.host
# Pivot can now access your web server at localhost:8080

# Expose your listener for reverse shell
ssh -R 4444:127.0.0.1:4444 user@pivot.host
# Target can connect to pivot:4444, reaches your listener
```

---

## Dynamic Port Forwarding (-D) / SOCKS Proxy

Create SOCKS proxy for flexible routing.

### Syntax

```bash
ssh -D LOCAL_PORT user@PIVOT_HOST
```

### Examples

```bash
# Create SOCKS proxy on port 9050
ssh -D 9050 user@pivot.host

# Use with proxychains
# Edit /etc/proxychains4.conf:
# socks5 127.0.0.1 9050

proxychains nmap -sT -Pn 192.168.1.0/24
proxychains curl http://internal.site
proxychains ssh user@internal.host
```

### Browser Configuration

```
SOCKS Host: 127.0.0.1
Port: 9050
SOCKS v5
```

---

## Useful SSH Options

```bash
# Common flags
-N    # Don't execute remote command (just tunnel)
-f    # Background after authentication
-C    # Enable compression
-q    # Quiet mode
-T    # Disable pseudo-terminal allocation
-v    # Verbose (add more v's for more verbose: -vvv)

# Combined example - background SOCKS proxy
ssh -D 9050 -N -f user@pivot.host

# Keep tunnel alive
ssh -o ServerAliveInterval=60 -D 9050 -N user@pivot.host

# Using SSH key
ssh -i key.pem -D 9050 -N user@pivot.host
```

---

## ProxyJump (-J) / Jump Hosts

SSH through multiple hosts.

```bash
# SSH to target through pivot
ssh -J user@pivot.host user@target.host

# Multiple jumps
ssh -J user@pivot1,user@pivot2 user@target.host

# Equivalent using ProxyCommand
ssh -o ProxyCommand="ssh -W %h:%p user@pivot.host" user@target.host
```

---

## SSH Config File

Simplify complex tunnels in `~/.ssh/config`:

```
# Simple jump host
Host target
    HostName 192.168.1.100
    User admin
    ProxyJump user@pivot.host

# SOCKS proxy
Host socks-proxy
    HostName pivot.host
    User user
    DynamicForward 9050
    
# Port forward
Host forward-rdp
    HostName pivot.host
    User user
    LocalForward 3389 192.168.1.100:3389
```

Usage:
```bash
ssh target
ssh socks-proxy -N
ssh forward-rdp -N
```

---

## sshuttle

VPN-like tunnel over SSH.

### Installation

```bash
apt install sshuttle
pip install sshuttle
```

### Usage

```bash
# Tunnel entire subnet
sshuttle -r user@pivot.host 192.168.1.0/24

# Multiple subnets
sshuttle -r user@pivot.host 192.168.1.0/24 10.0.0.0/8

# All traffic except pivot
sshuttle -r user@pivot.host 0/0 -x pivot.host

# With SSH key
sshuttle -r user@pivot.host 192.168.1.0/24 --ssh-cmd "ssh -i key.pem"

# DNS through tunnel
sshuttle --dns -r user@pivot.host 0/0
```

---

## autossh

Persistent SSH tunnels that auto-reconnect.

### Installation

```bash
apt install autossh
```

### Usage

```bash
# Persistent SOCKS proxy
autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -D 9050 -N user@pivot.host

# Persistent port forward
autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -L 8080:192.168.1.100:80 -N user@pivot.host
```

---

## Double Pivot with SSH

### Scenario

```
Attacker → Pivot1 → Pivot2 → Target
```

### Setup

```bash
# First tunnel to pivot1
ssh -D 9050 -N user@pivot1

# Through proxy, SSH to pivot2
proxychains ssh -D 9051 -N user@pivot2

# Use second proxy for target network
# Add to proxychains.conf: socks5 127.0.0.1 9051
proxychains nmap -sT -Pn target
```

### Alternative - Chained Tunnels

```bash
# On attacker - tunnel to pivot1
ssh -L 2222:pivot2_internal_ip:22 user@pivot1

# Through tunnel - tunnel to pivot2
ssh -L 3333:target:80 -p 2222 user@localhost

# Access target:80 at localhost:3333
```

---

## Troubleshooting

### Permission Denied for Low Ports

```bash
# Use ports > 1024 or run as root
ssh -L 8080:target:80 user@pivot    # Works
ssh -L 80:target:80 user@pivot      # Needs root
sudo ssh -L 80:target:80 user@pivot # Works
```

### "Could not request local forwarding"

```bash
# Check if port is in use
netstat -tlnp | grep PORT

# Use different local port
ssh -L 8081:target:80 user@pivot
```

### Remote Forwarding Not Working

```bash
# Enable on SSH server (/etc/ssh/sshd_config)
GatewayPorts yes

# Then restart sshd
systemctl restart sshd
```

### Tunnel Drops

```bash
# Use keepalive
ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 ...

# Or use autossh
autossh -M 0 -o "ServerAliveInterval 30" ...
```

---

## Quick Reference

| Use Case | Command |
|----------|---------|
| Access remote:80 locally | `ssh -L 8080:192.168.1.100:80 user@pivot` |
| SOCKS proxy | `ssh -D 9050 -N user@pivot` |
| Expose local:80 remotely | `ssh -R 8080:127.0.0.1:80 user@pivot` |
| Background tunnel | `ssh -D 9050 -N -f user@pivot` |
| Jump through host | `ssh -J user@pivot user@target` |
| VPN-like tunnel | `sshuttle -r user@pivot 192.168.1.0/24` |



