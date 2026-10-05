class_name FarmChapter
extends RefCounted
## Permanent shared chapter progress. The host validates proximity and activity.
const ACTIONS := ["accept", "deliver", "rescue", "return_animal", "repair", "catch_fish"]
const DELIVERY_REWARD := 180
const RESCUE_REWARD := 250
const FISHING_REWARD := 200

static func fresh() -> Dictionary:
	return {"stage":0}

static func valid(data:Variant) -> bool:
	if not data is Dictionary or data.size()!=1:return false
	var stage:Variant=data.get("stage")
	return (stage is int or stage is float) and is_finite(float(stage)) and stage>=0 and stage<=6 and float(stage)==floorf(float(stage))

static func act(state:FarmState, action:String) -> String:
	if not state.claimed:return "Escolha seu terreno antes de ajudar os vizinhos."
	if not valid(state.chapter):return "Progresso do capítulo inválido."
	var stage:=int(state.chapter.stage)
	if stage>=ACTIONS.size():return "Você já concluiu os primeiros laços do vale!"
	if action!=ACTIONS[stage]:return "Siga o objetivo atual do capítulo."
	var reward:=0
	match action:
		"deliver":
			if state.stock("carrot")<6:return "Separe 6 cenouras para Dona Nena."
			state.consume_stock("carrot",6)
			state.trade.nena.reputation+=1
			reward=DELIVERY_REWARD
		"return_animal":reward=RESCUE_REWARD
		"repair":state.resources.rod=true
		"catch_fish":reward=FISHING_REWARD
	state.chapter.stage=stage+1
	state.money+=reward
	state.revenue+=reward
	return ""
