# Machidoku — Prompt de Refinamento Visual

Você está trabalhando no projeto:

`.`

Antes de alterar qualquer arquivo, leia integralmente:

- `docs/PROJECT_CONTEXT.md`
- `docs/VISUAL_TARGET.md`
- `docs/reference/README.md`

Depois abra/inspecione:

- `docs/reference/machidoku_visual_target_desktop_v1.png`

Essa imagem é a **referência visual oficial** desta iteração.

## Objetivo

Refinar a interface atual do Machidoku até que ela fique visualmente muito mais próxima da referência oficial, preservando toda a lógica e comportamento já implementados.

O jogo já funciona.

NÃO reescreva o projeto.
NÃO refaça solver, geração de fases, persistência ou input.
NÃO altere regras do puzzle.

A tarefa é principalmente:

**visual refinement + asset integration + UI polish**

---

## Regra principal

A implementação atual não é a fonte visual de verdade.

Para decisões de aparência, siga:

`imagem de referência > docs/VISUAL_TARGET.md > implementação atual`

A implementação atual pode ser alterada visualmente sempre que necessário para atingir a referência.

---

## Preserve obrigatoriamente

- 1 especialista por setor;
- 1 especialista por linha;
- 1 especialista por coluna;
- especialistas não podem se tocar, inclusive diagonalmente;
- X normal é apenas anotação e nunca revela a solução;
- tentativa errada de especialista gera `ERROR_X` e perde vida;
- `ERROR_X` é permanente;
- especialistas pré-posicionados são fixos;
- 3 vidas no modo normal;
- vitória não exige marcar todos os X;
- save/progresso;
- níveis JSON;
- pipeline Python offline;
- comportamento de clique, duplo clique e arraste.

---

## Alvo visual

Quero reproduzir no jogo real a sensação da imagem de referência:

- casual puzzle premium;
- industrial;
- clean;
- 2.5D suave;
- comercial;
- amigável;
- moderno.

Não quero apenas “usar as mesmas cores”.

Quero reproduzir também:

- hierarquia;
- profundidade;
- proporções;
- espaçamentos;
- peso visual;
- acabamento;
- relação entre board e painel;
- coesão entre personagem, carro, ícones e UI.

---

## 1. Board

Prioridade máxima.

Comparar diretamente o board atual com a referência e corrigir:

- moldura externa;
- aro interno;
- espessura;
- radius;
- sombra;
- profundidade;
- espaçamento das células;
- leitura das fronteiras de setor.

O board deve parecer uma peça premium da interface.

Usar azul industrial `#264653` como base estrutural.

Criar sensação de:

- frame escuro robusto;
- rim/aro claro;
- sombra curta;
- leve profundidade.

Evitar:
- linhas cruas;
- bordas serrilhadas;
- aparência de GridContainer padrão;
- excesso de espaço entre células.

---

## 2. Células

Refinar células para ficarem mais próximas da referência.

Cada célula deve ter:

- cantos arredondados;
- cor pastel;
- highlight superior muito discreto;
- sombra inferior curta;
- volume suave;
- boa distinção sem parecer “candy”.

Usar UI nativa da Godot sempre que possível.

Preferir:
- `StyleBoxFlat`;
- overlays simples;
- Theme centralizado.

Não criar imagem raster individual para cada célula.

---

## 3. Fronteiras de setor

Fronteiras externas de setores devem ser mais fortes que o grid interno.

Garantir espessura consistente e evitar bordas duplas.

Se necessário, desenhar fronteiras em uma layer dedicada com base nos IDs das regiões, em vez de depender exclusivamente das bordas de cada célula.

---

## 4. X

### X normal

Deixar:
- menor;
- mais fino;
- menos contrastante;
- visualmente secundário ao especialista.

### ERROR_X

Manter:
- coral/vermelho;
- alto contraste;
- permanente;
- claramente diferente do X normal.

Não alterar a lógica.

---

## 5. Especialista

Use o asset de maior qualidade disponível no projeto.

Ele deve se aproximar do especialista da referência:

- capacete laranja;
- roupa azul;
- visual industrial amigável;
- 2.5D suave;
- legível em tamanho pequeno.

Ajustar:
- escala;
- recorte;
- posicionamento;
- sombra;
- integração com a célula.

Ele não deve parecer uma imagem colada por cima do board.

Se for necessário criar novo asset complexo e houver ferramenta de geração de imagem disponível, use-a.

Se não houver, não substitua por um SVG simplificado ruim. Preserve o melhor asset existente e concentre-se na integração.

---

## 6. Hatch Compact

Manter o carro fictício.

Refinar integração do asset:

- escala;
- margem;
- shadow/base;
- iluminação visual;
- espaço dentro do card.

O carro precisa pertencer à mesma linguagem visual do especialista e da UI.

Não usar marcas reais.

---

## 7. Cards superiores

Refinar os três cards:

- 1 por setor;
- 1 por linha e coluna;
- Sem se tocar.

Eles devem ficar muito mais próximos da referência.

Melhorar:

- altura;
- padding;
- raio;
- sombra;
- alinhamento de ícone;
- distância entre ícone e texto;
- peso tipográfico.

Não deixar aparência de botão utilitário.

---

## 8. Planta Industrial

Refinar o painel lateral.

Aproximar da referência:

- card externo claro;
- cabeçalho forte;
- subtítulo discreto;
- rows individuais arredondados;
- ícone em chip colorido;
- labels bem alinhadas;
- espaçamento consistente;
- `Em produção` integrado ao mesmo painel.

Não aumentar o painel a ponto de reduzir demais o board.

---

## 9. Background

O cenário atual pode ser reaproveitado, mas deve ficar mais próximo da referência.

Reduzir competição visual:

- menor contraste;
- menor saturação;
- mais haze/cream;
- menos detalhe onde houver UI sobreposta.

O board precisa dominar imediatamente a atenção.

---

## 10. Top bar

Refinar:

- Menu;
- logo/símbolo;
- MACHIDOKU;
- Reiniciar;
- vidas.

Usar a referência para proporção e peso.

O topo deve parecer parte do mesmo design system do restante da tela.

---

## 11. Tipografia

Usar fontes Roboto estáticas já existentes.

Aplicar hierarquia próxima da referência:

- nome do produto grande e forte;
- fase/mundo menor;
- dificuldade discreta;
- títulos dos cards em Medium/Bold;
- corpo em Regular.

Evitar texto excessivamente pequeno.

---

## 12. Paleta

Paleta oficial:

- cream: `#FFE6CF`
- orange: `#F4A261`
- coral: `#E76F51`
- industrial blue: `#264653`
- dark: `#1B252D`

Paleta secundária de setores:
usar pastéis harmônicos e distinguíveis.

Evitar cores muito lavadas ou regiões vizinhas quase iguais.

---

## 13. Estratégia técnica de assets

### Godot nativo

Usar para:

- cells;
- cards;
- buttons;
- panels;
- borders;
- shadows simples;
- popups.

### SVG

Usar para:

- ícones;
- logo/símbolo;
- regras;
- setores;
- controles simples.

### PNG/WebP transparente

Aceitável para:

- especialista;
- veículos;
- background;
- ilustrações complexas.

Não existe exigência de “tudo SVG”.

Qualidade visual é mais importante que forçar uma única tecnologia.

---

## 14. Responsividade

Nesta iteração, priorize desktop atual.

Não quebre futuras adaptações mobile.

Evitar dimensões absolutamente rígidas quando Containers/anchors puderem resolver.

---

## 15. Microanimações

Preservar as microanimações existentes.

Não criar animação de personagem ou carro nesta etapa.

Permitido apenas refinar:

- pop;
- fade;
- scale;
- shake;
- pulse.

A UI deve funcionar perfeitamente mesmo em estado estático.

---

## 16. Processo obrigatório

1. Leia os três documentos de contexto.
2. Inspecione a imagem de referência.
3. Execute o jogo atual ou inspecione a cena atual.
4. Liste internamente as diferenças visuais.
5. Trabalhe primeiro no board.
6. Depois cards e painel.
7. Depois integração de assets.
8. Depois background/top bar.
9. Execute testes.
10. Rode o projeto e verifique visualmente.
11. Corrija regressões.

Não faça uma reescrita geral sem necessidade.

---

## 17. Testes

Ao final:

- executar testes Python existentes;
- executar testes Godot existentes, se aplicável;
- abrir/rodar o jogo;
- validar que nenhuma referência a caminho absoluto antigo foi introduzida;
- garantir que o projeto funciona em:

`.`

Não introduzir dependência de:

`D:\Projetos\Machidoku`

---

## 18. Critério de aceite

A iteração não está concluída apenas porque:

- as cores estão corretas;
- os assets carregam;
- o jogo roda.

Ela está concluída quando a tela real está perceptivelmente mais próxima de:

`docs/reference/machidoku_visual_target_desktop_v1.png`

especialmente em:

- board;
- células;
- frame;
- cards;
- painel lateral;
- profundidade;
- spacing;
- coesão geral.

---

## 19. Entrega final

Ao terminar, informe objetivamente:

- arquivos alterados;
- assets reutilizados;
- assets novos;
- mudanças no board;
- mudanças nos cards;
- mudanças no painel;
- mudanças no background;
- resultado dos testes;
- diferenças que ainda permaneceram em relação à referência.

Não altere regras ou lógica para alcançar objetivos puramente visuais.
