# Vizinhos e entregas — 0.51

Três moradores têm casas permanentes no vale: Dona Rosa, ao norte além do moinho; Seu Bento, na saída leste para a ponte; Lia, pela estrada ao sul do Lago do Sossego. São casas do cenário, com modelos originais da coleção da fazenda, detalhes próprios e espaço para estacionar. Não ocupam terrenos compráveis.

## Como jogar

1. Abra **Entregas · Influência** na lateral esquerda para ler as pistas.
2. Explore: chegar perto descobre a casa e adiciona seu marcador ao mapa.
3. Aproxime-se a pé e aperte **E** para conversar e aceitar o pedido.
4. Use **V** perto da camionetinha parada para carregar os produtos.
5. Estacione entre as marcas perto da casa, saia com **E** e converse com o morador.
6. **Entregar da caçamba** retira somente os produtos pedidos. O restante continua no carro.

Pedidos aceitos não vencem. Cada entrega paga o valor exibido e rende **5 influência**. O pagamento supera a venda simples no armazém, compensando o transporte. A confiança cresce por morador: primeira visita, de confiança e amigo da casa. Os pedidos evoluem por três tamanhos e passam a incluir produtos mais elaborados. Depois de entregar, a casa espera 120 segundos de jogo antes de oferecer outro pedido.

Dona Rosa recebe desde o início. Com 10 influência, Seu Bento aceita encomendas; com 25, Lia aceita. As indicações são anunciadas ao alcançar esses valores. Pode conhecer as casas antes disso e voltar mais tarde. As casas só aparecem no mapa depois da descoberta; **Marcar casa** fecha o painel e orienta o trajeto.

No Sandbox, o estoque continua infinito, mas é preciso carregar fisicamente a caçamba e levar o carro: as entregas consomem a carga finita e contam influência. Survival paga dinheiro real e exige produção ou estoque disponível. Cada fazenda salva descobertas, confiança, pedidos aceitos e espera do próximo pedido. Saves anteriores começam sem progresso de entregas, mantendo todo o restante.

A camionetinha continua solo. No cooperativo, as casas aparecem e a cópia conserva o progresso, mas as ações de entrega ficam desabilitadas; nenhum save solo é alterado. Use a mesma versão nos dois PCs (protocolo 21).

## Validação

- Estado: pagamento atômico, recusa sem carga, sobras, influência, evolução, espera, reenvio sem pagamento duplicado, Sandbox e migração.
- Cena real: acesso de carro às três casas, moradores sobre o terreno, conversa, descoberta/mapa, carro distante/em movimento, falha de disco com reversão e recarregamento.
- Dois processos: progresso replicado, recusa de ações solo no cooperativo, persistência da cópia e preservação dos saves solo.
- Capturas reais Windows e Linux; pacotes exportados e executados. Todos os saves de testes são isolados sob `test-results`.
