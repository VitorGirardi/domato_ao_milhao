# Evolução da casa — prévia de arte

Dois modelos originais feitos no Blender para estudar a evolução visual da fazenda:

- **Casa inicial:** madeira simples, remendos e alpendre pequeno.
- **Primeira melhoria:** reboco claro, telhas de barro, varanda e floreiras.

Este pacote é uma prévia independente. Não modifica a cena principal, o carro, a física, a economia, a construção nem os saves. A integração jogável fica para uma etapa posterior, conforme o escopo combinado.

## Abrir a comparação

No Godot, abra `art/previews/houses_gallery.tscn` e execute **esta cena** com F6. Pela linha de comando:

```powershell
& 'C:/Users/Vitor/Tools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . res://art/previews/houses_gallery.tscn
```

**1** mostra a casa inicial; **2** mostra a melhoria; **3** compara as duas. Arraste com o botão direito para girar, use a roda para aproximar, **L** para alternar a luz e **R** para reenquadrar. Os mesmos controles estão nos botões da prévia.

## Arquivos e futura integração

- `art/source/farm_houses.blend`: fonte editável, com uma coleção por estágio.
- `tools/build_farm_houses.py`: gerador reproduzível para Blender 5.2.
- `assets/models/farm_house_starter.glb` e `farm_house_upgrade.glb`: modelos para importar no jogo.
- `art/previews/house_comparison.png`, `house_starter.png`, `house_upgrade.png`, `house_evening.png`: capturas da prévia no Godot.

Escala em metros, solo Y=0 no Godot, frente +Z e porta central. Os dois modelos cabem no mesmo limite máximo de 8 × 8 m, embora a casa inicial ocupe menos espaço. São exteriores com portas fechadas; não incluem interiores, colisões, preço de compra ou regras de melhoria. Esses pontos precisam ser definidos na integração jogável.

Dimensões importadas no Godot: inicial **5,95 × 4,78 × 6,50 m**, melhoria **7,34 × 5,48 × 7,81 m** (largura, altura, profundidade). São 5.874 e 7.602 vértices importados, respectivamente. A varanda deixa o volume um pouco à frente do pivô: para uma área de construção de 8 × 8 m centrada no grid, desloque o modelo visual em **Z=-0,40 m** nos dois estágios. Isso preserva a posição da porta na troca e mantém todas as peças dentro da mesma área. Soleira Y=0,32 m: a futura colisão precisa acomodar os degraus.

## Validação

`tests/test_house_art.gd` carrega e instancia os dois GLBs, verifica dimensões, pivô no chão e quantidade de vértices, exercita a comparação e a luz e captura as quatro vistas quando executado com vídeo. Não carrega nenhuma fazenda.
