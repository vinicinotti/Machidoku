# Arquitetura — jogo e apresentação visual

As cenas Main, Game, Board e Cell, o GameState e o adaptador de input do MVP foram preservados. As alterações acrescentam autoria offline, persistência e apresentação sem alterar as quatro regras do puzzle.

| Componente | Responsabilidade |
| --- | --- |
| Main / main.gd | Carregar catálogo, abrir menu/continuação, navegar por índice do catálogo, gravar conclusão |
| progress_store.gd | Save versionado, reconciliação de ids, backup e escrita verificada |
| Game / game.gd | HUD, legenda responsiva, reação das vidas, popup e chegada do veículo |
| Board / board.gd | Células, cores, geometria, sincronização e pulse de vitória |
| board_lines.gd | Overlay único de grade, fronteiras de setores e contorno externo |
| sector_palette.gd | Paleta de 12 cores, grafo de adjacência e escolha de cores por distância perceptual |
| Cell / cell.gd | Fundo e conteúdo passivo, pop/fade de marcas, reação visual de erro |
| board_input.gd | Primeiro clique imediato, reconhecimento do segundo por timestamp, drag e cancelamento |
| game_state.gd | Vidas, estados, erros persistentes, fixos e validação de vitória |
| level_loader.gd | Descobrir JSONs, validar dados e ordenar ids reais |
| visuals.gd / world_catalog.gd | Tema, fontes estáticas e metadados de mundo/produto |
| background.gd / life_indicator.gd | Ambiente PNG passivo e indicador nativo de vidas |
| dev/visual_preview.gd | Galeria independente de assets e estados visuais, sem save |
| tools/assets | Autoria reproduzível da família SVG e svg_inventory.json |
| tools/generator | Construção offline de candidatos e publicação validada |
| tools/solver | Validação independente e enumeração de soluções |
| tools/difficulty | Roteiro lógico sem resposta e métricas editoriais |

## Catálogo automático

`LevelLoader.load_levels(directory = "res://levels")` lista os arquivos JSON diretos, valida cada um, recusa ids repetidos e ordena por id. Nomes de arquivos e lacunas de ids não definem navegação. Adicionar um JSON válido com id único dispensa alteração de código. Não há manifesto de três ou quinze caminhos no runtime.

JSONs precisam ser incluídos como arquivos não resource em uma futura exportação (`*.json` no filtro). Presets/templates de exportação continuam fora desta iteração. Fases antigas ficam na raiz, em `levels/archive/mvp`, fora de `res://` e do catálogo ativo.

## Formato de fase

Mantidos: `id`, `name`, `world`, `product`, `vehicle_name`, `difficulty`, `size`, `regions`, `solution`, `preplaced_specialists`. Coordenadas e ids de setores começam em zero. `regions` cobre N×N e contém ids 0..N−1. Fixos são posições válidas da solução.

Acrescentados: `difficulty_metrics` com os números da prova e `generation` com versão, seed, tentativa e origem. O runtime ignora os detalhes de autoria para resolver a partida. Soluções e conectividade são validadas no loader; unicidade e prova lógica são verificadas offline.

## Estado, persistência e fluxo

GameState continua independente de cenas e input. Estados: EMPTY, X, SPECIALIST, ERROR_X e PREPLACED_SPECIALIST. X é uma anotação removível: `mark_x` não consulta a solução, não registra erro e não altera vidas. Somente `toggle_specialist` valida a resposta; uma tentativa incorreta vira ERROR_X e custa uma vida. ERROR_X é permanente durante a tentativa, não aceita especialista nem apagamento, e o dicionário `errors` registra apenas essas tentativas incorretas. A view desenha o X coral, sem especialista errado. Estados de célula não são serializados no save de progressão.

O adaptador de input mantém a distinção entre clique simples e duplo clique. O arraste usa UNSET, MARK ou ERASE: escolhe o modo pelo primeiro EMPTY/X normal e o mantém até soltar. Começar sobre um especialista ou ERROR_X deixa o modo pendente até alcançar uma célula editável. O modo é aplicado também às células interpoladas e cada célula é visitada uma vez por gesto. MARK ignora X já existentes; ERASE ignora EMPTY; ambos ignoram peças e erros confirmados. Não há consulta à solução durante gestos de anotação.

Não existe Timer de debounce no input. O primeiro pressionamento aplica a anotação imediatamente ou pede sua animação de saída. `Time.get_ticks_msec()` reconhece um segundo pressionamento na mesma célula em até 450 ms sem suspender o primeiro. Um segundo clique cancela a saída em curso e chama a intenção de especialista. Drag e perda de foco limpam esse histórico, evitando interpretar o clique após um arraste como uma tentativa de especialista.

Board seleciona remoção em 90 ms (clique) ou 55 ms (drag). Cell mantém X enquanto o Tween reduz escala a 0,85 e alpha a zero, depois o callback pede EMPTY ao modelo. A revisão de remoção e o cancelamento de Tween impedem callbacks antigos de apagar peças/ERROR_X mais recentes. Refreshes de outras células não reiniciam a saída; trocar de estado, terminar a partida ou substituir o tabuleiro cancela callbacks incompatíveis. GameState continua síncrono, independente das durações de apresentação.

O modo do drag é capturado antes da primeira alteração imediata. Ao cruzar o limiar de movimento, uma saída ainda em curso na primeira célula passa à duração curta; células seguintes começam a saída ao serem atravessadas. Se a primeira já virou EMPTY, o gesto continua ERASE até soltar.

Main carrega ProgressStore ao iniciar. Jogar usa `current_level`; iniciar fase grava o id. A vitória emite `level_completed` imediatamente, antes de aguardar o pulse de 180 ms, para não perder conclusão ao fechar durante a transição. Main registra conclusão e próximo id. Reiniciar substitui a partida sem apagar progressão. Uma falha de save é retornada e sinalizada na UI.

Formato e política de recuperação em `SAVE_FORMAT.md`. O caminho pode ser injetado ao instanciar Main, permitindo testes isolados sem alterar o save pessoal.

## Desenho do tabuleiro

Cell não desenha linhas de grade nem fronteiras de setor. `BoardLines` fica acima das células e produz:

- Grade interna em baixa opacidade, 0,7 px.
- Fronteiras quando os dois `region_id` diferem, 4,5 px, emitidas uma vez.
- Contorno externo arredondado nativo, com borda estrutural de 5 px.

Segmentos colineares consecutivos são unidos em runs. Antialiasing fica habilitado. O overlay e as células compartilham a mesma origem e pitch calculados no resize. O selo e a marca de erro continuam na view da célula.

## Cor e animação

Uma paleta de 12 tons suaves é convertida para CIELAB D65. O grafo liga setores que compartilham um lado. Uma busca DSATUR com backtracking exige distância CIE76 de pelo menos 24 entre vizinhos e favorece usar cores ainda não escolhidas. Setores não vizinhos podem reutilizar cores. A legenda usa exatamente o mapa calculado pelo board.

Tweens não modificam o modelo. Especialista: escala 0,70 → 1,10 → 1,00 em cerca de 160 ms e alpha em 100 ms. X: fade/scale curto. Erro: shake do conteúdo/flash dentro da célula em 180 ms, sem deslocar as fronteiras. Vida: pulse/fade em 170 ms. Vitória: pulse de 180 ms, painel em 100 ms e hatch em 160 ms. Não há spritesheets nem AnimatedSprite2D.

Animações de marca são substituídas quando chega um novo estado. Tweens são associados aos nós e são encerrados ao descartar a cena. Tabuleiro e input continuam bloqueados depois de terminar a partida. O popup de vitória aguarda o pulse curto; a gravação já ocorreu.

## Layout

Mantidos Containers, anchors, AspectRatioContainer e fonte estática. A janela acompanha pixels nativos, com mínimo 360×700. A partir de 900 px há legenda lateral com rolagem própria; abaixo disso ela é substituída por dois cards inferiores recolhíveis. A página usa ScrollContainer: expandir a planta/produção pode aumentar a altura rolável, sem comprimir o tabuleiro abaixo de sua área mínima. Abrir/recolher cards altera somente a árvore de apresentação. O tabuleiro mantém proporção quadrada. O popup acompanha redimensionamentos. A renderização existente Forward+ / Direct3D 12 permanece.

`visuals.gd` centraliza Theme, cores oficiais, fontes, superfícies, estados dos botões e helpers de marca/card. Não há textura para painéis ou células: StyleBoxFlat desenha base, borda e sombra; Cell usa polígono arredondado com cores interpoladas para o volume e acrescenta highlight superior. A geometria de Board e o cálculo de BoardLines permanecem iguais; o desenho de linhas/contorno foi refinado. A seleção de cores foi preservada e os 12 valores da paleta foram ajustados. Vidas são desenho nativo; o valor vem do mesmo GameState e o Tween anterior continua associado ao indicador.

Main, Game e Cell foram restilizadas por seus scripts; seus `.tscn` e a cena Board foram preservados. `dev/VisualPreview.tscn` não instancia Main, ProgressStore ou BoardInput. Personagem, veículos e ambiente são PNGs RGBA gerados por image_gen e incluídos no projeto; ícones/branding são SVGs simples. Tudo é estático. O wordmark é texto nativo; a implementação atual usa Barlow Semi Condensed Black com espaçamento centralizado em V.brand. Os SVGs ilustrativos antigos são legado, sem uso no runtime.

## Verificação

Testes Python verificam dados, geração por seed, conectividade, unicidade, prova lógica sem resposta, classes, SVGs e entrega/proveniência dos PNGs. A integração Godot injeta eventos no viewport, percorre as 15 fases, verifica cores e fronteiras únicas. Outro script roda em dois processos para comprovar save/reabertura, recuperação e reset. `test_visual_preview.gd` carrega 39 SVGs e cinco PNGs, verifica alpha, captura a galeria e testa cards/menu/board/resultados em janelas estreitas, além de uma fase 4 real para comparação desktop. Logs e capturas ficam em `artifacts`; relatórios em `VALIDATION.md` e `VISUAL_VALIDATION.md`.

## Camada visual v2 vigente

As descrições visuais de superfície e layout acima são históricas. A v2 mantém Main/Game/Board/Cell e separa o posicionamento em game_layout.gd, os retratos em specialist_art.gd e a barra em specialist_strip.gd. difficulty_badge.gd e score_popup.gd são componentes de apresentação. Shaders locais desenham bevel de tile, silhueta e suavização do cenário; não validam regras. Settings usa o mesmo ProgressStore. Métodos de interação e os 60 JSONs são preservados; a avaliação econômica de X ocorre somente na vitória. V.card antigo foi substituído por V.material nos componentes ativos. VISUAL_TARGET.md e VISUAL_STYLE.md descrevem a implementação atual.

## Consolidação sem novos sistemas

glass_surface.gd encapsula apenas a superfície visual, aplicada uma vez por painel lateral. Game cria um único BackBufferCopy depois do background e antes da UI. GameLayout desativa essa captura em portrait. Cell reutiliza TextureRect passivo para aplicar o mesmo ShaderMaterial de identidade da SpecialistStrip; nenhuma responsabilidade de input/estado migrou. Fontes são recursos estáticos centralizados em Visuals. Não foram adicionados Autoloads, formatos de dados ou persistência paralela. Detalhes atuais em VISUAL_STYLE e VISUAL_VALIDATION.

## Master 1672×941

GameLayout mantém o canvas de referência proporcional e centralizado. BoardPresentation é um Container de apresentação: dimensiona um Control intermediário quadrado e aplica escala visual ao seu conteúdo, sem alterar Board, Cell, picking, BoardInput ou GameState. A coluna da Planta usa um Control com caixas medidas para header/lista/produção, preservando ScrollContainer para fases maiores. O glass direito usa um mount transparente que compensa o padding do painel; isso evita encolher o vidro ou aplicar uma segunda camada.

## Correção estrutural vigente

A apresentação da Cell acrescenta um Control com clip apenas para o retrato e calcula o fit reservando 1,10 de escala. BoardInput e GameState continuam intactos. A composição mantém os mesmos componentes; ScoreRow é reparentado para ControlsRow no desktop e volta ao fluxo móvel. O ScrollContainer da Planta mantém linhas constantes, separadas da produção.
