# Profundezas da Pedra Clara — 0.59

A mina agora desce 22 metros, com 29 trechos conectados. As passagens compradas continuam abrindo a Galeria do Ferro e o Salão dos Cristais. Os nove veios anteriores mantêm identidade, minério e tempo de recuperação; dois novos veios de ouro e ametista ficam no fundo. Ouro vale $110 e ametista $165 por unidade e podem ser vendidos no painel de recursos ou levados na camionetinha.

## Habitantes

Encontre o abrigo, aproxime-se a pé e pressione **E**. O presente conquista a confiança; o dinheiro prepara o abrigo. Cada contratação inclui dez minutos de comida.

| Ajudante | Galeria | Presente e abrigo | Produção |
|---|---|---|---|
| Grunho | Entrada | 6 cenouras + $240 | 1 cobre / 2 minutos |
| Ferrugem | Ferro | 4 milhos + $600 | 1 ferro / 2 minutos |
| Vigia | Fundo dos cristais | 2 queijos + $1200 | 1 ametista / 2 minutos |

Uma refeição de **5 trigos e 2 ovos** sustenta dez minutos de trabalho. A reserva comporta trinta minutos. O painel permite pausar e retomar. Sem comida ou com estoque cheio, o ajudante descansa e preserva seu progresso. A produção vai ao estoque da fazenda, usa jazidas próprias e não esgota os veios do jogador. Não há produção com o jogo fechado. No Sandbox, dinheiro e produtos permanecem infinitos; a contratação ainda é uma escolha do jogador.

## Arte e movimento

Entrada com madeira, raízes e luz quente; galeria intermediária com fungos luminosos fictícios e luz esverdeada; fundo com cristais e luz fria. Criaturas originais de fantasia sombria, sem gore ou combate: Grunho é compacto, Ferrugem possui pernas de apoio e carapaça, Vigia é alto, pálido e tem antenas sensoriais. A anatomia mais estranha acompanha a profundidade.

Fontes editáveis em `art/source/cave_helper_*.blend`, `cave_detail_fungi.blend`, `resource_ore_gold.blend`, `resource_ore_amethyst.blend` e `region_mine.blend`. Os geradores são `tools/build_cave_helpers.py`, `build_cave_fungi.py` e `build_region_mine.py`. Execute pelo Blender em background com `--python-exit-code 1 --python <arquivo>`; a mina aceita `-- --skip-preview`.

As criaturas têm esqueletos nomeados e skin exportados em glTF. Caminhada, repouso, mineração e transporte são animados no Godot, não clips prontos do Blender. A passada acompanha a distância percorrida; as transições suavizam velocidade, direção e poses. O ciclo sai do abrigo, escava, carrega minério e retorna. Os habitantes ficam nas laterais das galerias e não bloqueiam o corredor.

## Referências de pesquisa

- [Minecraft — Meet the Warden](https://www.minecraft.net/en-us/article/meet-warden): presença por silhueta, movimentos e sentidos alternativos à visão. Inspiração conceitual para o Vigia; não reutilizamos o personagem ou seus assets.
- [Minecraft — Caves & Cliffs, parte II](https://www.minecraft.net/pt-br/article/caves---cliffs-part-ii-the-features): relacionar profundidade, exploração e distribuição de recursos.
- [National Park Service — Harvestman](https://www.nps.gov/articles/000/harvestman.htm): referência real de aracnídeos cavernícolas, apêndices alongados e estruturas de alimentação. As criaturas do jogo são fantasia, não reconstruções biológicas.
- [Deep Rock Galactic — Season 06](https://www.deeprockgalactic.com/season-06): referência de apresentação e identidade de biomas subterrâneos.

Todos os novos modelos foram construídos no Blender; nenhuma malha ou textura dessas referências foi copiada. O conjunto de decoração preparado na PR #41 foi integrado e revisado nesta entrega.

## Compatibilidade e validação

Save 31 migra o estoque e os nove cooldowns dos saves anteriores sem alterá-los, acrescentando os novos recursos e ajudantes não contratados. Protocolo cooperativo 28 exige a mesma versão nos dois computadores. Contratações e refeições são validadas e salvas pelo anfitrião, com checagem de proximidade e reversão em falha de gravação.

Testes: `test_cave_crew.gd`, `test_cave_animation.gd`, `test_cave_world.gd`, `test_coop_cave.gd`, `test_cave_details.gd`, `test_mine_exploration.gd` e regressões de recursos, saves, transporte e coop. Sempre use perfis isolados em `test-results`; nunca saves pessoais. O teste de exploração atravessa fisicamente os 29 trechos nos dois sentidos e verifica portas, terreno e câmera.
