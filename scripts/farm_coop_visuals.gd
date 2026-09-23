class_name FarmCoopVisuals
extends RefCounted
## Replicate the host's actual animation. Never run worker economics on a client.
static func roots(world:FarmWorld) -> Dictionary:
	var result:Dictionary={}
	for key in ["staff_root","field_root"]:
		var n:Variant=world.get(key)
		if is_instance_valid(n):result[key]=n
	for key in ["raul_motion","chico_motion"]:
		var n:Variant=world.get(key).node
		if is_instance_valid(n):result[key]=n
	for h in world.chickens:result["hen_%d_%d"%[h.coop,h.hen]]=h.node
	for pen in world.pigsties:
		for pig in pen.pigs:result["pig_%d_%d"%[pen.index,pig.slot]]=pig.node
	for c in world.cows:
		result["cow_%d"%c.index]=c.node
		if is_instance_valid(c.get("gate")):result["gate_%d"%c.index]=c.gate
		if is_instance_valid(c.get("gate_collision")):result["gate_collision_%d"%c.index]=c.gate_collision
	return result

static func capture(world:FarmWorld) -> Dictionary:
	var result:Dictionary={}
	var nodes:=roots(world)
	for key in nodes:
		var entries:Array=[]
		collect(nodes[key],nodes[key],entries)
		result[key]=entries
	return result

static func collect(root:Node3D,node:Node,entries:Array) -> void:
	if node is Node3D:
		var entry:Dictionary={"path":str(root.get_path_to(node)),"transform":node.transform,"visible":node.visible}
		if node is Skeleton3D:
			var bones:Array=[]
			for i in range(node.get_bone_count()):bones.append([node.get_bone_pose_position(i),node.get_bone_pose_rotation(i),node.get_bone_pose_scale(i)])
			entry.bones=bones
		if node is MeshInstance3D and node.mesh!=null and node.mesh.get_blend_shape_count()>0:
			var shapes:Array=[]
			for i in range(node.mesh.get_blend_shape_count()):shapes.append(node.get_blend_shape_value(i))
			entry.shapes=shapes
		if node is Label3D:entry.text=node.text
		if node is CollisionShape3D:entry.disabled=node.disabled
		entries.append(entry)
	for child in node.get_children():collect(root,child,entries)

static func apply(world:FarmWorld,data:Dictionary,weight:float) -> void:
	var nodes:=roots(world)
	for key in data:
		if not nodes.has(key):continue
		for entry in data[key]:
			var node:Node=nodes[key].get_node_or_null(NodePath(entry.path))
			if not node is Node3D:continue
			node.transform=node.transform.interpolate_with(entry.transform,weight);node.visible=entry.visible
			if node is Skeleton3D and entry.has("bones"):
				for i in range(mini(node.get_bone_count(),entry.bones.size())):
					var pose:Array=entry.bones[i]
					node.set_bone_pose_position(i,node.get_bone_pose_position(i).lerp(pose[0],weight))
					node.set_bone_pose_rotation(i,node.get_bone_pose_rotation(i).slerp(pose[1],weight))
					node.set_bone_pose_scale(i,node.get_bone_pose_scale(i).lerp(pose[2],weight))
			if node is MeshInstance3D and entry.has("shapes"):
				for i in range(mini(node.mesh.get_blend_shape_count(),entry.shapes.size())):node.set_blend_shape_value(i,lerpf(node.get_blend_shape_value(i),entry.shapes[i],weight))
			if node is Label3D and entry.has("text"):node.text=entry.text
			if node is CollisionShape3D and entry.has("disabled"):node.set_deferred("disabled",entry.disabled)
