class_name FarmFallTargets
extends RefCounted
## Logical target IDs survive visual rebuilds and item-array compaction.
static func item_key(state:FarmState,index:int,prefix:String,slot:int=-1) -> String:
	var item:Dictionary=state.items[index]
	var key:="%s:%.3f:%.3f"%[prefix,float(item.x),float(item.z)]
	return key+":%d"%slot if slot>=0 else key

static func add(targets:Dictionary,key:String,body:Node3D,model:Node3D,actor:FarmAvatar,kind:String,radius:float,height:float,index:int=-1,include_hidden:bool=false) -> void:
	if not is_instance_valid(body) or not is_instance_valid(model):return
	if not include_hidden and (not body.is_visible_in_tree() or not model.is_visible_in_tree()):return
	targets[key]={"body":body,"model":model,"actor":actor,"kind":kind,"radius":radius,"height":height,"item_index":index}

static func human(targets:Dictionary,key:String,body:Node3D,actor:FarmAvatar) -> void:
	if actor:add(targets,key,body,actor.root,actor,"human",.43,2.58)

static func collect(game:Node3D) -> Dictionary:
	var result:Dictionary={}
	var world:FarmWorld=game.world
	var state:FarmState=game.state
	if world.vendor_actor:human(result,"npc:vendor",world.vendor_actor.root,world.vendor_actor)
	if game.weapons:human(result,"npc:armorer",game.weapons.npc,game.weapons.npc_actor)
	var chapter:Variant=game.get("chapter_world")
	if chapter!=null:
		human(result,"npc:nena",chapter.nena,chapter.nena_actor)
		add(result,"chapter:hen",chapter.hen,chapter.hen,null,"chicken",.32,.85)
	var residents:Variant=game.get("residents_world")
	if residents!=null:
		for key in residents.people:human(result,"resident:"+key,residents.people[key],residents.actors[key])
	human(result,"npc:staff",world.staff_root,world.staff_actor)
	human(result,"npc:field",world.field_root,world.field_actor)
	human(result,"npc:dairy",world.raul_motion.node,world.raul_motion.actor)
	human(result,"npc:cheese",world.chico_motion.node,world.chico_motion.actor)
	if is_instance_valid(game.horse):add(result,"horse",game.horse,game.horse.model,null,"horse",.85,2.6)
	add(result,"cat",world.cat,world.cat.model,null,"cat",.32,.6)
	for chicken in world.chickens:
		add(result,item_key(state,chicken.coop,"chicken",chicken.hen),chicken.node,chicken.node,null,"chicken",.32,.85,chicken.coop)
	for cow in world.cows:
		add(result,item_key(state,cow.index,"cow"),cow.node,cow.node,null,"cow",.85,2.0,cow.index)
	for pen in world.pigsties:
		for pig in pen.pigs:
			add(result,item_key(state,pen.index,"pig",pig.slot),pig.node,pig.node,null,"pig",.6,1.1,pen.index)
	return result
