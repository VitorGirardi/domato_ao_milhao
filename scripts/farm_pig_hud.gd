class_name FarmPigHUD
extends RefCounted

static func show(hud:FarmHUD,state:FarmState,index:int) -> void:
	if index<0 or index>=state.items.size() or state.items[index].kind!="pigsty":return
	hud.building_index=index
	var data:Dictionary=state.items[index].pigs
	var p:=FarmGameUI.open(hud,"pigsty","Chiqueiro · %d / 3 porcos"%data.count,"pig",840,590)
	for slot in range(3):
		var c:=FarmGameUI.card(hud,p,Rect2(26+slot*268,117,250,145))
		FarmGameUI.icon(c,"pig",Rect2(82,8,85,72)).modulate=Color.WHITE if slot<data.count else Color(1,1,1,.25)
		hud.label(c,FarmPigs.NAMES[slot] if slot<data.count else "Vaga livre",Vector2(10,94),Vector2(230,32),23).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for slot in range(2):
		var c:=FarmGameUI.card(hud,p,Rect2(26+slot*402,276,386,164))
		var level:float=float(data.food if slot==0 else data.water)/100
		hud.label(c,("Ração" if slot==0 else "Água")+" · %d%%"%roundi(level*100),Vector2(18,12),Vector2(350,32),23)
		FarmGameUI.meter(hud,c,Rect2(18,57,350,15),level,Color("d4a44d") if slot==0 else Color("6aaab9"))
		var cost:=FarmPigs.food_cost(data)
		var button:=FarmGameUI.action(hud,c,"Repor · $%d"%cost if slot==0 else "Encher · grátis",Rect2(18,95,350,48),"pigs:food" if slot==0 else "pigs:water")
		button.disabled=data.count==0 or level>=1 or (slot==0 and state.money<cost)
	hud.label(p,FarmPigs.status(data),Vector2(28,451),Vector2(780,32),22)
	var buy:=FarmGameUI.action(hud,p,"Comprar porco · $240" if data.count<3 else "Chiqueiro completo",Rect2(28,499,385,49),"pigs:review",true)
	buy.disabled=data.count>=3 or state.money<FarmPigs.COST
	hud.label(p,"Companhia e cuidado · sem produção\nSaldo: "+hud.money_text(state),Vector2(435,499),Vector2(370,64),18)

static func confirm(hud:FarmHUD,state:FarmState,index:int) -> void:
	if index<0 or index>=state.items.size() or state.items[index].kind!="pigsty":return
	var data:Dictionary=state.items[index].pigs
	if data.count>=3:show(hud,state,index);return
	var p:=FarmGameUI.open(hud,"pig_confirm","Comprar "+FarmPigs.NAMES[int(data.count)],"pig",740,414)
	hud.label(p,"$240 · mais uma companhia no chiqueiro",Vector2(28,125),Vector2(684,40),25)
	hud.label(p,"Até três porcos por chiqueiro. Compartilham ração e água.\nMais porcos consomem os suprimentos mais rápido.\nÁgua grátis · ração até $12. Sem produção nesta etapa.",Vector2(28,184),Vector2(684,100),19)
	FarmGameUI.action(hud,p,"Voltar",Rect2(28,330,262,48),"pigs:back")
	FarmGameUI.action(hud,p,"Confirmar · $240",Rect2(306,330,406,48),"pigs:buy",true).disabled=state.money<FarmPigs.COST
