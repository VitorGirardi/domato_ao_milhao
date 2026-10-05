# Caderno de arte da fazenda

Pacote preparado para Vitor revisar todas as artes depois da reunião. **Arte e prévia somente**, com integração no jogo após aprovação. Nenhum arquivo do carro, gameplay, save ou versão publicada foi alterado.

Abra **[CADERNO.html](CADERNO.html)** para ver as imagens organizadas em uma única página. A galeria 3D está em `farm_art_gallery.tscn`: abra no Godot e pressione F6 para executar somente essa cena.

## Peças para revisar

| Grupo | Modelos | Direção visual |
|---|---|---|
| Casas | Inicial e primeira melhoria | Madeira simples → reboco claro, varanda e flores |
| Celeiros | Inicial e primeira melhoria | Madeira envelhecida → celeiro maior vermelho ocre, sótão e feno |
| Divisas | Cerca rústica, cerca pintada, portão rústico e portão pintado | Módulos repetíveis para organizar o terreno |
| Água | Poço e tanque com bomba | Pontos de cuidado e trabalho na fazenda |
| Horta | Canteiro elevado e treliça | Cenouras, alfaces e feijão |
| Pomar | Laranjeira jovem e adulta | Crescimento visível, árvore adulta com frutos |
| Colheita | Composteira e caixas de produtos | Detalhes de uma fazenda em atividade |

São **16 modelos** contando as duas casas da primeira entrega. Não são substituições automáticas dos modelos atuais do jogo.

## Galeria interativa

**1–6** alternam entre começo da fazenda, fazenda melhorada, celeiros, cercas, horta/pomar e detalhes. Botão direito gira, roda aproxima, **L** muda a luz e **R** reenquadra. A composição da fazenda é uma proposta visual para aprovar o conjunto, não um mapa jogável.

## Fontes Blender

| Fonte editável | Gerador |
|---|---|
| `art/source/farm_houses.blend` | `tools/build_farm_houses.py` |
| `art/source/art_barns.blend` | `tools/build_art_barns.py` |
| `art/source/art_fences.blend` | `tools/build_art_fences.py` |
| `art/source/art_garden.blend` | `tools/build_art_garden.py` |

GLBs em `assets/models/farm_house_*.glb` e `farm_art_*.glb`. Todos foram feitos no Blender, com escala em metros, solo Y=0 no Godot e frente +Z. `farm_art_manifest.json` registra dimensões e vértices importados. Portões têm nós de dobradiça para uma futura animação; não incluem lógica de abertura.

## Antes da integração jogável

- Definir preço, desbloqueio e regras para cada melhoria.
- Criar colisões, entrada/saída e interação de cada construção. As casas e celeiros são exteriores fechados, sem interiores.
- Respeitar o deslocamento visual das casas documentado em [CASAS.md](CASAS.md) e dimensionar as áreas de construção pelos limites reais dos modelos.
- A horta e as árvores são estudos de arte. Colheita, crescimento, renda e irrigação ainda não estão conectados a essas peças.
- Fazer a integração numa branch atualizada depois de coordenar com a conversa do carro.

## Verificação feita nesta etapa

Importação no Godot, carregamento e instanciação dos 16 GLBs, materiais, limites, pivôs no solo, dobradiças dos portões, seis vistas da galeria e luz alternativa. Capturas revisadas visualmente. `tests/test_farm_art.gd` não carrega a cena principal nem uma fazenda.
