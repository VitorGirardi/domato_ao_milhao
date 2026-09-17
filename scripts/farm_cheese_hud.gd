class_name FarmCheeseHUD
extends RefCounted
static func quantity(hud:FarmHUD,p:Control,maximum:int,at:Vector2) -> SpinBox:
	var q:=SpinBox.new();q.position=at;q.size=Vector2(130,48)
	q.min_value=1;q.max_value=maxi(1,maximum);q.step=1;q.rounded=true
	q.update_on_text_changed=true;q.editable=maximum>0;p.add_child(q)
	return q
static func show(hud:FarmHUD,state:FarmState,index:int) -> void:
	if index<0 or index>=state.items.size() or state.items[index].kind!="cheesery": return
	hud.building_index=index
	var data:Dictionary=state.items[index].cheese
	var p:=FarmGameUI.open(hud,"cheesery","Queijaria","cheese",820,640)
	var labels:Array[Label]=[]
	var shown:=maxi(1,maxi(data.batch,data.ready))
	for i in range(3):
		FarmGameUI.icon(p,["milk","clock","cheese"][i],Rect2(112+i*252,124,90,90))
		var label:=hud.label(p,["%d L de leite"%(shown*2),"90 segundos","%d queijo(s)"%shown][i],Vector2(42+i*252,229),Vector2(230,32),23)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;labels.append(label)
	for x in [270,524]:hud.label(p,"→",Vector2(x,150),Vector2(44,45),34)
	if data.batch>0:
		hud.label(p,"Preparando %d queijo(s) · faltam %ds"%[data.batch,ceili(data.remaining)],Vector2(28,295),Vector2(764,36),26)
		FarmGameUI.meter(hud,p,Rect2(28,353,764,22),1-float(data.remaining)/90,Color("d4a44d"))
		hud.label(p,"Feche o menu para a produção continuar.",Vector2(28,400),Vector2(764,32),21)
	elif data.ready>0:
		hud.label(p,"Seu lote ficou pronto!",Vector2(28,295),Vector2(764,36),27)
		FarmGameUI.action(hud,p,"Recolher %d queijo(s)"%data.ready,Rect2(28,357,764,56),"cheese:collect",true)
	else:
		hud.label(p,"Leite disponível: %d L · até 4 queijos por lote"%state.milk_stock,Vector2(28,295),Vector2(764,35),23)
		var q:=quantity(hud,p,mini(4,state.milk_stock/2),Vector2(28,361))
		hud.cheese_batch=1
		var action:=FarmGameUI.action(hud,p,"Preparar 1 queijo · 2 L",Rect2(178,361,614,50),"cheese:review",true)
		action.disabled=state.milk_stock<2
		q.value_changed.connect(func(n:float): hud.cheese_batch=int(n);labels[0].text="%d L de leite"%(int(n)*2);labels[2].text="%d queijo(s)"%int(n);action.text="Preparar %d queijo(s) · %d L"%[int(n),int(n)*2])
		if state.milk_stock<2:hud.label(p,"Colete leite no curral para começar.",Vector2(28,425),Vector2(764,30),20)
	FarmGameUI.action(hud,p,"Estoque · %d queijos"%state.cheese_stock,Rect2(28,494,368,48),"cheese_market")
	FarmGameUI.action(hud,p,"Encomendas de queijo",Rect2(414,494,378,48),"cheese_orders")
	FarmGameUI.action(hud,p,"Chico Queijeiro · "+("Gerenciar" if state.cheese_worker.hired else "Contratar"),Rect2(28,566,764,45),"chico")
static func review(hud:FarmHUD,state:FarmState) -> void:
	var p:=FarmGameUI.open(hud,"cheese_confirm","Confirmar lote","cheese",740,404)
	var amount:=hud.cheese_batch
	hud.label(p,"%d L de leite → %d queijo(s)"%[amount*2,amount],Vector2(28,130),Vector2(684,42),29)
	hud.label(p,"90 segundos de jogo ativo. Sem taxa extra.\nO leite sai do estoque ao confirmar.",Vector2(28,202),Vector2(684,70),21)
	FarmGameUI.action(hud,p,"Voltar",Rect2(28,321,250,49),"cheese:back")
	FarmGameUI.action(hud,p,"Confirmar produção",Rect2(296,321,416,49),"cheese:start",true).disabled=state.milk_stock<amount*2
static func shop(hud:FarmHUD,state:FarmState) -> void:
	var p:=FarmGameUI.open(hud,"dairy_shop","Leite e queijo · Dona Lúcia","cheese",740,438)
	for i in range(2):
		var c:=FarmGameUI.card(hud,p,Rect2(28+i*352,128,332,270))
		FarmGameUI.icon(c,"milk" if i==0 else "cheese",Rect2(121,20,90,90))
		hud.label(c,"%d L · $18/L"%state.milk_stock if i==0 else "%d queijos · $52/un."%state.cheese_stock,Vector2(18,135),Vector2(296,36),23).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		FarmGameUI.action(hud,c,"Vender leite" if i==0 else "Vender queijo",Rect2(18,204,296,47),"milk_market" if i==0 else "cheese_market",true)
static func stock(hud:FarmHUD,state:FarmState) -> void:
	var p:=FarmGameUI.open(hud,"cheese_stock","Queijos no estoque","cheese",740,480)
	FarmGameUI.icon(p,"cheese",Rect2(28,124,110,110))
	hud.label(p,"%d queijos · $52 cada"%state.cheese_stock,Vector2(165,136),Vector2(547,44),28)
	hud.label(p,"Venda comum para Dona Lúcia",Vector2(165,194),Vector2(547,30),21)
	hud.cheese_quantity=quantity(hud,p,state.cheese_stock,Vector2(28,273))
	var sale:=FarmGameUI.action(hud,p,"Vender 1 · $52",Rect2(178,273,534,49),"cheese:sell",true)
	sale.disabled=state.cheese_stock==0
	hud.cheese_quantity.value_changed.connect(func(n:float): sale.text="Vender %d · $%d"%[int(n),int(n)*52])
	hud.label(p,"Vender tudo também inclui queijos; pedidos não reservam estoque.",Vector2(28,342),Vector2(684,44),17)
	FarmGameUI.action(hud,p,"Encomendas",Rect2(28,410,330,44),"cheese_orders")
	FarmGameUI.action(hud,p,"Armazém",Rect2(377,410,335,44),"market")
static func orders(hud:FarmHUD,state:FarmState) -> void:
	var p:=FarmGameUI.open(hud,"cheese_orders","Queijos para Dona Nena","cheese",740,500)
	var amount:=FarmCheese.order_amount(state)
	FarmGameUI.icon(p,"cheese",Rect2(28,126,110,110))
	hud.label(p,["Tábua para o café","Fornada de pão de queijo","Queijos para a feira"][int(state.cheese_order.cycle)%3],Vector2(163,128),Vector2(549,40),25)
	hud.label(p,"%d / %d queijos disponíveis"%[state.cheese_stock,amount],Vector2(163,188),Vector2(549,36),23)
	hud.label(p,"$%d + 1 reputação com Dona Nena"%(amount*64),Vector2(28,266),Vector2(684,37),27)
	hud.label(p,"Sem prazo. Usa apenas queijos recolhidos. Cancelar não cobra.",Vector2(28,322),Vector2(684,40),18)
	var active:bool=state.cheese_order.active
	var b:=FarmGameUI.action(hud,p,"Entregar · $%d"%(amount*64) if active else "Aceitar encomenda",Rect2(28,405,450,50),"cheese:deliver" if active else "cheese:accept",true)
	b.disabled=state.cheese_stock<amount if active else not state.claimed
	FarmGameUI.action(hud,p,"Cancelar pedido" if active else "Armazém",Rect2(496,405,216,50),"cheese:cancel" if active else "market")
