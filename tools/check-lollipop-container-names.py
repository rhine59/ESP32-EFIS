#!/usr/bin/env python3
"""Check every Compose service has an explicit lollipop-prefixed container name."""
from pathlib import Path
import re
import sys
root=Path(__file__).resolve().parents[1]
failures=[]
for compose in sorted(root.rglob('compose.yml')):
    if any(part.startswith('build') for part in compose.relative_to(root).parts):continue
    text=compose.read_text()
    services=text.split('services:',1)
    if len(services)<2:
        failures.append(f'{compose}: no services');continue
    body=services[1].split('\nnetworks:',1)[0].split('\nvolumes:',1)[0].split('\nsecrets:',1)[0]
    for match in re.finditer(r'^  ([\w-]+):\s*$',body,re.M):
        start=match.end();next_service=re.search(r'^  [\w-]+:\s*$',body[start:],re.M)
        section=body[start:start+next_service.start()] if next_service else body[start:]
        names=re.findall(r'^    container_name:\s*([\w-]+)\s*$',section,re.M)
        if len(names)!=1 or not names[0].startswith('lollipop-'):
            failures.append(f'{compose.relative_to(root)}:{match.group(1)}: {names!r}')
if failures:
    print('\n'.join(failures),file=sys.stderr);sys.exit(1)
print('PASS: every Compose service uses an explicit lollipop- container name')
