class_name FarmResidentsHUD
extends RefCounted
static func board(game:Node3D) -> void:
	var h:FarmHUD=game.hud;var state:FarmState=game.state
	var p:=FarmGameUI.open(h,"residents","Vizinhos e entregas","map_pickup",1000,720)
	h.label(p,"Influência no vale · %d  |  Cada entrega rende dinheiro e +5 influência"%FarmResidents.influence(state),Vector2(26,106),Vector2(948,36),20)
	var i:=0
	for key in FarmResidents.PEOPLE:
		var person:Dictionary=FarmResidents.PEOPLE[key];var row:Dictionary=state.residents[key]
		var card:=FarmGameUI.card(h,p,Rect2(26,160+i*145,948,133))
		h.label(card,person.name+" · "+FarmResidents.trust(state,key) if row.met else person.name+" · ainda não conheceu",Vector2(18,12),Vector2(685,31),23)
		var text:String=person.hint
		if row.active:text="Pedido aceito · "+summary(state,key)
		elif row.met:text="Requer %d influência"%person.need if FarmResidents.influence(state)<person.need else "Próxima entrega em %ds"%ceili(maxf(0,row.ready_at-state.elapsed)) if state.elapsed<row.ready_at else "Pedido disponível · visite a casa"
		if key=="rosa" and row.met:text+=" · Horta recuperada" if state.rosa_story.stage==3 else " · Horta: etapa %d/3"%(int(state.rosa_story.stage)+1)
		h.label(card,text,Vector2(18,54),Vector2(660,62),18).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var button:=FarmGameUI.action(h,card,"Marcar casa" if row.known else "Explore o vale",Rect2(710,43,218,46),"resident:mark:"+key)
		button.disabled=not row.known;i+=1
	h.label(p,"As casas entram no mapa quando você chega perto. Pedidos aceitos não vencem.",Vector2(26,604),Vector2(948,30),17)
	if game.network.active:h.label(p,"Entregas de camionetinha são do solo. O progresso desta cópia fica preservado.",Vector2(26,640),Vector2(948,26),16)
	FarmGameUI.action(h,p,"Voltar ao vale",Rect2(350,675,300,36),"close")
static func summary(state:FarmState,key:String) -> String:
	var parts:PackedStringArray=[]
	for product in FarmResidents.order(state,key):parts.append("%d %s"%[FarmResidents.order(state,key)[product],FarmResidents.title(product)])
	return " + ".join(parts)
static func visit(game:Node3D,key:String) -> void:
	var h:FarmHUD=game.hud;var state:FarmState=game.state;var person:Dictionary=FarmResidents.PEOPLE[key];var row:Dictionary=state.residents[key]
	var p:=FarmGameUI.open(h,"resident_"+key,person.name,"barn",960,660)
	h.label(p,FarmRosa.quote(state) if key=="rosa" else person.quote,Vector2(26,110),Vector2(908,48),21).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	h.label(p,"%s · %d entregas · Influência %d"%[FarmResidents.trust(state,key),int(row.done)+(int(state.rosa_story.stage) if key=="rosa" else 0),FarmResidents.influence(state)],Vector2(26,170),Vector2(908,32),19)
	var card:=FarmGameUI.card(h,p,Rect2(26,220,908,192))
	h.label(card,"Pedido aceito · sem prazo" if row.active else "Pedido da casa",Vector2(18,12),Vector2(860,32),23)
	var i:=0
	for product in FarmResidents.order(state,key):
		var wanted:int=FarmResidents.order(state,key)[product];var loaded:=int(FarmPickupCargo.contents(state).get(product,0))
		h.label(card,"%s · %d unidades   |   Na caçamba: %d"%[FarmResidents.title(product),wanted,loaded],Vector2(18,57+i*34),Vector2(860,30),20);i+=1
	h.label(card,"Pagamento $%d  +  5 influência"%FarmResidents.reward(state,key),Vector2(18,144),Vector2(860,30),21)
	var hint:="Carregue com V, estacione na área livre e venha conversar a pé."
	var enabled:=true;var caption:="Entregar da caçamba" if row.active else "Aceitar pedido"
	if game.network.active:hint="As entregas de camionetinha estão disponíveis no solo.";enabled=false
	elif FarmResidents.influence(state)<person.need:hint="Preciso de uma indicação. Ganhe %d influência ajudando os vizinhos."%person.need;enabled=false
	elif not row.active and state.elapsed<row.ready_at:hint="Obrigada pela entrega! Novo pedido em %ds de jogo."%ceili(row.ready_at-state.elapsed);enabled=false
	if row.active and not game.residents_world.truck_ready(key):hint="Estacione a camionetinha perto da casa e venha conversar.";enabled=false
	h.label(p,hint,Vector2(26,438),Vector2(908,65),19).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(h,p,caption,Rect2(26,535,440,50),"resident:"+("deliver:" if row.active else "accept:")+key,true).disabled=not enabled
	FarmGameUI.action(h,p,"Vizinhos e influência",Rect2(482,535,452,50),"residents")
	if key=="rosa":FarmGameUI.action(h,p,"A horta de Dona Rosa",Rect2(26,604,440,36),"resident:story:rosa",true)
	FarmGameUI.action(h,p,"Até mais",Rect2(482 if key=="rosa" else 330,604,300,36),"close")
