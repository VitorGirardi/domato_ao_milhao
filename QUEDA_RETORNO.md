# Queda e retorno — 0.41.0

Compre a P-8 com Damião, na margem oeste da estrada perto do armazém.
**P** saca ou guarda; segure o botão direito para mirar; clique esquerdo
dispara; **R** recarrega. Cada carregador comporta oito tiros.

Um acerto derruba a pessoa ou o animal. A animação de levantar começa após
60 segundos e dura dois segundos. Ao terminar, há três segundos de proteção
contra outro acerto. Atirar novamente em quem está caído não reinicia a espera.
Estrelinhas indicam a queda, sem contador na tela e sem sangue.

A pessoa fica sem andar, trabalhar ou interagir durante esse período. Animais
também pausam suas rotinas; somente os animais atingidos pausam sua parte da
produção. Depois tudo continua. Não há recompensa, remoção do animal ou perda
de dinheiro e itens pela queda. A munição usada é consumida normalmente.

Se o cavalo ou seu cavaleiro forem atingidos, o cavaleiro desmonta. Na água,
a recuperação procura uma margem próxima e livre. No solo, os menus continuam
pausando o tempo do jogo. Esc, salvar e sair continuam disponíveis.

No cooperativo, os dois PCs precisam da versão 0.41.0, protocolo 12. O anfitrião
controla acertos e recuperação. Cada jogador compra sua própria pistola e
munição com o dinheiro da fazenda; o equipamento do visitante dura a sessão.
O anfitrião conserva seu equipamento no save cooperativo. Sua fazenda solo
continua separada. Entrar durante uma queda mostra o estado atual.

O estado temporário de queda não é gravado: ao reabrir a fazenda, todos estão
de pé. Save 20, backups, construções, estoque e dinheiro infinito são preservados.

## Conferência no jogo

1. Atire em uma pessoa e em cada espécie. Confira queda, estrelinhas e retorno
   após um minuto, sem contador.
2. Repita o tiro durante a espera; ela não deve recomeçar. Confira a curta
   proteção depois de levantar.
3. Experimente atrás de uma parede, montado e nadando. A parede deve bloquear
   o tiro; o cavaleiro deve desmontar; quem caiu na água deve recuperar em terra.
4. No cooperativo, testem os dois sentidos e entrada durante a queda. Movimento,
   interações e recuperação devem concordar nos dois computadores.

## Fontes de animação

`art/source/temporary_fall.blend` é a fonte Blender, reproduzida por
`tools/build_temporary_fall.py`. As curvas exportadas ficam em
`assets/animations/temporary_fall.gd`. O ajuste ao terreno é calculado pelo jogo.
