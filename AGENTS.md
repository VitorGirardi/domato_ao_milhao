# Regras permanentes do projeto

## Preferência de Vitor — dinheiro infinito

A partida normal do autor deve iniciar e continuar com dinheiro infinito, exibido como ∞. Preserve essa regra nas próximas versões; só a remova se Vitor pedir explicitamente. Saves antigos também recebem o modo ao serem abertos. Não use essa preferência para apagar ou reiniciar a fazenda.

Os testes de economia usam FarmState com dinheiro limitado por padrão, em arquivos QA isolados. Nunca sobrescreva farm_v1.json ou seu backup para testar. Preços, requisitos de nível e recursos de produção continuam existindo.

## Direção do mapa

O cenário natural ocupa terrenos ainda não comprados. Comprar ou expandir limpa apenas elementos naturais que interferem na área adquirida, preservando construções do jogador e marcos públicos. Cavalo como transporte foi implementado na 0.23; preservar montaria, desmontagem segura, tapinha para galopar e fôlego. Cuidados/progressão e veículos são planos futuros; manter caminhos largos.

## Coordenação entre sessões

Cada sessão trabalha em sua própria worktree e branch. Não faça checkout, stash ou edição na pasta de outra sessão. Entregue mudanças por PR; não faça push direto na main. A autorização permanente de integração abaixo se aplica às tarefas solicitadas por Vitor. Combine arquivos e pontos de integração antes de dividir tarefas.

## Entrega contínua autorizada por Vitor — 23/09/2026

Ao concluir uma tarefa solicitada por Vitor:

1. Execute a validação apropriada, suba o código por PR e integre a entrega validada. Para mudanças no jogo, publique os pacotes Windows e Linux compatíveis no GitHub Releases, disponíveis pelo launcher, e confira os arquivos publicados e a atualização. Alterações apenas de documentação não exigem novo binário.
2. Depois da publicação, consulte o estado atual da tarefa `trabalhador01` (thread `01a0cc08-9908-7f13-96f4-a695fc5c350e`). Verifique PRs, commits, dependências e evidências de testes das entregas concluídas; não deduza conclusão apenas pelo nome da tarefa ou pela existência de uma PR.
3. Se houver entregas concluídas e ainda ausentes da versão publicada, integre-as em uma worktree própria, resolva conflitos, preserve as funcionalidades já publicadas, teste a combinação e publique uma nova versão. Não deixe trabalho pronto fora da release sem informar uma razão concreta. Não inclua trabalho ainda em andamento como se estivesse pronto.
4. Coordene a publicação com trabalhador01 para evitar releases concorrentes. Se ele estiver trabalhando, informe esse estado e combine a entrega para a próxima publicação; não espere indefinidamente nem interrompa sua tarefa.
5. Informe a versão efetivamente publicada, como atualizar/testar e qualquer pendência real. Preserve saves, backups e dinheiro infinito. Nunca anuncie uma atualização disponível antes de verificar a publicação.

Esta é autorização permanente para integrar/mesclar PRs das tarefas do jogo solicitadas por Vitor e publicar suas versões após validação, sem pedir confirmação novamente a cada entrega. Não autoriza integrar indiscriminadamente todas as PRs históricas nem trabalho alheio ao escopo. Não cria monitoramento periódico: a conferência acontece na conclusão das tarefas e nas entregas coordenadas.
