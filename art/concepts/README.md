# Direção de personagens aprovada

`characters-approved.png` é a imagem de conceito aprovada pelo autor: cabeças
grandes, olhos expressivos, sorriso amplo, corpos compactos e roupa rural simples.
Foi criada com geração de imagem a partir das referências fornecidas pelo autor.
Serve como direção artística; não é uma captura de modelos já existentes no jogo.

Os modelos jogáveis são produzidos separadamente no Blender por
`tools/build_cartoon_characters.py`, gerando os fontes `farmer.blend` e
`helper.blend` e os GLBs correspondentes. As prévias de `tests/render_characters.gd`
mostram esses GLBs renderizados no Godot, sem geração ou retoque de imagem.

Nesta primeira implementação, os rostos são geometria estática e o movimento
usa seis grupos articulados. Não há rig facial, sincronização de fala ou roupas
trocáveis. As ferramentas continuam sendo equipadas somente durante as ações;
o forcado e a cesta da imagem de conceito não fazem parte da pose permanente.
