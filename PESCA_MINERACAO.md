# Pesca e mineração — 0.37.0

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

Viaje até a **Mina da Pedra Clara**, na serra. A compra custa **$1.500** e só pode ser concluída junto à entrada, em **(900, -216)**. As faixas amarelas e a barreira saem quando a mina é adquirida, liberando acesso ao túnel existente.

Com a picareta, aproxime-se de um dos três veios — cobre, ferro ou quartzo — e pressione **E**. A extração leva **5 segundos** e acrescenta uma unidade daquele minério ao estoque. Movimento, pulo, menus ou E cancelam, como na pesca. Cada veio se renova após **120 segundos de tempo ativo da fazenda**; não é um contador de tempo real com o jogo fechado. Os três veios têm contadores separados, que persistem ao salvar e reabrir a partida.

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

Ferramentas, propriedade da mina, estoque, dinheiro e renovação dos veios são compartilhados pela fazenda cooperativa. Cada jogador pode realizar uma atividade por vez; dois jogadores não podem extrair o mesmo veio simultaneamente. O anfitrião controla duração, requisitos, recompensa e gravação. Falhas de salvamento desfazem a compra, venda ou recompensa; não deixam uma operação parcialmente aplicada.

Atualize **os dois PCs para 0.37.0**: o protocolo de rede é **8**. O formato de save passou para **19**, mantendo a leitura das versões anteriores e iniciando os novos recursos vazios nos saves antigos. Fazenda, construções e dinheiro infinito são preservados. O save cooperativo permanece separado do solo. Depois de salvar na 0.37, continue nesta versão ou posterior; versões antigas não leem o formato 19.

## Arte e limites

Vara, picareta, peixe e três veios são modelos originais feitos no Blender. Os arquivos editáveis `resource_*.blend` estão em `art/source/`; os GLBs estão em `assets/models/`. O gerador é `tools/build_resource_models.py`.

Esta etapa usa o túnel atual da mina e os três pontos de pesca definidos à mão. Não há natação, iscas, minijogo de fisgada, grandes galerias subterrâneas ou geração procedural. Aprofundar cavernas, pesca e progressão regional são possibilidades futuras, sem prazo prometido.

## Verificar

Use APPDATA isolado em `test-results`, nunca o save real ou seu backup. `tests/test_resources.gd` cobre economia, migração e rejeição atômica de saves; `tests/test_gathering.gd` cobre duração, cancelamento e reversão quando salvar falha; `tests/test_coop_gathering.gd` exercita dois jogadores pelo executor de rede.

No jogo, compre ferramentas, pesque nos três locais, venda um tipo de peixe, compre a mina na entrada e extraia os três minérios. Confira o contador de renovação, cancele uma atividade e reabra a fazenda. Em dois PCs, confira estoque compartilhado, animações, bloqueio do mesmo veio e preservação da fazenda solo.
