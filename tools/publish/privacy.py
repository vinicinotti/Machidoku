"""Build and audit the public payload without changing the working project."""
from __future__ import annotations

import hashlib
import ipaddress
import json
import re
import struct
import subprocess
from pathlib import Path

ROOT_FILES = {
    '.gitignore', '.gitattributes', 'README.md', 'Jogar.cmd', 'Testar.ps1',
    'Publicar.ps1', 'CODEX_VISUAL_REFINEMENT_PROMPT.md', 'LICENSE',
}
ROOT_DIRS = {'game', 'docs', 'levels', 'tests', 'tools', '.github'}
DENIED_PARTS = {
    '.git', '.godot', '.venv', '__pycache__', 'node_modules', '.publish',
    'artifacts', 'engine', 'build', 'dist', '.pytest_cache',
}
DENIED_EXTENSIONS = {
    '.zip', '.7z', '.rar', '.log', '.exe', '.dll', '.pdb', '.dmp', '.pck',
    '.pem', '.key', '.p12', '.pfx', '.keystore', '.db', '.sqlite', '.sqlite3',
    '.pyc', '.pyo', '.bak', '.tmp',
}
TEXT_EXTENSIONS = {
    '.md', '.txt', '.json', '.svg', '.gd', '.gdshader', '.tscn', '.tres',
    '.cfg', '.godot', '.import', '.uid', '.py', '.ps1', '.cmd', '.yml', '.yaml',
}
WINDOWS_HOME = re.compile(r'(?i)[a-z]:[\\/]+Users[\\/]+[^\\/\s`"<>]+')
WINDOWS_WORKSPACE = re.compile(
    r'(?i)[a-z]:[\\/]+Users[\\/]+[^\\/\s`"<>]+[\\/]+Documents[\\/]+Machidoku'
)
UNIX_HOME = re.compile(r'/(?:home|Users)/[A-Za-z0-9_.-]+(?:/|$)')
EMAIL = re.compile(r'(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b')
IPV4 = re.compile(r'(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])')
IPV6 = re.compile(r'(?<![\w:])(?:[0-9A-Fa-f]{0,4}:){2,7}[0-9A-Fa-f]{0,4}(?![\w:])')
MAC = re.compile(r'(?<![\w:])(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}(?![\w:])|(?i:\b(?:mac|bssid|hardware[_ -]?address)\s*[:=]\s*)(?:[0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}(?!\w)')
SECRET = re.compile(
    r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
    r'|\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,}'
    r'|sk-[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16})\b'
)
PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
PIXEL_CHUNKS = {b'IHDR', b'PLTE', b'IDAT', b'IEND', b'tRNS', b'gAMA', b'cHRM', b'sRGB', b'iCCP', b'pHYs', b'sBIT'}


def allowed(name: str) -> bool:
    p = Path(name)
    if not p.parts or p.is_absolute() or '..' in p.parts:
        return False
    if p.parts[0] not in ROOT_DIRS and name not in ROOT_FILES:
        return False
    if any(part.lower() in DENIED_PARTS for part in p.parts):
        return False
    if p.suffix.lower() in DENIED_EXTENSIONS or '.private.' in p.name:
        return False
    if p.name.startswith('.env') or p.name in {'.git-credentials', '.netrc', '.npmrc', '.pypirc', 'export_credentials.cfg', 'export.cfg'}:
        return False
    if p.name in {'.gitignore', '.gitattributes', '.editorconfig'} or name in ROOT_FILES:
        return True
    if p.suffix.lower() in TEXT_EXTENSIONS:
        return True
    if p.suffix.lower() == '.png':
        return p.parts[:2] in {('game', 'assets'), ('docs', 'reference')}
    if p.suffix.lower() == '.ttf':
        return p.parts[:3] == ('game', 'assets', 'fonts')
    return False


def candidates(root: Path) -> list[str]:
    data = subprocess.check_output(
        ['git', '-C', str(root), 'ls-files', '--cached', '--others', '--exclude-standard', '-z']
    )
    return sorted(set(x for x in data.decode('utf-8').split('\0') if x))


def sanitize_text(text: str) -> str:
    text = WINDOWS_WORKSPACE.sub('.', text)
    text = WINDOWS_HOME.sub('<LOCAL_HOME>', text)
    return UNIX_HOME.sub('<LOCAL_HOME>/', text)


def sanitize_json(value):
    if isinstance(value, str):
        return sanitize_text(value)
    if isinstance(value, list):
        return [sanitize_json(x) for x in value]
    if isinstance(value, dict):
        return {k: sanitize_json(v) for k, v in value.items()}
    return value


def png_chunks(data: bytes):
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError('Invalid PNG signature')
    pos = len(PNG_SIGNATURE)
    while pos < len(data):
        if pos + 12 > len(data):
            raise ValueError('Truncated PNG')
        size = struct.unpack('>I', data[pos:pos + 4])[0]
        end = pos + size + 12
        if end > len(data):
            raise ValueError('Truncated PNG chunk')
        yield data[pos + 4:pos + 8], data[pos:end]
        pos = end


def strip_png_metadata(data: bytes) -> tuple[bytes, list[str]]:
    chunks = list(png_chunks(data))
    output = PNG_SIGNATURE + b''.join(raw for kind, raw in chunks if kind in PIXEL_CHUNKS)
    # Compressed pixels and image structure are copied byte-for-byte.
    before = [(kind, raw) for kind, raw in chunks if kind in PIXEL_CHUNKS]
    if before != list(png_chunks(output)):
        raise ValueError('PNG pixel chunks changed')
    return output, [kind.decode('ascii') for kind, _ in chunks if kind not in PIXEL_CHUNKS]


def audit_text(name: str, text: str) -> list[dict]:
    findings = []
    for rule, pattern in [('local-home', WINDOWS_HOME), ('unix-home', UNIX_HOME), ('credential', SECRET), ('email', EMAIL), ('ip-address', IPV4), ('ip-address', IPV6), ('mac-address', MAC)]:
        for match in pattern.finditer(text):
            value = match.group()
            if rule == 'email' and value.endswith('@users.noreply.github.com'):
                continue
            if rule == 'ip-address':
                try:
                    address = ipaddress.ip_address(value)
                except ValueError:
                    continue
                if address.is_loopback or address.is_unspecified:
                    continue
            findings.append({'file': name, 'line': text.count('\n', 0, match.start()) + 1, 'rule': rule})
    # No matched values are written into a report or public log.
    return findings


def audit_tree(root: Path) -> dict:
    findings = []
    count = 0
    paths = [root / name for name in candidates(root)] if (root / '.git').exists() else sorted(root.rglob('*'))
    for path in paths:
        name = path.relative_to(root).as_posix()
        if any(part in {'.git', '__pycache__', '.pytest_cache'} for part in path.relative_to(root).parts):
            continue
        if path.is_symlink():
            findings.append({'file': name, 'rule': 'symlink'})
            continue
        if not path.is_file():
            continue
        count += 1
        if not allowed(name) and name != '.machidoku-publication.json':
            findings.append({'file': name, 'rule': 'unexpected-file'})
        data = path.read_bytes()
        if path.suffix.lower() == '.png':
            _, metadata = strip_png_metadata(data)
            if metadata:
                findings.append({'file': name, 'rule': 'image-metadata'})
        elif path.suffix.lower() in TEXT_EXTENSIONS or name in ROOT_FILES:
            text = data.decode('utf-8-sig')
            findings.extend(audit_text(name, text))
            if path.suffix.lower() == '.json':
                findings.extend(audit_text(name, json.dumps(json.loads(text), ensure_ascii=False)))
    return {'files': count, 'findings': findings, 'passed': not findings}


def prepare(root: Path, destination: Path) -> dict:
    root, destination = root.resolve(), destination.resolve()
    if not destination.is_relative_to(root / 'artifacts'):
        raise ValueError('Snapshot must be under the ignored artifacts directory')
    if destination.exists():
        raise ValueError('Snapshot destination must be new')
    destination.mkdir(parents=True)
    report = {'excluded': [], 'sanitized_text': [], 'stripped_png': [], 'source_hashes': {}}
    for name in candidates(root):
        source = root / name
        if not source.is_file():
            continue
        if not allowed(name):
            report['excluded'].append(name)
            continue
        if source.is_symlink() or not source.resolve().is_relative_to(root):
            raise ValueError('External file or symlink: ' + name)
        original = source.read_bytes()
        report['source_hashes'][name] = hashlib.sha256(original).hexdigest()
        data = original
        if source.suffix.lower() == '.png':
            data, removed = strip_png_metadata(data)
            if removed:
                report['stripped_png'].append({'file': name, 'chunks': removed, 'pixels_unchanged': True})
        elif source.suffix.lower() in TEXT_EXTENSIONS or name in ROOT_FILES:
            text = data.decode('utf-8-sig')
            if source.suffix.lower() == '.json':
                parsed = sanitize_json(json.loads(text))
                if name == 'docs/asset_generation.json':
                    for item in parsed.get('assets', []):
                        item['source'] = 'Local AI image generation; original machine path withheld.'
                cleaned = json.dumps(parsed, ensure_ascii=False, indent=2) + '\n'
                # Keep authored JSON formatting unless privacy actually changed a value.
                text = cleaned if parsed != json.loads(text) else text
            else:
                text = sanitize_text(text)
            data = text.encode('utf-8')
            if data != original:
                report['sanitized_text'].append(name)
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    manifest = destination / 'docs/asset_generation.json'
    if manifest.exists():
        value = json.loads(manifest.read_text(encoding='utf-8'))
        for item in value.get('assets', []):
            asset = destination / item['file']
            if not asset.resolve().is_relative_to(destination):
                raise ValueError('External asset in manifest')
            item['sha256'] = hashlib.sha256(asset.read_bytes()).hexdigest()
        manifest.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (destination / '.machidoku-publication.json').write_text(
        json.dumps({'format': 1, 'source': 'Sanitized project snapshot', 'original_history_included': False}, indent=2) + '\n', encoding='utf-8'
    )
    report['audit'] = audit_tree(destination)
    if not report['audit']['passed']:
        raise ValueError('Privacy audit blocked publication: ' + json.dumps(report['audit']['findings']))
    return report
