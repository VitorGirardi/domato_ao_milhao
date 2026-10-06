class_name FarmOrchardStaffActions
extends RefCounted

const MUTATIONS:=["orchard_staff:apply","orchard_staff:pause","orchard_staff:stop"]

static func handle(game:Node3D,action:String) -> bool:
	if action=="orchard_staff:open":
		FarmOrchardStaffHUD.show(game.hud,game.state)
		return true
	if action not in MUTATIONS:return false
	var before:Dictionary=game.state.serialize()
	var command:Dictionary=FarmCoopCommands.capture(game,action)
	var error:=FarmCoopCommands.run(game.state,command)
	if not error.is_empty():
		game.hud.toast(error)
		return true
	if not game._save_game(false,true):
		game.state.restore(before)
		game.world.update_staff(game.state,0)
		game.hud.toast("Não foi possível salvar. A rotina e a contratação foram desfeitas.")
		return true
	game.world.update_staff(game.state,0)
	FarmOrchardStaffHUD.show(game.hud,game.state)
	game.hud.toast("Rotina do pomar atualizada. Feche o painel para acompanhar o Zeca.")
	game._update_ui()
	return true
