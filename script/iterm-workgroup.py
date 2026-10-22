"""Adds a Workgroup to iTerm2's settings (Settings › Workgroups) unless it's there
already, by ID or name, so one you've renamed stays as it is.

    python3 iterm-workgroup.py <workgroup.json> [--dry-run]

Prints "present", "added", or "missing" for a dry run. iTerm2 reads its
Workgroups when it starts."""
import json
import plistlib
import subprocess
import sys

DOMAIN = 'com.googlecode.iterm2'

path, dry_run = sys.argv[1], '--dry-run' in sys.argv[2:]
with open(path) as f:
    ours = json.load(f)

export = subprocess.run(['defaults', 'export', DOMAIN, '-'], capture_output=True)
# Before iTerm2's first launch there are no settings yet
prefs = plistlib.loads(export.stdout) if export.returncode == 0 else {}
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
