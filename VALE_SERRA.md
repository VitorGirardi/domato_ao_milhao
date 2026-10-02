# O Vale e a Serra — 0.40.0

## Explorar

Abra M, escolha o filtro Locais e marque Ponte do Rio Azul, Mirante da Serra,
Lago do Sossego, Lago da Serra ou Mina da Pedra Clara. A estrada sai do circuito
antigo em (160, -20). O primeiro desvio ao sul leva ao lago do vale; a ponte a
leste permite subir à serra. A linha do mapa indica direção direta: siga as estradas
para contornar água e encostas. Use a roda do mouse para aproximar o mapa.

O vale mantém o estilo do jogo: verde, terra batida, céu azul e água azul.
Há 1.115 × 900 m dentro dos limites exploráveis (1.003.500 m², aproximadamente
16,2 vezes os 62.060 m² anteriores). Isso não representa terreno comprável total.
O mirante chega a 120 m; as propriedades compráveis antigas continuam planas.

## Pesca e mina

Há pesca nos dois lagos e no Rio Azul e mineração na Mina da Pedra Clara.
A mina custa $1.500 e é comprada na entrada; as faixas e a barreira saem após a
compra. Vara e picareta custam $150 e $180. Use E junto aos pontos de coleta e
venda pelo painel de pesca e mineração.

A 0.38 amplia o interior com três setores, nove veios e corredores originais
Blender. A caverna se estende 72 m para dentro da montanha, com aproximadamente
128 m de caminhada até o fundo. Em **M → Locais**, marque a mina; já dentro dela,
use **E junto aos portões** para abrir a Galeria do Ferro ($1.200 + 8 cobres) e,
depois, o Salão dos Cristais ($3.000 + 10 ferros). Os materiais continuam sendo
exigidos com dinheiro infinito. Veja [controles e regras](PESCA_MINERACAO.md).

## Limites desta entrega

A pé, o personagem entra gradualmente na água e nada automaticamente no fundo.
Use os controles normais para nadar e voltar à margem; correr aumenta a velocidade.
O rio tem correnteza leve. Cavalo e gato permanecem nas margens. A cachoeira fica
ao norte do Lago da Serra, em (810, -266), com queda, espuma e som ambiente.
O cavalo ajusta cascos, corpo e sela à inclinação do chão.

O riacho junto ao armeiro também permite entrar e nadar. As duas margens são
acessíveis, com uma ponte curta em z=30 para atravessar a pé ou a cavalo.
O poço da cachoeira cobre toda a base da queda; as pedras laterais e o fundo
rochoso bloqueiam a passagem para dentro da montanha.

Assobie com C para chamar o cavalo desocupado de qualquer distância. Ele vem
por caminhos e pontes; na água espera na margem, e na mina espera na entrada.

As áreas novas não se tornam
automaticamente propriedades construíveis. O mapa continua finito e desenhado à
mão. Há separação entre dados de região e cenário, mas streaming de terrenos e
geração infinita não estão implementados. A mina tem nove veios e duas galerias
desbloqueáveis em um interior fixo; não gera novos corredores durante a partida.

## Preservação e cooperativo

Construções, produção, funcionários, animais, cavalo e dinheiro infinito são
preservados. O save 20 lê as versões anteriores. Ao migrar o save 19, mantém
ferramentas, mina, estoque e a renovação dos três veios antigos; as novas galerias
começam fechadas. Saves mais antigos recebem recursos vazios quando ausentes.
O protocolo é 11: atualize os dois PCs para 0.40 antes de hospedar/entrar.
As posições remotas aceitam toda a região e suas altitudes. Estoque de recursos,
mina e galerias abertas são compartilhados; o save cooperativo continua separado
do solo. Depois de salvar na 0.38, use esta versão ou posterior, pois versões
anteriores não leem o formato 20.

## Fontes e implementação

- `scripts/farm_region.gd`: rotas, alturas, água e pontos de interesse com coordenadas estáveis.
- `scripts/farm_region_scenery.gd`: vegetação em lotes por área, colisões e modelos.
- `scripts/farm_mine_layout.gd`: desenho dos corredores e passagens da mina.
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
observar dia/noite. Na mina, abrir as duas galerias, percorrer os corredores até
o fundo e voltar. Reabrir a fazenda e a sessão cooperativa após salvar.
`tests/test_mine_exploration.gd` verifica percurso físico, portões e reversão de
compras quando salvar falha.
