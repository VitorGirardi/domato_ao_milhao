# Prioridades — Do Mato ao Milhão

Este é o plano de evolução do jogo. A ordem pode mudar depois de jogar e ouvir o autor.
Cada etapa termina com uma versão jogável, testes e uma atualização no GitHub.
Não são promessas de prazo nem uma lista de tarefas já concluídas.

| Ordem | Etapa | Resultado esperado | Situação |
|---|---|---|---|
| 1 | Interações e primeiros minutos | Entender o jogo sem explicação externa; plantar, regar e colher com resposta visual | Entregue na 0.2; seguirá recebendo ajustes |
| 2 | Construção confortável | Selecionar, mover, girar, traçar cercas/caminhos e personalizar cores | Entregue na 0.3, com traçados retos e pintura por partes |
| 3 | Progressão e construções úteis | Celeiro com função, ferramentas melhores e desbloqueios com propósito | Reserva e primeira melhoria entregues na 0.3; ampliar depois |
| 4 | Animais com personalidade | Nomes, aparência, água, alimentação, ninhos e comportamentos | A fazer |
| 5 | Vizinhos e economia regional | Pedidos variados, especialidades, reputação e preços legíveis | A fazer |
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

## Entrega atual — 0.3

- [x] Cercas e caminhos por arraste reto, orçamento total e confirmação.
- [x] Cancelamento e rejeição sem construção parcial ou cobrança.
- [x] Pintura separada de paredes, telhados e portas em celeiros e galinheiros.
- [x] Celeiro com reserva compartilhada de 60 produtos por construção, fora da venda geral.
- [x] Bancada com regador de $300 que rega até cinco canteiros em cruz.
- [x] Preservação de saves antigos, reserva e melhorias persistentes.
- [x] Testes de simulação e integração das novas ações.

**Critério de conclusão:** traçar e cancelar sem perda, guardar produtos sem vendê-los
por acidente, melhorar o regador e retomar tudo a partir de uma partida salva.

## Próximo bloco — animais com personalidade

- Nomes para as galinhas e identificação ao selecionar.
- Comedouro e bebedouro com estados visuais claros.
- Bem-estar influenciando a produção, sem punições bruscas durante a aprendizagem.
- Coleta de ovos nos ninhos e comportamentos variados para a Maricota.
- Ajustar preços e tempos com base no teste do autor; balanceamento segue pendente.

## Cuidados em todas as etapas

- Preservar salvamentos existentes com migração testada.
- Informar custos e motivos de ações inválidas antes de confirmar.
- Evitar colheita duplicada, saldo negativo e perda de estruturas ao cancelar.
- Testar desempenho conforme aumentam construções e animais.
- Humor deve variar e criar histórias, sem punições grandes ou tarefas constantes.
- Recursos de multiplayer exigem projeto próprio de autoridade, propriedade e persistência.
