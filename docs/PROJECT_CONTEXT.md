# Machidoku — Project Context

## Objetivo

Machidoku é um puzzle lógico com identidade industrial.

A estrutura lógica é inspirada em puzzles de restrições simples que geram deduções encadeadas. O jogo deve ter poucas regras explícitas, mas permitir raciocínio profundo.

---

## Regras do modo normal

Para um tabuleiro `N x N`:

1. existe exatamente **1 especialista por setor**;
2. existe exatamente **1 especialista por linha**;
3. existe exatamente **1 especialista por coluna**;
4. especialistas **não podem se tocar**, incluindo diagonalmente;
5. o tabuleiro possui exatamente `N` setores e `N` especialistas;
6. cada setor deve ser ortogonalmente conectado.

---

## Semântica de input

### Clique simples em célula vazia
Adiciona um X normal.

### Clique simples em X normal
Remove o X.

### Arraste iniciado em célula vazia
Entra em modo de marcação e adiciona vários X.

### Arraste iniciado em X normal
Entra em modo de remoção e apaga vários X.

### Duplo clique
Tenta posicionar um especialista.

Se correto:
- especialista é colocado;
- microanimação de pop pode ser aplicada.

Se incorreto:
- perde uma vida;
- célula vira `ERROR_X`;
- `ERROR_X` é permanente naquela tentativa.

### Regra importante sobre X normal

O X normal é apenas uma anotação do jogador.

Ele **não deve ser validado contra a solução escondida**.

Portanto, é permitido ao jogador colocar um X normal numa célula que realmente contém um especialista sem perder vida e sem receber qualquer pista automática.

### Especialistas pré-posicionados

São fixos e não removíveis.

---

## Vitória

Não é necessário preencher todos os X.

A fase termina quando todos os especialistas corretos foram posicionados e as restrições da fase estão satisfeitas.

---

## Vidas

Modo normal:

- 3 vidas;
- tentativa incorreta de especialista consome 1 vida;
- X normal nunca consome vida.

---

## Mundo atual

### Mundo
`Automotive`

### Produto inicial
`Hatch Compact`

Campanha Automotive ativa com 60 fases em quatro produtos:

- 01 a 15: Hatch Compact;
- 16 a 30: Sedan;
- 31 a 45: SUV;
- 46 a 60: Sport Coupe;
- dificuldade variável;
- grids aproximadamente de 5x5 até 9x9;
- fases fáceis podem conter especialistas pré-posicionados;
- dificuldade não depende apenas do tamanho do grid.

---

## Setores industriais atuais

Conjunto visual/temático pode incluir:

- Chaparia;
- Soldagem;
- Pintura;
- Elétrica;
- Montagem;
- Inspeção;
- Logística;
- Testes;
- Powertrain.

Os nomes de setores são tema visual. As regras lógicas continuam sendo as mesmas.

---

## Progressão futura

Estrutura de mundos planejada:

1. Automotive;
2. Aerospace;
3. Shipyard;
4. Rail;
5. Advanced Industry.

O catálogo compartilhado em game/data/campaign.json define mundos, produtos, nomes, assets e blocos. Python e Godot leem a mesma fonte; novos mundos e produtos não exigem reescrever o loader. Cada produto Automotive ativo tem 15 fases fixas em JSON.

Exemplo no mundo Automotive:

- Hatch Compact;
- Sedan;
- SUV;
- Sport Coupe;
- outros produtos futuramente.

---

## Arquitetura atual

### Engine
Godot 4

### Linguagem do jogo
GDScript

### Ferramentas offline
Python 3.13

### Estrutura geral

- Godot executa fases fixas;
- Python gera/valida fases offline;
- níveis são armazenados em JSON;
- solver verifica validade e unicidade;
- geração procedural não ocorre durante a partida.

Fluxo desejado:

`generator -> solver -> unique solution validation -> difficulty classification -> JSON -> Godot`

---

## Persistência

O jogo deve manter progresso local.

Estado mínimo:

- `highest_unlocked_level`;
- `current_level`;
- `completed_levels`.

Ao sair da fase 2 e voltar ao menu, Continuar abre a fase 2. Selecionar/repetir uma fase antiga não reduz highest_unlocked_level nem muda o destino de Continuar. Produtos concluídos são derivados de completed_levels. Saves versão 1 continuam compatíveis; concluir o Hatch antigo libera a fase 16 ao reconciliar o catálogo ampliado.

---

## Geração de fases

O gerador Python publica somente puzzles válidos, de solução única e resolvidos pelo analisador lógico. Aceita --world, --product, --count, --start-id, --profiles, --output e --seed. Comandos em docs/GENERATION.md.

O solver deve validar:

- número de setores;
- conectividade dos setores;
- uma peça por linha;
- uma peça por coluna;
- uma peça por setor;
- não adjacência;
- solução única.

No longo prazo, a classificação de dificuldade deve considerar também técnicas de dedução humanas e profundidade de cadeias, não somente brute force.

---

## Microanimações atuais

Os assets figurativos continuam estáticos nesta fase.

Microanimações programáticas podem usar `Tween`:

- pop do especialista;
- fade/scale de X;
- remoção rápida de X;
- shake/flash em erro;
- pulso de vida;
- feedback de vitória.

Não implementar animação complexa de personagem ou veículo nesta etapa.

---

## Identidade visual

A referência visual oficial está documentada em:

`docs/VISUAL_TARGET.md`

Imagem principal:

`docs/reference/Interface de Jogo Machidoku Industrial.png`

A implementação deve seguir essa direção.

---

## Paleta principal

- `#FFE6CF`
- `#FF871C`
- `#E76F51`
- `#07365A`
- `#07244B`

---

## Ambiente de desenvolvimento atual

Novo caminho do projeto no Windows:

`.`

O projeto deve usar caminhos relativos sempre que possível e não depender do caminho antigo:

`D:\Projetos\Machidoku`

Python do projeto:

`3.13.x`

Ambiente virtual:

`.venv`

Godot pode permanecer portátil em:

`engine/godot/Godot.exe`

---

## Restrições para futuras alterações

Não alterar sem solicitação explícita:

- regras centrais;
- semântica de X;
- semântica de `ERROR_X`;
- vidas;
- solver;
- formato geral da progressão;
- geração offline;
- persistência.

Refatorações visuais devem preservar a jogabilidade.

## Seleção, assets e layout desktop

A home integra toda a seleção em uma única lista vertical. O topo contém branding e ícone Sair; o primeiro card é Próxima fase, com fase, produto, mundo e Jogar Fase XX. Abaixo fica o histórico desbloqueado em ordem decrescente, com cada separador de produto após sua primeira fase. Não há página separada nem grades por produto. Cada linha contém fase, melhor nota e Jogar novamente ou Jogar.

A vitória oferece Próxima fase e Repetir fase; as transições 15 para 16, 30 para 31 e 45 para 46 nomeiam o produto liberado. Na fase 60, a ação principal volta ao menu.

Sedan e Sport Coupe reutilizam os PNGs existentes. O caminho de compatibilidade suv_placeholder.tres agora usa o SUV gerado para a v2, com imagem própria em vehicles/suv.png.

No desktop, produto, fase, regras empilhadas e vidas ocupam uma coluna estreita à esquerda. O cabeçalho anterior deixa de limitar a altura do board, que cresce mantendo a planta à direita. Portrait mantém regras em três cards acima do board e detalhes expansíveis abaixo.

## Engrenagens e histórico integrado

Vitória com zero, um ou dois erros rende respectivamente três, duas ou uma engrenagem. Derrota não registra conclusão nem pontuação. level_stats armazena last_gears e best_gears, além de last_errors e best_errors. Replay pode melhorar best_gears, mas nunca reduzi-lo ou regredir a campanha.

Vidas continuam sendo três; sua apresentação usa o mesmo componente nativo de engrenagens, preenchidas ou em contorno. O popup mostra a nota da tentativa atual; a home mostra a melhor nota histórica.

O save continua na versão 1. Registros antigos com best_errors recuperam a nota correspondente. Conclusões sem dados de desempenho aparecem como Sem nota até o replay, sem inventar uma nota de zero ou três.

Na home, a fase atual é o primeiro card e o scroll inicia em zero a cada retorno. Para a fase 18: card Fase 18, fases 17 e 16, separador Sedan, fases 15 até 1 e separador Hatch abaixo da fase 1. Todos os marcadores encerram blocos descendentes: são inseridos após `product.first_level`, inclusive quando essa fase é o próprio card destacado. WorldCatalog deriva `first_level`, `last_level` e `vehicle_asset` dos dados compartilhados, preservando `display_name`. A fase destacada não se repete no histórico; fases futuras bloqueadas não entram nessa lista.

As 60 fases e o pipeline offline já existiam nesta etapa e foram preservados, com nova validação. Não foi necessário gerar ou substituir JSONs para implementar a home e as notas.

## Pontuação e seasons

GameState calcula score por especialistas, sequência limitada a 1,20, gestos de X, conclusão e tempo opcional. A avaliação de vidas/engrenagens continua sendo a de ProgressStore. Os X permanecem anotações neutras; seu valor é privado durante o puzzle e revelado no resultado, para não transformar score em dica da solução. BoardInput delimita os gestos existentes e descarta o X provisório convertido em duplo clique, sem atrasar a marcação visual.

O mesmo save versão 1 recebe wallet_points, scoring_version, claims em rewards e recordes em level_stats. Só a primeira conclusão paga carteira; replay pode melhorar score e engrenagens, sem moedas adicionais. Conclusões antigas implicam recompensa já coletada, sem crédito retroativo; notas desconhecidas e desbloqueios são preservados. Falha ao gravar desfaz as alterações em memória.

game/data/seasons.json configura quatro seasons de 15 fases, independentemente dos veículos. Quotas são derivadas das quantidades de fases anteriores com arredondamento individual de 70% das engrenagens possíveis: atualmente 32, 64 e 96. A quota se soma à progressão sequencial; replay pode liberar uma fronteira pendente. Os separadores de veículos e a home não foram alterados.

scoring_rules.gd centraliza parâmetros e fórmulas. reference_time_sec é um campo positivo opcional nos níveis; as 60 fases atuais continuam intactas e sem bônus temporal até calibração por playtest. O relógio é orientado a eventos de foco/pausa/término e não possui processamento por frame. Auditoria, validação e limites em SCORING_VALIDATION.md.

## Apresentação desktop v2

A v2 foi a base da apresentação; o master 1672×941 enviado depois prevalece sobre suas coordenadas. game_layout.gd reproduz sua composição medida; visuals.gd centraliza materiais com gradientes; cell.gd usa tile procedural volumoso e X grosso arredondado. A barra specialist_strip.gd associa cada slot ao setor real, revela o retrato correspondente e substitui o contador numérico. Dificuldade tem badge, vidas são engrenagens e configurações têm botão próprio com efeitos reduzidos no save existente. A home mostra pontuação geral e saldo disponível separadamente, preservando histórico e separadores.

X não consulta a solução durante clique ou gesto. GameState registra grupos e os avalia apenas na vitória, preservando fórmula e resultados. Save, input, scoring_rules, seasons, catálogo, solver, gerador e fases permanecem preservados. Detalhes atuais: VISUAL_TARGET, VISUAL_STYLE, ASSET_GUIDE e VISUAL_VALIDATION.

## Consolidação visual e UX

O cenário e a paleta aprovados foram preservados. A associação sector_id -> cor calculada -> retrato/EPI -> slot -> região usa o mesmo material parametrizado em specialist_art.gd. A cor da arte não é mais fixa por função. Dois painéis frosted estruturais separam as colunas laterais do fundo, com um único buffer do cenário, sem vidro nos cards internos. Marca oficial em Barlow Semi Condensed Black, títulos ExtraBold e HUD SemiBold; corpo/botões preservam Roboto. A home identifica a soma dos recordes como Pontuação total, separada de Pontos disponíveis. Gameplay, scoring, save, solver e geração não foram alterados.

## Master visual vigente

A imagem Interface de Jogo Machidoku Industrial.png define o canvas 1672×941 e a composição larga. UI em safe frame central, cenário em cover, laterais com um glass cada, cards sem ledges duplicados e barra superior dimensionada pela quantidade real de setores. Elementos impossíveis do puzzle ilustrado são ignorados. Fonte, retratos e assets aprovados são reutilizados; só layout, acabamento e tons visuais foram refinados. Gameplay, input, scoring, save e dados continuam idênticos. Ver VISUAL_TARGET.md para coordenadas e amostras reais do PNG.

## Correção estrutural vigente

A correção estrutural remove a sobreposição de 19 px antes documentada: painel esquerdo, moldura e planta têm limites separados. Os topos começam em y=105. Score integra a barra de instrução acima da mensagem. A planta mantém cards 64 px e rolagem própria. Cell reserva margens internas para os retratos durante todo o pop, sem alterar regras/input.
