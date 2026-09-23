# Som do vale — 0.28.0

A trilha **Manhã no Vale** é uma composição instrumental original de 32 compassos, em Dó maior, 80 BPM e 96 segundos. Combina cordas dedilhadas, baixo suave, sopro sintetizado e percussão discreta. Não usa músicas comerciais, samples baixados ou vozes. O tema tem frases e pausas; a cauda de reverberação atravessa o ponto de repetição sem corte.

`tools/build_audio.py` gera todos os 26 arquivos com Python e NumPy, usando semente fixa. Os WAVs e o manifesto com duração, pico e RMS ficam em `assets/audio`. Os timbres e chamados dos animais são estilizados e sintetizados, não gravações de animais reais.

## No jogo

- Música contínua no menu e na fazenda, mais baixa durante a partida/pausa e atenuada quando a janela perde foco.
- Vento leve, água conforme a proximidade do rio e chamados ocasionais dos animais e pássaros existentes por perto. Cada espécie possui seu intervalo; muitas aves não deixam a vaca/galinha sem vez.
- Relincho ao montar e reação curta quando o sprint é aceito, acompanhando a posição do cavalo. Comando recusado por fôlego/cooldown não produz som.
- Quatro variações de passos e de cascos, baseadas na distância realmente percorrida. Sem passos parado, em menus ou deslocando a câmera de construção.
- Respostas para plantar, regar, colher, construir e usar menus. A P-8 também respeita o volume de efeitos.
- Vozes limitadas: quatro efeitos e quatro fontes espaciais e uma voz própria que acompanha o cavalo. Sons não criam nós indefinidamente.

## Ajustar

Configurações → Som: **Volume geral**, **Música**, **Ambiente e animais**, **Efeitos e passos**. Zero silencia a categoria. Aplicar e voltar salva as preferências em settings.cfg; Cancelar descarta. Saves da fazenda não mudam de formato. Configurações antigas mantêm seu volume geral e recebem os novos controles nos valores padrão.

Configurações → Jogo e vídeo mantém sensibilidade, tela cheia, qualidade e FPS.

## Verificação

`tests/test_audio.gd` exige APPDATA isolado contendo test-results. Valida os 26 clipes, a duração/loop, buses, silêncio por categoria, passos/parada/menu, atenuação do rio, limite de vozes e ausência de mutações da fazenda. Executar com --headless --audio-driver Dummy. O gerador valida forma de onda finita e margem de pico; efeitos terminam em zero e a música possui borda contínua.
