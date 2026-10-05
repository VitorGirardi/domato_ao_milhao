extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var art := FarmBuildArt.new()
	var item := {"kind": "orchard", "orchard": FarmOrchard.fresh_item()}
	var view := art.instantiate(item, host)
	art.add_collision(item, view, 7)
	assert(view.get_node("Young").visible)
	assert(not view.get_node("Adult").visible)
	var fruits: Array = view.get_meta("fruits")
	assert(not fruits.is_empty(), "Mature Blender orange meshes must be discoverable")
	for fruit in fruits: assert(not fruit.visible)
	var body := view.get_node("OrchardTrunk") as StaticBody3D
	assert(body.get_meta("item_index") == 7)
	var body_id := body.get_instance_id()
	var young_id := view.get_node("Young").get_instance_id()
	item.orchard = {"growth": 180.0, "watered": true, "ready": 0, "fruit_time": 60.0}
	FarmOrchardView.update(view, item)
	assert(not view.get_node("Young").visible)
	assert(view.get_node("Adult").visible)
	for fruit in fruits: assert(not fruit.visible)
	item.orchard.ready = 6
	item.orchard.fruit_time = 120.0
	FarmOrchardView.update(view, item)
	for fruit in fruits: assert(fruit.visible)
	item.orchard.ready = 0
	item.orchard.watered = false
	item.orchard.fruit_time = 0.0
	FarmOrchardView.update(view, item)
	for fruit in fruits: assert(not fruit.visible)
	assert(view.get_node("OrchardTrunk").get_instance_id() == body_id)
	assert(view.get_node("Young").get_instance_id() == young_id)
	assert(FarmLevels.required("orchard") == 2)
	assert("orchard" in FarmBuildHUD.CATEGORIES["Lavoura"])
	assert(FarmMapPlaces.notices(item) == FarmOrchard.status(item))
	var state := FarmState.new()
	state.items.append(item)
	var hud := FarmHUD.new()
	root.add_child(hud)
	FarmInteractionUI.orchard(hud, state, 0)
	assert(hud.modal_kind == "orchard")
	assert(not hud.modal.get_meta("orchard_water").disabled)
	assert(hud.modal.get_meta("orchard_harvest").disabled)
	var water_id: int = hud.modal.get_meta("orchard_water").get_instance_id()
	item.orchard.ready = 6
	item.orchard.watered = true
	item.orchard.fruit_time = 120.0
	FarmInteractionUI.update_orchard(hud, state)
	assert(hud.modal.get_meta("orchard_water").disabled)
	assert(not hud.modal.get_meta("orchard_harvest").disabled)
	assert(hud.modal.get_meta("orchard_water").get_instance_id() == water_id)
	hud.free()
	host.free()
	print("ORCHARD_VIEW_OK")
	quit()
