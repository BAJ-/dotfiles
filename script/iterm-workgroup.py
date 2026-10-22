"""Adds a Workgroup to iTerm2's settings (Settings › Workgroups) unless it's there
already, by ID or name, so one you've renamed stays as it is.

    python3 iterm-workgroup.py <workgroup.json> [--dry-run]

Prints "present", "added", or "missing" for a dry run. iTerm2 reads its
Workgroups when it starts."""
import json
import os
import plistlib
import subprocess
import sys
import tempfile

DOMAIN = 'com.googlecode.iterm2'

path, dry_run = sys.argv[1], '--dry-run' in sys.argv[2:]
with open(path) as f:
    ours = json.load(f)

# Exported to a file the settings are a binary plist. Exported to stdout they're
# XML, which can't hold the control characters some settings have (a Set Tab
# Status trigger separates its fields with U+0001), and Python won't read that
with tempfile.TemporaryDirectory() as tmp:
    export = os.path.join(tmp, 'settings.plist')
    # Before iTerm2's first launch there are no settings yet
    if subprocess.run(['defaults', 'export', DOMAIN, export], capture_output=True).returncode == 0:
        with open(export, 'rb') as f:
            prefs = plistlib.load(f)
    else:
        prefs = {}
# A JSON array of Workgroups, stored as data. If it doesn't parse this fails
# rather than replace what's there
current = json.loads(prefs['Workgroups']) if 'Workgroups' in prefs else []

if any(w.get('uniqueIdentifier') == ours['uniqueIdentifier'] or w.get('name') == ours['name'] for w in current):
    print('present')
elif dry_run:
    print('missing')
else:
    data = json.dumps(current + [ours], separators=(',', ':'), ensure_ascii=False).encode()
    subprocess.run(['defaults', 'write', DOMAIN, 'Workgroups', '-data', data.hex()], check=True)
    print('added')
