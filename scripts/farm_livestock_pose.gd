class_name FarmLivestockPose
extends RefCounted
## Local presentation only. Authoritative movement remains with FarmWorld.

static func prepare_cow(root:Node3D) -> void:
	# Godot 4.7 imports COLOR_0 but leaves its material switch disabled.
	var coat:=root.find_child("CowBody",true,false) as MeshInstance3D
	if not coat:return
	for surface in range(coat.mesh.get_surface_count()):
		var source:=coat.mesh.surface_get_material(surface) as StandardMaterial3D
		if source and source.resource_name=="CowCoat":
			var material:=source.duplicate() as StandardMaterial3D
			material.vertex_color_use_as_albedo=true
			coat.set_surface_override_material(surface,material)

static func joint(root:Node3D,key:String,axis:Vector3,angle:float) -> void:
	var cache:Dictionary=root.get_meta("livestock_joints",{})
	if not cache.has(key):
		var node:=root.find_child(key,true,false) as Node3D
		cache[key]={"node":node,"rest":node.basis if node else Basis.IDENTITY}
		root.set_meta("livestock_joints",cache)
	var entry:Dictionary=cache[key]
	if entry.node:entry.node.basis=entry.rest*Basis(axis,angle)

static func cow(root:Node3D,time:float,grazing:float,walking:bool) -> void:
	# A short chewing bout with a quiet pause; never a whole-head vibration.
	var bout:=1.0-smoothstep(4.8,5.5,fposmod(time,7.0))
	var chew:=bout*(.45+.55*grazing)*(0.2 if walking else 1.0)
	joint(root,"CowJaw",Vector3.RIGHT,(.025+.025*sin(time*6.5))*chew)
	joint(root,"CowEarL",Vector3.FORWARD,sin(time*11)*.13*pow(maxf(0,sin(time*.72)),12))
	joint(root,"CowEarR",Vector3.FORWARD,sin(time*10+.8)*.12*pow(maxf(0,sin(time*.72+2.1)),12))

static func pig(root:Node3D,time:float,walking:bool=false) -> void:
	# Preview-ready pig: nose searches the ground, ears react, curled tail sways.
	var sniff:=smoothstep(.5,1.2,fposmod(time,6.0))*(1.0-smoothstep(4.4,5.3,fposmod(time,6.0)))
	joint(root,"PigHead",Vector3.RIGHT,(.42+.028*sin(time*12))*sniff if not walking else .04*sin(time*5))
	joint(root,"PigEarL",Vector3.FORWARD,.08*sin(time*4.1))
	joint(root,"PigEarR",Vector3.FORWARD,.07*sin(time*4.1+1.3))
	joint(root,"PigTail",Vector3.UP,.18*sin(time*3))
	for key in ["LegFL","LegFR","LegBL","LegBR"]:
		var phase:float={"LegBL":0.0,"LegFL":PI*.5,"LegBR":PI,"LegFR":PI*1.5}[key]
		joint(root,key,Vector3.RIGHT,.22*sin(time*7+phase) if walking else 0.0)
