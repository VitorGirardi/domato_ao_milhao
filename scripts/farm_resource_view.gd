class_name FarmResourceView
extends Node3D
## Blender props and feedback only; rewards live in the authoritative controller.
var game:Node3D
var ores:Array[Node3D]=[]
var ore_labels:Array[Label3D]=[]
var fish_labels:Array[Label3D]=[]
var props:Dictionary={}
var hint:Label
var meter:ProgressBar
var shop:Button
var elapsed:=0.0
var refresh_timer:=0.0

func setup(g:Node3D) -> void:
	game=g;name="ResourceView";process_priority=20
	shop=FarmGameUI.action(game.hud,game.hud.walking.root,"Peixes, minérios e ferramentas",Rect2(24,418,252,34),"resources")
	shop.add_theme_font_size_override("font_size",13)
	hint=game.hud.label(game.hud.walking.root,"",Vector2(420,678),Vector2(600,30),21,FarmHUD.CREAM)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color",Color("20392a"));hint.add_theme_constant_override("shadow_offset_y",2)
	meter=ProgressBar.new();meter.position=Vector2(470,713);meter.size=Vector2(500,14);meter.show_percentage=false
	meter.add_theme_stylebox_override("background",game.hud.style(Color("304c3d"),5,Color("78573b")))
	meter.add_theme_stylebox_override("fill",game.hud.style(Color("eabc5b"),5,Color("eabc5b")))
	game.hud.walking.root.add_child(meter)
	for i in range(3):
		var ore:=load("res://assets/models/resource_ore_%s.glb"%FarmResources.ORE_KEYS[i]).instantiate() as Node3D
		ore.position=FarmResourceSites.point(FarmResourceSites.ORE_SPOTS[i]);add_child(ore);ores.append(ore)
		var body:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=CylinderShape3D.new()
		shape.radius=.6;shape.height=.9;collision.shape=shape;collision.position.y=.45
		body.add_child(collision);ore.add_child(body)
		var label:=_label(FarmResources.NAMES[FarmResources.ORE_KEYS[i]],ore.position+Vector3(0,1.65,0));ore_labels.append(label)
	for i in range(3):
		var at:=FarmResourceSites.point(FarmResourceSites.FISH_SPOTS[i])
		fish_labels.append(_label("PESCA · E",at+Vector3(0,1.6,0)))
		var fish:=load("res://assets/models/resource_fish.glb").instantiate() as Node3D
		fish.position=at+Vector3(0,.9,0);fish.scale=Vector3.ONE*1.5;add_child(fish)
		var marker:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=.06;cylinder.bottom_radius=.08;cylinder.height=.85
		marker.mesh=cylinder;marker.position=at+Vector3(0,.4,0);var mat:=StandardMaterial3D.new();mat.albedo_color=Color("79553b");marker.material_override=mat;add_child(marker)
	refresh_world()

func _label(text:String,at:Vector3) -> Label3D:
	var label:=Label3D.new();label.text=text;label.position=at;label.font_size=34;label.pixel_size=.009
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("fff0c5");label.outline_size=8
	label.visibility_range_end=22;label.visibility_range_end_margin=5;add_child(label);return label

func refresh_world() -> void:
	if game==null:return
	var region:=game.world.landscape.get_node_or_null("ValeESerra") as FarmRegionScenery
	if region!=null:region.update_mine(game.state.resources.mine_owned)
	for i in range(ores.size()):
		var remaining:float=maxf(0,game.state.resources.node_ready[i]-game.state.elapsed)
		ores[i].visible=game.state.resources.mine_owned
		ore_labels[i].visible=game.state.resources.mine_owned
		ore_labels[i].text=FarmResources.NAMES[FarmResources.ORE_KEYS[i]]+(" · E" if remaining<=0 else " · %ds"%ceili(remaining))

func _new_prop(id:int,kind:String) -> Dictionary:
	var tool:=load("res://assets/models/resource_%s.glb"%("fishing_rod" if kind=="fish" else "pickaxe")).instantiate() as Node3D
	add_child(tool)
	var bobber:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.09;sphere.height=.18;bobber.mesh=sphere
	var material:=StandardMaterial3D.new();material.albedo_color=Color("f5ba55");bobber.material_override=material;add_child(bobber)
	var line:=MeshInstance3D.new();line.mesh=ImmediateMesh.new();var thread:=StandardMaterial3D.new();thread.albedo_color=Color("efe5c7");thread.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;line.material_override=thread;add_child(line)
	var entry:Dictionary={"kind":kind,"tool":tool,"bobber":bobber,"line":line};props[id]=entry;return entry

func _process(delta:float) -> void:
	if game==null:return
	elapsed+=delta;refresh_timer+=delta
	if refresh_timer>.2:refresh_timer=0;refresh_world()
	shop.visible=game.session_started and not game.build_mode and game.hud.modal_kind.is_empty()
	var own:int=game.gathering.own_id();var jobs:Dictionary=game.gathering.jobs
	for i in range(fish_labels.size()):fish_labels[i].visible=game.player.position.distance_to(FarmResourceSites.point(FarmResourceSites.FISH_SPOTS[i]))>2
	hint.visible=jobs.has(own) and game.hud.modal_kind.is_empty();meter.visible=hint.visible
	if hint.visible:
		var job:Dictionary=jobs[own]
		hint.text=("Pescando" if job.kind=="fish" else "Minerando")+" · %ds · E cancela"%ceili(job.remaining)
		meter.value=100*(1-float(job.remaining)/float(job.duration))
	for id in props.keys():
		if not jobs.has(id) or props[id].kind!=jobs[id].kind:
			for key in ["tool","bobber","line"]:props[id][key].queue_free()
			props.erase(id)
	for id in jobs:
		var a:FarmAvatar=game.actor if id==own else game.network.remote_actor
		if a==null or not is_instance_valid(a.root):continue
		var job:Dictionary=jobs[id];var entry:Dictionary=props[id] if props.has(id) else _new_prop(id,job.kind)
		var target:Vector3=FarmResourceSites.FISH_WATER[job.index] if job.kind=="fish" else FarmResourceSites.point(FarmResourceSites.ORE_SPOTS[job.index])+Vector3.UP*.7
		var direction:Vector3=target-a.root.global_position
		a.root.rotation.y=atan2(direction.x,direction.z)
		a.stop_emote();a.can.visible=false;a.carried_egg.visible=false
		var forward:=Vector3(direction.x,0,direction.z).normalized()
		var anchor:Vector3=a.root.global_position+Vector3.UP*1.25+forward*.6
		var swing:float=sin((float(job.duration)-float(job.remaining))*TAU*1.2)
		if job.kind=="mine":anchor+=Vector3.UP*(.35+.25*swing)
		a.reach_rein_hand("R",anchor,1);a.reach_rein_hand("L",anchor-forward*.14-Vector3.UP*.13,1)
		entry.tool.global_position=anchor
		entry.tool.global_basis=Basis(Vector3.UP,a.root.rotation.y)*Basis(Vector3.RIGHT,.85 if job.kind=="fish" else .75+swing*.85)
		entry.bobber.visible=job.kind=="fish";entry.line.visible=job.kind=="fish"
		if job.kind=="fish":
			entry.bobber.position=target+Vector3.UP*(.07+sin(elapsed*3)*.035)
			var mesh:ImmediateMesh=entry.line.mesh;mesh.clear_surfaces();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			mesh.surface_add_vertex(entry.tool.global_transform*Vector3(0,2,0));mesh.surface_add_vertex(entry.bobber.position);mesh.surface_end()
