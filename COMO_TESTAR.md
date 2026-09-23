# Como testar a versão 0.24.0

Extraia o ZIP e abra **DoMatoAoMilhao.exe**. Continue sua fazenda; não precisa reiniciar.

1. **Minimapa:** andando ou montado, confira sua seta branca, o rio, os caminhos e seus terrenos. Norte fica para cima.
2. **Mapa completo:** pressione **M** ou clique no minimapa. Escolha um destino à direita ou clique numa área do mapa. A distância aparece no minimapa; a linha é direta, não uma rota automática.
3. **Encontrar o cavalo:** escolha **Pé de Pano** no mapa. O marcador acompanha sua posição atual. **Limpar destino** remove a marcação. Destinos são temporários, não ficam no save.
4. **Cavalo remodelado:** observe de lado e de frente, monte com **E**, ande com **WASD** e toque **Shift** para galopar. Confira pernas, pescoço e focinho. **E** desmonta em local livre.
5. **Tela cheia integrada:** use **F11** para alternar janela/tela cheia, inclusive com o mapa aberto. **M** ou **Esc** fecha o mapa. No modo construção, **M** continua sendo mover construção.
6. **Save:** use **F5**, feche e reabra. Fazenda, cavalo e inventário da P-8 permanecem. Dinheiro infinito mantido.

Abertura do mapa pausa deslocamento e ações. Terrenos comprados e construções aparecem no mapa; árvores removidas pela expansão também desaparecem dele.

## Histórico — tela cheia 0.23.2

O jogo inicia em **tela cheia**. Use **F11** para alternar entre janela e tela cheia. Experimente também no menu e ao digitar o nome da fazenda. A imagem deve ocupar toda a tela, com botões clicáveis, menus centralizados e sem faixas pretas.

## Conteúdo integrado

Extraia todo o ZIP para uma pasta e abra **DoMatoAoMilhao.exe**. Retome sua fazenda existente.

1. **Damião:** siga a estrada oeste até a bancada próxima ao armazém. Use **E**, compre a P-8 e feche a loja.
2. **Treino:** **P** saca/guarda, botão direito e mouse miram, clique esquerdo dispara e **R** recarrega. Os três alvos ao lado da loja reagem aos acertos.
3. **Pé de Pano:** chegue perto do cavalo e use **E** para montar. A pistola será guardada. **WASD** cavalga, toque em **Shift** dá o tapinha para galopar e **E** desmonta em local livre.
4. **Passeio:** confira o pomar, as pedras e a campina no circuito ampliado do vale.
5. **Persistência:** use **F5**, feche e reabra. Fazenda, cavalo, arma e munição continuam salvos. Dinheiro infinito permanece ativo.

A versão reúne as duas entregas no save 16. Ao montar ou abrir menus, uma recarga em andamento é cancelada sem consumir munição. Armas funcionam a pé e os disparos atingem os alvos de treino; personagens e animais não recebem dano.

## Histórico de testes — terrenos 0.21

Extraia o ZIP e abra `DoMatoAoMilhao.exe`. Escolha **Voltar para minha fazenda**.
A versão aceita a partida anterior. Não precisa começar outra.

## Terrenos, natureza e dinheiro infinito — novidade

1. Continue sua fazenda. O saldo aparece como **∞** automaticamente, inclusive em partidas antigas. Compras e serviços não esgotam o dinheiro. Requisitos de nível, leite, sementes e limites configurados de funcionários continuam funcionando.
2. Use **T · Terrenos** para comprar **Clareira do Bosque** (leste), **Campo dos Ipês** (norte) ou **Campina do Sol** (sul). Cada lote tem 24 × 24 m. Os preços são informativos enquanto o dinheiro infinito estiver ativo.
3. Ao comprar, as árvores, pássaros, arbustos e capim que interferem no lote saem do cenário. A mesma limpeza ocorre ao expandir a propriedade original. O restante do vale continua arborizado; construções do jogador não são apagadas.
4. Caminhe até a placa do novo terreno, use **TAB** e construa ali. A grade acompanha o terreno sob o cursor. O estoque é compartilhado; ajudantes podem trabalhar nesses lotes.
5. Salve com **F5** e retome. Os terrenos continuam seus e a limpeza é reconstruída sem reaparecer dentro da propriedade.
6. Fora do terreno, confira o capim fino e árvores maiores. Alguns galhos têm pássaros pousados, com pequenos saltos e movimentos de cabeça.
7. Na margem do rio, observe os filetes claros acompanhando a correnteza numa mesma direção.

A área de caminhada agora é 142 × 190 m. Cavalo como transporte e veículos continuam planejados para etapas futuras.
O save foi atualizado para versão 15, preservando construções, produção, equipe e progresso anteriores. A regra permanente de dinheiro infinito está em `AGENTS.md`.

**QA isolado:** `-- --qa --qa-v021`, em desenvolvimento, valida compras, limpeza, Zeca no terreno leste, dinheiro infinito, persistência e capturas do rio/pássaros. Usa apenas o save QA.

## Vale renovado — 0.20

1. Continue sua fazenda. O cenário novo aparece sem reiniciar nem mover suas construções.
2. Caminhe com **WASD** e gire com **mouse direito**: confira as manchas naturais no gramado, flores menores e capim com movimento suave.
3. Siga a estrada que passa ao sul da fazenda em direção ao **BOSQUE** (leste). Há árvores, arbustos e um banco junto à trilha. Agora é possível caminhar além do antigo limite.
4. Vá até o armazém de Dona Lúcia e siga para o lado do rio. Observe a margem, pedras e água em movimento. A margem é explorável; atravessar o rio ainda não faz parte deste bloco.
5. Em **TAB**, construa ou mova um canteiro, caminho ou prédio sobre o gramado. O capim deve desaparecer do espaço ocupado e reaparecer no local liberado.
6. Caminhe no bosque, abra **TAB** e volte: o personagem deve continuar no local, sobre o terreno, sem ser puxado para o limite antigo.
7. Confira seus ajudantes, animais, colheitas e **F5**. O cenário usa o mesmo save 14; as regras e a área máxima da propriedade permanecem.

A área de caminhada passou de aproximadamente 75 × 82 m para 104 × 128 m (2,16 vezes a área). A câmera de construção acompanha essa ampliação. A ampliação é do vale explorável; não aumenta gratuitamente seu terreno.

Sete novos modelos originais têm fontes Blender em `art/source/valley_*.blend`. Gramado, terra, margens e água usam materiais procedurais; o mapa tem colinas contínuas e relevo suave apenas fora da região construível.

**Teste isolado no Godot:** `-- --qa --qa-v020`, somente em desenvolvimento. Valida o piso, caminhada ampliada e vegetação fora das construções; captura quatro vistas em `test-results/valley-v020-*.png`. Usa o arquivo de teste, sem gravar sua fazenda real.

## Níveis da fazenda

1. Continue sua partida. Clique em **FAZENDA · NÍVEL** no alto da tela para ver os seis desbloqueios.
2. Colha um canteiro: **+10 XP**. Colete ovos: **+2 por ovo**; leite: **+3 por litro**; queijo: **+8 por unidade**.
3. Entregue uma encomenda: **+30 XP**, incluindo o primeiro pedido da Dona Nena.
4. Os ajudantes dão a mesma experiência ao concluir a coleta. Regar, replantar, vender, construir e mover não dão XP.
5. Em **TAB**, construções bloqueadas mostram cadeado e nível. Clique ou use o atalho: abre o painel de níveis sem gastar moedas.
6. Ao alcançar um nível, surge o aviso e a construção fica disponível pelo preço normal. **F5**, feche e reabra para conferir o progresso.

| Nível | XP acumulado | Desbloqueio |
|---|---:|---|
| 1 | 0 | Canteiros, cercas, placas e caminhos |
| 2 | 30 | Galinheiro |
| 3 | 120 | Celeiro |
| 4 | 280 | Oficina rural |
| 5 | 550 | Curral |
| 6 | 950 | Queijaria |

O limite deste bloco é nível 6; XP continua registrado. Melhorias dos prédios e treinamento dos funcionários são independentes.
Partidas antigas recebem XP de reconhecimento por colheitas/encomendas registradas e um nível mínimo pelas construções, funcionários e equipamentos existentes. Dinheiro, estoque e construções permanecem. Não resete sua fazenda para testar.

**Teste automático do começo, sem tocar na partida real:** execute o projeto no Godot com `-- --qa --qa-v019` (somente versão de desenvolvimento). Usa `qa_farm_v021.json`. Três canteiros colhidos liberam o galinheiro; o teste também confere bloqueios, tela e recarga do XP. A versão exportada ignora esse modo.

## Conferir as mãos corrigidas

1. Em caminhada, aproxime a câmera e use **B → Six Seven**. Observe de frente e de lado.
2. A palma deve acompanhar o antebraço sem dobrar o punho lateralmente em ângulo reto.
3. Confira também parado, correndo, nas outras danças, regando e colhendo.
4. Olhe as mãos de Zeca, Lúcia, Chico e Raul: todos receberam o polegar revisado.
5. Interrompa a dança e regue um canteiro; a orientação deve retornar normalmente.

## Six Seven

1. Em caminhada, fique parado no chão, aperte **B** e escolha **Six Seven** no centro.
2. As mãos alternam a altura com as palmas para cima. A dança dura seis segundos.
3. Interrompa com WASD, Espaço ou abrindo uma interação. O personagem responde imediatamente.
4. As outras três danças e os três emojis continuam disponíveis. Não foi adicionada música.

## Raul do Curral — teste rápido

1. Retome sua fazenda e tenha um curral com Mimosa. Abra **E no curral → Raul · Cuidar do curral**.
   Também está em **H → Equipe e treinamento → Raul · Curral**.
2. Revise a contratação de **$140**. Voltar não cobra; confirmar contrata uma vez.
3. Escolha o curral, deixe **$60 de limite**, revise e confirme **Aplicar rotina**.
4. Feche os menus e fique no modo caminhada. Aos **4 L**, ele abre a porteira, chama Mimosa,
   entra, agacha para ordenhar e sai com o recipiente. Não bloqueie a entrada.
5. Aos **35%**, ele repõe água ou ração. Cada tarefa custa **$2**, mais a ração quando usada.
   Água não custa material. O limite de $60 inclui serviço e ração; não é cobrado antecipadamente.
6. Contrate/configure Chico na queijaria, com **2 queijos por lote**. O leite recolhido pelo Raul
   abastece automaticamente a produção. Após a coleta do Chico, confira o queijo no estoque.
7. Abra o painel do Raul: veja tarefas, litros e gasto total. Aplicar novamente mantém a verba usada.
   **Renovar orçamento** só zera o usado após confirmar; o gasto histórico permanece.
8. Pause no meio da ordenha: a tarefa incompleta não cobra nem recolhe leite. Raul sai com segurança.
   Menus e modo construção congelam a simulação inteira, incluindo essa saída.
9. Se faltar saldo/verba ou uma cerca bloquear a entrada, ele pausa. Libere a passagem, reponha
   saldo ou renove a verba e use **Retomar**. Não atravessa a cerca para concluir tarefas.
10. Salve com F5 e reabra: atribuição, orçamento e relatório ficam. A pose pode reiniciar;
    leite e serviços já concluídos não duplicam. Dispensa preserva vaca e leite; recontratar custa $140.

O leite é transferido ao concluir a ordenha; o trajeto de saída representa o transporte.
Uma vaga de Raul pode atender um curral por vez. Sem produção enquanto o jogo está fechado.

## Chico Queijeiro — para testar quando puder

1. Retome a fazenda. Abra **E na queijaria → Chico Queijeiro**, ou **H → Equipe e treinamento → Chico**.
2. Revise a contratação de **$160** e volte: não deve cobrar. Confirme para contratar.
3. Escolha a queijaria, **2 queijos por lote** e **$8 de limite total**. Revise e aplique.
4. Tenha **8 L de leite no estoque**, coletados no curral. Chico espera o leite do lote inteiro, sem buscar na vaca.
5. Feche os menus e fique em caminhada. Observe buscar leite, levar o recipiente, preparar, rondar e recolher os queijos.
6. Após dois lotes, o relatório deve mostrar **2 lotes, 4 queijos recolhidos e $8 de serviços**.
   Sem mais verba, nenhum lote novo começa. Produção leva 90 s/lote, mais caminhada e manuseio.
7. Abra e aplique a rotina novamente: os $8 usados permanecem. **Renovar orçamento** libera outra verba só ao confirmar.
8. Pause durante a caminhada: nenhuma taxa/leite é descontada até completar um novo início de lote.
   Lotes já iniciados seguem a produção normal quando a fazenda está ativa; a coleta espera você retomar o Chico.
9. Bloqueie o caminho até a frente da queijaria: ele pausa sem cobrar. Libere e use **Retomar**.
10. Salve no meio do trabalho e reabra: atribuição, verba e relatório ficam. A animação pode recomeçar; cobrança não duplica.
11. Dispense Chico: leite e queijos ficam, assim como o lote em preparo. Recontratar custa $160 e preserva o histórico.
12. Venda queijos ou entregue pedidos manualmente. Chico não vende nem entrega encomendas.

Save atual: **formato 13**. Depois de salvar, use a 0.18 ou posterior. Nenhum funcionário é contratado automaticamente ao migrar.

## Queijaria

1. Retome sua fazenda e colete leite da Mimosa. A queijaria usa o leite do estoque, não o que está no curral.
2. **TAB → G / Queijaria**: custa **$900**, ocupa **6 × 6 m**. Posicione em área livre e gire com Q/R se quiser.
3. Volte à caminhada, aproxime-se da porta e aperte **E · Fazer queijo**.
4. Escolha **1 a 4 queijos**. Cada queijo usa **2 L**. Revise e volte: nenhum leite deve ser consumido.
5. Escolha novamente e confirme: leite descontado uma vez; qualquer lote demora **90 segundos**.
6. Feche o menu e fique em caminhada. Reabra para conferir o progresso. O tempo pausa em menus e construção.
7. Salve com F5 no meio do lote e reabra o jogo: o preparo deve continuar de onde parou, sem descontar leite outra vez.
8. Ao aparecer **Queijo pronto · Recolher lote**, clique no aviso ou use E na queijaria. Recolha uma vez.
9. **F → Leite e queijo → Vender queijo**: venda uma unidade por **$52** e confira saldo e quantidade.
   **Vender tudo** inclui o queijo recolhido; não inclui produção ainda dentro da queijaria.
10. **Encomendas → Pedidos de queijo**, ou botão da queijaria: aceite o pedido da Dona Nena.
    O primeiro pede **3 queijos por $192 + 1 reputação**. Depois, pedidos de 4 e 5 queijos.
    Não há prazo; cancelar não cobra. Vendas normais podem consumir estoque que você pretendia entregar.
11. Mova a queijaria durante um lote: produção e tempo permanecem. Remover com lote ativo/pronto é bloqueado.

Save agora é **formato 13**. Use a 0.18 ou posterior depois de salvar.
Início e coleta podem ser manuais ou feitos por Chico. A produção não avança com o jogo fechado.

## Humor e Mimosa

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
   Save atual: **formato 13**. Depois de salvar na 0.17, use esta versão ou posterior.

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


## 0.22 — Passeio pelo vale

Continue sua fazenda e aperte TAB para caminhar. Use WASD e Shift para correr.
Siga a estrada ao norte: a placa IPÊS / MIRANTE leva ao Campo dos Ipês e ao moinho do Mirante dos Ventos.
Ao sul, siga CAMPINA / ABÓBORAS para a Campina do Sol e a carroça na Curva da Abóbora.
Ao leste, a estrada leva ao Recanto da Prosa; a trilha que segue ao norte chega à Clareira do Bosque.
Observe o moinho girando e as mensagens ao chegar às três paradas. Elas aparecem uma vez por sessão.
T continua abrindo os terrenos; F5 salva. O cavalo ainda não foi implementado.


## 0.23 — Cavalo e mapa ampliado

1. Continue sua fazenda e use TAB para caminhar. Pé de Pano começa na estrada junto ao rio, um pouco ao norte do armazém de Lúcia (x=-30, z=5). Ele já está disponível, sem compra nesta versão.
2. Chegue perto e aperte E para montar. WASD cavalga; mouse direito gira a câmera.
3. Dê um toque em Shift: o personagem dá um tapinha na lateral e o cavalo galopa por 3,5 segundos. Cada impulso custa 25 de fôlego; veja a barra. O fôlego recupera andando ou parado fora do galope.
4. Siga ao norte, passe o moinho e procure CIRCUITO DO VALE. O trajeto passa pelo pomar, pedras e flores, voltando perto da carroça. Uma ligação ao leste também acessa o circuito.
5. E desmonta ao lado, procurando espaço livre. Se estiver apertado, afaste-se dos obstáculos. TAB desmonta antes de entrar na construção. Emotes e salto do personagem ficam disponíveis a pé.
6. F5 salva a posição do cavalo. Ao reabrir, você começa a pé e ele permanece onde foi deixado. Se uma construção ocupar o lugar, ele é reposicionado para perto, em espaço livre.
7. Abra um menu durante a montaria: o deslocamento e o impulso devem pausar. Feche para continuar.

O cavalo ainda não tem compra, alimentação ou evolução; este bloco entrega montaria e exploração. Seu dinheiro infinito continua ativo.
