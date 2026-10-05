extends SceneTree
var game: Node3D

func _initialize() -> void: call_deferred("run")

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	game.hud.toast_time = 0
	game.hud.toast_panel.visible = false
	if label in ["adult", "ripe"]: await create_timer(1.6).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/orchard-" + label + ".png")

func stand(at: Vector2) -> void:
	game.player.position = Vector3(at.x, FarmLandscape.height_at(at), at.y)
	game.actor.airborne = false
	game.actor.swimming = false
	game.player.velocity = Vector3.ZERO

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"), "Use isolated QA APPDATA")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.qa_mode = true
	game.save_path = "user://orchard-integration.json"
	game.set_process(false)
	game.set_physics_process(false)
	game.pickup.set_physics_process(false)
	game.session_started = true
	game.build_mode = false
	game.hud.close_modal()
	game.state = FarmState.new_farm("survival")
	assert(game.state.claim(Vector2(4, -2)).is_empty())
	game.state.farm_xp = 30
	var cash: int = game.state.money
	assert(game.state.place("orchard", Vector2(4, -2), 0).is_empty())
	assert(game.state.money == cash - 100)
	game.world.rebuild(game.state)
	game.horse.position = Vector3(40, 0, 40)
	game.pickup.position = Vector3(45, 0, 40)
	stand(Vector2(4, 1))
	game.camera.position = Vector3(12, 7, 11)
	game.camera.look_at(Vector3(4, 1.7, -2))
	game.camera.fov = 45
	game._update_ui()
	await capture("young")
	game._action("orchard:accept")
	assert(game.state.orchard_journey.stage == 1)
	game.hud.close_modal()
	assert(game._nearby_context().get("text") == "Cuidar da laranjeira")
	game._interact_nearest()
	assert(game.hud.modal_kind == "orchard" and game.selected == 0)
	await capture("care")
	stand(Vector2(35, 35))
	game._action("orchard:water")
	assert(not game.state.items[0].orchard.watered)
	stand(Vector2(4, 1))
	game.horse.mounted = true
	game._action("orchard:water")
	assert(not game.state.items[0].orchard.watered)
	game.horse.mounted = false
	game.pickup.mounted = true
	game._action("orchard:water")
	assert(not game.state.items[0].orchard.watered)
	game.pickup.mounted = false
	game.actor.airborne = true
	game._action("orchard:water")
	assert(not game.state.items[0].orchard.watered)
	game.actor.airborne = false
	game._action("orchard:water")
	assert(game.state.items[0].orchard.watered)
	game.actor.action_time = 0
	game.state.tick(180)
	game.world.update_orchards(game.state)
	assert(game.state.items[0].orchard.growth == 180)
	assert(game.state.items[0].orchard.ready == 0)
	await capture("adult")
	game.state.tick(120)
	game.world.update_orchards(game.state)
	assert(game.state.items[0].orchard.ready == 6)
	await capture("ripe")
	game._interact_nearest()
	assert(game.hud.modal_kind == "orchard")
	await capture("harvest-panel")
	game._action("orchard:harvest")
	assert(game.state.inventory.orange == 6 and game.state.items[0].orchard.ready == 0)
	assert(not game.state.items[0].orchard.watered)
	game._action("orchard:deliver")
	assert(game.state.orchard_journey.stage == 1)
	stand(Vector2(-24, 15))
	cash = game.state.money
	game._action("orchard:deliver")
	assert(game.state.orchard_journey.stage == 2 and game.state.inventory.orange == 0)
	assert(game.state.money == cash + 220)
	await capture("delivered")
	game._action("orchard:deliver")
	assert(game.state.money == cash + 220)
	assert(game._save_game(false, true))
	assert(game._load_game())
	assert(game.state.orchard_journey.stage == 2 and game.state.items[0].orchard.growth == 180)
	# Fast headless runners can finish before harvest/watering feedback expires.
	# Stop new ambient work and allow the existing tweens to release their targets.
	game.session_started = false
	game.audio.set_process(false)
	game.audio.stop_all()
	await create_timer(1.6).timeout
	game.queue_free()
	await process_frame
	game = null
	await create_timer(.2).timeout
	print("ORCHARD_INTEGRATION_OK: real world, E care, watering, growth, harvest, Lucia delivery, proximity/mount gates and save roundtrip")
	quit()
