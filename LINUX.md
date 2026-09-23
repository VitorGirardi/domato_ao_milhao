# Linux e Omarchy

Pacote nativo Linux x86_64 (Intel/AMD de 64 bits). NÃ£o precisa instalar Godot, Wine ou Proton. Requer driver grÃ¡fico com OpenGL 3.3; o jogo usa o renderizador Compatibility.

Extraia o `.tar.gz` e abra um terminal na pasta:

```sh
./jogar.sh
```

Se o gerenciador de arquivos perder as permissÃµes ao copiar:

```sh
chmod +x jogar.sh DoMatoAoMilhao.x86_64
./jogar.sh
```

No Omarchy, teste a sessÃ£o grÃ¡fica padrÃ£o primeiro. Para comparar os dois backends:

```sh
./jogar.sh --display-driver x11
./jogar.sh --display-driver wayland
```

O padrÃ£o atual do Godot Ã© X11, que pode funcionar na sessÃ£o Wayland por XWayland. O backend nativo Wayland Ã© uma alternativa. NÃ£o Ã© necessÃ¡rio mudar a configuraÃ§Ã£o global do Omarchy. F11 alterna janela/tela cheia; o compositor controla posicionamento e tamanho da janela no Wayland.

Saves ficam no diretÃ³rio de dados do usuÃ¡rio (`${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Do Mato ao MilhÃ£o/`). Nunca extraia arquivos QA por cima dos saves. Para um teste sem afetar sua fazenda:

```sh
XDG_DATA_HOME="$PWD/test-results-ian/data" XDG_CONFIG_HOME="$PWD/test-results-ian/config" ./jogar.sh --log-file "$PWD/test-results-ian.log"
```

## ValidaÃ§Ã£o

O workflow `Linux compatibility` executa o motor Linux oficial, audita nomes de recursos em filesystem sensÃ­vel a maiÃºsculas, testa gameplay/saves, renderiza por X11 e Wayland/Weston com Mesa por software e exporta/executa o binÃ¡rio Linux. As capturas e logs ficam no artefato `linux-validation`; o pacote fica em `DoMatoAoMilhao-Linux-x86_64`.

Esses testes nÃ£o equivalem a testar Omarchy/Hyprland na GPU do Ian e nÃ£o comprovam FPS ou Ã¡udio fÃ­sico (CI usa Ã¡udio Dummy). No computador dele confirmar: menu, novo jogo/continuar, WASD e mouse, F11, troca de workspace e retorno, volume, cavalo/rÃ©deas, salvar/sair/reabrir. Anotar GPU, versÃ£o do Omarchy, backend e escala do monitor se aparecer problema. Multiplayer exige a mesma versÃ£o nos dois computadores; sua validaÃ§Ã£o Ã© separada.

ReferÃªncias: [exportaÃ§Ã£o Linux](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_linux.html), [Wayland/X11 no Godot](https://docs.godotengine.org/en/4.7/tutorials/platform/linux/wayland_x11.html), [Omarchy](https://omarchy.org/).
