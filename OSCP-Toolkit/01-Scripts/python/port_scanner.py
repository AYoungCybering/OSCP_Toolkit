#!/usr/bin/env python3
"""
Fast Multi-threaded Port Scanner
Useful when nmap is not available or for quick scans
"""

import socket
import sys
import argparse
import concurrent.futures
from datetime import datetime

# Common ports to scan
COMMON_PORTS = [
    21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 445, 993, 995,
    1723, 3306, 3389, 5432, 5900, 6379, 8080, 8443, 8888, 9090
]

TOP_100_PORTS = [
    7, 9, 13, 21, 22, 23, 25, 26, 37, 53, 79, 80, 81, 88, 106, 110, 111,
    113, 119, 135, 139, 143, 144, 179, 199, 389, 427, 443, 444, 445, 465,
    513, 514, 515, 543, 544, 548, 554, 587, 631, 646, 873, 990, 993, 995,
    1025, 1026, 1027, 1028, 1029, 1110, 1433, 1720, 1723, 1755, 1900, 2000,
    2001, 2049, 2121, 2717, 3000, 3128, 3306, 3389, 3986, 4899, 5000, 5009,
    5051, 5060, 5101, 5190, 5357, 5432, 5631, 5666, 5800, 5900, 6000, 6001,
    6646, 7070, 8000, 8008, 8009, 8080, 8081, 8443, 8888, 9100, 9999, 10000,
    32768, 49152, 49153, 49154, 49155, 49156, 49157
]


def scan_port(target: str, port: int, timeout: float = 1.0) -> tuple:
    """
    Scan a single port and return result
    
    Returns:
        tuple: (port, is_open, banner)
    """
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((target, port))
        
        if result == 0:
            # Try to grab banner
            banner = ""
            try:
                sock.settimeout(2)
                sock.send(b"HEAD / HTTP/1.0\r\n\r\n")
                banner = sock.recv(1024).decode('utf-8', errors='ignore').strip()[:100]
            except:
                try:
                    banner = sock.recv(1024).decode('utf-8', errors='ignore').strip()[:100]
                except:
                    pass
            
            sock.close()
            return (port, True, banner)
        
        sock.close()
        return (port, False, "")
        
    except socket.error:
        return (port, False, "")
    except Exception:
        return (port, False, "")


def get_service_name(port: int) -> str:
    """Get common service name for port"""
    services = {
        21: "ftp", 22: "ssh", 23: "telnet", 25: "smtp", 53: "dns",
        80: "http", 110: "pop3", 111: "rpcbind", 135: "msrpc", 139: "netbios",
        143: "imap", 443: "https", 445: "smb", 993: "imaps", 995: "pop3s",
        1433: "mssql", 1521: "oracle", 3306: "mysql", 3389: "rdp",
        5432: "postgresql", 5900: "vnc", 6379: "redis", 8080: "http-proxy",
        8443: "https-alt", 27017: "mongodb"
    }
    return services.get(port, "unknown")


def scan_host(target: str, ports: list, threads: int = 100, timeout: float = 1.0, verbose: bool = False):
    """
    Scan multiple ports on a host using thread pool
    """
    print(f"\n[*] Scanning {target}")
    print(f"[*] Ports: {len(ports)}")
    print(f"[*] Threads: {threads}")
    print(f"[*] Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    open_ports = []
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as executor:
        futures = {executor.submit(scan_port, target, port, timeout): port for port in ports}
        
        for future in concurrent.futures.as_completed(futures):
            port, is_open, banner = future.result()
            
            if is_open:
                service = get_service_name(port)
                open_ports.append((port, service, banner))
                
                banner_text = f" - {banner}" if banner else ""
                print(f"[+] {port}/tcp open {service}{banner_text}")
            elif verbose:
                print(f"[-] {port}/tcp closed")
    
    print(f"\n[*] Scan complete: {len(open_ports)} open ports found")
    print(f"[*] Finished: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return open_ports


def parse_ports(port_arg: str) -> list:
    """Parse port argument into list of ports"""
    ports = []
    
    for part in port_arg.split(','):
        if '-' in part:
            start, end = map(int, part.split('-'))
            ports.extend(range(start, end + 1))
        else:
            ports.append(int(part))
    
    return sorted(set(ports))


def main():
    parser = argparse.ArgumentParser(
        description='Fast Multi-threaded Port Scanner',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s 192.168.1.1                    # Scan common ports
  %(prog)s 192.168.1.1 -p 1-1000          # Scan port range
  %(prog)s 192.168.1.1 -p 80,443,8080     # Scan specific ports
  %(prog)s 192.168.1.1 --top100           # Scan top 100 ports
  %(prog)s 192.168.1.1 -p- -t 200         # All ports with 200 threads
        """
    )
    
    parser.add_argument('target', help='Target IP address or hostname')
    parser.add_argument('-p', '--ports', help='Port(s) to scan (e.g., 80,443 or 1-1000)')
    parser.add_argument('-p-', '--all-ports', action='store_true', help='Scan all 65535 ports')
    parser.add_argument('--top100', action='store_true', help='Scan top 100 ports')
    parser.add_argument('-t', '--threads', type=int, default=100, help='Number of threads (default: 100)')
    parser.add_argument('--timeout', type=float, default=1.0, help='Socket timeout in seconds (default: 1.0)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Show closed ports')
    parser.add_argument('-o', '--output', help='Output file for results')
    
    args = parser.parse_args()
    
    # Resolve hostname
    try:
        target = socket.gethostbyname(args.target)
    except socket.gaierror:
        print(f"[-] Could not resolve hostname: {args.target}")
        sys.exit(1)
    
    # Determine ports to scan
    if args.all_ports:
        ports = list(range(1, 65536))
    elif args.top100:
        ports = TOP_100_PORTS
    elif args.ports:
        ports = parse_ports(args.ports)
    else:
        ports = COMMON_PORTS
    
    # Run scan
    try:
        results = scan_host(target, ports, args.threads, args.timeout, args.verbose)
        
        # Save results if output file specified
        if args.output and results:
            with open(args.output, 'w') as f:
                f.write(f"# Port scan results for {target}\n")
                f.write(f"# {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
                for port, service, banner in sorted(results):
                    f.write(f"{port}/tcp open {service}\n")
            print(f"\n[*] Results saved to {args.output}")
            
    except KeyboardInterrupt:
        print("\n\n[!] Scan interrupted by user")
        sys.exit(1)


if __name__ == "__main__":
    main()



