class_name FarmResourceSites
extends RefCounted

const FISH_SPOTS := [Vector2(280,295),Vector2(820,-193),Vector2(430,45),Vector2(-42.0+sin(-15.0*.065)*2.6+5.8,-15)]
const FISH_NAMES := ["Lago do Sossego","Lago da Serra","Rio Azul","Riacho da Fazenda"]
const FISH_WATER := [Vector3(280,5,282),Vector3(820,68,-214),Vector3(446,2,45),Vector3(-42.0+sin(-15.0*.065)*2.6,-.1,-15)]
const ORE_SPOTS := [Vector2(898,-224),Vector2(902,-225),Vector2(902,-230),Vector2(882,-247),Vector2(882,-256),Vector2(899,-258),Vector2(918,-268),Vector2(902,-280),Vector2(898,-289)]
const MINE_AT := Vector2(900,-216)

static func point(at:Vector2) -> Vector3:
	return Vector3(at.x,FarmLandscape.height_at(at),at.y)

static func nearby(game:Node3D) -> Dictionary:
	if not game.state.claimed or game.build_mode or game._mounted():return {}
	var at:Vector3=game.player.position
	if game.gathering.jobs.has(game.gathering.own_id()):
		return {"text":"Cancelar atividade","action":"resource","value":"gather:cancel"}
	if game.state.resources.mine_owned:
		for i in range(2):
			if at.distance_to(point(FarmMineLayout.GALLERY_AT[i]))<3:
				return {"text":FarmMineLayout.TITLES[i]+(" · aberta" if game.state.resources.gallery_level>i else " · liberar passagem"),"action":"resource","value":"mine_gallery"}
		for i in range(ORE_SPOTS.size()):
			if Vector2(at.x,at.z).distance_to(ORE_SPOTS[i])<=1.55 and absf(at.y-point(ORE_SPOTS[i]).y)<3:
				var ready:float=maxf(0,float(game.state.resources.node_ready[i])-game.state.elapsed)
				var ore:String=FarmResources.NODE_ORES[i]
				return {"text":("Extrair "+FarmResources.NAMES[ore]) if ready<=0 else "%s · renova em %ds"%[FarmResources.NAMES[ore],ceili(ready)],"action":"resource","value":"gather:mine:%d"%i}
	if at.distance_to(point(MINE_AT))<3:
		return {"text":"Mina da Pedra Clara" if game.state.resources.mine_owned else "Comprar mina · $1500","action":"resource","value":"resources"}
	for i in range(FISH_SPOTS.size()):
		if at.distance_to(point(FISH_SPOTS[i]))<3:
			return {"text":"Pescar · "+FISH_NAMES[i],"action":"resource","value":"gather:fish:%d"%i}
	return {}
