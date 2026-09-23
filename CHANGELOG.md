# 0.32.0 — Noites no vale

Relógio completo de 24 horas, entardecer e amanhecer graduais, luar e 37 postes nas ruas e trilhas. Luzes locais limitadas a seis; horário compartilhado no cooperativo. Saves e economia permanecem preservados. Veja DIA_NOITE.md para horários e mudança do contador antigo de dias.

# 0.31.0 — Fazenda cooperativa

Construção, comércio, animais, equipe e cavalo compartilhados. Comandos validados e persistidos no anfitrião, animação replicada e proteção de seleção após edições concorrentes. Fazendeira selecionável e sincronizada; galinha cisca e vaca mastiga. Save cooperativo da 0.30 continua válido.

# 0.30.0 — Cultivo cooperativo

- Plantio, rega, crescimento e colheita autoritativos no anfitrião; estoque compartilhado.
- Revisões por canteiro e sequências por jogador impedem colheitas duplicadas e pedidos repetidos.
- Save cooperativo separado, backup, retomada e rollback se a gravação falhar.
- E cultivar, I estoque e F5 salvar; protocolo 2, ambos precisam da 0.30.

# 0.29.0 — Visita multiplayer

- Jogar junto: hospedar ou entrar por IP, para dois jogadores.
- Snapshot da fazenda, movimento/corrida/pulo, nomes e emotes sincronizados.
- Saves solo isolados, cancelamento, timeout e reconexão; visita sem produção/construção/montaria.
- HUD específico da visita e preset nativo Linux.

# 0.28.1 — Voz natural do cavalo

- Substitui relincho e bufadas sintéticos por gravações reais CC0, com créditos e fontes preservadas.
- Sprint usa expiração curta; pitch original e volume moderado.
- Mantém gatilhos de montaria, cooldown, áudio espacial e saves da 0.28.

# Versão 0.25.0 — estrebaria e cavalo solto

## 0.28.0 — Montaria e vozes dos animais

- Rédeas chegam às palmas e acompanham a pose montada. Durante o tapinha, a mão esquerda mantém as duas rédeas e a direita alcança o pescoço.
- Relincho ao montar e vocalização no sprint aceito, com fonte acompanhando o cavalo.
- Chamados de galinhas, vacas, pássaros e cavalo com intervalos independentes, proximidade e volume revistos.


## 0.27.0 — O vale ganhou som

- Tema original Manhã no Vale, com 96 segundos, e 23 efeitos/ambientes sintetizados para a fazenda.
- Passos e cascos por distância percorrida, chamados espaciais de animais/pássaros e rio audível conforme proximidade.
- Quatro controles de volume persistentes, abas Som/Jogo e vídeo, transições suaves e limite de vozes simultâneas.
- Câmera recua imediatamente diante de paredes e volta suavemente; mira respeita a sensibilidade escolhida.
- Minimizar/Alt-Tab pausa a partida, interrompe recarga e cancela arrastes sem gastar recursos. Menus já abertos são preservados.
- Testes isolados de mixagem, silêncio das categorias e preservação do estado da fazenda.


## 0.26.0 — Um novo começo

- Cavalo revisado: pescoço contínuo, cabeça/crina novas, pastejo sem afundar o peito e caminhada em quatro tempos.
- Menu inicial com captura real do vale e acesso a Continuar, Novo jogo, Configurações, Controles e Sair.
- Novo jogo com nome, confirmação e arquivo da fazenda anterior; cancelamento preserva a partida.
- Volume, sensibilidade, tela cheia, qualidade gráfica e limite de FPS persistidos em settings.cfg.
- Menu de pausa permite configurar, consultar controles e salvar/voltar à tela inicial.


- Estrebaria original no Blender, construída por $550 a partir do nível 5; entrada aberta, colisões, rotação, mudança de lugar e destino no mapa.
- Cavalo alterna entre observar, pastar e caminhar perto de onde ficou, com limite de 4,5 m, checagem de obstáculos e pausa quando o jogador se aproxima.
- Descanso desmontado recupera 7 pontos de fôlego/s, ou 14 perto da entrada da estrebaria. Sem sistema obrigatório de fome.
- Rédeas acompanham a cabeça ao pastar. Montaria restaura a pose; menus pausam o comportamento.
- Save 17 aceita versões anteriores; dinheiro infinito mantido. Cuidados manuais e evolução ficam para a próxima etapa.

# Versão 0.24.0 — mapa do vale e Pé de Pano

- Minimapa orientado ao norte, jogador, cavalo, bosques, rio, estradas, terrenos e construções.
- Mapa completo com destinos, marcação por clique, distância em metros e limpeza do destino. M andando/montado; mover preservado na construção.
- Cavalo original remodelado no Blender com superfície anatômica contínua e esqueleto de dez ossos; revisão de olhos, focinho e junções.
- Tela cheia/F11 e HUD centralizado da 0.23.2 integrados. Saves16 e dinheiro infinito preservados.

# Alterações

## 0.23.2 — Tela cheia

- Inicia em tela cheia na resolução do monitor. F11 alterna entre tela cheia e janela, inclusive com menus ou campos de texto em foco; a janela recupera sua posição e tamanho dentro da área disponível.
- Cenário preenche a tela sem barras de proporção. HUD mantém escala uniforme, centralização, espaçamentos e cliques corretos em monitores largos ou altos.
- Fundo dos menus cobre toda a tela; retículo continua no centro do disparo. Munição fica abaixo dos alertas da fazenda, sem sobreposição.
- Tela inicial mostra a versão atual e o atalho F11. Saves, mapa, cavalo e armas mantidos.

## 0.23.1 — Damião, P-8 e cavalo juntos

- Damião, armeiro original modelado no Blender: corpo cheio, pele negra, regata clara e expressão séria; bancada e três alvos de treino na estrada oeste.
- P-8 comprável, munição, câmera sobre o ombro, recarga, recuo, som, clarão e alvos com reação. P saca/guarda, mouse direito mira, clique esquerdo dispara e R recarrega.
- Montar guarda a arma imediatamente e cancela a recarga sem perder munição. Disparos e recarga ficam bloqueados durante a montaria.
- Save 16 mantém cavalo, arma e munição; migra as versões anteriores das duas entregas. Dinheiro infinito e mapa/circuito da 0.23 preservados.

## 0.23.0 — Pé de Pano e o circuito do vale

- Cavalo original Blender com sela, rédeas e animação de pernas, cabeça, cauda e cavaleiro.
- E monta/desmonta; WASD cavalga a 8 m/s; toque em Shift anima um tapinha e ativa galope a 14 m/s por 3,5 s, custando 25 de fôlego.
- Fôlego recupera fora do galope; menus pausam movimento e duração do impulso. Desmontagem procura um lugar livre.
- Mapa explorável de 214 × 290 m, mais de duas vezes a área anterior; circuito montado de aproximadamente 490 m.
- Pomar do Sossego, Pedras do Eco e Campina das Flores ampliam o passeio, com placas e descobertas.
- Save 16 migra saves antigos e guarda a posição do cavalo, com validação atômica. Dinheiro infinito mantido.

## 0.22.0 — Caminhos do vale

- Trilhas de terra conectam os terrenos e três paradas, com passagem livre e nove placas de orientação.
- Mirante dos Ventos com moinho animado, Recanto da Prosa com piquenique e Curva da Abóbora com carroça original Blender.
- Vegetação respeita caminhos e paradas; colisões dos marcos também orientam os ajudantes.
- Descobertas exibem uma frase curta ao chegar, uma vez por sessão.
- Dinheiro infinito, saves e margens corrigidas preservados. Cavalo ainda é a próxima etapa.

## 0.21.1 — Margens do rio

- Corrige a borda exposta da água: a superfície agora termina enterrada nas duas margens.
- Refina a malha do leito e das margens, com colisão acompanhando o terreno.
- Mantém correnteza, dinheiro infinito e compatibilidade dos saves.

## 0.21.0 — Terrenos vivos

- Dinheiro infinito permanente no jogo normal, HUD ∞ e regra registrada no AGENTS.md.
- Três lotes de 24 × 24 m compráveis pelo menu T; mapa explorável de 142 × 190 m.
- Aquisição e expansão limpam apenas natureza que interfere na propriedade. Saves antigos preservados no formato 15.
- Capim fino e curvo, distribuição mais densa e renderização por setores.
- Árvores maiores com pássaros originais Blender pousados e animados.
- Correnteza com camadas que se deslocam ao longo das curvas do rio.
- Construção, grade, colisões e rotinas ajustadas aos novos terrenos.

## 0.20.0 — Um vale para explorar

- Substitui o chão quadriculado por gramado, terra e margens com mistura procedural.
- Sete assets originais Blender: duas árvores, arbusto, capim, duas flores e pedras.
- Bosques agrupados, capim com vento, rio animado em leito rebaixado e colinas contínuas.
- Caminhada ampliada para 104 × 128 m, placas de orientação e ponto de descanso.
- Vegetação respeita as construções; piso original permanece plano em toda posição legal de fazenda.
- Retorno da câmera de construção respeita altura e obstáculos do cenário ampliado.
- Save 14 mantido; testes de terreno, colisões, movimento e regressão das rotinas.

## 0.19.0 — A fazenda sobe de nível

- Seis níveis com XP de colheitas, coletas manuais/automáticas e encomendas.
- Galinheiro, celeiro, oficina, curral e queijaria liberados progressivamente; custos mantidos.
- Barra compacta, painel com ícones, cadeados no catálogo e aviso de evolução.
- Save 14: migração reconhece o progresso antigo, sem cobrar nem remover construções.
- Testes de limites, duplicação, ajudantes, bloqueios sem cobrança e persistência.

## 0.18.2 — Correção das mãos

- Substitui a dobra lateral excessiva do punho na Six Seven por rotação axial do antebraço.
- Refaz a base e proporções do polegar na malha compartilhada e fixa sua influência ao osso da mão.
- Regenera os cinco personagens no Blender, mantendo corpo contínuo, esqueleto e piscar.
- Teste de alinhamento dos punhos e revisão aproximada de doze poses em cinco modelos.

## 0.18.1 — Six Seven

- Quarta dança na roda B, com ícone próprio e botão central.
- Movimento alternado das mãos com palmas para cima, usando o rig existente.
- Testes de acionamento, alternância, cancelamento e duração; mantém save 13.

## 0.18.0 — Raul do Curral

- Funcionário para água, ração e ordenha, com atribuição a um curral e orçamento próprio.
- $140 para contratar; $2 por tarefa mais ração, cobrados apenas ao concluir e incluídos no limite.
- Porteira articulada com passagem, posicionamento cooperativo da vaca e trajeto pelo corredor interno.
- Animações de ordenha agachada, transporte, alimentação e água; personagem e saco originais Blender.
- Leite alimenta a cadeia automática do Chico; vendas e encomendas seguem manuais.
- Save 13, pausa, dispensa, renovação e relatórios persistentes.
- Testes de migração, gastos, interrupções, bloqueios, quatro rotações e cadeia vaca–queijo.

## 0.17.0 — Chico Queijeiro

- Contratação, atribuição a uma queijaria, lote e verba de serviços.
- Transporte animado de leite e queijo, preparo, coleta e rondas de espera.
- Taxa de $4 somente ao iniciar lote; coleta grátis, sem venda automática.
- Orçamento com renovação explícita, pausa, dispensa e relatórios preservados.
- Caminhos bloqueados interrompem o trabalho sem cobrança; retomada pelo painel.
- Personagem e acessórios originais Blender, rig articulado e piscar.
- Save 12, migração, remapeamento de atribuição e testes de economia, interface e navegação.

## 0.16.0 — Queijaria do vale

- Queijaria de $900, modelo Blender original, atalho G e interação E.
- Lotes de até quatro queijos: dois litros por unidade, 90 segundos por lote.
- Confirmação de consumo, progresso, coleta e aviso acionável de lote pronto.
- Estoque de queijo, venda parcial por $52 e inclusão na venda geral.
- Encomendas de queijo da Dona Nena, sem prazo, com pagamento e reputação.
- Save 11, migração, preservação ao mover e bloqueio de remoção com produção.
- Testes de produção, duplicação, vendas, pedidos, validação de save e interface.

## 0.15.0 — Resenha no campo

- Roda de emotes em B, três dancinhas e três reações visuais temporárias.
- Cancelamento por movimento, pulo, trabalho, interação e menus.
- Mimosa caminha entre pontos de pastagem, mastiga com pescoço articulado e descansa em pé.
- Cochos e abrigo reposicionados para liberar a circulação; espera pelo jogador no caminho.
- Modelos Blender atualizados, inspeção de poses e testes de controles, limites e pausa.
- Save 10 e regras de produção de leite mantidos. Pastar é uma animação; reponha ração no menu.

## 0.14.0 — Curral e leite

- Curral com uma vaga, compra da Mimosa, ração, água e leite.
- Modelos Blender originais e movimentos procedurais da vaca; colisões nas cercas/cochos.
- Coleta, estoque próprio, venda parcial e venda geral de leite por $18/L.
- Proteção contra compra/coleta duplicada, venda excessiva e remoção do curral ocupado.
- Save 10, migração, preservação ao mover e testes de economia e interação.
- Dancinhas e emojis registrados na fila, antes da queijaria.

## 0.13.0 — Mais fazenda na tela

- HUD compacto na caminhada, objetivo sob demanda e controles discretos.
- Ação contextual compartilha o alvo da tecla E; escolha de sementes somente em canteiro vazio.
- Avisos acionáveis de ninho cheio e ajudantes pausados; menos notificações repetitivas.
- Testes de interações reais, transições dos avisos, pausa de objetivos e alternância de câmeras.
- Save formato 9 preservado.

## 0.12.0 — Menus de jogo e lavoura automática

- Ícones rurais originais, ações curtas, cartões e hierarquia nos menus de interação.
- Galinheiro separa cuidados e animais; celeiro separa disponível e reserva; oficina mostra alcance.
- Mercado simplifica vendas e encomendas; equipe e Zeca recebem o mesmo padrão.
- HUD oculto durante menus e avisos acima das janelas, sem cobrir os títulos.
- Bento rega, colhe e replanta nos canteiros e culturas escolhidos, com animações.
- Limite de gastos inclui sementes e serviço; pausa independente por orçamento ou saldo.
- Renovação explícita, relatório acumulado, migração de saves e proteção contra cobrança parcial.
- 35 novas verificações de estado, integração visual e testes dos fluxos existentes.

## 0.11.0 — Equipe, evolução da fazenda e pulo

- Zeca no galinheiro e Bento na irrigação simultaneamente, com contratação, pausa, gastos e treinamento independentes.
- Bento custa $120. Treinamento por $240 por pessoa reduz serviço de $2 para $1 e acelera o trabalho.
- Dois postos de trabalho nesta primeira equipe; plantio e colheita seguem manuais.
- Migração preserva rotinas antigas sem contratar ninguém automaticamente.

- Espaço pula em caminhada, com pose no ar, aterrissagem e bloqueio de pulo duplo, menus e trabalho.
- Colisões dos telhados acompanham sua altura e inclinação.
- Celeiro, galinheiro e oficina ganham nível 2 com custos, prévia, confirmação e detalhes Blender próprios.
- Reserva de 120 por celeiro melhorado; seis galinhas, 24 ovos no ninho e quatro ovos por ciclo no galinheiro melhorado.
- Galinhas adicionais consomem o dobro de suprimentos; nomes, necessidades e ovos existentes permanecem.
- Oficina equipada libera regador profissional para nove canteiros; requer a melhoria anterior.
- Save 8, migração dos formatos anteriores, reembolso da estrutura evoluída e equipamentos permanentes.
- Testes de cancelamento, custos, capacidade, produção, migração, seis personagens animais e salto real.

## 0.10.0 — Estoque, oficina rural e irrigação

- Cabelo contínuo sobre a cabeça dos três personagens, chapéus ajustados e revisão em quatro ângulos.
- Celeiro abre estoque/reserva por produto pela porta; sem interior 3D nesta etapa.
- Oficina rural modelada no Blender, construção de $180 e bancada de regador transferida para ela.
- Zeca caminha até canteiros selecionados, anima a rega e cobra $2 somente ao concluir.
- Irrigação substitui o trato do galinheiro; pausa por saldo, acesso bloqueado e remoção da última seleção.
- Save 6 com migração dos formatos anteriores, mantendo melhorias já adquiridas.
- Testes de menu, seleção, cobrança única, persistência, remoção, rota bloqueada e troca de rotina sem teleporte.

## 0.9.0 — Trato animado e Dona Lúcia

- Cabelo contido sob a aba dos chapéus; corrigidas as pontas que atravessavam a superfície.
- Regador independente dos eixos do pulso, preso pela alça e inclinado para despejar; gotas no bico real.
- Ronda local do Zeca, planejamento de rotas com obstáculos, ida ao ninho, agachamento e ovo visível.
- Serviço condicionado à chegada ao ninho, sem cobrança quando inacessível; save continua no formato 5.
- Dona Lúcia com GLB/Blender próprios, tranças, brincos e roupa diferente; textos do armazém atualizados.
- Testes de rota, destino bloqueado, cobrança após acesso, pausa e sequência renderizada de coleta.

## 0.8.1 — Zeca corpulento e olhos com piscadas

- Zeca com barriga e tronco mais largos; pesos do corpo separados dos braços pela topologia.
- Olhos menores, íris castanha, pupilas reduzidas e sobrancelhas reposicionadas nos dois modelos.
- Morph Blink exportado no GLB e animado no Godot, com fechamento rápido e reabertura suave.
- Intervalos independentes; Zeca e vendedor piscam mesmo com a simulação pausada.
- Testes de fechamento/reabertura, capturas da piscada e regressão de movimento, cuidados e save.

## 0.8.0 — Corpo conectado e galinhas cartoon

- Malha contínua nos ombros, tronco, braços, mãos, quadril e pernas; anatomia alongada e menos arredondada.
- Protagonista e Zeca com 20 ossos, pesos normalizados e deformação de cotovelos/joelhos.
- Conversão correta das poses de repouso importadas; teste de regressão contra membros invertidos.
- Regador preso ao osso da mão; caminhada, corrida e ações adaptadas ao esqueleto.
- Galinha refeita no Blender: pescoço/peito/asas unidos, penas, olhos e dedos; patas alternadas na caminhada.
- Revisão visual de frente, perfil, pose dobrada e dentro do jogo; fontes Blender e geradores reproduzíveis.
- Salvamento permanece no formato 5, com o QA isolado em qa_farm_v08.json.
- Limites: faces estáticas, sem IK/dedos articulados; asas e pescoço da galinha ainda sem animação própria.

## 0.7.0 — Primeira versão dos personagens cartoon

- Protagonista e Zeca refeitos no Blender com volumes suaves, cabeças grandes e corpos compactos.
- Olhos grandes com reflexos, sobrancelhas, nariz, sorriso curvado e cabelo em mechas volumosas.
- Zeca com corpo mais largo, bigode esculpido e macacão verde; protagonista com roupa azul e luvas.
- Chapéus com abas curvas, alças, botões, bolsos, barras dobradas e botas arredondadas.
- Seis grupos de articulação preservados para caminhada, rega e trabalho; colisão ajustada à altura.
- Gerador compartilhado para os dois modelos, integrado ao processo de recriação dos assets.
- Conceito aprovado guardado separadamente dos modelos; prévias reais dos GLBs geradas pelo Godot.
- Testes de integração de jogo, regador, ajudante e salvamento; formato de save permanece 5.

## 0.6.0 — Uma mãozinha no trato

- Zeca do Trato: primeiro ajudante, com modelo Blender próprio baseado no fazendeiro original.
- Painel H e acesso pelo galinheiro; seleção de um galinheiro por vez e confirmação da contratação.
- Contratação por $120; checagens a cada 15 segundos de simulação, cobrando $2 apenas quando há serviço, mais a ração usada.
- Coleta de ovos e reposição de água/ração em 25% ou menos; água grátis e ração até $8.
- Pausa, retomada, troca de galinheiro grátis e dispensa confirmada; recontratação custa $120.
- Saldo insuficiente interrompe o trabalho sem transação parcial; retomada exige ação do jogador.
- Remover o galinheiro atendido pausa o ajudante; mover a construção preserva a atribuição.
- Histórico de rodadas, ovos e gastos, incluindo contratação, e aviso de serviços no jogo.
- Salvamento no formato 5, lendo formatos 1–4 sem contratar ninguém ou cobrar automaticamente.
- 336 verificações da simulação, testes de interface e persistência; roteiro de teste manual em COMO_TESTAR.md.
- Entrada de mouse dos testes usa coordenadas do viewport para respeitar o redimensionamento da janela.

## 0.5.0 — Negócios com a vizinhança

- Dona Nena, Seu Bento e Dona Lola com especialidades, frases e nove receitas de pedidos.
- Quadro de encomendas original feito no Blender, junto ao armazém; acesso também pela aba e por J.
- Venda por produto e quantidade, com total atualizado durante a digitação.
- Um pedido ativo por vizinho, entrega integral e pagamento único; reserva e ninhos ficam separados.
- Reputação por entrega, níveis em 2 e 5 pontos e pedidos maiores com bônus de 25%, 35% e 45%.
- Prazos de 8, 10 e 12 minutos de simulação, pausados na construção, nas janelas e com o jogo fechado.
- Desistência e vencimento sem multa, perda de estoque ou redução de reputação.
- Formato de salvamento 4, migração dos formatos 1–3 e crédito do pedido introdutório já concluído.
- 258 verificações da simulação, testes das telas, entradas, pausas, prazos e recuperação do backup.

## 0.4.0 — Um quintal cheio de personalidade

- Maricota, Clotilde e Pipoca com nomes editáveis, cores próprias e identificação ao clicar.
- Painel de cuidados acessível pelo galinheiro, por uma galinha ou com E de perto.
- Ração para 360 s e água para 300 s de tempo ativo; primeira carga incluída, reposição de ração até $8 e água grátis.
- Produção de 2 ovos a cada 45, 90 ou 180 s conforme os suprimentos, sem morte dos animais.
- Ninhos com até 12 ovos visíveis; coleta manual, sem duplicação e com remoção do galinheiro protegida.
- Comedouro, bebedouro, ninho e ovo originais criados no Blender, com fontes `.blend` e modelos `.glb`.
- Fiscalização, dança e reunião da Maricota; nomes personalizados usados nas mensagens.
- Clotilde cisca, Pipoca descansa e as galinhas tentam desviar de obstáculos próximos.
- Migração dos formatos 1 e 2 para 3, preservando estoque e progresso de produção anterior.
- 181 verificações da simulação e testes visuais de cuidados, seleção, salvamento e comportamentos.

## 0.3.0 — Sua fazenda, do seu jeito

- Cercas e caminhos por arraste em linha, com prévia, orçamento e confirmação.
- Cancelar, soltar sobre a interface ou rejeitar um traçado não gasta dinheiro nem deixa peças parciais.
- Paredes, telhados e portas pintáveis separadamente em celeiros e galinheiros; sete cores.
- Modelos Blender atualizados com materiais próprios para portas, mantendo os acabamentos.
- Celeiros oferecem 60 espaços de reserva por unidade; produtos guardados ficam fora da venda geral.
- Remoção de celeiro bloqueada quando deixaria produtos sem armazenamento.
- Bancada vende regador melhorado por $300: até cinco canteiros em cruz por ação.
- Migração dos saves 0.1/0.2, persistindo reserva, melhoria e cores no formato interno 2.
- 110 verificações da simulação e testes de integração de mouse, materiais, armazenamento e rega.
- Correção do executor de testes para retornar falha quando alguma verificação falhar.

## 0.2.0 — O cuidado ganha vida

- Caminhada com braços e pernas articulados; personagem se volta para a ação.
- Regador modelado no Blender, gotas, som próprio e breve gesto de rega.
- Produtos saltando e texto flutuante com a quantidade recebida na colheita.
- Brotinhos, plantas jovens verdes e produção madura como etapas visuais distintas.
- Marcadores azuis para rega e dourados para colheita; texto na seleção atual.
- Destaque no chão, seleção de construções pelo corpo/telhado e grade de posicionamento.
- Mover estruturas com M ou pelo painel: prévia, giro, cancelamento e validação.
- Movimento gratuito preserva cores, textos, produção e crescimento.
- Guia de oito objetivos com botões contextuais e progresso persistente.
- Salvamentos da 0.1 continuam aceitos, com inferência dos objetivos observáveis.
- Lista de prioridades em ROADMAP.md para as próximas etapas.

## 0.1.0 — Primeiro terreno

Primeiro protótipo: vale 3D, escolha do terreno, câmeras, construção, plantação,
galinhas, comércio, placas, pintura e salvamento.

