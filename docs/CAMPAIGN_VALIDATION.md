# Campanha Automotive, seleção e replay

Este relatório registra a iteração anterior. A seleção foi posteriormente integrada à home, com notas por engrenagens e regras à esquerda; ver [HOME_VALIDATION.md](HOME_VALIDATION.md).

Entrega de 20/10/2026, validada no workspace `.`.

## Conteúdo publicado

| Produto | IDs globais | Arquivos em game/levels | Situação da arte |
| --- | --- | --- | --- |
| Hatch Compact | 01 a 15 | 01_hatch.json a 15_hatch.json | PNG existente |
| Sedan | 16 a 30 | 16_sedan.json a 30_sedan.json | PNG existente |
| SUV | 31 a 45 | 31_suv.json a 45_suv.json | Placeholder explícito no catálogo |
| Sport Coupe | 46 a 60 | 46_sport_coupe.json a 60_sport_coupe.json | PNG existente |

São 60 fases acessíveis pela campanha Godot, incluindo 45 novos JSONs gerados pelo pipeline offline. As 15 fases Hatch originais foram preservadas byte a byte. Todos os puzzles têm solução única e geometria distinta dos demais publicados.

O catálogo compartilhado [campaign.json](../game/data/campaign.json) registra mundos, produtos, nomes, assets e blocos. O Python usa esse arquivo para os metadados; a Godot usa para seleção, miniaturas, contagens por produto e veículos. O loader existente continua genérico, descobrindo JSONs e ordenando por ID global.

## Geração e dificuldade

O gerador recebeu world, product, count e start-id, preservando os parâmetros anteriores de seed, profiles, output, attempts, overwrite e resume. Os perfis e dependências são remapeados juntos. Checkpoints são separados por mundo/produto/seed e invalidam derivados quando o hash da fonte muda.

As primeiras 13 fases de cada novo lote usam a busca independente. A posição 14 usa mutações de fronteiras em uma base 8×8 do próprio produto; a posição 15 amplia essa base para 9×9. Origem e mutações são registradas. Essa estratégia evita depender exclusivamente da baixa frequência de finais muito difíceis na busca independente, mantendo todos os filtros do solver e do analisador. Os perfis Hatch originais permanecem disponíveis.

Por produto, a distribuição publicada é de quatro fáceis, seis normais, três difíceis e duas muito difíceis. Tamanhos variam de 5×5 a 9×9; há fases 9×9 normais antes de fases 7×7 difíceis. A classificação usa o roteiro lógico, confinamentos e profundidade, com candidatos, fixos e técnicas registrados. A exceção editorial da fase introdutória Hatch foi preservada.

O [relatório consolidado](level_report.json) contém os 60 resultados do solver e os rastros do analisador. Comandos de geração, lotes e regeneração isolada estão em [GENERATION.md](GENERATION.md).

## Seleção, replay e save

- O menu oferece Jogar/Continuar e Selecionar fase.
- A seleção agrupa os produtos; concluídas têm check, disponíveis têm destaque orange e bloqueadas têm cadeado e botão desabilitado.
- O controle de acesso também existe em Main.start_level, evitando abrir fases bloqueadas por chamadas diretas.
- Abrir e concluir a fase 7 com progresso na 42 preserva highest_unlocked_level=42 e current_level=42. Estatísticas do replay são atualizadas normalmente.
- A vitória oferece Próxima fase e Repetir fase. As transições 15 para 16, 30 para 31 e 45 para 46 identificam o novo produto liberado.
- Produto concluído é derivado das suas fases em completed_levels, sem duplicação no save.
- O save permanece na versão 1. Configurações, estatísticas, conclusões e desbloqueios existentes são preservados. Um save antigo com Hatch concluído passa a continuar no Sedan.
- Um catálogo temporariamente menor não reduz o maior desbloqueio nem apaga conclusões ausentes daquele catálogo. Reset explícito mantém sua função anterior.

Detalhes de persistência e recuperação estão em [SAVE_FORMAT.md](SAVE_FORMAT.md).

## Layout desktop

As três regras foram movidas para um bloco compacto no cabeçalho do produto, com texto em duas linhas, ícones e os mesmos tokens visuais. A faixa antes reservada às regras saiu da coluna do board. O painel da planta continua à direita.

O board mede 466×466 px em 1100×820 e 661×661 px em 1448×1086. As capturas anteriores e posteriores da fase 4 permitem comparar o ganho de espaço com o mesmo puzzle. Portrait conserva suas regras acima do board e detalhes expansíveis abaixo.

A seleção adapta suas grades para desktop, portrait e mínimo 360×700, com rolagem vertical e sem cortes horizontais. O popup de desbloqueio também foi verificado após redimensionamento de desktop para 360×700.

## Arquivos principais

- Dados: 45 novos JSONs em game/levels; game/data/campaign.json; docs/level_report.json.
- Pipeline: tools/generator/generate.py e novo tools/generator/campaign_profiles.json.
- Runtime: world_catalog.gd, progress_store.gd, main.gd e game.gd.
- Nova tela: game/scripts/level_select.gd e seu UID.
- Placeholder: game/assets/vehicles/suv_placeholder.tres, alias temporário do Hatch existente. Nenhuma nova imagem ou fonte.
- Testes: test_campaign.gd e UID, test_campaign_generation.py, atualizações de test_mvp.gd, test_visual_preview.gd, test_levels.py, test_pipeline.py e Testar.ps1.
- Documentação: PROJECT_CONTEXT, GAME_DESIGN, GENERATION, SAVE_FORMAT, README e levels/README.

As mudanças visuais anteriores e a alteração de project.godot que já estavam no workspace foram preservadas.

## Validação final

Comando executado:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Testar.ps1 -Render
```

| Verificação | Resultado |
| --- | --- |
| Solver independente | 60 fases válidas, conectadas e com solução única |
| Python | 27 testes aprovados |
| Godot, integração e progressão completa | 574 verificações aprovadas |
| Persistência entre processos | 7 de escrita + 10 de reabertura aprovadas |
| Preview e layouts existentes | 52 verificações aprovadas |
| Nova campanha, seleção e replay | 123 verificações aprovadas |
| Arquivos protegidos | 23 hashes conferidos, nenhum alterado |
| Caminho antigo | Nenhuma dependência introduzida no runtime, ferramentas ou launchers |

Godot 4.7.2 executou as cenas reais em Windows, Forward+ / Direct3D 12, Intel UHD Graphics 620. A suíte percorreu as 60 fases, usando input sintético nas 15 primeiras e o estado real do jogo nas demais. Os testes de regras, X, ERROR_X, vidas, fixos, arraste e duplo clique continuam aprovados. Solver, analisador, GameState, BoardInput, Board, Cell, fronteiras e os 15 Hatch passaram na conferência de preservação. Não houve gravação no save pessoal; os testes usam user://tests/.

## Evidências locais

- [Seleção desktop](../artifacts/campaign_selection_desktop.png), [portrait](../artifacts/campaign_selection_portrait.png) e [mínimo 360×700](../artifacts/campaign_selection_minimum.png).
- [Gameplay desktop](../artifacts/campaign_game_desktop.png) e [1448×1086](../artifacts/campaign_game_large.png).
- [Fase 4 antes](../artifacts/campaign-before/reference_desktop_1100x820.png) e [depois](../artifacts/reference_desktop_1100x820.png).
- [Produto desbloqueado](../artifacts/campaign_product_unlock.png) e [popup no mínimo portrait](../artifacts/campaign_unlock_portrait.png).
- [Suíte final](../artifacts/campaign-final-suite.log), [relatório de campanha](../artifacts/campaign_tests.json) e [hashes protegidos](../artifacts/campaign-protected-check.json).

artifacts/ é ignorado pelo Git; as evidências estão no workspace local.

## Limitações

SUV usa a arte provisória do Hatch por meio de um recurso próprio. A arte definitiva ainda deve ser produzida e vinculada no catálogo. Sedan e Sport Coupe reutilizam os arquivos existentes, sem nova geração de imagem.

A dificuldade é uma heurística editorial com prova lógica restrita; o balanceamento dos novos lotes ainda precisa de playtest. As fases finais derivadas não são amostras inteiramente independentes das suas bases. A validação mobile ocorreu em janelas Windows, sem exportação ou aparelho físico.
