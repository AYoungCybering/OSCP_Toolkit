# Enumeration Cheatsheet

## Initial Host Discovery

### Ping Sweep

```bash
# Using fping
fping -a -g 10.10.10.0/24 2>/dev/null

# Using nmap
nmap -sn 10.10.10.0/24 -oG - | grep "Up" | cut -d " " -f 2

# Using bash
for i in $(seq 1 254); do (ping -c 1 10.10.10.$i | grep "bytes from" &); done
```

---

## Port Scanning

### Nmap Quick Scans

```bash
# Quick TCP scan
nmap -sC -sV -oA nmap/initial TARGET

# Full TCP port scan
nmap -p- -sC -sV -oA nmap/full TARGET

# UDP scan (top 20)
nmap -sU --top-ports 20 -oA nmap/udp TARGET

# Fast scan (top 1000)
nmap -F TARGET

# Version detection on specific ports
nmap -sV -p 21,22,80,443 TARGET
```

### Nmap Detailed Scans

```bash
# Aggressive scan
nmap -A -T4 TARGET

# Scripts + version + default scripts
nmap -sC -sV -p- -T4 TARGET

# Vuln scan
nmap --script vuln TARGET

# All scripts for specific service
nmap --script "http-*" -p 80 TARGET
```

### Rustscan (Fast)

```bash
rustscan -a TARGET -- -sC -sV
rustscan -a TARGET -p 1-65535 -- -A
```

### Masscan (Very Fast)

```bash
masscan -p1-65535,U:1-65535 TARGET --rate=1000 -e tun0
```

---

## Service Enumeration

### FTP (21)

```bash
# Anonymous login
ftp TARGET
> anonymous
> anonymous

# Nmap scripts
nmap --script ftp-anon,ftp-bounce,ftp-libopie,ftp-proftpd-backdoor,ftp-vsftpd-backdoor,ftp-vuln-cve2010-4221 -p 21 TARGET

# Download all files
wget -m ftp://anonymous:anonymous@TARGET
wget -m --no-passive ftp://anonymous:anonymous@TARGET
```

### SSH (22)

```bash
# Banner grab
nc -nv TARGET 22

# Nmap scripts
nmap --script ssh2-enum-algos,ssh-hostkey,ssh-auth-methods -p 22 TARGET

# Brute force
hydra -l user -P /usr/share/wordlists/rockyou.txt TARGET ssh
```

### SMTP (25)

```bash
# Connect
nc -nv TARGET 25

# VRFY users
smtp-user-enum -M VRFY -U users.txt -t TARGET

# Nmap scripts
nmap --script smtp-commands,smtp-enum-users,smtp-vuln-cve2010-4344,smtp-vuln-cve2011-1720,smtp-vuln-cve2011-1764 -p 25 TARGET
```

### DNS (53)

```bash
# Zone transfer
dig axfr @TARGET DOMAIN
dnsrecon -d DOMAIN -t axfr
host -l DOMAIN TARGET

# Enumeration
dnsenum DOMAIN
dnsrecon -d DOMAIN -D /usr/share/wordlists/dnsmap.txt -t std

# Reverse DNS
dnsrecon -r 10.10.10.0/24 -n TARGET
```

### HTTP/HTTPS (80/443)

```bash
# Nikto
nikto -h http://TARGET

# Gobuster directory
gobuster dir -u http://TARGET -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,html,txt

# Feroxbuster
feroxbuster -u http://TARGET -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt

# Wfuzz
wfuzz -c -z file,/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt --hc 404 http://TARGET/FUZZ

# Whatweb
whatweb http://TARGET

# Wappalyzer (browser extension)

# Virtual host enumeration
gobuster vhost -u http://TARGET -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt

# API enumeration
gobuster dir -u http://TARGET/api -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
```

### Kerberos (88)

```bash
# User enumeration
kerbrute userenum --dc TARGET -d DOMAIN users.txt

# AS-REP Roasting
GetNPUsers.py DOMAIN/ -usersfile users.txt -format hashcat -outputfile hashes.txt

# Kerberoasting
GetUserSPNs.py DOMAIN/USER:PASSWORD -dc-ip TARGET -outputfile hashes.txt
```

### POP3 (110)

```bash
# Connect
nc -nv TARGET 110
telnet TARGET 110

# Commands
USER username
PASS password
LIST
RETR 1
```

### RPCBind (111)

```bash
# Enumerate
rpcinfo -p TARGET
nmap -sV -p 111 --script=rpcinfo TARGET
```

### SMB (139/445)

```bash
# Enumerate shares
smbclient -L //TARGET -N
smbmap -H TARGET
smbmap -H TARGET -u guest

# Connect to share
smbclient //TARGET/share -N
smbclient //TARGET/share -U username

# Enum4linux
enum4linux -a TARGET

# Nmap scripts
nmap --script smb-enum-shares,smb-enum-users,smb-os-discovery -p 445 TARGET
nmap --script smb-vuln* -p 445 TARGET

# CrackMapExec
crackmapexec smb TARGET -u '' -p '' --shares
crackmapexec smb TARGET -u user -p password --shares
```

### SNMP (161)

```bash
# Community string bruteforce
onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt TARGET

# Enumerate with community string
snmpwalk -c public -v1 TARGET
snmpwalk -c public -v2c TARGET 1.3.6.1.4.1.77.1.2.25  # Windows users
snmpwalk -c public -v2c TARGET 1.3.6.1.2.1.6.13.1.3   # TCP ports

# snmp-check
snmp-check TARGET -c public
```

### LDAP (389)

```bash
# Anonymous bind
ldapsearch -x -H ldap://TARGET -b "dc=DOMAIN,dc=com"

# Enumeration
ldapsearch -x -H ldap://TARGET -D "user@domain.com" -w 'password' -b "dc=DOMAIN,dc=com"

# Nmap
nmap -p 389 --script ldap-search TARGET
```

### MSSQL (1433)

```bash
# Nmap
nmap --script ms-sql-info,ms-sql-empty-password,ms-sql-xp-cmdshell,ms-sql-config,ms-sql-ntlm-info,ms-sql-tables,ms-sql-hasdbaccess,ms-sql-dac,ms-sql-dump-hashes --script-args mssql.instance-port=1433,mssql.username=sa,mssql.password=,mssql.instance-name=MSSQLSERVER -sV -p 1433 TARGET

# Impacket
mssqlclient.py user:password@TARGET -windows-auth
```

### MySQL (3306)

```bash
# Connect
mysql -h TARGET -u root -p

# Nmap
nmap --script mysql-info,mysql-enum,mysql-empty-password,mysql-brute -p 3306 TARGET
```

### RDP (3389)

```bash
# Nmap
nmap --script rdp-enum-encryption,rdp-vuln-ms12-020 -p 3389 TARGET

# Connect
rdesktop TARGET
xfreerdp /v:TARGET /u:user /p:password
```

### WinRM (5985/5986)

```bash
# Check if accessible
crackmapexec winrm TARGET -u user -p password

# Connect
evil-winrm -i TARGET -u user -p password
```

### NFS (2049)

```bash
# Show mounts
showmount -e TARGET

# Mount
mount -t nfs TARGET:/share /mnt/nfs

# Nmap
nmap --script nfs-ls,nfs-showmount,nfs-statfs -p 2049 TARGET
```

---

## Web Enumeration

### Technology Detection

```bash
whatweb http://TARGET
curl -I http://TARGET
```

### Directory Bruteforce

```bash
# Gobuster
gobuster dir -u http://TARGET -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,html,txt,bak

# Feroxbuster
feroxbuster -u http://TARGET -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,html

# Dirb
dirb http://TARGET /usr/share/dirb/wordlists/common.txt

# FFUF
ffuf -u http://TARGET/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
```

### Subdomain Enumeration

```bash
# Gobuster
gobuster dns -d TARGET -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt

# FFUF vhost
ffuf -u http://TARGET -H "Host: FUZZ.TARGET" -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -fc 301,302

# Sublist3r
sublist3r -d TARGET
```

### Parameter Fuzzing

```bash
# GET parameters
ffuf -u 'http://TARGET/page?FUZZ=test' -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt

# POST parameters
ffuf -u http://TARGET/page -X POST -d 'FUZZ=test' -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt
```

---

## Vulnerability Scanning

```bash
# Nmap vuln scripts
nmap --script vuln TARGET

# Nikto
nikto -h http://TARGET

# Nuclei
nuclei -u http://TARGET -t /path/to/nuclei-templates/

# Searchsploit
searchsploit SERVICE_NAME VERSION
searchsploit -m EXPLOIT_ID  # Mirror/copy exploit
```



