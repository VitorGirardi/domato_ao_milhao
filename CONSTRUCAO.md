# Construção e camionetinha — 0.58.0

Entre no modo construção com **Tab**. No alto da tela:

- **Mover construção**: clique na peça e depois no novo lugar. **R/Q** gira; **Esc** cancela. A mudança é grátis e preserva produção, melhorias, animais e filhotes. Um destino ocupado ou fora da fazenda não altera a construção original.
- **Vender / remover**: clique na peça, confira o valor e confirme. Você recebe **50% do valor da obra mais as melhorias da construção**, arredondado para baixo. Equipamentos permanentes comprados separadamente não entram nessa conta.
- **Selecionar**: abre a ficha da peça, com os mesmos botões de mover e vender, além de cuidar ou pintar quando disponíveis.

Recolha a produção e libere a reserva do celeiro antes de remover. Currais com vaca e chiqueiros com porcos continuam protegidos; use Mover para reorganizar sem perder os animais. Vender um galinheiro retira suas galinhas, e vender canteiro ou pomar retira o plantio; o aviso aparece na confirmação. O Sandbox mantém dinheiro infinito.

Mudanças e vendas são salvas imediatamente. Se não for possível gravar, a operação é desfeita. No cooperativo, o anfitrião valida e salva; uma construção alterada por outra pessoa invalida a confirmação antiga.

A camionetinha conserva a velocidade vertical adquirida na subida: passar rápido por um topo pode tirar as rodas do chão. No ar, segue o embalo e a gravidade; volante e freio voltam a atuar ao tocar o solo. A carroceria amortece a queda. Devagar, mantém aderência; estradas, pontes, travessias rasas e limites de água profunda continuam funcionando. Veículo ainda exclusivo do modo solo.

## Catálogo e controles

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
