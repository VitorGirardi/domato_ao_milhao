# Pesca e mineração — 0.39.0

Na 0.39, a picareta usa duas mãos, preparação lateral e impacto na face do veio.
Fique a até 1,55 m da pedra para minerar. A coleta exige estar a pé e fora da natação.

Peixes e minérios são novas fontes de renda, com ferramentas próprias e estoque separado dos produtos agrícolas. Escolha seu terreno antes de começar. A partida normal do autor mantém dinheiro infinito; os preços continuam válidos na economia limitada usada pelos testes.

## Comprar ferramentas

Abra o armazém com **F** e escolha **Pesca e mineração**, ou use o botão de peixes, minérios e ferramentas durante a caminhada. A vara custa **$150** e a picareta **$180**. Cada ferramenta é comprada uma vez e não se desgasta nesta versão.

## Pescar

Use **M → Locais** para orientar a viagem. Desmonte e aproxime-se do marcador na margem; pressione **E** para começar. Cada captura leva **8 segundos** e rende um peixe. Pressionar E novamente, afastar-se mais de 1,3 m, pular ou abrir um menu cancela a atividade sem recompensa. Há três pontos de pesca:

| Local | Coordenadas X/Z | Distribuição: tilápia / truta / dourado |
|---|---|---|
| Lago do Sossego | (280, 295) | 75% / 20% / 5% |
| Lago da Serra | (820, -193) | 40% / 45% / 15% |
| Rio Azul | (430, 45) | 20% / 35% / 45% |

A espécie é sorteada ao concluir a captura. Os percentuais não garantem uma sequência de resultados. A vara, a linha e a boia aparecem durante a atividade.

## Comprar a mina e extrair

Use **M → Locais → Mina da Pedra Clara** para marcar o destino e siga as estradas até a serra. Desmonte junto à entrada, em **(900, -216)**, e pressione **E** para abrir o painel. A mina custa **$1.500**; as faixas amarelas e a barreira saem após a compra. Compre também a picareta de **$180**.

O interior tem três setores ligados por corredores, com nove veios. São 17 células conectadas de 8 m: a caverna avança 72 m para dentro da montanha, com aproximadamente 128 m de percurso até o fundo. Essa medida é a extensão horizontal, não uma descida vertical.

| Setor | Veios | Como liberar |
|---|---|---|
| Entrada | Um cobre, um ferro e um quartzo | Comprar mina e picareta |
| Galeria do Ferro | Um cobre e dois ferros | $1.200 + 8 unidades de cobre |
| Salão dos Cristais | Um ferro e dois quartzos | Abrir a Galeria do Ferro; $3.000 + 10 unidades de ferro |

Aproxime-se de cada portão interno e pressione **E** para abrir o painel de desbloqueio. As compras são feitas em sequência e retiram os materiais do estoque compartilhado da fazenda. **Mesmo com dinheiro infinito, é preciso extrair e guardar os minérios exigidos.** Não venda todo o cobre ou ferro se estiver juntando materiais para abrir a próxima passagem.

Com a picareta, aproxime-se de um veio e pressione **E**. A extração leva **5 segundos** e acrescenta uma unidade daquele minério ao estoque. Movimento, pulo, menus ou E cancelam, como na pesca. Cada veio se renova após **120 segundos de tempo ativo da fazenda**; não é um contador de tempo real com o jogo fechado. Os nove veios têm contadores separados, que persistem ao salvar e reabrir a partida. Os três veios da versão anterior continuam acessíveis no setor de entrada, sem exigir a compra de uma galeria.

## Vender

O painel de pesca e mineração mostra quantidade, preço por unidade e total de cada recurso. **Vender** vende todo o estoque daquele tipo. O dinheiro e a receita da fazenda são atualizados; produtos agrícolas e reservas do celeiro não são usados.

| Recurso | Preço por unidade |
|---|---:|
| Tilápia | $18 |
| Truta | $28 |
| Dourado | $45 |
| Cobre | $24 |
| Ferro | $40 |
| Quartzo | $65 |

O limite é de 10.000 unidades por tipo. Venda antes de atingir o limite para continuar coletando. Capturar um peixe concede 3 XP; extrair um minério, 5 XP.

## Cooperativo e saves

Ferramentas, propriedade da mina, galerias abertas, estoque, dinheiro e renovação dos veios são compartilhados pela fazenda cooperativa. Cada jogador pode realizar uma atividade por vez; dois jogadores não podem extrair o mesmo veio simultaneamente. O anfitrião controla duração, requisitos, recompensa e gravação. Falhas de salvamento desfazem a compra, venda ou recompensa; não deixam uma operação parcialmente aplicada.

Atualize **os dois PCs para 0.39.0**: o protocolo de rede é **10**. O formato de save passou para **20**, mantendo a leitura das versões anteriores. Na migração do save 19, ferramentas, propriedade da mina, estoque, contadores de coleta e renovação dos três veios antigos são preservados; as duas galerias começam fechadas, com seis novos veios prontos para coleta após o desbloqueio. Saves anteriores à pesca e mineração começam com esses recursos vazios.

Fazenda, construções e dinheiro infinito são preservados. O save cooperativo permanece separado do solo. Depois de salvar na 0.38, continue nesta versão ou posterior; versões antigas não leem o formato 20.

## Arte e limites

Vara, picareta, peixe e três veios são modelos originais feitos no Blender. Os arquivos editáveis `resource_*.blend` estão em `art/source/`; os GLBs estão em `assets/models/`. O gerador é `tools/build_resource_models.py`.

A mina ampliada também é original Blender: `art/source/region_mine.blend`, `assets/models/region_mine.glb` e gerador `tools/build_region_mine.py`. O desenho dos corredores é compartilhado com `scripts/farm_mine_layout.gd`.

A caverna e os três pontos de pesca são definidos à mão. A mina tem extensão fixa e duas compras de expansão; não há geração procedural de galerias, natação, iscas ou minijogo de fisgada.

## Verificar

Use APPDATA isolado em `test-results`, nunca o save real ou seu backup. `tests/test_resources.gd` cobre economia, migração e rejeição atômica de saves; `tests/test_gathering.gd` cobre duração, cancelamento e reversão quando salvar falha; `tests/test_coop_gathering.gd` exercita dois jogadores pelo executor de rede.

`tests/test_mine_exploration.gd` percorre fisicamente a caverna, verifica bloqueio e abertura dos portões e reversão quando uma compra não consegue salvar. A economia cobre os nove veios, custos minerais, compras fora de ordem, migração do save 19 e rejeição de dados inválidos.

No jogo, compre ferramentas, pesque nos três locais, venda um tipo de peixe e compre a mina na entrada. Extraia os três minérios iniciais, reserve 8 cobres e abra a Galeria do Ferro. Reserve 10 ferros e abra o Salão dos Cristais; caminhe até o fundo e volte à entrada. Confira a renovação dos veios, cancele uma atividade e reabra a fazenda para conferir galerias e estoque. Em dois PCs, confira portões compartilhados, estoque, animações, bloqueio do mesmo veio e preservação da fazenda solo.
