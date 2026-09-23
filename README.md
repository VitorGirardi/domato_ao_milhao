# Do Mato ao Milhão

**Comece com um terreno. Termine comprando a vizinhança.**

Protótipo jogável de um tycoon de fazenda 3D estilizado para Windows, em português.
Godot 4.7.2 + modelos originais feitos no Blender 5.2.1. Campanha solo e offline.

**Versão atual: 0.26.0.** Veja [as prioridades](ROADMAP.md) e [as novidades](CHANGELOG.md).

Veja o [roteiro de teste manual](COMO_TESTAR.md), incluindo encomendas e vendas da 0.5.

## Jogar

O executável local fica em `exports/windows-v0.26.0/DoMatoAoMilhao.exe` depois da exportação.
Ele abre diretamente, sem instalar Godot ou Blender. Os binários não são enviados ao Git.

Para executar a partir do código:
1. Abra o Godot 4.7.2, escolha **Importar** e selecione `project.godot`.
2. Aguarde a importação dos modelos.
3. Pressione **F5** para jogar. O cenário é montado pelos scripts durante a execução.

## Novidades da 0.26.0

Menu inicial com foto do vale, Continuar, Novo jogo, Configurações e Controles. Preferências de volume, câmera, qualidade, FPS e tela cheia ficam salvas. Novo jogo pede confirmação e arquiva a fazenda anterior. Esc permite salvar e voltar ao menu.

## Tela cheia

O jogo abre em tela cheia; **F11** alterna para janela e volta, inclusive nos menus. O cenário preenche diferentes proporções de monitor sem faixas pretas, enquanto menus e HUD mantêm tamanho proporcional e espaçamento. [Detalhes e QA](TELA_CHEIA.md).

## Novidades da 0.23.1

Damião vende a P-8 e munição na estrada oeste, perto do armazém. **E** abre a loja; **P** saca/guarda, **mouse direito** mira, **clique esquerdo** dispara e **R** recarrega. Três alvos permitem treinar. Montar guarda a arma automaticamente; save 16 preserva cavalo e inventário. [Guia do armeiro](ARMEIRO.md).

## Novidades da 0.23.0

Pé de Pano é uma montaria jogável: **E** monta/desmonta, **WASD** cavalga e um toque em **Shift** dá um tapinha para galopar, consumindo fôlego. Mapa de 214 × 290 m com circuito longo, pomar, pedras e campina florida. Save 16 preserva a posição do cavalo; dinheiro infinito mantido. [Como testar](COMO_TESTAR.md). Cuidados e progressão da montaria, depois veículos, ficam para próximas etapas.

## Novidades da 0.20.0

Vale com gramado e trilhas procedurais, bosques originais Blender, flores, vento no capim, rio animado e relevo contínuo. A área de caminhada mais que dobrou; o terreno construível e sua partida são preservados. [Roteiro de exploração](COMO_TESTAR.md).

## Novidades da 0.19.0

A fazenda tem seis níveis. Produção e encomendas rendem XP, inclusive com ajudantes. Clique no indicador de nível para ver os desbloqueios; construções bloqueadas mostram cadeado. Partidas antigas preservam seu progresso com migração para save 14. [Como testar](COMO_TESTAR.md).

## Novidades da 0.18.2

- Corrige a Six Seven: a palma gira pelo eixo longitudinal do antebraço, preservando o alinhamento do punho.
- Polegar mais curto e arredondado, ligado à região correta da palma nos cinco modelos de personagem.
- Pesos da palma e do polegar definidos pela topologia da mão, sem depender de limites de coordenadas do corpo.
- Revisão ampliada de danças, caminhada, corrida, rega, coleta e transporte. Save permanece no formato 13.

## Recursos da 0.18.1

- **B → Six Seven**: quarto emote de dança, mãos abertas alternando a altura e balanço do corpo.
- Dura seis segundos e cancela ao andar, pular ou interagir. Animação original no rig do personagem, sem faixa musical adicionada.

## Recursos da 0.18

- **Raul do Curral**, em **E no curral → Raul**, ou **H → Equipe e treinamento → Raul**.
- Contratação de **$140**; **$2 por tarefa concluída**, mais a ração utilizada. O limite inclui os dois.
- Ordenha a partir de **4 L**; repõe água e ração quando chegam a **35%**.
- Abre a porteira, espera Mimosa se posicionar, entra, ordenha agachado e sai carregando leite.
- Saco de ração e recipiente com água acompanham as tarefas. Fora do atendimento, Mimosa volta a pastar.
- Leite entra no estoque compartilhado e abastece os lotes do Chico. Vendas continuam manuais.
- Pausa, dispensa, renovação explícita e relatório de litros, tarefas e gastos.
- **Save 13**, migração sem contratação automática; orçamento e resultados persistem.

## Recursos da 0.17

- **Chico Queijeiro**: na queijaria ou em **H → Equipe e treinamento → Chico**.
- Contratação de **$160**; uma queijaria atribuída, lote de 1 a 4 queijos e limite total de serviços.
- Busca leite do estoque compartilhado, inicia lotes por **$4 cada** e recolhe queijos **sem taxa**.
- Aguarda leite suficiente para o lote escolhido. Pausa sem cobrar se falta saldo, verba ou passagem.
- **Aplicar rotina** mantém o gasto usado; **Renovar orçamento** exige confirmação e preserva o histórico.
- Pausar e dispensar não apagam leite, queijos ou lotes em preparo. Recontratar preserva gastos/resultados.
- Aparência própria no Blender, piscar, caminhar, carregar leite e bandeja de queijos; pequenas rondas durante espera.
- Venda e encomendas continuam manuais. Chico não coleta leite diretamente da vaca.
- **Save 12**, compatível com versões anteriores; não contrata funcionários automaticamente.

## Recursos da 0.16

- **Queijaria ($900)**: TAB → **G**, terreno de 6 × 6 m; E na porta abre a produção.
- **2 L de leite → 1 queijo**. Escolha de 1 a 4 queijos; qualquer lote leva **90 s** de jogo ativo.
- Prévia antes de consumir leite, preparo, aviso de lote pronto e coleta manual. Menus e construção pausam.
- **F → Leite e queijo** vende queijos a **$52/un.**; Vender tudo inclui queijos já recolhidos.
- Pedidos de queijo da **Dona Nena**: 3, 4 ou 5 unidades por **$64/un. + 1 reputação**.
  Aceite antes de entregar. Sem prazo ou multa; o pedido não reserva seu estoque.
- Mover mantém o lote. Remover durante preparo ou antes de recolher é bloqueado.
- **Save 11** preserva produção em andamento, estoque e pedido. Migra saves anteriores.
- Construção original no Blender, ícones e telas próprias; sem automação da queijaria nesta etapa.

## Recursos da 0.15

- **B · Emotes** abre a roda: Dança da Galinha, Passinho do Milho e Rei da Colheita.
- Gargalhada, coração e “Cadê meu milho?!” aparecem acima do personagem por alguns segundos.
- Andar, pular ou interagir cancela a dança. A seleção pausa a fazenda; dançar não pausa a produção.
- Mimosa caminha, vira, pasta abaixando o pescoço, mastiga e descansa em pé.
- Curral reorganizado para dar espaço ao trajeto. A vaca aguarda se o jogador estiver no caminho.
- Animações no Godot sobre os modelos Blender. Save continua no formato 10.
- A 0.16 acrescenta queijaria e encomendas de queijo.

## Recursos da 0.14

- **Curral ($650)**, na tecla **0** em construção. Ocupa 8 × 6 metros e tem uma vaga.
- Compre **Mimosa ($480)** pelo menu do curral; começa com ração e água.
- Modelos originais Blender, movimentos de cabeça, cauda e patas; cerca, abrigo e cochos.
- Produção de **2 L a cada 60 s**, com água e ração. Capacidade de 8 L; ao encher,
  colete para retomar. Sem suprimentos, a produção para, sem morte da vaca.
- Repor ração custa até $12; água grátis. Tempo só avança em caminhada, menus fechados.
- Leite coletado vai a um estoque próprio, acessível no curral, celeiro e armazém.
  Venda por quantidade a **$18/L**, ou junto com **Vender tudo**. Nesta etapa leite não tem reserva.
- Mover preserva a vaca e o leite. Remover curral ocupado é bloqueado para evitar perda.
- Save **10** migra fazendas antigas, mantendo os demais sistemas.
- O bloco seguinte, 0.15, acrescenta emotes e a rotina visual da vaca.

## Recursos da 0.13

- HUD de caminhada compacto: relógio, saldo, objetivo recolhido e atalhos pequenos.
- Ação próxima destacada, com o mesmo alvo do E: celeiro, oficina, galinhas, placa,
  comércio e cultivos. Plantas crescendo mostram progresso sem sugerir uma ação pronta.
- Sementes aparecem somente perto de canteiros vazios; objetivos detalhados abrem ao clicar.
- Aviso de ninho cheio ou ajudante pausado leva direto ao galinheiro/equipe.
- Alertas não repetem a cada quadro; fim de cada trato e primeiros ovos não geram mais mensagens.
- Construção conserva suas ferramentas. Save continua no formato 9.

## Recursos da 0.12

- Menus de celeiro, galinheiro, oficina, armazém, encomendas e equipe com ícones,
  ações curtas, cartões e números separados. O HUD do campo fica oculto nas janelas.
- Bento pode **regar, colher e replantar**, com tarefas independentes e cultura por canteiro.
- **H → Equipe e treinamento → Rotina e orçamento**. Selecione os canteiros,
  defina o limite total e confirme. As culturas atuais ficam até a próxima colheita.
- Cada tarefa custa $2 ($1 após treinar); replantar soma sementes: cenoura $4,
  trigo $6 ou milho $8 por canteiro. Cobra somente quando conclui.
- Sem saldo ou orçamento suficiente para a tarefa inteira, apenas Bento pausa.
  O limite não renova ao editar, salvar, reabrir ou virar o dia; use **Renovar orçamento**.
- Resultados mostram produção por cultura, plantios, serviços e sementes acumulados.
  Renovar o limite preserva esse relatório. A produção vai ao estoque; a venda é sua decisão.
- Save 9 preserva fazendas anteriores. Irrigação antiga continua até ativar a rotina completa.

## Recursos anteriores — 0.11

**Equipe simultânea:** H → Equipe e treinamento. Zeca cuida de um galinheiro e Bento
rega os canteiros selecionados. Bento custa $120 para contratar e $2 por rega concluída.
Os dois têm pausas, gastos e treinamento independentes. A primeira equipe tem duas vagas fixas.
Treinar cada um custa $240: caminhada 40% mais rápida e serviço de $2 para $1.
Zeca confere o trato a cada 10 s; Bento também rega 40% mais rápido. Ração é cobrada à parte.
Na 0.11 a lavoura tinha somente rega automática; a 0.12 também permite plantar e colher.
Saves antigos mantêm a tarefa do Zeca; Bento não é contratado automaticamente.



- **Espaço** pula no modo caminhada, com pose no ar e aterrissagem. Sem pulo duplo ou durante trabalho/menus.
- Dois níveis para celeiro, galinheiro e oficina, com prévia, confirmação e detalhes modelados no Blender.
- Celeiro nível 2 ($360): reserva individual de 60 para 120 produtos.
- Galinheiro nível 2 ($420): inclui três novas galinhas, totalizando seis; ninho de 24 ovos,
  quatro ovos por ciclo e consumo dobrado de água/ração. Todas podem ser renomeadas.
- Oficina nível 2 ($500): libera o regador profissional ($450), após o regador básico de área ($300).
  Rega manual de até nove canteiros (3 × 3); não muda o custo ou alcance do Zeca.
- Evoluções mantêm pintura, lugar e conteúdo. Remover devolve metade da estrutura e da evolução;
  equipamentos comprados permanecem com o jogador. Cada construção evolui separadamente.
- Save 8 migra as fazendas anteriores para nível 1 e mantém as compras antigas.

## Recursos da 0.10

- Cabelo contínuo nos três personagens, revisado em quatro ângulos no Godot.
- Celeiro: entrada com E abre estoque disponível, reserva e total por produto.
- Oficina rural: construção de $180 na tecla 9; bancada de melhorias transferida para ela.
- Zeca: em H, escolha Irrigação e marque canteiros. Custa $2 por canteiro efetivamente regado.
  Essa rotina substitui o trato do galinheiro até você atribuí-lo novamente.
  Sem saldo ou passagem, Zeca pausa; feche janelas e use caminhada para ele trabalhar.
- Save formato 6, compatível com os formatos anteriores e melhorias já compradas.

## Ações da 0.9

- Cabelo aparado sob a superfície curva do chapéu, incluindo as pontas das mechas.
- Regador orientado pela alça, com recipiente em pé, inclinação de despejo e gotas saindo do bico.
- Zeca caminha entre pontos próximos do galinheiro, vai ao ninho e se abaixa com um ovo na mão.
- Rotas locais desviam de construções/cercas; se o ninho estiver inacessível, não há serviço nem cobrança.
- Dona Lúcia substitui Seu Tonico com modelo próprio, tranças, brincos, roupa e piscadas.

A ronda fica próxima do galinheiro atribuído. A verificação de serviço continua
a cada 15 segundos e só conclui se Zeca tiver alcançado o ponto de acesso ao ninho.
Uma frente bloqueada pode adiar a rodada. Mantenha passagem livre ao redor da construção.
Não há abertura de portões ou transporte até um depósito nesta etapa.

## Personagens e galinhas — corpos conectados

A revisão 0.8.1 deixou Zeca mais corpulento, com barriga e tronco largos.
Os dois modelos têm olhos cerca de um terço menores, íris castanha e pupilas
reduzidas. Um morph facial fecha os olhos em 0,22 segundo; cada personagem
pisca de forma independente, com pausas entre 2,5 e 5,5 segundos.
Zeca e o vendedor também piscam quando o tempo da fazenda está pausado.

A 0.8 refaz a anatomia do protagonista e do Zeca: ombros, tronco, braços,
quadril, mãos e pernas compartilham uma malha contínua. Pernas mais longas,
cintura definida e botas menores substituem os volumes arredondados separados.
Os rostos cartoon e as roupas rurais continuam seguindo a direção aprovada.

Cada personagem tem um esqueleto de 20 ossos e pesos de deformação, com
cotovelos e joelhos dobráveis. O regador acompanha a mão por um encaixe no osso.
A movimentação ainda é procedural; não há IK, dedos individuais ou rig facial.
Poses mais extremas e futuras animações poderão exigir ajustes de pesos.

As galinhas têm peito, pescoço e raízes das asas contínuos, penas sobrepostas,
crista, olhos expressivos e patas com dedos e movimento alternado. Preservam
as três cores, nomes, cuidados, produção e comportamentos anteriores.
As patas usam pivôs; a galinha ainda não tem esqueleto completo para asas/pescoço.

O conceito aprovado está em `art/concepts/characters-approved.png`; é uma imagem
ilustrativa. As capturas de `tests/render_characters.gd` mostram os GLBs reais no
Godot. Os fontes editáveis ficam em `art/source/farmer.blend` e `helper.blend`.
As regras existentes são preservadas; o save 9 inclui a rotina completa de lavoura.

## Primeiros passos

1. Dê um nome à sua fazenda e clique em **Escolher meu pedaço de terra**.
2. Clique numa área válida do vale para comprar um terreno de 24 × 24 m por $400.
3. Siga o guia à esquerda e coloque três canteiros. Cada um custa $20 e inclui as primeiras sementes.
4. Escolha **Cuidar** e clique nos canteiros para regar.
5. Use **TAB** para caminhar e deixar o tempo passar. A construção e as janelas pausam a simulação.
6. Colha com **E** perto do canteiro ou use **Cuidar** na câmera aérea.
7. Abra o **Armazém [F]**, venda ou entregue o pedido especial e reinvista.
8. Construa um galinheiro, mantenha ração e água e colete os ovos pelo painel de cuidados.
9. Junte $900 e use **Expandir**. Há duas expansões neste mapa.

## Controles

| Ação | Controle |
|---|---|
| Andar / deslocar câmera aérea | WASD |
| Correr | Shift + WASD |
| Girar câmera | Segurar botão direito e mover mouse |
| Aproximar / afastar | Scroll |
| Alternar caminhada e construção | TAB |
| Construir / selecionar / cuidar | Clique esquerdo |
| Traçar cercas / caminhos | Segurar clique esquerdo e arrastar; soltar para revisar |
| Girar construção | R / Q |
| Mover construção selecionada | M |
| Cuidar de canteiro / editar placa / abrir celeiro ou galinheiro próximo | E |
| Armazém da Dona Lúcia | F |
| Encomendas da vizinhança | J |
| Gerenciar o ajudante | H |
| Salvar | F5 |
| Cancelar ferramenta / fechar janela / menu | Esc |
| Ferramentas da barra | 1–8 |

**Pintura:** em construção, use Cuidar para selecionar celeiro, galinheiro, oficina, cerca ou placa;
escolha a parte e depois uma das sete cores no painel da direita. Celeiro e galinheiro
têm paredes, telhado e portas independentes; cerca e placa têm a cor principal.
Os acabamentos claros permanecem fixos. Pintura é gratuita.
**Placas:** o editor abre ao construir ou clicar na placa. Até 40 caracteres.
**Remover:** devolve metade do preço da construção selecionada. Se remover um celeiro
deixaria a reserva sem espaço, retire os produtos antes; nenhum produto é apagado.
**Traçados:** cercas e caminhos seguem uma linha reta no eixo predominante do arraste.
O custo e a validade aparecem na prévia. Solte para conferir e confirmar o total.
Esc ou Cancelar abandona sem cobrança. Soltar sobre a interface cancela.
Um traçado inválido não coloca nenhuma peça. Um clique sem arraste coloca uma peça
após confirmação, respeitando R/Q. Nos traçados, cercas giram conforme a direção.
**Replantar:** selecione a semente e interaja com um canteiro vazio.
**Mover:** selecione uma estrutura com Cuidar, pressione M ou use o painel. Escolha
o destino, gire com R/Q e confirme com clique. Esc cancela. Não há custo e nada é
removido antes da confirmação. Textos, cores e plantações permanecem intactos.
**Marcadores:** azul significa regar, dourado significa colher. O destaque indica o alvo atual.
**Guia:** cada objetivo tem um botão que abre a ferramenta ou tela apropriada;
as conquistas permanecem concluídas mesmo depois de colher ou remover estruturas.

## Celeiro e oficina rural

Selecione um celeiro com Cuidar ou pressione E junto à porta para abrir **Estoque do celeiro**.
A entrada abre um painel; ainda não há interior 3D explorável.
Cada celeiro oferece 60 espaços no nível 1 e 120 no nível 2, compartilhados entre todos os celeiros da fazenda.
Guardar transfere todo o produto escolhido que couber; Retirar devolve toda a reserva
daquele produto ao estoque. O estoque comum permanece sem limite neste protótipo.
**Vender estoque não vende a reserva.** Retire produtos antes de entregar pedidos.
Mover ou pintar um celeiro preserva os produtos guardados.

Construa uma **Oficina rural** por $180 usando a tecla 9. Na bancada da oficina, $300 compram o regador melhorado, uma única vez. Regar um canteiro seco
também rega os quatro vizinhos imediatos, em cruz, se estiverem plantados e precisando
de água. Funciona nas duas câmeras, sem atingir diagonais, colher ou replantar por você.
A melhoria é permanente, inclusive depois de remover a oficina. Uma melhoria comprada em versões antigas continua válida.

## Galinhas e cuidados

Cada galinheiro inclui **Maricota, Clotilde e Pipoca**, com plumagens branca, marrom
e escura. Clique numa galinha com Cuidar para identificá-la, ou abra o galinheiro
com E de perto ou pelo botão **Cuidar das galinhas**. Nomes podem ser alterados
individualmente, com até 24 caracteres. Ao selecionar o galinheiro, os nomes
também aparecem sobre as galinhas. As personalidades continuam após renomear.

Ração e água são compartilhadas pelas três galinhas de cada galinheiro. A primeira
carga vem incluída. Um comedouro cheio dura 360 segundos de tempo ativo; um
bebedouro dura 300. Repor ração custa de $1 a $8, proporcional ao que falta e
arredondado para cima; água é grátis. O painel mostra o preço antes da ação.
Os modelos de comedouro e bebedouro mostram seu conteúdo, e avisos no cenário
indicam quando estão abaixo de 25%.

| Cuidado do galinheiro | Produção |
|---|---|
| Com água e ração | 2 ovos a cada 45 segundos |
| Sem um dos dois | 2 ovos a cada 90 segundos |
| Sem os dois | 2 ovos a cada 180 segundos |

**As galinhas não morrem.** Repor os suprimentos restaura o ritmo normal.
O ninho guarda até **12 ovos**; cheio, pausa a produção sem acumular uma fila
oculta. Use **Coletar ovos** no painel para transferi-los ao estoque. Ovos no
ninho não são vendidos automaticamente. É preciso coletar antes de remover
o galinheiro. Mover, girar ou pintar preserva nomes, suprimentos e ovos.

Os cuidados e a produção pausam na construção, nas janelas e com o jogo fechado.
Maricota alterna fiscalização do fazendeiro, dança do ovo e reunião por mais
milho. Clotilde gosta de ciscar e Pipoca faz pausas pelo terreiro. Os eventos
são apenas divertidos: não cobram dinheiro, roubam produtos ou exigem resposta.

## Vizinhos e encomendas

No Armazém [F], escolha o produto e a quantidade para vender. O preço total aparece
antes da venda. A reserva do celeiro e os ovos ainda no ninho ficam separados.
Vender todo o estoque continua disponível; confira os pedidos ativos antes.

Abra **Encomendas [J]**, a aba do armazém ou o quadro ao lado da Dona Lúcia (E de
perto; clique na câmera aérea). Dona Nena, Seu Bento e Dona Lola têm três receitas
cada, com especialidades, quantidades, prazo e pagamento visíveis. Aceitar inicia
o prazo, sem reservar ou consumir produtos. É permitido um pedido por vizinho.
A entrega consome todos os produtos necessários de uma vez e paga uma única vez.

Cada entrega dá um ponto de reputação com aquele vizinho. Com 2 pontos você vira
Parceiro; com 5, Preferido. Os pedidos passam a exigir duas e três vezes as
quantidades iniciais, pagando 35% e 45% acima da venda comum, em vez de 25%
(valores arredondados para cima). O pedido já aceito mantém suas condições.
Os prazos são 8, 10 e 12 minutos de tempo ativo, conforme o nível. Construção,
janelas e jogo fechado pausam o relógio. Salvar não reinicia o prazo.

Desistir ou deixar vencer passa à próxima oferta sem perder dinheiro, produtos
ou reputação. O pedido introdutório de seis cenouras por $110 continua sem prazo,
uma única vez, e também rende um ponto com Nena. Partidas antigas que já o
concluíram recebem esse ponto na migração.

## Zeca do Trato — primeiro ajudante

Abra **H** ou use Ajudante no painel do galinheiro. Escolha o galinheiro e confira
os custos antes de confirmar: **$120 para contratar** e **$2 por rodada com serviço**,
mais a ração utilizada (até $8). A água é grátis. Sem tarefa, não há cobrança.

A cada 15 segundos de simulação, Zeca confere um galinheiro escolhido: recolhe
ovos e repõe suprimentos em 25% ou menos. O painel mostra rodadas, ovos e gasto
acumulado, incluindo contratação. A reserva do celeiro e a lavoura ficam intactas.

Pausar congela o trabalho e a contagem do ajudante; as galinhas continuam produzindo
quando o jogo está em caminhada. Retomar continua o intervalo. Trocar de galinheiro
é grátis e reinicia a checagem. Se faltar dinheiro, ele pausa sem executar parte
do serviço: retome explicitamente depois de conseguir saldo. Menus, construção
e jogo fechado pausam toda a simulação e não geram custos.

Dispensar exige confirmação e é grátis, preservando a fazenda e o histórico.
Contratação não é reembolsada; recontratar custa outros $120. Remover o galinheiro
atendido deixa Zeca pausado até escolher outro e retomar. Mover ou girar mantém
a atribuição. O ajudante ocupa um posto junto ao galinheiro; não há navegação
entre tarefas, vários funcionários ou automação da lavoura nesta primeira entrega.

## O que esta versão entrega

- Vale 3D com rio, colinas, árvores e armazém de um vizinho.
- Escolha da posição inicial do terreno e validação de área, saldo e sobreposição.
- Fazendeiro em terceira pessoa com colisões, câmera com zoom e rotação, câmera aérea.
- Canteiros, celeiro, galinheiro, cercas, placas e caminhos.
- Cenoura (32 s), trigo (46 s), milho (62 s); irrigação, crescimento, colheita e replantio.
- Três galinhas identificáveis por cor e nome; água, ração e produção conforme o cuidado.
- Ovos visíveis nos ninhos, coleta manual, nomes editáveis e três eventos da gerente.
- Venda por produto e quantidade, três vizinhos, nove receitas de encomendas e reputação individual.
- Zeca do Trato, com coleta e reposição automáticas em um galinheiro, custos e histórico.
- Pintura, placas, metas, expansão, efeitos sonoros de interação e salvamento local.
- Caminhada articulada, regador com gotas e animação, colheita com produtos e texto flutuante.
- Três estágios visuais das plantações, marcadores, seleção destacada e grade de construção.
- Reposicionamento gratuito e cancelável; capítulo introdutório com oito objetivos persistentes.
- Cercas e caminhos por arraste, orçamento antes de confirmar e colocação integral ou nenhuma.
- Pintura de paredes, telhados e portas; reserva do celeiro e regador que alcança até cinco canteiros.

## Limites assumidos do protótipo

Esta é a versão **0.17.0**, destinada a validar o ciclo de jogo e a direção visual.
O celeiro tem estoque e reserva; a oficina contém a melhoria de ferramenta. Não há interior explorável.
Os traçados são retos, sem curvas ou desenho livre. Preços e tempos aguardam ajuste com partidas reais.
Os cuidados das galinhas são por galinheiro; ainda não há reprodução, doenças,
venda de animais. A 0.14 acrescenta uma vaca por curral.
O comércio tem preços fixos e fica acessível pela interface, além do armazém no mapa.
Os três vizinhos aparecem como perfis e encomendas; ainda não têm ranchos exploráveis nem simulação econômica independente.
O personagem tem animações procedurais de caminhada e ações. As galinhas tentam
desviar localmente de construções e cercas, mas ainda não planejam rotas longas
nem entendem portões; podem parar quando não encontram uma passagem.
A equipe tem duas vagas fixas. Sem multiplayer, vagas livres, tratores dirigíveis, indústrias, clima, estações ou continente.
O jogo não cresce enquanto está fechado. O relógio representa dias de trabalho simplificados.

## Salvamento

Salvamento automático a cada 30 segundos, manual em F5 e ao sair normalmente.
Arquivos em `%APPDATA%/Godot/app_userdata/Do Mato ao Milhão/`:
- `farm_v1.json`: fazenda atual;
- `farm_v1.json.bak`: cópia anterior, usada se o arquivo principal não puder ser lido.

São preservados terreno, estruturas, textos, cores, cultivos, dinheiro, estoque,
relógio e progresso. Ao abrir, o personagem volta a um ponto seguro da propriedade.
Começar outra fazenda exige confirmação no menu e substitui a fazenda atual.
Salvamentos das versões 0.1, 0.2, 0.3, 0.4, 0.5 e 0.6 são aceitos; os objetivos são inferidos a partir das
construções, plantações e conquistas que ficaram registradas. A posição antiga
de uma construção permanece salva se uma mudança de lugar for cancelada.
Reserva, melhoria do regador e cores por parte também são salvas. O nome do arquivo
continua `farm_v1.json`, com formato interno atualizado para 12; a migração preserva
dinheiro, produtos e construções. Galinheiros antigos recebem ração e água cheias,
nomes iniciais e ninho vazio, preservando o progresso de produção e os ovos já
no estoque. Nomes, suprimentos e ovos nos ninhos passam a ser salvos.
Reputação, ofertas e prazos aceitos também são preservados. Ajudante, atribuição, pausa, intervalo e histórico também são salvos. Fazendas antigas iniciam sem funcionário. Após salvar na 0.6, continue usando a 0.6 ou posterior.

## Organização

```text
assets/models/        Modelos GLB usados pelo jogo
art/source/           Modelos Blender editáveis (fora da importação do Godot)
scenes/main.tscn       Cena de entrada
scripts/farm_state.gd Simulação, economia e validação dos dados
scripts/farm_world.gd Cenário, construções e visuais
scripts/farm_hud.gd   Interface em português
scripts/main.gd       Câmeras, personagem, interações e persistência
scripts/farm_progression.gd Níveis, benefícios e custos das construções
tools/build_progression_assets.py Detalhes visuais do nível 2 no Blender
scripts/farm_avatar.gd Animação do personagem e regador
scripts/farm_feedback.gd Efeitos visuais temporários das ações
scripts/farm_staff.gd Rotina, custos e validação do ajudante
scripts/farm_trade.gd Ofertas, reputação, preços e validação do comércio
scripts/farm_staff_motion.gd Rotas locais, acesso ao ninho e gesto de coleta
scripts/farm_animals.gd Necessidades, ritmo de produção e validação dos animais
tests/                Testes da simulação
tools/build_assets.py Gerador reproduzível do kit original no Blender
tools/build_feedback_assets.py Personagem articulado, regador e plantas
tools/build_staff_assets.py Entrada de geração do Zeca
tools/build_cartoon_characters.py Rostos e exportação dos personagens
tools/character_hair.py Cabelo contínuo dos três personagens
tools/build_workshop.py Oficina rural e bancada
tools/character_body.py Corpo contínuo, esqueleto e pesos de deformação
tools/build_chicken.py Galinha cartoon e pivôs das patas
tools/build_trade_assets.py Quadro de encomendas no Blender
tools/build_animal_assets.py Comedouro, bebedouro, ninho e ovo no Blender
DESIGN.md             Direção e recorte da primeira versão
ROADMAP.md            Prioridades e etapas futuras
```

## Recriar os modelos

Execute a partir da raiz do projeto (ajuste o caminho se necessário):

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python tools/build_assets.py
```

Isso recria os `.blend` em `art/source` e os `.glb` em `assets/models`.
Para alterar um modelo manualmente, abra seu `.blend` e exporte GLB para o arquivo correspondente.
O script gerador sobrescreve esses modelos: guarde alterações manuais no Git antes de executá-lo.

## Testes e exportação

Com `godot` apontando para o executável Godot 4.7.2:

```powershell
godot --headless --editor --path . --import
godot --headless --path . --script tests/test_farm_state.gd
godot --headless --path . --script tests/test_v03.gd
godot --headless --path . --script tests/test_v04.gd
godot --headless --path . --script tests/test_v05.gd
godot --headless --path . --script tests/test_v06.gd
godot --headless --path . --script tests/test_v09.gd
godot --headless --path . --script tests/test_v010.gd
godot --headless --path . --script tests/test_v011.gd
godot --headless --path . --script tests/test_crew.gd
New-Item -ItemType Directory -Force test-results
godot --path . --resolution 1440x900 --script tests/render_characters.gd
godot --path . --resolution 1440x900 --fixed-fps 60 --quit-after 12000 -- --qa
godot --path . --resolution 960x640 --script tests/render_staff.gd
New-Item -ItemType Directory -Force exports/windows-v0.17
godot --headless --path . --export-release 'Windows Desktop'
```

O teste de integração usa apenas `qa_farm_v021.json`, nunca o salvamento real.
Valida compra, colocação via controles do jogo, colheita, venda, pintura, texto,
movimento, câmeras, gravação real, leitura e recuperação de backup.
Também verifica movimento/cancelamento de construções, poses do personagem,
rega, colheita, etapas visuais, botões do guia e remoção dos efeitos temporários.
Na 0.3, testa entrada de mouse, confirmação/cancelamento de traçados, soltura sobre a
interface, materiais por parte, reserva, remoção protegida e rega em área. Os testes
da simulação cobrem economia, produção e salvamento. Na 0.4 também são validados nomes, suprimentos,
coleta, migração, limites de produção, cliques em galinhas, pausa, movimentos,
modelos visuais e humor. Na 0.5, verifica vendas digitadas, pedidos, reputação, pausas, vencimento e acesso ao quadro. Na 0.6, também testa contratação, cancelamento, custos, pausa, falta de saldo, seleção, dispensa e persistência do ajudante. Na 0.8, confere os corpos com skin, os 20 ossos, orientação da pose de repouso, rega e pivôs das galinhas. O teste visual precisa terminar com `V017_INTEGRATION_OK`, `V016_INTEGRATION_OK`, `V015_INTEGRATION_OK`, `COW_V015_OK`, `V014_INTEGRATION_OK`, `V013_INTEGRATION_OK`, `V012_INTEGRATION_OK`, `CREW_INTEGRATION_OK`, `V011_INTEGRATION_OK`, `V010_INTEGRATION_OK`, `V09_CHARACTER_OK`, `V06_INTEGRATION_OK`, `V05_INTEGRATION_OK`, `V04_INTEGRATION_OK`,
`V03_INTEGRATION_OK`, `SAVE_OK` e sem `ERROR` no log (não basta o código de saída).
As capturas são geradas em `test-results/` e não entram no Git.
O modo QA só é aceito por compilações de depuração/editor.

Testado inicialmente em Windows com i5-13420H, 16 GB de RAM e RTX 3050 Laptop 6 GB.
O teste breve confirma funcionamento, sem representar um benchmark de fazenda grande.

## Créditos e uso

Projeto de Vitor Girardi. Código e modelos originais criados para este projeto.
Nenhuma licença pública de redistribuição foi concedida para o conteúdo do jogo.
Godot: licença MIT, incluída em `GODOT_LICENSE.txt`; [licenças de terceiros do motor](https://godotengine.org/license/).
Blender é a ferramenta de autoria dos modelos; não precisa estar instalado para jogar.

Teste da lavoura: `godot --headless --path . --script tests/test_v012.gd` (35 verificações).

Teste do curral: `godot --headless --path . --script tests/test_v014.gd` (26 verificações).

Teste isolado de humor e Mimosa: `godot --headless --path . --fixed-fps 60 --quit-after 12000 -- --qa --qa-v015`. Exija `V015_INTEGRATION_OK` e `COW_V015_OK`, sem `ERROR`. Sem `--headless`, também gera capturas de cada animação.

Teste isolado da queijaria: `godot --headless --path . --fixed-fps 60 --quit-after 12000 -- --qa --qa-v016`. Exija `V016_INTEGRATION_OK`, sem `ERROR`. Simulação: `godot --headless --path . --script tests/test_v016.gd --quit-after 120`, com `V016_STATE_OK`.

Teste isolado de Chico: `godot --headless --path . --fixed-fps 60 --quit-after 12000 -- --qa --qa-v017`. Exija `V017_INTEGRATION_OK`, sem `ERROR`. Simulação: `godot --headless --path . --script tests/test_v017.gd --quit-after 120`, com `V017_STATE_OK`. Sem `--headless`, gera capturas da rotina.
