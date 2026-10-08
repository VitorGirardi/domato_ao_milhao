extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://driver_seat.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false)
	game.qa_mode=true;game.session_started=true;game.build_mode=false;game.hud.close_modal();game.hud.visible=false
	game.state=FarmState.new_farm("sandbox");game.world.day_night.update_cycle(80,Vector3.ZERO)
	var truck:FarmPickup=game.pickup;truck.set_physics_process(false)
	var shell:MeshInstance3D=truck.model.find_child("PickupBody",true,false)
	var roof_top:float=shell.get_aabb().end.y
	for character in FarmCharacters.IDS:
		FarmCharacters.apply_to_game(game,character);truck.restore({"x":30,"z":25,"angle":0})
		game.player.position=truck.door_stand();game.actor.airborne=false;game.actor.swimming=false
		await physics_frame;assert(truck.enter())
		while truck.transitioning():truck.drive(.05,0,0,false,true)
		await process_frame
		var actor:FarmAvatar=game.actor
		var hip:Vector3=truck.model.to_local(actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.bones.Pelvis).origin))
		assert(hip.y>1.86 and hip.y<2.02 and hip.z>-.34 and hip.z<.02,"Pelvis must sit over the cushion")
		for bone in ["Pelvis","Thigh.L","Shin.L","Foot.L","Head"]:
			print(character," ",bone," ",truck.model.to_local(actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(actor.bones[bone]).origin)))
		print("SOLE ",character," ",actor.locomotion.sole_height(actor)+FarmVehicleTransition.SEATED_ORIGIN.y)
		var sole:=actor.locomotion.sole_height(actor)+FarmVehicleTransition.SEATED_ORIGIN.y
		assert(sole>=1.37 and sole<1.43,"Soles must rest on cab floor 1.38")
		for node in game.avatar.find_children("*","MeshInstance3D",true,false):
			# Dummy rendering does not register skinned meshes. Joint/floor/grip
			# checks run everywhere; the graphics job also checks deformed skin.
			if DisplayServer.get_name()=="headless":break
			if not node.name in ["HeadSkin","BodySkin"]:continue
			var mesh:Mesh=node.bake_mesh_from_current_skeleton_pose()
			var low:=INF;var high:=-INF;var seat_contact:=INF
			for surface in range(mesh.get_surface_count()):
				var vertices:PackedVector3Array=mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				var original:PackedVector3Array=node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				for index in range(vertices.size()):
					var vertex:=vertices[index]
					var p:Vector3=truck.model.to_local(node.to_global(vertex));low=minf(low,p.y);high=maxf(high,p.y)
					if node.name=="BodySkin" and original[index].y>.85 and original[index].y<1 and original[index].z<-.04:seat_contact=minf(seat_contact,p.y)
			print("MESH ",character," ",node.name," ",low," ",high)
			if node.name=="HeadSkin":assert(high<roof_top-.20,"Head and hat must remain below the actual roof underside")
			else:assert(seat_contact>1.78 and seat_contact<1.84,"Clothed pelvis must contact the cushion, not pass beneath it")
		for side in ["L","R"]:
			assert(actor.rein_grip_world(side).distance_to(truck.model.to_global(Vector3(-.53+(-.22 if side=="L" else .22),2.3,.5)))<.08)
		truck.driver_door.rotation.y=1.15
		game.camera.position=truck.to_global(Vector3(-5,2.7,.2));game.camera.look_at(truck.position+Vector3(0,2.1,.05))
		if DisplayServer.get_name()!="headless":
			await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/driver-seat-"+character+".png")
		truck.reset_driver()
	game.session_started=false;game.audio.stop_all();game.queue_free();await process_frame
	print("DRIVER_SEAT_OK");quit()
