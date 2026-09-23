# Porcos na fazenda

O chiqueiro fica disponível no nível 3 por $500. O botão aparece na faixa superior do catálogo de construção. Cada chiqueiro recebe até três porcos: Bolota, Paçoca e Jujuba, comprados por $240 cada com confirmação. Use Cuidar ou E próximo à entrada para abrir o painel.

Os porcos compartilham ração e água. Cada porco consome um reservatório de ração em 600 segundos e de água em 480 segundos de simulação ativa; dois ou três consomem proporcionalmente mais. Repor água é grátis e completar a ração custa até $12. O modo de dinheiro infinito permanece ativo no jogo normal. Construção, menus solo e pausas seguem o controle de tempo existente; no cooperativo o host continua a simulação compartilhada.

Nesta etapa os porcos são animais de companhia e cuidado: não produzem itens, não são vendidos e não morrem sem suprimentos. Essa limitação aparece no painel de compra. Um chiqueiro ocupado pode ser movido e girado, preservando todos os animais e suprimentos, mas não pode ser removido. Um vazio segue a regra normal de reembolso da construção.

O cercado tem colisões, assim como os recipientes, abrigo e porcos visíveis. O portão permanece fechado e os cuidados são feitos de fora. O primeiro porco passeia na faixa livre; os demais farejam a lama e descansam no abrigo. Animais invisíveis não bloqueiam o jogador. A área de circulação é local ao cercado e acompanha a rotação da construção.

## Persistência e cooperativo

- Save de fazenda **18**: novo `item.pigs = {count, food, water}`. Saves anteriores continuam sendo aceitos sem reiniciar a fazenda. Saves 18 não são compatíveis com versões antigas do jogo.
- Protocolo de rede **4**: ambos os jogadores precisam desta atualização. A mudança impede que um cliente antigo ignore silenciosamente a nova construção.
- `FarmPigs` valida estado e executa compra/cuidados. `FarmPigPen` controla apresentação e colisões. `FarmPigHUD` mostra compra/estado/cuidados.
- Comandos `pigs:buy`, `pigs:food`, `pigs:water` passam pela validação, ordenação, limite de repetição e salvamento do host. Falha ao salvar desfaz a compra antes da replicação.
- As três instâncias visuais existem desde a criação do cercado. A compra habilita a correspondente, sem reconstruir a fazenda. `FarmCoopVisuals` transmite transforms e poses sob `pig_<item>_<slot>`; níveis/visibilidade dos suprimentos derivam do snapshot autoritativo.
- Saves de testes são isolados. Não foram usados saves reais do jogador.

## Verificação

```text
godot --path . --audio-driver Dummy --script tests/test_pigs.gd
godot --headless --path . --audio-driver Dummy --script tests/test_pigs.gd
python tests/run_network.py --godot <godot> --test test_coop_pigs --gui
```

O teste de jogo confere custos finitos, limite de compra, cuidados, avanço de tempo, dados inválidos, compatibilidade com save17, movimentação ocupada, persistência, catálogo, painel em duas resoluções e contrato visual. O par real testa construção e compra pelo visitante, cancelamento, repetição de pedido, cuidados, compra pelo host, capacidade, visibilidade e falha de disco com rollback. A CI Linux inclui ambos e os testes cooperativos existentes.

Os modelos são a entrega visual separada descrita em `CHIQUEIRO_VISUAL.md`. Esta implementação depende dela. A configuração de release e a publicação continuam sob coordenação da mainmato.
