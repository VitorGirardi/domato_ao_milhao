class_name FarmRosaHUD
extends RefCounted
static func show(game:Node3D) -> void:
	var h:FarmHUD=game.hud;var state:FarmState=game.state
	var p:=FarmGameUI.open(h,"rosa_story","A horta de Dona Rosa","seed",960,660)
	var complete:bool=state.rosa_story.stage==3
	h.label(p,"Amizade floresceu" if complete else FarmRosa.step(state).title,Vector2(26,108),Vector2(908,36),25)
	h.label(p,FarmRosa.quote(state),Vector2(26,160),Vector2(908,90),21).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var card:=FarmGameUI.card(h,p,Rect2(26,272,908,175))
	if complete:
		h.label(card,"Canteiro da amizade liberado em TAB → Jardim.\nA horta está viva graças à sua ajuda.\nOs pedidos comuns continuam disponíveis.",Vector2(18,22),Vector2(872,132),23).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	else:
		var i:=0
		for product in FarmRosa.step(state).cargo:
			h.label(card,"%s · %d   |   Na caçamba: %d"%[FarmResidents.title(product),FarmRosa.step(state).cargo[product],FarmPickupCargo.contents(state).get(product,0)],Vector2(18,16+i*36),Vector2(870,32),21);i+=1
		h.label(card,"$%d + 5 influência · Etapa %d de 3"%[FarmRosa.step(state).pay,int(state.rosa_story.stage)+1],Vector2(18,119),Vector2(870,32),21)
	var hint:="Sem prazo. A caixa na entrada atende mesmo quando Rosa passeia."
	if game.network.active:hint="Esta história está disponível no solo; o progresso da cópia é preservado."
	h.label(p,hint,Vector2(26,468),Vector2(908,54),19).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if not complete:
		var active:bool=state.rosa_story.active
		FarmGameUI.action(h,p,"Entregar ajuda da caçamba" if active else "Combinar ajuda",Rect2(26,540,440,48),"resident:"+("story_deliver" if active else "story_accept")+":rosa",true).disabled=game.network.active or (active and not game.residents_world.truck_ready("rosa"))
	FarmGameUI.action(h,p,"Pedidos da casa",Rect2(482,540,452,48),"resident:talk:rosa")
	FarmGameUI.action(h,p,"Até mais",Rect2(330,608,300,34),"close")
