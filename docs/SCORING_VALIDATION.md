# Pontuação, carteira e seasons

Implementação incremental de 20/10/2026. O relatório cobre esta alteração, preservando o trabalho anterior no workspace.

## Auditoria e pontos de integração

| Arquivo encontrado | Responsabilidade | Integração realizada |
| --- | --- | --- |
| `scenes/Main.tscn`, `scripts/main.gd` | Cena principal, navegação e gravação após vitória | Encaminha o resultado calculado ao mesmo ProgressStore; recebe o comprovante da recompensa e informa bloqueios de season |
| `scripts/game_state.gd` | Estado puro, validação contra `solution`, erros, vidas e conclusão | Calcula a tentativa depois de validar cada ação, sem alterar as regras do puzzle |
| `scripts/board_input.gd` | Clique imediato, duplo clique e arraste interpolado de vários X | Delimita um gesto de pontuação; cancela seu X provisório quando o gesto se torna um especialista |
| `scripts/board.gd`, `scripts/cell.gd` | Geometria, visualização das células e animação de remoção de X | Preservados integralmente |
| `scripts/game.gd` | HUD, responsividade e modal de vitória/derrota | Exibe pontos de especialistas na linha existente, popups discretos e resumo no modal; controla tempo por foco/pausa |
| `scripts/progress_store.gd` | Save versão 1, backup, conclusões, recordes e replay | Amplia o mesmo arquivo com carteira, recompensa única, recordes de score e requisitos de season |
| `scripts/level_loader.gd` | Descoberta, ordenação e validação dos JSONs | Aceita `reference_time_sec` positivo e finito como campo opcional |
| `scripts/world_catalog.gd`, `data/campaign.json` | Mundos, produtos, nomes, assets e intervalos | WorldCatalog também lê a configuração independente de seasons; o catálogo de produtos foi preservado |
| `scripts/level_select.gd` | Home integrada, histórico, replay, notas e separadores de veículos | Preservado integralmente, inclusive separadores após `first_level` |

Não existem Autoloads. Foram mantidos `changed`, `finished`, `level_completed` e as chamadas organizadas entre Main, Game e ProgressStore. Os sinais locais novos `score_changed` e `operator_scored` representam resultados já validados. Não há Event Bus, novo gerenciador de save ou reorganização de diretórios.

Os níveis continuam contendo ID, nome, mundo, produto, veículo, dificuldade, tamanho, regiões, solução e especialistas fixos. As 60 matrizes e os demais dados publicados não foram alterados. O pipeline offline também não foi alterado.

## Conceitos e cálculo

- `GameState.run_score`: pontuação da tentativa. Existe tanto na primeira conclusão quanto em replay.
- `ProgressStore.data.wallet_points`: saldo econômico persistido, creditado somente na primeira conclusão.
- `ProgressStore.best_gears(id)` e `total_gears()`: melhor nota permanente por fase e soma global. Não são moeda e nunca são gastas para desbloquear seasons.

Todos os parâmetros e fórmulas de balanceamento estão em [scoring_rules.gd](../game/scripts/scoring_rules.gd):

| Componente | Parâmetro inicial |
| --- | --- |
| Especialistas novos consecutivos | 100, 105, 110, 115, 120; os seguintes permanecem em 120 |
| Teto do multiplicador da sequência | 1,20 |
| X novos corretos por gesto | `20*n + 5*n*(n-1)` |
| Conclusão | 500 |
| Tempo até 0,75R / R / 1,5R / 2R | 500 / 350 / 200 / 100 |
| Tempo acima de 2R ou referência ausente | 0 |
| Multiplicador para 1 / 2 / 3 engrenagens | 1,00 / 1,15 / 1,30 |
| Quota de cada season anterior | `ceil(número de fases * 3 * 0,70)` |

Na vitória: `roundi((operator_score + x_score + time_bonus + completion_bonus) * quality_multiplier)`. A qualidade reutiliza `ProgressStore.gears_for_errors`, que já representa as três vidas existentes. Uma derrota não recebe bônus de conclusão, não registra conclusão e não paga carteira. Erros de especialista não subtraem pontos e mantêm exatamente o consumo de vidas existente.

Cada especialista e cada X correto rende pontos apenas uma vez por posição na tentativa. Remover/recolocar especialistas ou apagar/remarcar X não permite acumular pontos repetidos nem fabricar uma sequência. Peças fixas não rendem pontos. Um X deliberado ou erro de especialista interrompe a sequência; remover uma peça também impede estender a sequência com reposições já pontuadas.

## X neutros e gestos

O jogo não possuía validação de erro para X. X sobre uma posição da solução continua sendo uma anotação normal, apagável e sem consumo de vida. O scoring consulta a mesma fonte `solution` usada para validar especialistas; não cria um segundo solver nem altera estados de célula para indicar acerto de X.

**Decisão de compatibilidade:** o valor dos X é acumulado internamente, mas só aparece no resultado após a vitória. Mostrar `+20` em uma anotação correta e nada em uma incorreta revelaria a solução pelo placar. Por esse motivo, o HUD mostra explicitamente pontos de especialistas, e não o total parcial oculto dos X. Não há popup de acerto/erro de X durante o puzzle. O detalhamento completo fica no tooltip do resultado.

O clique continua marcando X imediatamente. Apenas a contabilização aguarda a distinção entre clique simples e duplo, usando a janela de 450 ms existente. O segundo clique cancela a contabilização do X provisório antes da tentativa de especialista, preservando sequências consecutivas reais. O arraste existente é um único lote, mesmo se durar mais de 450 ms, e é contabilizado ao terminar ou cancelar o gesto. Apagar não pontua. Um lote com quatro X corretos e um sobre a solução rende os pontos de quatro, sem transformar o quinto em erro de gameplay.

## Tempo efetivo

O cronômetro usa `Time.get_ticks_usec()` e acumula intervalos ao receber eventos. Não foi adicionado `_process()` nem `_physics_process()` para pontuação ou tempo.

O tempo começa depois da montagem da interface, enquanto a janela tem foco e a SceneTree não está pausada. Pausa e perda de foco interrompem a contagem; retomada a reinicia. Vitória/derrota interrompem o cronômetro antes da transição e do modal. Sair da cena também encerra o intervalo. Não existem telas de pause, modais obrigatórios ou animação inicial de bloqueio adicionais no fluxo atual.

`reference_time_sec` é opcional no JSON e deve ser número positivo e finito. Exemplo: `"reference_time_sec": 90`. Os níveis antigos sem o campo recebem bônus temporal zero. As 60 fases atuais permanecem sem referência calibrada: nenhum tempo foi inventado a partir da dificuldade heurística. Configurar essas referências exige playtest e pode ser feito por fase, sem migrar o formato inteiro.

## Save e compatibilidade

O arquivo continua sendo `user://progress.json`, versão 1, com a escrita temporária e o backup existentes. Campos aditivos:

| Local | Campos e finalidade |
| --- | --- |
| Raiz | `scoring_version: 1`, `wallet_points: 0` inicialmente |
| `rewards[id]` | `claimed`, `amount`; conclusões anteriores recebem identificação `legacy` quando necessário |
| `level_stats[id]` | `last_score`, `best_score`, `last_elapsed_sec`, preservando erros, engrenagens, contagem de conclusões e demais campos |

Antes da primeira conclusão, ProgressStore verifica simultaneamente `completed_levels` e o marcador de recompensa. Depois salva conclusão, recordes, carteira e claim na mesma operação. Repetir a notificação de conclusão, reiniciar, recarregar o save ou vencer com score maior não concede outra recompensa. Uma falha na gravação restaura os dados anteriores em memória e não apresenta a recompensa como creditada.

Saves sem `scoring_version` mantêm os desbloqueios que a regra anterior já permitiria inferir de conclusões existentes. Conclusões antigas são consideradas com recompensa coletada, com valor retroativo zero. Engrenagens conhecidas são mantidas; conclusões sem dados suficientes continuam como `Sem nota` e contam zero para novos requisitos até um replay registrar desempenho real. Não há estimativa artificial de nota, tempo ou score antigo. Configurações e campos adicionais permanecem preservados.

Replay pode melhorar `best_score` e `best_gears`, mantendo os maiores valores. A soma global usa apenas a melhor nota de cada fase, portanto duas para três engrenagens acrescenta exatamente uma. O modal informa recompensa já coletada, recorde e eventual ganho de engrenagens, sem destacar `+0 pontos`.

O feedback usa Labels e Tweens locais, limitados a três popups simultâneos de especialistas. Sequências mais altas recebem ênfase discreta; na vitória, duas engrenagens recebem pulso menor que três. Os efeitos alteram posição, escala e opacidade, sem alterar a geometria dos Containers.

## Seasons independentes

[seasons.json](../game/data/seasons.json) define IDs, nomes e listas explícitas de fases. Foram configuradas quatro seasons de 15 fases como ponto inicial, sem referência a `product`, veículos ou separadores. A coincidência inicial entre intervalos de seasons e produtos não é uma dependência da lógica; os testes também usam uma season abrangendo fases de produtos diferentes e seasons de tamanhos diferentes.

Requisitos atuais: Season 1 aberta; Season 2 requer 32 engrenagens globais; Season 3 requer 64; Season 4 requer 96. O cálculo soma o arredondamento de cada quota individual. Uma season de 15 fases seguida de outra de 20 produz requisito de 74 para a terceira, não um percentual arredondado do total agregado.

O avanço continua sequencial e a nova quota atua como requisito adicional. Se a fase de fronteira foi concluída com nota insuficiente, seu resultado informa o requisito e desabilita Próxima fase. Menu e replay continuam disponíveis. Melhorar uma fase anterior pode liberar a fronteira pendente e atualizar Continuar automaticamente. O saldo da carteira nunca participa dessa decisão. Desbloqueios já existentes não são reduzidos ao carregar um save ou mudar temporariamente o catálogo.

## Arquivos novos e modificados

Novos: `game/scripts/scoring_rules.gd`, `game/data/seasons.json`, `game/tests/test_scoring.gd` e este relatório; o Godot gera os arquivos `.uid` associados aos scripts.

Modificados no runtime: `game_state.gd`, `board_input.gd`, `progress_store.gd`, `world_catalog.gd`, `level_loader.gd`, `main.gd` e `game.gd`, conforme a auditoria acima. Modificados para validação: `Testar.ps1`, `test_persistence.gd`, `test_campaign.gd` e `tests/test_campaign_generation.py`. Documentação relacionada: README, SAVE_FORMAT, GAME_DESIGN e PROJECT_CONTEXT.

O cenário sintético de travessia das fronteiras no teste de campanha recebeu notas suficientes para as novas quotas. O teste de IDs esparsos declara uma season própria para seus IDs 10 e 30, sem confundi-los com a configuração real da campanha. O comportamento das 60 fases e dos separadores continua sendo testado em cenas reais.

## Validação

Comando completo: `powershell -NoProfile -ExecutionPolicy Bypass -File .\Testar.ps1 -Render`.

Execução final concluída com código 0:

| Verificação | Resultado |
| --- | --- |
| Solver independente | 60 fases válidas e com solução única |
| Python | 28 testes aprovados |
| Integração e progressão nas 60 fases | 574 verificações aprovadas |
| Persistência entre processos | 10 de escrita e 14 de reabertura aprovadas |
| Preview e layouts | 52 verificações aprovadas |
| Campanha, home e separadores | 325 verificações aprovadas |
| Scoring, carteira, tempo e seasons | 105 verificações aprovadas |
| Integridade | 68 hashes preservados, incluindo 60 JSONs, board, células, fronteiras, catálogo de produtos, configuração do projeto, solver e gerador |

Total Godot: 1.080 verificações, sem falhas. Não há erros de script, referências inválidas ou avisos de vazamento nos logs finais. O único warning do runtime é o teste já existente que abre deliberadamente um save de versão futura e confirma sua preservação sem sobrescrita. Os saves de teste usam `user://tests/`; o save pessoal não foi aberto pela aplicação durante a validação.

O board permaneceu em 548×548 px na janela 1100×820 e 759×759 px em 1448×1086. O importador do editor normalizou automaticamente `project.godot` durante os testes; ao terminar, seus bytes originais foram restaurados a partir do backup desta etapa e conferidos por hash. Nenhuma mudança de configuração de renderização integra esta entrega.

O novo teste cobre especialistas consecutivos até o sexto e além do teto, resets, erro sem desconto de pontos, grupos de 1 a 6 X, grupo parcialmente incorreto, proteção contra repetição, limites temporais exatos e imediatamente acima/abaixo, relógio pausado e sem foco, conclusão, carteira, replay, recordes, migração, rollback em falha de save e requisitos 31/32 e 63/64.

As cenas reais também verificam duplos cliques sem X fantasma, um arraste longo de cinco células com quatro X corretos, parada do tempo antes do modal, recompensa e replay em 360×700, fronteira de season bloqueada, bloqueio pela API, ordem da home e rolagem. A regressão existente cobre input no viewport, vidas, fixos, erros permanentes, regras, layout desktop/mobile, 60 conclusões, notas e separadores, além da persistência em processos separados.

Evidências locais em `artifacts/`, ignorado pelo Git:

- [Suíte completa](../artifacts/scoring-full-suite.log) e [relatório de scoring](../artifacts/scoring_tests.json).
- [Conferência dos 68 hashes](../artifacts/scoring-protected-check.json).
- [Primeira vitória desktop](../artifacts/scoring_first_win_desktop.png), [mobile](../artifacts/scoring_first_win_mobile.png) e [replay mobile](../artifacts/scoring_replay_mobile.png).
- [Bloqueio de season em mobile](../artifacts/scoring_season_gate_mobile.png).

## Limites e balanceamento futuro

1. A fórmula quadrática de X favorece grupos grandes. Como X incorretos são neutros, marcar uma grande área sem raciocinar pode render muitos pontos quando a fase for concluída. A proteção por posição impede repetição, mas não elimina esse incentivo. Um teto ou critérios adicionais exigem decisão de game design; não foram inventados nesta tarefa.
2. O bônus temporal máximo de 500 pode superar os pontos de especialistas em fases curtas. Por isso as referências atuais permanecem sem calibração, com bônus zero, até haver dados de playtest.
3. A primeira conclusão fixa a recompensa econômica para sempre. Um replay perfeito melhora recordes e engrenagens, mas não compensa uma primeira conclusão inferior com moedas adicionais. É uma consequência intencional da regra solicitada.
4. Notas desconhecidas de saves antigos não são fabricadas. Novas quotas posteriores ao desbloqueio preservado podem exigir replay dessas fases.
5. O save permanece local. Não há autenticação ou proteção contra edição manual dos arquivos. Loja, backend, cosméticos e novas mecânicas estão fora do escopo.
6. A adaptação mobile é validada por janelas Windows redimensionadas, sem exportação nem teste em aparelho físico.

## Integração visual v2

Na v2, end_x_action apenas registra posições e grupos. A consulta à solução e a fórmula dos X são executadas em finish_score, após a vitória. Isso preserva os valores finais e evita qualquer avaliação de anotações durante o puzzle. A mesma sequência de teste continua rendendo 1.391 pontos. A home distingue soma dos recordes de saldo da carteira; nenhuma regra econômica ou quota de season foi alterada. Validação atual em VISUAL_VALIDATION.md; números anteriores deste relatório são históricos.
