# O Vale e a Serra ? 0.36.0

## Explorar

Abra M, escolha o filtro Locais e marque Ponte do Rio Azul, Mirante da Serra,
Lago do Sossego, Lago da Serra ou Mina da Pedra Clara. A estrada sai do circuito
antigo em (160, -20). O primeiro desvio ao sul leva ao lago do vale; a ponte a
leste permite subir ? serra. A linha do mapa indica dire??o direta: siga as estradas
para contornar ?gua e encostas. Use a roda do mouse para aproximar o mapa.

O vale mant?m o estilo do jogo: verde, terra batida, c?u azul e ?gua azul.
H? 1.084 ? 900 m dentro dos limites explor?veis (975.600 m?, aproximadamente
15,7 vezes os 62.060 m? anteriores). Isso n?o representa terreno compr?vel total.
O mirante chega a 120 m; as propriedades compr?veis antigas continuam planas.

## Limites desta entrega

Pesca, compra de minas, extra??o e venda de min?rios ainda n?o est?o implementadas.
A mina permanece interditada com faixas amarelas; lagos s?o locais de explora??o
preparados para a pr?xima etapa. ?gua profunda impede entrada: ainda n?o h? nata??o.
As ?reas novas n?o se tornam automaticamente propriedades constru?veis.
O mapa continua finito e desenhado ? m?o. H? separa??o entre dados de regi?o e
cen?rio, mas o streaming de terrenos e a gera??o infinita s?o trabalhos futuros.

## Preserva??o e cooperativo

Nada ? apagado ou reposicionado nos saves; constru??es, produ??o, funcion?rios,
animais, cavalo e dinheiro infinito permanecem. Formato de save inalterado.
O protocolo passou de 6 para 7: atualize os dois PCs antes de hospedar/entrar.
As posi??es remotas aceitam agora toda a regi?o e suas altitudes. O save cooperativo
continua separado do solo. Um cavalo salvo na regi?o nova exige vers?o 0.36 ou posterior;
evite voltar ? 0.35 depois de salvar nessa ?rea.

## Fontes e implementa??o

- `scripts/farm_region.gd`: rotas, alturas, ?gua e pontos de interesse com coordenadas est?veis.
- `scripts/farm_region_scenery.gd`: vegeta??o em lotes por ?rea, colis?es e modelos.
- `art/source/region_mine.blend`, `region_bridge.blend`, `region_lookout.blend`:
  originais Blender; GLBs correspondentes em `assets/models/`.
- `tools/build_region_mine.py` e `tools/build_region_landmarks.py`: gera??o reproduz?vel no Blender 5.2.
- Shader de c?u acompanha o mesmo rel?gio do solo/cooperativo; nuvens pausam com ele.
- Terrain/colis?o residem em mem?ria nesta etapa; vegeta??o distante usa culling.

## Verifica??o

Use dados isolados em `test-results`, nunca o APPDATA real do jogador.
`tests/test_region.gd` verifica alturas antigas, rotas fora da ?gua, inclina??es,
colis?o dos destinos/ponte e preserva??o da fazenda; modo gr?fico salva capturas.
`tests/test_coop_region.gd`, via `tests/run_network.py`, verifica dois peers na serra,
destinos, save solo isolado e retomada do cavalo na expans?o.

Roteiro manual: seguir a estrada a p? e a cavalo, atravessar a ponte pelos dois
lados, subir ao mirante, visitar ambos os lagos e a mina, conferir margens e
observar dia/noite. Reabrir a fazenda e a sess?o cooperativa ap?s salvar.
