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
	shop=FarmGameUI.action(game.hud,game.hud.walking.root,"Recursos e ferramentas",Rect2(24,544,190,40),"resources")
	shop.add_theme_font_size_override("font_size",14);FarmWalkHUD.dim_shortcut(shop)
	shop.tooltip_text="Peixes, minérios e ferramentas"
	hint=game.hud.label(game.hud.walking.root,"",Vector2(420,678),Vector2(600,30),21,FarmHUD.CREAM)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color",Color("20392a"));hint.add_theme_constant_override("shadow_offset_y",2)
	meter=ProgressBar.new();meter.position=Vector2(470,713);meter.size=Vector2(500,14);meter.show_percentage=false
	meter.add_theme_stylebox_override("background",game.hud.style(Color("304c3d"),5,Color("78573b")))
	meter.add_theme_stylebox_override("fill",game.hud.style(Color("eabc5b"),5,Color("eabc5b")))
	game.hud.walking.root.add_child(meter)
	for i in range(FarmResources.NODE_COUNT):
		var ore:=load("res://assets/models/resource_ore_%s.glb"%FarmResources.NODE_ORES[i]).instantiate() as Node3D
		ore.position=FarmResourceSites.point(FarmResourceSites.ORE_SPOTS[i]);add_child(ore);ores.append(ore)
		var body:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=CylinderShape3D.new()
		shape.radius=.6;shape.height=.9;collision.shape=shape;collision.position.y=.45
		body.add_child(collision);ore.add_child(body)
		var label:=_label(FarmResources.NAMES[FarmResources.NODE_ORES[i]],ore.position+Vector3(0,1.65,0));ore_labels.append(label)
	for i in range(FarmResourceSites.FISH_SPOTS.size()):
		var at:=FarmResourceSites.point(FarmResourceSites.FISH_SPOTS[i])
		fish_labels.append(_label("PESCA · E",at+Vector3(0,1.6,0)))
		var marker:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=.06;cylinder.bottom_radius=.08;cylinder.height=.85
		marker.mesh=cylinder;marker.position=at+Vector3(0,.4,0);var mat:=StandardMaterial3D.new();mat.albedo_color=Color("79553b");marker.material_override=mat;add_child(marker)
	var life:=FarmCaveLife.new();add_child(life);life.setup(game)
	refresh_world()

func _label(text:String,at:Vector3) -> Label3D:
	var label:=Label3D.new();label.text=text;label.position=at;label.font_size=34;label.pixel_size=.009
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("fff0c5");label.outline_size=8
	label.visibility_range_end=22;label.visibility_range_end_margin=5;add_child(label);return label

func refresh_world() -> void:
	if game==null:return
	var region:=game.world.landscape.get_node_or_null("ValeESerra") as FarmRegionScenery
	if region!=null:
		region.update_mine(game.state.resources.mine_owned)
		region.update_galleries(game.state.resources.gallery_level)
		region.update_lights(game.player.position)
	for i in range(ores.size()):
		var remaining:float=maxf(0,game.state.resources.node_ready[i]-game.state.elapsed)
		ores[i].visible=game.state.resources.mine_owned
		ore_labels[i].visible=game.state.resources.mine_owned and game.state.resources.gallery_level>=FarmResources.NODE_LEVELS[i]
		ore_labels[i].text=FarmResources.NAMES[FarmResources.NODE_ORES[i]]+(" · E" if remaining<=0 else " · %ds"%ceili(remaining))

func _new_prop(id:int,kind:String) -> Dictionary:
	var tool:=load("res://assets/models/resource_%s.glb"%("fishing_rod" if kind=="fish" else "pickaxe")).instantiate() as Node3D
	add_child(tool)
	var bobber:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.09;sphere.height=.18;bobber.mesh=sphere
	var material:=StandardMaterial3D.new();material.albedo_color=Color("f5ba55");bobber.material_override=material;add_child(bobber)
	var line:=MeshInstance3D.new();line.mesh=ImmediateMesh.new();var thread:=StandardMaterial3D.new();thread.albedo_color=Color("efe5c7");thread.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;line.material_override=thread;add_child(line)
	var rings:=Node3D.new();rings.visible=false;add_child(rings)
	for i in range(3):
		var ring:=MeshInstance3D.new();var torus:=TorusMesh.new()
		torus.inner_radius=.91;torus.outer_radius=1.0;torus.rings=24;torus.ring_segments=6
		ring.mesh=torus;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var foam:=StandardMaterial3D.new();foam.albedo_color=Color(.78,.96,1,.7)
		foam.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;foam.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override=foam;rings.add_child(ring)
	var entry:Dictionary={"rings":rings,"kind":kind,"tool":tool,"bobber":bobber,"line":line,"last_time":-1.0,"actor":null};props[id]=entry;return entry

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
			var previous:FarmAvatar=props[id].actor
			if previous!=null and is_instance_valid(previous.root):previous.animate(1,false,false,false)
			for key in ["tool","bobber","line","rings"]:props[id][key].queue_free()
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
		entry.actor=a
		if job.kind=="mine":
			var seconds:float=float(job.duration)-float(job.remaining)
			var pose:=FarmMiningPose.apply(a,entry.tool,seconds,target)
			var contact_time:=FarmMiningPose.CONTACT*FarmMiningPose.PERIOD
			var hit:=floori((seconds-contact_time)/FarmMiningPose.PERIOD)
			var previous_hit:=floori((float(entry.last_time)-contact_time)/FarmMiningPose.PERIOD)
			if entry.last_time>=0 and hit>previous_hit and seconds-float(entry.last_time)<.35:
				_impact(pose.world_impact)
			entry.last_time=seconds
		else:
			a.reach_rein_hand("R",anchor,1);a.reach_rein_hand("L",anchor-forward*.14-Vector3.UP*.13,1)
			entry.tool.global_position=anchor
			entry.tool.global_basis=Basis(Vector3.UP,a.root.rotation.y)*Basis(Vector3.RIGHT,.85)
		entry.bobber.visible=job.kind=="fish";entry.line.visible=job.kind=="fish"
		if job.kind=="fish":
			_fishing_feedback(entry,job,target)
			var mesh:ImmediateMesh=entry.line.mesh;mesh.clear_surfaces();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			mesh.surface_add_vertex(entry.tool.global_transform*Vector3(0,2,0));mesh.surface_add_vertex(entry.bobber.position);mesh.surface_end()

func _impact(at:Vector3) -> void:
	# Brief chips at blade contact; no ongoing emitter after a cancelled job.
	for i in range(5):
		var chip:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3.ONE*.035
		chip.mesh=mesh;var material:=StandardMaterial3D.new();material.albedo_color=Color("b7a78c")
		chip.material_override=material;add_child(chip);chip.global_position=at
		var direction:=Vector3(cos(i*2.4)*.23,.15+float(i%3)*.06,sin(i*2.4)*.23)
		var tween:=create_tween();tween.set_parallel(true)
		tween.tween_property(chip,"position",at+direction,.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chip,"scale",Vector3.ONE*.05,.3)
		tween.chain().tween_callback(chip.queue_free)
	if game.player.global_position.distance_to(at)<12:
		game.audio.play_effect("step_2",-18,.65)

func _fishing_feedback(entry:Dictionary,job:Dictionary,target:Vector3) -> void:
	# All motion follows the replicated job clock; only FarmGathering grants fish.
	var seconds:float=float(job.duration)-float(job.remaining)
	var cast:=clampf(seconds/.65,0,1)
	var tip:Vector3=entry.tool.global_transform*Vector3(0,2,0)
	var biting:bool=job.remaining<=2.0
	var bob:=sin(seconds*(15.0 if biting else 3.0))*(.065 if biting else .025)
	var water:=target+Vector3.UP*(.07+bob)
	entry.bobber.position=tip.lerp(water,cast)+Vector3.UP*sin(cast*PI)*.8
	entry.rings.position=target+Vector3.UP*.035
	entry.rings.visible=cast>=1 and (seconds<2.15 or biting)
	var ripple_time:=seconds-.65 if not biting else seconds-(float(job.duration)-2.0)
	for i in range(entry.rings.get_child_count()):
		var ring:MeshInstance3D=entry.rings.get_child(i)
		var phase:=fposmod(ripple_time-float(i)*.27,1.15)/1.15
		var radius:=lerpf(.08,.66 if biting else .9,phase)
		ring.scale=Vector3(radius,.08,radius)
		ring.material_override.albedo_color.a=(1-phase)*.6
