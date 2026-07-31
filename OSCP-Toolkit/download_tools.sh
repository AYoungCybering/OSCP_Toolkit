#!/bin/bash

# OSCP Toolkit - Download All Tools (Bash/Linux)
# Run as: chmod +x download_tools.sh && ./download_tools.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           OSCP TOOLKIT - DOWNLOAD ALL TOOLS               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Create directories
mkdir -p 02-Enumeration/linux
mkdir -p 02-Enumeration/windows
mkdir -p 03-Wordlists/directory-wordlists
mkdir -p 03-Wordlists/username-lists
mkdir -p 03-Wordlists/password-lists
mkdir -p 06-Exploits/kernel_exploits
mkdir -p 06-Exploits/windows_lpe
mkdir -p 08-Pivoting/chisel

download() {
    local url="$1"
    local output="$2"
    local desc="$3"
    
    echo -e "${YELLOW}[*] Downloading $desc...${NC}"
    if wget -q "$url" -O "$output" 2>/dev/null || curl -sL "$url" -o "$output" 2>/dev/null; then
        echo -e "${GREEN}[+] $desc downloaded!${NC}"
        return 0
    else
        echo -e "${RED}[-] Failed to download $desc${NC}"
        return 1
    fi
}

echo -e "\n${CYAN}=== Linux Enumeration Tools ===${NC}"

download "https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh" \
    "02-Enumeration/linux/linpeas.sh" "LinPEAS"
chmod +x 02-Enumeration/linux/linpeas.sh 2>/dev/null || true

download "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" \
    "02-Enumeration/linux/linenum.sh" "LinEnum"
chmod +x 02-Enumeration/linux/linenum.sh 2>/dev/null || true

download "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" \
    "02-Enumeration/linux/lse.sh" "Linux Smart Enumeration"
chmod +x 02-Enumeration/linux/lse.sh 2>/dev/null || true

download "https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64" \
    "02-Enumeration/linux/pspy64" "pspy64"
chmod +x 02-Enumeration/linux/pspy64 2>/dev/null || true

download "https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy32" \
    "02-Enumeration/linux/pspy32" "pspy32"
chmod +x 02-Enumeration/linux/pspy32 2>/dev/null || true

download "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" \
    "02-Enumeration/linux/linux-exploit-suggester.sh" "Linux Exploit Suggester"
chmod +x 02-Enumeration/linux/linux-exploit-suggester.sh 2>/dev/null || true

echo -e "\n${CYAN}=== Windows Enumeration Tools ===${NC}"

download "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe" \
    "02-Enumeration/windows/winPEASx64.exe" "WinPEAS x64"

download "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx86.exe" \
    "02-Enumeration/windows/winPEASx86.exe" "WinPEAS x86"

download "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat" \
    "02-Enumeration/windows/winPEAS.bat" "WinPEAS batch"

download "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Seatbelt.exe" \
    "02-Enumeration/windows/Seatbelt.exe" "Seatbelt"

download "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpUp.exe" \
    "02-Enumeration/windows/SharpUp.exe" "SharpUp"

download "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" \
    "02-Enumeration/windows/PowerUp.ps1" "PowerUp"

download "https://live.sysinternals.com/accesschk64.exe" \
    "02-Enumeration/windows/accesschk64.exe" "AccessChk"

echo -e "\n${CYAN}=== Windows PrivEsc Exploits ===${NC}"

download "https://github.com/itm4n/PrintSpoofer/releases/download/v1.0/PrintSpoofer64.exe" \
    "06-Exploits/windows_lpe/PrintSpoofer64.exe" "PrintSpoofer x64"

download "https://github.com/itm4n/PrintSpoofer/releases/download/v1.0/PrintSpoofer32.exe" \
    "06-Exploits/windows_lpe/PrintSpoofer32.exe" "PrintSpoofer x32"

download "https://github.com/BeichenDream/GodPotato/releases/download/V1.20/GodPotato-NET4.exe" \
    "06-Exploits/windows_lpe/GodPotato-NET4.exe" "GodPotato NET4"

download "https://github.com/BeichenDream/GodPotato/releases/download/V1.20/GodPotato-NET2.exe" \
    "06-Exploits/windows_lpe/GodPotato-NET2.exe" "GodPotato NET2"

download "https://github.com/int0x33/nc.exe/raw/master/nc64.exe" \
    "06-Exploits/windows_lpe/nc64.exe" "Netcat x64"

download "https://github.com/int0x33/nc.exe/raw/master/nc.exe" \
    "06-Exploits/windows_lpe/nc.exe" "Netcat x86"

echo -e "\n${CYAN}=== Pivoting Tools ===${NC}"

download "https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_amd64.gz" \
    "08-Pivoting/chisel/chisel_linux_amd64.gz" "Chisel Linux x64"

download "https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_windows_amd64.gz" \
    "08-Pivoting/chisel/chisel_windows_amd64.gz" "Chisel Windows x64"

# Extract chisel
echo -e "${YELLOW}[*] Extracting Chisel binaries...${NC}"
cd 08-Pivoting/chisel
if [ -f chisel_linux_amd64.gz ]; then
    gunzip -f chisel_linux_amd64.gz 2>/dev/null || true
    mv chisel_linux_amd64 chisel_linux 2>/dev/null || true
    chmod +x chisel_linux 2>/dev/null || true
fi
if [ -f chisel_windows_amd64.gz ]; then
    gunzip -f chisel_windows_amd64.gz 2>/dev/null || true
    mv chisel_windows_amd64 chisel.exe 2>/dev/null || true
fi
cd "$SCRIPT_DIR"

echo -e "\n${CYAN}=== Wordlists ===${NC}"

download "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt" \
    "03-Wordlists/directory-wordlists/common.txt" "Common directories"

download "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt" \
    "03-Wordlists/directory-wordlists/directory-list-2.3-medium.txt" "Directory list medium"

download "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt" \
    "03-Wordlists/directory-wordlists/raft-medium-directories.txt" "Raft medium directories"

download "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/top-usernames-shortlist.txt" \
    "03-Wordlists/username-lists/top-usernames-shortlist.txt" "Top usernames"

download "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/Names/names.txt" \
    "03-Wordlists/username-lists/names.txt" "Names list"

download "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt" \
    "03-Wordlists/password-lists/10k-most-common.txt" "10k common passwords"

download "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/darkweb2017-top10000.txt" \
    "03-Wordlists/password-lists/darkweb2017-top10000.txt" "Darkweb top 10k"

echo -e "\n${CYAN}=== Reverse Shell Scripts ===${NC}"

download "https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php" \
    "07-ReverseShells/php-reverse-shell.php" "PHP reverse shell"

download "https://raw.githubusercontent.com/samratashok/nishang/master/Shells/Invoke-PowerShellTcp.ps1" \
    "07-ReverseShells/Invoke-PowerShellTcp.ps1" "Nishang PowerShell TCP"

# Optional: Copy rockyou if on Kali
if [ -f /usr/share/wordlists/rockyou.txt ]; then
    echo -e "${YELLOW}[*] Copying rockyou.txt from Kali...${NC}"
    cp /usr/share/wordlists/rockyou.txt 03-Wordlists/rockyou.txt
    echo -e "${GREEN}[+] rockyou.txt copied!${NC}"
elif [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    echo -e "${YELLOW}[*] Extracting rockyou.txt from Kali...${NC}"
    gunzip -c /usr/share/wordlists/rockyou.txt.gz > 03-Wordlists/rockyou.txt
    echo -e "${GREEN}[+] rockyou.txt extracted!${NC}"
else
    echo -e "${YELLOW}[!] rockyou.txt not found - copy manually from Kali${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[+] Download complete!${NC}"
echo ""
echo -e "${YELLOW}Tool locations:${NC}"
echo "  Linux enumeration: 02-Enumeration/linux/"
echo "  Windows enumeration: 02-Enumeration/windows/"
echo "  Windows exploits: 06-Exploits/windows_lpe/"
echo "  Chisel: 08-Pivoting/chisel/"
echo "  Wordlists: 03-Wordlists/"
echo ""



