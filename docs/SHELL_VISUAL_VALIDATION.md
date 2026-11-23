# Identidade compartilhada: Home, gameplay e Results

Escopo desta etapa: apresentação desktop em 16:9 e timing visual da conclusão. A identidade aprovada do gameplay foi reutilizada. Não houve revisão da campanha, regras, geração, score ou save. O teste usa um save próprio em `user://tests/ui-shell.json`; não modifica o progresso pessoal.

## Home

Uma única superfície estrutural de glass, com o shader, blur, borda e sombra já usados no gameplay, envolve a pontuação e a coluna de fases. A primeira tentativa mantinha a pontuação muito horizontal; a versão final usa um card vertical à esquerda, com total em destaque e carteira secundária. A próxima fase e o histórico ficam à direita, preservando a árvore e a ordem original de PhaseHistory.

A marca usa o mesmo símbolo, wordmark, fonte, escala e tratamento do gameplay aprovado. O CTA usa o gradiente, lip, highlight e estados do botão Reiniciar. O carro ganhou enquadramento sobre a plataforma existente. As linhas de replay mantêm densidade, engrenagens e botões secundários com volume. A barra de rolagem tem trilho transparente, thumb arredondado a 23% e opacidade maior no hover/drag.

Separadores continuam após `first_level`, inclusive quando a fase destacada é o início de um produto. O próximo nível não é duplicado no histórico. O botão de saída conserva seu sinal e sua ação, agora dentro de uma superfície com volume.

## Results

O modal mantém dados, textos de origem, quantidade de engrenagens, nomes de nós e ações. A apresentação acrescenta creme com gradiente, lip, realce, medalhão para o check, cabeçalho mais forte, carro maior sobre a plataforma compartilhada e engrenagens da mesma classe/arte das vidas.

`ScoreSummary` permanece intacto como fonte de dados e tooltip. Um RichTextLabel apresenta esse texto com hierarquia, destacando a linha de pontos recebidos. Não se calcula score ou multiplicador no componente visual. Replay, recompensa já coletada, requisito de temporada e aviso de save continuam usando os dados originais.

O CTA principal usa o mesmo material laranja do gameplay, com texto Barlow mais forte. As duas ações secundárias reutilizam o mesmo componente creme empregado no replay da Home. A plataforma tem largura própria, centralizada no carro, evitando um disco excessivamente largo.

O fundo usa cópia da tela, blur leve, saturação 0,88, dim 0,28 e tint navy discreta. A entrada ocorre progressivamente; não é apenas uma camada uniforme azul/preta. O board concluído continua reconhecível.

## Sequência visual

| Tempo de referência | Apresentação |
| --- | --- |
| 0 s | A vitória, score, progressão e save são confirmados pelo fluxo original |
| 0–0,35 s | Pop da última peça, popup de pontos, highlight e atualização da faixa |
| 0,35–0,65 s | Pausa de leitura |
| 0,65–1,40 s | Micro-pop nas faces dos tiles, brilho de moldura e até 28 partículas pequenas |
| 1,40–1,90 s | Estado final concluído, sem deslocamento das células |
| 1,90–2,20 s | Transição do fundo com blur, dim e tint |
| Aproximadamente 2,20 s | Abertura do modal, seguida do fade nativo |

A onda usa escala máxima 1,035, duração individual 220 ms e intervalo de 35 ms por soma de linha/coluna. Só o quad visual da peça é escalado. Retângulos das células, roteamento de input e modelo permanecem iguais. O glow desenha somente a borda; uma sombra que tingia o interior foi removida na revisão visual.

O prazo usa relógio monotônico da apresentação para evitar acúmulo de delta de frames. Não avança o relógio de gameplay, que já está parado na vitória. Reduzir movimentos suprime a onda e as partículas, mantendo uma pausa calma. Sair durante a sequência cancela a apresentação sem abrir modal sobre outra tela. No fluxo mobile legado, o timing anterior foi preservado.

## Componentes reaproveitados

- `glass_surface.gd`, `frosted_glass.gdshader` e captura do fundo usada no gameplay.
- `ui_skin.gd`, `ui_desktop_refinement.action_skin`, receita de Reiniciar e materiais creme.
- Símbolo e tratamento de wordmark aprovados, Barlow dos rótulos e as fontes existentes.
- `production_stage.gd`, PNGs dos veículos, ícones de check/saída/fábrica e `gear_indicator.gd`.
- Dados e callbacks originais de Home e Results.

## Componentes novos

- `ui_shell.gd`: estilos compartilhados de cards/botões/marca e restauração dos Controls legados.
- `ui_home.gd`: aplicação dos estilos e geometria desktop à Home existente.
- `ui_results.gd` e `ui_result_fit.gd`: apresentação do resultado e encaixe após o layout dos Containers.
- `ui_completion.gd`: sequência visual com deadline, onda, glow e partículas leves.
- `ui_result_backdrop.gdshader`: blur, saturação, tint e escurecimento progressivos.
- `test_ui_shell.gd`: teste da integração visual, timing e invariância dos resultados.

Os valores novos estão em `ui_tokens.gd`: grupos SHELL, HOME, HOME_DECORATION, RESULTS, RESULT_PLATFORM_WIDTH e COMPLETION. Não foram criadas cores, fontes ou assets para uma identidade separada.

## Evidências

[Home](../artifacts/shell_home_1920x1080.png), [gameplay](../artifacts/shell_gameplay_1920x1080.png), [Results](../artifacts/shell_results_1920x1080.png), [três telas lado a lado](../artifacts/shell_three_screens.png) e [sequência da conclusão](../artifacts/shell_completion_sequence.png).

Na inspeção lado a lado, as três telas compartilham fábrica, navy, creme, tipografia, botões, engrenagens, gradientes, bordas e profundidade. A Home tem composição de seleção e o resultado tem composição de recompensa, dentro do mesmo sistema visual. Esta é uma avaliação visual das capturas, não uma afirmação de aprovação pelo usuário.

## Diferenças e limites

- O check permanece um vetor existente dentro de um medalhão com volume; não foi criada uma ilustração 3D exclusiva.
- Plataforma, partículas e brilho são elementos nativos leves. A profundidade é 2.5D; não há física nem pedestal 3D.
- O efeito de blur pode variar entre renderers. A evidência desktop nativa não substitui uma validação em navegador; o preset Web existente tinha um bloqueio de exportação anterior a esta tarefa.
- Mobile não foi redesenhado. Foram preservados seus fluxos e mantidas as regressões existentes de resize.
- Nenhum ponto visual exigiu mudar campanha, score, save ou regras. As únicas integrações no código existente são chamadas de apresentação em Home/Results e a substituição da espera visual anterior pela sequência solicitada.

Logs e integridade: [execução inicial](../artifacts/shell-full-suite.log), [retomada das suítes](../artifacts/shell-remaining-tests.log), [teste visual final](../artifacts/shell-ui-tests.log), [timing](../artifacts/shell_ui_tests.json) e [hashes/métodos](../artifacts/shell_integrity.json).

## Fechamento técnico

A validação inicial identificou overflow do modal de desbloqueio após reduzir a janela de desktop para retrato. O encaixe agora usa o viewport real para escala e centralização, inclusive quando o mínimo do Container excede a área disponível. Campanha, pontuação e layouts foram repetidos após essa correção.

O teste de animação também foi corrigido para medir prazos monotônicos e observar a atualização após `Node._process`, pois `SceneTree.process_frame` retoma antes dela. Isso evita amostrar o frame anterior em máquinas com renderização lenta. A animação continua usando o prazo visual de 2,20 s.

A conferência de integridade compara 118 arquivos da base anterior: 111 estão idênticos e sete contêm apenas as integrações visuais, tokens e ajustes de espera dos testes. Os 78 arquivos protegidos da validação anterior também permanecem idênticos. Ao reverter somente a chamada de estilo e a nova espera de comemoração em `game.gd`, seu conteúdo coincide integralmente com a cópia anterior; o mesmo ocorre em `level_select.gd` ao retirar a chamada visual. Não foram alterados backend, níveis, assets PNG, cenas ou persistência.

Resultado final: **1.326 verificações Godot e 28 testes Python aprovados**. MVP 574; persistência 24; preview 56; campanha 325; scoring 108; layout V2 137; referência 65; integração Home/Results 37. Abertura do modal observada em **2,273 s** e overlay observado em 2,050 s. As capturas da comemoração são realizadas em um replay separado para que o readback da GPU não interfira na medição temporal.

A execução completa inicial parou na regressão de encaixe. Após a correção, foram repetidas campanha e todas as suítes seguintes; o teste Shell teve uma última execução independente após corrigir sua amostragem. Os logs das tentativas anteriores foram mantidos. [Consolidação dos resultados](../artifacts/shell_validation_final.json). Validação nativa em 1920 × 1080, D3D12 Forward+; navegador não validado nesta etapa.
