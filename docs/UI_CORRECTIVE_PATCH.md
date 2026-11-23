# Patch pontual de UI

O patch altera apresentação, mantendo os Controls, nomes, sinais e callbacks existentes.

- Home: track navy com 10% de opacidade e thumb creme arredondado, com 28% em repouso, 58% em hover e 75% durante o arraste. Largura de 8 px na referência 1672 × 941. O painel externo foi preservado.
- Gameplay: Menu, coluna esquerda e instruções compartilham x = 179 e largura = 310 na referência. A base das instruções é y = 806, igual à base da moldura do board. O board mantém posição e tamanho.
- Setores: tile reduzido de aproximadamente 58 para 44 px; desenho interno de aproximadamente 44 para 28 px. Cards mantêm 64 px de altura, com margens laterais de 14 px e centralização vertical.
- Configurações: material compartilhado com Home/Results, creme quente, navy, Barlow, bordas arredondadas, lip, botão Fechar laranja e checkbox com gradiente e volume. O overlay reutiliza o blur e dim de Results. Os estados marcado/desmarcado pertencem ao CheckBox original.

Os valores novos estão em `ui_tokens.gd`. `ui_options.gd` concentra a apresentação do modal; `game.gd` recebe somente duas chamadas de estilo, na abertura e no redimensionamento. O handler de `toggled`, persistência, suspensão do relógio e callback de Fechar permanecem intactos.

## Capturas

- [Home](../artifacts/ui_patch_home_1920x1080.png) e [fim da lista](../artifacts/ui_patch_home_bottom_1920x1080.png).
- [Gameplay](../artifacts/ui_patch_gameplay_1920x1080.png).
- [Configurações](../artifacts/ui_patch_options_1920x1080.png) e [opção marcada](../artifacts/ui_patch_options_checked_1920x1080.png).
- [Configurações em 1366 × 768](../artifacts/ui_patch_options_1366x768.png) e [encaixe em 360 × 700](../artifacts/ui_patch_options_360x700.png).

## Verificação

As capturas foram geradas pelo Godot nativo em 1920 × 1080, D3D12 Forward+. O arquivo de QA usa um save isolado em `user://tests/ui-patch.json`. Foi verificado que a lista chega ao final, a opção persiste após fechar/reabrir e recarregar o save, o relógio fica suspenso no modal e puzzle, vidas e carteira permanecem iguais.

[Geometria e comportamento observados](../artifacts/ui_patch_measurements.json). A validação nativa não representa uma validação em navegador.

Resultado: **295 verificações aprovadas**, sem falhas, nas suítes existentes de preview (56), layout V2 (137), referência (65) e Home/Results (37). Importação Godot e `git diff --check` também passaram.

Comparação com a cópia anterior ao patch: 135 de 139 arquivos permanecem idênticos, incluindo testes, níveis, dados, backend, assets PNG e scripts de lógica. Os quatro arquivos existentes alterados contêm tokens, estilos e as duas chamadas de apresentação. Há um novo script visual, `ui_options.gd`. [Integridade e logs das suítes](../artifacts/ui_patch_integrity.json).
