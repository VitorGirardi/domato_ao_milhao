# Damião e a P-8 do Vale

Damião atende na margem oeste da estrada, perto do armazém. Ele é um novo personagem negro, de corpo cheio, regata clara, calça verde-oliva e expressão séria, modelado no Blender com o rig humano do jogo, respiração e piscar.

## Jogar

1. Aproxime-se da bancada de Damião em **(-33,5; 22)** e pressione **E**.
2. Compre a **P-8 por $850**, com 8 munições carregadas e 24 na reserva. Caixas extras têm 24 munições e custam $60; a reserva comporta 96.
3. **P** saca ou guarda a pistola. A câmera passa para cima do ombro.
4. Segure o **botão direito** e mova o mouse para mirar. **Clique esquerdo** dispara uma vez. **R** recarrega.
5. Os três alvos ao norte da banca reagem aos acertos. O disparo tem som, recuo, clarão, rastro curto e indicação de acerto.

Montar no cavalo, menus, construção, salto, emotes e outras interações guardam a pistola e cancelam a recarga sem perder munição. A carteira infinita do jogo normal continua funcionando. Arma, munição e contadores persistem no save; partidas anteriores começam sem arma. Este primeiro sistema inclui alvos de treino, sem combate ou dano em personagens e animais.

## Integração

- `FarmArmory`: inventário versionado, validação e transações. Campo opcional `armory` no save 16, validado antes de qualquer mutação; ausência migra para inventário vazio.
- `FarmWeapons`: NPC, bancada, alvos, controles, câmera/pose, efeitos e UI. Hooks pequenos em `main.gd`; sem modificar `FarmWorld` ou `FarmLandscape`.
- Posição do NPC: `SHOP_AT=(-33.5,0,22)`. Bancada virada para a estrada, em `(-32.5,0,22)`. Alvos em `(-33.2,0,10/14/18)`, também virados para leste.
- Reserva pública `Rect2(-35,8,3,18)`, fora de todos os terrenos compráveis. O módulo filtra apenas a vegetação natural dessa faixa em memória; nunca modifica construções ou propriedade salvas. Árvores que projetariam a copa sobre o local são retiradas pela margem de seu raio.
- Assets exclusivos: `gunsmith`, `pistol_p8`, `gunsmith_bench`, `practice_target`. Nenhum personagem existente ou gerador compartilhado é alterado.
- O raio da câmera escolhe o alvo; um segundo raio parte do cano e respeita obstáculos, inclusive quando o cano está dentro de uma colisão.

O cavalo e o inventário de armas são salvos juntos. Saves 15 de armas recebem o cavalo padrão; saves 16 do mapa recebem inventário vazio. Montado, sacar, disparar e recarregar ficam bloqueados. Quando cavalo e bancada estão próximos, E usa a interação mais perto.

## Reproduzir os assets e os testes

Use Blender 5.2 e Godot 4.7.2. Dentro da worktree:

```powershell
& $blender --background --python tools/build_gunsmith.py -- --preview
& $blender --background --python tools/build_pistol_assets.py
$env:APPDATA = Join-Path $PWD 'test-results/isolated-appdata'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
& $godot --headless --path . --editor --import
& $godot --headless --path . --script tests/test_armory.gd --quit-after 600
& $godot --path . --script tests/test_armory_integration.gd --quit-after 1200 -- --capture
& $godot --headless --path . --script tests/test_armory_horse.gd --quit-after 1200
& $godot --headless --path . --script tests/test_horse.gd --quit-after 600
& $godot --headless --path . --script tests/test_farm_state.gd --quit-after 600
& $godot --headless --path . --script tests/test_v021.gd --quit-after 600
```

`$blender` e `$godot` representam os caminhos locais dos executáveis. O teste visual exige `APPDATA` dentro de `test-results`; ele grava somente `qa_armory_integration.json` nesse perfil isolado. Não utiliza o save real.

Resultados esperados: `ARMORY_STATE_OK`, `ARMORY_HORSE_OK`, `HORSE_STATE_OK`, `ARMORY_INTEGRATION_OK`, `SIMULATION: 57 checks, 0 failures` e `V021_STATE_OK`. Capturas ficam em `test-results/armory`; o retrato Blender fica em `test-results/gunsmith`.
