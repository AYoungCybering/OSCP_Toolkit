# OSCP Toolkit - Download All Tools (PowerShell)
# Run as: powershell -ExecutionPolicy Bypass -File download_tools.ps1

$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'  # Speeds up downloads

Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║           OSCP TOOLKIT - DOWNLOAD ALL TOOLS               ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create directories
$dirs = @(
    "02-Enumeration/linux",
    "02-Enumeration/windows",
    "03-Wordlists/directory-wordlists",
    "03-Wordlists/username-lists",
    "03-Wordlists/password-lists",
    "06-Exploits/kernel_exploits",
    "06-Exploits/windows_lpe",
    "08-Pivoting/chisel"
)

foreach ($dir in $dirs) {
    $path = Join-Path $BaseDir $dir
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Download-File {
    param($Url, $Output, $Description)
    
    Write-Host "[*] Downloading $Description..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Output -UseBasicParsing
        Write-Host "[+] $Description downloaded!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[-] Failed to download $Description" -ForegroundColor Red
        return $false
    }
}

Write-Host "`n=== Linux Enumeration Tools ===" -ForegroundColor Cyan

# LinPEAS
Download-File `
    -Url "https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh" `
    -Output (Join-Path $BaseDir "02-Enumeration/linux/linpeas.sh") `
    -Description "LinPEAS"

# LinEnum
Download-File `
    -Url "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" `
    -Output (Join-Path $BaseDir "02-Enumeration/linux/linenum.sh") `
    -Description "LinEnum"

# Linux Smart Enumeration
Download-File `
    -Url "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" `
    -Output (Join-Path $BaseDir "02-Enumeration/linux/lse.sh") `
    -Description "Linux Smart Enumeration"

# pspy64
Download-File `
    -Url "https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64" `
    -Output (Join-Path $BaseDir "02-Enumeration/linux/pspy64") `
    -Description "pspy64"

# pspy32
Download-File `
    -Url "https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy32" `
    -Output (Join-Path $BaseDir "02-Enumeration/linux/pspy32") `
    -Description "pspy32"

# Linux Exploit Suggester
Download-File `
    -Url "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" `
    -Output (Join-Path $BaseDir "02-Enumeration/linux/linux-exploit-suggester.sh") `
    -Description "Linux Exploit Suggester"

Write-Host "`n=== Windows Enumeration Tools ===" -ForegroundColor Cyan

# WinPEAS x64
Download-File `
    -Url "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe" `
    -Output (Join-Path $BaseDir "02-Enumeration/windows/winPEASx64.exe") `
    -Description "WinPEAS x64"

# WinPEAS x86
Download-File `
    -Url "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx86.exe" `
    -Output (Join-Path $BaseDir "02-Enumeration/windows/winPEASx86.exe") `
    -Description "WinPEAS x86"

# WinPEAS bat (less detection)
Download-File `
    -Url "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat" `
    -Output (Join-Path $BaseDir "02-Enumeration/windows/winPEAS.bat") `
    -Description "WinPEAS batch"

# Seatbelt
Download-File `
    -Url "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Seatbelt.exe" `
    -Output (Join-Path $BaseDir "02-Enumeration/windows/Seatbelt.exe") `
    -Description "Seatbelt"

# SharpUp
Download-File `
    -Url "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpUp.exe" `
    -Output (Join-Path $BaseDir "02-Enumeration/windows/SharpUp.exe") `
    -Description "SharpUp"

# PowerUp.ps1
Download-File `
    -Url "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" `
    -Output (Join-Path $BaseDir "02-Enumeration/windows/PowerUp.ps1") `
    -Description "PowerUp"

# accesschk (Sysinternals)
Download-File `
    -Url "https://live.sysinternals.com/accesschk64.exe" `
    -Output (Join-Path $BaseDir "02-Enumeration/windows/accesschk64.exe") `
    -Description "AccessChk"

Write-Host "`n=== Windows PrivEsc Exploits ===" -ForegroundColor Cyan

# PrintSpoofer
Download-File `
    -Url "https://github.com/itm4n/PrintSpoofer/releases/download/v1.0/PrintSpoofer64.exe" `
    -Output (Join-Path $BaseDir "06-Exploits/windows_lpe/PrintSpoofer64.exe") `
    -Description "PrintSpoofer x64"

Download-File `
    -Url "https://github.com/itm4n/PrintSpoofer/releases/download/v1.0/PrintSpoofer32.exe" `
    -Output (Join-Path $BaseDir "06-Exploits/windows_lpe/PrintSpoofer32.exe") `
    -Description "PrintSpoofer x32"

# GodPotato
Download-File `
    -Url "https://github.com/BeichenDream/GodPotato/releases/download/V1.20/GodPotato-NET4.exe" `
    -Output (Join-Path $BaseDir "06-Exploits/windows_lpe/GodPotato-NET4.exe") `
    -Description "GodPotato NET4"

Download-File `
    -Url "https://github.com/BeichenDream/GodPotato/releases/download/V1.20/GodPotato-NET2.exe" `
    -Output (Join-Path $BaseDir "06-Exploits/windows_lpe/GodPotato-NET2.exe") `
    -Description "GodPotato NET2"

# nc.exe (netcat for Windows)
Download-File `
    -Url "https://github.com/int0x33/nc.exe/raw/master/nc64.exe" `
    -Output (Join-Path $BaseDir "06-Exploits/windows_lpe/nc64.exe") `
    -Description "Netcat x64"

Download-File `
    -Url "https://github.com/int0x33/nc.exe/raw/master/nc.exe" `
    -Output (Join-Path $BaseDir "06-Exploits/windows_lpe/nc.exe") `
    -Description "Netcat x86"

Write-Host "`n=== Pivoting Tools ===" -ForegroundColor Cyan

# Chisel Linux
Download-File `
    -Url "https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_amd64.gz" `
    -Output (Join-Path $BaseDir "08-Pivoting/chisel/chisel_linux_amd64.gz") `
    -Description "Chisel Linux x64"

# Chisel Windows
Download-File `
    -Url "https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_windows_amd64.gz" `
    -Output (Join-Path $BaseDir "08-Pivoting/chisel/chisel_windows_amd64.gz") `
    -Description "Chisel Windows x64"

Write-Host "`n=== Wordlists ===" -ForegroundColor Cyan

# Common directories
Download-File `
    -Url "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt" `
    -Output (Join-Path $BaseDir "03-Wordlists/directory-wordlists/common.txt") `
    -Description "Common directories"

# Directory list medium
Download-File `
    -Url "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt" `
    -Output (Join-Path $BaseDir "03-Wordlists/directory-wordlists/directory-list-2.3-medium.txt") `
    -Description "Directory list medium"

# Raft directories
Download-File `
    -Url "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt" `
    -Output (Join-Path $BaseDir "03-Wordlists/directory-wordlists/raft-medium-directories.txt") `
    -Description "Raft medium directories"

# Top usernames
Download-File `
    -Url "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/top-usernames-shortlist.txt" `
    -Output (Join-Path $BaseDir "03-Wordlists/username-lists/top-usernames-shortlist.txt") `
    -Description "Top usernames"

# Names
Download-File `
    -Url "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/Names/names.txt" `
    -Output (Join-Path $BaseDir "03-Wordlists/username-lists/names.txt") `
    -Description "Names list"

# Common passwords
Download-File `
    -Url "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt" `
    -Output (Join-Path $BaseDir "03-Wordlists/password-lists/10k-most-common.txt") `
    -Description "10k common passwords"

# Darkweb passwords
Download-File `
    -Url "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/darkweb2017-top10000.txt" `
    -Output (Join-Path $BaseDir "03-Wordlists/password-lists/darkweb2017-top10000.txt") `
    -Description "Darkweb top 10k"

Write-Host "`n=== Reverse Shell Scripts ===" -ForegroundColor Cyan

# PHP reverse shell
Download-File `
    -Url "https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php" `
    -Output (Join-Path $BaseDir "07-ReverseShells/php-reverse-shell.php") `
    -Description "PHP reverse shell"

# Nishang PowerShell shells
Download-File `
    -Url "https://raw.githubusercontent.com/samratashok/nishang/master/Shells/Invoke-PowerShellTcp.ps1" `
    -Output (Join-Path $BaseDir "07-ReverseShells/Invoke-PowerShellTcp.ps1") `
    -Description "Nishang PowerShell TCP"

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "[+] Download complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Notes:" -ForegroundColor Yellow
Write-Host "  - Chisel files are gzipped. Extract with: gzip -d filename.gz"
Write-Host "  - rockyou.txt is too large to download here (~140MB)"
Write-Host "    Get it from Kali: /usr/share/wordlists/rockyou.txt.gz"
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")



