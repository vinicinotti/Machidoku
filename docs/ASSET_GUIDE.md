# Guia de arte v2

## Arquivos ativos

| Caminho em game/assets | Dimensões | Uso |
| --- | --- | --- |
| specialists/specialists_atlas_v2.png | 1774×887, RGBA | Dez retratos, grade 5×2 |
| specialists/{função}.tres | Regiões 354,8×443,5 | Célula e slot, com filter_clip |
| decoration/factory_courtyard_v2.png | 1424×1104, RGB | Cenário, mipmaps e suavização |
| vehicles/hatch_compact.png | 1774×887, RGBA | Hatch |
| vehicles/sedan.png | 1774×887, RGBA | Sedan |
| vehicles/suv.png | 1774×887, RGBA | SUV real, cabine alta |
| vehicles/sport_coupe.png | 1774×887, RGBA | Coupé |

suv_placeholder.tres mantém o caminho de compatibilidade, agora apontando para o SUV real. O catálogo compartilhado e os IDs não mudaram. Os veículos existentes foram comparados e reutilizados quando adequados.

Funções do atlas: Chaparia, Soldagem, Pintura, Elétrica, Montagem, Inspeção, Logística, Testes, Powertrain e Acabamento. specialist_art.gd resolve a identidade pelos metadados do setor e aplica a cor calculada pelo board ao EPI no mesmo shader da célula e do slot. Variam capacetes/caps, máscara, óculos, uniforme e rosto, mantendo pose e luz.

O atlas foi gerado como um único asset para coerência. Cada retrato tem mais de três vezes sua exibição de aproximadamente 90 px no desktop normativo. Não houve recorte destrutivo nem dez cópias raster: AtlasTexture endereça o mesmo PNG. O alpha gerado é preservado.

## Produção futura

- Cenários: até 2048×2048, sem UI embutida, luz/perspectiva v2 e foco secundário.
- Retratos: aproximadamente 512×512 ou atlas com resolução comprovadamente suficiente. Frente, busto, cabeça/ombros completos, margem transparente e identidade de função.
- Produtos: três quartos, frente à direita, proporções distintas, sem emblemas reais ou texto, fundo transparente.
- Ícones: SVG com viewBox, formas locais, strokes consistentes, pontas arredondadas e gradientes. Não rasterizar formas simples em PNG.
- Cards e efeitos: Controls, StyleBoxes e shaders simples. Não usar screenshots como assets.

A v2 prevalece sobre arte antiga. Não misturar técnicas, proporções ou luz entre retratos. SVG não pode conter raster, fontes, scripts, filtros incompatíveis ou recursos externos. O teste XML verifica o contrato.

Os 43 SVGs estão em svg_inventory.json. refine_v2.py reconstrói ícones, marca, regras e indicadores, mantendo aliases. Renderer Forward+ / Direct3D 12 permanece. Barlow Semi Condensed é usada na marca/títulos/HUD; Roboto permanece no corpo e botões. As duas licenças OFL estão incluídas. Proveniência dos oito PNGs históricos/atuais e prompts: [asset_generation.json](asset_generation.json). Capturas: [VISUAL_VALIDATION.md](VISUAL_VALIDATION.md).

## Fontes oficiais e integridade

Arquivos não modificados obtidos do [repositório oficial Google Fonts](https://github.com/google/fonts/tree/main/ofl/barlowsemicondensed), família de Jeremy Tribby. A [licença OFL](https://github.com/google/fonts/blob/main/ofl/barlowsemicondensed/OFL.txt) foi incluída como BarlowSemiCondensed-OFL.txt, preservando a licença anterior de Roboto.

- `BarlowSemiCondensed-Black.ttf`: SHA-256 `171502596b584862a651426010f14878d8f7a87e6a080a621c0b1cd447a5fefc`.
- `BarlowSemiCondensed-Black.ttf.import`: SHA-256 `b9faf6f463bc352123e43ea686b78cc7dd79bd3e078e5754ba4c17d4de97067c`.
- `BarlowSemiCondensed-ExtraBold.ttf`: SHA-256 `a8096d0dc3ff22ea015d63f436a6856a69e402c12da9991f4a40f2c0bedf44ee`.
- `BarlowSemiCondensed-ExtraBold.ttf.import`: SHA-256 `8e5dcb82110d98d4bf4e8d0257a4dcfd191b660e1486fcfedea53b8d1b096188`.
- `BarlowSemiCondensed-OFL.txt`: SHA-256 `186d750eb496a4c17a76385f82be6aea2ac1cf2de074a811d63786cf374ea73f`.
- `BarlowSemiCondensed-SemiBold.ttf`: SHA-256 `bd299f4bc5b44d30be8d42e9bad3a5df7d66af1cd55d0ed72a8b8916360a1424`.
- `BarlowSemiCondensed-SemiBold.ttf.import`: SHA-256 `6beada5f27cdd4cb9478cbaa77b0b3aabf8abbd0e924d91b9b6ede912c26cf08`.

Não foram geradas ou editadas novas imagens PNG nesta revisão. Cenário, atlas, veículos e ícones existentes foram reutilizados.
