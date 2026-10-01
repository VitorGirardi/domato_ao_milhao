# O Vale e a Serra — 0.37.0

## Explorar

Abra M, escolha o filtro Locais e marque Ponte do Rio Azul, Mirante da Serra,
Lago do Sossego, Lago da Serra ou Mina da Pedra Clara. A estrada sai do circuito
antigo em (160, -20). O primeiro desvio ao sul leva ao lago do vale; a ponte a
leste permite subir à serra. A linha do mapa indica direção direta: siga as estradas
para contornar água e encostas. Use a roda do mouse para aproximar o mapa.

O vale mantém o estilo do jogo: verde, terra batida, céu azul e água azul.
Há 1.084 × 900 m dentro dos limites exploráveis (975.600 m², aproximadamente
15,7 vezes os 62.060 m² anteriores). Isso não representa terreno comprável total.
O mirante chega a 120 m; as propriedades compráveis antigas continuam planas.

## Pesca e mina

A 0.37 acrescenta pesca nos dois lagos e no Rio Azul, compra da Mina da Pedra Clara
e extração de cobre, ferro e quartzo no túnel existente. A mina custa $1.500 e é
comprada na entrada; as faixas e a barreira saem após a compra. Vara e picareta
custam $150 e $180. Use E junto aos pontos de coleta e venda pelo painel de pesca
e mineração. Veja [locais, preços, controles e regras](PESCA_MINERACAO.md).

## Limites desta entrega

Água profunda impede entrada: ainda não há natação. As áreas novas não se tornam
automaticamente propriedades construíveis. O mapa continua finito e desenhado à
mão. Há separação entre dados de região e cenário, mas streaming de terrenos e
geração infinita são trabalhos futuros. A mina usa seu túnel atual; grandes
galerias subterrâneas e mais atividades regionais são aprofundamentos futuros,
sem prazo prometido.

## Preservação e cooperativo

Nada é apagado ou reposicionado nos saves; construções, produção, funcionários,
animais, cavalo e dinheiro infinito permanecem. O save 19 lê as versões anteriores,
iniciando ferramentas, mina e estoque de recursos vazios quando ausentes.
O protocolo é 8: atualize os dois PCs para 0.37 antes de hospedar/entrar.
As posições remotas aceitam toda a região e suas altitudes. Estoque de recursos e
mina são compartilhados; o save cooperativo continua separado do solo. Depois de
salvar na 0.37, use esta versão ou posterior, pois versões anteriores não leem o
formato 19.

## Fontes e implementação

- `scripts/farm_region.gd`: rotas, alturas, água e pontos de interesse com coordenadas estáveis.
- `scripts/farm_region_scenery.gd`: vegetação em lotes por área, colisões e modelos.
- `art/source/region_mine.blend`, `region_bridge.blend`, `region_lookout.blend`: originais Blender; GLBs correspondentes em `assets/models/`.
- `tools/build_region_mine.py` e `tools/build_region_landmarks.py`: geração reproduzível no Blender 5.2.
- `art/source/resource_*.blend` e `tools/build_resource_models.py`: ferramentas, peixe e veios da 0.37.
- Shader de céu acompanha o mesmo relógio do solo/cooperativo; nuvens pausam com ele.
- Terreno e colisão residem em memória nesta etapa; vegetação distante usa culling.

## Verificação

Use dados isolados em `test-results`, nunca o APPDATA real do jogador.
`tests/test_region.gd` verifica alturas antigas, rotas fora da água, inclinações,
colisão dos destinos/ponte e preservação da fazenda; modo gráfico salva capturas.
`tests/test_coop_region.gd`, via `tests/run_network.py`, verifica dois peers na serra,
destinos, save solo isolado e retomada do cavalo na expansão. Os testes da economia
e das atividades estão descritos em [Pesca e mineração](PESCA_MINERACAO.md).

Roteiro manual: seguir a estrada a pé e a cavalo, atravessar a ponte pelos dois
lados, subir ao mirante, visitar ambos os lagos e a mina, conferir margens e
observar dia/noite. Reabrir a fazenda e a sessão cooperativa após salvar.
