class_name FarmStable
extends RefCounted
const REST_RADIUS:=6.0
const RECOVERY:=14.0

static func entrance(item:Dictionary) -> Vector2:
	var offset:=Vector3(0,0,5.2).rotated(Vector3.UP,int(item.turn)*PI/2)
	return Vector2(item.x+offset.x,item.z+offset.z)

static func nearby(state:FarmState,p:Vector2) -> int:
	var best:=-1;var distance:=REST_RADIUS
	for i in range(state.items.size()):
		var item:Dictionary=state.items[i]
		if item.kind!="stable":continue
		var d:=p.distance_to(entrance(item))
		if d<distance:best=i;distance=d
	return best

static func show(hud:FarmHUD,state:FarmState,horse:FarmHorse,index:int) -> void:
	if index<0 or index>=state.items.size() or state.items[index].kind!="stable":return
	var p:=FarmGameUI.open(hud,"stable","Estrebaria · Pé de Pano","barn",730,450)
	var near:=Vector2(horse.position.x,horse.position.z).distance_to(entrance(state.items[index]))<REST_RADIUS
	FarmGameUI.icon(p,"clock",Rect2(32,123,70,70))
	hud.label(p,"Descanso reforçado" if near else "Um cantinho para descansar",Vector2(119,120),Vector2(580,34),25)
	hud.label(p,"Fôlego recupera 2× mais rápido perto da entrada.",Vector2(119,167),Vector2(580,32),18)
	hud.label(p,"Pé de Pano está por aqui." if near else "Traga o cavalo até a entrada e desmonte com E.",Vector2(32,228),Vector2(666,40),21)
	FarmGameUI.meter(hud,p,Rect2(32,286,666,20),horse.stamina/100,Color("77a059"))
	hud.label(p,"Fôlego · %d%%   •   O descanso acontece com o menu fechado"%int(horse.stamina),Vector2(32,315),Vector2(666,30),16)
	FarmGameUI.action(hud,p,"Voltar para o Pé de Pano",Rect2(172,380,386,44),"close",true)
