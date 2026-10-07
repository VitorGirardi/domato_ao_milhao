> Integrado à mina jogável na versão 0.59, junto dos ajudantes e da descida. Esta cena continua disponível como galeria isolada de arte; veja [PROFUNDEZAS.md](../../PROFUNDEZAS.md).

# Cavernas — prévia de arte independente

Esta cena preserva a galeria de revisão dos modelos. Abre sozinha e não instancia a fazenda, o carro, controles do jogador ou saves. Os modelos também são usados pela mina do mapa principal desde a 0.59.

## Ver as galerias

No Godot 4.7.2, abra `art/previews/cave_gallery.tscn` e execute essa cena (F6).
Também é possível executar pela raiz do projeto:

```powershell
& 'C:/Users/Vitor/Tools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path . art/previews/cave_gallery.tscn
```

- **1, 2 e 3** ou botões: cobre, ferro e cristais.
- **Botão direito e arrastar:** girar a vista.
- **Roda:** aproximar ou afastar.
- **R:** restaurar o enquadramento.

As imagens `copper.png`, `iron.png` e `crystals.png` nesta pasta mostram a cena
no renderizador do jogo. `assets.png` apresenta os modelos no Blender.

## Direção visual

| Galeria | Materiais e elementos |
| --- | --- |
| Cobre | Pedra quente, cobre exposto, oxidação verde, raízes e lanternas âmbar. |
| Ferro | Rocha fria, veios escuros e ferrugem, escoras de madeira, corda e ferramentas. |
| Cristais | Quartzo azul e lilás, agrupamentos maiores ao fundo, luz suave entre as formações. |

## Contrato para integração posterior

Fonte editável: `art/source/cave_details.blend`, com coleções nomeadas por modelo.
Gerador reproduzível: `tools/build_cave_details.py`, executado com Blender 5.2
em modo background. Os nove GLBs usam metros e eixo Y para cima, sem luz,
câmera, colisão, scripts ou texturas externas.

| Modelo `cave_detail_*.glb` | Origem e uso |
| --- | --- |
| `ore_copper`, `ore_iron` | Base no piso; pedras com mineral exposto, cerca de 2 m de largura. |
| `crystals` | Base no piso; conjunto de quartzo com cerca de 1,8 m de altura. |
| `stalactites`, `roots` | Pivô superior em Y=0; pendem cerca de 2,24 m e 1,88 m. |
| `support` | Base no piso; vão livre de 6 × 4,8 m, largura externa de 7,63 m. |
| `lantern` | Base no apoio; 0,91 m até a alça. A luz pontual pertence à composição da cena. |
| `tools` | Base no piso; picareta apoiada, balde e corda. |
| `wall` | Origem inferior central; 8 × 5 × 0,6 m; face visível +Z e fundo contínuo. |

O piso da prévia é apenas uma base de apresentação. Os veios existentes e
suas regras de extração continuam sendo a referência para a futura colocação.
Não substituir identificadores, coordenadas de mineração ou colisões apenas
para encaixar estes detalhes. Preserve o vão da passagem e mantenha raízes e
estalactites acima do jogador. Os GLBs visuais não concedem recursos.

## Validação

`tests/test_cave_details.gd` verifica materiais, limites, pivôs, ausência de
objetos de física/luzes/câmeras nos modelos e troca das três galerias. Em modo
gráfico, grava capturas em `test-results/cave-details/`. O teste não abre saves.

```powershell
godot --headless --path . --script tests/test_cave_details.gd
godot --path . --script tests/test_cave_details.gd
```

Nenhum arquivo de runtime, mapa, câmera do jogador, física, versão ou launcher
faz parte desta entrega. A PR é uma entrega de arte para integração posterior.
