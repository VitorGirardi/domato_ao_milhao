# Movimento do personagem

A caminhada e a corrida usam ciclos trabalhados no Blender, com apoio dos pés,
movimento do quadril, contrarrotação dos ombros e braços menos rígidos. A transição
entre andar, correr e parar é gradual. Cabeça e tronco acompanham as curvas.

As animações seguem o deslocamento real do personagem e funcionam com fazendeiro
e fazendeira, tanto no solo quanto no cooperativo. A velocidade e os controles
continuam os mesmos: WASD para andar, Shift para correr.

Esta primeira etapa trata da locomoção. As ações de trabalho, mira, montaria,
direção, nado e queda mantêm seus próprios controles de pose.

Fonte editável: `art/source/locomotion.blend`. O gerador
`tools/build_locomotion.py` exporta as amostras usadas pelo jogo em
`assets/animations/locomotion.gd`.
