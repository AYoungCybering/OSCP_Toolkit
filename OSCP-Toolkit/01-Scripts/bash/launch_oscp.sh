#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  OSCP Toolkit Launcher
#  Opens tmux with root shell - services handle the rest
#═══════════════════════════════════════════════════════════════════════════════

SESSION="oscp"
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
TOOLKIT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

#───────────────────────────────────────────────────────────────────────────────
# Find a terminal emulator
#───────────────────────────────────────────────────────────────────────────────
find_terminal() {
    for term in qterminal xfce4-terminal gnome-terminal konsole mate-terminal terminator xterm; do
        if command -v "$term" &> /dev/null; then
            echo "$term"
            return 0
        fi
    done
    return 1
}

#───────────────────────────────────────────────────────────────────────────────
# Launch in terminal if not already in one
#───────────────────────────────────────────────────────────────────────────────
if [ ! -t 0 ] || [ ! -t 1 ]; then
    TERMINAL=$(find_terminal)
    if [ -z "$TERMINAL" ]; then
        notify-send "OSCP Toolkit" "No terminal found! Open a terminal and run this script." 2>/dev/null
        exit 1
    fi
    
    case "$TERMINAL" in
        gnome-terminal)
            gnome-terminal -- bash -c "$SCRIPT_PATH; exec bash"
            ;;
        qterminal)
            qterminal -e bash -c "$SCRIPT_PATH; exec bash"
            ;;
        xfce4-terminal)
            xfce4-terminal -e "bash -c '$SCRIPT_PATH; exec bash'"
            ;;
        konsole)
            konsole -e bash -c "$SCRIPT_PATH; exec bash"
            ;;
        *)
            $TERMINAL -e "$SCRIPT_PATH"
            ;;
    esac
    exit 0
fi

#───────────────────────────────────────────────────────────────────────────────
# Main script (in terminal)
#───────────────────────────────────────────────────────────────────────────────
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║             OSCP Toolkit Launcher                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check tmux
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}[✗] tmux not installed!${NC}"
    echo "    Run: sudo apt install tmux"
    read -p "Press Enter to exit..."
    exit 1
fi

# Ensure services are running (if installed)
if systemctl --user is-enabled oscp-cmd-server.service &>/dev/null 2>&1; then
    echo -e "${CYAN}[*] Checking services...${NC}"
    systemctl --user start oscp-cmd-server.service 2>/dev/null
    systemctl --user start oscp-http-server.service 2>/dev/null
    echo -e "${GREEN}[✓] Services running${NC}"
else
    echo -e "${YELLOW}[!] Services not installed. Run: ~/OSCP-Toolkit/install.sh${NC}"
fi

# Handle existing session
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${YELLOW}[!] Session '$SESSION' exists${NC}"
    echo ""
    echo "  1) Attach to it"
    echo "  2) Kill and restart"
    echo "  3) Exit"
    read -p "Choice [1/2/3]: " choice
    
    case $choice in
        1) 
            echo -e "${GREEN}[+] Attaching...${NC}"
            tmux attach -t "$SESSION"
            exit 0 
            ;;
        2) 
            tmux kill-session -t "$SESSION" 
            ;;
        *) 
            exit 0 
            ;;
    esac
fi

echo -e "${GREEN}[+] Creating tmux session with root shell...${NC}"

# Create session
tmux new-session -d -s "$SESSION" -n "root"
# tmux send-keys -t "$SESSION:0" "sudo -i" Enter

# Open browser if services are running
if systemctl --user is-active oscp-http-server.service &>/dev/null 2>&1; then
    sleep 0.5
    xdg-open "http://localhost:8888" 2>/dev/null &
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ Ready!                                                         ║${NC}"
echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                                   ║${NC}"
echo -e "${GREEN}║  You're in a ROOT SHELL - commands from browser go here           ║${NC}"
echo -e "${GREEN}║                                                                   ║${NC}"
echo -e "${GREEN}║  Browser: http://localhost:8888                                   ║${NC}"
echo -e "${GREEN}║                                                                   ║${NC}"
echo -e "${GREEN}║  Ctrl+B c = new window    Ctrl+B n = next window                  ║${NC}"
echo -e "${GREEN}║  Ctrl+B d = detach        Ctrl+B 0 = window 0                     ║${NC}"
echo -e "${GREEN}║                                                                   ║${NC}"
echo -e "${GREEN}║  Commands FOLLOW your active window!                              ║${NC}"
echo -e "${GREEN}║                                                                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Attach to session
tmux attach -t "$SESSION"
