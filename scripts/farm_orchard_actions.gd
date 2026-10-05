class_name FarmOrchardActions
extends RefCounted

const MUTATIONS:=["orchard:water","orchard:harvest","orchard:accept","orchard:deliver"]

static func proximity_error(game:Node3D,command:Dictionary,sender:int=1) -> String:
	var action:Variant=command.get("action","")
	if action not in ["orchard:water","orchard:harvest","orchard:deliver"]:return ""
	var local:bool=not game.network.active or sender==game.multiplayer.get_unique_id()
	var position:Vector3=game.player.position if local else game.network.target
	var airborne:bool=game.actor.airborne if local else game.network.remote_airborne
	var riding:bool=game._mounted() if local else game.network.mounts.rider==sender
	if airborne or riding or (local and (game.actor.swimming or game.pickup.mounted)) or absf(position.y-FarmLandscape.height_at(Vector2(position.x,position.z)))>1.0:
		return "Aproxime-se a pé, no chão, para fazer isso."
	if not local and Time.get_ticks_msec()-game.network.motion_received_at>5000:return "Aguarde a posição do jogador atualizar."
	if action=="orchard:deliver":
		if game.falls.is_down("npc:vendor"):return "Aguarde a Lúcia se recuperar."
		return "" if Vector2(position.x,position.z).distance_to(Vector2(-24,14))<5 else "Leve as laranjas até a Lúcia no armazém."
	var index:Variant=command.get("index",-1)
	if not index is int or index<0 or index>=game.state.items.size() or game.state.items[index].kind!="orchard":return "Selecione uma laranjeira produtiva."
	var item:Dictionary=game.state.items[index]
	var area:Rect2=game.state.item_rect("orchard",Vector2(item.x,item.z),item.turn)
	var flat:=Vector2(position.x,position.z)
	return "" if flat.distance_to(flat.clamp(area.position,area.end))<=2.65 else "Aproxime-se da laranjeira para regar ou colher."

static func feedback(game:Node3D,action:String,index:int) -> void:
	if action not in ["orchard:water","orchard:harvest"] or index<0 or index>=game.state.items.size():return
	var item:Dictionary=game.state.items[index]
	var at:=Vector3(item.x,0,item.z)
	var direction:=at-game.player.position
	if direction.length_squared()>.001:game.avatar.rotation.y=atan2(direction.x,direction.z)
	var kind:="water" if action=="orchard:water" else "harvest"
	game.actor.play(kind)
	if kind=="water":game.feedback.water(at,game.avatar.global_transform*Vector3(.47,1.1,1),false,"Regado!",game.actor.can)
	else:game.feedback.floating_text(at,"+6 laranjas",Color("ffce72"))
	game._chime(kind)
