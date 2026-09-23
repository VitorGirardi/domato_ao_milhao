# Revisão de anatomia e movimento de Pé de Pano

Base: versão0.25 (11db201), preservando estrebaria, vida solta, rédeas dinâmicas, dez ossos e os pivôs usados pela montaria.

O pescoço antigo era uma oval inclinada unida a uma esfera extra no peito. A revisão usa seções afuniladas, contínuas com o tronco, remove esse volume extra e remodela cabeça, focinho, orelhas e crina. A pele permanece unificada e os pesos são normalizados no gerador Blender.

O pivô do pescoço agora fica na junção com o ombro. Pastejar gira em torno dessa junção, sem deslocar todo o pescoço para baixo e amassar o peito. Olhos, arreio e rédeas acompanham a cabeça. Caminhada tem quatro fases distintas de contato e menor oscilação do tronco; galope mantém sua fase de reunião e extensão.

## Reproduzir

```powershell
& $blender --background --python tools/build_horse.py
$env:APPDATA = Join-Path $env:TEMP 'domato-test-results-horse'
& $godot --headless --path . --editor --import --quit
& $godot --path . --script tests/test_horse_anatomy.gd --quit-after 2400
& $godot --path . --quit-after 6000 -- --qa --qa-v025
```

O teste de anatomia não abre saves reais; gera vistas em test-results/horse-anatomy. Verifica dez ossos, pivôs e rédeas,16poses de passo/galope, pastejo executado por FarmHorseLife e duas vistas no cenário real. A revisão visual dessas imagens é necessária; apenas asserts não avaliam a aparência.

Regressões adicionais: tests/test_horse.gd, tests/test_stable.gd e tests/test_armory_horse.gd. Não há mudança de schema, dinheiro, regras da estrebaria, velocidade de deslocamento ou colisão.
