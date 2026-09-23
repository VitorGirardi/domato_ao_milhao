# Do Mato ao Milhão — Launcher 1.0

Extraia o launcher uma única vez em uma pasta sua, com permissão de escrita.
Windows: abra **DoMato-Launcher.exe**. Linux/Omarchy: dê permissão de execução
e abra **DoMato-Launcher.x86_64** (`chmod +x DoMato-Launcher.x86_64`).
Não precisa instalar Godot, Go ou Python.

**Instalar e jogar** baixa a última versão estável pública do jogo no GitHub.
Depois use **Jogar** para abrir a versão instalada, inclusive sem internet,
ou **Atualizar e jogar** quando houver novidades. O primeiro uso baixa o jogo;
não reaproveita automaticamente as pastas antigas extraídas manualmente.
Vitor e Ian precisam estar na mesma versão para o multiplayer.

O launcher cria a pasta `jogo` ao seu lado. Mantenha os dois juntos se mover
a instalação. Ele guarda versões completas separadas e troca apenas o registro
da versão ativa após conferir download, SHA-256 e executável. Falhas de conexão,
arquivo corrompido ou encerramento antes da troca preservam a versão ativa.
Não atualiza enquanto um jogo iniciado por este launcher está aberto.
Feche também jogos antigos abertos manualmente antes de atualizar ou jogar.

**Voltar à versão anterior** alterna as duas últimas instalações. O launcher
não reverte saves: um save mais novo pode ser incompatível com jogo mais antigo.
Versões antigas ficam na pasta gerenciada; não há limpeza automática nesta edição.
Durante download ou jogo, feche primeiro a operação/jogo para encerrar o launcher.

Seus saves solo, cooperativo, backups, personagem e opções continuam nos locais
originais do Godot, fora da instalação. O launcher não lê nem escreve esses saves:

- Windows: `%APPDATA%\Godot\app_userdata\Do Mato ao Milhão\`
- Linux: `${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Do Mato ao Milhão/`

O auxiliar embutido é extraído na pasta de dados própria do launcher.
`jogo/game.log` registra a execução mais recente em caso de erro.
Não há login, token embutido, servidor pago ou telemetria. O launcher consulta
somente a release estável pública de `VitorGirardi/domato_ao_milhao` no GitHub.
Limites temporários do GitHub podem impedir consulta/download; jogar instalado
continua disponível. A versão 1.0 atualiza o **jogo**, não o próprio launcher.

## Publicar próximas versões

Use tags estáveis `vMAJOR.MINOR.PATCH`, release marcada como latest e pacotes:

- `DoMatoAoMilhao-Windows-vMAJOR.MINOR.PATCH.zip`
- `DoMatoAoMilhao-Linux-vMAJOR.MINOR.PATCH-x86_64.tar.gz`
- SHA-256 do asset fornecido pelo GitHub; fallback
  `SHA256SUMS-vMAJOR.MINOR.PATCH.txt` com `hash  nome-do-pacote`.

O ZIP pode conter uma pasta raiz; TAR pode ter os arquivos na raiz. Exatamente
um `DoMatoAoMilhao.exe` ou `DoMatoAoMilhao.x86_64` deve estar presente.
Arquivos especiais, links, caminhos absolutos e travessia `..` são recusados.
Publique os dois pacotes antes de tornar a release latest. Não marque uma
release apenas de launcher como latest do jogo; distribua os launchers como
assets adicionais da release existente.

SHA-256 verifica integridade do download, não substitui assinatura de código.
As notas da release são exibidas como texto, nunca executadas.

## Desenvolvimento

`launcher/core`: auxiliar Go sem dependências externas (Windows/Linux x86_64).
`launcher/ui`: janela nativa Godot 4.7.2, com foto do próprio jogo.
Compile os helpers em `launcher/ui/bin` antes de exportar o projeto do launcher.
`go -C launcher/core test ./...` testa instalação, hashes, extração, trava,
rollback, falhas de rede e pacote. Workflow Launcher valida Linux nativo,
download público e abertura/fechamento do jogo, com dados QA isolados.
O projeto principal do jogo não é alterado por esta entrega.
