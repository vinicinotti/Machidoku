# Refinamento visual desktop

Registro histórico anterior à v2. Apresentação e evidências atuais: [VISUAL_VALIDATION.md](VISUAL_VALIDATION.md).

Iteração de 20/10/2026. Referência oficial: [machidoku_visual_target_desktop_v1.png](reference/machidoku_visual_target_desktop_v1.png).

## Alterações

- Board: aro cream, bezel azul industrial e bandeja interna separados, com bordas arredondadas, antialiasing e sombra curta. A geometria das células e o mapeamento de input foram preservados.
- Células: face com gradiente de cor por vértice, base inferior mais escura, highlight discreto e raios proporcionais. Todas continuam desenhadas com primitivas nativas, sem raster por célula.
- Setores: cores pastéis mais definidas; fronteiras finas de 1,25 px em azul industrial com aproximadamente 42% de opacidade. Sem caps adicionais nos encontros, para evitar acúmulo de contraste. A borda externa permanece forte e o grid interno sutil. O algoritmo que emite cada aresta compartilhada uma vez foi preservado. A paleta já garante distância CIE76 mínima de 24 entre setores adjacentes.
- Marcas: X normal menor e menos contrastante; ERROR_X conserva contraste coral, badge e permanência. Especialista com escala e posição ajustadas e sombra de contato nativa.
- Cards de regras: textos e ícones maiores, padding e altura proporcionais, cantos e sombras coerentes com os outros painéis.
- Planta Industrial: cabeçalho mais forte, linhas arredondadas e chips dimensionados pela altura disponível. Os sete setores ficam inteiros em 1100 × 820 e 1448 × 1086. Listas maiores em janelas baixas mantêm rolagem.
- Produção: card integrado ao painel, com base elíptica nativa sob o carro e espaço reservado para a ilustração, evitando sobreposição com textos.
- Topo: marca centralizada independentemente da largura dos botões, hierarquia maior para produto/fase e vidas proporcionais ao HUD.
- Background: opacidade menor, modulação quente e haze em gradiente nativo. Instruções e feedback receberam superfícies próprias sob o board.
- Responsividade: escala desktop considera largura e altura; o painel continua migrando para cards expansíveis abaixo do board em portrait.

## Assets

Reutilizados sem modificar os arquivos: `specialist_default.png`, `hatch_compact.png`, `factory_courtyard.png`, fontes Roboto Regular/Medium/Bold e SVGs existentes de marca, regras, setores e controles.

Nenhum novo PNG, WebP, SVG ou fonte. A base do veículo é um novo componente nativo em `production_stage.gd`.

## Arquivos desta iteração

| Arquivo | Responsabilidade |
| --- | --- |
| [visuals.gd](../game/scripts/visuals.gd) | Tokens, superfícies, aro, bezel e bandeja |
| [cell.gd](../game/scripts/cell.gd) | Volume das células, marcas e integração do especialista |
| [board_lines.gd](../game/scripts/board_lines.gd) | Apresentação das fronteiras |
| [sector_palette.gd](../game/scripts/sector_palette.gd) | Valores da paleta secundária |
| [game.gd](../game/scripts/game.gd) | Layout, cards, painel, produção e escala |
| [life_indicator.gd](../game/scripts/life_indicator.gd) | Desenho proporcional das vidas |
| [background.gd](../game/scripts/background.gd) | Modulação do cenário e haze |
| [production_stage.gd](../game/scripts/production_stage.gd) e `.uid` | Novo componente de apresentação do veículo |
| [test_visual_preview.gd](../game/tests/test_visual_preview.gd) | Quatro verificações adicionais de setores visíveis e ausência de sobreposição |
| Este documento | Registro de entrega e limitações |

A alteração de `project.godot` que já estava no workspace foi preservada. Os documentos de contexto, a imagem oficial e o prompt já existentes também foram preservados.

## Validação

Comando: `powershell -NoProfile -ExecutionPolicy Bypass -File .\Testar.ps1 -Render`.

| Verificação | Resultado |
| --- | --- |
| Validador de fases | 15 válidas, conectadas e com solução única |
| Python | 25 testes aprovados |
| Godot, integração renderizada | 214 verificações aprovadas |
| Persistência entre processos | 7 verificações de escrita + 10 de reabertura aprovadas |
| Preview e layouts renderizados | 52 verificações aprovadas |
| SHA-256 de arquivos protegidos | 32 conferidos, nenhum alterado |
| Métodos de comportamento em scripts visuais | 16 idênticos ao HEAD anterior |
| Caminho antigo | Sem referência nas fontes de execução, ferramentas, testes e launchers |

O Godot executou as cenas reais em Windows, Forward+ / Direct3D 12, Intel UHD Graphics 620. Não houve alteração de regras, JSONs, solver, gerador, input ou formato de save. Os testes usam saves isolados em `user://tests/`.

As capturas foram inspecionadas em desktop 1448 × 1086 e 1100 × 820, janela baixa 1100 × 740, grids 5 × 5 a 9 × 9 e portrait 390 × 844 / 360 × 700. Também foram examinados produção expandida, estados de erro, especialista fixo, menu e resultados.

## Evidências

- [Antes, 1448 × 1086](../artifacts/refinement-before/reference_desktop_1448x1086.png).
- [Depois, 1448 × 1086](../artifacts/reference_desktop_1448x1086.png).
- [Depois, 1100 × 820](../artifacts/reference_desktop_1100x820.png).
- [Fase inicial, 5 × 5](../artifacts/phase_01.png).
- [Portrait mínimo](../artifacts/visual_game_360x700.png).
- [Execução final](../artifacts/refinement-final-suite.log), [relatório Godot](../artifacts/godot_tests_Windows.json) e [relatório visual](../artifacts/visual_tests.json).
- [Arquivos protegidos](../artifacts/refinement-protected-check.json) e [métodos preservados](../artifacts/refinement-methods-check.json).

`artifacts/` permanece ignorado pelo Git. As imagens e logs estão disponíveis no workspace local.

## Diferenças que permanecem

A imagem oficial tem células, ícones e iluminação mais esculpidos. A versão real usa superfícies nativas com relevo discreto e os SVGs existentes, de desenho mais simples. O cenário e as ilustrações reutilizados não são idênticos aos da referência.

A referência mostra um board 5 × 5 na fase 4 e informações de contagem inconsistentes entre board e painel. A fase 4 publicada permanece 7 × 7, com sete setores e sete especialistas. A composição real se adapta ao conteúdo correto, sem copiar essa inconsistência da imagem.

Em janelas baixas, os chips ficam mais compactos; fases com mais setores podem exigir rolagem no painel. A verificação mobile foi feita por redimensionamento no Godot para Windows, sem exportação ou teste em aparelho físico. Os testes de input são sintéticos, sem playtest humano adicional.
