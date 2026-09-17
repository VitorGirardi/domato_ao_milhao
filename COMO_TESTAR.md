# Como testar a versão 0.8

Este roteiro cobre os **corpos conectados**, as **galinhas novas**, o Zeca e as encomendas.
Abra o executável da pasta `windows-v0.8` e escolha **Voltar para minha fazenda**.
A versão nova aceita a fazenda anterior; não precisa começar outra.

**Regra principal:** o tempo só avança caminhando, com as janelas fechadas.
Use **TAB** até aparecer o modo de caminhada. Construção e qualquer janela
pausam plantas, galinhas, ajudante e prazos de encomendas.

## 0. Conferir os personagens novos

1. Abra a **0.8** e retome sua fazenda. O protagonista já usa o modelo novo.
2. Use TAB para caminhar. Segure o botão direito e gire a câmera para ver o rosto;
   aproxime com a roda do mouse. Confira ombros ligados ao tronco, cintura e pernas.
   Os braços não devem parecer peças soltas.
3. Ande com WASD, corra com Shift e interaja com um canteiro seco para ver o regador.
4. Se Zeca já estiver contratado, visite o galinheiro dele e compare os personagens.
   Se ainda não estiver, siga o teste de contratação abaixo.
5. Ande, corra e pare repetidamente: cotovelos e joelhos devem dobrar sem abrir
   frestas no corpo. Regue com **E** perto de um canteiro seco e confira o regador na mão.
6. Visite as galinhas: veja olhos, crista, penas e dedos. Observe as patas
   alternando enquanto caminham. Clique em uma para conferir nome e cuidados.
7. Os rostos ainda têm expressão fixa e a galinha não articula asas/pescoço.
   Esta é uma base de animação; poses novas poderão precisar de ajustes.

## 1. Ver o Zeca trabalhar — cerca de 2 minutos

1. Tenha um galinheiro e pelo menos **$132** livres: $120 para contratar e uma
   folga para o serviço. Se precisar, venda uma parte do estoque pelo **F**.
   Um galinheiro novo custa $180 e já inclui três galinhas, água e ração.
2. Pressione **H** ou clique em **Ajudante [H]** no topo. Escolha o galinheiro.
3. Clique em **Contratar • conferir custos**, leia os valores e confirme **$120**.
   O saldo deve cair exatamente $120. Zeca aparece junto ao galinheiro.
4. Feche a janela e vá para caminhada com **TAB**. Não recolha os ovos manualmente.
   Se o ninho já tinha ovos, ele coleta na próxima checagem, em até 15 segundos.
   Num galinheiro novo e bem cuidado, os primeiros dois ovos levam cerca de
   45 segundos; a coleta ocorre nessa checagem ou na seguinte.
5. Deve aparecer **Zeca concluiu o trato**. Os ovos entram no estoque e o ninho
   esvazia. Uma rodada somente de coleta custa **$2**.
6. Abra **H**: confira as rodadas, os ovos coletados e o total gasto.
   O total inclui a contratação e todos os serviços desde o início da partida.

Zeca confere o galinheiro a cada **15 segundos**. Se não houver ovos e os
suprimentos estiverem acima de 25%, não faz serviço nem cobra. Quando água ou
ração chegam a 25% ou menos, repõe. A rodada custa $2, mais até $8 de ração;
a água é grátis. Com suprimentos inicialmente cheios, essas reposições aparecem
depois de aproximadamente 4–5 minutos de caminhada. Ele atende **um galinheiro**.

## 2. Pausar, trocar e salvar

1. Em **H**, clique em **Pausar**, feche a janela e caminhe por cerca de um minuto.
   As galinhas continuam produzindo, mas o Zeca não coleta nem cobra.
2. Abra **H** e confira que o gasto do ajudante não mudou. Clique em **Retomar**.
   Ele continua a contagem de onde parou.
3. Se tiver dois galinheiros, escolha o outro na lista e clique em
   **Atender este galinheiro**. A troca é grátis e reinicia a checagem de 15 segundos.
4. Para testar salvamento com calma, pause o Zeca, feche a janela, pressione **F5**
   e saia pelo menu. Abra novamente a **0.8**: ele continua contratado e pausado,
   com os mesmos totais e galinheiro. Jogo fechado não gera serviço nem cobrança.
5. **Dispensar…** abre uma confirmação. **Voltar sem alterar** cancela a dispensa.
   Confirmar é grátis, preserva os produtos e encerra o trabalho. Contratação
   anterior não é devolvida; recontratar custa outros $120.

Se faltar saldo para uma rodada completa, Zeca pausa sozinho sem cobrar parte
do serviço. Venda produtos e use **Retomar**. Dinheiro novo não o reativa sozinho.
Remover o galinheiro atendido também pausa o Zeca; escolha outro e retome.

## 3. Encomendas dos vizinhos — versão 0.5

1. Pressione **J**. Selecione **Dona Nena**, **Seu Bento** ou **Dona Lola**.
   Confira produtos, quantidades, recompensa e prazo antes de aceitar.
2. O pedido inicial de Nena no quadro é **6 cenouras + 2 ovos**, por **$115**.
   Se você já avançou as ofertas, siga as quantidades que a tela mostrar.
3. Clique em **Aceitar**. Aceitar não gasta nem separa produtos. Pode haver
   um pedido ativo por vizinho.
4. Para o primeiro pedido de Nena, dois canteiros de cenoura rendem seis unidades.
   Regue, caminhe cerca de 32 segundos e colha. Os dois ovos podem ser recolhidos
   pelo Zeca ou manualmente no painel do galinheiro.
5. Abra **J** novamente e entregue. A recompensa entra uma vez, os produtos
   saem do estoque e a reputação com esse vizinho sobe um ponto.
6. Com **2 pontos**, vire Parceiro; com **5**, Preferido. Os próximos pedidos
   exigem mais produtos e pagam bônus maiores. Pedido já aceito não muda.

O prazo começa ao aceitar e dura 8, 10 ou 12 minutos de caminhada, conforme o
nível. A janela de encomendas pausa o relógio: feche-a para vê-lo avançar.
Desistir ou deixar vencer passa para outra oferta sem multa nem perda de reputação.
Produtos na reserva do celeiro e ovos no ninho precisam ir para o estoque antes.

**Atenção à diferença:** em **F** ainda existe o pedido introdutório de **6 cenouras
por $110**, sem ovos e sem prazo. Ele é único e também dá um ponto com Nena.
O quadro **J** oferece os pedidos recorrentes.

## 4. Vender apenas uma parte

1. Abra **F → Vender produtos** e anote a quantidade de ovos ou cenouras.
2. Digite **1** no produto escolhido. O botão mostra o total: ovo vale $10;
   cenoura, $12. Clique em **Vender 1**.
3. Confira: saiu uma unidade, o saldo subiu pelo preço mostrado e os demais
   produtos ficaram no estoque. Produtos reservados no celeiro ficam separados.
4. Para preparar encomendas, evite **Vender estoque inteiro** até conferir o que
   precisa guardar. Você pode vender quantidades diferentes de cada produto.

## O que observar durante a partida

- Os botões e textos ficam legíveis no tamanho de janela que você usa?
- A coleta automática reduz o trabalho sem consumir dinheiro demais?
- Os prazos dos vizinhos permitem produzir com tranquilidade?
- Alguma ação perde produtos, cobra duas vezes ou deixa de funcionar após salvar?

Se algo falhar, anote a ação, o que apareceu e o que esperava. O menu, o saldo e
o galinheiro escolhido ajudam a reproduzir o problema.

Esta entrega tem um cuidador em um posto junto ao galinheiro. Ainda não há
deslocamento com rotas, vários funcionários, salários por dia ou automação da lavoura.
