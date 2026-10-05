# Camionetinha de roça — protótipo solo

Uma picape verde e creme, com caçamba de madeira, pneus de terra e faróis redondos. Modelo original feito no Blender; fonte em `art/source/farm_pickup.blend` e gerador em `tools/build_farm_pickup.py`. Caixas e produtos da carga são gerados no jogo.

Ela fica emprestada perto do armazém da Lúcia, nas fazendas Survival e Sandbox. No mapa, procure **Companhia → Camionetinha · protótipo**. Se uma construção ocupar a vaga, o carro procura um espaço livre próximo.

- **E** perto do carro: entrar. Parado, **E**: sair pelo primeiro espaço seguro.
- **W** acelera; **S** freia e depois engata ré.
- **A/D** viram; **Espaço** freia mais rápido.
- Mouse gira a câmera. Painel à direita mostra volante animado, velocidade, marcha e carga.
- **V**, parado e perto do carro ou ao volante: abrir a caçamba. Longe do carro, V continua sendo o comando de companhia.

Até 72 km/h, aceleração gradual, rodas animadas, motor sintetizado e carroceria acompanhando o terreno. As estradas e as duas pontes são transitáveis. Trechos rasos permitem passagem; água profunda, encostas excessivas, obstáculos e limites do mapa mostram um aviso e impedem avançar. Menus pausam a condução.

## Carga

A caçamba leva **60 unidades**, ou **120 com a melhoria da garagem**, divididas entre cenoura, trigo, milho, ovos, leite, queijo, peixes e minérios. Cada clique transfere até dez unidades. Carregar retira do estoque; descarregar devolve ao estoque. Até seis caixas (doze com a melhoria) aparecem na carroceria, com produtos visíveis.

Estacione perto do armazém da Lúcia para vender toda a carga pelo preço normal de cada produto. Vender longe do armazém não é permitido. A carga fica separada do estoque disponível para produção e missões, portanto descarregue os produtos que deseja usar nessas atividades.

No Sandbox, carregar e descarregar preservam os recursos infinitos, com a mesma capacidade física da caçamba. Posição e carga ficam no save de cada fazenda; continuar recoloca o jogador a pé e mantém o carro estacionado.

O veículo funciona apenas no solo. Não aparece nem bloqueia caminhos no cooperativo. Ao criar uma nova cópia cooperativa, os produtos carregados voltam ao estoque dessa cópia; a carga solo permanece intacta. Não cobra dinheiro ou combustível e ainda não transporta passageiros. O cavalo continua disponível.

## Conferência manual

1. Continue uma fazenda existente, localize a camionetinha e entre com E.
2. Acelere, vire, freie, suba as estradas e cruze as duas pontes; confira o volante no painel.
3. Tente sair em movimento, avançar em água profunda e atravessar uma parede: o jogo deve impedir e informar o motivo no painel quando aplicável.
4. Pare e abra a caçamba com V; carregue produtos até o limite, descarregue parte e confira as caixas.
5. Tente vender longe da Lúcia; depois estacione no armazém e confira a venda, saldo e caçamba vazia.
6. Salve com F5 carregado e continue: posição, carga e estoque devem permanecer.
7. Crie outra fazenda sem apagar a anterior: cada uma mantém seu carro, sua carga e seu modo.
8. Crie e saia do cooperativo: produtos disponíveis no estoque cooperativo, carga solo preservada.

Testes automáticos: `tests/test_pickup.gd` e `tests/test_pickup_cargo.gd`, sempre com APPDATA/XDG_DATA_HOME isolados sob `test-results`. Cobrem direção, todas as rotas nos dois sentidos, ambas as pontes, desembarque, carga, capacidade, venda por proximidade, saves inválidos, modos e cópia cooperativa. O CI também executa revisão gráfica no Linux.

## Garagem e melhorias

Na 0.49, construa a garagem para ampliar a caçamba, melhorar pneus e motor, instalar bagageiro e escolher nome e pintura. [Custos e instruções](GARAGEM.md).
