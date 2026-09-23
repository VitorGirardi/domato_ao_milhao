# Personagem principal

Antes de criar uma fazenda, o jogador escolhe Fazendeiro ou Fazendeira em dois cards com modelos 3D de corpo inteiro e animação de repouso/piscar. Mouse e teclado funcionam. A escolha é visual: ambos têm as mesmas habilidades e controles.

A fazendeira tem modelo original Blender, camisa terracota, jardineira verde, botas, chapéu com fita e duas tranças curtas que terminam acima dos ombros. Mantém o contrato do rig humanoide: 20 ossos, malha contínua, mãos e blend shape Blink. Usa as animações existentes de andar/correr/pular, plantar/regar/colher/coletar, emotes, pistola e montaria, incluindo contato com as rédeas.

## Perfil e compatibilidade

- `user://character_profile.cfg`, seção `character`, chave `id`: `farmer` ou `farmer_woman`.
- Perfil ausente/inválido usa `farmer`; saves antigos não precisam migrar.
- Ver prévia/cancelar não grava perfil. Nova fazenda grava a escolha e aplica o modelo; falha ao criar a fazenda restaura a escolha anterior.
- A identidade é local e independente do snapshot da fazenda compartilhada. Essa PR não altera o protocolo de rede.
- Integração de aparência remota: validar com `FarmCharacters.valid(id)` e criar via `FarmCharacters.instantiate_model(id)`. O avatar local guarda o metadado `character_id`. Nunca derive a aparência do visitante do save do anfitrião.

## Autoria e testes

Fonte: `art/source/farmer_woman.blend`. Gerar apenas a fazendeira com Blender em background e `--python tools/build_cartoon_characters.py -- farmer_woman`. `tools/rebuild_characters.py` também inclui a nova protagonista.

`tests/test_character_choice.gd` verifica cards por mouse/teclado, quatro proporções de tela, perfil inválido/falha de gravação, rollback em falha da fazenda, escolha ao reiniciar/cancelar, poses e punhos, reconexão da pistola e rédeas. Rodar com APPDATA (Windows) ou XDG_DATA_HOME (Linux) em um diretório contendo `test-results`, com `--audio-driver Dummy`. Capturas gráficas em `test-results/character-choice`.

A integração do handshake por jogador é coordenada pela mainmato após a entrega do cultivo cooperativo 0.30. Não considerar esta branch uma versão publicada do multiplayer com aparências sincronizadas.
