# Dia e noite — 0.32

O céu, luz solar, luar, neblina e lanternas acompanham o horário da fazenda.
O amanhecer acontece entre 05h30 e 07h30; o fim de tarde começa às 17h,
com noite estabelecida às 20h. Postes acendem e apagam gradualmente.
Há 37 lanternas fixas nas ruas e trilhas, com colisão e base na altura do terreno.
Terrenos compráveis e o centro das vias permanecem livres. A limpeza da
vegetação não remove a iluminação pública.

A noite mantém luz ambiente e luar para permitir trabalho e cavalgada.
Só os seis postes mais próximos usam luz dinâmica, sem sombras adicionais;
os demais conservam a lanterna visível. Os modelos usam instâncias agrupadas.

O relógio agora tem 24 horas: cada hora continua durando 20 segundos de jogo
ativo, totalizando oito minutos por ciclo. O dia muda à meia-noite. O contador
antigo pulava de 19h59 para 08h e contava um dia a cada quatro minutos.
Ao abrir um save anterior, seu tempo acumulado é reinterpretado no relógio
completo; o número de dia exibido pode diminuir. Nenhum tempo, progresso,
inventário ou prazo de encomenda é reescrito para essa mudança visual.

No solo, menus/construção continuam pausando o tempo. No cooperativo, ambos
veem o tempo transmitido pelo anfitrião, mesmo com menus abertos. Não há um
segundo relógio local avançando a economia. O save guarda o horário existente;
reabrir ou entrar no cooperativo restaura a iluminação correspondente.

Para testar: atualize no launcher e clique em Jogar. Observe o pôr do sol a
partir das 17h e os postes do armazém. Às 20h o vale estará noturno; à meia-noite
muda o dia, e às 06h começa a clarear. Partindo de 08h, o pôr do sol começa
após três minutos de jogo ativo. Use a mesma versão nos dois PCs.

QA: test_day_night.gd verifica relógio, passagem pela meia-noite, continuidade
das cores, limite de luzes, persistência e reconstrução sem duplicar postes.
test_coop_night.gd usa dois processos reais e verifica noite, meia-noite,
amanhecer, persistência e retorno ao solo. Saves reais não são usados.
