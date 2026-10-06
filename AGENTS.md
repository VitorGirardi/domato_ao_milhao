# Regras permanentes do projeto

## Preferência de Vitor — dinheiro infinito

A pedido de Vitor, cada nova fazenda escolhe Survival (economia limitada, $1.600 iniciais e progressão) ou Sandbox (dinheiro infinito, exibido como ∞, e catálogo/equipamentos liberados). Preserve o modo escolhido ao salvar e carregar. Saves anteriores à escolha de modos mantêm o dinheiro infinito e seu progresso original. Nunca apague ou reinicie uma fazenda para aplicar essa preferência. Cada fazenda tem seu save; criar outra não substitui as existentes.

No Sandbox, todos os produtos e minérios são infinitos, assim como a reserva de munição; preserve isso também em saves Sandbox anteriores. Consulte `FarmState.stock/stock_text/consume_stock` para disponibilidade e consumo. Os contadores físicos continuam finitos na serialização. Survival e saves Original não recebem recursos infinitos apenas por terem dinheiro infinito.

Os testes de economia usam FarmState com dinheiro limitado por padrão, em arquivos QA isolados. Nunca sobrescreva farm_v1.json ou seu backup para testar. Preços, requisitos de nível e recursos de produção continuam existindo no Survival.

## Direção do mapa

O cenário natural ocupa terrenos ainda não comprados. Comprar ou expandir limpa apenas elementos naturais que interferem na área adquirida, preservando construções do jogador e marcos públicos. Cavalo como transporte foi implementado na 0.23; preservar montaria, desmontagem segura, tapinha para galopar e fôlego. Camionetinha de roça é um protótipo solo na 0.45; preservar direção e posição por fazenda. Carga de até 60 unidades e painel com volante foram adicionados na 0.47; preservar carga por fazenda e os recursos infinitos do Sandbox. A garagem da 0.49 oferece melhorias permanentes (caçamba de 120, pneus, motor e bagageiro), pintura e nome; preservar essa configuração por fazenda. Cuidados/progressão do cavalo e veículos cooperativos são planos futuros; manter caminhos largos.

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

## Vizinhos e entregas

As casas fixas dos moradores ficam fora dos terrenos compráveis. Preserve descobertas, pedidos, confiança e influência por fazenda. Entregas consomem carga real da camionetinha, com validação de proximidade e gravação antes da confirmação; permanecem solo enquanto o veículo for solo. No Sandbox, o estoque é infinito, a caçamba continua finita.

A história da horta de Dona Rosa (0.53) usa `rosa_story` independente dos pedidos comuns: nunca altere a carga de uma encomenda já aceita ao avançar a história. A rotina mantém atendimento fixo na entrada. O Canteiro da amizade libera ao concluir a história no Survival e desde o início no Sandbox.

## Prioridade permanente de Vitor — animações e movimentação

Priorize sempre animações e movimentações nas mudanças do jogo. Ao criar ou evoluir personagens, animais ou veículos, comece pelas poses, proporções, passadas, curvas e transições entre movimento e repouso. Conecte a mecânica e os menus depois que essa base estiver coerente. Valide visualmente o resultado e confira deslocamento, colisões, terreno e sincronização cooperativa quando aplicáveis, preservando as ações já publicadas.
