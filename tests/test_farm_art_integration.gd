extends SceneTree

const NEW_KINDS=["house","fence_painted","gate_rustic","gate_painted","well","wash_tub","raised_bed","trellis","orchard_young","orchard_mature","compost","produce_crates"]

func _initialize() -> void:call_deferred("run")

func fresh(mode:String="sandbox") -> FarmState:
	var state:=FarmState.new_farm(mode)
	assert(state.claim(Vector2(4,0)).is_empty())
	return state

func state_checks() -> void:
	assert(FarmState.ITEMS.barn.size==Vector2(6,6),"Existing barn saves retain their footprint")
	for kind in NEW_KINDS:
		var state:=fresh()
		var before:=state.serialize()
		assert(state.can_place(kind,Vector2(4,0),1).is_empty(),kind)
		assert(state.serialize()==before,"Placement preview mutated state")
		FarmCoopCommands.run(state,{"action":"place","kind":kind,"at":Vector2(4,0),"turn":1,"crop":"carrot"})
		assert(state.items.size()==1 and state.items[0].kind==kind and state.items[0].turn==1,kind)
		assert(state.items[0].paint==-1,"New art must preserve its authored palette")
		assert(not state.items[0].planted,"Decorative garden must not produce invisible crops")
		before=state.serialize()
		assert(not state.place(kind,Vector2(4,0),0).is_empty())
		assert(state.serialize()==before,"Rejected overlap changed state")
		assert(state.move_item(0,Vector2(6,2),3).is_empty())
		if kind=="house":
			FarmCoopCommands.run(state,{"action":"evolution_buy:0","index":0})
			assert(FarmProgression.level(state.items[0])==2)
			assert(not state.upgrade_building(0).is_empty(),"Duplicate upgrade must be rejected")
		var restored:=FarmState.new()
		assert(restored.restore(JSON.parse_string(JSON.stringify(state.serialize()))),kind)
		for key in ["kind","x","z","turn","paint","level"]:
			assert(restored.items[0][key]==state.items[0][key],kind+": "+key)
		assert(restored.infinite_resources() and restored.unlimited_money,kind)
		var survival:=fresh("survival")
		if FarmLevels.required(kind)>1:
			assert(not survival.place(kind,Vector2(4,0),0).is_empty(),"Survival level gate: "+kind)
			survival.farm_xp=10000
		var balance:=survival.money
		assert(survival.place(kind,Vector2(4,0),0).is_empty(),kind)
		assert(survival.money==balance-int(FarmState.ITEMS[kind].cost),"Survival construction cost: "+kind)
		assert(restored.restore(survival.serialize()) and not restored.unlimited_money and not restored.infinite_resources())
	var painted:=fresh()
	assert(painted.place("barn",Vector2(4,0),0).is_empty())
	for part in ["walls","roof","door"]:assert(painted.paint_item(0,part,2).is_empty())
	assert(painted.upgrade_building(0).is_empty())
	var copy:=FarmState.new()
	assert(copy.restore(painted.serialize()) and copy.items[0].paint==2 and copy.items[0].roof_paint==2 and copy.items[0].door_paint==2)

func bounds_of(node:Node3D) -> AABB:
	var result:=AABB()
	var first:=true
	for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		var box:AABB=(node.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		result=box if first else result.merge(box)
		first=false
	assert(not first,"Missing visible art")
	return result

func run() -> void:
	state_checks()
	var world:=FarmWorld.new()
	root.add_child(world)
	await process_frame
	var display:=fresh()
	var variants:Array=[]
	for kind in NEW_KINDS+["barn","fence"]:
		var state:=fresh()
		assert(state.place(kind,Vector2(4,0),0).is_empty())
		variants.append(state.items[0].duplicate(true))
		if kind in ["house","barn"]:
			assert(state.upgrade_building(0).is_empty())
			variants.append(state.items[0].duplicate(true))
	for index in variants.size():
		var item:Dictionary=variants[index]
		var pivot:=Node3D.new()
		world.add_child(pivot)
		world.model_item(item,pivot)
		var box:=bounds_of(pivot)
		var footprint:Vector2=FarmState.ITEMS[item.kind].size
		assert(absf(box.position.y)<.06,"Floating or buried art: "+str(item.kind))
		assert(box.position.x>=-footprint.x*.5-.07 and box.end.x<=footprint.x*.5+.07,"Art exceeds X footprint: "+str(item.kind))
		assert(box.position.z>=-footprint.y*.5-.07 and box.end.z<=footprint.y*.5+.07,"Art exceeds Z footprint: "+str(item.kind))
		pivot.free()
		item.x=-10+(index%4)*10
		item.z=-14+int(index/4)*10
		display.items.append(item)
	world.rebuild(display)
	await physics_frame
	assert(world.item_nodes.size()==variants.size())
	var gate_index:=-1
	for index in variants.size():
		var node:Node3D=world.item_nodes[index]
		var bodies:Array=node.find_children("*","StaticBody3D",true,false)
		assert(not bodies.is_empty(),"Missing collision: "+str(variants[index].kind))
		for body:StaticBody3D in bodies:
			assert(int(body.get_meta("item_index",-1))==index,"Collision cannot select its owning item")
		if variants[index].kind=="gate_rustic":gate_index=index
	assert(gate_index>=0)
	var gate:Node3D=world.item_nodes[gate_index]
	var hinge:Node3D=gate.find_child("GateHingeLeft",true,false)
	assert(hinge!=null)
	var rest:=hinge.rotation
	assert(gate_hit(world,gate),"Closed gate has no physical barrier")
	var near:Array[Vector3]=[gate.global_position+Vector3(0,0,1)]
	for step in 100:world.update_art_gates(near,.05)
	await physics_frame
	assert(hinge.rotation.distance_to(rest)>.5,"Nearby actor cannot open gate")
	assert(not gate_hit(world,gate),"Open gate still blocks the passage")
	var far:Array[Vector3]=[Vector3(200,0,200)]
	for step in 200:world.update_art_gates(far,.05)
	await physics_frame
	assert(hinge.rotation.distance_to(rest)<.05,"Gate did not close after actor left")
	assert(gate_hit(world,gate),"Closed gate did not restore its physical barrier")
	gate.rotation.y=PI/2
	await physics_frame
	assert(gate_hit(world,gate),"Rotated closed gate lost its collision")
	for step in 100:world.update_art_gates(near,.05)
	await physics_frame
	assert(not gate_hit(world,gate),"Rotated open gate still blocks passage")
	if DisplayServer.get_name()!="headless":
		var camera:=Camera3D.new()
		world.add_child(camera)
		camera.position=Vector3(43,48,55)
		camera.look_at(Vector3(4,0,2))
		camera.current=true
		world.day_night.update_cycle(180,Vector3.ZERO)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://test-results")
		root.get_texture().get_image().save_png("res://test-results/farm_art_integration.png")
	world.queue_free()
	await process_frame
	print("FARM_ART_INTEGRATION_OK: placement, cooperative commands, costs, upgrades, save roundtrip, footprints, collision and automatic gates")
	quit()

func gate_hit(world:FarmWorld,gate:Node3D) -> bool:
	var start:Vector3=gate.to_global(Vector3(0,.75,-2))
	var end:Vector3=gate.to_global(Vector3(0,.75,2))
	var query:=PhysicsRayQueryParameters3D.create(start,end,1)
	return not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
