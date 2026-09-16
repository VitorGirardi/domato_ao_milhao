# Do Mato ao Milhão

**Comece com um terreno. Termine comprando a vizinhança.**

Protótipo jogável de um tycoon de fazenda 3D estilizado para Windows, em português.
Godot 4.7.2 + modelos originais feitos no Blender 5.2.1. Campanha solo e offline.

**Versão atual: 0.3.0.** Veja [as prioridades](ROADMAP.md) e [as novidades](CHANGELOG.md).

## Jogar

O executável local fica em `exports/windows-v0.3/DoMatoAoMilhao.exe` depois da exportação.
Ele abre diretamente, sem instalar Godot ou Blender. Os binários não são enviados ao Git.

Para executar a partir do código:
1. Abra o Godot 4.7.2, escolha **Importar** e selecione `project.godot`.
2. Aguarde a importação dos modelos.
3. Pressione **F5** para jogar. O cenário é montado pelos scripts durante a execução.

## Primeiros passos

1. Dê um nome à sua fazenda e clique em **Escolher meu pedaço de terra**.
2. Clique numa área válida do vale para comprar um terreno de 24 × 24 m por $400.
3. Siga o guia à esquerda e coloque três canteiros. Cada um custa $20 e inclui as primeiras sementes.
4. Escolha **Cuidar** e clique nos canteiros para regar.
5. Use **TAB** para caminhar e deixar o tempo passar. A construção e as janelas pausam a simulação.
6. Colha com **E** perto do canteiro ou use **Cuidar** na câmera aérea.
7. Abra o **Armazém [F]**, venda ou entregue o pedido especial e reinvista.
8. Construa o galinheiro para receber ovos, personalize placas e pinte as construções.
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
| Cuidar de canteiro / editar placa / abrir celeiro próximo | E |
| Armazém do Seu Tonico | F |
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

## O que esta versão entrega

- Vale 3D com rio, colinas, árvores e armazém de um vizinho.
- Escolha da posição inicial do terreno e validação de área, saldo e sobreposição.
- Fazendeiro em terceira pessoa com colisões, câmera com zoom e rotação, câmera aérea.
- Canteiros, celeiro, galinheiro, cercas, placas e caminhos.
- Cenoura (32 s), trigo (46 s), milho (62 s); irrigação, crescimento, colheita e replantio.
- Três galinhas por galinheiro; produção de dois ovos a cada 45 s.
- Maricota ocasionalmente vira a “gerente” e acompanha o jogador por alguns segundos.
- Venda de estoque e um contrato de seis cenouras por $110.
- Pintura, placas, metas, expansão, efeitos sonoros de interação e salvamento local.
- Caminhada articulada, regador com gotas e animação, colheita com produtos e texto flutuante.
- Três estágios visuais das plantações, marcadores, seleção destacada e grade de construção.
- Reposicionamento gratuito e cancelável; capítulo introdutório com oito objetivos persistentes.
- Cercas e caminhos por arraste, orçamento antes de confirmar e colocação integral ou nenhuma.
- Pintura de paredes, telhados e portas; reserva do celeiro e regador que alcança até cinco canteiros.

## Limites assumidos do protótipo

Esta é a versão **0.3**, destinada a validar o ciclo de jogo e a direção visual.
O celeiro tem reserva e uma melhoria de ferramenta; não tem interior explorável.
Os traçados são retos, sem curvas ou desenho livre. Preços e tempos aguardam ajuste com partidas reais.
Ração e água das galinhas estão incluídas;
não há sistema completo de necessidades, criação ou reprodução animal.
O comércio tem preços fixos e fica acessível pela interface, além do armazém no mapa.
Há um único vizinho comerciante, sem simulação econômica independente.
O personagem tem animações procedurais de caminhada e ações; as galinhas ainda não têm navegação com obstáculos.
Sem multiplayer, funcionários, tratores dirigíveis, indústrias, clima, estações ou continente.
O jogo não cresce enquanto está fechado. O relógio representa dias de trabalho simplificados.

## Salvamento

Salvamento automático a cada 30 segundos, manual em F5 e ao sair normalmente.
Arquivos em `%APPDATA%/Godot/app_userdata/Do Mato ao Milhão/`:
- `farm_v1.json`: fazenda atual;
- `farm_v1.json.bak`: cópia anterior, usada se o arquivo principal não puder ser lido.

São preservados terreno, estruturas, textos, cores, cultivos, dinheiro, estoque,
relógio e progresso. Ao abrir, o personagem volta a um ponto seguro da propriedade.
Começar outra fazenda exige confirmação no menu e substitui a fazenda atual.
Salvamentos das versões 0.1 e 0.2 são aceitos; os objetivos são inferidos a partir das
construções, plantações e conquistas que ficaram registradas. A posição antiga
de uma construção permanece salva se uma mudança de lugar for cancelada.
Reserva, melhoria do regador e cores por parte também são salvas. O nome do arquivo
continua `farm_v1.json`, com formato interno atualizado para 2; a migração preserva
dinheiro, produtos e construções. Após salvar na 0.3, continue usando a 0.3 ou posterior.

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
tests/                Testes da simulação
tools/build_assets.py Gerador reproduzível do kit original no Blender
tools/build_feedback_assets.py Personagem articulado, regador e plantas
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
New-Item -ItemType Directory -Force test-results
godot --path . --quit-after 1800 -- --qa
New-Item -ItemType Directory -Force exports/windows-v0.3
godot --headless --path . --export-release 'Windows Desktop'
```

O teste de integração usa apenas `qa_farm_v03.json`, nunca o salvamento real.
Valida compra, colocação via controles do jogo, colheita, venda, pintura, texto,
movimento, câmeras, gravação real, leitura e recuperação de backup.
Também verifica movimento/cancelamento de construções, poses do personagem,
rega, colheita, etapas visuais, botões do guia e remoção dos efeitos temporários.
Na 0.3, testa entrada de mouse, confirmação/cancelamento de traçados, soltura sobre a
interface, materiais por parte, reserva, remoção protegida e rega em área. Os testes
da simulação somam 110 verificações. O teste visual precisa terminar com
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
