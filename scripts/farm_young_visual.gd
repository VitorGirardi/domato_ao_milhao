class_name FarmYoungVisual
extends RefCounted
## Growth changes proportions continuously; feet keep their original ground pivot.
static func apply(root:Node3D,item:Dictionary,slot:int) -> void:
	if root.get_meta("temporary_down",false):return
	var p:=FarmYoung.progress(item,slot)
	if p>=1 and not root.has_meta("young_shape"):return
	if not root.has_meta("young_shape"):
		var parts:Array=[]
		var head:String={"coop":"HenBody","corral":"CowHead","pigsty":"PigHead"}[item.kind]
		for key in [head]:
			var node:=root.find_child(key,true,false) as Node3D
			if node:parts.append({"node":node,"scale":node.scale,"key":key})
		root.set_meta("young_shape",parts)
	var blend:=smoothstep(0,1,p)
	var start:float={"coop":.38,"corral":.48,"pigsty":.43}[item.kind]
	root.scale=Vector3.ONE*lerpf(start,1,blend)
	for part in root.get_meta("young_shape"):
		var factor:=lerpf(1.22,1,blend)
		part.node.scale=part.scale*factor
	# Per-animal materials: yellow down and gradual adult comb/horns/udder.
	if not root.has_meta("young_coat"):
		var materials:Array=[]
		for node in root.find_children("*","MeshInstance3D",true,false):
			for surface in range(node.mesh.get_surface_count()):
				var source:=node.get_active_material(surface) as StandardMaterial3D
				if not source:continue
				var down:bool=item.kind=="coop" and (source.resource_name.begins_with("Cream") or source.resource_name.begins_with("White"))
				var adult_part:bool=(item.kind=="coop" and source.resource_name=="Red") or (item.kind=="corral" and (str(node.name).begins_with("Horn") or str(node.name).begins_with("Teat") or node.name=="Udder"))
				if not down and not adult_part:continue
				var material:=source.duplicate() as StandardMaterial3D
				if adult_part:material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
				node.set_surface_override_material(surface,material)
				materials.append({"material":material,"color":source.albedo_color,"adult":adult_part})
		root.set_meta("young_coat",materials)
	for coat in root.get_meta("young_coat"):
		if coat.adult:
			var color:Color=coat.color;color.a=smoothstep(.55,1,p);coat.material.albedo_color=color
		else:coat.material.albedo_color=Color("ffe697").lerp(coat.color,blend)

static func stride(root:Node3D,before:Vector3,delta:float,stride_length:float,turn:float=0) -> Dictionary:
	var motion:Dictionary=root.get_meta("distance_gait",{"phase":0.0,"blend":0.0})
	var distance:=Vector2(root.position.x-before.x,root.position.z-before.z).length()
	var travel:=distance+minf(absf(turn),.1)*.09*root.scale.x
	# A teleport never advances the feet through dozens of steps.
	if travel<1.5 and delta>0:
		motion.phase=fposmod(motion.phase+travel/maxf(.1,stride_length*root.scale.x)*TAU,TAU)
		motion.blend=lerpf(motion.blend,1.0 if travel>.00001 else 0.0,1-exp(-delta*12))
	else:motion.blend=0.0
	root.set_meta("distance_gait",motion)
	return motion

static func pig_legs(root:Node3D,motion:Dictionary) -> void:
	for key in ["LegFL","LegFR","LegBL","LegBR"]:
		var phase:float={"LegBL":0.0,"LegFL":PI*.5,"LegBR":PI,"LegFR":PI*1.5}[key]
		FarmLivestockPose.joint(root,key,Vector3.RIGHT,.24*sin(motion.phase+phase)*motion.blend)
