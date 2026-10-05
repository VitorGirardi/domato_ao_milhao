extends SceneTree
## Real stock/cargo accounting, Sandbox invariants and the expanded shop layouts.
class CargoHost extends Node3D:
	var state:FarmState
	var hud:FarmHUD
class ParkedPickup extends FarmPickup:
	func cargo_access() -> bool:return false

func _initialize() -> void:call_deferred("run")

func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/orchard-"+label+".png")

func check_panel(panel:Panel) -> void:
	var cards:Array[Rect2]=[]
	for child in panel.get_children():
		if not child is Control:continue
		var bounds:=Rect2(child.position,child.size)
		assert(Rect2(Vector2.ZERO,panel.size).encloses(bounds),"Control outside modal: %s"%bounds)
		if child is Panel and child.position.y>=150:
			for previous in cards:assert(not previous.intersects(bounds),"Overlapping cards")
			cards.append(bounds)
			for nested in child.get_children():
				if nested is Control:assert(Rect2(Vector2.ZERO,child.size).encloses(Rect2(nested.position,nested.size)),"Control outside card: "+str(nested))

func run() -> void:
	var state:=FarmState.new_farm("survival")
	assert(state.claim(Vector2(4,-2)).is_empty())
	state.inventory.orange=18
	var baseline:=state.sale_value()-18*16
	assert(FarmPickupCargo.transfer(state,"orange",10,true).is_empty())
	assert(state.inventory.orange==8 and state.pickup.cargo.orange==10)
	assert(state.sale_value()==baseline+8*16)
	var restored:=FarmState.new()
	assert(restored.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(restored.inventory.orange==8 and restored.pickup.cargo.orange==10)
	assert(FarmPickupCargo.transfer(restored,"orange",4,false).is_empty())
	assert(restored.inventory.orange==12 and restored.pickup.cargo.orange==6)
	var cash:=restored.money
	assert(FarmPickupCargo.sell(restored)==96 and restored.money==cash+96)
	assert(FarmPickupCargo.sell(restored)==0 and restored.inventory.orange==12)
	cash=restored.money
	assert(restored.sell_product("orange",2)==32 and restored.money==cash+32 and restored.inventory.orange==10)
	var value:=restored.sale_value()
	assert(restored.sell_all()==value and restored.inventory.orange==0)
	var sandbox:=FarmState.new_farm("sandbox")
	sandbox.claim(Vector2(4,-2))
	var physical:=int(sandbox.inventory.orange)
	assert(FarmPickupCargo.transfer(sandbox,"orange",60,true).is_empty())
	assert(FarmPickupCargo.transfer(sandbox,"orange",60,false).is_empty())
	assert(sandbox.inventory.orange==physical and sandbox.stock("orange")==1000000000)
	assert(sandbox.sell_product("orange",1)==16 and sandbox.inventory.orange==physical)
	assert(FarmPickupCargo.KEYS.size()==13 and FarmPickupCargo.TITLES.size()==13)
	var hud:=FarmHUD.new();root.add_child(hud)
	await process_frame
	hud.market(state,"sales");await process_frame
	assert(hud.sale_buttons.has("orange") and hud.sale_quantities.size()==5)
	check_panel(hud.modal);await capture("shop")
	state.orchard_journey.stage=1;state.orchard_journey.harvested=6
	FarmOrchardMission.show(hud,state);await process_frame
	check_panel(hud.modal);await capture("mission")
	var host:=CargoHost.new();host.state=state;host.hud=hud
	var truck:=ParkedPickup.new();truck.game=host
	FarmPickupCargo.show(truck);await process_frame
	check_panel(hud.modal);await capture("cargo")
	# This UI-only pickup never runs setup(), which normally parents these nodes.
	truck.instruments.free();truck.cargo_visual.free();truck.accessories.free()
	truck.free();host.free();hud.queue_free();await process_frame
	print("ORCHARD_TRADE_OK: orange sales, cargo roundtrip, saves, Sandbox and expanded UI")
	quit()
