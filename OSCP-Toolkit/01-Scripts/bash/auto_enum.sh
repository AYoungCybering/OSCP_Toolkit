#!/bin/bash

# ============================================================
# Automated Enumeration Script
# Run against a target to perform initial recon
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║              AUTO ENUMERATION SCRIPT                  ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

usage() {
    echo "Usage: $0 <target_ip> [output_dir]"
    echo ""
    echo "Options:"
    echo "  target_ip    Target IP address"
    echo "  output_dir   Output directory (default: ./enum_<target>)"
    exit 1
}

check_tools() {
    local tools=("nmap" "gobuster" "nikto" "enum4linux")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}[!] Missing tools: ${missing[*]}${NC}"
        echo -e "${YELLOW}[!] Some scans will be skipped${NC}"
    fi
}

# Check arguments
if [ -z "$1" ]; then
    banner
    usage
fi

TARGET="$1"
OUTPUT_DIR="${2:-./enum_$TARGET}"

banner
echo -e "${GREEN}[*] Target: $TARGET${NC}"
echo -e "${GREEN}[*] Output: $OUTPUT_DIR${NC}"
echo ""

check_tools

# Create output directory
mkdir -p "$OUTPUT_DIR"/{nmap,web,smb,misc}

# ============================================================
# NMAP SCANS
# ============================================================

echo -e "\n${BLUE}[+] Starting Nmap scans...${NC}"

# Quick TCP scan
echo -e "${YELLOW}[*] Quick TCP scan (top 1000 ports)...${NC}"
nmap -sC -sV -oA "$OUTPUT_DIR/nmap/quick" "$TARGET" 2>/dev/null &
QUICK_PID=$!

# Full TCP scan (background)
echo -e "${YELLOW}[*] Full TCP scan (all ports) - running in background...${NC}"
nmap -p- -sC -sV -oA "$OUTPUT_DIR/nmap/full" "$TARGET" 2>/dev/null &
FULL_PID=$!

# UDP scan (background)
echo -e "${YELLOW}[*] UDP scan (top 20) - running in background...${NC}"
nmap -sU --top-ports 20 -oA "$OUTPUT_DIR/nmap/udp" "$TARGET" 2>/dev/null &
UDP_PID=$!

# Wait for quick scan
wait $QUICK_PID
echo -e "${GREEN}[+] Quick scan complete${NC}"

# Parse quick scan results for open ports
OPEN_PORTS=$(grep -oP '\d+/open' "$OUTPUT_DIR/nmap/quick.gnmap" 2>/dev/null | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
echo -e "${GREEN}[*] Open ports: $OPEN_PORTS${NC}"

# ============================================================
# WEB ENUMERATION (if HTTP found)
# ============================================================

if grep -qE '80/open|443/open|8080/open|8443/open' "$OUTPUT_DIR/nmap/quick.gnmap" 2>/dev/null; then
    echo -e "\n${BLUE}[+] Web service detected - starting web enumeration...${NC}"
    
    # Determine HTTP/HTTPS ports
    HTTP_PORTS=$(grep -oP '(80|8080|8000|8888)/open' "$OUTPUT_DIR/nmap/quick.gnmap" 2>/dev/null | cut -d'/' -f1)
    HTTPS_PORTS=$(grep -oP '(443|8443)/open' "$OUTPUT_DIR/nmap/quick.gnmap" 2>/dev/null | cut -d'/' -f1)
    
    for port in $HTTP_PORTS; do
        echo -e "${YELLOW}[*] Gobuster on port $port...${NC}"
        if command -v gobuster &> /dev/null; then
            gobuster dir -u "http://$TARGET:$port" \
                -w /usr/share/wordlists/dirb/common.txt \
                -o "$OUTPUT_DIR/web/gobuster_$port.txt" \
                -q 2>/dev/null &
        fi
        
        echo -e "${YELLOW}[*] Nikto on port $port...${NC}"
        if command -v nikto &> /dev/null; then
            nikto -h "http://$TARGET:$port" -o "$OUTPUT_DIR/web/nikto_$port.txt" 2>/dev/null &
        fi
    done
    
    for port in $HTTPS_PORTS; do
        echo -e "${YELLOW}[*] Gobuster on port $port (HTTPS)...${NC}"
        if command -v gobuster &> /dev/null; then
            gobuster dir -u "https://$TARGET:$port" \
                -w /usr/share/wordlists/dirb/common.txt \
                -o "$OUTPUT_DIR/web/gobuster_https_$port.txt" \
                -k -q 2>/dev/null &
        fi
    done
fi

# ============================================================
# SMB ENUMERATION (if SMB found)
# ============================================================

if grep -qE '445/open|139/open' "$OUTPUT_DIR/nmap/quick.gnmap" 2>/dev/null; then
    echo -e "\n${BLUE}[+] SMB service detected - starting SMB enumeration...${NC}"
    
    if command -v enum4linux &> /dev/null; then
        echo -e "${YELLOW}[*] Running enum4linux...${NC}"
        enum4linux -a "$TARGET" > "$OUTPUT_DIR/smb/enum4linux.txt" 2>/dev/null &
    fi
    
    echo -e "${YELLOW}[*] Nmap SMB scripts...${NC}"
    nmap --script smb-enum-shares,smb-enum-users,smb-os-discovery -p 445 "$TARGET" \
        -oA "$OUTPUT_DIR/smb/nmap_smb" 2>/dev/null &
    
    echo -e "${YELLOW}[*] Checking for SMB vulnerabilities...${NC}"
    nmap --script smb-vuln* -p 445 "$TARGET" \
        -oA "$OUTPUT_DIR/smb/nmap_smb_vuln" 2>/dev/null &
fi

# ============================================================
# SERVICE-SPECIFIC ENUMERATION
# ============================================================

# FTP
if grep -qE '21/open' "$OUTPUT_DIR/nmap/quick.gnmap" 2>/dev/null; then
    echo -e "\n${BLUE}[+] FTP service detected${NC}"
    echo -e "${YELLOW}[*] Checking anonymous login...${NC}"
    nmap --script ftp-anon -p 21 "$TARGET" -oA "$OUTPUT_DIR/misc/ftp_anon" 2>/dev/null &
fi

# SSH
if grep -qE '22/open' "$OUTPUT_DIR/nmap/quick.gnmap" 2>/dev/null; then
    echo -e "\n${BLUE}[+] SSH service detected${NC}"
    echo -e "${YELLOW}[*] Grabbing SSH banner...${NC}"
    timeout 5 nc -nv "$TARGET" 22 > "$OUTPUT_DIR/misc/ssh_banner.txt" 2>&1 &
fi

# SNMP
if grep -qE '161/open' "$OUTPUT_DIR/nmap/udp.gnmap" 2>/dev/null; then
    echo -e "\n${BLUE}[+] SNMP service detected${NC}"
    if command -v snmpwalk &> /dev/null; then
        echo -e "${YELLOW}[*] Running snmpwalk...${NC}"
        snmpwalk -c public -v1 "$TARGET" > "$OUTPUT_DIR/misc/snmpwalk.txt" 2>/dev/null &
    fi
fi

# ============================================================
# WAIT AND SUMMARY
# ============================================================

echo -e "\n${BLUE}[+] Waiting for background scans to complete...${NC}"
echo -e "${YELLOW}[*] This may take a while. You can check partial results in $OUTPUT_DIR${NC}"

# Wait for all background jobs
wait

echo -e "\n${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}[+] Enumeration complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"

echo -e "\n${BLUE}Results saved to: $OUTPUT_DIR${NC}"
echo ""
echo "Quick summary:"
echo "  - Nmap results: $OUTPUT_DIR/nmap/"
echo "  - Web results:  $OUTPUT_DIR/web/"
echo "  - SMB results:  $OUTPUT_DIR/smb/"
echo "  - Other:        $OUTPUT_DIR/misc/"

# Display open ports summary
echo -e "\n${YELLOW}Open Ports:${NC}"
if [ -f "$OUTPUT_DIR/nmap/quick.nmap" ]; then
    grep "open" "$OUTPUT_DIR/nmap/quick.nmap" | head -20
fi



