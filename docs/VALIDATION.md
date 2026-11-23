# Validação — identidade visual e regressão do jogo

Concluída em **20/10/2026**, no Windows, com Godot **4.7.2.stable.official.ed1daf0bf** e Python **3.13.15**. A execução gráfica usou Forward+ / Direct3D 12 na NVIDIA GeForce RTX 4060 identificada pela engine.

## Resultados

| Verificação | Resultado |
| --- | --- |
| Catálogo ativo | 15 fases válidas, 15 soluções únicas |
| Testes Python | 25 testes, nenhuma falha |
| Integração renderizada | 214 verificações, nenhuma falha |
| Galeria e layout renderizados | 48 verificações, nenhuma falha |
| Persistência em processos separados | 7 na escrita + 10 na reabertura, nenhuma falha |
| Importação e execução Godot | Sem erros de parser/runtime nos logs finais |
| Capturas | Jogo: 16 gravações / 15 PNGs; visual: 16 gravações / 16 PNGs |
| Preservação SHA-256 | 27 arquivos e 15 métodos protegidos, zero alterações |

A iteração baseada na referência integrou cinco PNGs gerados por image_gen, refinou os SVGs simples (incluindo Powertrain), moldura, células, Theme e hierarquia desktop/portrait. O projeto inclui 39 SVGs, dos quais 15 são legado/compatibilidade. O relatório detalhado está em [VISUAL_VALIDATION.md](VISUAL_VALIDATION.md). Não foram alterados solver, gerador, fases, regras, input ou persistência.

As verificações renderizadas incluem os cenários funcionais e as gravações de imagem; não são cenários independentes adicionais. Os testes de input usam eventos sintéticos no viewport das cenas. Foi feita revisão visual dos PNGs. Não foi realizado playtest humano com mouse físico nem calibração de dificuldade com jogadores.

O teste principal inclui 198 verificações funcionais e 16 gravações de imagem. O teste visual acrescenta 32 verificações funcionais e 16 gravações. A importação do projeto foi executada em modo headless; os cenários de input e de apresentação foram executados com renderização real. As esperas entre cliques independentes do harness usam o relógio monotônico, evitando que um Timer criado em frame caro termine antes da janela real de duplo clique.

## Responsividade de clique e remoção

O Timer de 450 ms foi removido do input. O primeiro pressionamento já cria X visível ou inicia sua saída. O intervalo de 450 ms é comparado por timestamps apenas para reconhecer o segundo pressionamento na mesma célula, sem bloquear o primeiro.

Verificações novas aprovadas:

- Marcação no primeiro pressionamento e X visível no primeiro frame da view.
- Remoção iniciada no pressionamento, mantendo X até terminar o Tween de 90 ms.
- Escala entre 1 e 0,85 e alpha entre 1 e zero durante a saída, amostrados com `custom_step(0.045)`; confirmação de EMPTY depois da animação, sem aguardar 450 ms.
- Segundo clique durante a saída cancela o callback anterior e coloca especialista ou ERROR_X, sem apagamento posterior nem cobrança extra.
- Segundo clique após a saída já ter concluído ainda é reconhecido pelo timestamp e coloca o especialista normalmente.
- Arraste mantém ERASE mesmo quando a primeira célula já virou EMPTY antes do movimento; células seguintes entram em saída imediatamente e terminam em 55 ms, verificadas após 75 ms.
- Um novo MARK que cruza X em saída cancela a remoção anterior, preservando a intenção mais recente e impedindo desaparecimento tardio.
- Regras A–H, 15 fases, fixos, ERROR_X permanente e save continuam aprovados.

A entrada de X normal parte de alpha 0,30 para que a primeira imagem não fique completamente transparente antes do primeiro passo do Tween. As animações continuam sendo verificadas por propriedades e estados dos nós; as capturas registram estados estáticos. A avaliação subjetiva de latência com mouse físico ainda depende de playtest.

## Contrato de interação corrigido — A–H

| Caso | Comportamento verificado por eventos no viewport |
| --- | --- |
| A | Clique alterna EMPTY ↔ X normal |
| B | X sobre uma posição da solução continua normal, removível, sem perder vida, cor de erro, flash ou feedback que revele a resposta |
| C | Duplo clique errado, sobre EMPTY ou X normal, perde uma vida e deixa somente ERROR_X; clique e duplo clique posteriores não removem nem repetem a cobrança |
| D | Duplo clique correto cria especialista, inclusive substituindo X normal; clique simples não altera a peça |
| E | Drag MARK marca EMPTY, preserva X existentes e ignora peças/erros; revisitar uma célula não alterna seu estado |
| F | Drag ERASE remove somente X normais, mantendo EMPTY e o modo de todo o gesto |
| G | ERASE atravessa ERROR_X sem removê-lo; iniciar em ERROR_X ou peça espera o primeiro EMPTY/X normal para escolher o modo |
| H | Reiniciar elimina todos os ERROR_X e demais estados temporários, repõe vidas e conserva as peças fixas |

O modelo também foi testado anotando e apagando todas as células editáveis da fase, inclusive as posições da solução, sem alterar vidas ou registrar erros. Vitória após duas tentativas incorretas continua possível e preserva os X vermelhos até o fim da tentativa. Nenhuma fase, regra de solução ou estrutura do save foi alterada nesta correção.

## Fases e geração

Fase 1 preservada e revalidada; 14 novas fases selecionadas offline. Todas são Automotive / Hatch Compact. Há N setores conectados, cobertura N×N, N especialistas, exatamente um por linha/coluna/setor e nenhuma adjacência. O solver independente encontrou uma única solução em cada fase e os rastros lógicos derivam a mesma resposta sem consultar o campo solution.

Distribuição: 4 fáceis, 6 normais, 3 difíceis e 2 muito difíceis. Grids 5×5, 6×6, 7×7, 8×8 e 9×9, com fixos em parte das fases. Métricas e classificação por fase em `LEVEL_NOTES.md`; rastros completos em `level_report.json`.

O primeiro perfil usa a introdução original com rótulo editorial Fácil; as demais classes seguem a heurística. A última fase deriva de uma expansão e mutação de fronteiras da fase 14, com origem registrada no JSON. Não é apresentada como layout totalmente independente.

O gerador foi executado para publicar o bloco e gerar o relatório. Durante desenvolvimento, a busca aleatória inicial da fase 15 esgotou o limite sem publicar fallback; a estratégia final foi alterada para expansão e mutação, e o bloco foi revalidado inteiro. O teste de limite esgotado confirma que não se cria saída inválida.

## Cenários cobertos

- Descoberta dos JSONs por nomes arbitrários e ordenação de ids, inclusive com lacunas.
- Clique para X, remoção, duplo clique para especialista, remoção e proteção dos fixos.
- Duplo clique interpretado como uma única tentativa de especialista.
- Arraste de marcação e apagamento, incluindo interpolação de células entre eventos.
- Anotações sem validação, tentativas erradas convertidas em X vermelho permanente, substituição de X normal e vitória com erros confirmados.
- Três vidas, terceiro erro, bloqueio após derrota, painel e reinício.
- Retorno ao menu e continuação da fase 2.
- Vitória nas 15 fases sem exigir X no restante, gravação das conclusões, avanço e conclusão final do Hatch Compact.
- Cores de setores vizinhos com CIE76 ≥ 24 nas 15 fases.
- Contagem de fronteiras compartilhadas emitidas uma única vez nas 15 grades.
- Tweens de peça e vida retornam à escala/alpha finais sem alterar a geometria da célula.
- Layouts 1100×820, 620×900, 1100×740 e 580×700; menu e vitória na janela mínima anterior. O teste visual acrescenta 390×844 e 360×700, cards inferiores e redimensionamento de resultado aberto.

## Persistência real entre processos

Um processo Godot abre Main com save isolado, completa a fase 1, entra na 2, volta ao menu, continua da 2, reinicia e fecha. Outro processo abre Main novamente e confirma fase 2, conclusão da 1, desbloqueio e três vidas. O arquivo fica em `user://tests/cross_process.json`; o save pessoal não é alterado.

Também foram testados reset persistido, primário truncado com recuperação pelo backup, versão futura protegida e navegação com ids 10 e 30. A simulação de versão futura produz um WARNING esperado. O primário truncado é tratado sem erro de parser no log e com recuperação da cópia válida.

## Arte e revisão visual

Especialista, três carros e ambiente foram gerados em PNG com transparência. Nove ícones de setores e as regras usam SVG. Fronteiras continuam em um overlay único; o contorno e a moldura são mais robustos e as células têm volume nativo. Foram revisadas capturas de menu, fases, erros, derrota, vitória, galeria, cards portrait e fase 4 em 1448×1086 e 1100×820 para comparação com a referência.

As capturas documentam estados estáticos; a verificação dos Tweens usa o estado dos nós. As cinco ilustrações raster estão incluídas no projeto, sem animação de personagens, spritesheets ou marcas reais de veículos. A transparência é verificada no Godot.

## Evidências

- `artifacts/import.log`
- `artifacts/godot-tests-rendered.log` e `godot_tests_Windows.json`
- `artifacts/persistence-write.log`, `persistence-read.log`
- `artifacts/persistence_write.json`, `persistence_read.json`
- PNGs atuais: menu, phase_01, phase_07, phase_11, phase_14, phase_15, errors, defeat, victory_01, victory_15, layouts 620×900/1100×740/580×700, menu_minimum e victory_minimum.

Arquivos intermediários e relatórios headless de execuções anteriores podem permanecer em `artifacts`; os resultados desta correção são o log e JSON renderizados, os logs de importação e os dois relatórios de persistência indicados acima. A pasta é ignorada pelo Git.

## Inventário das correções anteriores

Para o inventário da iteração visual atual, consultar [ASSETS.md](ASSETS.md), [ASSET_GUIDE.md](ASSET_GUIDE.md) e [VISUAL_VALIDATION.md](VISUAL_VALIDATION.md). Os registros abaixo descrevem as alterações anteriores que formam a base desta apresentação.

Neste ajuste de responsividade: `board_input.gd` passou a aplicar o primeiro clique imediatamente e reconhecer o segundo por timestamps; `board.gd` coordena as saídas de X em 90/55 ms; `cell.gd` anima a saída e invalida callbacks obsoletos. `game/tests/test_mvp.gd` cobre os tempos, cancelamentos e interações rápidas. README, design e arquitetura foram atualizados. GameState, regras de ERROR_X, dados das fases e formato do save foram preservados. Não foram criados novos arquivos de código.

Na correção de semântica anterior, GameState deixou de validar anotações e passou a converter somente tentativas erradas em ERROR_X; o arraste passou a escolher MARK/ERASE na primeira célula editável. Esse contrato continua coberto pelos cenários A–H.

O inventário da segunda iteração, mantido abaixo, registra a base sobre a qual esta correção foi aplicada.

**Modificados:**

- `game/scripts/main.gd`: continuação, carregamento de progresso, gravação e reset de debug com confirmação.
- `game/scripts/game.gd`: callbacks de conclusão, Tween de vida/board/popup/veículo e resultado do bloco.
- `game/scripts/board.gd`, `cell.gd`, `visuals.gd`: fronteiras únicas, mapa de cores, X e microanimações.
- `game/scripts/level_loader.gd`: descoberta automática e validação reforçada.
- `game/levels/01_hatch.json`: layout preservado, metadados de geração e dificuldade acrescentados.
- `game/assets/specialists/specialist.svg`, `vehicles/hatch.svg` e oito SVGs em `sectors`.
- `tests/test_levels.py`, `game/tests/test_mvp.gd` e `Testar.ps1`.
- README e documentos de design, arquitetura, roadmap, assets, fases e validação.

**Novos:**

- `game/scripts/progress_store.gd`, `board_lines.gd`, `sector_palette.gd`.
- `game/levels/02_hatch.json` até `15_hatch.json`.
- `tools/generator/generate.py`, `profiles.json`, `tools/difficulty/analyze.py`.
- `tests/test_pipeline.py`, `game/tests/test_persistence.gd`.
- `docs/SAVE_FORMAT.md`, `GENERATION.md`, `level_report.json`.
- Metadados .uid de scripts novos gerados pelo Godot.

**Preservados:**

As quatro cenas, solver independente, fontes, engine e configuração do projeto. Os três JSONs originais estão em `levels/archive/mvp`. Sedan e esportivo foram retirados do catálogo ativo e seus assets antigos continuam preservados; nenhum produto seguinte foi implementado. Não houve configuração de remoto, backend ou exportação mobile.

## Pendências reais

- Calibrar dificuldade, janela de gesto e legibilidade por playtest humano.
- Validar acessibilidade além da distinção de cores e disponibilizar redução de movimento em outra etapa.
- A progressão é salva, mas marcas e vidas de partidas em andamento não são restauradas.
- O analisador é restrito às regras implementadas; não é avaliação completa de raciocínio humano.
- A gravação dos JSONs é atômica por arquivo; uma publicação de bloco inteiro ainda não é uma transação de diretório.
- Testes executados nesta máquina; outros hardwares, export standalone e dispositivos mobile não foram testados.

Não há bloqueio externo nem funcionalidade obrigatória desta iteração deixada pendente.
