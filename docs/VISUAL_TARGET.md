# Master visual do Machidoku

Referência normativa: [Interface de Jogo Machidoku Industrial.png](<reference/Interface de Jogo Machidoku Industrial.png>), 1672×941. Esta imagem enviada pelo usuário substitui as coordenadas da V2 anterior. A correção estrutural posterior prevalece sobre qualquer sobreposição ilustrada: os três blocos têm limites separados e topos alinhados. Os arquivos V1/V2 continuam como histórico. Copiar composição e acabamento; o conteúdo ilustrado do puzzle não é especificação funcional.

Especificação vigente: [refinamento P1/P2/P3](REFERENCE_VISUAL_REFINEMENT.md), com parâmetros em ui_tokens.gd. O conteúdo abaixo mantém a geometria aceita e os componentes atualizados.

## Safe frame

`visuals.gd` define `DESKTOP_CANVAS = Vector2(1672,941)`. `game_layout.gd` usa `s = min(viewport_width/1672, viewport_height/941)`, mesma escala nos dois eixos e origem `(viewport - canvas*s)/2`. O background cobre toda a viewport. Em 1920×1020, a UI ocupa 1812,41×1020 e começa em x=53,79. Em ultrawide, as margens aumentam, sem ampliar horizontalmente as colunas.

## Geometria de referência

Caixas em pixels do canvas base; valores aproximados medidos na imagem. Elementos internos podem variar com conteúdo real, quantidade de setores e tipografia Barlow.

| Elemento | x | y | largura | altura | raio / padding / gap |
| --- | ---: | ---: | ---: | ---: | --- |
| Menu | 209 | 26 | 198 | 66 | raio 26, padding 14 |
| Marca | 625 | 10 | 423 | 86 | símbolo 86, gap 12, Baloo 2 ExtraBold 54 |
| Configurações | 1182 | 25 | 69,63 | 64,93 | quadrado arredondado, lip 6%, ícone branco |
| Reiniciar | 1274 | 25 | 246 | 66 | raio 26 |
| Glass esquerdo | 179 | 105 | 310 | 590 | raio 32, padding H19 |
| Campanha / fase | 198 | 133 | 272 | 62 | ícone 70×56 centralizado, gap 14 |
| Produto no cabeçalho | 282 | 196 | 169 | 52 | ExtraBold 40 |
| Dificuldade | 198 | 256 | 272 | 72 | gradiente, lip e track de pontos com contraste ≥3:1 |
| Primeira regra | 198 | 349 | 272 | 72 | raio 24, padding H12/V5 |
| Segunda regra | 198 | 434 | 272 | 72 | gap 13 |
| Terceira regra | 198 | 519 | 272 | 72 | gap 13 |
| Card de vidas | 198 | 604 | 272 | 78 | raio 26, padding 12 |
| Barra de especialistas | 505 | 105 | 638 | 110,097 | 11,7% H, anel branco e silhueta chapada |
| Moldura do board | 505 | 218 | 638 | 588 | rim 8; bezel H16/V10; tray 3 |
| Planta Industrial | 1157 | 105 | 378 | 786 | raio 32, padding 22 |
| Cabeçalho da planta | 1179 | 147 | 334 | 62 | ícone 56×60, gap 16 |
| Lista de setores | 1179 | 227 | 334 | 362 | cards 64 em todos os grids, gap 10 |
| Em Produção | 1179 | 603 | 334 | 277 | raio 28, padding H16/top12/bottom20, gaps 4 |
| Mensagem | 505 | 821 | 638 | 62,106 | única barra central, fonte 2,2% H |
| Instruções e pontuação | 198 | 710 | 272 | 95,982 | card auxiliar na coluna esquerda |
| Pontuação corrente | dentro do card | auxiliar esquerdo | largura natural | altura do conteúdo | sob os controles |

Menu termina 13 px acima do painel esquerdo. O glass esquerdo termina em x=489, reservando 16 px até a moldura. Moldura e planta ficam separadas por 14 px. A barra superior compartilha x e largura com a moldura e termina aproximadamente 3 px antes dela. Os três topos estruturais começam em y=105. Uma única dica começa 15 px abaixo do board. Controles e score ocupam o card auxiliar esquerdo.

A especificação P1/P2/P3 substitui as duas barras centrais por uma única dica. O score permanece no card auxiliar de controles à esquerda, preservando acesso às informações.

## Materiais e cores

Um glass estrutural em cada lateral; a barra de especialistas é uma superfície creme própria. Cards internos são faces claras com uma borda e sombra suave em dois níveis e highlight superior. Não empilhar glass ou aros inferiores nos cards. `V.surface` usa textura vetorial de altura próxima à dos cards para evitar a faixa causada pela compressão excessiva do gradiente no nine-patch.

O glass esquerdo mistura 36% de creme com 64% do cenário suavizado; o direito usa 42%/58%, com alpha final 0,97. Um único preenchimento frosted recebe borda, luz suave na periferia e sombra externa nativa de 10 px. Ambos leem o mesmo buffer anterior à UI, LOD 2,6, com arredondamento, highlight e borda suave. A cor vista depende do background, portanto esses percentuais não são uma medida inversa exata da ilustração. O asset do cenário é preservado. Blur fixo 3×3 com mip baixo suaviza o cenário sem o padrão de blocos de um mip alto isolado.

## Amostras do PNG original

Pixels medidos com System.Drawing, sem inferir cores a partir da prévia do chat. Gradientes e antialiasing variam ao redor de cada ponto.

| Uso | Ponto x/y | HEX |
| --- | --- | --- |
| Navy do texto | 305 / 154 | #00235C |
| Navy da moldura | 560 / 225 | #0D456F |
| Creme de card | 1400 / 260 | #FEF0E4 |
| Laranja do botão | 1405 / 71 | #F04707 |
| Verde da dificuldade | 370 / 290 | #45BD50 |
| Amarelo de tile | 800 / 400 | #FEDA4B |
| Coral de tile | 595 / 400 | #FE8E61 |
| Verde de tile | 700 / 610 | #86EB7F |
| Azul de tile | 950 / 517 | #55BEFA |
| Roxo de tile | 1080 / 630 | #BE81EF |

A paleta incorporou os cinco tons de tiles medidos, mantendo DSATUR e distância CIE76 mínima 24. Sua distribuição continua sendo calculada pelo grafo real, sem copiar regiões ou cores por posição da screenshot.

## Conteúdo e interação

Baloo 2 ExtraBold somente no wordmark, Barlow ExtraBold nos títulos e SemiBold em HUD/regras/legenda. Corpo e botões fora do gameplay mantêm as fontes existentes. Logo usa o mesmo V.brand. Retratos permanecem na família atual, com EPI tingido pela cor real do setor e o mesmo material na célula e no slot.

Cinco setores geram cinco slots. Os seis slots da ilustração e suas posições impossíveis não são copiados. Fixos, X, vidas, popup de score, descoberta/remoção e feedback seguem o GameState. No desktop, BoardPresentation aplica só a proporção visual do interior da moldura sobre um espaço local quadrado. Board, BoardInput e conversão de coordenadas nativa continuam responsáveis pelo picking; não há mapa de input paralelo. Portrait restaura proporção quadrada e fluxo vertical abaixo de 900 px.

Validação e comparações: [VISUAL_VALIDATION.md](VISUAL_VALIDATION.md).

## Enquadramento dos especialistas

Cell mantém o input e as transições de estado existentes. No desktop, o mount usa margem `max(3, lado*0,025)`, sem desconto adicional no rodapé. O fit preserva o aspecto e reserva pop visual máximo 1,04, além de 1 px de segurança por lado. A propriedade animada continua seguindo a mesma transição; apenas a escala aplicada ao retrato é limitada a 1,04. O enquadramento mobile anterior permanece separado. Um clip no mount protege os tiles vizinhos sem precisar cortar a arte no estado normal. A peça fixa usa o mesmo enquadramento; seu cadeado fica separado, no canto do tile. A barra superior tem padding uniforme, slots com clip e pop limitado a 1,04.

As linhas da Planta mantêm altura 64 e ícones 48, independentemente da quantidade de setores. Cinco linhas cabem integralmente. Listas maiores usam rolagem local com trilho discreto, mantendo o card de produção fora da área rolável. Não reduzir cards, fonte ou ícone para forçar sete ou nove itens numa caixa projetada para cinco.
