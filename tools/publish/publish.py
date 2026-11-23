"""One-command, audited publication. Credentials never enter the payload."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from privacy import audit_text, audit_tree, prepare

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / 'artifacts/security-tools'
AUDIT = ROOT / 'artifacts/security-audit'
DOWNLOADS = {
    ('gitleaks', 'Windows'): ('gitleaks/gitleaks', 'v8.30.1', 'gitleaks_8.30.1_windows_x64.zip', 'd29144deff3a68aa93ced33dddf84b7fdc26070add4aa0f4513094c8332afc4e'),
    ('gitleaks', 'Linux'): ('gitleaks/gitleaks', 'v8.30.1', 'gitleaks_8.30.1_linux_x64.tar.gz', '551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb'),
    ('gh', 'Windows'): ('cli/cli', 'v2.105.0', 'gh_2.105.0_windows_amd64.zip', '8813a72c899900afaa10e3fec8fbc64b908c89dbfe837e95ed2fa500fc140627'),
}


def run(args, cwd=ROOT, *, check=True, input=None):
    env = os.environ.copy()
    env['GIT_TERMINAL_PROMPT'] = '0'
    env['GCM_INTERACTIVE'] = 'Never'
    result = subprocess.run([str(a) for a in args], cwd=cwd, env=env, input=input,
                            capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180)
    if check and result.returncode:
        # Avoid leaking arbitrary command output, paths or credentials into CI logs.
        raise RuntimeError('Command failed: ' + str(args[0]).replace(str(TOOLS), '<tools>') + ' ' + str(args[1]) + ' (exit ' + str(result.returncode) + ')')
    return result


def ensure_tool(name: str) -> Path:
    system = platform.system()
    if platform.machine().lower() not in {'amd64', 'x86_64'}:
        raise RuntimeError('Pinned tools currently require an x64 machine')
    exe = name + ('.exe' if system == 'Windows' else '')
    destination = TOOLS / exe
    receipt = TOOLS / (exe + '.verified.json')
    TOOLS.mkdir(parents=True, exist_ok=True)
    if destination.exists() and receipt.exists():
        recorded = json.loads(receipt.read_text(encoding='utf-8'))
        if hashlib.sha256(destination.read_bytes()).hexdigest() == recorded['binary_sha256']:
            return destination
    try:
        repo, version, archive, expected = DOWNLOADS[name, system]
    except KeyError as exc:
        raise RuntimeError('Unsupported tool/platform combination') from exc
    url = f'https://github.com/{repo}/releases/download/{version}/{archive}'
    request = urllib.request.Request(url, headers={'User-Agent': 'Machidoku-publication'})
    with urllib.request.urlopen(request, timeout=90) as response:
        content = response.read()
    if hashlib.sha256(content).hexdigest() != expected:
        raise RuntimeError('Tool checksum mismatch: ' + name)
    if archive.endswith('.zip'):
        with zipfile.ZipFile(io.BytesIO(content)) as bundle:
            member = next(n for n in bundle.namelist() if n.rsplit('/', 1)[-1] == exe)
            binary = bundle.read(member)
    else:
        with tarfile.open(fileobj=io.BytesIO(content), mode='r:gz') as bundle:
            member = next(n for n in bundle.getmembers() if Path(n.name).name == exe and n.isfile())
            binary = bundle.extractfile(member).read()
    destination.write_bytes(binary)
    if system != 'Windows':
        destination.chmod(0o755)
    receipt.write_text(json.dumps({'version': version, 'archive_sha256': expected, 'binary_sha256': hashlib.sha256(binary).hexdigest()}, indent=2), encoding='utf-8')
    return destination


def leak_scan(scanner: Path, directory: Path, label: str, history=False):
    AUDIT.mkdir(parents=True, exist_ok=True)
    report = AUDIT / (label + '.private.json')
    result = run([scanner, 'git' if history else 'dir', str(directory), '--redact', '--no-banner',
                  '--report-format', 'json', '--report-path', str(report), '--log-level', 'error'], check=False)
    if result.returncode:
        raise RuntimeError('Secret scanner blocked publication; inspect the local redacted report: ' + report.name)


def audit_commit_metadata(directory: Path):
    result = run(['git', 'log', '--all', '--format=%ae%n%ce%n%B'], cwd=directory)
    findings = audit_text('commit-metadata', result.stdout)
    if findings:
        raise RuntimeError('Commit metadata contains an email, path, address or credential that requires review')


def validate_payload(directory: Path, scanner: Path, label: str):
    report = audit_tree(directory)
    if not report['passed']:
        raise RuntimeError('Privacy audit failed: ' + json.dumps(report['findings']))
    leak_scan(scanner, directory, label)
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--repository', default='vinicinotti/Machidoku')
    parser.add_argument('--message', default='Atualiza Machidoku')
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--audit-only', action='store_true')
    args = parser.parse_args()
    AUDIT.mkdir(parents=True, exist_ok=True)
    scanner = ensure_tool('gitleaks')
    if args.audit_only:
        report = validate_payload(ROOT, scanner, 'ci-payload')
        if (ROOT / '.git').exists():
            audit_commit_metadata(ROOT)
            leak_scan(scanner, ROOT, 'ci-history', history=True)
        print('Privacy and secret checks passed for', report['files'], 'files.')
        return
    if not re.fullmatch(r'[A-Za-z0-9-]+/[A-Za-z0-9_.-]+', args.repository):
        raise RuntimeError('Invalid repository name')
    if audit_text('commit-message', args.message):
        raise RuntimeError('Commit message contains data that requires review')
    msg_scan = run([scanner, 'stdin', '--redact', '--no-banner', '--log-level', 'error'], input=args.message, check=False)
    if msg_scan.returncode:
        raise RuntimeError('Secret scanner blocked the commit message')
    snapshot = Path(tempfile.mkdtemp(prefix='public-snapshot-', dir=ROOT / 'artifacts'))
    snapshot.rmdir()  # prepare() requires a new, controlled destination.
    report = prepare(ROOT, snapshot)
    report['payload'] = validate_payload(snapshot, scanner, 'prepared-payload')
    # Run the existing Python suite against the actual sanitized delivery.
    tests = run([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests', '-v'], cwd=snapshot, check=False)
    (AUDIT / 'payload-tests.private.log').write_text(tests.stdout + tests.stderr, encoding='utf-8')
    if tests.returncode:
        raise RuntimeError('Existing project tests failed on the sanitized copy; publication stopped')
    report['python_tests_passed'] = True
    report['snapshot_relative_path'] = snapshot.relative_to(ROOT).as_posix()
    report_path = AUDIT / 'publication.private.json'
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print('Sanitized payload ready:', report['payload']['files'], 'files; existing Python suite passed.')
    if args.prepare_only:
        print('No GitHub changes. Local report: artifacts/security-audit/publication.private.json')
        return
    gh = ensure_tool('gh')
    if run([gh, 'auth', 'status', '--hostname', 'github.com'], check=False).returncode:
        raise RuntimeError('Authenticate with artifacts/security-tools/gh.exe auth login --web --git-protocol https --scopes project')
    account = json.loads(run([gh, 'api', 'user']).stdout)
    owner, repository = args.repository.split('/')
    if account['login'].lower() != owner.lower():
        raise RuntimeError('Authenticated GitHub account does not match the repository owner')
    noreply = f"{account['id']}+{account['login']}@users.noreply.github.com"
    status = run([gh, 'api', f'repos/{args.repository}'], check=False)
    if status.returncode:
        if '404' not in status.stderr:
            raise RuntimeError('Could not verify destination repository')
        run([gh, 'repo', 'create', args.repository, '--public', '--description', 'Machidoku: puzzle industrial em Godot.'])
        remote_exists = False
    else:
        remote = json.loads(status.stdout)
        if remote['private']:
            raise RuntimeError('Existing repository is private; its visibility will not be changed')
        marker = run([gh, 'api', f'repos/{args.repository}/contents/.machidoku-publication.json'], check=False)
        if marker.returncode:
            raise RuntimeError('Existing repository is not an audited Machidoku publication; refusing to overwrite')
        remote_exists = True
    protection = run([gh, 'api', '--method', 'PATCH', f'repos/{args.repository}', '--input', '-'],
                     input=json.dumps({'security_and_analysis': {'secret_scanning': {'status': 'enabled'},
                                       'secret_scanning_push_protection': {'status': 'enabled'}}}), check=False)
    checkout = ROOT / '.publish' / repository
    if checkout.parent.is_symlink() or checkout.parent.resolve().parent != ROOT:
        raise RuntimeError('Publication directory must stay inside the workspace')
    checkout.parent.mkdir(parents=True, exist_ok=True)
    origin = f'https://github.com/{args.repository}.git'
    if not checkout.exists():
        if remote_exists:
            run(['git', 'clone', '--branch', 'main', origin, str(checkout)])
        else:
            checkout.mkdir()
            run(['git', 'init', '-b', 'main'], cwd=checkout)
            run(['git', 'remote', 'add', 'origin', origin], cwd=checkout)
    if checkout.is_symlink() or not checkout.resolve().is_relative_to((ROOT / '.publish').resolve()):
        raise RuntimeError('Invalid publication checkout')
    if run(['git', 'remote', 'get-url', 'origin'], cwd=checkout).stdout.strip() != origin:
        raise RuntimeError('Unexpected publication remote')
    if run(['git', 'status', '--porcelain'], cwd=checkout).stdout.strip():
        raise RuntimeError('Publication checkout has pending changes; inspect it before retrying')
    if remote_exists:
        run(['git', 'pull', '--ff-only', 'origin', 'main'], cwd=checkout)
        audit_commit_metadata(checkout)
        leak_scan(scanner, checkout, 'existing-public-history', history=True)
    run(['git', 'config', 'user.name', account['login']], cwd=checkout)
    run(['git', 'config', 'user.email', noreply], cwd=checkout)
    run(['git', 'config', 'commit.gpgsign', 'false'], cwd=checkout)
    run(['git', 'config', 'credential.https://github.com.helper', '!"' + gh.as_posix() + '" auth git-credential'], cwd=checkout)
    current = run(['git', 'ls-files', '-z'], cwd=checkout).stdout.split('\0')
    source_files = {p.relative_to(snapshot).as_posix(): p for p in snapshot.rglob('*')
                    if p.is_file() and '__pycache__' not in p.parts}
    for name in current:
        if name and name not in source_files:
            path = checkout / name
            if not path.resolve().is_relative_to(checkout.resolve()) or path.is_symlink():
                raise RuntimeError('Unsafe path in publication checkout')
            path.unlink(missing_ok=True)
    for name, source in source_files.items():
        target = checkout / name
        if target.is_symlink() or not target.resolve().is_relative_to(checkout.resolve()):
            raise RuntimeError('Unsafe target path')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    validate_payload(checkout, scanner, 'final-checkout')
    run(['git', 'add', '--all'], cwd=checkout)
    dirty = run(['git', 'diff', '--cached', '--quiet'], cwd=checkout, check=False)
    if dirty.returncode not in {0, 1}:
        raise RuntimeError('Could not inspect staged publication')
    if dirty.returncode:
        run(['git', 'commit', '-m', args.message], cwd=checkout)
    audit_commit_metadata(checkout)
    leak_scan(scanner, checkout, 'final-public-history', history=True)
    # A single explicit branch, no force, tags, mirror or original local history.
    run(['git', 'push', '--set-upstream', 'origin', 'main'], cwd=checkout)
    linked = run([gh, 'project', 'link', '1', '--owner', owner, '--repo', args.repository], check=False)
    revision = run(['git', 'rev-parse', 'HEAD'], cwd=checkout).stdout.strip()
    report.update({'repository': args.repository, 'commit': revision, 'public': True,
                   'project_linked': linked.returncode == 0,
                   'secret_protection_configured': protection.returncode == 0,
                   'published_at': datetime.now(timezone.utc).isoformat()})
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print('Published: https://github.com/' + args.repository)
    print('Commit:', revision)
    print('Projects link:', 'confirmed' if linked.returncode == 0 else 'requires attention')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError, OSError, subprocess.SubprocessError) as exc:
        print('PUBLICATION STOPPED:', exc, file=sys.stderr)
        raise SystemExit(1)
