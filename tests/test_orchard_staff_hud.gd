extends SceneTree

func _initialize() -> void:call_deferred("run")

func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/orchard-staff-"+label+".png")

func check_bounds(control:Control) -> void:
	for child in control.get_children():
		if not child is Control or not child.visible:continue
		if control is ScrollContainer:continue # Its content deliberately scrolls.
		var available:=Rect2(Vector2.ZERO,control.size).grow(.5)
		assert(available.encloses(Rect2(child.position,child.size)),"%s child outside %s: %s / %s"%[child.get_class(),control.get_class(),Rect2(child.position,child.size),control.size])
		check_bounds(child)

func run() -> void:
	var state:=FarmState.new_farm("survival")
	assert(state.claim(Vector2(4,-2)).is_empty())
	state.farm_xp=30
	assert(state.place("orchard",Vector2(0,-2),0).is_empty())
	assert(state.place("orchard",Vector2(8,-2),0).is_empty())
	var hud:=FarmHUD.new();root.add_child(hud);await process_frame
	FarmOrchardStaffHUD.show(hud,state);await process_frame
	assert(hud.modal.get_meta("orchard_staff_apply").disabled)
	var checks:Dictionary=hud.modal.get_meta("orchard_staff_checks")
	assert(checks.size()==2 and checks[0].disabled and checks[1].disabled)
	check_bounds(hud.modal);await capture("locked")
	state.orchard_journey={"stage":2,"harvested":6}
	FarmOrchardStaffHUD.show(hud,state);await process_frame
	checks=hud.modal.get_meta("orchard_staff_checks")
	checks[0].button_pressed=true
	assert(not hud.modal.get_meta("orchard_staff_apply").disabled)
	assert(hud.modal.get_meta("orchard_staff_apply").text.contains("$120"))
	# A network refresh must keep an unsubmitted choice, not restore saved trees.
	FarmOrchardStaffHUD.show(hud,state);await process_frame
	checks=hud.modal.get_meta("orchard_staff_checks")
	assert(checks[0].button_pressed and not checks[1].button_pressed)
	check_bounds(hud.modal);await capture("choose")
	assert(FarmOrchardStaff.configure(state,[0]).is_empty())
	assert(state.staff.hired and state.staff.paused)
	hud.close_modal();FarmOrchardStaffHUD.show(hud,state);await process_frame
	assert(not hud.modal.get_meta("orchard_staff_apply").text.contains("$120"))
	check_bounds(hud.modal);await capture("active")
	FarmCrewHUD.show(hud,state);await process_frame
	check_bounds(hud.modal);await capture("crew")
	FarmInteractionUI.orchard(hud,state,0);await process_frame
	check_bounds(hud.modal);await capture("tree")
	assert(FarmOrchardStaff.pause(state).is_empty())
	FarmOrchardStaffHUD.show(hud,state);await process_frame
	check_bounds(hud.modal);await capture("paused")
	var sandbox:=FarmState.new_farm("sandbox")
	assert(sandbox.claim(Vector2(4,-2)).is_empty())
	assert(sandbox.place("orchard",Vector2(4,-2),0).is_empty())
	hud.close_modal();FarmOrchardStaffHUD.show(hud,sandbox);await process_frame
	checks=hud.modal.get_meta("orchard_staff_checks");checks[0].button_pressed=true
	assert(not hud.modal.get_meta("orchard_staff_apply").disabled)
	assert(not hud.modal.get_meta("orchard_staff_apply").text.contains("$120"))
	check_bounds(hud.modal);await capture("sandbox")
	hud.queue_free();await process_frame
	print("ORCHARD_STAFF_HUD_OK: locked, choices, retained draft, hired, paused, Sandbox and child bounds")
	quit()
