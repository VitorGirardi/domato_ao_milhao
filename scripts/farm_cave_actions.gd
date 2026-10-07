class_name FarmCaveActions
extends RefCounted

static func nearby(game:Node3D) -> Dictionary:
	if not game.state.resources.mine_owned:return {}
	for i in range(3):
		if game.state.resources.gallery_level<i:continue
		if game.player.position.distance_to(FarmResourceSites.point(FarmCaveCrew.DENS[i]))<3.5:
			return {"text":FarmCaveCrew.NAMES[i]+" · ajudante da caverna","action":"resource","value":"cave:open:%d"%i}
	return {}

static func proximity_error(game:Node3D,command:Dictionary,sender:int=1) -> String:
	var action:Variant=command.get("action","")
	if not action is String or not action.begins_with("cave:"):return ""
	var parts:PackedStringArray=action.split(":")
	if parts.size()!=3 or parts[2] not in ["0","1","2"]:return "Ajudante desconhecido."
	var local:=sender==1
	var at:Vector3=game.player.position if local else game.network.target
	if not local and Time.get_ticks_msec()-game.network.motion_received_at>5000:return "Aguarde a posição do jogador atualizar."
	if (game._mounted() if local else game.network.mounts.rider==sender):return "Desmonte para conversar."
	return "" if at.distance_to(FarmResourceSites.point(FarmCaveCrew.DENS[int(parts[2])]))<4.5 else "Aproxime-se do abrigo do ajudante."

static func show(game:Node3D,i:int) -> void:
	if i<0 or i>2:return
	var h:FarmHUD=game.hud
	var entry:Dictionary=game.state.cave_crew[i]
	var p:=FarmGameUI.open(h,"cave_helper",FarmCaveCrew.NAMES[i]+" · habitante das profundezas","worker",880,590)
	p.set_meta("helper",i)
	var descriptions:=["Tímido e forte. Suas garras reconhecem o cobre na pedra.","Suas patas extras se firmam na rocha para arrancar ferro.","Não tem olhos. Sente a ametista vibrar através de suas antenas."]
	h.label(p,descriptions[i],Vector2(28,112),Vector2(824,38),20)
	h.label(p,"Produz 1 %s a cada 2 minutos de trabalho ativo."%FarmResources.NAMES[FarmCaveCrew.ORES[i]],Vector2(28,167),Vector2(824,30),21)
	h.label(p,"O minério vai ao estoque da fazenda. Não trabalha com o jogo fechado.",Vector2(28,208),Vector2(824,30),17,FarmHUD.MUTED)
	var status:="Ainda desconfiado: ofereça sua comida favorita e prepare um abrigo."
	if entry.joined:
		status="Pausado" if entry.paused else ("Com fome" if entry.fuel<=0 else ("Trabalhando" if FarmCaveCrew.active(game.state,i) else "Estoque cheio"))
		status+=" · comida: %d min · entregues: %d"%[ceili(entry.fuel/60),entry.produced]
	p.set_meta("cave_status",h.label(p,status,Vector2(28,263),Vector2(824,34),20))
	if not entry.joined:
		var foods:=["cenouras","milhos","queijos"]
		h.label(p,"$%d + %d %s · inclui comida para 10 minutos."%[FarmCaveCrew.COSTS[i],FarmCaveCrew.QUANTITIES[i],foods[i]],Vector2(28,320),Vector2(824,30),20)
		FarmGameUI.action(h,p,"Conquistar confiança e preparar abrigo",Rect2(28,373,824,48),"cave:recruit:%d"%i,true)
	else:
		h.label(p,"Refeição: 5 trigos + 2 ovos = 10 minutos (reserva máxima: 30).",Vector2(28,320),Vector2(824,30),19)
		FarmGameUI.action(h,p,"Levar refeição",Rect2(28,373,400,48),"cave:feed:%d"%i,true)
		FarmGameUI.action(h,p,"Retomar trabalho" if entry.paused else "Deixar descansar",Rect2(452,373,400,48),"cave:pause:%d"%i)
	h.label(p,"A comida vem da sua fazenda. Cada galeria revela um novo aliado.",Vector2(28,462),Vector2(824,30),17,FarmHUD.MUTED)
	FarmGameUI.action(h,p,"Fechar e acompanhar",Rect2(28,526,824,40),"close")

static func handle(game:Node3D,action:String) -> bool:
	if not action.begins_with("cave:"):return false
	var parts:PackedStringArray=action.split(":")
	if parts.size()!=3 or parts[2] not in ["0","1","2"]:return true
	var error:=proximity_error(game,{"action":action})
	if not error.is_empty():game.hud.toast(error);return true
	var i:=int(parts[2])
	if parts[1]=="open":show(game,i);return true
	var before:Dictionary=game.state.serialize()
	error=FarmCaveCrew.run(game.state,action)
	if not error.is_empty():game.hud.toast(error);return true
	if not game._save_game(false,true):
		game.state.restore(before);game.hud.toast("Não foi possível salvar. A mudança foi desfeita.");return true
	show(game,i);game.hud.toast("Combinado! Feche o painel para acompanhar o ajudante.");game._update_ui()
	return true
