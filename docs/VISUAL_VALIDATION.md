# Validação do refinamento desktop

Etapa vigente: [refinamento P1/P2/P3 e validação em 16:9](REFERENCE_VISUAL_REFINEMENT.md). Os registros anteriores abaixo são históricos quando divergem dessa especificação.

Escopo: proporções, materiais e alinhamentos desktop. Mecânicas e adaptação mobile não foram redesenhadas. Referência: [master industrial](<reference/Interface de Jogo Machidoku Industrial.png>), 1672×941. Capturas de puzzles reais, sem reproduzir os estados impossíveis da ilustração.

## Correções verificadas

- Configurações: fundo circular 66×66 sem nove partes; ícone 36 centralizado horizontal e verticalmente. Hover, pressed e foco continuam nativos.
- Cards: fonte procedural 256×256 com área suficiente para os cortes; margens dos cantos não se sobrepõem no destino. Face clara com opacidade 0,88, borda, highlight interno e sombra discreta. O raio da sombra do glass acompanha seu material; LOD do fundo reduzido de 3,2 para 2,6.
- Board: aro e bezel com StyleBoxFlat e curvas contínuas nos quatro cantos. Mesmas dimensões internas e mesmo sistema de picking.
- Especialistas: margem desktop max(3, lado×0,025), reserva de escala visual 1,04 e 1 px interno; altura normal superior a 82% do tile. Clip continua como proteção, com teste de contenção do próprio retângulo durante o maior pop. O fluxo de animação/estado não foi alterado.
- Rodapé: comandos em linha única com largura natural; conjunto centralizado; score adjacente com gap 16. A mensagem principal continua abaixo, sem sobreposição.
- Produção: padding horizontal 16, superior 12 e inferior 20. Nota afastada da borda inferior em pelo menos 18 px; veículo e base compartilham o centro horizontal.
- Identificação da fase: carro centralizado verticalmente, título alinhado às legendas, dificuldade com ícone 44, padding 12 e raio 25. Vidas com altura 78 e raio 26. Ícones das regras em coluna de largura constante, altura 40 e menor opacidade.

## Testes

Comando: `powershell -NoProfile -ExecutionPolicy Bypass -File .\Testar.ps1 -Render`.

| Grupo | Resultado |
| --- | --- |
| Python e assets | 28 testes aprovados |
| Fases offline | 60 válidas, conectadas e com solução única |
| Regras, input e progressão | 574 verificações |
| Persistência | 10 de escrita e 14 de reabertura |
| Preview e rolagem da planta | 56 verificações |
| Campanha, replay e separadores | 325 verificações |
| Pontuação, carteira e seasons | 108 verificações |
| Apresentação desktop e regressão existente | 137 verificações |

Total Godot: **1224 verificações, zero falhas**. Adicionalmente, as mesmas **137 verificações de apresentação passaram no renderer Compatibility/OpenGL**, incluindo compilação e execução dos shaders. A suíte inclui regressões mobile preexistentes; isso não representa trabalho de adaptação mobile nesta etapa.

As novas verificações cobrem formato do botão, alinhamento do ícone, cortes das texturas, gap do score, altura da barra, espaço inferior da nota, centro do veículo e ocupação/limites dos retratos. Foram inspecionadas capturas em 1672×941 e 1920×1020; o teste também verifica safe frame ultrawide e redimensionamento. Não se afirma correspondência pixel-perfect.

78 arquivos protegidos mantêm seus hashes: lógica do Board/Input/GameState, persistência, scoring, campanha, 60 fases, catálogos e PNGs. Treze métodos de comportamento de Game/Cell também permanecem idênticos. Project.godot foi restaurado após normalização do editor. Os testes usam saves próprios em user://tests/.

## Evidências e limite Web

[Desktop](../artifacts/polish_desktop.png), [Sedan com sete setores](../artifacts/polish_7_sectors.png), [1920×1020](../artifacts/polish_1920x1020.png) e [antes/depois da fase Sedan](../artifacts/polish_before_after.png). Comparação com o master: [lado a lado](../artifacts/master_comparison.png) e [sobreposição](../artifacts/master_overlay_50.png).

[Suíte completa](../artifacts/polish-full-suite.log), [renderer Compatibility](../artifacts/polish-compatibility.log) e [integridade](../artifacts/polish_integrity.json).

O preset Web existente recusou a exportação por erro de configuração. Uma cópia isolada com renderer Compatibility também recusou o preset. Templates locais foram encontrados pelo próprio engine; a causa específica da validação do preset não foi determinada nesta etapa. Portanto, não houve validação efetiva em navegador. A inspeção OpenGL nativa reduz a incerteza de shader, mas não substitui essa validação. A configuração original de exportação foi preservada, sem publicação externa.
