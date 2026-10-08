# Habilidades pela prática

Abra **Caderno → Habilidades** para acompanhar Pesca, Agricultura, Mineração e Manejo de animais. A evolução é automática; não há pontos para distribuir. Cada fazenda tem seu progresso, compartilhado entre anfitrião e visitante no cooperativo.

## Experiência

| Habilidade | Ação manual concluída | XP |
| --- | --- | --- |
| Pesca | Capturar um peixe | 10 |
| Agricultura | Colher um canteiro ou uma laranjeira | 10 |
| Mineração | Concluir uma extração | 10 |
| Manejo | Cuidar do conforto do cercado | 8 |
| Manejo | Recolher um ovo | 1 |
| Manejo | Recolher um litro de leite | 2 |

Ajudantes não geram experiência. Tentativas, ações canceladas, repetição sem produto e falhas ao salvar não concedem XP. Conforto mantém seu intervalo de oito minutos. As animações e os tempos das ações permanecem iguais.

## Níveis e benefícios

Os cinco níveis começam em **0, 30, 100, 240 e 480 XP**: Iniciante, Aprendiz, Praticante, Experiente e Mestre. O XP continua sendo registrado após o nível máximo.

| Nível | Pesca: chance extra de cada truta/dourado | Agricultura: desconto por semente / produtos extras | Mineração: um minério extra | Manejo: reposição de ração e água no conforto |
| --- | --- | --- | --- | --- |
| 1 | — | — | — | — |
| 2 | +2 pontos percentuais | $1 / 0 | A cada 20 extrações | Até 2 pontos de cada |
| 3 | +4 pontos percentuais | $1 / 1 | A cada 10 extrações | Até 4 pontos de cada |
| 4 | +6 pontos percentuais | $2 / 1 | A cada 7 extrações | Até 6 pontos de cada |
| 5 | +8 pontos percentuais | $2 / 2 | A cada 5 extrações | Até 8 pontos de cada |

A pesca transfere a chance da tilápia para truta e dourado, mantendo as diferenças entre os locais. O desconto vale no replantio manual e nunca reduz o preço abaixo de $1. A colheita extra vale apenas para canteiros; laranjeiras dão XP, mas mantêm a produção. Na mineração, o bônus segue a contagem total de extrações manuais e respeita os limites de estoque. O conforto não ultrapassa 100 pontos de suprimento.

O benefício usa o nível anterior ao XP daquela ação. Subir de nível avisa no jogo e libera a melhoria para as próximas ações.

## Saves e cooperativo

Save **32**, protocolo **30**: atualize ambos os PCs para 0.64.0. O anfitrião calcula, salva e compartilha o progresso. Fazendas antigas Survival/Original começam as novas habilidades no nível 1, preservando dinheiro, inventário, construções e a jornada anterior. Sandbox começa com as quatro habilidades no nível máximo, inclusive em saves antigos. A migração não apaga saves nem backups; versões antigas não devem abrir saves novos.

## Verificação

`tests/test_skills.gd` cobre recompensas, bônus, limites, automação, saves inválidos, migração e Sandbox. `test_skills_ui.gd` verifica a tela e navegação. `test_gathering.gd` cobre cancelamento e reversão ao falhar a gravação. `test_coop_work.gd` confirma que colheitas de ambos os jogadores somam XP compartilhado, com as animações completas.
