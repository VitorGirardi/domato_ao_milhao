# Construção — 0.33.0

No launcher, Atualizar e depois Jogar. Use TAB na fazenda para abrir a câmera de construção.

1. Escolha Lavoura, Animais, Estruturas, Decoração ou Terrenos.
2. Clique na miniatura e depois no terreno. R/Q gira a peça; Esc cancela.
3. Lavoura: escolha Canteiro e a semente nos três botões ao lado.
4. Selecionar: clique numa construção existente. Mover, Pintar, Abrir/Cuidar e Remover aparecem conforme o tipo. As cores só abrem ao clicar Pintar. Placas têm Editar texto.
5. Terrenos: Expandir fazenda ou Comprar terreno. Construções bloqueadas mostram o nível necessário; clique para ver a progressão.
6. O botão ? mostra os controles de câmera. TAB volta ao personagem.

Anfitrião e visitante usam o mesmo catálogo. Atualizem os dois PCs. A construção continua sendo validada e salva pelo anfitrião.

Nenhuma migração de save: a fazenda, o ciclo de dia/noite e o dinheiro infinito continuam. Testes usam diretórios isolados; não substitua o save real para testar.

## Validação

`tests/test_build_menu.gd`: categorias, miniaturas, sementes, atalhos, seleção, pintura, abrir, cancelar, bloqueios de nível, janela menor e retorno ao personagem.

`tests/test_coop_build_menu.gd`: dois processos com projeção real do cursor, prévia, posicionamento pelo mouse, replicação e Escape. Execute por `tests/run_network.py --gui --test test_coop_build_menu --godot CAMINHO`.

`tools/render_build_thumbnails.gd` recria as miniaturas a partir dos modelos do jogo em uma execução gráfica do Godot.
