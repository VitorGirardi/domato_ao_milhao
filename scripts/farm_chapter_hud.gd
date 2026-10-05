class_name FarmChapterHUD
extends RefCounted

const TITLES := ["Um convite da Nena", "Uma fornada de boas-vindas", "Cadê a Pipoca?", "Devagar com a Pipoca", "Um cantinho para pescar", "A primeira pescaria", "Primeiros laços concluídos"]
const STEPS := [
	"Encontre Dona Nena perto do armazém e converse com ela usando E.",
	"Cultive e colha 6 cenouras. Leve a produção até Dona Nena e entregue com E. Recompensa: $180 e amizade com Nena.",
	"Pipoca escapou! Procure a galinha junto à cerca quebrada e aproxime-se a pé. Use E para libertá-la.",
	"Acompanhe Pipoca até Dona Nena. Ande devagar: ela espera quando você se afasta demais. Com as duas perto, use E. Recompensa: $250.",
	"Vá ao cantinho indicado na margem do Riacho da Fazenda e use E para recuperar o lugar. Você recebe uma vara de pesca.",
	"Aproxime-se da boia do Riacho da Fazenda, use E para pescar e espere a fisgada. Recompensa: $200 e um pesqueiro recuperado para aproveitar.",
	"Nena recebeu a encomenda, Pipoca voltou para casa e o cantinho de pesca está pronto. O banco e a lanterna ficam no vale. Continue cuidando da fazenda e explorando!"
]

static func show(game:Node3D) -> void:
	var stage:int=game.state.chapter.stage
	var hud:FarmHUD=game.hud
	var p:=FarmGameUI.open(hud,"chapter","Primeiros laços · Histórias do vale","book",780,500)
	hud.label(p,TITLES[stage],Vector2(28,115),Vector2(724,44),26)
	var body:=hud.label(p,"",Vector2(28,177),Vector2(724,135),20)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.text=STEPS[stage]
	var progress:String="Encomenda %s    •    Resgate %s    •    Pesqueiro %s"%["✓" if stage>=2 else "○","✓" if stage>=4 else "○","✓" if stage>=6 else "○"]
	hud.label(p,progress,Vector2(28,325),Vector2(724,35),19)
	hud.label(p,"Sem prazo. O progresso fica salvo nesta fazenda.",Vector2(28,371),Vector2(724,28),16,FarmHUD.MUTED)
	FarmGameUI.action(hud,p,"Voltar ao campo",Rect2(28,428,345,46),"close")
	if stage<6:FarmGameUI.action(hud,p,"Marcar próximo destino",Rect2(391,428,361,46),"chapter:mark",true)
