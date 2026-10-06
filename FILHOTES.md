# Filhotes e crescimento — 0.57

Abra **E → Filhotes e crescimento** no cercado; no curral vazio, **Criar uma bezerra**. Confira o custo e confirme perto da construção, a pé. Galinhas existentes, vacas e porcos antigos permanecem adultos.

- Galinheiro nível 1: ampliação com três pintinhos, alternativa à ampliação com adultas. Custo $300 e 6 ovos, mantendo as três galinhas atuais.
- Curral vazio: criar uma bezerra por $280 (alternativa à vaca adulta de $480).
- Chiqueiro: criar um leitão por $140 por vaga (alternativa ao adulto de $240).
- Pintinhos crescem em 8 minutos ativos com suprimentos; leitões em 16 e bezerra em 24. Crescimento pausa sem água/ração, nunca regride. Sem crescimento offline, doença ou morte.
- Produção apenas adulta; capacidade, cuidados e animais de saves anteriores preservados. Crescimento visual gradual, passadas proporcionais ao deslocamento, pausa/curva suaves, cercas e cochos respeitados.

Versão 0.57.0, save 30, protocolo 27. Atualizem os dois PCs no cooperativo. Idade e suprimentos são conduzidos pelo anfitrião e salvos com a fazenda. Compras repetidas/sem vaga são recusadas; falha de gravação desfaz a aquisição.

## Movimento e aparência

Pintinhos amarelos, bezerra e leitões têm proporções próprias, com crescimento contínuo. A penugem dá lugar à cor adulta; crista, chifres e úbere aparecem gradualmente. As passadas acompanham a distância percorrida e o tamanho do corpo, com transição ao parar. Ciscar, farejar, pastar, descansar e atender o Raul continuam funcionando. Cercados girados, pausas diante do jogador e quedas temporárias são preservados.

O tempo de crescimento exige suprimentos: 8/16/24 minutos não significam uma única reposição. Use os cuidados existentes e os funcionários para manter água e ração. Animais temporariamente caídos pausam a simulação do cercado proporcionalmente, como os adultos.

## Validação reproduzível

Use APPDATA/XDG_DATA_HOME isolados sob test-results, nunca saves pessoais.

- `tests/test_young.gd`: aquisição, recursos, alternativas adultas, produção, suprimentos, maturidade em passos pequenos/grandes, save antigo/inválido, movimento da construção e Sandbox.
- `tests/test_young_life.gd`: painéis, compra próxima a pé, rollback de disco, recarga, movimento nas quatro rotações, descanso, prioridade de atendimento/quedas e capturas dos estágios 0/25/50/75/100%.
- `tests/test_coop_young.gd`, via `tests/run_network.py`: dois processos, compra remota, distância, rollback, repetição/replay, bezerra/leitão replicados e saves individuais preservados.
