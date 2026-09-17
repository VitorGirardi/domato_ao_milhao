# Do Mato ao Milhão

**Comece com um terreno. Termine comprando a vizinhança.**

Protótipo jogável de um tycoon de fazenda 3D estilizado para Windows, em português.
Godot 4.7.2 + modelos originais feitos no Blender 5.2.1. Campanha solo e offline.

**Versão atual: 0.7.0.** Veja [as prioridades](ROADMAP.md) e [as novidades](CHANGELOG.md).

Veja o [roteiro de teste manual](COMO_TESTAR.md), incluindo encomendas e vendas da 0.5.

## Jogar

O executável local fica em `exports/windows-v0.7/DoMatoAoMilhao.exe` depois da exportação.
Ele abre diretamente, sem instalar Godot ou Blender. Os binários não são enviados ao Git.

Para executar a partir do código:
1. Abra o Godot 4.7.2, escolha **Importar** e selecione `project.godot`.
2. Aguarde a importação dos modelos.
3. Pressione **F5** para jogar. O cenário é montado pelos scripts durante a execução.

## Personagens cartoon — primeira implementação

A 0.7 traz protagonista e Zeca refeitos no Blender a partir da direção visual
aprovada: cabeça grande, olhos expressivos, sorriso largo e corpo compacto.
Os modelos têm superfícies suaves, chapéus com abas curvas, cabelo volumoso,
bolsos, alças, botões e botas arredondadas. Zeca tem corpo mais largo e bigode.
O vendedor também usa o novo modelo base do fazendeiro.

As seis partes articuladas preservam caminhada, regador e ações de trabalho.
A colisão do personagem acompanha a nova altura. As expressões faciais ainda
são fixas; não há rig facial, roupas trocáveis ou animação de fala. O forcado e
a cesta do conceito são referências de apresentação, não equipamentos permanentes.

O conceito aprovado está em `art/concepts/characters-approved.png`; é uma imagem
ilustrativa. As capturas de `tests/render_characters.gd` mostram os GLBs reais no
Godot. Os fontes editáveis ficam em `art/source/farmer.blend` e `helper.blend`.
O formato de salvamento e as regras da fazenda permanecem os mesmos da 0.6.

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
| Armazém do Seu Tonico | F |
| Encomendas da vizinhança | J |
| Gerenciar o ajudante | H |
| Salvar | F5 |
| Cancelar ferramenta / fechar janela / menu | Esc |
| Ferramentas da barra | 1–8 |

**Pintura:** em construção, use Cuidar para selecionar celeiro, galinheiro, cerca ou placa;
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

## Celeiro e primeira melhoria

Selecione um celeiro com Cuidar ou pressione E de perto para abrir **Reserva e bancada**.
Cada celeiro oferece 60 espaços, compartilhados entre todos os celeiros da fazenda.
Guardar transfere todo o produto escolhido que couber; Retirar devolve toda a reserva
daquele produto ao estoque. O estoque comum permanece sem limite neste protótipo.
**Vender estoque não vende a reserva.** Retire produtos antes de entregar pedidos.
Mover ou pintar um celeiro preserva os produtos guardados.

Na bancada, $300 compram o regador melhorado, uma única vez. Regar um canteiro seco
também rega os quatro vizinhos imediatos, em cruz, se estiverem plantados e precisando
de água. Funciona nas duas câmeras, sem atingir diagonais, colher ou replantar por você.
A melhoria é permanente, inclusive depois de remover o celeiro vazio.

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

Abra **Encomendas [J]**, a aba do armazém ou o quadro ao lado do Seu Tonico (E de
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

Esta é a versão **0.7**, destinada a validar o ciclo de jogo e a direção visual.
O celeiro tem reserva e uma melhoria de ferramenta; não tem interior explorável.
Os traçados são retos, sem curvas ou desenho livre. Preços e tempos aguardam ajuste com partidas reais.
Os cuidados das galinhas são por galinheiro; ainda não há reprodução, doenças,
venda de animais ou outras espécies.
O comércio tem preços fixos e fica acessível pela interface, além do armazém no mapa.
Os três vizinhos aparecem como perfis e encomendas; ainda não têm ranchos exploráveis nem simulação econômica independente.
O personagem tem animações procedurais de caminhada e ações. As galinhas tentam
desviar localmente de construções e cercas, mas ainda não planejam rotas longas
nem entendem portões; podem parar quando não encontram uma passagem.
Sem multiplayer, vários funcionários, tratores dirigíveis, indústrias, clima, estações ou continente.
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
continua `farm_v1.json`, com formato interno atualizado para 5; a migração preserva
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
scripts/farm_avatar.gd Animação do personagem e regador
scripts/farm_feedback.gd Efeitos visuais temporários das ações
scripts/farm_staff.gd Rotina, custos e validação do ajudante
scripts/farm_trade.gd Ofertas, reputação, preços e validação do comércio
scripts/farm_animals.gd Necessidades, ritmo de produção e validação dos animais
tests/                Testes da simulação
tools/build_assets.py Gerador reproduzível do kit original no Blender
tools/build_feedback_assets.py Personagem articulado, regador e plantas
tools/build_staff_assets.py Entrada de geração do Zeca
tools/build_cartoon_characters.py Autor dos dois personagens cartoon e suas articulações
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
godot --path . --resolution 1440x900 --script tests/render_characters.gd
New-Item -ItemType Directory -Force test-results
godot --path . --resolution 1440x900 --fixed-fps 60 --quit-after 2400 -- --qa
New-Item -ItemType Directory -Force exports/windows-v0.7
godot --headless --path . --export-release 'Windows Desktop'
```

O teste de integração usa apenas `qa_farm_v07.json`, nunca o salvamento real.
Valida compra, colocação via controles do jogo, colheita, venda, pintura, texto,
movimento, câmeras, gravação real, leitura e recuperação de backup.
Também verifica movimento/cancelamento de construções, poses do personagem,
rega, colheita, etapas visuais, botões do guia e remoção dos efeitos temporários.
Na 0.3, testa entrada de mouse, confirmação/cancelamento de traçados, soltura sobre a
interface, materiais por parte, reserva, remoção protegida e rega em área. Os testes
da simulação somam 336 verificações. Na 0.4 também são validados nomes, suprimentos,
coleta, migração, limites de produção, cliques em galinhas, pausa, movimentos,
modelos visuais e humor. Na 0.5, verifica vendas digitadas, pedidos, reputação, pausas, vencimento e acesso ao quadro. Na 0.6, também testa contratação, cancelamento, custos, pausa, falta de saldo, seleção, dispensa e persistência do ajudante. Na 0.7, confere os novos modelos, articulações e rega. O teste visual precisa terminar com `V07_CHARACTER_OK`, `V06_INTEGRATION_OK`, `V05_INTEGRATION_OK`, `V04_INTEGRATION_OK`,
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
