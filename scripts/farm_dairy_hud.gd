class_name FarmDairyHUD
extends RefCounted
static func show(hud:FarmHUD,state:FarmState,index:int) -> void:
	if index<0 or index>=state.items.size() or state.items[index].kind!="corral": return
	hud.building_index=index
	var data:Dictionary=state.items[index].dairy
	var p:=FarmGameUI.open(hud,"dairy","Curral · "+(str(data.name) if data.owned else "Uma nova companhia"),"cow",840,584)
	if not data.owned:
		FarmGameUI.icon(p,"cow",Rect2(315,122,210,175))
		hud.label(p,"Uma vaga esperando pela Mimosa",Vector2(28,317),Vector2(784,36),27).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		hud.label(p,"2 L por minuto com água e ração",Vector2(28,368),Vector2(784,30),21).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var buy:=FarmGameUI.action(hud,p,"Comprar vaca · $480",Rect2(215,459,410,53),"dairy:review",true)
		buy.disabled=state.money<FarmDairy.COW_COST
		hud.label(p,"Saldo: $%d"%state.money,Vector2(28,539),Vector2(784,28),18)
		return
	for i in range(3):
		var c:=FarmGameUI.card(hud,p,Rect2(26+i*268,126,250,302))
		FarmGameUI.icon(c,["milk","wheat","water"][i],Rect2(86,15,78,78))
		hud.label(c,["Leite pronto","Ração","Água"][i],Vector2(14,110),Vector2(222,30),22).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var value:float=float(data.milk)/8 if i==0 else float(data.food if i==1 else data.water)/100
		hud.label(c,"%d / 8 L"%data.milk if i==0 else "%d%%"%roundi(value*100),Vector2(14,153),Vector2(222,38),29).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		FarmGameUI.meter(hud,c,Rect2(20,205,210,15),value,Color("6aaab9") if i!=1 else Color("d4a44d"))
		var cost:=ceili((100-data.food)*.12-0.000001)
		var text:String=("Coletar %d L"%data.milk if data.milk>0 else "Produzindo…") if i==0 else ("Repor · $%d"%cost if i==1 else "Encher · grátis")
		var b:=FarmGameUI.action(hud,c,text,Rect2(14,244,222,44),"dairy:"+["milk","food","water"][i],i==0)
		b.disabled=data.milk==0 if i==0 else (cost==0 or state.money<cost if i==1 else data.water>=100)
	var status:="Leite cheio · colete para produzir mais" if data.milk==8 else ("Reponha água e ração para produzir" if minf(data.food,data.water)<=0 else "Próximos 2 L em %ds"%ceili(60-data.timer))
	hud.label(p,status,Vector2(28,449),Vector2(784,30),22)
	FarmGameUI.action(hud,p,"Estoque de leite · %d L"%state.milk_stock,Rect2(28,511,380,45),"milk_market")
	FarmGameUI.action(hud,p,"Raul · Cuidar do curral",Rect2(430,511,380,45),"raul")
static func confirm(hud:FarmHUD,state:FarmState,index:int) -> void:
	var p:=FarmGameUI.open(hud,"dairy_confirm","Comprar Mimosa","cow",740,414)
	hud.label(p,"$480 · uma vaca para este curral",Vector2(28,125),Vector2(684,40),27)
	hud.label(p,"Água grátis · ração até $12 por reposição\nProduz 2 L por minuto; acumula até 8 L.\nComeça alimentada e com água. Leite vale $18 / L.",Vector2(28,186),Vector2(684,100),20)
	FarmGameUI.action(hud,p,"Voltar",Rect2(28,330,262,48),"dairy:back")
	FarmGameUI.action(hud,p,"Confirmar · $480",Rect2(306,330,406,48),"dairy:buy",true).disabled=state.money<480
static func stock(hud:FarmHUD,state:FarmState) -> void:
	var p:=FarmGameUI.open(hud,"milk_stock","Leite no estoque","milk",740,422)
	FarmGameUI.icon(p,"milk",Rect2(30,128,110,110))
	hud.label(p,"Estoque: %d L"%state.milk_stock,Vector2(163,128),Vector2(546,45),29)
	hud.label(p,"Dona Lúcia compra por $18 / L",Vector2(163,184),Vector2(546,30),21)
	hud.label(p,"Leite coletado · incluído em Vender tudo",Vector2(30,252),Vector2(680,30),18,FarmHUD.MUTED)
	var q:=SpinBox.new(); q.position=Vector2(28,316); q.size=Vector2(126,48)
	q.min_value=1; q.max_value=maxi(1,state.milk_stock); q.value=1; q.step=1; q.rounded=true
	q.update_on_text_changed=true; q.editable=state.milk_stock>0
	p.add_child(q); hud.milk_quantity=q
	var sale:=FarmGameUI.action(hud,p,"Vender 1 L · $18",Rect2(170,316,320,48),"sell_milk",true)
	sale.disabled=state.milk_stock==0
	q.value_changed.connect(func(n:float): sale.text="Vender %d L · $%d"%[int(n),int(n)*18])
	FarmGameUI.action(hud,p,"Armazém",Rect2(506,316,206,48),"market")
