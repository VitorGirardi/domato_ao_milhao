# Como testar a versão 0.15.0

Extraia o ZIP e abra `DoMatoAoMilhao.exe`. Escolha **Voltar para minha fazenda**.
A versão aceita a partida anterior. Não precisa começar outra.

## Humor e Mimosa — teste primeiro

1. Em caminhada, parado no chão, aperte **B** ou clique **B · Emotes**.
2. Escolha Dança da Galinha, Passinho do Milho ou Rei da Colheita. Cada dança dura 6 segundos.
3. Repita e interrompa com WASD, Espaço, E, F ou TAB: o personagem deve responder imediatamente.
4. Teste gargalhada, coração e “Cadê meu milho?!”. A reação aparece acima do chapéu e some em 2,8 s.
5. Abra B e feche com Esc: o relógio pausa apenas enquanto a roda está aberta. Durante a dança a fazenda continua.
6. No curral com vaca, fique em caminhada e feche os menus por 40 segundos. Mimosa deve andar, virar,
   abaixar a cabeça junto aos tufos de capim, mastigar e descansar. As patas acompanham a caminhada.
7. Abra o menu do curral ou use TAB: a rotina pausa. Volte à caminhada para continuar.
8. Salve e reabra: vaca, leite e suprimentos ficam preservados; a pose temporária pode reiniciar.

## Curral e leite

1. Em **TAB → construção**, aperte **0** ou clique em Curral. Custa **$650** e ocupa 8 × 6 m.
2. Volte à caminhada. Perto do portão, pressione **E · Cuidar da vaca**.
3. Clique **Comprar vaca · $480**. Confira os custos; voltar não cobra. Confirme para receber Mimosa.
4. Feche o menu e fique em caminhada por **60 segundos**. Observe a vaca mexer cabeça, patas e cauda.
5. Abra o curral: devem existir **2 L** prontos. **Coletar** transfere tudo para o estoque de leite.
6. Abra **Estoque de leite** ou **F → Leite**. Venda 1 L por **$18** e confira o restante.
   O celeiro também tem acesso ao leite. **Vender tudo** inclui o leite coletado, mas não o que ficou no curral.
7. Deixe acumular **8 L**: produção pausa até coletar. Reponha água e ração pelos cartões.
   Água é grátis; ração custa até $12 conforme o que faltar. Sem água ou comida, não produz.
8. Mova o curral na câmera de construção. A vaca, os suprimentos e o leite devem permanecer.
   Curral ocupado não pode ser removido nesta versão; use Mover.
9. Salve com F5 e reabra. Compra, cuidados, leite pronto e estoque permanecem.
   Save novo: **formato 10**. Depois de salvar na 0.14, use esta versão ou posterior.

A coleta é pelo menu nesta etapa; ordenha manual animada, queijaria e ajudante das vacas vêm depois.
Pastar é visual nesta etapa: continue repondo ração e água no menu.

## HUD da caminhada

1. Use TAB para caminhar: grandes painéis somem; permanecem horário, saldo, objetivo e atalhos.
2. Aproxime-se do celeiro: aparece **E · Abrir celeiro**. Aperte E ou clique nessa ação.
3. Aproxime-se de canteiros secos, maduros e vazios. Confira **Regar**, **Colher** e **Plantar**.
   Só o canteiro vazio exibe sementes. Escolha uma cultura e plante; o custo aparece na ação.
4. Um cultivo regado crescendo mostra sua porcentagem, sem botão de ação ativo.
5. Clique no objetivo pequeno no canto esquerdo. O painel mostra detalhes e a próxima ação.
   Enquanto ele estiver aberto, o tempo pausa. Feche com X ou Esc.
6. Deixe um ninho encher: o aviso leva ao galinheiro. Ao coletar, desaparece.
   Bento sem orçamento exibe o motivo e acesso à equipe. A pausa manual não gera alerta.
7. Afaste-se das construções: o botão de interação some. Use TAB para recuperar a barra completa.
8. F5 salva; feche e reabra. A fazenda anterior continua compatível.

## Menus

1. Caminhe até o celeiro e use **E**. Confira os cartões e os números separados.
   **Guardar →** move tudo que couber para a reserva; **← Retirar** devolve ao disponível.
2. No galinheiro, use **Coletar**, **Repor** e **Encher** nos três cartões.
   A aba **Galinhas** reúne os nomes; os botões de renomear ficam ali.
3. Na oficina, compare os desenhos de alcance dos dois regadores.
   Uma melhoria bloqueada informa o requisito; uma comprada mostra **Equipado**.
4. Em **F**, digite a quantidade no cartão e confira o total no botão antes de vender.
   **Vender tudo** preserva a reserva. **Encomendas** separa vizinhos, produtos, prazo e pagamento.
5. Use **H** para ver Zeca e **Equipe e treinamento** para ver os dois funcionários.
   O HUD do campo desaparece enquanto um menu está aberto; **X** ou **Esc** fecha.

## Bento — ciclo automático

1. Em **H → Equipe e treinamento**, contrate Bento por $120 se necessário.
2. Abra **Rotina e orçamento**. Marque canteiros, escolha o próximo cultivo de cada um
   e deixe **Regar**, **Colher** e **Replantar** ativos para o ciclo completo.
3. Defina, por exemplo, $100 de orçamento. **Revisar e ativar** mostra os custos;
   voltar não modifica a rotina. Confirme **Ativar rotina**.
4. Feche os menus e use **TAB** para caminhar. Tempo e trabalho só avançam assim.
   Bento caminha até a lavoura, colhe a madura, replanta a cultura escolhida e rega.
   A cultura que já estava plantada não muda antes de colher. Zeca segue no galinheiro.
5. Confira **Resultados**: produção no estoque, contagem de ações e custos separados.
   Serviço: $2 por tarefa ($1 treinado); sementes: cenoura $4, trigo $6, milho $8.
   Exemplo sem treinamento: colher, replantar trigo e regar custa $12 ($6 serviços + $6 sementes).
6. Use um limite pequeno: se a próxima tarefa não couber, Bento pausa sem cobrar parte dela.
   Editar a rotina, salvar ou reabrir não zera o gasto. **Renovar orçamento…** mostra
   confirmação antes de liberar novamente o limite. O relatório acumulado permanece.
7. Teste cada tarefa desmarcada. Canteiros não selecionados ficam fora da rotina.
   A colheita não é vendida automaticamente: vá ao armazém quando quiser negociar.
8. Pause Bento no cartão da equipe; Zeca deve continuar. Treinar cada um custa $240,
   reduz taxa de serviço para $1 e acelera a caminhada e o trabalho.
9. F5 salva. Feche e reabra para conferir culturas, tarefas, orçamento, relatório e treinamento.
   Sem saldo, só o trabalhador impedido pausa; sem acesso, libere a passagem e retome.

Save formato **10**. Depois de salvar na 0.14, continue nela ou em versão posterior.
Testes automáticos usam partida isolada e não alteram a fazenda real.
Não há trabalho ou cobrança com menus abertos, em construção ou com o jogo fechado.

## Novidades da 0.11 — teste primeiro

1. Em caminhada (TAB), pressione **Espaço**. Teste parado, andando (WASD) e correndo (Shift).
   Confira subida, pose no ar e aterrissagem. Apertar de novo no ar não dá outro impulso.
   Construção, menus e animações de trabalho bloqueiam o início de um pulo.
2. Abra seu celeiro, galinheiro ou oficina com **E**. Clique **Evoluir • $…**.
   Confira custo, benefício e localização. **Voltar sem comprar** não gasta dinheiro.
3. Celeiro: confirme **$360**. A reserva desta construção sobe de 60 para 120 unidades;
   os produtos e a pintura permanecem. Confira as caixas e a cobertura na fachada.
4. Galinheiro: confirme **$420**. Agora são seis galinhas, com ninho de 24 ovos e quatro
   ovos por ciclo, consumindo o dobro de água/ração. Abra a aba Galinhas para renomear as novas.
   Observe os ninhos adicionais e a torre de ventilação. Ovos antigos não se perdem.
5. Oficina: confirme **$500**. Ela ganha armário e bancada equipada. Com o regador de
   cinco canteiros comprado ($300), adquira o profissional por **$450**.
   Monte nove canteiros em 3 × 3 e regue o central: os secos devem receber água, inclusive diagonais.
6. Salve com F5 e reabra. Níveis, nomes, estoque e ferramentas devem permanecer.
   Cada construção evolui individualmente, até o nível 2 nesta versão.
7. Remover uma estrutura devolve metade da construção + evolução. Produtos reservados e
   ovos continuam protegendo a remoção; equipamentos adquiridos não desaparecem com a oficina.

Saves anteriores migram para o formato 9. Depois de salvar na 0.12, continue usando esta versão;
executáveis antigos não reconhecem o novo formato. Os testes automáticos usam save separado.

## Novidades da 0.10 — teste primeiro

1. Veja o protagonista, Zeca e Dona Lúcia de frente, perfil e costas. Confira a linha do cabelo,
   as laterais junto às orelhas e o encaixe sob o chapéu; observe também as piscadas.
2. Caminhe até a porta do celeiro e pressione **E**. O painel mostra disponível e reserva
   de cada produto. Guarde e retire um produto; vender não deve consumir a reserva.
   A entrada abre esse menu de estoque; ainda não existe interior 3D explorável.
3. Em construção (TAB), pressione **9** e coloque a **Oficina rural ($180)**.
   Aproxime-se da entrada em caminhada e pressione E para abrir a bancada.
   O regador melhorado custa $300; se já foi comprado, permanece instalado, sem nova cobrança.
4. Com Zeca contratado, abra **H → Irrigação**. Marque apenas os canteiros desejados e ative.
   Ativar não cobra: cada canteiro seco e plantado custa **$2 quando a rega termina**.
   Essa rotina substitui o trato das galinhas. Para voltar, atribua um galinheiro pelo painel H.
5. Feche as janelas, use TAB para caminhar e observe Zeca ir até cada canteiro e usar o regador.
   Canteiros molhados, vazios ou maduros não cobram. A melhoria em área é da rega manual.
6. Abra H e pause/retome. Janelas e construção também pausam. Sem $2 ou caminho livre,
   ele pausa sem cobrar; resolva o motivo e retome em H. Remover todos os canteiros escolhidos pausa o ajudante.
7. Salve com F5 e reabra: confira seleção e gastos. Saves antigos são aceitos, com irrigação desligada.
   Não há irrigação nem cobrança com o jogo fechado. Não abra duas versões simultaneamente.

## 0. Correções e rotina da 0.9

1. Gire a câmera ao redor dos chapéus: as mechas devem permanecer sob a aba.
2. Regue um canteiro seco com E. Confira a mão na alça, o bico à frente e as gotas saindo dele.
3. Visite o armazém: Dona Lúcia deve aparecer na tenda e nos textos de interação/venda.
4. Com Zeca contratado e ativo, feche as janelas e use TAB para caminhar.
   Observe por 20 segundos: ronda, ida ao ninho e, se houver ovos, agachamento e ovo na mão.
5. A coleta só acontece na checagem de 15 segundos se o ponto de acesso estiver alcançado.
   Se aparecer CAMINHO BLOQUEADO, libere a frente e os lados do galinheiro.
   Sem acesso, não há coleta ou cobrança. As rotas são locais e não abrem portões.
6. Pause em H: Zeca para de andar. Janelas e modo de construção também pausam a rotina.

## Conferir os personagens novos

1. Abra a **0.11.0** e retome sua fazenda. O protagonista já usa o modelo novo.
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
7. Pare e observe cada rosto por 10 segundos: os olhos devem fechar e reabrir
   rapidamente, em intervalos diferentes. Confira também Zeca pausado e o vendedor.
8. Zeca deve ter barriga/tronco mais largos e ambos devem ter olhos menores.
   Sorrisos ainda são fixos e a galinha não articula asas/pescoço.
   Esta é uma base de animação; poses novas poderão precisar de ajustes.

## 1. Ver o Zeca trabalhar — cerca de 2 minutos

1. Tenha um galinheiro e pelo menos **$132** livres: $120 para contratar e uma
   folga para o serviço. Se precisar, venda uma parte do estoque pelo **F**.
   Um galinheiro novo custa $180 e já inclui três galinhas, água e ração.
2. Pressione **H** ou clique em **Ajudante [H]** no topo. Escolha o galinheiro.
3. Clique em **Contratar • conferir custos**, leia os valores e confirme **$120**.
   O saldo deve cair exatamente $120. Zeca aparece junto ao galinheiro.
4. Feche a janela e vá para caminhada com **TAB**. Não recolha os ovos manualmente.
   Se o ninho já tinha ovos, ele coleta na próxima checagem, na checagem de 15 segundos, com acesso livre ao ninho.
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
   e saia pelo menu. Abra novamente a **0.11.0**: ele continua contratado e pausado,
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
