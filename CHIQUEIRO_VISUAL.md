# Chiqueiro — conjunto visual

Conjunto original de Blender no estilo do jogo: cerca de madeira, portão com emblema de focinho, abrigo de telhas, cama de palha, cocho de ração, bebedouro com torneira e área de lama com marcas de cascos.

Esta entrega contém **somente assets e prévia**. Não adiciona construção à loja, custos, produção, save, colisões ou navegação. Os três porcos mostrados no teste são figurantes de prévia; não definem a capacidade futura.

## Peças

| Arquivo em assets/models | Uso |
| --- | --- |
| pigsty.glb | Conjunto montado, sem porcos embutidos |
| pig_shelter.glb | Abrigo com palha |
| pig_feeder.glb | Cocho e ração independente |
| pig_waterer.glb | Bebedouro e água independente |
| pig_mud.glb | Lama e marcas de cascos |

Cada GLB tem fonte correspondente em `art/source`. O builder `tools/build_pigsty.py` reconstrói as cinco peças sem modificar animais ou outros prédios. As partes estáticas são agrupadas por componente para reduzir superfícies e nós.

## Contrato de integração (coordenadas Godot)

- Origem no centro do cercado, Y no chão, frente em +Z. Reservar retângulo **8 × 6 m**, incluindo os postes. Abrigo fica no fundo esquerdo; ração ao fundo direito e água à frente direita.
- `GateHinge` em **(1.1, 0, 2.7)**. Fechado: rotação Y = 0. Aberto para dentro: **−PI/2**. `GateLeaf` é filho do pivô. Vão nominal de 2.2 m; vão útil aproximado de 2.02 m entre os postes.
- Reservar área de varredura do portão e checar pessoas/animais antes de fechar. O modelo não implementa colisão. `GateApproach` em (0, 0, 3.15) indica o ponto exterior de interação, além do footprint.
- `FeedTrough/FeedFill` e `WaterTrough/WaterFill`: ocultar o fill quando vazio. Para nível parcial, ajustar **scale.y entre 0.01 e 1**; o pivô fica próximo do fundo do recipiente. O suporte e as paredes não dependem dessa escala. Em instância autônoma, localizar por nome recursivo a partir da raiz importada.
- `PigShelter`, `MudPatch` e `PigSpawn1/2/3` são nós estáveis. Os spawns são apenas referências; validar ocupação/colisão ao criar animais na integração. Y = −0.015 no chão, 0.015 na lama e 0.06 na palha, compensando a base dos cascos do modelo atual.
- Comprimento máximo do abrigo: cerca de 3.6 m, altura 2.54 m. Não mudar escala do porco para caber: o abrigo foi conferido com o modelo atual em escala 1.
- Ao integrar multiplayer, host controla conteúdo e portão. Replicar visibilidade/escala dos fills e transformação do pivô, ou derivar dos estados autoritativos. Os marcadores não são entidades de rede.
- Dinheiro infinito, saves e sistemas existentes permanecem como estão.

## Rebuild e validação

```text
blender --background --python tools/build_pigsty.py
godot --headless --editor --path . --import --quit
godot --path . --audio-driver Dummy --script tests/test_pigsty_assets.gd
godot --headless --path . --audio-driver Dummy --script tests/test_pigsty_assets.gd
```

O teste não instancia o jogo nem abre saves. Confere os cinco imports, materiais, agrupamento estático, hierarquia do portão, marcadores e separação dos níveis de ração/água. Em modo gráfico gera capturas de frente, verso, aberto, fechado, níveis baixos e vazios em `test-results/pigsty`. A opção `-- --pigsty-film` grava 180 frames de prévia. Para testes usar APPDATA/XDG_DATA_HOME isolados como nas demais rotinas de QA.
