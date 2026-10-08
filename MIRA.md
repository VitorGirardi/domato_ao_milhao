## Câmera livre — 0.61

A exploração agora usa o movimento do mouse sem segurar botão. Toque Alt para alternar entre câmera e cursor; abrir menus libera o cursor e fechar restaura o modo escolhido. Alt+Tab continua disponível sem trocar o modo de construção. Rodinha ajusta a distância. Um ponto discreto indica o centro da visão quando a arma está guardada.

Na construção o cursor permanece livre e o botão direito gira a vista. Com a arma sacada, botão direito mira, esquerdo atira e R recarrega; liberar o cursor com Alt interrompe a mira e permite usar a interface sem disparar.

Em movimento, a câmera acompanha suavemente o carro e o cavalo. Olhar manualmente suspende esse acompanhamento por dois segundos. O cavalo mantém a direção relativa à câmera; o acompanhamento não interfere enquanto houver comando lateral ou de retorno.

Para voltar ao controle anterior, desmarque **Câmera livre** em **Configurações → Jogo e vídeo** e aplique. A preferência é por perfil, sem alterar os saves. Instalações anteriores começam com o novo padrão e preservam sensibilidade e demais configurações.

Validação: `test_free_camera.gd` cobre movimento sem botão, Alt, menus, construção, mira, foco, Alt+Tab, acompanhamento, modo antigo e liberação ao sair; `test_settings.gd` cobre migração e persistência. A mesma integração roda com janela real e em Linux.

# Mira sobre o ombro — 0.43.0

**P** saca ou guarda a pistola. Segure o **botão direito** para aproximar a câmera
sobre o ombro e levantar a arma com as duas mãos. Mova o mouse para mirar e
use o **clique esquerdo** para disparar. **R** recarrega.

Durante a mira, **Q troca o ombro da câmera**. A arma continua na mão direita,
apoiada pela esquerda. Soltar o botão direito devolve suavemente a câmera de
caminhada. Sacar a arma não muda o ângulo normal da câmera. Não há primeira pessoa.

A cruz no centro indica o ponto desejado. O disparo sai do cano: uma parede
entre a pistola e o alvo continua bloqueando o tiro, mesmo que a câmera consiga
enxergar por cima ou ao lado dela. A câmera recua diante de obstáculos.

A pose feita no Blender serve aos dois personagens e aparece para o amigo
no cooperativo, incluindo mira, disparo e recarga. Ambos os PCs devem atualizar
para 0.43.0, protocolo 14. Save 20, dinheiro infinito e queda temporária preservados.

## Conferência no jogo

1. Saque com P; confira que a visão de caminhada continua no mesmo ângulo.
2. Segure direito: o personagem fica ao lado da cruz e segura a arma com as duas mãos.
3. Mire acima e abaixo, ande mirando e pressione Q para conferir os dois ombros.
4. Solte direito, abra menus, guarde a arma ou monte no cavalo: a mira deve terminar.
5. Experimente junto a paredes e confira que o cano não dispara através delas.
6. No cooperativo, confira a pose do amigo nos dois personagens e teste os tiros.
