# Bloco Hatch Compact — classificação e soluções

Catálogo ativo: 15 fases Automotive / Hatch Compact. Todas têm cobertura completa, N setores ortogonalmente conectados, N especialistas, uma peça por linha/coluna/setor, nenhuma adjacência e exatamente uma solução. São 4 fáceis, 6 normais, 3 difíceis e 2 muito difíceis.

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

A fase 1 preserva o layout introdutório do MVP com sua classificação editorial Fácil. As demais classes são o resultado direto da heurística publicada em `GENERATION.md`. As fases 14 e 15 exigem respectivamente cinco e seis confinamentos neste roteiro, incluindo combinações nos dois sentidos entre eixos e setores.

A fase 15 amplia a 14, com um setor adicional e mutações de fronteira, depois é novamente validada. O tamanho maior e a peça fixa não removem a cadeia lógica exigida. A origem aparece nos metadados de geração.

O relatório `level_report.json` contém candidatos iniciais, contagens, profundidade e cada passo lógico, com coordenadas baseadas em zero. A dificuldade ainda precisa de playtest humano.

## Soluções — spoilers

Cada sequência abaixo indica a coluna do especialista em cada linha. Aqui os números começam em **1**; nos JSONs começam em **0**.

- Fase 01: **1, 3, 5, 2, 4**.
- Fase 02: **5, 2, 4, 1, 3**.
- Fase 03: **2, 6, 3, 5, 1, 4**.
- Fase 04: **2, 5, 3, 1, 7, 4, 6**.
- Fase 05: **1, 3, 6, 4, 2, 5**.
- Fase 06: **1, 5, 7, 2, 4, 6, 3**.
- Fase 07: **3, 1, 5, 7, 2, 8, 6, 4**.
- Fase 08: **3, 1, 4, 6, 2, 5**.
- Fase 09: **4, 8, 6, 1, 5, 3, 7, 2**.
- Fase 10: **4, 1, 3, 5, 7, 2, 6**.
- Fase 11: **4, 9, 6, 8, 5, 1, 3, 7, 2**.
- Fase 12: **8, 6, 4, 1, 3, 5, 2, 7**.
- Fase 13: **5, 1, 7, 2, 4, 6, 3**.
- Fase 14: **4, 1, 6, 2, 7, 3, 8, 5**.
- Fase 15: **4, 1, 6, 2, 7, 3, 8, 5, 9**.
