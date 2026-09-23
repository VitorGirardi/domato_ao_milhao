# Tela cheia — 0.23.2

O executável inicia em tela cheia na resolução nativa do monitor. F11 alterna para janela e volta, inclusive nos menus e campos de texto. O tamanho e a posição anteriores da janela são restaurados, limitados à área disponível do monitor; Esc continua controlando os menus do jogo.

O cenário usa canvas_items + expand, sem esticar ou cortar o HUD para preencher a tela. FarmHUD centraliza sua área de autoria1440×900 com escala uniforme. O sombreado modal cobre toda a área extra. O status da pistola acompanha essa área, abaixo dos alertas; o retículo e o raio de mira permanecem no centro real do viewport.

## QA

`tests/test_fullscreen.gd` exige APPDATA isolado com test-results no caminho. Use uma pasta curta fora da raiz do projeto para evitar o limite de caminho do cache gráfico do Windows. Não use a pasta de saves reais.

```powershell
$env:APPDATA = Join-Path $env:TEMP 'domato-test-results-fullscreen'
& $godot --path . --script tests/test_fullscreen.gd --quit-after 6000 -- --capture
```

O teste verifica tamanhos reais1280×720,1366×768,1920×1080,1920×1200,2560×1080,1280×960,1280×1024 e3840×2160; bounds, centralização, overlay, cliques transformados, dropdown, alertas e retículo. Executa dez ciclos de F11 com LineEdit focado, ignora repetição da tecla, verifica restauração da janela, tiro no alvo após transições e preservação da montaria/inventário. Imprime uma amostra local de tempo por frame. Resultado esperado: FULLSCREEN_QA_OK; capturas em test-results/fullscreen.

A revisão independente por subagente também confere as capturas. O teste não garante desempenho em qualquer GPU; resolução nativa4K exige mais renderização que720p. FarmState/save não é alterado por essa funcionalidade.

Configuração de resolução baseada na documentação oficial: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
