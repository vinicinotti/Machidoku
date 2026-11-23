"""Original, Godot-compatible vector family. No raster or external resources."""
from pathlib import Path
import re
import json

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'game/assets'
ITEMS = []
BLUE, DARK, ORANGE, CORAL, CREAM = '#264653', '#1B252D', '#F4A261', '#E76F51', '#FFE6CF'


def asset(name, view, body, role, reference):
    path = BASE / name
    path.parent.mkdir(parents=True, exist_ok=True)
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}">\n{body.strip()}\n</svg>\n'
    path.write_text(svg, encoding='utf-8')
    ITEMS.append((name, view, role, reference, ', '.join(sorted(set(re.findall(r'#[A-Fa-f0-9]{6}\b', svg))))))


def gradient(identifier, a, b, x2='0', y2='1'):
    return f'<linearGradient id="{identifier}" x1="0" y1="0" x2="{x2}" y2="{y2}"><stop stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>'


teeth = ''.join(f'<rect x="27" y="3" width="10" height="15" rx="3" transform="rotate({angle} 32 32)"/>' for angle in range(0,360,45))
gear_shape = teeth + '<circle cx="32" cy="32" r="22"/>'
gear = f'''<g fill="{DARK}" opacity=".12" transform="translate(0 2)">{gear_shape}</g>
<g fill="{BLUE}">{gear_shape}</g><circle cx="32" cy="32" r="15" fill="{CREAM}"/>
<rect x="27" y="3" width="10" height="15" rx="3" fill="{CORAL}" transform="rotate(45 32 32)"/>
<circle cx="32" cy="32" r="11.5" fill="{ORANGE}"/>
<path d="M24 29a9 9 0 0 1 13-5" fill="none" stroke="#FFF9F2" stroke-width="2.5" stroke-linecap="round" opacity=".7"/>
<circle cx="32" cy="33" r="4.7" fill="{CORAL}"/>'''
asset('branding/machidoku_symbol.svg','0 0 64 64',gear,'Símbolo industrial de oito dentes; usado com Label Roboto Bold.','32–72 px')
asset('branding/machidoku_logo.svg','0 0 128 96',f'''<rect x="18" y="16" width="92" height="68" rx="18" fill="{DARK}" opacity=".06"/>
<rect x="18" y="12" width="92" height="68" rx="18" fill="#FFF9F2"/>
<path d="M25 33h13M25 45h13M90 50h13M90 62h13" stroke="{ORANGE}" stroke-width="3" stroke-linecap="round" opacity=".55"/>
<g transform="translate(32 14)">{gear}</g>''','Emblema de marca sem lettering; wordmark composto nativamente ao lado.','96–160 px')

asset('specialists/specialist_default.svg','0 0 256 256',f'''
<defs>{gradient('helmet-surface','#FFC58A',ORANGE)}{gradient('uniform-surface','#365E6D',BLUE)}{gradient('face-surface','#F5CCAA','#E3AF89')}</defs>
<ellipse cx="128" cy="242" rx="87" ry="9" fill="{BLUE}" opacity=".10"/>
<path d="M42 237v-31c0-35 35-57 86-57s86 22 86 57v31Z" fill="{DARK}" opacity=".13" transform="translate(0 5)"/>
<path d="M42 236v-31c0-35 35-57 86-57s86 22 86 57v31Z" fill="url(#uniform-surface)" stroke="{BLUE}" stroke-width="3.5" stroke-linejoin="round"/>
<path d="m83 162 45 31 45-31 16 74H67Z" fill="{ORANGE}"/>
<path d="m83 162 14 10-9 64H76Zm90 0-14 10 9 64h12Z" fill="{CREAM}"/>
<path d="m80 206-4 12h104l-3-12Z" fill="#FFEEDC" opacity=".8"/>
<path d="M109 142h38v33l-19 18-19-18Z" fill="#D6A17B"/>
<path d="m109 171 19 22-16 12-16-32m51-2-19 22 16 12 16-32" fill="{BLUE}"/>
<path d="M128 195v41" stroke="{BLUE}" stroke-width="3.5"/>
<rect x="146" y="211" width="23" height="16" rx="4" fill="{BLUE}"/>
<path d="M151 215h12" stroke="{CREAM}" stroke-width="2" stroke-linecap="round" opacity=".8"/>
<ellipse cx="77" cy="118" rx="11" ry="16" fill="#E3AF89"/><ellipse cx="179" cy="118" rx="11" ry="16" fill="#E3AF89"/>
<path d="M78 87h100v41c0 30-21 52-50 52s-50-22-50-52Z" fill="url(#face-surface)" stroke="{BLUE}" stroke-width="3.5"/>
<path d="M81 99h94v12H81Z" fill="#B67C58" opacity=".17"/>
<path d="M98 125h9m42 0h9" stroke="{BLUE}" stroke-width="4.5" stroke-linecap="round"/>
<path d="m128 128-4 11h7" fill="none" stroke="#C18B68" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M115 151q13 8 26 0" fill="none" stroke="#A96C55" stroke-width="3.5" stroke-linecap="round"/>
<path d="M61 89c0-42 27-70 67-70s67 28 67 70v12H61Z" fill="#C57C42" transform="translate(0 4)"/>
<path d="M61 89c0-42 27-70 67-70s67 28 67 70v12H61Z" fill="url(#helmet-surface)" stroke="{BLUE}" stroke-width="3.5"/>
<path d="M78 71c6-20 17-31 34-36" fill="none" stroke="{CREAM}" stroke-width="7" opacity=".65" stroke-linecap="round"/>
<rect x="118" y="15" width="20" height="71" rx="8" fill="#FFD6A9" stroke="{ORANGE}" stroke-width="2"/>
<path d="M58 91h140a8 8 0 0 1 0 16H58a8 8 0 0 1 0-16Z" fill="{BLUE}"/>
<path d="M64 93h127" stroke="#FFF9F2" stroke-width="2" opacity=".25" stroke-linecap="round"/>
''','Busto industrial com capacete, colete e relevo vetorial discreto.','32–160 px')

def car(name, kind, role):
    roofs = {
        'hatch': ('M58 142 82 96Q88 79 108 76L264 71Q280 71 291 84L337 127 423 139 423 194 403 196C400 150 337 148 333 195L164 192C160 146 97 145 94 190L58 182Z',
                  'M108 88 92 124 177 125 177 86Z M190 85 262 84Q270 84 278 93L314 129 190 126Z'),
        'sedan': ('M50 147 98 130 151 84Q162 73 181 73H282Q295 73 307 86L350 132 431 145 431 195 403 197C399 151 337 149 333 196L164 193C160 147 97 146 94 191L50 184Z',
                  'M174 86 124 127 211 128 211 86Z M224 86H279Q286 86 294 94L329 131 224 129Z'),
        'sport': ('M47 153 109 134 174 96Q186 89 206 89H280Q294 89 307 101L342 131 432 144 432 194 403 197C399 151 337 149 333 196L164 193C160 147 97 146 94 191L47 184Z',
                  'M195 101 145 129 223 129 223 101Z M235 101H278Q285 101 295 109L319 131 235 130Z')}
    body,windows=roofs[kind]
    asset('vehicles/'+name,'0 0 512 256',f'''
<defs>{gradient('body-surface','#FFBD7C',ORANGE)}{gradient('body-front',ORANGE,'#DE8B4A')}{gradient('glass-surface','#436F7E',BLUE)}</defs>
<ellipse cx="257" cy="222" rx="210" ry="12" fill="{BLUE}" opacity=".10"/>
<g fill="{DARK}" stroke="{BLUE}" stroke-width="3"><ellipse cx="130" cy="190" rx="34" ry="36"/><ellipse cx="369" cy="195" rx="34" ry="36"/></g>
<g fill="{CREAM}"><ellipse cx="130" cy="190" rx="17" ry="19"/><ellipse cx="369" cy="195" rx="17" ry="19"/></g>
<g fill="{BLUE}"><ellipse cx="130" cy="190" rx="7" ry="8"/><ellipse cx="369" cy="195" rx="7" ry="8"/></g>
<path d="{body}" fill="url(#body-surface)" stroke="{BLUE}" stroke-width="3.5" stroke-linejoin="round"/>
<path d="M423 139 469 157Q475 160 474 169L470 193 423 194Z" fill="url(#body-front)" stroke="{BLUE}" stroke-width="3.5" stroke-linejoin="round"/>
<path d="M337 127 382 115 455 139 469 157 423 139Z" fill="#FFC88D" stroke="{BLUE}" stroke-width="3" stroke-linejoin="round"/>
<path d="{windows}" fill="url(#glass-surface)" stroke="{BLUE}" stroke-width="2.5" stroke-linejoin="round"/>
<path d="m202 91 29 28" stroke="#D5E7E2" stroke-width="5" opacity=".23" stroke-linecap="round"/>
<path d="M192 141 188 178M170 181l160 3" stroke="#D48A4C" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<path d="m204 143 19 1" stroke="{BLUE}" stroke-width="3.5" stroke-linecap="round"/>
<path d="m70 143 16-4-1 15-17 1Z" fill="{CORAL}"/>
<path d="m431 151 31 11-2 9-29-8Z" fill="#FFF5DE" stroke="{BLUE}" stroke-width="2" stroke-linejoin="round"/>
<path d="m437 179 26 2-1 6-25-2Z" fill="{BLUE}"/>
<path d="m62 173 24 3m322 9 11 1" stroke="{BLUE}" stroke-width="4" stroke-linecap="round"/>
<path d="m88 137 86 3m151-2 91 10" stroke="#FFEAD2" stroke-width="3" opacity=".65" stroke-linecap="round"/>
''',role,'160–430 px; mantém leitura no painel e vitória')

car('hatch_compact.svg','hatch','Hatch fictício, compacto e elevado, em três quartos suave.')
car('sedan.svg','sedan','Sedan fictício preparado; não ativado como produto seguinte.')
car('sport_coupe.svg','sport','Coupé fictício de teto baixo; preparado, sem fase ativa.')

sector_paths = {
 'stamping': '<rect x="11" y="8" width="42" height="12" rx="3"/><path d="M19 20v15h26V20M27 35v10h10V35M12 56v-8h40v8M8 56h48"/>',
 'welding': '<path d="m10 43 20-20 12 12-20 20Z M36 29l10-10M48 7v6M53 21h6M48 31l6 6M36 12l-4-5"/>',
 'painting': '<rect x="10" y="8" width="31" height="16" rx="4"/><path d="M41 16h11v19H30v11M25 46h10v12H25Z"/>',
 'electrical': '<path d="M36 6 13 36h18l-3 22 23-33H34Z"/>',
 'assembly': '<path d="M20 8a16 16 0 0 0 17 20l19 19-9 9-19-19A16 16 0 0 1 8 20l12 9 9-9Z"/>',
 'inspection': '<circle cx="27" cy="27" r="18"/><path d="m40 40 15 15M17 27l7 7 14-15"/>',
 'logistics': '<rect x="7" y="10" width="32" height="36" rx="3"/><path d="M39 25h10l9 13v8H39M8 24h30M23 11v12"/><circle cx="18" cy="49" r="6"/><circle cx="49" cy="49" r="6"/>',
 'testing': '<path d="M11 49a25 25 0 1 1 42 0M32 11v8M13 23l7 4M51 23l-7 4M32 40l12-18"/><circle cx="32" cy="40" r="4"/>',
 'powertrain': '<path d="M10 24h9l7-9h17v9h9v27H19l-9-9ZM5 29v12M31 15V9m-7 0h15M52 30h6v15h-6M29 27l-6 10h10l-5 10"/>'
}
for name,paths in sector_paths.items():
    asset(f'sectors/{name}.svg','0 0 64 64',f'<g fill="none" stroke="{BLUE}" stroke-width="4.1" stroke-linecap="round" stroke-linejoin="round">{paths}</g>',f'Ícone de setor: {name}; mesma família e peso.','20–40 px')

rules = {
 'one_per_sector': f'<path d="M9 9h29v19h17v27H9Z" fill="#BED7CE" stroke="{BLUE}" stroke-width="3" stroke-linejoin="round"/><circle cx="26" cy="36" r="8" fill="{BLUE}"/><path d="M20 30h12" stroke="{ORANGE}" stroke-width="4" stroke-linecap="round"/>',
 'one_per_row_column': f'<path d="M5 21h54M5 43h54M21 5v54M43 5v54" stroke="{BLUE}" stroke-width="4" stroke-linecap="round"/><circle cx="32" cy="32" r="7" fill="{ORANGE}" stroke="{BLUE}" stroke-width="2.5"/>',
 'no_touching': f'<rect x="8" y="8" width="48" height="48" rx="9" fill="#FFF9F2" stroke="{CORAL}" stroke-width="3.5" stroke-dasharray="4 5"/><circle cx="31" cy="33" r="10" fill="{BLUE}"/>'
}
for name,body in rules.items():
    asset(f'rules/{name}.svg','0 0 64 64',body,'Regra resumida; texto fica em Label ao lado.','28–40 px')

ui = {
 'back': '<path d="m35 15-17 17 17 17M18 32h36"/>',
 'restart': '<path d="M17 22a21 21 0 1 1-3 24M17 10v14H4"/>',
 'check': '<path d="m14 33 12 12 25-27"/>',
 'lock': '<rect x="15" y="28" width="34" height="28" rx="7"/><path d="M22 28V19a10 10 0 0 1 20 0v9M32 39v7"/>',
 'factory': '<path d="M7 54V25l17 9V25l17 9V16h11l5 38ZM7 54h50M15 42h3m10 0h3m13 0h3M43 8h7"/>',
 'car': '<path d="m9 34 7-15h27l11 15M8 34h48v17H8ZM16 41h7m18 0h7"/><circle cx="18" cy="51" r="5"/><circle cx="47" cy="51" r="5"/>',
 'dropdown': '<path d="m16 25 16 16 16-16"/>'
}
for name,paths in ui.items():
    asset(f'ui/icon_{name}.svg','0 0 64 64',f'<g fill="none" stroke="{BLUE}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round">{paths}</g>','Ação/indicador de UI: '+name+'.','18–32 px')
asset('ui/icon_life.svg','0 0 64 64',f'<circle cx="32" cy="35" r="22" fill="{CORAL}" opacity=".18"/><circle cx="32" cy="31" r="22" fill="{CORAL}"/><path d="M19 24a15 15 0 0 1 20-6" fill="none" stroke="{CREAM}" stroke-width="4" opacity=".7" stroke-linecap="round"/>','Vida ativa; o HUD desenha os círculos e outlines nativamente.','16–28 px')
asset('ui/icon_error.svg','0 0 64 64',f'<circle cx="32" cy="33" r="25" fill="{CORAL}"/><path d="M32 17v19" stroke="#FFF9F2" stroke-width="5" stroke-linecap="round"/><circle cx="32" cy="46" r="3" fill="#FFF9F2"/>','Erro confirmado; usado no badge do ERROR_X.','12–28 px')

asset('decoration/factory_background_left.svg','0 0 640 300',f'''
<path d="M0 266h625" stroke="#C79872" stroke-width="4" stroke-linecap="round"/>
<path d="M27 260V137l104 43v-43l104 43v-43l104 43v80Z" fill="#D5AB87"/>
<path d="M347 260V53h36l16 207Z" fill="#DEB38C"/>
<path d="M353 35h62m-18-18h51" stroke="#D5AB87" stroke-width="12" stroke-linecap="round"/>
<g fill="{CREAM}"><rect x="50" y="203" width="25" height="28" rx="4"/><rect x="101" y="203" width="25" height="28" rx="4"/><rect x="154" y="203" width="25" height="28" rx="4"/><rect x="207" y="203" width="25" height="28" rx="4"/><rect x="260" y="203" width="25" height="28" rx="4"/></g>
<rect x="421" y="196" width="81" height="64" rx="13" fill="#DCB18B"/><path d="M438 196v-19h46v19" fill="none" stroke="#C79872" stroke-width="5"/>
<circle cx="548" cy="232" r="28" fill="#D5AB87"/><path d="M548 235v26" stroke="#C79872" stroke-width="5"/>
''','Silhueta de fábrica, colocada em baixa opacidade no fundo.','350–750 px; modulate alpha ≤ 0,35')
asset('decoration/factory_background_right.svg','0 0 480 300',f'''
<path d="M8 266h465" stroke="#C79872" stroke-width="4" stroke-linecap="round"/>
<rect x="153" y="119" width="264" height="143" rx="15" fill="#D9AD86"/>
<path d="m140 123 148-70 143 70Z" fill="#D1A37D"/>
<rect x="216" y="176" width="131" height="86" rx="11" fill="#E6BD98"/>
<path d="M228 193h107m-107 18h107m-107 18h107" stroke="{CREAM}" stroke-width="4"/>
<circle cx="72" cy="230" r="31" fill="#D5AB87"/><circle cx="107" cy="240" r="22" fill="#DEB38C"/>
<path d="M72 231v31m35-20v20" stroke="#C79872" stroke-width="5"/>
''','Galpão e formas arbustivas simples para fundo responsivo.','250–600 px; modulate alpha ≤ 0,35')
asset('decoration/industrial_shapes.svg','0 0 320 160',f'<rect x="25" y="28" width="75" height="75" rx="18" fill="{ORANGE}" opacity=".18" transform="rotate(-12 62 65)"/><circle cx="159" cy="72" r="36" fill="{CORAL}" opacity=".11"/><path d="M223 47h61v61h-61Z" fill="none" stroke="{BLUE}" stroke-width="5" opacity=".09" transform="rotate(12 253 77)"/>','Formas discretas para cards de produto e preview.','180–400 px')

aliases = {
 'specialists/specialist.svg':'specialists/specialist_default.svg',
 'vehicles/hatch.svg':'vehicles/hatch_compact.svg','vehicles/sports.svg':'vehicles/sport_coupe.svg',
 'sectors/electric.svg':'sectors/electrical.svg',
 'ui/rule_region.svg':'rules/one_per_sector.svg','ui/rule_axes.svg':'rules/one_per_row_column.svg',
 'ui/rule_distance.svg':'rules/no_touching.svg','ui/app_icon.svg':'branding/machidoku_symbol.svg',
 'ui/factory.svg':'ui/icon_factory.svg'
}
for old,new in aliases.items():
    (BASE/old).write_text((BASE/new).read_text(encoding='utf-8'),encoding='utf-8')

inventory = [dict(file=name, viewBox=view, role=role, reference=reference, colors=colors) for name,view,role,reference,colors in ITEMS]
(ROOT/'docs/svg_inventory.json').write_text(json.dumps(dict(assets=inventory, aliases=aliases), indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
print(f'Built {len(ITEMS)} canonical SVGs and {len(aliases)} compatibility copies. Raster art is managed separately.')
