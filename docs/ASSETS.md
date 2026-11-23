# Assets do Machidoku

Referência atual: [master 1672×941](<reference/Interface de Jogo Machidoku Industrial.png>). UI nativa, SVG para formas simples e PNG para arte figurativa.

| Grupo | Conteúdo ativo |
| --- | --- |
| specialists | specialists_atlas_v2.png, dez regiões AtlasTexture, associação por setor |
| vehicles | Hatch Compact, Sedan, SUV e Sport Coupe transparentes |
| decoration | factory_courtyard_v2.png, cenário industrial opaco |
| branding | Símbolo SVG; wordmark é Label Barlow Semi Condensed Black |
| sectors / rules / ui | Ícones, regras, vidas, dificuldade, configurações e ações |
| shaders | Tile, identidade/silhueta por setor, vidro estrutural e suavização do cenário |

Nenhum painel ou board é screenshot. Há 43 SVGs no inventário, incluindo aliases e recursos históricos ainda referenciados por preview/testes. PNGs antigos de personagem/fundo permanecem para proveniência e compatibilidade, fora do gameplay ativo.

Dimensões e uso em [ASSET_GUIDE.md](ASSET_GUIDE.md). Prompts integrais, ferramenta, origens e hashes em [asset_generation.json](asset_generation.json). Novas imagens foram copiadas integralmente, sem upscale nem remoção manual de fundo. O runtime não depende de API, internet ou Python.

Ícones v2: `python tools/assets/refine_v2.py`. build_svg_assets.py preserva o gerador histórico v1 e não deve sobrescrever a v2. Barlow Semi Condensed Black/ExtraBold/SemiBold foi adicionada com sua licença OFL; Roboto e sua licença foram preservadas.

Na etapa do master, o PNG aprovado do cenário, o atlas e veículos foram preservados. O shader do cenário foi suavizado; a engrenagem de vida recebeu contorno quente em SVG e no gerador reproduzível. Não houve geração de arte nova.
