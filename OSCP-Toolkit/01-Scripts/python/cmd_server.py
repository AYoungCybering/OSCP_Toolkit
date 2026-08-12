#!/usr/bin/env python3
"""
OSCP Command Server v6.0
- Sends commands to ANY tmux session's active window
- Does NOT create sessions - you create them, server finds them
- Works with systemd service

Run: python3 cmd_server.py
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import json

PORT = 9999


def run_tmux(args):
    """Run tmux command"""
    try:
        result = subprocess.run(
            ['tmux'] + args,
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.returncode == 0, result.stdout.strip()
    except Exception as e:
        return False, str(e)


def find_session():
    """Find any running tmux session, prefer 'oscp' if exists"""
    ok, output = run_tmux(['list-sessions', '-F', '#{session_name}'])
    if not ok or not output:
        return None
    
    sessions = output.strip().split('\n')
    
    # Prefer 'oscp' session
    if 'oscp' in sessions:
        return 'oscp'
    
    # Otherwise use first available
    return sessions[0] if sessions else None


def get_active_window(session):
    """Get active window in session"""
    ok, output = run_tmux([
        'list-windows', '-t', session,
        '-F', '#{window_index}:#{window_name}:#{window_active}'
    ])
    
    if not ok or not output:
        return "0", "unknown"
    
    for line in output.split('\n'):
        parts = line.split(':')
        if len(parts) >= 3 and parts[2] == '1':
            return parts[0], parts[1]
    
    return "0", "unknown"


def send_command(cmd, execute=True):
    """Send command to active window of any tmux session"""
    
    session = find_session()
    if not session:
        return False, "No tmux session found! Run: tmux new -s oscp"
    
    win_idx, win_name = get_active_window(session)
    target = f"{session}:{win_idx}"
    
    # Send command
    ok, _ = run_tmux(['send-keys', '-t', target, cmd])
    if not ok:
        return False, f"Failed to send to {target}"
    
    if execute:
        run_tmux(['send-keys', '-t', target, 'Enter'])
    
    return True, f"{session}:{win_idx}:{win_name}"


class CommandHandler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_GET(self):
        """Return session status"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        
        session = find_session()
        if session:
            win_idx, win_name = get_active_window(session)
            active = f"{win_idx}:{win_name}"
        else:
            active = None
        
        self.wfile.write(json.dumps({
            'session': session,
            'exists': session is not None,
            'active': active
        }).encode())
    
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode('utf-8'))
            cmd = data.get('cmd', '')
            execute = data.get('execute', True)
            
            if not cmd:
                self.send_error_response("No command")
                return
            
            success, info = send_command(cmd, execute)
            
            if success:
                print(f"[→] {info} | {cmd[:50]}{'...' if len(cmd) > 50 else ''}")
                self.send_success_response({'window': info})
            else:
                print(f"[✗] {info}")
                self.send_error_response(info)
                
        except Exception as e:
            print(f"[ERR] {e}")
            self.send_error_response(str(e))
    
    def send_success_response(self, data):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'status': 'ok', **data}).encode())
    
    def send_error_response(self, message):
        self.send_response(500)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'status': 'error', 'message': message}).encode())
    
    def log_message(self, format, *args):
        pass


def main():
    print(f"""
╔═══════════════════════════════════════════════════════════════════╗
║              OSCP Command Server v6.0                             ║
╠═══════════════════════════════════════════════════════════════════╣
║  Commands go to your ACTIVE tmux window                           ║
║  Server finds your session automatically                          ║
╚═══════════════════════════════════════════════════════════════════╝

Listening on http://localhost:{PORT}
""")
    
    session = find_session()
    if session:
        win_idx, win_name = get_active_window(session)
        print(f"[✓] Found session: {session}, active: {win_idx}:{win_name}")
    else:
        print("[*] No tmux session yet - create one: tmux new -s oscp")
    
    print("\nPress Ctrl+C to stop\n" + "─" * 60)
    
    server = HTTPServer(('localhost', PORT), CommandHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        server.shutdown()


if __name__ == '__main__':
    main()
