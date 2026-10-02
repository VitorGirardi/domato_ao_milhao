class_name FarmFallPose
extends RefCounted
## Presentation only: no gameplay timer, damage, collision or persistence.
const CURVES=preload("res://assets/animations/temporary_fall.gd")

static func species(entry:Dictionary) -> String:
	var kind:String=entry.get("kind","human")
	return kind if CURVES.DATA.has(kind) else "human"

static func sample(track:Array,frame:float) -> Vector3:
	var i:=clampi(int(frame),0,track.size()-1)
	var j:=mini(i+1,track.size()-1)
	var a:Array=track[i];var b:Array=track[j]
	return Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),frame-i)

static func prepare(entry:Dictionary) -> void:
	if entry.has("fall_pose"):return
	var model:Node3D=entry.model
	var cache:Dictionary={"parts":{},"meshes":[],"bones":[]}
	for key in CURVES.DATA[species(entry)]:
		if key=="ROOT":continue
		var node:=model.find_child(key,true,false) as Node3D
		if node:cache.parts[key]={"node":node,"rest":node.transform}
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if mesh.skin or not mesh.is_visible_in_tree():continue
		# Actual authored surface samples avoid the empty corners of a rotated AABB.
		var vertices:Array[Vector3]=[]
		for surface in mesh.mesh.get_surface_count():
			var array:PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for i in range(0,array.size(),maxi(1,array.size()/120)):
				vertices.append(array[i])
		cache.meshes.append({"node":mesh,"vertices":vertices})
	var actor:FarmAvatar=entry.get("actor")
	if actor:
		for key in actor.bones:
			var radius:=.12
			if key=="Head":radius=.25
			elif key in ["Spine","Chest","Hips"]:radius=.23
			cache.bones.append({"skin":actor.skeleton,"index":actor.bones[key],"radius":radius})
	elif species(entry)=="horse":
		var skins:=model.find_children("*","Skeleton3D",true,false)
		if not skins.is_empty():
			var skin:Skeleton3D=skins[0]
			for i in skin.get_bone_count():
				var key:=skin.get_bone_name(i)
				var radius:=.12
				if key=="SkinHorseBody":radius=.54
				elif key=="SkinHorseNeck":radius=.32
				cache.bones.append({"skin":skin,"index":i,"radius":radius})
	entry.fall_pose=cache

static func apply(entry:Dictionary,age:float,recovery:bool=false) -> void:
	prepare(entry)
	var model:Node3D=entry.model
	var cache:Dictionary=entry.fall_pose
	var base:Transform3D=entry.base_transform
	var frame:=30.0+clampf(age,0,2)*30.0 if recovery else clampf(age,0,1)*30.0
	# Model may itself be the animal's body. Use the unposed parent + saved
	# transform as the anchor, never the already rolled presentation transform.
	var parent:=model.get_parent_node_3d()
	var anchor:Transform3D=parent.global_transform*base if parent else base
	var terrain_key:float=float(entry.get("ground_y",INF))
	var fitted:bool=cache.get("fit_frame",-1.0)==frame and cache.get("fit_anchor",Transform3D.IDENTITY)==anchor and cache.get("fit_ground",-INF)==terrain_key
	var tracks:Dictionary=CURVES.DATA[species(entry)]
	model.transform=base
	var actor:FarmAvatar=entry.get("actor")
	if actor:
		actor.skeleton.reset_bone_poses()
		actor.can.visible=false;actor.carried_egg.visible=false;actor.reaction.visible=false
		actor.face_mesh.set_blend_shape_value(actor.blink_index,smoothstep(0,15,frame) if not recovery else 1.0-smoothstep(55,80,frame))
	for key in tracks:
		if key=="ROOT":continue
		var angles:=sample(tracks[key],frame)
		if actor and actor.bones.has(key):actor.pose_bone(key,angles)
		elif cache.parts.has(key):
			var part:Dictionary=cache.parts[key]
			part.node.transform=part.rest
			part.node.basis=part.rest.basis*Basis.from_euler(angles)
	if species(entry)=="horse" and entry.body.has_method("sync_skin"):entry.body.sync_skin()
	if species(entry)=="chicken":
		var hen:=model.find_child("HenBody",true,false) as MeshInstance3D
		if hen:
			var index:=hen.find_blend_shape_by_name("Peck")
			if index>=0:hen.set_blend_shape_value(index,sin(clampf(frame,0,30)/30*PI)*.6 if not recovery else sin((frame-30)/60*PI)*.4)
	var angles:=sample(tracks.ROOT,frame)
	model.basis=base.basis*Basis.from_euler(angles)
	# Fit every support to its own terrain sample, so a side-lying body follows
	# slopes rather than rotating around its feet and hanging above the ground.
	var lift:float=cache.get("lift",0.0)
	if not fitted:
		lift=-INF
		for mesh in cache.meshes:
			for vertex in mesh.vertices:
				var p:Vector3=mesh.node.to_global(vertex)
				lift=maxf(lift,ground(entry,p)-p.y+.018)
		for bone in cache.bones:
			var p:Vector3=bone.skin.to_global(bone.skin.get_bone_global_pose(bone.index).origin)
			lift=maxf(lift,ground(entry,p)-p.y+bone.radius)
		cache.lift=lift;cache.fit_frame=frame;cache.fit_anchor=anchor;cache.fit_ground=terrain_key
		cache.fit_passes=int(cache.get("fit_passes",0))+1
	if is_finite(lift):
		var weight:=smoothstep(0,.28,age) if not recovery else 1.0-smoothstep(1.65,2,age)
		model.global_position.y+=lift*weight

static func ground(entry:Dictionary,p:Vector3) -> float:
	if entry.has("ground_y"):return float(entry.ground_y)
	return FarmLandscape.height_at(Vector2(p.x,p.z))

static func reset(entry:Dictionary) -> void:
	if not is_instance_valid(entry.get("model")):return
	entry.model.transform=entry.base_transform
	if entry.has("fall_pose"):
		for part in entry.fall_pose.parts.values():
			if is_instance_valid(part.node):part.node.transform=part.rest
	var actor:FarmAvatar=entry.get("actor")
	if actor:
		actor.skeleton.reset_bone_poses()
		actor.face_mesh.set_blend_shape_value(actor.blink_index,0)
	if species(entry)=="horse" and is_instance_valid(entry.get("body")) and entry.body.has_method("sync_skin"):entry.body.sync_skin()
	if species(entry)=="chicken":
		var hen:=entry.model.find_child("HenBody",true,false) as MeshInstance3D
		if hen:
			var index:=hen.find_blend_shape_by_name("Peck")
			if index>=0:hen.set_blend_shape_value(index,0)
	entry.erase("fall_pose")

