#!/bin/bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║             OSCP Toolkit Installer                                ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/OSCP-Toolkit"

echo -e "${CYAN}[*] Installing to $INSTALL_DIR...${NC}"
rm -rf "$INSTALL_DIR"
cp -r "$SCRIPT_DIR" "$INSTALL_DIR"

find "$INSTALL_DIR" -type f \( -name "*.sh" -o -name "*.py" -o -name "START" \) -exec sed -i 's/\r$//' {} \; 2>/dev/null
chmod +x "$INSTALL_DIR/START" "$INSTALL_DIR/INSTALL.sh" 2>/dev/null

mkdir -p "$HOME/Desktop"
cat > "$HOME/Desktop/OSCP-Toolkit.desktop" << DESKTOP
[Desktop Entry]
Name=OSCP Toolkit
Exec=$INSTALL_DIR/START
Icon=utilities-terminal
Terminal=false
Type=Application
DESKTOP
chmod +x "$HOME/Desktop/OSCP-Toolkit.desktop"

echo -e "${GREEN}[✓] Installed! Desktop shortcut created.${NC}"
echo -e "${GREEN}[✓] Run: ~/OSCP-Toolkit/START${NC}"

read -p "Start now? [Y/n] " -n 1 -r
echo
[[ ! $REPLY =~ ^[Nn]$ ]] && cd "$INSTALL_DIR" && exec ./START
