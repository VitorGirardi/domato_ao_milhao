# Fazendas e modos — 0.42

No menu inicial, abra **Minhas fazendas** para retomar um save ou criar outra fazenda. Escolha nome, modo e personagem antes de entrar no mundo. O modo fica fixo nesse save.

- **Survival:** fazenda vazia, $1.600 iniciais, compras descontam do saldo e construções são liberadas pela progressão. O terreno inicial custa $400.
- **Sandbox:** dinheiro e recursos ∞: cenoura, trigo, milho, ovos, leite, queijo, tilápia, truta, dourado, cobre, ferro e quartzo. Vendas, encomendas e produção não consomem esses estoques. A reserva de munição é infinita; a P-8 ainda usa seu carregador e recarga normais. Catálogo completo, regadores melhorados, vara, picareta e mina/galerias disponíveis. Vale também ao abrir saves Sandbox anteriores, preservando a fazenda e seu progresso. Construções e animais continuam sendo colocados pelo jogador; o cenário não vem preenchido.
- **Original:** saves anteriores conservam o progresso e o dinheiro infinito, sem alterar os desbloqueios que tinham.

Os saves novos ficam em `farms/`, dentro da pasta de dados do jogo. O `farm_v1.json` original permanece no mesmo lugar. Cada save tem seu backup; `Continuar` lembra a última fazenda selecionada. Criar outra não substitui nem arquiva a atual. O cooperativo continua separado, agora associado à fazenda selecionada, e respeita o modo do anfitrião. Ambos os jogadores precisam da mesma versão (protocolo 16).

As ações amarelas de objetivos fecham o painel antes de selecionar uma ferramenta ou abrir a tela de destino. Os atalhos de caminhada ficam à esquerda, discretos e iluminados ao passar o mouse ou focar pelo teclado. O minimapa fica no alto à direita, com o dinheiro logo abaixo.

## Verificação manual

1. Abra a fazenda antiga, salve e volte ao menu.
2. Crie uma Survival; compre o terreno e confira o saldo $1.200. Salve e volte ao menu.
3. Crie uma Sandbox, confira ∞ e todas as categorias de construção liberadas.
4. Alterne entre as três fazendas; confira nomes, personagens e progressos independentes. Reinicie o jogo: `Continuar` deve abrir a última selecionada.
5. Em Objetivos, clique no botão amarelo: construção/cuidado volta ao campo; armazém abre a tela correspondente.
6. Confira a coluna lateral, o destaque com mouse/teclado e minimapa/gold sem sobreposição. Teste também montado e em cooperativo.

Automação: `tests/test_farm_slots.gd` com APPDATA/XDG_DATA_HOME isolados em `test-results`; nunca usar saves pessoais. Cobre migração, modos, slots, backups, falhas de criação, cooperativo e ações de objetivos. As imagens `farms-new.png`, `farms-list.png` e `farms-hud.png` são geradas quando executado com renderização gráfica.
