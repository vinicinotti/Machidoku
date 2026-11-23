# Autoria e arquivo de fases

Os 60 JSONs ativos estão em `game/levels/`, dentro de `res://`. O solver lê os mesmos arquivos e o Godot os descobre por id.

As três fases originais da primeira iteração estão preservadas em `levels/archive/mvp/`, fora do catálogo ativo. O gerador usa a primeira como starter para preservar a introdução. Não copie o arquivo histórico sobre uma fase atual sem revalidar os metadados.

Perfis e ferramentas ficam em `tools/generator`, `tools/solver` e `tools/difficulty`. Consulte `docs/GENERATION.md`.
