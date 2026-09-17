# Alterações

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
