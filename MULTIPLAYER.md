# Cultivo cooperativo — 0.30.0

Multiplayer para plantio, rega e colheita compartilhados: dois jogadores no mesmo mapa, por ENet/UDP. Nome acima do visitante, movimento interpolado, corrida, pulo, danças e reações. Você hospeda sua fazenda e seu amigo visita; não precisa alugar servidor.

## Testar com Vitor e Ian

1. Nos dois PCs, extraia a versão **0.30.0** em pastas novas. Mantenha as versões iguais.
2. No PC de Vitor: menu inicial → **Jogar junto**, digite o nome e escolha **Criar cooperativo da minha fazenda** (primeira vez) ou **Continuar cooperativo**. Se ainda não houver fazenda, o vale inicial é compartilhado. O menu da sessão mostra os endereços do PC.
3. No PC de Ian: **Jogar junto**, digite seu nome, informe o IP local de Vitor e clique em **Entrar na fazenda**. Na mesma rede, costuma ser `192.168.x.x` ou `10.x.x.x`; não use `127.0.0.1` entre computadores.
4. Vitor fecha o painel com **Voltar à fazenda**. Usem **WASD**, **Shift**, **Espaço**, **B** e **M**. Mouse direito gira a câmera. Cada um controla o próprio personagem.
5. **Esc** abre as opções/endereço. **Salvar e encerrar / Sair do cooperativo** retorna ao menu; quem saiu recupera sua fazenda solo. Se o anfitrião fechar o jogo, o visitante recebe aviso e sai da sessão.

Se o Windows perguntar, permita o jogo na rede privada usada por vocês. A porta da sessão é **UDP 28729**. A aplicação não muda o firewall nem o roteador. Wi-Fi de convidados/isolamento entre aparelhos pode bloquear LAN. Se houver vários IPs, use o da mesma rede do outro PC. Porta ocupada mostra erro; feche a outra sessão hospedada.

## De casas diferentes

Conectem os dois computadores numa rede Tailscale autorizada para vocês e usem o IP Tailscale do anfitrião. O plano Personal consultado é gratuito para até seis usuários. Isso evita depender de aluguel de servidor ou configurar encaminhamento no roteador. Nenhuma conta, instalação de VPN ou mudança de rede foi feita automaticamente.

## Cultivar juntos

Aproxime-se de um canteiro e use **E** para plantar, regar ou colher, conforme a indicação na tela. Num canteiro vazio, escolha cenoura, trigo ou milho nos botões de sementes. Os dois podem cuidar dos canteiros; as plantas crescem no computador do anfitrião e são atualizadas para o convidado. Não é preciso esperar o anfitrião fechar o menu para a plantação crescer.

**I** abre o estoque compartilhado; também é possível abri-lo perto do celeiro. A colheita dos dois é somada ao mesmo estoque. Pedidos repetidos, ações distantes e tentativas simultâneas no mesmo canteiro são validados pelo anfitrião para evitar duplicar produção.

## Salvamento e continuidade

Na primeira hospedagem, o jogo copia sua fazenda solo para um cooperativo separado. Depois o botão **Continuar cooperativo** retoma esse progresso, mesmo que você tenha jogado no solo entre as sessões. Prepare canteiros no solo antes de criar seu primeiro cooperativo; construir no multiplayer ainda não está liberado.

No computador anfitrião, o arquivo é `farm_v1_coop.json`, ao lado do save solo, com backup `.bak`. Ações de cultivo confirmadas são gravadas antes de serem reconhecidas; F5, autosave e encerramento também salvam o cooperativo. Se houver falha de gravação, a ação é desfeita; ao tentar sair, a sessão permanece aberta para tentar salvar novamente. Arquivos cooperativos inválidos não são substituídos por uma fazenda nova automaticamente.

O convidado não grava a fazenda compartilhada por cima do seu save. Ao sair, ambos recuperam a fazenda solo que tinham antes de conectar. Dinheiro infinito preservado. O anfitrião precisa permanecer com o jogo aberto.

## Limites desta etapa

Plantio, rega, crescimento, colheita, estoque e salvamento cooperativo estão ativos. Construções, compras/vendas, encomendas, animais, funcionários, armas e montaria ainda não têm ações cooperativas; os controles dessas funções continuam bloqueados. Os sistemas de produção de animais e funcionários não avançam nesta etapa. O solo continua completo. Sem servidor dedicado, migração de anfitrião, senha ou descoberta automática de salas. Use com amigos na rede privada.

## Validação

`tests/run_network.py --godot CAMINHO --test test_coop [--gui]` executa dois processos distintos, com APPDATA/XDG isolados. Testa plantio/regas cruzados, crescimento, duas tentativas de colher o mesmo canteiro, repetição de requisição, distância, estoque idêntico, falha de disco com rollback e retomada do cooperativo. `test_coop_save.gd` testa arquivo separado, backup, recuperação e erro de gravação. `test_network.gd` mantém conexão/movimento/emotes/reconexão. LAN real e desempenho no Omarchy do Ian precisam do teste de vocês.

Fontes:
- https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html
- https://tailscale.com/pricing
