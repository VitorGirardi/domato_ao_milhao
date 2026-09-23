# Linux e Omarchy

Pacote nativo Linux x86_64 (Intel/AMD de 64 bits). Não precisa instalar Godot, Wine ou Proton. Requer driver gráfico com OpenGL 3.3; o jogo usa o renderizador Compatibility.

Extraia o `.tar.gz` e abra um terminal na pasta:

```sh
./jogar.sh
```

Se o gerenciador de arquivos perder as permissões ao copiar:

```sh
chmod +x jogar.sh DoMatoAoMilhao.x86_64
./jogar.sh
```

No Omarchy, teste a sessão gráfica padrão primeiro. Para comparar os dois backends:

```sh
./jogar.sh --display-driver x11
./jogar.sh --display-driver wayland
```

O padrão atual do Godot é X11, que pode funcionar na sessão Wayland por XWayland. O backend nativo Wayland é uma alternativa. Não é necessário mudar a configuração global do Omarchy. F11 alterna janela/tela cheia; o compositor controla posicionamento e tamanho da janela no Wayland.

Saves ficam no diretório de dados do usuário (`${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Do Mato ao Milhão/`). Nunca extraia arquivos QA por cima dos saves. Para um teste sem afetar sua fazenda:

```sh
XDG_DATA_HOME="$PWD/test-results-ian/data" XDG_CONFIG_HOME="$PWD/test-results-ian/config" ./jogar.sh --log-file "$PWD/test-results-ian.log"
```

## Validação

O workflow `Linux compatibility` executa o motor Linux oficial, audita nomes de recursos em filesystem sensível a maiúsculas, testa gameplay/saves, renderiza por X11 e Wayland/Weston com Mesa por software e exporta/executa o binário Linux. As capturas e logs ficam no artefato `linux-validation`; o pacote fica em `DoMatoAoMilhao-Linux-x86_64`.

Esses testes não equivalem a testar Omarchy/Hyprland na GPU do Ian e não comprovam FPS ou áudio físico (CI usa áudio Dummy). No computador dele confirmar: menu, novo jogo/continuar, WASD e mouse, F11, troca de workspace e retorno, volume, cavalo/rédeas, salvar/sair/reabrir. Anotar GPU, versão do Omarchy, backend e escala do monitor se aparecer problema. Multiplayer exige a mesma versão nos dois computadores; sua validação é separada.

Referências: [exportação Linux](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_linux.html), [Wayland/X11 no Godot](https://docs.godotengine.org/en/4.7/tutorials/platform/linux/wayland_x11.html), [Omarchy](https://omarchy.org/).
