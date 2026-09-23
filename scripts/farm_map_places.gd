class_name FarmMapPlaces
extends RefCounted
## A shared, read-only view of the simulation for both maps.
const ICONS={"barn":"barn","coop":"chicken","corral":"cow","pigsty":"pig","stable":"map_horse","workshop":"workshop","cheesery":"cheese"}

static func notices(item:Dictionary) -> String:
	var notes:PackedStringArray=[]
	var data:Dictionary={}
	match item.kind:
		"coop":
			data=item.get("flock",{})
			if data.get("nest",0)>0:notes.append("%d ovos prontos"%data.nest)
		"corral":
			data=item.get("dairy",{})
			if not data.get("owned",false):return ""
			if data.get("milk",0)>0:notes.append("Leite para ordenhar")
		"pigsty":
			data=item.get("pigs",{})
			if data.get("count",0)==0:return ""
		"cheesery":
			if item.get("cheese",{}).get("ready",0)>0:notes.append("Queijo pronto")
	if data.get("water",100)<25:notes.append("Pouca água")
	if data.get("food",100)<25:notes.append("Pouca ração")
	return " • ".join(notes)

static func direction(offset:Vector2) -> String:
	var index:=posmod(roundi(atan2(offset.x,-offset.y)/(PI/4)),8)
	return ["N ↑","NE ↗","L →","SE ↘","S ↓","SO ↙","O ←","NO ↖"][index]
