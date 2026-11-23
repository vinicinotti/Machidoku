# Machidoku — game design

## Conceito e regras

Uma planta industrial com setores irregulares recebe especialistas. O jogador cruza restrições espaciais para eliminar candidatos e encontrar posições obrigatórias. **Poucas regras explícitas + muitas consequências lógicas.**

Para N×N, há N setores conectados ortogonalmente e N especialistas. Exatamente uma peça por setor, linha e coluna. Peças não podem se tocar, inclusive em diagonal. O X é anotação; não é necessário preencher todas as células para vencer.

## Interação, vidas e erros

Clique marca/apaga X normal; duplo clique coloca/remove especialista e pode substituir diretamente um X normal. O primeiro pressionamento inicia feedback imediatamente: não há espera para decidir o clique simples. A janela de 450 ms só reconhece o segundo pressionamento na mesma célula. Clique simples não altera especialistas. Iniciar drag ou perder o foco limpa o histórico de double-click e encerra o gesto ativo.

Na remoção de X, a escala vai até 0,85 e o alpha até zero: 90 ms no clique e 55 ms no arraste. O estado vira EMPTY ao finalizar. Se o segundo clique chegar antes disso, a saída é cancelada para não apagar o especialista ou ERROR_X criado pela tentativa. Arrastes mantêm o modo escolhido antes da primeira alteração, mesmo que a célula inicial termine de desaparecer antes do movimento.

X normal representa uma hipótese do jogador, nunca é validado contra a solução e nunca custa vida nem denuncia uma anotação incorreta. Pode ser colocado sobre a solução e depois apagado normalmente.

Cada fase começa com três vidas. Somente tentar colocar especialista fora da solução consome uma vida: a tentativa se transforma em ERROR_X, um X coral permanente, sem deixar a peça errada. ERROR_X não aceita clique, duplo clique nem arraste e só desaparece ao reiniciar. O terceiro erro causa PRODUÇÃO INTERROMPIDA. Fixos não podem ser removidos.

O arraste escolhe o modo na primeira célula editável: EMPTY inicia MARK e X normal inicia ERASE. O modo fica fixo até soltar, inclusive ao revisitar células. MARK altera somente EMPTY; ERASE altera somente X normal. Especialistas e ERROR_X são ignorados, sem escolher nem trocar o modo do gesto. Uma anotação sobre a solução continua sendo apenas anotação também durante o arraste.

## Campanha Automotive

São 60 fases Automotive: Hatch Compact (01 a 15), Sedan (16 a 30), SUV (31 a 45) e Sport Coupe (46 a 60). O Hatch original permanece intacto. Cada produto retoma puzzles acessíveis e chega a um final muito difícil. Por produto, são quatro fáceis, seis normais, três difíceis e duas muito difíceis, entre 5×5 e 9×9. Os tamanhos variam durante a progressão: grades maiores com fixos podem ser menos exigentes que grades menores sem pistas.

As fases têm solução única e um roteiro demonstrável com posições únicas e confinamentos. A classificação usa número de confinamentos e profundidade do roteiro, com exceção editorial da fase introdutória preservada. Métricas não substituem playtest humano.

## Progresso e resultados

A home mostra a próxima fase de campanha como CTA principal e o histórico desbloqueado em uma coluna descendente. Cada linha possui fase, melhor nota e replay. Não há tela separada ou grade por produto. Completar uma fase libera a seguinte quando a quota da season permite; replay anterior não reduz desbloqueios nem desloca a continuação para trás. Reiniciar altera só a partida. O save não restaura marcas ou vidas em andamento.

Vitórias mostram produto, fase e dificuldade, com Próxima fase e Repetir fase. As fases 15, 30 e 45 atravessam os produtos atuais quando a season seguinte está liberada. A fase 60 encerra Automotive e oferece Voltar ao menu e Repetir fase. A conclusão de produto deriva de todas as suas fases em completed_levels.

Pontuação da tentativa, carteira econômica e engrenagens permanentes são valores distintos. A carteira recebe apenas a primeira conclusão; replay melhora recordes e engrenagens. Seasons são configuradas separadamente dos produtos e exigem a soma das quotas de 70% das engrenagens possíveis de cada season anterior, arredondadas individualmente para cima. X continuam neutros e sua pontuação só é revelada no resultado. Balanceamento e decisões de compatibilidade estão em [SCORING_VALIDATION.md](SCORING_VALIDATION.md).

## Identidade e movimento

Especialistas e quatro veículos usam os PNGs estáticos existentes; o caminho de compatibilidade do SUV aponta para sua arte própria. Os ícones SVG seguem o mesmo sistema de linhas. Evitar emojis, marcas reais, texturas pesadas e animações longas.

Paleta oficial: cream #FFE6CF, orange #FF871C, coral #E76F51, industrial blue #07365A, dark #07244B. Setores usam 12 tons suaves e cores selecionadas pela adjacência. Barlow Semi Condensed Black/ExtraBold define marca e títulos, SemiBold os labels de HUD. Roboto permanece no corpo e botões, com fontes centralizadas no tema.

O board desenha fronteiras em camada única, com linhas internas leves e X grandes, grossos e arredondados. Especialistas têm maior peso visual. Tweens curtos dão pop nas peças, fade no X, reação no erro/vida e pulse na vitória. Arte continua estática; nenhuma spritesheet é necessária.

## Planejamento preservado

Mundos futuros: Aerospace, Shipyard, Rail e Advanced Industry. Somente Automotive está ativo nesta entrega. game/data/campaign.json centraliza mundos e produtos; o loader continua genérico.

Classes futuras: Normal, Difícil e Muito Difícil, além de Produção Crítica com uma vida e recompensa maior. Produção Crítica não foi implementada.

Modo Projeto futuro: receber matriz vazia e tamanhos exigidos, desenhar setores conectados, validar o layout e então resolver os especialistas. Fora do escopo atual, assim como mobile export, ranking, backend, monetização e multiplayer.

No desktop, a coluna esquerda reúne produto, fase, três regras empilhadas e vidas. Isso libera altura para ampliar o board, mantendo a planta lateral. A home adapta largura dos cards e usa rolagem vertical no histórico. Todos os separadores encerram seus blocos descendentes após `product.first_level`, como Sedan abaixo da fase 16 e Hatch abaixo da fase 1. Essa regra inclui a próxima fase destacada, que não se repete na lista.

Vitórias rendem 3/2/1 engrenagens para 0/1/2 erros. A melhor nota é preservada no replay; o popup exibe a tentativa atual. Vidas compartilham o mesmo desenho de engrenagem, sem alterar as três vidas ou a lógica de erros. Uma conclusão antiga sem registro de erros fica Sem nota até o replay.


A apresentação atual segue o master 1672×941, descrito em VISUAL_TARGET.md. Barra por setor substitui a contagem numérica, dificuldade tem badge, configurações permitem efeitos reduzidos e a home mostra desempenho e saldo econômico separadamente. Dados e regras permanecem preservados.
