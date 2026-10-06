# Animais vivos — 0.56

Aproxime-se a pé do galinheiro, curral ou chiqueiro e abra seu painel com **E**. Entre em **Bem-estar** para oferecer um cuidado gratuito:

- Galinhas: renovar a palha do ninho.
- Vaca: escovação.
- Porcos: preparar o banho de lama. A lama fica mais escura e úmida.

É preciso ter um animal no cercado e pelo menos 25% de água e ração. O cuidado vale por **8 minutos de simulação ativa**, não acumula nem consome dinheiro ou materiais. Ovos e leite ganham **20% de velocidade**, sem aumentar o consumo de suprimentos. Porcos continuam sendo companhia, sem produção. Os cuidados feitos ficam registrados por cercado.

O bônus não substitui água e ração e não ultrapassa a capacidade de ovos/leite. Quando termina, volta a velocidade normal. Fechar o jogo não desconta tempo; não existem doença, morte ou punição por ausência. No cooperativo, o tempo avança enquanto o anfitrião joga.

## Vida no cercado

Os três porcos passeiam em áreas seguras do chiqueiro, farejam e descansam à noite. Galinhas se acomodam perto do galinheiro entre 20h e 6h e procuram os lados dos suprimentos quando estão baixos. Evitam outras galinhas e o jogador. A vaca faz pausas noturnas, olha para os cochos quando precisa de suprimentos e continua atendendo o Raul. Os cuidados não alteram a produção noturna existente.

O coração sobre o cercado indica conforto ativo. Ao selecionar a construção, também aparece sua atividade. Posições e poses são conduzidas pelo anfitrião no cooperativo. Quedas temporárias têm prioridade e pausam os animais atingidos.

## Saves e cooperativo

Versão 0.56.0, save 29, protocolo 26. Atualizem os dois PCs. Saves anteriores, modos Survival/Sandbox e fazendas separadas são preservados. O estado de conforto acompanha a construção ao mover/girar. Falha de gravação desfaz a ação antes de confirmar; distância, montaria e repetição são verificadas pelo anfitrião.

## Validação reproduzível

Use APPDATA/XDG_DATA_HOME isolados sob test-results; nunca use saves pessoais.

- `tests/test_animal_care.gd`: produção, consumo, fim do bônus e esgotamento em passos pequenos/grandes, saves antigos e inválidos, quedas, Sandbox e construção movida.
- `tests/test_animal_life.gd`: painéis, distância, ação no chão, rollback de disco, recarga, quatro rotações, movimento dos três porcos, descanso, atendimento do Raul e capturas gráficas.
- `python tests/run_network.py --godot CAMINHO --test test_coop_animal_care`: dois processos, distância remota, save inválido, replay, cópia compartilhada e save solo intacto.
