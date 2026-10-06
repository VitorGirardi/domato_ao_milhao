class_name FarmBuildActions
extends RefCounted
## Review a specific structure; simulation may continue while the dialog is open.
static func stamp(state:FarmState,index:int) -> String:
	if index<0 or index>=state.items.size():return ""
	var item:Dictionary=state.items[index]
	return str([item.kind,item.x,item.z,item.turn,state.removal_refund(index)])

static func handle(game:Node3D,action:String) -> bool:
	if action not in ["build:sell_review","build:sell_confirm"]:return false
	var menu:FarmBuildHUD=game.hud.construction
	if action=="build:sell_confirm":
		if game.hud.modal_kind!="build_sale":return true
		if game.selected!=menu.review_index or stamp(game.state,game.selected)!=menu.review_stamp:
			game.hud.close_modal();game.hud.toast("A construção mudou. Selecione novamente para vender.");return true
		game.hud.close_modal();game._action("remove");return true
	if not game.build_mode or game.selected<0 or game.selected>=game.state.items.size():return true
	var index:int=game.selected
	var error:String=game.state.removal_error(index)
	if not error.is_empty():game.hud.toast(error);return true
	menu.review_index=index;menu.review_stamp=stamp(game.state,index)
	var item:Dictionary=game.state.items[index]
	var p:=FarmGameUI.open(game.hud,"build_sale","Vender construção?","coins",700,390)
	var explanation:="%s\nVocê recebe $%d: metade do valor da obra e das melhorias.\nA peça será removida do terreno."%[FarmState.ITEMS[item.kind].name,game.state.removal_refund(index)]
	if item.kind=="coop":explanation+="\nAs galinhas deste galinheiro também serão retiradas."
	elif item.kind in ["plot","orchard"]:explanation+="\nO plantio desta peça também será removido."
	var details:Label=game.hud.label(p,explanation,Vector2(28,100),Vector2(644,175),20)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(game.hud,p,"Cancelar",Rect2(28,310,270,48),"close")
	FarmGameUI.action(game.hud,p,"Vender por $%d"%game.state.removal_refund(index),Rect2(316,310,356,48),"build:sell_confirm",true)
	return true
