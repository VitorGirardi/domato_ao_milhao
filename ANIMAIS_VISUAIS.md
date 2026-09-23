# Animações dos animais

Galinhas alternam passeio com pausas para ciscar e bicar. O pescoço contínuo e o rosto deformam juntos com `Peck`; os pés permanecem no chão. Inspeção, reunião e dança suspendem a pausa. O estado de alimentação/ovos não mudou.

A vaca tem manchas na superfície, cascos divididos, mandíbula de mastigação e orelhas independentes. A marcha usa quatro fases. Navegação, limites do curral e aproximação para ordenha permanecem sob `FarmCowMotion`.

O porco é um **modelo de prévia**, com focinho, orelhas dobradas, cascos e cauda enrolada; `FarmLivestockPose.pig` oferece farejar e caminhar. Não foi adicionado à loja, ao save ou à economia nesta entrega.

## Contrato para multiplayer

- Apenas o host chama `FarmWorld.animate` com tempo positivo. O cliente recebe poses; não executa uma segunda simulação de navegação.
- `FarmHenMotion.pose(hen,time,delta,stepping,pecking)` modifica somente `HenBody` / blendshape `Peck` e `LegL/R`. O chamador fornece tempo com a fase individual. A pausa de navegação fica em `FarmWorld`.
- `FarmCowMotion.setup/animate` mantém as assinaturas e os nós `CowHead`, `CowNeck`, `CowTail`, `LegFL/FR/BL/BR`. Novos nós visuais: `CowJaw`, `CowEarL/R`.
- `FarmLivestockPose.prepare_cow` habilita COLOR_0 no material importado pelo Godot 4.7, preservando o recurso compartilhado. Chamado no setup do curral.
- A coleta genérica de transforms locais e blendshapes deve incluir os novos nós e `Peck`. Não replicar os caches de metadados `hen_pose` / `livestock_joints`.
- Não há mudanças em protocolo, FarmState, preços, produção, saves ou dinheiro infinito.

## Reproduzir assets e QA

Com Blender instalado:

```text
blender --background --python tools/build_chicken.py
blender --background --python tools/build_livestock.py -- cow pig
```

`build_dairy_assets.py` também reutiliza o builder novo da vaca ao reconstruir o curral. Fontes `.blend` e modelos `.glb` estão versionados.

Com APPDATA (Windows) ou XDG_DATA_HOME (Linux) apontando para uma pasta QA cujo nome contenha `test-results`:

```text
godot --headless --editor --path . --import --quit
godot --path . --audio-driver Dummy --script tests/test_livestock_pose.gd
godot --headless --path . --audio-driver Dummy --script tests/test_livestock_pose.gd
```

O teste verifica contrato dos modelos, poses finitas, preservação dos roots, transição para caminhada, pausa real na fazenda, prioridade da inspeção e chegada da vaca para ordenha. No modo gráfico salva prévias em `test-results/livestock`. `-- --livestock-film` grava 180 frames opcionais para revisão do movimento. Todos os saves usados são isolados.
