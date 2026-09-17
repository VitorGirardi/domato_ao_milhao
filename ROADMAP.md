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
| 6 | Gestão e automação | Funcionários, rotinas e máquinas para evitar tarefas repetitivas | A fazer |
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

## Entrega atual — 0.5

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

## Próximo bloco — gestão e automação

- Primeiro ajudante com uma rotina simples de cuidado da fazenda.
- Contratação, custo e benefício visíveis antes de confirmar.
- Pausar ou dispensar o ajudante sem perder produtos ou construções.
- Evoluir para outras rotinas e máquinas depois de validar a primeira.

## Cuidados em todas as etapas

- Preservar salvamentos existentes com migração testada.
- Informar custos e motivos de ações inválidas antes de confirmar.
- Evitar colheita duplicada, saldo negativo e perda de estruturas ao cancelar.
- Testar desempenho conforme aumentam construções e animais.
- Humor deve variar e criar histórias, sem punições grandes ou tarefas constantes.
- Recursos de multiplayer exigem projeto próprio de autoridade, propriedade e persistência.
