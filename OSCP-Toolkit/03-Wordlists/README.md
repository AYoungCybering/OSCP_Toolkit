# Wordlists

## Download Instructions

### SecLists (Recommended)

```bash
# Clone entire repository
git clone https://github.com/danielmiessler/SecLists.git

# Or download specific lists
# Directories
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt

# Common
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt

# Subdomains
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt
```

### RockYou

```bash
# Usually included in Kali at /usr/share/wordlists/rockyou.txt.gz
gunzip /usr/share/wordlists/rockyou.txt.gz

# Or download
wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
```

---

## Directory Structure

```
03-Wordlists/
├── rockyou.txt              # Password cracking (14M passwords)
├── directory-wordlists/     # Web directory enumeration
│   ├── common.txt
│   ├── directory-list-2.3-small.txt
│   ├── directory-list-2.3-medium.txt
│   ├── raft-small-directories.txt
│   └── raft-medium-directories.txt
├── username-lists/          # Username enumeration
│   ├── names.txt
│   ├── top-usernames-shortlist.txt
│   └── xato-net-10-million-usernames.txt
└── password-lists/          # Password lists
    ├── 10k-most-common.txt
    ├── 100k-most-common.txt
    ├── darkweb2017-top10000.txt
    └── probable-v2-top12000.txt
```

---

## Essential Wordlists

### Web Directory Enumeration

| File | Size | Use Case |
|------|------|----------|
| common.txt | 4,652 | Quick scans |
| directory-list-2.3-small.txt | 87K | Standard scan |
| directory-list-2.3-medium.txt | 220K | Thorough scan |
| raft-medium-directories.txt | 30K | Alternative |

### Password Cracking

| File | Size | Use Case |
|------|------|----------|
| rockyou.txt | 14M | Primary password list |
| 10k-most-common.txt | 10K | Quick password spray |
| darkweb2017-top10000.txt | 10K | Leaked passwords |

### Username Enumeration

| File | Size | Use Case |
|------|------|----------|
| top-usernames-shortlist.txt | 17 | Common usernames |
| names.txt | 10K | Name-based usernames |

---

## Quick Download Script

```bash
#!/bin/bash
# download_wordlists.sh

mkdir -p wordlists/{directories,usernames,passwords}

# Directories
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -O wordlists/directories/common.txt
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-small.txt -O wordlists/directories/directory-list-small.txt
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt -O wordlists/directories/directory-list-medium.txt

# Usernames
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/top-usernames-shortlist.txt -O wordlists/usernames/top-usernames.txt
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/Names/names.txt -O wordlists/usernames/names.txt

# Passwords
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt -O wordlists/passwords/10k-most-common.txt
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/darkweb2017-top10000.txt -O wordlists/passwords/darkweb-top10000.txt

echo "Wordlists downloaded to ./wordlists/"
```

---

## Kali Linux Paths

```bash
# Default wordlist locations in Kali
/usr/share/wordlists/
/usr/share/wordlists/rockyou.txt
/usr/share/wordlists/dirb/common.txt
/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
/usr/share/seclists/  # If SecLists installed
```

---

## Tool-Specific Usage

### Gobuster

```bash
gobuster dir -u http://target -w directory-wordlists/common.txt
gobuster dir -u http://target -w directory-wordlists/directory-list-2.3-medium.txt -x php,html,txt
```

### Hydra

```bash
hydra -L username-lists/top-usernames.txt -P password-lists/10k-most-common.txt ssh://target
```

### John the Ripper

```bash
john --wordlist=rockyou.txt hashes.txt
```

### Hashcat

```bash
hashcat -m 0 -a 0 hashes.txt rockyou.txt
```

---

## Custom Wordlist Generation

### CeWL (Spider website for words)

```bash
cewl http://target -m 5 -w custom_wordlist.txt
```

### Crunch (Generate patterns)

```bash
# 8 character passwords with specific charset
crunch 8 8 -t ,@@^^%%% -o passwords.txt

# Company name variations
crunch 6 8 -t company%% -o company_passwords.txt
```

### Username Generation

```bash
# From names
cat names.txt | while read name; do
    first=$(echo $name | cut -d' ' -f1)
    last=$(echo $name | cut -d' ' -f2)
    echo "${first,,}"
    echo "${last,,}"
    echo "${first,,}.${last,,}"
    echo "${first:0:1}${last,,}"
done > generated_usernames.txt
```



