# Refinamento visual por prioridades P1, P2 e P3

Solicitação consolidada: aproximar a apresentação da referência industrial, preservando gameplay, nós e sinais existentes. A especificação mais recente substitui o botão circular e o rodapé de duas barras das iterações anteriores.

## Implementação

P1 foi aplicado primeiro: peças com gradiente de três pontos, lip saturado e realce superior; configurações arredondado com engrenagem branca; Reiniciar com duas setas; ícones coloridos maiores; faixa de avatares mais alta e silhueta chapada; uma única barra de dica sob o board. Controles e pontos permanecem em um card auxiliar compacto na coluna esquerda.

P2 ajustou o navy da moldura, somente a fonte do wordmark, contraste dos pontos de dificuldade e plataforma cinza-quente. P3 consolidou os consumidores em um registro visual por setor, preservou células de razão aproximada 1,07 e a lista rolável com produção fixa.

`game/scripts/ui_tokens.gd` reúne as novas cores, dimensões relativas a H, materiais e a geometria desktop aceita. `ui_sector_registry.gd` reúne id, ordem, nome, cor, receita, ícone e avatar de cada setor real, a partir do catálogo existente. `ui_skin.gd` cria materiais e texturas com cache. `ui_desktop_refinement.gd` aplica a apresentação sem escrever no modelo. Não há valores visuais novos hardcoded na cena da galeria. Fluxos e estilos mobile legados continuam separados.

As coordenadas são frações de H no canvas de referência. A escala usa `min(viewport_H/941, viewport_W/1672)` e mantém a proporção em viewports mais estreitos. Em 16:9, as dimensões efetivas escalam com H; em 1920×991 há margens horizontais maiores, sem tratar esse aspecto como defeito. A largura do painel esquerdo foi preservada após conferência em 16:9.

## Decisões e medidas

| Item | Resultado |
| --- | --- |
| Corpo da peça | Topo, centro e base da tabela; o centro usa a cor base explicitamente |
| Lip | 5,5% da altura útil, cor saturada própria; sem sombra preta para simular a borda |
| Pressão | Apenas apresentação: corpo desce 2,5 px de referência e lip reduz para 1 px |
| Canto e intervalo | Raio 14% do lado; intervalo visual 5% dentro do mesmo retângulo de input |
| Faixa de avatares | 11,7% H, anel branco, fundo saturado e silhueta com RGB × 0,65 |
| Configurações | 7,4% H × 6,9% H; gradiente e lip próprios |
| Reiniciar | Altura aceita de 66/941 H preservada; ícone de duas setas brancas |
| Ícones de setor | Tile de aproximadamente 6,2% H; glifo com 75% do lado; chevron maior |
| Mensagem central | Uma barra de 6,6% H com fonte de 2,2% H |
| Lista | Cinco linhas visíveis na caixa existente; oito ou nove registros acessíveis por rolagem |
| Plataforma | Disco cinza-quente com aro branco, espessura e sombra discretas |

A proposta de pontos brancos e preto a 20% sobre amarelo não garante contraste de 3:1. Foi usada uma pequena base neutra `#687884` sob os pontos: branco preenchido e `#071928` apagado. Os contrastes medidos entre os três são aproximadamente 4,56:1, 3,91:1 e 17,82:1. A base neutra é uma diferença deliberada em relação à ilustração.

Cornflower foi substituído por índigo `#6F88F2`. Os oito tons solicitados e quatro extensões existentes resultam em ΔE76 mínimo aproximado de 24,14 entre todos os pares. Distância CIE76 não garante acessibilidade para todas as formas de daltonismo; a geometria e as fronteiras dos setores continuam disponíveis.

A faixa e a lista já tinham a quantidade real de setores. O problema de ver somente cinco linhas era a área de rolagem, não falta de registros. A implementação preserva a rolagem e mantém o card de produção fora dela, evitando comprimir nove linhas.

## Galeria e comparação

Cena independente: [visual_gallery.tscn](../game/ui/visual_gallery.tscn). Não carrega GameState ou cenas de gameplay. Contém oito peças, retratos e silhuetas, ícones coloridos, os botões interativos, moldura, wordmark, dificuldade, plataforma e dica.

Abrir no Godot com F6 ou executar:

```powershell
engine/godot/Godot.exe --path game res://ui/visual_gallery.tscn
```

[Galeria renderizada](../artifacts/reference_visual_gallery.png), [Hatch em 1920×1080](../artifacts/reference_game_5_sectors_1920x1080.png), [oito setores](../artifacts/reference_game_8_sectors_1920x1080.png), [nove setores](../artifacts/reference_game_9_sectors_1920x1080.png) e [comparação 16:9](../artifacts/reference_comparison_1920x1080.png).

## Diferenças restantes e assets

- Os ícones foram refinados a partir dos vetores existentes. Mantêm leitura e cores, mas não reproduzem os pequenos ícones ilustrados em 3D da referência. Faltam versões ilustradas equivalentes para correspondência exata.
- O atlas atual traz busto e capacete na mesma imagem. O slot permite extravasamento e o enquadramento foi ampliado, mas a posição exata do capacete depende das margens transparentes de cada retrato. Um capacete em camada separada permitiria reproduzir com precisão a sobreposição sugerida de 8%.
- O disco da produção é desenho nativo com elipses, não o pedestal ilustrado com iluminação fotográfica. Os tons e as proporções são aproximados, como indicado no pedido.
- Baloo 2 ExtraBold aproxima largura e formas arredondadas, mas não é a fonte exata da imagem. A licença OFL acompanha o arquivo em assets/fonts. Fonte obtida do [repositório Google Fonts](https://github.com/google/fonts/tree/main/ofl/baloo2); [projeto dos autores](https://github.com/EkType/Baloo2).
- Quantidade de setores, cores atribuídas a cada região e posições dos especialistas seguem a fase real. A referência contém inconsistências de lógica e identidade cromática que não foram copiadas.
- Os controles e pontos não existem no mesmo lugar na referência. O card auxiliar à esquerda preserva essas informações e libera o rodapé central solicitado.

Não foram gerados placeholders para os assets ilustrados ausentes. Logo, Menu, fundo, aro creme, cadeados, engrenagens de vidas, produção e fontes dos demais rótulos foram preservados. A única alteração no script de SpecialistStrip fica em `fit_slots`, exclusivamente visual; seus métodos de montagem e descoberta e seus sinais permanecem intactos.

Resultados automatizados e hashes: [reference_ui_tests.json](../artifacts/reference_ui_tests.json), [suíte completa](../artifacts/reference-full-suite.log) e [integridade](../artifacts/reference_integrity.json). A validação Web no navegador permanece fora desta evidência; o preset existente já apresentava bloqueio de exportação.


## Resultado final da validação

Suíte `Testar.ps1 -Render`: **28 testes Python e 1.289 verificações Godot**, sem falhas. Composição: 574 de regras/input, 24 de persistência, 56 de preview e rolagem, 325 de campanha/replay/separadores, 108 de pontuação, 137 de apresentação existente e 65 novos da especificação P1/P2/P3.

Os 65 novos também passaram separadamente em Compatibility/OpenGL. Em ambos os renderers, os oito centros e lips da galeria respeitam o limite de 3 por canal; no capture nativo final, os centros coincidiram exatamente com os oito HEX configurados. Foram conferidos 1920×1080, proporção constante em 1600×900 e regressões existentes de resize. A suíte mais antiga ainda exerce mobile, sem redesenho nesta etapa.

94 arquivos anteriores protegidos continuam byte a byte iguais, incluindo todos os scripts de gameplay e ferramentas Python. Os 78 arquivos de lógica, níveis, catálogos e PNGs protegidos da etapa anterior também mantêm seus hashes. Os três métodos de SpecialistStrip que montam, dimensionam a disponibilidade e atualizam a descoberta estão inalterados; somente fit_slots recebeu a apresentação. Project.godot foi restaurado após a normalização do editor.
