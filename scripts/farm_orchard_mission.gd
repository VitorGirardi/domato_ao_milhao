class_name FarmOrchardMission
extends RefCounted
## Lúcia receives this permanent order for the bakery. No deadline.

static func show(hud:FarmHUD,state:FarmState) -> void:
	var stage:=int(state.orchard_journey.stage)
	var harvested:=mini(6,int(state.orchard_journey.harvested))
	var p:=FarmGameUI.open(hud,"orchard_mission","Primeira colheita · Dona Lúcia","orange",860,684)
	hud.label(p,"A padaria da Nena quer laranjas frescas do seu pomar!",Vector2(26,112),Vector2(808,32),23)
	hud.label(p,"Lúcia recebe a encomenda no armazém. Sem prazo para entregar.",Vector2(26,150),Vector2(808,30),18,FarmHUD.MUTED)
	var steps:=["Aceite e plante uma laranjeira produtiva em Lavoura.","Regue a árvore e acompanhe o crescimento na sua fazenda.","Colha 6 laranjas após aceitar a missão e traga 6 no estoque."]
	for i in range(steps.size()):
		var c:=FarmGameUI.card(hud,p,Rect2(26,198+i*62,808,54))
		hud.label(c,"%d. %s"%[i+1,steps[i]],Vector2(14,12),Vector2(780,30),18)
	var progress:="Aceite para começar a contar sua própria colheita."
	if stage==1:progress="Colhidas: %d / 6   ·   No estoque: %s   ·   Entrega: 6"%[harvested,state.stock_text("orange")]
	if stage==2:progress="Encomenda concluída! Seu pomar continua produzindo."
	hud.label(p,progress,Vector2(26,400),Vector2(808,34),21)
	hud.label(p,"Recompensa: $220 · 30 XP · +1 reputação com Dona Nena",Vector2(26,445),Vector2(808,30),20)
	hud.label(p,"Venda as próximas colheitas por $16 cada ou transporte na caçamba.",Vector2(26,486),Vector2(808,28),17,FarmHUD.MUTED)
	var action:=FarmGameUI.action(hud,p,"Concluída" if stage==2 else ("Entregar 6 laranjas" if stage==1 else "Aceitar encomenda"),Rect2(26,542,392,48),"orchard:deliver" if stage==1 else "orchard:accept",true)
	action.disabled=stage==2 or not state.claimed or (stage==1 and (harvested<6 or state.stock("orange")<6))
	action.tooltip_text="Vá a pé ao armazém da Lúcia para entregar. Descarregue as laranjas da caçamba antes."
	FarmGameUI.action(hud,p,"Marcar armazém no mapa",Rect2(436,542,398,48),"orchard:mark")
	FarmGameUI.action(hud,p,"Voltar ao armazém",Rect2(26,611,808,44),"market")
