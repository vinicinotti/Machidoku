# Save local — versão 1

Arquivo padrão: `user://progress.json`. O caminho é resolvido pelo Godot; não há caminho absoluto específico de máquina no runtime. No Windows, a configuração padrão usa `%APPDATA%\Godot\app_userdata\Machidoku`.

```json
{
  "version": 1,
  "highest_unlocked_level": 2,
  "current_level": 2,
  "completed_levels": [1],
  "level_stats": {
    "1": {"completions": 1, "last_errors": 0, "best_errors": 0, "last_gears": 3, "best_gears": 3}
  },
  "rewards": {},
  "settings": {}
}
```

Campos de fase armazenam **ids**, não índices de array nem nomes de arquivos. A navegação usa o catálogo real ordenado. Lacunas de ids são suportadas; uma conclusão desbloqueia o id seguinte disponível, não `id + 1`.

`ProgressStore` normaliza os IDs contra o catálogo carregado, elimina IDs inválidos/duplicados e preserva conclusões temporariamente ausentes. Se o catálogo mudar, escolhe uma fase atual disponível sem reduzir o maior desbloqueio. Estatísticas guardam conclusões e erros; recompensas e configurações ficam como objetos reservados. Erros contam somente tentativas incorretas de especialista; anotações X não alteram vidas nem estatísticas. Estados de célula não são salvos.

## Quando grava

- Ao iniciar/retomar a fase de campanha, atualiza `current_level`. Selecionar uma fase anterior ou já concluída é replay e preserva esse cursor.
- Ao vencer, registra conclusão e estatísticas. highest_unlocked_level recebe o máximo entre o valor anterior e o próximo ID real permitido pela quota da season. current_level avança somente quando a fase vencida não está atrás do cursor atual; replay anterior conserva Continuar e pode liberar uma fronteira pendente ao melhorar engrenagens.
- A vitória final mantém a fase 60 como atual e conclui 60 IDs. Produtos concluídos são derivados das fases, sem novo campo redundante.
- Reiniciar cria outra partida, preservando desbloqueios e conclusões.

O save não inclui marcas do tabuleiro, vidas de uma partida em andamento nem histórico completo de jogadas. Reabrir a fase devolve um tabuleiro novo, com três vidas.

## Escrita e recuperação

1. Escrever `progress.json.tmp`, fazer flush e fechar.
2. Se o arquivo atual for válido, copiá-lo para `progress.json.bak`.
3. Renomear o temporário para o caminho principal e verificar o resultado.

A substituição é atômica por arquivo. Se a leitura principal falhar, tentar a cópia de segurança. Um primário truncado não substitui o backup bom durante a recuperação. Sem arquivos válidos, usar defaults e manter o jogo utilizável. Uma versão futura é preservada e bloqueada para escrita. Falhas de escrita são retornadas e exibidas pela interface; não são tratadas como gravações bem-sucedidas.

Isso reduz o risco de perda por fechamento durante escrita. Não substitui backup externo nem uma garantia contra defeito físico no armazenamento.

## Reset e testes

Em debug, Ctrl+Shift+R abre um diálogo de confirmação. Não há botão de reset junto à ação principal do menu. Os testes usam `user://tests/integration.json` e `user://tests/cross_process.json`, sem apagar ou alterar o save real do jogador.

O teste de persistência fecha o primeiro processo após completar a fase 1 e continuar da fase 2. Outro processo abre as cenas novamente e confirma fase atual, desbloqueio e conclusão. Também cobre arquivo truncado, versão futura, reset e ids não consecutivos.

## Compatibilidade com a campanha ampliada

A versão continua 1 e os campos existentes permanecem preservados. Não há migração destrutiva. Ao carregar um save anterior ao scoring que já concluiu as 15 fases Hatch, a reconciliação preserva a liberação de 16 e move a continuação concluída para essa próxima fase. Saves antigos recebem a mesma preservação das liberações inferidas nas fronteiras 30/31 e 45/46. Novas conclusões respeitam as quotas de seasons documentadas abaixo.

A reconciliação não reduz o maior desbloqueio mesmo se o catálogo estiver temporariamente menor; a fase atual é ajustada para um ID disponível. Reset explícito continua sendo a operação que apaga progresso.

Exemplo de replay: highest_unlocked_level=42, current_level=42, selecionar e vencer a fase 7 mantém ambos em 42, acrescentando somente a conclusão e estatísticas pertinentes. O teste de campanha verifica seleção real, botão Repetir fase, retorno por Continuar e reabertura do save. Saves de teste usam user://tests/campaign.json e user://tests/campaign_legacy.json.

## Pontuação por engrenagens

Vitórias válidas aceitam errors=0, 1 ou 2. A fórmula é 3-errors: três, duas ou uma engrenagem. errors=3 ou um valor negativo não pode registrar conclusão. Somente a vitória real do GameState chama a gravação durante o jogo.

Em level_stats[id], last_gears guarda a tentativa mais recente e best_gears recebe o máximo entre a nota anterior e a atual. best_errors continua equivalente a 3-best_gears. Os outros campos de estatísticas são preservados; configurações, recompensas, completed_levels, highest_unlocked_level e current_level mantêm a compatibilidade.

A versão permanece 1, pois os campos são aditivos. best_gears ausente é derivado de best_errors válido. Se uma conclusão antiga não possui nenhum registro de desempenho, best_gears(id) retorna -1 e a UI mostra Sem nota. Isso não é uma vitória com zero engrenagens nem concede uma nota sem evidência. O próximo replay registra uma nota válida.

O popup mostra engrenagens da tentativa atual, mesmo quando o replay é pior; a home sempre mostra a melhor nota. Os testes cobrem melhoria, preservação de recorde, reabertura em outro processo e preservação do cursor da campanha.

## Pontos econômicos e seasons

O mesmo JSON recebe `scoring_version: 1` e `wallet_points`, inicialmente zero. Em `rewards[id]`, `claimed` e `amount` registram a recompensa única. A carteira só é creditada na primeira conclusão, antes de marcar o claim, e tudo é gravado junto. Replays não concedem pontos econômicos. Falha na gravação restaura o estado anterior em memória.

`level_stats[id]` recebe `last_score`, `best_score` e `last_elapsed_sec`, mantendo todos os campos anteriores. Engrenagens são somadas a partir do melhor resultado por fase, sem contador global duplicado no save.

Toda conclusão prévia implica recompensa já coletada. Saves antigos recebem claim com valor retroativo zero, sem alterar carteira, notas, configurações ou desbloqueios existentes. Notas sem evidência permanecem desconhecidas. Não há migração de tempo ou score por estimativa.

Seasons são definidas em `game/data/seasons.json`, separadamente dos produtos. Para novos avanços, a quantidade global de engrenagens deve alcançar a soma das quotas individuais anteriores, cada uma `ceil(fases * 3 * 0,70)`. Desbloqueios já existentes permanecem preservados. Engrenagens nunca são gastas; wallet_points não libera seasons.

Detalhamento, parâmetros e limitações em [SCORING_VALIDATION.md](SCORING_VALIDATION.md).
