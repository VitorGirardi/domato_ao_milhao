class_name FarmCaveLife
extends Node3D

var game:Node3D
var creatures:Array[FarmCaveCreature]=[]
var labels:Array[Label3D]=[]
var visual_progress:=[0.0,0.0,0.0]

func setup(g:Node3D) -> void:
	game=g;name="CaveLife"
	for i in range(3):
		var creature:=FarmCaveCreature.new();creature.setup(self,i);creatures.append(creature)
		creature.root.position=FarmResourceSites.point(FarmCaveCrew.DENS[i])
		var label:=Label3D.new();label.position=creature.root.position+Vector3.UP*(2.3+i*.55)
		label.text=FarmCaveCrew.NAMES[i]+" · E";label.font_size=32;label.pixel_size=.008
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.visibility_range_end=14
		label.outline_size=8;add_child(label);labels.append(label)
		prop("tools",FarmCaveCrew.DENS[i]+Vector2(-1,0),0,.65)
		prop(["ore_copper","ore_iron","crystals"][i],FarmCaveCrew.WORK[i]+Vector2(0,-.8),0,.6)
	# All dressing stays at the sides or above headroom; the walking lane is clear.
	for i in range(FarmMineLayout.CELLS.size()):
		var cell:Vector2=FarmMineLayout.CELLS[i]
		var at:=Vector2(FarmMineLayout.ORIGIN.x,FarmMineLayout.ORIGIN.z)+cell
		if i%3==0:
			prop("stalactites",at+Vector2(2,1),5.3,.58)
		if cell.y>-36 and i%3==1:prop("roots",at+Vector2(-2,0),5.2,.6)
		if cell.y<=-24 and cell.y>-56 and i%2==0:prop("fungi",at+Vector2(2.7,1.5),0,.8)
		if cell.y<=-56 and i%2==0:prop("crystals",at+Vector2(3,2),0,.5)
		if cell.y>-24 and i%4==0:prop("support",at,0,.95)

func prop(kind:String,at:Vector2,height:float,size_scale:float) -> void:
	var model:=load("res://assets/models/cave_detail_%s.glb"%kind).instantiate() as Node3D
	model.position=FarmResourceSites.point(at)+Vector3.UP*height
	model.scale=Vector3.ONE*size_scale;add_child(model)

func _process(delta:float) -> void:
	if game==null:return
	for i in range(3):
		var creature:=creatures[i]
		var entry:Dictionary=game.state.cave_crew[i]
		creature.root.visible=game.state.resources.mine_owned and game.state.resources.gallery_level>=i
		labels[i].visible=creature.root.visible
		var active:=FarmCaveCrew.active(game.state,i)
		var progress:float=entry.progress
		# The visitor receives farm clocks twice a second. Interpolate the visual
		# clock so walking never alternates a short sprint and a network wait.
		if active and game.network.active and not game.network.hosting:
			var predicted:float=fposmod(float(visual_progress[i])+delta,FarmCaveCrew.PERIOD)
			var correction:=fposmod(progress-predicted+60,120)-60
			visual_progress[i]=progress if absf(correction)>1 else fposmod(predicted+correction*(1-exp(-delta*2)),120)
			progress=visual_progress[i]
		else:visual_progress[i]=progress
		var weight:=clampf(progress/8,0,1) if progress<96 else 1-clampf((progress-96)/8,0,1)
		if not active:weight=0
		var target:=FarmResourceSites.point(FarmCaveCrew.DENS[i].lerp(FarmCaveCrew.WORK[i],weight))
		var previous:=creature.root.position
		creature.root.position=previous.move_toward(target,delta*.75)
		var travel:=creature.root.position-previous
		var distance:=Vector2(travel.x,travel.z).length()
		var mining:=active and progress>=8 and progress<96 and creature.root.position.distance_to(target)<.12
		var facing:=travel if distance>.001 else Vector3(0,0,-1) if mining else Vector3(0,0,1)
		creature.root.rotation.y=lerp_angle(creature.root.rotation.y,atan2(facing.x,facing.z),1-exp(-delta*5))
		if mining:creature.clock=progress
		creature.animate(delta,distance,mining,active and progress>=96 and progress<106)
		labels[i].text=FarmCaveCrew.NAMES[i]+(" · com fome" if entry.joined and entry.fuel<=0 else " · E")

	if game.hud.modal_kind=="cave_helper" and is_instance_valid(game.hud.modal):
		var panel:Control=game.hud.modal
		var i:int=panel.get_meta("helper",0)
		var entry:Dictionary=game.state.cave_crew[i]
		if entry.joined and panel.has_meta("cave_status"):
			var status:="Pausado" if entry.paused else "Com fome" if entry.fuel<=0 else "Trabalhando" if FarmCaveCrew.active(game.state,i) else "Estoque cheio"
			panel.get_meta("cave_status").text=status+" · comida: %d min · entregues: %d"%[ceili(entry.fuel/60),entry.produced]
