# Garagem da fazenda — 0.49

Construa em **TAB → Estruturas → Garagem**. Ocupa 8 × 10 metros e custa $700, liberada no nível 4 (280 XP). No Sandbox, pode construir desde o início. Modelo original em `art/source/garage.blend`, reproduzível com `tools/build_garage.py`.

Entre pelo vão aberto com a camionetinha e pare. O botão **Garagem** no painel de direção abre as melhorias. A pé, perto do carro, **V → Garagem** oferece o mesmo menu. Também é possível consultar a garagem selecionando a construção; comprar exige estar perto do carro parado, junto da garagem, no modo caminhada.

| Melhoria | Efeito | Custo no Survival |
| --- | --- | --- |
| Caçamba reforçada | 60 → 120 unidades, duas camadas de caixas e reforços visíveis | $900 + 12 ferro |
| Pneus de roça | Pneus mais largos, encostas até 55° e freio mais forte | $650 + 8 cobre |
| Motor preparado | Aceleração maior, até 79 km/h, entrada de ar no capô | $1.200 + 16 ferro |
| Bagageiro de teto | Acessório visual de madeira e metal | $180 + 3 cobre |

Cada melhoria é permanente e comprada uma única vez. Cinco pinturas e nome de até 24 caracteres não têm custo. O nome aparece no painel e no mapa. Remover a garagem não apaga melhorias nem carga; reconstruir permite personalizar novamente. Nenhuma melhoria permite atravessar paredes ou água profunda.

No Sandbox, dinheiro e materiais permanecem infinitos. Saves anteriores recebem o carro básico, mantendo posição e carga. Cada fazenda conserva sua configuração. A garagem pode ser construída e movida no cooperativo, mas a camionetinha e suas melhorias continuam exclusivas do solo. Use a mesma versão nos dois PCs (protocolo 19).

## Conferência

1. No Survival de nível baixo, confira o bloqueio; no nível 4, construa a garagem.
2. Entre dirigindo, freie e saia do carro dentro do vão. Confira que a posição estacionada permanece ao continuar o save.
3. Tente comprar sem dinheiro ou minério: nada deve ser consumido. Complete os recursos e compre; repetir não deve cobrar de novo.
4. Carregue 120 produtos com a melhoria da caçamba. Salve, continue, descarregue ou venda perto da Lúcia.
5. Confira pintura, nome no mapa e painel, pneus, capô e bagageiro.
6. Tente personalizar longe da garagem, em movimento e no cooperativo: a ação deve ser recusada.
7. Em dois PCs, construa e gire a garagem; ambos devem ver a mesma construção e manter os saves solo intactos.

Testes `test_garage.gd`, `test_coop_garage.gd`, regressões de camionetinha/carga/construção e suítes Linux. Os saves de teste ficam exclusivamente sob `test-results`.
