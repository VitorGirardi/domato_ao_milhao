# Camionetinha de roça — protótipo solo

Uma picape verde e creme, com caçamba de madeira, pneus de terra e faróis redondos. Modelo original feito no Blender; fonte em `art/source/farm_pickup.blend` e gerador em `tools/build_farm_pickup.py`.

Ela fica emprestada perto do armazém da Lúcia, nas fazendas Survival e Sandbox. No mapa, procure **Companhia → Camionetinha · protótipo**. Se uma construção ocupar a vaga, o carro procura um espaço livre próximo.

- **E** perto do carro: entrar. Parado, **E**: sair pelo primeiro espaço seguro.
- **W** acelera; **S** freia e depois engata ré.
- **A/D** viram; **Espaço** freia mais rápido.
- Mouse gira a câmera. O velocímetro aparece durante a condução.

Velocidade máxima de 72 km/h, com aceleração gradual, rodas animadas, motor sintetizado e carroceria acompanhando o terreno. Colisões, margens de água e limites do mapa interrompem o movimento. Menus pausam a condução. A posição fica no save de cada fazenda; continuar recoloca o jogador a pé e mantém o carro estacionado.

Nesta primeira versão, o veículo funciona apenas no solo. Não aparece nem bloqueia caminhos no cooperativo. Não cobra dinheiro ou combustível e ainda não transporta carga ou passageiros. O cavalo continua disponível.

## Conferência manual

1. Continue uma fazenda existente, localize a camionetinha no mapa e entre com E.
2. Acelere, vire e freie; confira pneus, mãos no volante, câmera e som.
3. Tente sair em movimento, passar pela água e atravessar uma parede: o jogo deve impedir essas ações.
4. Estacione, saia, salve com F5 e continue novamente: o carro deve permanecer onde estava.
5. Crie outra fazenda sem apagar a anterior: cada uma mantém seu carro e seu modo.
6. Entre e saia do cooperativo: o carro solo deve reaparecer na sua posição original.

Teste automático: `tests/test_pickup.gd`, sempre com APPDATA/XDG_DATA_HOME isolados sob `test-results`. Cobre direção por input real, pausa, colisões, desembarque seguro, saves antigos/inválidos, modos, reposicionamento de vaga e ausência no cooperativo. O CI também executa a revisão gráfica no Linux.
