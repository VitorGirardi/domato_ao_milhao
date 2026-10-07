# Som do vale — 0.60

Motor, tiro, animais, passos e ações foram revisados para reduzir o timbre artificial e dar espaço aos sons do mundo.

| Grupo | Revisão |
|---|---|
| Camionetinha | Duas camadas de motor diesel gravado, marcha lenta e carga; aceleração, quatro marchas sonoras com histerese, queda de giro nas trocas e subida de giro no ar. Volume e alcance ajustados para o motorista. As marchas são sonoras, sem mudar a física. |
| P-8 | Disparo gravado com ataque e cauda, sobreposição limitada a seis tiros, variação discreta de altura. Recarga e ferrolho acompanham o tempo da ação. Tiros remotos partem da posição de disparo e perdem volume à distância. |
| Passos e cavalo | Gravações de cascalho, folhas e cascos. Quatro variações sem repetição consecutiva; chão de trilha/caverna e mato têm texturas diferentes. Cadência acompanha distância, sem passos ao dirigir. |
| Animais | Vaca, três chamados de galinha, pássaros e ronronar usam gravações. Relincho e respiração reais já existentes preservados. Intervalos independentes e posição do animal mantidos. |
| Fazenda e mineração | Plantar/colher usam folhas e terra; regar usa água, construir usa martelo. Picareta tem três impactos de metal, na fase de contato da animação. Compras e recompensas usam confirmação, não martelo. |
| Ambiente | Vento em vegetação, riacho e cachoeira usam gravações com emendas de loop. Vento, rio e chamados externos são atenuados nas galerias. |
| Música e interface | Tema original “Manhã no Vale” e sinais discretos de interface preservados; música mais baixa na partida, ainda mais ao dirigir ou entrar na mina. Assobio de chamada preservado para não mudar a identificação da interação. |

## Volume e limites

Configurações → Som mantém Volume geral, Música, Ambiente e animais, Efeitos e passos. Zero silencia a categoria. Preferências e saves existentes são preservados; não há mudança de economia, protocolo ou formato de save.

Quatro vozes de ações, quatro de animais, seis efeitos espaciais e uma voz própria do cavalo; motor usa duas camadas. Disparos locais têm polifonia limitada. Limiter no Master mantém margem de pico. Menus interrompem o motor, passos e novas chamadas; perda de foco também silencia o motor.

## Fontes e reconstrução

As gravações CC0 de Joseph Sardin/BigSoundBank estão em `art/audio/natural/`, com URLs, licença e SHA256 em `sources.json`. Créditos em AUDIO_CREDITS.md. Modelamos o som da P-8 a partir de um disparo 9 mm gravado; não é uma simulação balística ou acústica de um modelo real de pistola. A picareta usa foley de metal.

`python tools/build_natural_audio.py` reconstrói a paleta a partir dos originais, sem rede. Requer NumPy, SciPy e ffmpeg. Faz conversão para mono/32 kHz, filtro de graves, cortes, fades, ajuste de ganho e crossfade de loops. Se executar os geradores antigos `build_audio.py` ou `build_companion_audio.py`, execute este por último para restaurar a paleta atual. Música e sinais da interface continuam originais sintetizados; não foram substituídos por gravações.

## Validação

`test_audio_assets.py` verifica WAVs, RMS, picos, canais e continuidade. `test_audio.gd` e `test_animal_audio.gd` cobrem mix, configurações, eventos e distância. `test_audio_mix.gd` mede a saída real do mixer para motor no banco do motorista, aceleração, marchas, silêncio em pausa, disparo distante, mute e ausência de mutações do save. Todos os testes usam perfis isolados em test-results.

Para comparar: dirigir parado/acelerando/freando, disparar e recarregar, caminhar na trilha e no mato, aproximar-se dos animais e entrar na mina. As preferências antigas de volume continuam valendo; se Efeitos estava em zero, o motor continuará mudo até ajustar essa categoria.
