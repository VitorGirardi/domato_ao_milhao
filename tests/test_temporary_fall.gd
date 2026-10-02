extends SceneTree
var game:Node3D
var falls:FarmTemporaryFall
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://temporary_fall.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.companions.set_process(false);game.world.set_process(false);game.audio.set_process(false);game.weapons.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	falls=game.falls;falls.set_process(false);falls.set_physics_process(false)
	RenderingServer.set_render_loop_enabled(false)
	var state:=FarmState.new();state.unlimited_money=true;state.farm_xp=950
	assert(state.claim(Vector2(4,0)).is_empty());state.land_size=40
	for row in [["coop",Vector2(-6,-6)],["corral",Vector2(8,-6)],["pigsty",Vector2(-6,6)],["cheesery",Vector2(8,8)]]:
		assert(state.place(row[0],row[1],0).is_empty(),"Fixture placement failed")
	state.items[1].dairy.owned=true;state.items[1].dairy.milk=4;state.items[2].pigs.count=3
	state.staff.hired=true;state.staff.coop=0;state.field_staff.hired=true
	state.dairy_worker.hired=true;state.dairy_worker.site=1;state.cheese_worker.hired=true;state.cheese_worker.site=3
	game.state=state;game.world.rebuild(state);falls.last_state=state;falls.refresh_targets()
	await physics_frame;await physics_frame
	game.world.cat.reset(state);falls.refresh_targets()
	assert(falls.targets.size()>=15,"Missing NPCs or livestock")
	for key in ["npc:vendor","npc:armorer","npc:staff","npc:field","npc:dairy","npc:cheese","horse","cat","player:1"]:assert(falls.targets.has(key),"Missing "+key)
	# Nearest actor wins; an ordinary wall blocks the manual target capsules.
	var vendor:Node3D=falls.targets["npc:vendor"].body;var armorer:Node3D=falls.targets["npc:armorer"].body
	var vendor_at:=vendor.global_position;var armorer_at:=armorer.global_position
	vendor.global_position=Vector3(120,100,3);armorer.global_position=Vector3(120,100,6)
	var ray_from:=Vector3(120,101,0);var ray_to:=Vector3(120,101,10)
	assert(falls.trace_hit(ray_from,ray_to,1).key=="npc:vendor")
	var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(3,3,.3);collision.shape=box;wall.add_child(collision);game.add_child(wall);wall.position=Vector3(120,101,1.5)
	await physics_frame;await physics_frame
	assert(falls.trace_hit(ray_from,ray_to,1).key.is_empty(),"Shot passed through cover")
	wall.queue_free();vendor.global_position=vendor_at;armorer.global_position=armorer_at
	# Every species falls without deleting data, routines cannot overwrite poses.
	var save_before:=state.serialize()
	var keys:=falls.targets.keys();keys.erase("player:1")
	var standing:Dictionary={}
	for key in keys:standing[key]=falls.targets[key].model.global_transform
	for key in keys:assert(falls.knock_down(key),"Cannot knock down "+key)
	falls.advance(1.5);falls.apply_poses()
	for key in keys:
		assert(falls.records[key].entry.model.get_meta("temporary_down",false))
		assert(not falls.knock_down(key),"Repeated shot restarted fall")
		assert(is_equal_approx(falls.records[key].age,1.5))
	var transforms:Dictionary={}
	for key in keys:transforms[key]=falls.records[key].entry.model.global_transform
	game.world.animate(.2,game.player.position,state);game.world.update_staff(state,.2);game.horse.life.update(game.horse,.2,true,state,game.world.landscape,game.player)
	for key in keys:assert(falls.records[key].entry.model.global_transform.is_equal_approx(transforms[key]),"Routine overwrote down pose: "+key)
	game.world.update_animals(state)
	for cow in game.world.cows:assert(cow.body.collision_layer==0,"Down cow collision was re-enabled")
	for pen in game.world.pigsties:
		for pig in pen.pigs:assert(pig.body.collision_layer==0,"Down pig collision was re-enabled")
	assert(not FarmCoopCommands.run(state,{"action":"dairy:milk","index":1}).is_empty(),"Coop milk action ignored down cow")
	game.selected=1;game._action("dairy:milk");game.hud.close_modal()
	assert(state.serialize()==save_before,"Fall or blocked milking changed saved economy/ownership")
	var production_before:Array=state.items.duplicate(true)
	state.tick(1)
	assert(state.items==production_before,"Down animals continued production or consumption")
	assert(falls.find_children("*","Label",true,false).is_empty() and falls.find_children("*","Label3D",true,false).is_empty(),"Unexpected timer UI")
	falls.advance(58.49);assert(falls.records.size()==keys.size())
	falls.advance(.01);assert(is_equal_approx(falls.records[keys[0]].age,60))
	falls.advance(1.99);assert(falls.records.size()==keys.size())
	falls.advance(.01);assert(falls.records.is_empty() and state.temporary_down.is_empty())
	for cow in game.world.cows:assert(cow.body.collision_layer==1)
	for pen in game.world.pigsties:
		for pig in pen.pigs:assert(pig.body.collision_layer==1)
	for key in keys:
		assert(not falls.knock_down(key),"Missing recovery protection")
		assert(falls.targets[key].model.global_transform.is_equal_approx(standing[key]),"Standing transform not restored: "+key)
	falls.advance(3.0);assert(falls.knock_down("npc:vendor"));falls.reset()
	# Rebuilding an unrelated object preserves logical identity and recovery.
	var cow_key:=FarmFallTargets.item_key(state,1,"cow")
	assert(falls.knock_down(cow_key));falls.advance(12)
	var previous_id:int=falls.records[cow_key].entry.model.get_instance_id()
	game.world.rebuild(state);await process_frame;falls.refresh_targets();falls.apply_poses()
	assert(falls.records[cow_key].entry.model.get_instance_id()!=previous_id)
	assert(is_equal_approx(falls.records[cow_key].age,12))
	assert(falls.blocks_command({"action":"move_item","index":1}))
	assert(not falls.blocks_command({"action":"move_item","index":3}))
	falls.advance(50);assert(not falls.is_down(cow_key));falls.reset()
	# Local actions/movement freeze, but save remains possible; water recovers dry.
	var wet:=Vector2(FarmRegion.legacy_river_x(22),22)
	game.player.position=Vector3(wet.x,FarmRegion.water_level(wet)-.85,wet.y)
	assert(falls.knock_down("player:1"));var frozen:Vector3=game.player.position
	Input.action_press("forward");game._physics_process(.1);Input.action_release("forward")
	assert(game.player.position==frozen and not game._try_jump())
	assert(game._save_game(false))
	falls.advance(60);assert(not FarmRegion.water_blocked(Vector2(game.player.position.x,game.player.position.z)),"Water recovery stayed wet")
	falls.advance(2);assert(not falls.local_down());falls.reset()
	# A hit during a jump must finish recovery on the physical support, including bridges.
	for point in [Vector2(20,25),Vector2(420,0)]:
		var support_y:=FarmLandscape.height_at(point)
		game.player.position=Vector3(point.x,support_y+2,point.y)
		game.actor.airborne=true
		assert(falls.knock_down("player:1"))
		falls.advance(60)
		assert(absf(game.player.position.y-support_y)<.2,"Airborne recovery missed ground/bridge: "+str(game.player.position))
		falls.advance(2);falls.reset()
	# Horse impact unseats its rider; rider impact also releases the mount.
	game.horse.restore({"x":20.0,"z":25.0,"angle":0.0});game.player.position=game.horse.position+Vector3(2,.1,0)
	await physics_frame;await physics_frame
	game.horse.mount(game.player,game.avatar,game.actor);assert(game.horse.mounted)
	assert(falls.knock_down("horse"));assert(not game.horse.mounted and not game.actor.airborne)
	assert(game.player.position.distance_to(game.horse.position)>1.0)
	falls.reset();game.horse.mount(game.player,game.avatar,game.actor)
	assert(falls.knock_down("player:1") and not game.horse.mounted)
	falls.reset();game.session_started=false;game.queue_free();await process_frame
	print("TEMPORARY_FALL_OK: cover/nearest, all species and staff, 60+2+3 lifecycle, rebuild, dry recovery, mounted impacts, preserved saves, no timer UI")
	quit()
