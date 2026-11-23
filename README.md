# MACHIDOKU

Puzzle lógico 2D em Godot 4.7.2, com identidade industrial **2.5D suave**, ilustrações geradas, ícones SVG e UI nativa. A campanha **Automotive** contém **60 fases** em Hatch Compact, Sedan, SUV e Sport Coupe, seleção/replay, progresso local, geração offline e microanimações.

## Publicar no GitHub

No PowerShell, execute `./Publicar.ps1 -Mensagem "Descreva a atualização"`.
Para somente preparar e auditar a entrega, use `./Publicar.ps1 -Preparar`.
O destino padrão é o repositório público `vinicinotti/Machidoku`, associado ao GitHub Projects 1.

O comando cria uma cópia sanitizada, verifica dados de identificação e credenciais com Gitleaks, executa os testes Python e publica pela branch `main`. A cópia Git de publicação fica em `.publish/`, separada do histórico de desenvolvimento. Os commits públicos usam o endereço `noreply` da conta autenticada. O login é feito pelo fluxo oficial do GitHub CLI; senhas e tokens ficam fora do projeto.

Logs, backups, builds, credenciais e arquivos compactados são excluídos. Caminhos locais são removidos da documentação exportada. Os PNGs publicados preservam os dados de imagem e removem metadados adicionais; a origem das ilustrações geradas por IA e os créditos/licenças continuam registrados. Os originais locais são preservados. GitHub Actions repete a auditoria de arquivos e histórico após pushes e pull requests. A verificação reduz o risco de exposição, mas não substitui a proteção da conta e do computador.

## Executar localmente

Abra **Jogar.cmd** com dois cliques. Para editar, abra `game/project.godot` no Godot. Pelo PowerShell, na raiz:

```powershell
Start-Process .\engine\godot\Godot.exe -ArgumentList '--path', '.\game'
Start-Process .\engine\godot\Godot.exe -ArgumentList '--editor', '--path', '.\game'
```

Use `Godot.exe`: o launcher de console original procura outro nome de executável. Engine e fontes originais foram preservadas. Não é necessário instalar pacotes Python, acessar a internet ou configurar servidor. O renderizador existente continua Forward+ / Direct3D 12.

## Jogar e continuar

- Um especialista por setor, linha e coluna; nenhuma peça pode tocar outra, inclusive na diagonal.
- Clique simples marca X ou inicia sua remoção no primeiro pressionamento, sem espera de double-click. A janela de 450 ms apenas reconhece o segundo clique para especialista.
- Duplo clique coloca/remove especialista, inclusive sobre um X removível.
- Arraste marca vários X; começar sobre X escolhe apagamento.
- Peças com selo são fixas. X não é condição de vitória.

Cada fase começa com três vidas. **X normal é apenas anotação:** pode marcar qualquer célula editável, inclusive uma posição da solução, sem perder vida, revelar erro ou receber cor vermelha. Pode ser apagado por clique ou arraste; duplo clique o substitui por uma tentativa de especialista.

Somente uma tentativa incorreta de especialista custa vida. A peça não fica no tabuleiro: surge um **X vermelho permanente**, que não pode ser apagado nem receber especialista até reiniciar a fase. Repetir uma ação nessa célula não cobra outra vida. O terceiro erro interrompe a produção. Um especialista correto permanece normalmente; clique simples não o altera e duplo clique o remove.

O arraste mantém um modo único: começar na primeira célula editável vazia marca X, começar em X normal apaga. Células vazias continuam vazias no modo apagar; X existentes continuam X no modo marcar. Especialistas, peças fixas e X vermelhos são ignorados, inclusive na escolha do modo inicial.

Remover X inicia o fade/scale imediatamente: escala até 0,85 e alpha até zero, em 90 ms no clique ou 55 ms no drag. Ao terminar, a célula vira EMPTY. Um segundo clique durante a saída cancela a remoção pendente e faz a tentativa de especialista normalmente. Não há Timer bloqueando o feedback visual.

**Jogar/Continuar retoma a fase salva.** A vitória grava a conclusão e libera a próxima fase antes da animação, desde que o requisito da season seguinte esteja atendido. Voltar ao menu ou fechar o jogo mantém esse progresso. Uma fase retomada começa com tabuleiro novo e três vidas; as marcas de uma partida em andamento não são salvas. Reiniciar apaga apenas a partida atual.

A home já contém a seleção: Próxima fase no topo e histórico vertical em ordem decrescente, com replay e melhor nota. Os separadores de veículos encerram os blocos após sua primeira fase. A fase 60 conclui Automotive. A vitória oferece Próxima fase e Repetir fase. Replay preserva o progresso e pode melhorar a nota.

Especialistas e gestos de X geram pontuação da tentativa. Pontos econômicos são recebidos somente na primeira conclusão; replay melhora score e engrenagens, sem pagar novamente. Seasons são independentes dos veículos e usam engrenagens permanentes, com requisitos atuais 32, 64 e 96. Os X continuam neutros: seus pontos aparecem apenas no resultado. As 60 fases sem tempo de referência configurado recebem bônus temporal zero. Parâmetros, compatibilidade e testes em [SCORING_VALIDATION.md](docs/SCORING_VALIDATION.md).

O save fica em `user://progress.json` (normalmente `%APPDATA%\Godot\app_userdata\Machidoku\progress.json` no Windows). Em builds de debug, **Ctrl+Shift+R** abre uma confirmação para restaurar o progresso. Detalhes em [SAVE_FORMAT.md](docs/SAVE_FORMAT.md).

## As 60 fases

Cada produto tem 15 fases com solução única, cobertura completa e setores ortogonalmente conectados. O Hatch original foi preservado. Por produto, são quatro fáceis, seis normais, três difíceis e duas muito difíceis. Os tamanhos variam de 5×5 a 9×9. Fases maiores com peças fixas aparecem antes de fases menores mais exigentes.

Tabela do bloco Hatch original. Os outros lotes estão no relatório consolidado docs/level_report.json.

| Fase | Matriz | Dificuldade | Fixos | Confinamentos | Profundidade | Score |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 5×5 | Fácil | 1 | 1 | 7 | 10 |
| 2 | 5×5 | Fácil | 1 | 0 | 8 | 8 |
| 3 | 6×6 | Fácil | 1 | 0 | 8 | 8 |
| 4 | 7×7 | Fácil | 2 | 0 | 8 | 8 |
| 5 | 6×6 | Normal | 0 | 1 | 12 | 15 |
| 6 | 7×7 | Normal | 1 | 0 | 10 | 10 |
| 7 | 8×8 | Normal | 2 | 0 | 12 | 12 |
| 8 | 6×6 | Normal | 0 | 1 | 10 | 13 |
| 9 | 8×8 | Normal | 1 | 0 | 12 | 12 |
| 10 | 7×7 | Difícil | 0 | 3 | 13 | 22 |
| 11 | 9×9 | Normal | 2 | 1 | 13 | 16 |
| 12 | 8×8 | Difícil | 0 | 2 | 17 | 23 |
| 13 | 7×7 | Difícil | 0 | 2 | 13 | 19 |
| 14 | 8×8 | Muito difícil | 0 | 5 | 14 | 29 |
| 15 | 9×9 | Muito difícil | 1 | 6 | 14 | 32 |


Os números descrevem o roteiro do analisador restrito; não medem diretamente o esforço humano. A fase 1 preserva a introdução do MVP e sua classificação editorial Fácil. Consulte [LEVEL_NOTES.md](docs/LEVEL_NOTES.md).

## Validar e testar

```powershell
.\.venv\Scripts\python.exe tools\solver\validate.py
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
powershell -ExecutionPolicy Bypass -File .\Testar.ps1
powershell -ExecutionPolicy Bypass -File .\Testar.ps1 -Render
```

O último comando usa a GPU e salva capturas em `artifacts/`. O runner verifica SVGs, PNGs RGBA e transparência, logs, input por eventos no viewport, progressão pelas 60 fases e seleção/replay, persistência em dois processos e galeria/layout portrait. Os saves de teste são isolados em `user://tests/` e não alteram o save do jogador. Resultados em [VALIDATION.md](docs/VALIDATION.md) e [VISUAL_VALIDATION.md](docs/VISUAL_VALIDATION.md).

## Identidade e preview

Cinco ilustrações PNG com transparência foram geradas por **image_gen**, seguindo a referência visual: especialista, Hatch Compact, Sedan, Sport Coupé e ambiente industrial. Ícones simples, branding e decoração de celebração continuam SVG; são 24 SVGs ativos e 15 de legado/compatibilidade. Powertrain agora tem ícone próprio.

O logo oficial combina símbolo SVG com Label Barlow Semi Condensed Black. Cards, botões, moldura, bezel e células são nativos, com relevo, degradê leve, highlights e sombras. Regras e dados da fase ficam na coluna esquerda do desktop; a planta e produção continuam à direita. Sedan e Sport Coupe estão ativos. SUV usa arte própria pelo caminho de compatibilidade existente. Prompts e hashes em [asset_generation.json](docs/asset_generation.json).

Desktop a partir de 900 px mantém a legenda lateral. Em portrait, **PLANTA INDUSTRIAL** e **EM PRODUÇÃO** são cards inferiores recolhíveis; quando expandidos, a página pode rolar. A janela mínima é 360×700, com layout em pixels nativos. Isso foi validado em viewport Windows; não constitui teste em aparelho Android/iOS.

Abra a cena `game/scenes/dev/VisualPreview.tscn` no editor, ou execute:

```powershell
Start-Process .\engine\godot\Godot.exe -ArgumentList '--path', '.\game', 'res://scenes/dev/VisualPreview.tscn'
```

A galeria mostra os assets ativos, cores, X, ERROR_X, fixos, vidas e estados dos botões, sem carregar/gravar uma partida. Para reconstruir os SVGs e `docs/svg_inventory.json`: `.\.venv\Scripts\python.exe tools\assets\build_svg_assets.py`. Esse comando não sobrescreve PNGs nem o guia de assets. O jogo usa arquivos locais e não depende de geração de imagens em runtime.

## Gerar fases offline

```powershell
.\.venv\Scripts\python.exe tools\generator\generate.py --output artifacts\novo_bloco --report artifacts\novo_bloco_report.json
```

Esse comando não altera o catálogo ativo. A busca fria de perfis difíceis pode levar alguns minutos; o limite é explícito e uma falha não publica candidatos inadequados. Para reutilizar checkpoints validados, acrescentar `--resume`. Para regenerar somente o bloco Hatch original conscientemente:

```powershell
.\.venv\Scripts\python.exe tools\generator\generate.py --overwrite --resume --report artifacts\hatch_report.json
```

`tools/generator/profiles.json` define os perfis. Seeds são reproduzíveis. `--overwrite` é obrigatório para substituir arquivos existentes. O jogo só lê os JSONs prontos; não executa Python nem gera fases em runtime. Veja [GENERATION.md](docs/GENERATION.md).

## Organização

```text
game/scenes/       Main, Game, Board, Cell e dev/VisualPreview
game/scripts/      estado, input, UI, save, loader, fronteiras e paleta
game/levels/       60 JSONs ativos, descobertos automaticamente por id
game/assets/       Barlow e Roboto estáticas, ícones SVG e ilustrações PNG RGBA
game/tests/        integração, persistência e preview/layout visual
tools/assets/      autoria reproduzível dos SVGs e manifesto
tools/generator/   geração offline, perfis e checkpoints opcionais
tools/solver/      validação e enumeração independente
tools/difficulty/  prova lógica restrita e métricas
levels/archive/    fases originais do MVP, fora do catálogo ativo
docs/              design, arquitetura, save, pipeline e validação
artifacts/         capturas, logs e experiências locais, ignorados pelo Git
```

As fontes originais, engine, `.venv` e cache Godot continuam ignorados pelo Git. As três TTFs estáticas copiadas e a licença OFL estão em `game/assets/fonts`. Não há remoto configurado.

## Documentação

- [Campanha, seleção/replay e validação desta entrega](docs/CAMPAIGN_VALIDATION.md)
- [Game design](docs/GAME_DESIGN.md)
- [Arquitetura](docs/ARCHITECTURE.md)
- [Formato do save](docs/SAVE_FORMAT.md)
- [Pipeline e dificuldade](docs/GENERATION.md)
- [Fases e soluções](docs/LEVEL_NOTES.md)
- [Assets](docs/ASSETS.md)
- [Estilo visual](docs/VISUAL_STYLE.md)
- [Manifesto de SVGs](docs/ASSET_GUIDE.md)
- [Validação visual](docs/VISUAL_VALIDATION.md)
- [Validação](docs/VALIDATION.md)
- [Roadmap](docs/FUTURE_ROADMAP.md)

Vitória sem erros rende três engrenagens, com um erro rende duas e com dois erros rende uma. Vidas usam o mesmo desenho. O replay conserva a melhor nota; registros antigos sem desempenho aparecem como Sem nota. Detalhes da home, layout e evidências em [HOME_VALIDATION.md](docs/HOME_VALIDATION.md).

## Apresentação v2

O gameplay desktop segue o master 1672×941 documentado em docs/VISUAL_TARGET.md. Há barra de especialistas por setor, badge de dificuldade, engrenagens de vida, opções com efeitos reduzidos e arte 2.5D. A home mostra pontuação geral e saldo disponível. Comparação, testes e limites em [VISUAL_VALIDATION.md](docs/VISUAL_VALIDATION.md).

A consolidação mantém o cenário aprovado, aplica a cor real de cada setor ao EPI do especialista e utiliza uma única superfície frosted por painel lateral no desktop. Não altera gameplay, dados de campanha, pontuação ou persistência.

O master visual atual é [Interface de Jogo Machidoku Industrial.png](<docs/reference/Interface de Jogo Machidoku Industrial.png>), 1672×941. A UI mantém safe frame centralizado, inclusive em ultrawide. As posições impossíveis e os slots excedentes da ilustração não são copiados. Especificação geométrica e amostras do PNG em [VISUAL_TARGET.md](docs/VISUAL_TARGET.md).
