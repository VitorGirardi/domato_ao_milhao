class_name FarmYoungActions
extends RefCounted

static func handle(game:Node3D,action:String) -> bool:
	if action=="young:open":
		FarmYoungHUD.show(game.hud,game.state,game.selected)
		return true
	if action!="young:adopt":return false
	var command:Dictionary=FarmCoopCommands.capture(game,action)
	var error:=FarmAnimalCareActions.proximity_error(game,command)
	var before:Dictionary=game.state.serialize()
	if error.is_empty():error=FarmYoung.adopt(game.state,game.selected)
	if not error.is_empty():game.hud.toast(error);return true
	if not game._save_game(false,true):
		game.state.restore(before)
		game.hud.toast("Não foi possível salvar. A aquisição foi desfeita.")
		return true
	game.world.rebuild(game.state)
	game.world.update_animals(game.state)
	game.hud.close_modal()
	game.hud.toast("Filhotes acolhidos! Acompanhe o crescimento no cercado.")
	game._chime();game._update_ui()
	return true
