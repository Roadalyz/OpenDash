#!/usr/bin/env python3
"""
Documentation Server for Dashcam Project

This script provides a local web server for viewing the project documentation
with Mermaid diagram support, syntax highlighting, and responsive design.

Design Decision: We use a simple Python HTTP server with markdown rendering
instead of complex documentation generators like Sphinx or GitBook because:
1. Simplicity - Easy to setup and maintain
2. No external dependencies beyond Python standard library + markdown
3. Fast iteration - Changes are immediately visible
4. Portable - Works on all platforms without installation
5. Customizable - Easy to extend with additional features

Usage:
    python docs/serve_docs.py [--port PORT] [--host HOST]
"""

import argparse
import http.server
import os
import socketserver
import sys
import webbrowser
from pathlib import Path
from urllib.parse import unquote

try:
    import markdown
    from markdown.extensions import codehilite, toc, tables
    MARKDOWN_AVAILABLE = True
except ImportError:
    MARKDOWN_AVAILABLE = False
    print("Warning: markdown package not installed. Install with: pip install markdown")

# HTML template with Mermaid support and responsive design
HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} - Dashcam Documentation</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
    <style>
        :root {{
            --primary-color: #2563eb;
            --secondary-color: #64748b;
            --background-color: #ffffff;
            --text-color: #1e293b;
            --border-color: #e2e8f0;
            --code-background: #f8fafc;
            --sidebar-width: 280px;
        }}
        
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: var(--text-color);
            background-color: var(--background-color);
        }}
        
        .container {{
            display: flex;
            min-height: 100vh;
        }}
        
        .sidebar {{
            width: var(--sidebar-width);
            background-color: var(--code-background);
            border-right: 1px solid var(--border-color);
            padding: 2rem 1rem;
            position: fixed;
            height: 100vh;
            overflow-y: auto;
        }}
        
        .sidebar h3 {{
            color: var(--primary-color);
            margin-bottom: 1rem;
            font-size: 1.1rem;
        }}
        
        .sidebar ul {{
            list-style: none;
            margin-bottom: 2rem;
        }}
        
        .sidebar li {{
            margin-bottom: 0.5rem;
        }}
        
        .sidebar a {{
            color: var(--secondary-color);
            text-decoration: none;
            padding: 0.25rem 0.5rem;
            border-radius: 4px;
            display: block;
            transition: background-color 0.2s;
        }}
        
        .sidebar a:hover {{
            background-color: var(--background-color);
            color: var(--primary-color);
        }}
        
        .main-content {{
            margin-left: var(--sidebar-width);
            padding: 2rem 3rem;
            flex: 1;
            max-width: calc(100% - var(--sidebar-width));
        }}
        
        .header {{
            background: linear-gradient(135deg, var(--primary-color), #3b82f6);
            color: white;
            padding: 2rem 3rem;
            margin: -2rem -3rem 2rem -3rem;
        }}
        
        .header h1 {{
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
        }}
        
        .header p {{
            font-size: 1.1rem;
            opacity: 0.9;
        }}
        
        .content {{
            max-width: 800px;
        }}
        
        h1, h2, h3, h4, h5, h6 {{
            color: var(--text-color);
            margin-top: 2rem;
            margin-bottom: 1rem;
        }}
        
        h1 {{ font-size: 2rem; }}
        h2 {{ font-size: 1.5rem; }}
        h3 {{ font-size: 1.25rem; }}
        
        p {{
            margin-bottom: 1rem;
        }}
        
        code {{
            background-color: var(--code-background);
            padding: 0.125rem 0.25rem;
            border-radius: 3px;
            font-family: 'SF Mono', Monaco, 'Cascadia Code', Consolas, monospace;
            font-size: 0.875rem;
        }}
        
        pre {{
            background-color: var(--code-background);
            padding: 1rem;
            border-radius: 6px;
            overflow-x: auto;
            margin: 1rem 0;
            border: 1px solid var(--border-color);
        }}
        
        pre code {{
            background: none;
            padding: 0;
        }}
        
        blockquote {{
            border-left: 4px solid var(--primary-color);
            padding-left: 1rem;
            margin: 1rem 0;
            color: var(--secondary-color);
            font-style: italic;
        }}
        
        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
        }}
        
        th, td {{
            padding: 0.75rem;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }}
        
        th {{
            background-color: var(--code-background);
            font-weight: 600;
        }}
        
        .mermaid {{
            text-align: center;
            margin: 2rem 0;
        }}
        
        .alert {{
            padding: 1rem;
            border-radius: 6px;
            margin: 1rem 0;
            border-left: 4px solid;
        }}
        
        .alert-info {{
            background-color: #eff6ff;
            border-color: var(--primary-color);
            color: #1e40af;
        }}
        
        .alert-warning {{
            background-color: #fefce8;
            border-color: #eab308;
            color: #a16207;
        }}
        
        .alert-success {{
            background-color: #f0fdf4;
            border-color: #22c55e;
            color: #166534;
        }}
        
        .breadcrumb {{
            background-color: var(--code-background);
            padding: 0.75rem 1rem;
            margin: -2rem -3rem 2rem -3rem;
            border-bottom: 1px solid var(--border-color);
        }}
        
        .breadcrumb a {{
            color: var(--primary-color);
            text-decoration: none;
        }}
        
        .breadcrumb a:hover {{
            text-decoration: underline;
        }}
        
        @media (max-width: 768px) {{
            .sidebar {{
                display: none;
            }}
            
            .main-content {{
                margin-left: 0;
                max-width: 100%;
                padding: 1rem;
            }}
            
            .header {{
                margin: -1rem -1rem 1rem -1rem;
                padding: 1.5rem 1rem;
            }}
            
            .header h1 {{
                font-size: 1.8rem;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <nav class="sidebar">
            <h3>🏠 Getting Started</h3>
            <ul>
                <li><a href="/">Overview</a></li>
                <li><a href="/architecture/">Architecture</a></li>
                <li><a href="/development/setup.html">Project Setup</a></li>
                <li><a href="/development/building.html">Building</a></li>
            </ul>
            
            <h3>📖 Guides</h3>
            <ul>
                <li><a href="/guides/logging.html">Logging System</a></li>
                <li><a href="/guides/testing.html">Testing Guide</a></li>
                <li><a href="/guides/debugging.html">Debugging</a></li>
                <li><a href="/guides/tiger_style.html">Tiger Style</a></li>
            </ul>
            
            <h3>🐳 Deployment</h3>
            <ul>
                <li><a href="/deployment/docker.html">Docker Setup</a></li>
                <li><a href="/deployment/production.html">Production</a></li>
                <li><a href="/deployment/raspberry_pi.html">Raspberry Pi</a></li>
            </ul>
            
            <h3>🔧 Development</h3>
            <ul>
                <li><a href="/development/scripts.html">Build Scripts</a></li>
                <li><a href="/development/vscode.html">VS Code Setup</a></li>
                <li><a href="/development/contributing.html">Contributing</a></li>
            </ul>
            
            <h3>📚 API Reference</h3>
            <ul>
                <li><a href="/api/logger.html">Logger API</a></li>
                <li><a href="/api/core.html">Core Components</a></li>
                <li><a href="/api/utils.html">Utilities</a></li>
            </ul>
        </nav>
        
        <main class="main-content">
            {content}
        </main>
    </div>
    
    <script>
        // Initialize Mermaid
        mermaid.initialize({{
            startOnLoad: true,
            theme: 'default',
            securityLevel: 'loose',
            flowchart: {{
                useMaxWidth: true,
                htmlLabels: true
            }}
        }});
        
        // Initialize syntax highlighting
        hljs.highlightAll();
        
        // Smooth scrolling for anchor links
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {{
            anchor.addEventListener('click', function (e) {{
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {{
                    target.scrollIntoView({{
                        behavior: 'smooth',
                        block: 'start'
                    }});
                }}
            }});
        }});
    </script>
</body>
</html>"""


class DocumentationHandler(http.server.SimpleHTTPRequestHandler):
    """Custom HTTP handler for serving documentation with markdown rendering."""
    
    def __init__(self, *args, docs_root=None, **kwargs):
        self.docs_root = docs_root or Path(__file__).parent
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests with markdown processing."""
        path = unquote(self.path)
        
        # Remove query parameters and fragments
        if '?' in path:
            path = path.split('?')[0]
        if '#' in path:
            path = path.split('#')[0]
        
        # Handle root request
        if path == '/':
            path = '/index.html'
        
        # Convert .html requests to .md files
        if path.endswith('.html'):
            md_path = path[:-5] + '.md'
            if self.serve_markdown(md_path):
                return
        
        # Try to serve as regular file
        super().do_GET()
    
    def serve_markdown(self, path):
        """Render and serve a markdown file."""
        if not MARKDOWN_AVAILABLE:
            self.send_error(500, "Markdown rendering not available")
            return True
        
        # Construct file path
        if path.startswith('/'):
            path = path[1:]
        
        file_path = self.docs_root / path
        
        if not file_path.exists():
            return False
        
        try:
            # Read markdown content
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Configure markdown extensions
            md = markdown.Markdown(extensions=[
                'toc',
                'tables',
                'codehilite',
                'fenced_code',
                'attr_list'
            ])
            
            # Convert to HTML
            html_content = md.convert(content)
            
            # Post-process to convert Mermaid code blocks
            html_content = self.process_mermaid_blocks(html_content)
            
            # Extract title from first heading or filename
            title = "Documentation"
            if content.startswith('#'):
                title = content.split('\n')[0].lstrip('#').strip()
            
            # Generate breadcrumb
            breadcrumb = self.generate_breadcrumb(path)
            
            # Wrap in template
            full_html = HTML_TEMPLATE.format(
                title=title,
                content=breadcrumb + f'<div class="content">{html_content}</div>'
            )
            
            # Send response
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(full_html.encode('utf-8'))
            
            return True
            
        except Exception as e:
            self.send_error(500, f"Error rendering markdown: {e}")
            return True
    
    def process_mermaid_blocks(self, html_content):
        """Convert Mermaid code blocks to proper Mermaid divs."""
        import re
        import html
        
        # Pattern to find code blocks with language-mermaid class
        # This matches: <pre class="codehilite"><code class="language-mermaid">...content...</code></pre>
        pattern = r'<pre[^>]*><code class="language-mermaid">(.*?)</code></pre>'
        
        def replace_mermaid(match):
            # Decode HTML entities in the Mermaid content
            mermaid_code = html.unescape(match.group(1))
            # Return as a div with class="mermaid" for Mermaid.js to process
            return f'<div class="mermaid">{mermaid_code}</div>'
        
        # Replace all Mermaid code blocks
        html_content = re.sub(pattern, replace_mermaid, html_content, flags=re.DOTALL)
        
        return html_content
    
    def generate_breadcrumb(self, path):
        """Generate breadcrumb navigation."""
        parts = path.strip('/').split('/')
        breadcrumb_parts = ['<a href="/">Home</a>']
        
        current_path = ""
        for part in parts[:-1]:  # Exclude filename
            current_path += f"/{part}"
            part_name = part.replace('_', ' ').title()
            breadcrumb_parts.append(f'<a href="{current_path}/">{part_name}</a>')
        
        if len(breadcrumb_parts) > 1:
            return f'<div class="breadcrumb">{" > ".join(breadcrumb_parts)}</div>'
        return ""


def create_handler(docs_root):
    """Create a handler class with the docs root bound."""
    def handler(*args, **kwargs):
        return DocumentationHandler(*args, docs_root=docs_root, **kwargs)
    return handler


def main():
    """Main function to start the documentation server."""
    parser = argparse.ArgumentParser(description='Serve dashcam project documentation')
    parser.add_argument('--port', type=int, default=8080, help='Port to serve on (default: 8080)')
    parser.add_argument('--host', default='localhost', help='Host to bind to (default: localhost)')
    parser.add_argument('--no-browser', action='store_true', help='Don\'t open browser automatically')
    
    args = parser.parse_args()
    
    # Get documentation root directory
    docs_root = Path(__file__).parent
    
    # Change to docs directory
    os.chdir(docs_root)
    
    # Create server
    handler = create_handler(docs_root)
    
    try:
        with socketserver.TCPServer((args.host, args.port), handler) as httpd:
            url = f"http://{args.host}:{args.port}"
            print(f"📚 Serving dashcam documentation at {url}")
            print(f"📁 Documentation root: {docs_root}")
            print("Press Ctrl+C to stop the server")
            
            # Open browser if requested
            if not args.no_browser:
                try:
                    webbrowser.open(url)
                except Exception as e:
                    print(f"Could not open browser: {e}")
            
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n👋 Documentation server stopped")
    except OSError as e:
        if e.errno == 98:  # Address already in use
            print(f"❌ Error: Port {args.port} is already in use")
            print(f"Try using a different port: python {sys.argv[0]} --port {args.port + 1}")
        else:
            print(f"❌ Error starting server: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
