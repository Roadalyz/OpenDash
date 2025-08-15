#!/usr/bin/env python3
"""Debug script to test Mermaid rendering."""

import markdown
import re
import html

# Simple test markdown with Mermaid
test_md = '''
# Test Document

Here's a Mermaid diagram:

```mermaid
graph TD
    A[Start] --> B[End]
```

End of test.
'''

def process_mermaid_blocks(html_content):
    """Convert Mermaid code blocks to proper Mermaid divs."""
    
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

# Test markdown conversion
md = markdown.Markdown(extensions=[
    'toc',
    'tables',
    'codehilite',
    'fenced_code',
    'attr_list'
])

html_before = md.convert(test_md)
print("HTML BEFORE Mermaid processing:")
print("=" * 50)
print(html_before)
print("=" * 50)

html_after = process_mermaid_blocks(html_before)
print("\nHTML AFTER Mermaid processing:")
print("=" * 50)
print(html_after)
print("=" * 50)
