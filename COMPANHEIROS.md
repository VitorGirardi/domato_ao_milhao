# Carinho, companhia e chamado

- **E perto do gato:** o personagem se agacha e passa a mão na cabeça; o gato reage e ronrona por cerca de três segundos. Funciona com fazendeiro e fazendeira. O gesto interrompe ferramentas/emotes e segura o movimento durante a animação.
- **V perto do gato:** alterna acompanhar/ficar. Para começar, aproxime-se a até 2,2 m. Quem está sendo acompanhado pode mandar ficar mesmo à distância. Uma única pessoa conduz o gato por vez.
- **C a pé:** assobio com mão junto à boca e som espacial. O cavalo desocupado se aproxima e para a cerca de 3,5 m; alcance de 60 m, intervalo de quatro segundos e tentativa de até 25 segundos. Não desmonta outro jogador.

As rotas contornam obstáculos numa busca limitada. O passo do cavalo também testa o volume físico. Sem caminho livre os animais aguardam; não atravessam paredes nem são teleportados. O gato pode acompanhar pelo vale e ficar no local indicado. Não há viagem instantânea quando o jogador se afasta demais.

`FarmCompanions` concentra comandos, poses sobrepostas ao rig compartilhado, sons e autoridade. `FarmCompanionPath` procura rotas sob demanda. `FarmCat` e `FarmHorseLife` executam o movimento; `FarmCoopMount` mantém a marcha visível no visitante. Os hooks de `main.gd` são setup, teclas C/V e interação E do gato.

No cooperativo o anfitrião valida proximidade, posição recente do visitante, cooldown e ocupação. Ambos veem os gestos e ouvem os sons próximos; movimento e pose dos animais seguem a replicação existente. Protocolo **6**, exigindo a mesma versão nos dois computadores. Save **18** mantido; seguir e chamar são estados transitórios. O cavalo continua usando sua persistência de posição já existente.

Os sons são sínteses originais reproduzíveis por `tools/build_companion_audio.py`, sem gravações externas: ronronar de 3,2 s e assobio de 1,35 s. Usam o volume de efeitos, atenuação espacial e param ao perder foco. A escuta em caixas de som reais ainda requer avaliação humana; o QA usa Dummy para não tocar áudio no computador durante os testes.

## Validação

`tests/test_companions.gd` cobre desvio de obstáculos, contato da mão nos dois personagens, ronronar, acompanhar/parar, aproximação do cavalo e recusa quando montado. Salva vistas das poses em `test-results/companions`. `tests/run_network.py --test test_coop_companions` executa dois peers reais, com carinho, seguir/parar e chamado feitos pelo visitante e saves isolados. Ambos integram a CI Linux.

Integrado na versão 0.34 com o chiqueiro, o catálogo contextual e a iluminação da 0.33. Atualizem os dois computadores pelo launcher.
