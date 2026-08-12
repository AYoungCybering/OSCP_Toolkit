#!/usr/bin/env python3
"""
Simple HTTP Server with Upload Support
Useful for file transfers during pentesting
"""

import http.server
import socketserver
import os
import sys
import argparse
import cgi
from urllib.parse import unquote

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler with file upload support"""
    
    def do_POST(self):
        """Handle file uploads via POST"""
        try:
            content_type = self.headers.get('Content-Type', '')
            
            if 'multipart/form-data' in content_type:
                # Handle multipart form upload
                form = cgi.FieldStorage(
                    fp=self.rfile,
                    headers=self.headers,
                    environ={
                        'REQUEST_METHOD': 'POST',
                        'CONTENT_TYPE': content_type,
                    }
                )
                
                if 'file' in form:
                    file_item = form['file']
                    filename = os.path.basename(file_item.filename)
                    filepath = os.path.join(os.getcwd(), filename)
                    
                    with open(filepath, 'wb') as f:
                        f.write(file_item.file.read())
                    
                    self.send_response(200)
                    self.send_header('Content-type', 'text/html')
                    self.end_headers()
                    response = f"<html><body><h1>File '{filename}' uploaded successfully!</h1></body></html>"
                    self.wfile.write(response.encode())
                    print(f"[+] File uploaded: {filepath}")
                    return
            else:
                # Handle raw body upload
                content_length = int(self.headers.get('Content-Length', 0))
                body = self.rfile.read(content_length)
                
                # Use path as filename or default to 'uploaded_file'
                filename = unquote(self.path.strip('/')) or 'uploaded_file'
                filename = os.path.basename(filename)
                filepath = os.path.join(os.getcwd(), filename)
                
                with open(filepath, 'wb') as f:
                    f.write(body)
                
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(f"File uploaded: {filename}\n".encode())
                print(f"[+] File uploaded: {filepath}")
                return
            
            self.send_error(400, "Bad Request")
            
        except Exception as e:
            self.send_error(500, f"Server Error: {str(e)}")
    
    def do_PUT(self):
        """Handle file uploads via PUT"""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            filename = unquote(self.path.strip('/')) or 'uploaded_file'
            filename = os.path.basename(filename)
            filepath = os.path.join(os.getcwd(), filename)
            
            with open(filepath, 'wb') as f:
                f.write(self.rfile.read(content_length))
            
            self.send_response(201)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(f"File uploaded: {filename}\n".encode())
            print(f"[+] File uploaded via PUT: {filepath}")
            
        except Exception as e:
            self.send_error(500, f"Server Error: {str(e)}")
    
    def list_directory(self, path):
        """Override to add upload form to directory listing"""
        response = super().list_directory(path)
        if response:
            # Add upload form to HTML
            content = response.fp.read()
            upload_form = b'''
            <hr>
            <h2>Upload File</h2>
            <form method="POST" enctype="multipart/form-data">
                <input type="file" name="file">
                <input type="submit" value="Upload">
            </form>
            '''
            content = content.replace(b'</body>', upload_form + b'</body>')
            response.fp.seek(0)
            response.fp.truncate()
            response.fp.write(content)
            response.fp.seek(0)
        return response


def run_server(port, bind_address='0.0.0.0'):
    """Start the HTTP server"""
    handler = CustomHTTPRequestHandler
    
    with socketserver.TCPServer((bind_address, port), handler) as httpd:
        print(f"[*] Serving HTTP on {bind_address}:{port}")
        print(f"[*] Directory: {os.getcwd()}")
        print(f"[*] Upload supported via POST/PUT")
        print("[*] Press Ctrl+C to stop\n")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[*] Server stopped")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Simple HTTP Server with Upload Support')
    parser.add_argument('-p', '--port', type=int, default=80, help='Port to serve on (default: 80)')
    parser.add_argument('-b', '--bind', default='0.0.0.0', help='Address to bind to (default: 0.0.0.0)')
    parser.add_argument('-d', '--directory', help='Directory to serve (default: current)')
    
    args = parser.parse_args()
    
    if args.directory:
        os.chdir(args.directory)
    
    run_server(args.port, args.bind)



