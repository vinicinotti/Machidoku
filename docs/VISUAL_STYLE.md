# Materiais e apresentação v2

Etapa vigente: [refinamento P1/P2/P3 e validação em 16:9](REFERENCE_VISUAL_REFINEMENT.md). Os registros anteriores abaixo são históricos quando divergem dessa especificação.

Alvo normativo: [master 1672×941](<reference/Interface de Jogo Machidoku Industrial.png>). Composição em [VISUAL_TARGET.md](VISUAL_TARGET.md).

## Tokens e luz

`visuals.gd`: texto #07244B, azul #07365A, frame #073A53, creme #FFE6CF, papel #FFF7ED, laranja #FF871C, ação #FF681B e amarelo #FFDC47. Coral de erro: #E76F51. A paleta de 12 setores em sector_palette.gd usa tons vivos e CIE76 mínimo 24 entre vizinhos, favorecendo cores distintas antes de reutilizá-las.

Luz superior esquerda, highlights claros e sombras abaixo. Não misturar direções de iluminação.

## Superfícies

V.material mantém os materiais volumosos legados; V.surface usa face única, uma borda e sombra discreta nos cards atuais. Ambos geram SVG procedural em memória e o reutiliza como textura de nove partes em StyleBoxTexture. Gradiente, aro, base e sombra pertencem a Controls reais. Não são screenshots. Textos, estados, foco e input continuam nativos. A textura é armazenada por cor, raio e estado, sem reconstrução por frame.

Moldura: aro creme, bezel navy e bandeja interna, em painéis encadeados. Tile: ColorRect com tile_surface.gdshader calculando distância arredondada, bevel, highlight e sombra. O shader não lê texturas, tempo ou solução. Cor e dimensão mudam somente em eventos de resize. As fronteiras continuam em overlay único: 1,25 px, grid sutil e contorno externo forte, preservando picking, pitch e emissão única de arestas.

## Arte e tipografia

Atlas transparente de dez retratos, cenário opaco e SUV foram gerados com image_gen integrada a partir da v2. Hatch, Sedan e Sport Coupe foram comparados e mantidos na mesma família. PNGs novos têm lado máximo inferior a 2048; AtlasTexture evita duplicar pixels dos retratos. SVGs simples foram refinados com gradientes e primitivas locais.

A marca usa Barlow Semi Condensed Black com espaçamento de glifos +1; títulos usam ExtraBold e labels de HUD usam SemiBold. Roboto permanece nos textos corridos e botões, preservando legibilidade e dimensões. Ambas as famílias têm licença OFL incluída. Textos não são rasterizados em assets. SVGs de 64 unidades são importados em escala 2 para nitidez.

## Vidro estrutural

No desktop há exatamente duas superfícies frosted: uma envolve toda a coluna esquerda e outra envolve toda a Planta Industrial. Os cards internos conservam seus materiais claros, sem vidro aninhado. glass_surface.gd usa frosted_glass.gdshader com cantos arredondados, tint creme de 36% no painel esquerdo e 42% no direito, borda e highlight. Um único BackBufferCopy captura o cenário antes da UI; ambas as superfícies leem o mesmo buffer com mipmaps/LOD 2,6. Não há refração animada, loops de blur ou cópia por card. A mistura mantém respectivamente 64% e 58% do fundo suavizado nas superfícies, sem alterar o PNG, saturação ou material do cenário. No portrait a captura é desativada e os painéis desktop ficam ocultos.

## Identidade cromática

A paleta por adjacência continua inalterada. specialist_art.gd recebe a textura da função e a cor calculada do setor. O mesmo shader specialist_identity.gdshader é aplicado à célula e ao slot. Máscaras procedurais em coordenadas locais do atlas tingem capacete e detalhes de EPI, preservando pele, cabelo, branco e uniforme navy. Parâmetros de matiz se referem às dez artes, nunca a uma fase específica. A silhueta utiliza o mesmo material em estado não revelado. O retrato é desenhado acima do glow, evitando a troca aparente da sua cor durante o acerto.

## Movimento

Especialista correto coordena célula, luz, score e slot do setor. Até três popups simultâneos; o fade começa após leitura. Os efeitos usam posição, escala e opacidade, sem deslocar Containers nem determinar regras. Um slot cancela o tween anterior antes de mudar de estado.

Vidas usam engrenagens SVG laranja; as perdidas são desaturadas. Configurações usam engrenagem creme de tamanho/desenho diferentes. Efeitos reduzidos desativam overshoots novos e pulse do board, mantendo interação e informação.

O cenário usa mipmaps com kernel fixo 3×3 em uma passagem, evitando blocos de mip alto. Não há blur multipasse. Shaders não têm laços nem uniformes de tempo. Isso limita custo; não substitui teste em aparelho mobile.

## Geometria do master

O canvas atual é 1672×941 com safe frame uniforme. BoardPresentation faz somente a transformação visual do interior levemente retangular, mantendo o espaço local do Board e todos os seus métodos de input intactos. A proporção quadrada volta no mobile. Badge e cards não usam a base inferior duplicada dos materiais anteriores. Vidas mantêm engrenagem com contorno quente; configurações preservam botão separado. A geometria completa e os HEX medidos estão em VISUAL_TARGET.md.

## Correção estrutural

Painéis não se sobrepõem à moldura. Cada lateral continua com um único preenchimento frosted, complementado por sombra externa nativa e rim light suave, sem glass aninhado. V.surface acrescenta sombra em dois níveis e highlight superior em uma única face. As linhas da planta são constantes e rolam localmente. Footer tem instruções/score num mesmo componente e a mensagem abaixo. Retratos são enquadrados no espaço interno do tile, incluindo a margem para o overshoot; a clipping area não é usada como substituto de dimensionamento correto.


## Refinamento desktop de proporções

`V.desktop_surface` usa fonte SVG quadrada de 256×256, com cortes de nove partes que não se sobrepõem no destino. Raios e margens respeitam a altura real de cada card. A face clara tem opacidade 0,88, um highlight interno e sombra discreta. O material legado continua disponível para os demais fluxos.

Configurações usa SVG circular 66×66 sem recorte em nove partes, com ícone centralizado nos dois eixos. A moldura desktop usa StyleBoxFlat com curvas nativas contínuas, em vez das texturas com margens assimétricas. O interior e as coordenadas de input do Board são preservados.

Comandos e score têm largura natural, gap 16 e alinhamento central do conjunto. O texto não quebra no desktop. Produção usa padding H16, superior 12 e inferior 20; carro e plataforma compartilham o centro horizontal. O retrato ocupa mais de 82% da altura do tile e permanece dentro dele no maior pop permitido. Nenhum ajuste de layout mobile faz parte desta etapa.
