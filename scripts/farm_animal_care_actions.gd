class_name FarmAnimalCareActions
extends RefCounted



static func proximity_error(game:Node3D,command:Dictionary,sender:int=1) -> String:
	var action:Variant=command.get("action","")
	if action!="animal:care" and action not in FarmYoung.ACTIONS:return ""
	var local:bool=not game.network.active or sender==game.multiplayer.get_unique_id()
	var position:Vector3=game.player.position if local else game.network.target
	var airborne:bool=game.actor.airborne if local else game.network.remote_airborne
	var riding:bool=game._mounted() if local else game.network.mounts.rider==sender
	if airborne or riding or (local and (game.actor.swimming or game.pickup.mounted)) or absf(position.y-FarmLandscape.height_at(Vector2(position.x,position.z)))>1.0:
		return "Aproxime-se a pé, no chão, para fazer isso."
	if not local and Time.get_ticks_msec()-game.network.motion_received_at>5000:return "Aguarde a posição do jogador atualizar."
	var index:Variant=command.get("index",-1)
	if not index is int or index<0 or index>=game.state.items.size() or game.state.items[index].kind not in FarmAnimalCare.KINDS:return "Escolha um cercado com animais."
	var item:Dictionary=game.state.items[index]
	var area:Rect2=game.state.item_rect(item.kind,Vector2(item.x,item.z),item.turn)
	var flat:=Vector2(position.x,position.z)
	return "" if flat.distance_to(flat.clamp(area.position,area.end))<=2.65 else "Aproxime-se do cercado para cuidar dos animais."

static func handle(game:Node3D,action:String) -> bool:
	if action=="animal:open":
		FarmAnimalCareHUD.show(game.hud,game.state,game.selected)
		return true
	if action=="animal:back":
		game._tend_selected()
		return true
	if action!="animal:care":return false
	var command:Dictionary=FarmCoopCommands.capture(game,action)
	var error:=proximity_error(game,command)
	var before:Dictionary=game.state.serialize()
	if error.is_empty():error=FarmAnimalCare.care(game.state,game.selected)
	if not error.is_empty():game.hud.toast(error);return true
	if not game._save_game(false,true):
		game.state.restore(before)
		game.hud.toast("Não foi possível salvar. O cuidado foi desfeito.")
		return true
	game.world.update_animals(game.state)
	FarmAnimalCareHUD.show(game.hud,game.state,game.selected)
	game.hud.toast("Cuidado feito! Conforto por 8 minutos de jogo ativo.")
	game._chime()
	game._update_ui()
	return true
