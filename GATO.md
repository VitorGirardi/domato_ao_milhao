# Companheiro felino

Um gato aparece gratuitamente depois que a fazenda é criada, tanto em partidas novas quanto em saves existentes. A primeira aparência é caramelo com peito/patas claros e olhos verdes e coleira vermelha com medalhinha dourada. A revisão visual reduz pernas e corpo, assenta as orelhas dentro da cabeça, remove marcas salientes do rosto e embute o peito claro na superfície. O modelo e a fonte Blender são originais; `tools/build_cat.py` reproduz `art/source/cat.blend` e `assets/models/cat.glb`.

O gato circula perto de um ponto livre da propriedade, para quando o jogador chega perto e alterna descanso sentado com observação. Cabeça, orelhas, olhos e patas têm articulações; a cauda usa uma malha contínua com sete ossos. `FarmCatPose` controla respiração, piscadas, marcha de quatro fases, transição para sentar e reação ao carinho. A escala de gameplay é 72% da fonte.

Chegue perto e use **E — Fazer carinho no gato**. Ele se volta para o jogador, inclina a cabeça, fecha os olhos e movimenta as orelhas e a cauda durante aproximadamente três segundos. A interação não prende o jogador nem interfere na montaria, ferramentas ou diálogos. Nesta etapa a reação é do gato; não há animação nova de agachar/tocar com a mão do personagem. Não há fome, compra, produção, morte ou punição.

## Mundo e rede

- Uma instância por fazenda, criada por `FarmWorld`. Comportamento local em solo; só o host decide movimento/reação no cooperativo.
- Pontos e passos evitam construções e colisões do cenário. Se uma construção ocupar seu ponto, o gato procura outro espaço. Quando não há espaço livre, aguarda uma reconstrução/mudança do mundo; não remove objetos para aparecer.
- Não tem colisão sólida: não bloqueia jogador ou portas. Não segue jogadores pelo mapa nem usa navegação de longa distância.
- Proximidade e intervalo entre carinhos são validados pelo host. Posição do visitante deve ter atualização recente. A apresentação é replicada pelo contrato existente `FarmCoopVisuals`, incluindo os ossos da cauda.
- Protocolo **5**, pois há uma nova RPC. Os dois jogadores devem atualizar. Save permanece **18**; posição e reações são transitórias e não modificam economia ou o arquivo da fazenda.
- Reconstruções/sessões recriam o ponto de descanso. Nome personalizado, pelagens selecionáveis, sons, seguir, dormir e animação de carinho do humano ficam fora desta primeira entrega.

## QA isolado

`tests/test_cat.gd` verifica poses, interação real no jogo, bloqueio de carinho distante/repetido, invariância do estado e captura/replicação visual. `--cat-film` grava sequências PNG de idle, marcha, sentado e carinho.

`tests/test_coop_cat.gd`, executado por `tests/run_network.py --test test_coop_cat`, usa dois processos reais e confirma carinho do visitante, recusa à distância, repetição, pose recebida e saves solo preservados. Ambos integram a CI Linux.

Esta PR parte da entrega dos porcos (PR20). Não publica release e não modifica o launcher.
