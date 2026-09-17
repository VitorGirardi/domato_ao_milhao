# Prioridades — Do Mato ao Milhão

Este é o plano de evolução do jogo. A ordem pode mudar depois de jogar e ouvir o autor.
Cada etapa termina com uma versão jogável, testes e uma atualização no GitHub.
Não são promessas de prazo nem uma lista de tarefas já concluídas.

| Ordem | Etapa | Resultado esperado | Situação |
|---|---|---|---|
| 1 | Interações e primeiros minutos | Entender o jogo sem explicação externa; plantar, regar e colher com resposta visual | Entregue na 0.2; seguirá recebendo ajustes |
| 2 | Construção confortável | Selecionar, mover, girar, traçar cercas/caminhos e personalizar cores | Entregue na 0.3, com traçados retos e pintura por partes |
| 3 | Progressão e construções úteis | Celeiro com função, ferramentas melhores e desbloqueios com propósito | Reserva e primeira melhoria entregues na 0.3; ampliar depois |
| 4 | Animais com personalidade | Nomes, aparência, água, alimentação, ninhos e comportamentos | Primeira entrega na 0.4, com galinhas |
| 5 | Vizinhos e economia regional | Pedidos variados, especialidades, reputação e preços legíveis | Primeira entrega na 0.5; ranchos físicos e economia dinâmica depois |
| 6 | Gestão e automação | Funcionários, rotinas e máquinas para evitar tarefas repetitivas | Primeiro ajudante entregue na 0.6; outras rotinas e máquinas depois |
| 7 | Cadeias produtivas e expansão | Queijo, farinha, novos terrenos e regiões | A fazer |
| 8 | Mundo vivo | Clima, estações, feiras, concursos e acontecimentos engraçados | A fazer |
| 9 | Cooperativo | Amigos em ranchos próprios, visitas e comércio sincronizado | A fazer após estabilizar a campanha solo |

## Entrega anterior — 0.2

- [x] Personagem com braços e pernas articulados durante a caminhada.
- [x] Regador visível ao cuidar da plantação, gotas e resposta sonora própria.
- [x] Colheita com produtos saltando e indicação da quantidade recebida.
- [x] Brotos, plantas jovens e cultivos maduros visualmente distintos.
- [x] Indicações de rega e colheita no próprio canteiro.
- [x] Seleção destacada e grade durante a colocação de construções.
- [x] Mover construções com prévia, giro, cancelamento e validação de sobreposição.
- [x] Objetivos iniciais sequenciais com botão que leva à próxima ação.
- [x] Preservar progresso de objetivos e ler salvamentos da versão 0.1.
- [x] Validar a economia, as interações, o salvamento e o executável Windows.

**Critério de conclusão:** completar o caminho de terreno vazio até primeira venda,
reorganizar a fazenda sem perder plantas ou dinheiro e retomar a partida salva.

## Entrega anterior — 0.3

- [x] Cercas e caminhos por arraste reto, orçamento total e confirmação.
- [x] Cancelamento e rejeição sem construção parcial ou cobrança.
- [x] Pintura separada de paredes, telhados e portas em celeiros e galinheiros.
- [x] Celeiro com reserva compartilhada de 60 produtos por construção, fora da venda geral.
- [x] Bancada com regador de $300 que rega até cinco canteiros em cruz.
- [x] Preservação de saves antigos, reserva e melhorias persistentes.
- [x] Testes de simulação e integração das novas ações.

**Critério de conclusão:** traçar e cancelar sem perda, guardar produtos sem vendê-los
por acidente, melhorar o regador e retomar tudo a partir de uma partida salva.

## Entrega anterior — 0.4

- [x] Nomes editáveis, cores próprias e identificação ao clicar nas galinhas.
- [x] Comedouro e bebedouro feitos no Blender, com conteúdo visível.
- [x] Água e ração influenciando a produção, sem morte dos animais.
- [x] Ninhos com limite, coleta manual e proteção contra perda ou duplicação.
- [x] Fiscalização, dança e reunião da gerente; ciscar e descanso das companheiras.
- [x] Preservar nomes, necessidades e ovos ao mover e salvar.
- [x] Migrar galinheiros antigos com primeira carga de suprimentos, preservando o estoque.
- [x] Validar simulação, interações, interface e salvamento.

**Critério de conclusão:** cuidar, nomear e reconhecer as galinhas; coletar e vender
ovos; salvar e retomar sem perder produção ou suprimentos.

## Entrega anterior — 0.5

- [x] Três vizinhos com especialidades e nove receitas de encomendas.
- [x] Quadro feito no Blender, acessível no mapa, pela interface ou por J.
- [x] Quantidades, pagamento e prazo explícitos antes de aceitar.
- [x] Reputação individual com níveis em 2 e 5 pontos; condições aceitas ficam fixas.
- [x] Venda por produto e quantidade, preservando reservas e ovos no ninho.
- [x] Prazos pausados nas janelas, construção e jogo fechado; sem multas ao desistir ou vencer.
- [x] Persistência e migração das fazendas anteriores, incluindo o pedido introdutório.
- [x] 258 verificações da simulação, testes de interface e recuperação de backup.

**Critério de conclusão:** vender parte da colheita, aceitar e entregar pedidos,
subir de reputação e retomar uma encomenda salva sem reiniciar o prazo.
Preços e tempos ainda precisam do teste do autor para balanceamento.

## Entrega anterior — 0.6

- [x] Zeca do Trato, com aparência própria no Blender e posto junto ao galinheiro.
- [x] Contratação confirmada, custos visíveis e histórico de serviços.
- [x] Coleta de ovos e reposição de suprimentos em um galinheiro escolhido.
- [x] Pausa, retomada, mudança de atribuição e dispensa sem perda de produtos.
- [x] Interrupção sem cobranças parciais quando falta dinheiro.
- [x] Pausa global nos menus, construção e jogo fechado; atribuição persistente.
- [x] Testes de simulação, telas, economia, migração e recuperação de backup.
- [x] Roteiro manual cobrindo também os vizinhos e as vendas da 0.5.

**Critério de conclusão:** contratar, observar a coleta, pausar sem pagar,
trocar de galinheiro e retomar a partida com ajudante e histórico preservados.

## Entrega anterior — 0.7: personagens

- [x] Registrar o conceito cartoon aprovado pelo autor.
- [x] Refazer protagonista e Zeca como modelos editáveis no Blender.
- [x] Preservar as articulações de caminhada, rega e trabalho.
- [x] Conferir modelos reais no Godot, enquadramento, colisão e salvamento.
- [x] Atualizar o gerador reproduzível e o roteiro de teste visual.

A direção visual seguirá recebendo ajustes com a avaliação dentro do jogo.
Expressões animadas e personalização de roupas ficam para outra etapa.

## Entrega anterior — 0.8: anatomia e animais

- [x] Corpo humano contínuo e proporções menos arredondadas.
- [x] Rig de 20 ossos, pesos e revisão de cotovelos/joelhos dobrados.
- [x] Adaptar caminhada, corrida, rega e trabalho ao esqueleto.
- [x] Galinhas com nova silhueta, penas e patas alternadas.
- [x] Revisar os GLBs reais no Godot e preservar a integração do jogo.

## Entrega anterior — 0.9: ações visíveis

- [x] Corrigir cabelo/chapéu e orientação do regador.
- [x] Ronda local, acesso ao ninho e coleta animada do Zeca.
- [x] Evitar cobrança de serviço quando não há acesso ao ninho.
- [x] Comerciante própria: Dona Lúcia.

## Direção da automação

- Ajustar os custos do Zeca com o teste do autor.
- [x] Rotina de lavoura com rega, colheita e replantio.
- Evoluir deslocamento, postos e capacidade de trabalho antes de vários funcionários.
- Depois, avançar para cadeias produtivas e expansão regional.

## Cuidados em todas as etapas

- Preservar salvamentos existentes com migração testada.
- Informar custos e motivos de ações inválidas antes de confirmar.
- Evitar colheita duplicada, saldo negativo e perda de estruturas ao cancelar.
- Testar desempenho conforme aumentam construções e animais.
- Humor deve variar e criar histórias, sem punições grandes ou tarefas constantes.
- Recursos de multiplayer exigem projeto próprio de autoridade, propriedade e persistência.


## Entrega 0.10 — funções das construções e irrigação

- [x] Revisar cabelo dos três personagens em quatro ângulos.
- [x] Celeiro com painel de estoque/reserva na entrada.
- [x] Oficina rural independente para bancada de melhorias.
- [x] Irrigação do Zeca com seleção, custo informado e animação.
- [x] Compatibilidade com saves anteriores e testes de economia/rotas.
- [ ] Interior explorável do celeiro.
- [ ] Novas ferramentas e máquinas na oficina rural.


## Entrega 0.11 — investir e ver a fazenda crescer

- [x] Dois níveis de celeiro, galinheiro e oficina, com prévia de compra.
- [x] Benefícios reais de capacidade, produção e ferramentas.
- [x] Detalhes visuais próprios por evolução, preservando a área ocupada.
- [x] Pulo em Espaço, pose no ar, aterrissagem e colisão nos telhados.
- [x] Save compatível e testes de custos, migração e interação.
- [ ] Ajustar preços e ritmo de progressão a partir do teste do jogador.

- [x] Equipe inicial de dois ajudantes trabalhando simultaneamente.
- [x] Contratação, pausa e treinamento por pessoa, com gastos separados.
- [x] Plantio e colheita configuráveis com Bento.
- [ ] Novas vagas e transporte.

## Entrega atual — 0.12: clareza e automação

- [x] Menus de interação com ícones, menos texto e ações evidentes.
- [x] Colher e replantar com Bento; tarefas independentes e cultura por canteiro.
- [x] Orçamento incluindo sementes, pausa segura e renovação explícita.
- [x] Relatório de produção e gastos, persistência e migração.
- [x] Revisão visual, integração e teste de ciclo completo sem venda automática.
- [ ] Ajustar legibilidade e ritmo após o teste do jogador.
