#!/bin/bash

# ============================================================
# Directory Enumeration Script
# Wrapper for common directory enumeration tools
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║            DIRECTORY ENUMERATION                      ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

usage() {
    echo "Usage: $0 <url> [options]"
    echo ""
    echo "Options:"
    echo "  -w <wordlist>    Custom wordlist (default: common.txt)"
    echo "  -x <extensions>  File extensions (e.g., php,html,txt)"
    echo "  -t <threads>     Number of threads (default: 50)"
    echo "  -o <output>      Output directory"
    echo "  -r               Recursive scan"
    echo "  --tool <tool>    Tool to use: gobuster, ffuf, dirb (default: auto)"
    echo ""
    echo "Examples:"
    echo "  $0 http://192.168.1.1"
    echo "  $0 http://192.168.1.1 -x php,html -w /path/to/wordlist.txt"
    echo "  $0 https://192.168.1.1 -t 100 --tool ffuf"
    exit 1
}

# Check available tools
check_tools() {
    if command -v gobuster &> /dev/null; then
        echo "gobuster"
    elif command -v ffuf &> /dev/null; then
        echo "ffuf"
    elif command -v dirb &> /dev/null; then
        echo "dirb"
    else
        echo "none"
    fi
}

# Find wordlist
find_wordlist() {
    local wordlists=(
        "/usr/share/wordlists/dirb/common.txt"
        "/usr/share/wordlists/dirbuster/directory-list-2.3-small.txt"
        "/usr/share/seclists/Discovery/Web-Content/common.txt"
        "/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt"
        "/opt/wordlists/common.txt"
    )
    
    for wl in "${wordlists[@]}"; do
        if [ -f "$wl" ]; then
            echo "$wl"
            return
        fi
    done
    
    echo ""
}

# Default values
WORDLIST=""
EXTENSIONS=""
THREADS=50
OUTPUT=""
RECURSIVE=false
TOOL=""
URL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w)
            WORDLIST="$2"
            shift 2
            ;;
        -x)
            EXTENSIONS="$2"
            shift 2
            ;;
        -t)
            THREADS="$2"
            shift 2
            ;;
        -o)
            OUTPUT="$2"
            shift 2
            ;;
        -r)
            RECURSIVE=true
            shift
            ;;
        --tool)
            TOOL="$2"
            shift 2
            ;;
        -h|--help)
            banner
            usage
            ;;
        *)
            if [ -z "$URL" ]; then
                URL="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$URL" ]; then
    banner
    usage
fi

banner

# Find wordlist if not specified
if [ -z "$WORDLIST" ]; then
    WORDLIST=$(find_wordlist)
    if [ -z "$WORDLIST" ]; then
        echo -e "${RED}[-] No wordlist found. Please specify one with -w${NC}"
        exit 1
    fi
fi

# Auto-detect tool if not specified
if [ -z "$TOOL" ]; then
    TOOL=$(check_tools)
fi

if [ "$TOOL" = "none" ]; then
    echo -e "${RED}[-] No directory enumeration tools found.${NC}"
    echo -e "${RED}[-] Please install gobuster, ffuf, or dirb${NC}"
    exit 1
fi

echo -e "${GREEN}[*] URL: $URL${NC}"
echo -e "${GREEN}[*] Wordlist: $WORDLIST${NC}"
echo -e "${GREEN}[*] Tool: $TOOL${NC}"
echo -e "${GREEN}[*] Threads: $THREADS${NC}"
[ -n "$EXTENSIONS" ] && echo -e "${GREEN}[*] Extensions: $EXTENSIONS${NC}"
echo ""

# Set output file
if [ -z "$OUTPUT" ]; then
    OUTPUT="./dir_enum_$(date +%Y%m%d_%H%M%S).txt"
fi

# Run enumeration based on tool
case $TOOL in
    gobuster)
        echo -e "${YELLOW}[*] Running Gobuster...${NC}"
        CMD="gobuster dir -u $URL -w $WORDLIST -t $THREADS -o $OUTPUT"
        
        [ -n "$EXTENSIONS" ] && CMD="$CMD -x $EXTENSIONS"
        
        # Add -k for HTTPS
        [[ "$URL" == https://* ]] && CMD="$CMD -k"
        
        echo -e "${BLUE}$CMD${NC}"
        echo ""
        eval $CMD
        ;;
        
    ffuf)
        echo -e "${YELLOW}[*] Running FFUF...${NC}"
        CMD="ffuf -u ${URL}/FUZZ -w $WORDLIST -t $THREADS -o $OUTPUT -of csv"
        
        if [ -n "$EXTENSIONS" ]; then
            # FFUF needs separate wordlist for extensions
            CMD="ffuf -u ${URL}/FUZZ -w $WORDLIST -t $THREADS -o $OUTPUT -of csv -e .$EXTENSIONS"
        fi
        
        echo -e "${BLUE}$CMD${NC}"
        echo ""
        eval $CMD
        ;;
        
    dirb)
        echo -e "${YELLOW}[*] Running Dirb...${NC}"
        CMD="dirb $URL $WORDLIST -o $OUTPUT"
        
        if [ -n "$EXTENSIONS" ]; then
            CMD="$CMD -X .$EXTENSIONS"
        fi
        
        echo -e "${BLUE}$CMD${NC}"
        echo ""
        eval $CMD
        ;;
esac

echo ""
echo -e "${GREEN}[+] Scan complete!${NC}"
echo -e "${GREEN}[*] Results saved to: $OUTPUT${NC}"

# Quick summary
if [ -f "$OUTPUT" ]; then
    echo ""
    echo -e "${YELLOW}Found directories/files:${NC}"
    case $TOOL in
        gobuster)
            grep "Status: 200\|Status: 301\|Status: 302\|Status: 403" "$OUTPUT" 2>/dev/null | head -20
            ;;
        ffuf)
            tail -n +2 "$OUTPUT" 2>/dev/null | head -20
            ;;
        dirb)
            grep "+ " "$OUTPUT" 2>/dev/null | head -20
            ;;
    esac
fi



