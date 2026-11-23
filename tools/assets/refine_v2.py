"""Reproducible vector polish for the normative desktop v2 target."""
from pathlib import Path
import math
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'game/assets'
NAVY = '#07365A'
GRAD = '<defs><linearGradient id="ink" x1="0" y1="0" x2="0.7" y2="1"><stop stop-color="#2F86A7"/><stop offset="1" stop-color="#052B50"/></linearGradient><linearGradient id="warm" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#FFC538"/><stop offset="1" stop-color="#FF681A"/></linearGradient><linearGradient id="light" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#FFFEF0"/><stop offset="1" stop-color="#EDD2AE"/></linearGradient></defs>'


def write(name, body):
    (ASSETS / name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">{GRAD}{body}</svg>\n', encoding='utf-8')


def dimensional(body):
    return f'<g transform="translate(0 2)" fill="{NAVY}" stroke="{NAVY}" stroke-width="4" opacity="0.22" stroke-linecap="round" stroke-linejoin="round">{body}</g><g fill="url(#ink)" stroke="{NAVY}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">{body}</g>'


icons = {
    'stamping': '<path d="M9 36c0-15 9-25 23-25s23 10 23 25v5H9Z"/><path d="M29 8h6v28h-6Z" fill="#8CD7F0"/><rect x="7" y="37" width="50" height="8" rx="3"/><path d="M13 46h38v10H13Z"/><circle cx="32" cy="48" r="3" fill="#FFF6D9"/>',
    'welding': '<path d="M15 8h34l3 36-12 12H24L12 44Z"/><rect x="21" y="18" width="22" height="13" rx="3" fill="#FFE17A"/><path d="M23 39h18m-15 7h12" fill="none" stroke="#72BDDC" stroke-width="3"/>',
    'painting': '<path d="M22 19h25v18H22Z"/><rect x="27" y="9" width="15" height="10" rx="3"/><path d="M24 37h13v9H27l3 11H18l-3-19Z"/><path d="M47 23h8v10h-8M11 24H5m7 8H5" fill="none" stroke-width="4"/><circle cx="31" cy="27" r="3" fill="#F0B6FF"/>',
    'electrical': '<path d="M38 6 14 36h16l-5 22 25-32H33Z" fill="#7CE2AA"/>',
    'assembly': '<path d="M21 7a16 16 0 0 0 17 20l18 19-10 10-18-19A16 16 0 0 1 8 20l12 8 8-8Z"/><path d="m34 34 14 15" stroke="#7DC5E9" fill="none"/>',
    'inspection': '<circle cx="27" cy="25" r="17" fill="#FAAE46"/><circle cx="27" cy="25" r="12" fill="#A6DCF1"/><path d="m40 39 15 16" fill="none" stroke-width="8"/><path d="M18 20q3-7 11-6" fill="none" stroke="#FFFDF1" stroke-width="3"/>',
    'logistics': '<path d="M11 38h23V24h9v22H11Z" fill="#D486CC"/><path d="M31 24V10H18v17m26-6h6v28h9" fill="none" stroke-width="5"/><circle cx="15" cy="48" r="8"/><circle cx="38" cy="48" r="8"/><circle cx="15" cy="48" r="3" fill="#A5D4E6"/><circle cx="38" cy="48" r="3" fill="#A5D4E6"/>',
    'testing': '<path d="M10 48a25 25 0 1 1 44 0Z"/><path d="m32 33 13-15" fill="none" stroke="#FFE27B" stroke-width="5"/><circle cx="32" cy="33" r="6" fill="#FFB32D"/>',
    'powertrain': '<path d="M17 18h26v8h10v21H17v-7H8V26h9Z"/><path d="M23 10h14M30 10v8m-6 17h16" stroke="#97DCE8" stroke-width="4" fill="none"/>',
}
for key, body in icons.items():
    write('sectors/' + key + '.svg', dimensional(body))
write('rules/one_per_sector.svg', dimensional('<path d="M12 8h20v23h20v24H12Z" fill="#6CD7E9"/><circle cx="25" cy="42" r="6"/>'))
write('rules/one_per_row_column.svg', dimensional('<path d="M21 7v50M43 7v50M7 21h50M7 43h50" fill="none" stroke-width="5"/><circle cx="43" cy="21" r="5" fill="#FFCF50"/>'))
write('rules/no_touching.svg', '<rect x="7" y="7" width="50" height="50" rx="10" fill="#FFF6DB" stroke="#EE6431" stroke-width="3" stroke-dasharray="3 4"/><circle cx="32" cy="33" r="11" fill="#092A43"/><circle cx="29" cy="28" r="5" fill="#4191AB"/>')
write('ui/icon_factory.svg', dimensional('<path d="M7 54V24l13 9V19l13 11V10h12l12 44Z"/><path d="M38 10V5h8v5" fill="#FF8535"/><path d="M17 42v3m13-5v5m14-10v10" stroke="#72CAE6" stroke-width="4"/>'))
write('ui/icon_difficulty.svg', '<rect x="5" y="6" width="54" height="54" rx="14" fill="#64461D"/><rect x="15" y="31" width="8" height="19" rx="3" fill="url(#warm)"/><rect x="28" y="22" width="8" height="28" rx="3" fill="url(#warm)"/><rect x="41" y="13" width="8" height="37" rx="3" fill="url(#warm)"/><path d="M18 32v12m13-21v20m13-28v28" stroke="#FFF5BC" stroke-width="2" stroke-linecap="round"/>')

points = []
for i in range(40):
    angle = i * math.tau / 40 - math.pi / 2
    radius = 28 if i % 5 in [1, 2, 3] else 22
    points.append((32 + math.cos(angle) * radius, 31 + math.sin(angle) * radius))
path = 'M' + ' '.join(f'{x:.2f},{y:.2f}' for x,y in points) + 'Z'
write('ui/icon_life.svg', f'<path d="{path}" transform="translate(0 2)" fill="#8D4E24" opacity="0.24"/><path d="{path}" fill="url(#warm)" stroke="#C96920" stroke-width="1.4" stroke-linejoin="round"/><path d="{path}" transform="translate(4.8 4.6) scale(.85)" fill="none" stroke="#FFE8AD" stroke-width="1.5"/><circle cx="32" cy="31" r="13" fill="url(#light)" stroke="#9B5419" stroke-width="2"/><circle cx="32" cy="31" r="8.5" fill="url(#warm)"/><path d="M26 27q4-5 9-3" stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linecap="round"/>')
write('ui/icon_life_empty.svg', f'<path d="{path}" fill="#E9D7C5" stroke="#A59C90" stroke-width="2" stroke-linejoin="round"/><circle cx="32" cy="31" r="12" fill="url(#light)" stroke="#B7AEA1" stroke-width="2"/>')
write('ui/icon_settings.svg', f'<path d="{path}" transform="translate(0 2)" fill="#933917"/><path d="{path}" fill="url(#light)" stroke="#8C3B1B" stroke-width="2.8" stroke-linejoin="round"/><circle cx="32" cy="31" r="9" fill="#B1471E" stroke="#FFD593" stroke-width="2"/>')
write('ui/icon_restart_action.svg', '<path d="M22 15a22 22 0 1 1-11 19" fill="none" stroke="#983610" stroke-width="9" stroke-linecap="round"/><path d="M22 13a22 22 0 1 1-11 19" fill="none" stroke="#FFF8E6" stroke-width="6" stroke-linecap="round"/><path d="m23 4-12 11 15 6Z" fill="#FFF8E6" stroke="#983610" stroke-width="2" stroke-linejoin="round"/>')
write('branding/machidoku_symbol.svg', f'<path d="{path}" transform="translate(0 2)" fill="#041C2B" opacity="0.35"/><path d="{path}" fill="url(#ink)" stroke="#05243A" stroke-width="1.5"/><path d="{path}" transform="translate(3.8 3.5) scale(.88)" fill="none" stroke="#A2D8E0" stroke-width="0.8"/><path d="M44 6 55 14 44 26 34 18Z" fill="url(#warm)" stroke="#CF5B17" stroke-width="1"/><circle cx="32" cy="31" r="17" fill="url(#light)" stroke="#082D45" stroke-width="1.5"/><circle cx="32" cy="31" r="12" fill="url(#warm)"/><circle cx="32" cy="31" r="7" fill="#FF6B18"/><path d="M25 26q3-5 9-3" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"/>')

for old,new in {'ui/rule_region.svg':'rules/one_per_sector.svg','ui/rule_axes.svg':'rules/one_per_row_column.svg','ui/rule_distance.svg':'rules/no_touching.svg','sectors/electric.svg':'sectors/electrical.svg','ui/factory.svg':'ui/icon_factory.svg','ui/app_icon.svg':'branding/machidoku_symbol.svg'}.items():
    (ASSETS / old).write_bytes((ASSETS / new).read_bytes())

inventory = []
for file in sorted(ASSETS.rglob('*.svg')):
    source = file.read_text(encoding='utf-8')
    inventory.append({'file':file.relative_to(ASSETS).as_posix(), 'viewBox':ET.fromstring(source).attrib['viewBox'], 'colors':sorted(set(re.findall(r'#[A-Fa-f0-9]{6}\b',source)))})
(ROOT / 'docs/svg_inventory.json').write_text(json.dumps({'version':2,'assets':inventory},indent=2)+'\n',encoding='utf-8')
print('V2 vector family:',len(inventory),'SVGs')
