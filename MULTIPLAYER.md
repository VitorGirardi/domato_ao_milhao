# Visita à fazenda — 0.29.0

Primeiro bloco multiplayer implementado: dois jogadores no mesmo mapa, por ENet/UDP. Nome acima do visitante, movimento interpolado, corrida, pulo, danças e reações. Você hospeda sua fazenda e seu amigo visita; não precisa alugar servidor.

## Testar com Vitor e Ian

1. Nos dois PCs, extraia a versão **0.29.0** em pastas novas. Mantenha as versões iguais.
2. No PC de Vitor: menu inicial → **Jogar junto**, digite o nome e escolha **Hospedar minha fazenda**. Se ainda não houver fazenda, o vale inicial é compartilhado. O menu da sessão mostra os endereços do PC.
3. No PC de Ian: **Jogar junto**, digite seu nome, informe o IP local de Vitor e clique em **Entrar na fazenda**. Na mesma rede, costuma ser `192.168.x.x` ou `10.x.x.x`; não use `127.0.0.1` entre computadores.
4. Vitor fecha o painel com **Continuar visita**. Usem **WASD**, **Shift**, **Espaço**, **B** e **M**. Mouse direito gira a câmera. Cada um controla o próprio personagem.
5. **Esc** abre as opções/endereço. **Encerrar visita / Sair da visita** retorna ao menu; quem saiu recupera sua fazenda solo. Se o anfitrião fechar o jogo, o visitante recebe aviso e sai da sessão.

Se o Windows perguntar, permita o jogo na rede privada usada por vocês. A porta da sessão é **UDP 28729**. A aplicação não muda o firewall nem o roteador. Wi-Fi de convidados/isolamento entre aparelhos pode bloquear LAN. Se houver vários IPs, use o da mesma rede do outro PC. Porta ocupada mostra erro; feche a outra sessão hospedada.

## De casas diferentes

Conectem os dois computadores numa rede Tailscale autorizada para vocês e usem o IP Tailscale do anfitrião. O plano Personal consultado é gratuito para até seis usuários. Isso evita depender de aluguel de servidor ou configurar encaminhamento no roteador. Nenhuma conta, instalação de VPN ou mudança de rede foi feita automaticamente.

## O que funciona nesta etapa

- Visita para 2 PCs, hospedagem local, entrada por IPv4/IPv6, nomes e personagens.
- Andar, correr, pular, danças e emojis sincronizados; câmera independente e mapa local.
- Entrada tardia, sair, reconectar, cancelamento, erro de conexão e aviso ao anfitrião encerrar.
- Snapshot validado da fazenda do anfitrião. O mundo da visita é uma cópia em memória: **sem escrita nos saves de nenhum jogador**, inclusive autosave e saída do jogo.

## Limites explícitos

É uma visita, não o cooperativo econômico completo: **tempo, produção, funcionários e animais ficam pausados; construir, negociar, plantar, colher, usar arma ou montar no cavalo não estão habilitados durante a visita**. As funções solo continuam normais. Menus e perda de foco param somente o movimento local; a conexão permanece ativa. Sem servidor dedicado, descoberta automática de salas, senha, matchmaking ou migração de anfitrião. Use com amigos na LAN/rede privada, não como servidor público.

A fazenda e a sessão ficam no PC do anfitrião, que deve permanecer com o jogo aberto. Não há custo de hospedagem; energia e conexão são as já usadas pelos computadores.

## Validação e próximo bloco

Testado em dois processos Godot distintos no Windows, tanto headless quanto em duas janelas renderizadas: snapshot, movimento, pulo, emotes, reconexão, encerramento, conexão recusada/tempo limite e arquivos solo intactos. O teste automático usa `tests/run_network.py --godot CAMINHO [--gui]`, com APPDATA/XDG isolados em test-results. Ainda validar LAN real Windows ↔ Omarchy no computador do Ian.

Próxima etapa: colheita e plantio confirmados pelo anfitrião, com inventário compartilhado e proteção contra ações duplicadas. Depois construção, economia, IA dos animais/funcionários e posse exclusiva de montaria. Fazer esse progresso persistir em save cooperativo separado antes de permitir escrita na fazenda principal.

Fontes:
- https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html
- https://tailscale.com/pricing
