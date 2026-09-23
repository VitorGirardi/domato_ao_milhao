# Regras permanentes do projeto

## Preferência de Vitor — dinheiro infinito

A partida normal do autor deve iniciar e continuar com dinheiro infinito, exibido como ∞. Preserve essa regra nas próximas versões; só a remova se Vitor pedir explicitamente. Saves antigos também recebem o modo ao serem abertos. Não use essa preferência para apagar ou reiniciar a fazenda.

Os testes de economia usam FarmState com dinheiro limitado por padrão, em arquivos QA isolados. Nunca sobrescreva farm_v1.json ou seu backup para testar. Preços, requisitos de nível e recursos de produção continuam existindo.

## Direção do mapa

O cenário natural ocupa terrenos ainda não comprados. Comprar ou expandir limpa apenas elementos naturais que interferem na área adquirida, preservando construções do jogador e marcos públicos. Cavalo como transporte foi implementado na 0.23; preservar montaria, desmontagem segura, tapinha para galopar e fôlego. Cuidados/progressão e veículos são planos futuros; manter caminhos largos.

## Coordenação entre sessões

Cada sessão trabalha em sua própria worktree e branch. Não faça checkout, stash ou edição na pasta de outra sessão. Entregue mudanças por PR; não faça push direto na main nem merge sem instrução explícita do autor. Combine arquivos e pontos de integração antes de dividir tarefas.
