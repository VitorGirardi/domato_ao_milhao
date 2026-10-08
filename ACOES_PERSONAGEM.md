# Trabalho e transporte

As animações usam fontes editáveis do Blender e poses amostradas para os dois personagens. A movimentação normal continua responsável por andar e correr; cada ação assume o esqueleto durante sua duração e devolve o controle ao terminar.

Na 0.63.1, o motorista se apoia sobre o banco, com os pés no piso e espaço para o chapéu. A cabine mantém o personagem em escala normal, e a pose final da entrada é a mesma usada ao dirigir. Colisões produzem uma pancada proporcional ao impacto, sujeita ao volume de efeitos; empurrar continuamente um obstáculo não repete o som.

- Mineração: preparação do golpe, rotação do tronco, impacto e recuperação, mantendo o contato da picareta sincronizado com os efeitos.
- Rega: levantar e inclinar o regador com apoio das duas mãos. A água começa durante a inclinação.
- Colheita: flexionar as pernas, alcançar a planta e retornar. O efeito dos produtos acompanha o contato; a economia continua confirmada pela ação validada.
- Camionetinha: aproximar-se da porta do motorista e pressionar E. A porta abre, o personagem entra, fecha e assume o volante. Pare antes de sair. Obstáculos podem impedir a abertura.
- Cavalo: aproximar-se e pressionar E para apoiar no estribo, passar a perna e se acomodar. E novamente inicia a desmontagem em espaço livre.

Durante entrada e saída, a direção aguarda a conclusão da animação. Menus pausam as transições; reset de fazenda e encerramento da sessão limpam poses e colisões temporárias. A camionetinha continua solo. O cavalo e as ações de trabalho são replicados no cooperativo, com o anfitrião validando as ações. Os dois jogadores precisam usar a mesma versão.

Os saves existentes, o estoque, o dinheiro infinito do Sandbox e as configurações da camionetinha são preservados. Nenhum save real deve ser usado nos testes: configure APPDATA ou XDG_DATA_HOME sob test-results.

## Validação

Os testes verificam os dois esqueletos, contato das mãos, apoio dos pés, repetição de comandos, retorno à locomoção, pausa, obstáculos, cancelamento e persistência. A revisão gráfica inclui trabalho no canteiro e as etapas de entrada e saída. Dois processos Godot verificam as poses de trabalho e a montaria pela rede.

O teste `test_work_integration.gd` executa plantar, regar e colher pelo mesmo método usado pela interação do jogador; `test_coop_work.gd` repete rega e colheita com anfitrião e visitante.
