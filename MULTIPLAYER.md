# Fazenda cooperativa — 0.31.0

Dois jogadores por ENet/UDP, sem servidor pago. Os dois usam a **mesma versão 0.31.0**. O anfitrião mantém o jogo aberto e valida as mudanças da fazenda.

## Entrar e jogar
1. Extraia o pacote em uma pasta nova. Windows: `DoMatoAoMilhao.exe`. Linux/Omarchy: `./jogar.sh`.
2. Abra **Jogar junto**, escolha seu nome e personagem. A escolha é local: não altera o personagem do amigo nem exige reiniciar o save.
3. Vitor: **Criar cooperativo da minha fazenda** ou **Continuar cooperativo**. Ian: informe o IP de Vitor e use **Entrar na fazenda**. Porta **UDP 28729**.
4. Feche o painel com **Voltar à fazenda**. WASD anda, Shift corre, Espaço pula, mouse direito gira a câmera. E interage; Tab alterna construção; F abre comércio; H abre equipe; T abre terrenos; I mostra estoque; B abre emotes; M abre mapa; F5 salva no anfitrião; Esc abre opções/sair.

Na mesma rede use o IP local do anfitrião. Em redes diferentes vocês podem usar uma rede privada Tailscale já configurada e seu IP. O jogo não instala VPN nem modifica roteador/firewall.

## O que os dois podem fazer
- Escolher o terreno inicial, construir, girar, mover, remover, pintar, editar placas, traçar cercas/caminhos, comprar terrenos e evoluir construções.
- Plantar, regar e colher; guardar/retirar reservas no celeiro; melhorar ferramentas e configurar irrigação.
- Vender produtos, leite e queijo; aceitar, entregar e cancelar encomendas. Estoque, reputação, nível e evolução são compartilhados.
- Cuidar das galinhas, recolher ovos e dar nomes; comprar/cuidar da vaca e ordenhar; produzir/recolher queijo.
- Contratar, atribuir, treinar, pausar e dispensar a equipe disponível. Configurar rotinas e limites de gastos. A produção acontece somente no anfitrião; o convidado recebe resultados e animações.
- Montar o Pé de Pano, cavalgar, dar o tapinha com Shift e desmontar com E. Há **um cavalo compartilhado**, ocupado por um jogador de cada vez. Desconectar libera o cavalo.

Menus e câmera de construção de um jogador **não pausam a fazenda compartilhada**. Uma edição estrutural invalida seleções antigas para não atingir o prédio errado. Reabra a construção se o outro jogador a modificar. Ações repetidas e colheitas concorrentes são validadas no anfitrião.

## Progresso e segurança do save
O cooperativo usa `farm_v1_coop.json` com `.bak`, separado de `farm_v1.json`. A primeira hospedagem copia a fazenda solo; as próximas continuam o cooperativo. A versão 0.31 retoma o cooperativo da 0.30. Não precisa reiniciar. Fazenda solo, backup e dinheiro infinito são preservados.

As alterações confirmadas são salvas antes da resposta. Uma falha de gravação desfaz a alteração. F5, autosave e saída também salvam. O visitante não grava por cima da própria fazenda solo. Não há migração de anfitrião: quando ele sai, o convidado volta ao menu; o progresso fica no PC anfitrião.

## Limites
Dois jogadores, acesso por IP e um cavalo. Sem servidor dedicado, descoberta automática ou migração de anfitrião. A pistola e treino de tiro continuam apenas no solo; não há combate entre jogadores. O porco é um modelo de prévia, ainda não uma espécie comprável. Jogue com amigos na sua rede privada.

## Testes
`tests/run_network.py --godot CAMINHO --test test_coop_full --gui` executa dois jogos isolados e verifica comércio sem duplicação, animais, contratação, construção, seleções antigas, identidade masculina/feminina, animação replicada, ocupação/movimento/sprint/desmontagem do cavalo, desconexão montado e persistência. Os testes `test_coop`, `test_network`, `test_coop_commands` e `test_coop_save` cobrem cultivo, reconexão, operações de domínio e recuperação de save. CI Linux valida X11, Wayland e o executável exportado. Desempenho e latência nos PCs de Vitor e Ian ainda precisam do teste real.
