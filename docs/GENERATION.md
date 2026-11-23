# Pipeline offline e dificuldade

A campanha Automotive contém 60 JSONs prontos: Hatch Compact 01 a 15, Sedan 16 a 30, SUV 31 a 45 e Sport Coupe 46 a 60. O jogo carrega JSON pronto. Python é uma ferramenta de autoria e nunca roda no gameplay.

## Pipeline

1. Criar uma permutação de colunas sem contato diagonal entre linhas consecutivas.
2. Semear um setor em cada especialista e crescer regiões por vizinhos ortogonais até cobrir o grid.
3. Rejeitar setores de uma célula para evitar pistas triviais demais neste bloco.
4. Enumerar até duas soluções com o solver independente, respeitando os fixos. Somente uma é aceitável.
5. Construir um roteiro lógico sem consultar a solução armazenada.
6. Exigir conclusão lógica e classificação compatível com o perfil.
7. Revalidar estrutura, solução e unicidade; comparar a resposta derivada com a resposta armazenada.
8. Após selecionar o bloco inteiro, escrever os JSONs com substituição atômica por arquivo e produzir o relatório.

Não há fallback para layout ambíguo ou classificação errada. Esgotar o limite lança erro antes da publicação dos novos candidatos. Uma falha de IO durante a etapa de publicação ainda pode interromper uma substituição de bloco; para testar conteúdo novo, gerar em uma pasta separada antes de copiá-lo para o catálogo ativo.

## Perfis e comandos

`tools/generator/profiles.json` contém id, size, fixed e difficulty. A fase 1 usa `starter: true`, preservando o layout inicial arquivado do MVP. Ela continua Fácil por decisão editorial de introdução, embora o analisador a marque como Normal pelo confinamento inicial. Seus números são publicados sem alteração.

`base: 14` na fase 15 escolhe outra estratégia: ampliar a fase 14 para 9×9, acrescentar um setor e um especialista fixo, e fazer mutações nas fronteiras. Cada mutação preserva conectividade e protege as posições da solução. A fase selecionada teve 23 mutações aceitas; conferir o valor exato em `generation.boundary_mutations` no JSON. Ela passa novamente pelo solver e pelo analisador. A origem é registrada, em vez de apresentar o resultado como uma amostra independente.

```powershell
.\.venv\Scripts\python.exe tools\generator\generate.py --seed 41971 --output artifacts\experimento --report artifacts\experimento_report.json
```

Flags:

- `--seed`: seed mestre. Cada id tem uma sequência própria; `seed_offset` no perfil permite outra sequência explicitamente.
- `--world` e `--product`: IDs registrados em game/data/campaign.json.
- `--count`: quantidade; repete o template quando necessário.
- `--start-id`: primeiro ID global; remapeia também as dependências base.
- `--profiles`: perfis em ordem de dependência; padrão profiles.json para Hatch e campaign_profiles.json para outros produtos.
- `--attempts`: limite por perfil; padrão 100000.
- `--starter`: origem opcional da fase introdutória.
- `--output`: pasta dos JSONs, padrão `game/levels`.
- `--report`: relatório de perfis efetivos, métricas e rastros; padrão artifacts/generation_<world>_<product>.json, fora da pasta de fases.
- `--overwrite`: permite substituir os nomes de saída existentes.
- `--resume`: reaproveita checkpoints locais em `artifacts/generator_cache/v2/<world>/<product>/<seed>`, revalidando solução e critérios lógicos.

Sem `--resume`, a geração é reproduzível com os mesmos perfis, starter, seed e versão do algoritmo. A busca fria dos perfis difíceis pode levar minutos. Checkpoints só aceleram autoria e não são necessários para jogar. O comando recusa ids duplicados e arquivos com ids conflitantes no catálogo de destino.

## Analisador restrito

`tools/difficulty/analyze.py` mantém candidatos, peças fixas e grupos de linha, coluna e setor. Aplica:

- Eliminação por linha, coluna, setor e adjacência de uma peça já determinada.
- Posição única de linha, coluna ou setor.
- Setor confinado em linha/coluna.
- Linha/coluna confinada em setor.

Não usa busca especulativa nem a resposta armazenada para decidir uma jogada. Se essas regras não bastam, retorna `solved_logically: false`, e o gerador rejeita o candidato. Isso é uma prova para este conjunto de regras; não é um solver humano completo.

Cada passo registra sua regra, grupo, célula ou eliminações e uma profundidade de dependência conservadora. Uma posição única depende das exclusões anteriores do grupo. Essa métrica depende da ordem determinística do analisador e não equivale a segundos de raciocínio humano.

## Heurística de classificação, versão 1

`score = 3 × confinamentos + profundidade máxima`. Não há termo para tamanho da matriz.

| Classe | Critério, aplicado nesta ordem |
| --- | --- |
| Muito difícil | pelo menos 4 confinamentos e score ≥ 28 |
| Difícil | pelo menos 2 confinamentos e score ≥ 17 |
| Normal | algum confinamento ou profundidade ≥ 10 |
| Fácil | demais casos resolvidos pelo conjunto de regras |

Também são publicados candidatos iniciais, singletons iniciais, fixos e contagens por regra. Fixos e geometria afetam o roteiro e os candidatos antes de classificar. Tamanho sozinho não determina a classe: a fase 11 tem 9×9 com dois fixos e é Normal; a 13 tem 7×7 sem fixos e é Difícil.

Esses limiares são um instrumento de curadoria, ainda sujeito a playtest. Não implementar Produção Crítica nesta iteração.

## Dados entregues

Os 60 JSONs ativos estão em game/levels. O relatório consolidado docs/level_report.json contém 60 rastros. Os 15 Hatch originais foram preservados byte a byte. As três fases originais foram preservadas em `levels/archive/mvp`; o loader não visita essa pasta. Ver `LEVEL_NOTES.md` para classificação e soluções do novo bloco.

## Lotes por produto e comandos exatos

O catálogo compartilhado é `game/data/campaign.json`. Para acrescentar um produto ou mundo, registre ID, display_name, asset, start_id e level_count e então gere seus JSONs. O loader descobre e ordena os IDs; seleção e veículos usam esse catálogo. Os campos existentes vehicle_name e product continuam compatíveis, e novos JSONs acrescentam product_display_name.

Os três lotes entregues usam o template `campaign_profiles.json`. O bloco mantém tamanhos variados e usa classificação lógica, não tamanho crescente como proxy de dificuldade. Na posição 14, `base: 12` faz mutações conectadas em um puzzle 8×8 do próprio lote; na posição 15, `base: 14` amplia para 9×9 com um fixo. Exigem pelo menos oito mutações aceitas, uma geometria ainda não publicada, solução única e a categoria lógica solicitada. Não são cópias com metadados trocados. A origem e o número de mutações ficam em generation. As primeiras 13 posições usam a busca independente existente.

Esse recurso foi necessário porque a busca independente dos finais de Sedan e SUV esgotou 100000 tentativas; o lote nunca foi publicado incompleto. Sport Coupe foi uniformizado no mesmo template. Não foi reduzido nenhum limiar de validação ou dificuldade. Perfis Hatch e seu comando antigo continuam disponíveis.

Gerar um lote de N fases, por exemplo cinco Sedan em uma pasta de experimentação:

```powershell
.\.venv\Scripts\python.exe tools\generator\generate.py --world automotive --product sedan --count 5 --start-id 16 --seed 52021 --output artifacts\sedan_experimento --report artifacts\sedan_experimento.json
```

Gerar os lotes completos em uma pasta nova, sem alterar os Hatch:

```powershell
.\.venv\Scripts\python.exe tools\generator\generate.py --product sedan --count 15 --start-id 16 --seed 52021 --output artifacts\campanha_nova --report artifacts\sedan_report.json
.\.venv\Scripts\python.exe tools\generator\generate.py --product suv --count 15 --start-id 31 --seed 62021 --output artifacts\campanha_nova --report artifacts\suv_report.json
.\.venv\Scripts\python.exe tools\generator\generate.py --product sport_coupe --count 15 --start-id 46 --seed 72021 --output artifacts\campanha_nova --report artifacts\sport_coupe_report.json
```

Validar o catálogo ativo ou apenas um arquivo:

```powershell
.\.venv\Scripts\python.exe tools\solver\validate.py
.\.venv\Scripts\python.exe tools\solver\validate.py game\levels\16_sedan.json
```

Regenerar somente Sedan no catálogo ativo, preservando os outros produtos:

```powershell
.\.venv\Scripts\python.exe tools\generator\generate.py --product sedan --count 15 --start-id 16 --seed 52021 --overwrite --resume
```

Para SUV, usar --product suv --start-id 31 --seed 62021; para Sport Coupe, --product sport_coupe --start-id 46 --seed 72021, mantendo count/overwrite/resume. Sem --overwrite, arquivos existentes são recusados. IDs conflitantes em outros nomes também são recusados. Regenerar altera conteúdo publicado, portanto novos experimentos devem usar outra pasta.

Checkpoints são separados por mundo/produto/seed e conferem perfil, fonte starter ou hash do puzzle base. Uma alteração no base invalida o checkpoint dependente; isso evita atribuir uma fase derivada a uma origem antiga. Retomar revalida solver, trace, classificação e duplicação de geometria. A mesma versão, seed e perfis reproduzem o mesmo conteúdo.

O analisador continua uma heurística editorial restrita. O score usa confinamentos e profundidade; geometria, fixos e adjacência afetam os candidatos e o roteiro. Tamanho, candidatos iniciais e técnicas são registrados, sem pretensão de prever tempo ou dificuldade percebida de jogadores. O playtest dos três novos produtos permanece pendente.

## Home e pontuação

A home integrada e as engrenagens não alteram geração, solver, dificuldade ou os 60 JSONs publicados. Todos os comandos acima continuam válidos. Esta etapa apenas revalidou o catálogo existente; não gerou outro lote.
