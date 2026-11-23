# Home integrada, engrenagens e regras à esquerda

Registro histórico anterior à v2. Apresentação e evidências atuais: [VISUAL_VALIDATION.md](VISUAL_VALIDATION.md).

Entrega de 20/10/2026 em `.`.

## Campanha preservada

O workspace já continha 60 fases Automotive: Hatch Compact 01 a 15, Sedan 16 a 30, SUV 31 a 45 e Sport Coupe 46 a 60. Todos os JSONs foram preservados e revalidados pelo solver. Não foi necessário gerar ou substituir fases nesta etapa. O catálogo central e o pipeline offline também permaneceram intactos.

Desbloqueios 15 para 16, 30 para 31 e 45 para 46 continuam funcionando. Geração de futuros lotes e regeneração isolada de produtos seguem documentadas em [GENERATION.md](GENERATION.md).

## Home e histórico

A apresentação de level_select.gd foi adaptada para ser a própria home, instanciada por Main.show_menu. Não há botão ou página separada de seleção nem grades horizontais por produto.

- Branding no topo e botão Sair somente com ícone, no canto direito.
- Um card principal mostra Próxima fase, ID, produto, mundo e Jogar Fase XX.
- Abaixo dele aparece um histórico de uma coluna em ordem decrescente.
- Cada linha contém fase, melhor nota e Jogar novamente ou Jogar, sem descrição longa.
- Todos os produtos recebem seus separadores imediatamente após sua primeira fase, encerrando o bloco descendente. Na fase 18: card 18, fases 17 e 16, separador Sedan, fases 15 até 1 e separador Hatch. Na fase 16: card 16, separador Sedan, fases 15 até 1 e separador Hatch.
- O histórico mostra fases anteriores desbloqueadas; fases futuras bloqueadas não aparecem. Main mantém a verificação de acesso.
- Ao voltar à home, a lista é reconstruída com a fase atual no topo e scroll em zero.
- Depois de concluir a fase 60, seu card continua permitindo replay e mostra sua melhor nota.

A largura do conteúdo é limitada no desktop e adapta-se ao portrait. A rolagem é vertical. O CTA atual e o ícone Sair foram verificados também no mínimo 360×700.

## Engrenagens e compatibilidade

| Desempenho na vitória | Nota |
| --- | --- |
| Nenhum erro | 3 engrenagens |
| Um erro | 2 engrenagens |
| Dois erros | 1 engrenagem |
| Três erros | Derrota, sem conclusão ou nota |

A nota usa as vidas perdidas na vitória real do GameState. O popup mostra a tentativa atual; a home mostra a melhor nota histórica. Em level_stats[id], last_gears registra a tentativa e best_gears só aumenta. Os campos de erros e contagem de conclusões continuam disponíveis. Replay preserva o maior desbloqueio e o cursor da campanha.

O save permanece na versão 1, com campos aditivos. Registros antigos com best_errors válido recuperam a nota correspondente. Se uma conclusão não contém dados de desempenho, aparece Sem nota até o replay. Não é atribuída uma nota de zero ou três sem evidência. Configurações e outras estatísticas são preservadas.

Vidas continuam limitadas a três e mantêm sua lógica e pulso existentes. O novo componente nativo gear_indicator.gd desenha a mesma família de engrenagens em vidas e notas, com preenchimento para as ativas e contorno para as vazias. Não foram criados PNGs, SVGs ou fontes.

## Ganho de área no desktop

Produto, fase, três regras empilhadas e vidas ficam em uma coluna estreita à esquerda. O painel da planta permanece à direita. A remoção da antiga faixa de título/regras libera altura para o board.

| Janela | Board anterior | Board atual | Ganho aproximado de área |
| --- | --- | --- | --- |
| 1100×820 | 466×466 px | 548×548 px | 38% |
| 1448×1086 | 661×661 px | 759×759 px | 32% |

As dimensões atuais foram medidas nas cenas reais pelo teste de campanha. Os valores anteriores e as capturas foram preservados em artifacts/home-before. Em portrait, os mesmos componentes retornam à composição acima do board; as regras continuam visíveis e os detalhes da planta ficam recolhíveis abaixo.

## Arquivos desta etapa

Alterados:

- game/scripts/main.gd: home integrada e remoção da navegação separada.
- game/scripts/level_select.gd: adaptação da apresentação existente para card atual e histórico vertical.
- game/scripts/progress_store.gd: cálculo, melhor nota, leitura compatível e preservação de estatísticas.
- game/scripts/life_indicator.gd: reutilização das engrenagens sem alterar a API de vidas.
- game/scripts/game.gd: coluna esquerda, responsividade e nota no popup.
- game/tests/test_campaign.gd: home, separadores, acesso por rolagem, notas, replay e layout.
- game/tests/test_persistence.gd: pontuação entre processos.
- PROJECT_CONTEXT, GAME_DESIGN, GENERATION, SAVE_FORMAT, VISUAL_TARGET e README.

Novos: game/scripts/gear_indicator.gd, seu arquivo .uid e este relatório. Os arquivos anteriores não relacionados à tarefa, incluindo project.godot, foram preservados.

## Testes finais

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Testar.ps1 -Render
```

| Verificação | Resultado |
| --- | --- |
| Solver independente | 60 fases válidas, conectadas e com solução única |
| Python | 27 testes aprovados |
| Integração Godot e progressão pelas 60 fases | 574 verificações aprovadas |
| Persistência em processos separados | 8 de escrita + 11 de reabertura aprovadas |
| Preview e layouts | 52 verificações aprovadas |
| Campanha, home, notas e replay | 325 verificações aprovadas |
| Integridade dos arquivos protegidos | 72 hashes conferidos, nenhum alterado |

Total após a correção dos separadores: 27 testes Python e 970 verificações Godot, incluindo gravações de capturas. O processo final terminou com código 0. Os saves de teste são isolados em user://tests/; o save pessoal não foi alterado.

Foram verificados os estados de nota 3, 2 e 1, preservação do recorde em replay pior, melhoria posterior, derrota sem nota, save antigo, conclusão sem dados históricos, nota persistida em outro processo, ordenação e separadores nas fases 1, 16, 18, 31, 32, 42, 46, 47 e 60, além de retorno da home ao topo. O teste de input existente continua cobrindo X neutro, ERROR_X, vidas, fixos, duplo clique e arraste.

O Godot executou as cenas reais em Windows, Forward+ / Direct3D 12, Intel UHD Graphics 620. Não foram modificados GameState, BoardInput, Board, Cell, fronteiras, solver, analisador, catálogo ou gerador. Os 60 JSONs permanecem idênticos aos anteriores.

## Evidências locais

- [Home da fase 16 no desktop](../artifacts/home_phase16_desktop.png) e [portrait](../artifacts/home_phase16_portrait.png).
- [Home da fase 42 no desktop](../artifacts/home_phase42_desktop.png) e [mínimo 360×700](../artifacts/home_phase42_minimum.png).
- [Campanha concluída com nota da fase 60](../artifacts/home_completed_minimum.png).
- [Gameplay desktop](../artifacts/campaign_game_desktop.png), [1448×1086](../artifacts/campaign_game_large.png) e [antes](../artifacts/home-before/campaign_game_desktop.png).
- [Popup de desbloqueio em portrait](../artifacts/campaign_unlock_portrait.png).
- [Suíte final](../artifacts/separators-final-suite.log), [resultados da campanha](../artifacts/campaign_tests.json) e [integridade](../artifacts/separators-protected-check.json).

artifacts/ é ignorado pelo Git; as evidências permanecem no workspace local.

## Correção dos separadores

O marcador do produto atual deixou de ser inserido automaticamente abaixo do card destacado. Tanto esse card quanto cada linha do histórico passam pela mesma verificação: inserir o separador somente se o ID renderizado for `product.first_level`. Isso posiciona Sedan entre 16 e 15, SUV entre 31 e 30, Sport Coupe entre 46 e 45 e Hatch Compact após 1. Quando a próxima fase é 16, 31, 46 ou 1, o respectivo marcador aparece imediatamente após o card destacado, sem duplicar a fase.

WorldCatalog deriva `first_level`, `last_level` e `vehicle_asset` de `start_id`, `level_count` e `asset` no catálogo compartilhado. O separador usa `display_name` e `vehicle_asset` do produto. Não há IDs fixos na lógica de renderização nem duplicação dos intervalos no JSON. As regras do jogo, progressão e notas permanecem preservadas.

O teste de campanha verifica a sequência completa de fases e marcadores, as quatro fronteiras explicitamente, os primeiros níveis destacados e fases intermediárias 18, 32 e 47. A suíte completa passou, incluindo 325 verificações de campanha. Os 72 hashes protegidos continuam idênticos ao baseline. Evidências atualizadas: [home da fase 18](../artifacts/home_phase18_desktop.png), [home da fase 16](../artifacts/home_phase16_desktop.png) e [suíte da correção](../artifacts/separators-final-suite.log).

## Limitações

SUV continua com o placeholder já previsto no catálogo. Registros antigos sem dados de desempenho precisam de replay para receber uma nota. A responsividade foi testada por redimensionamento no Windows, sem exportação ou teste em aparelho físico. A classificação de dificuldade dos lotes permanece uma heurística editorial sujeita a playtest.
