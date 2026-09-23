# Proposta de cooperativo — ainda não implementado

Primeiro marco: dois PCs, uma fazenda compartilhada. Hospedagem pelo jogador (listen server), sem aluguel. Menu Jogar junto → Hospedar fazenda / Entrar por endereço. Quem hospeda mantém o jogo aberto e o save; ao sair, a sessão termina com aviso ao convidado. O save pessoal do convidado nunca é substituído. Dinheiro infinito permanece.

## Conexão gratuita

Na mesma rede: endereço local do host, ENet/UDP nativo do Godot. Não precisa internet nem conta de hospedagem; o Windows pode pedir liberação do jogo na rede privada.
De casas diferentes: Tailscale Personal entre os dois PCs (plano gratuito para até seis usuários na consulta de 2026-09-23). Não instalar nem abrir portas automaticamente. Convidado usa o IP Tailscale do host. Uma rede de convidados com isolamento ou regras de firewall pode impedir a conexão. Testar em dois computadores de verdade antes de considerar entregue. Servidor dedicado 24 h fica para depois, exigindo um computador sempre ligado ou hospedagem externa.

## Implementação em etapas

1. Sessão e dois personagens: ENetMultiplayerPeer, protocolo/versionamento iguais, nomes, andar/pular/emotes sincronizados, chegada/saída e erro de conexão visíveis. Testes com dois processos isolados e depois dois PCs.
2. Fazenda compartilhada: separar o jogador/câmera locais da simulação em main.gd. FarmState, tempo, inventário, colheita, obras e vendas são confirmados pelo host. Convidado envia intenção com identificador; host valida distância, recursos, posse e duplicatas. Mesmo canteiro/ovo não pode ser coletado duas vezes. Estado inicial e atualizações confiáveis; movimento em canal separado com interpolação.
3. Animais, ajudantes e cavalo: IA executada no host; movimento/ações replicados. Exclusão de posse por cavalo, soltura na desconexão, sem dois cavaleiros no mesmo animal. Sons locais reproduzidos uma vez por evento.
4. Persistência e robustez: arquivo cooperativo separado na primeira versão, snapshots e backup atômicos no host; convidado não grava fazenda recebida por cima da solo. Menus não pausam a simulação compartilhada; desconexão/host sair retorna ao menu com mensagem. Testar atraso, reconexão, duas colheitas concorrentes e salvar/carregar.

A build 0.28.1 contém somente a correção sonora. Esta proposta não habilita multiplayer nem simula servidor na interface.

Fontes consultadas:
- https://docs.godotengine.org/en/4.7/tutorials/networking/high_level_multiplayer.html
- https://tailscale.com/pricing
