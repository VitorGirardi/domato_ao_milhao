extends SceneTree
var world: FarmWorld
var state: FarmState
var camera: Camera3D

func _initialize() -> void: call_deferred("run")

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	if label in ["watering","harvesting"]:
		for step in range(3): world.update_staff(state,.1)
	else:
		world.update_staff(state,.1)
		await create_timer(1.6).timeout
	camera.position = world.staff_root.position + Vector3(6,4,7)
	camera.look_at(world.staff_root.position + Vector3(0,1.3,0))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/zeca-orchard-" + label + ".png")

func advance_until_working() -> void:
	for step in range(800):
		var previous := world.staff_root.position
		world.update_staff(state,.1)
		assert(world.staff_root.position.distance_to(previous) <= .25, "Zeca teleported")
		assert(world.orchard_staff_motion.route.walkable(world.staff_root.position,state), "Worker crossed obstacle")
		assert(absf(world.staff_root.position.y-FarmLandscape.height_at(Vector2(world.staff_root.position.x,world.staff_root.position.z))) < .01)
		if world.orchard_staff_motion.working: return
		assert(not state.orchard_staff.paused, "Unexpected path blockage")
	assert(false, "Worker never reached tree")

func ready_for_water() -> void:
	state.items[0].orchard = FarmOrchard.fresh_item()
	state.orchard_staff.paused = false
	state.orchard_staff.reason = ""
	world.orchard_staff_motion.reset()
	world.staff_actor.action_time = 0

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	state = FarmState.new_farm("survival")
	state.claim(Vector2(4,-2)); state.farm_xp = 30
	assert(state.place("orchard",Vector2(4,-2),0).is_empty())
	state.orchard_journey = {"stage":2,"harvested":6}
	assert(FarmOrchardStaff.configure(state,[0]).is_empty())
	assert(state.staff.coop == -1)
	world = FarmWorld.new(); root.add_child(world)
	world.rebuild(state)
	camera = Camera3D.new(); world.add_child(camera); camera.current = true
	var worker_id := world.staff_root.get_instance_id()
	var money: int = state.money
	# Client presentation creates the same actor, but must never serve or charge.
	for step in range(20): world.update_staff(state,0)
	assert(state.money == money and not state.items[0].orchard.watered)
	world.staff_root.position = Vector3(-6,0,1)
	state.scenery_obstacles.append(Rect2(-1,-5,1,9))
	advance_until_working()
	assert(state.money == money and not state.items[0].orchard.watered)
	assert(world.staff_root.position.distance_to(Vector3(4,0,-2)) >= 2.9)
	await capture("watering")
	for step in range(15): world.update_staff(state,.1)
	assert(state.items[0].orchard.watered and state.money == money-2)
	assert(state.orchard_staff.services == 1)
	# Harvest uses the adult Blender tree, the same Zeca and a completed animation.
	state.items[0].orchard = {"growth":180.0,"watered":true,"ready":6,"fruit_time":120.0}
	world.update_orchards(state)
	advance_until_working()
	money = state.money
	assert(state.inventory.orange == 0)
	await capture("harvesting")
	for step in range(ceili(FarmWorkPose.HARVEST_DURATION/.1)+1): world.update_staff(state,.1)
	assert(state.inventory.orange == 6 and state.money == money-2)
	assert(world.staff_root.get_instance_id() == worker_id)
	# Manual care racing an animation cancels the pending service, without charge.
	ready_for_water(); advance_until_working(); money = state.money
	assert(FarmOrchard.water(state,0).is_empty())
	for step in range(20): world.update_staff(state,.1)
	assert(state.money == money)
	# Pause and temporary fall invalidate the animation rather than billing on resume.
	ready_for_water(); advance_until_working(); money = state.money
	state.orchard_staff.paused = true
	for step in range(20): world.update_staff(state,.1)
	assert(state.money == money and not state.items[0].orchard.watered)
	ready_for_water(); advance_until_working()
	state.temporary_down["npc:staff"] = true
	for step in range(20): world.update_staff(state,.1)
	assert(state.money == money and not state.items[0].orchard.watered)
	state.temporary_down.erase("npc:staff")
	# A moved tree invalidates the captured placement even though its index is stable.
	ready_for_water(); advance_until_working()
	state.items[0].x = 8
	world.update_staff(state,.1)
	assert(not world.orchard_staff_motion.working and state.money == money)
	state.items[0].x = 4
	# Rebuild/save load discards pending animation, preserving ledger and one actor.
	ready_for_water(); advance_until_working()
	var saved := state.serialize()
	assert(state.restore(JSON.parse_string(JSON.stringify(saved))))
	world.rebuild(state)
	assert(not world.orchard_staff_motion.working and world.staff_actor.action_time == 0)
	assert(world.staff_root.get_instance_id() == worker_id and state.money == money)
	# Reconfiguring the same tree list still cancels the old pending service.
	ready_for_water(); advance_until_working()
	assert(FarmOrchardStaff.configure(state,[0]).is_empty())
	world.update_staff(state,.1)
	assert(state.money == money and not state.items[0].orchard.watered)
	# Removing a target during animation cannot redirect its charge to another index.
	assert(state.remove_item(0).is_empty())
	var after_remove: int = state.money
	for step in range(20): world.update_staff(state,.1)
	assert(state.money == after_remove and not world.orchard_staff_motion.working)
	assert(state.restore(JSON.parse_string(JSON.stringify(saved))))
	world.rebuild(state)
	# All approaches blocked: pause instead of remote care or a second worker spawn.
	ready_for_water(); world.staff_root.position = Vector3(-6,0,1)
	state.scenery_obstacles.append(Rect2(-2,-8,12,12))
	world.update_staff(state,.1)
	assert(state.orchard_staff.paused and state.orchard_staff.reason == "blocked")
	assert(state.money == money and not state.items[0].orchard.watered)
	await capture("blocked")
	# Route checks include actual scenery stones, water and bounded long-distance grids.
	var route := FarmOrchardStaffMotion.OrchardRoute.new()
	route.stones.append(Rect2(20,20,4,4))
	assert(not route.walkable(Vector3(22,0,22),state))
	assert(not route.walkable(Vector3(-42,0,0),state))
	route.plan(Vector3(-6,0,1),Vector3(400,0,-100),state)
	assert(route.blocked and route.path.is_empty())
	await create_timer(1.6).timeout
	world.queue_free(); await process_frame; world = null; camera = null
	await create_timer(.2).timeout
	print("ORCHARD_STAFF_MOTION_OK: physical path, contact, animation completion, single actor, client no-op, races, pause/fall/move, save rebuild and blocked route")
	quit()
