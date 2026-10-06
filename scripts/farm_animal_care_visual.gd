class_name FarmAnimalCareVisual
extends RefCounted

static func update(root:Node3D,item:Dictionary,elapsed:float,highlighted:bool) -> void:
	var badge:=root.get_node_or_null("AnimalComfort") as Label3D
	if not badge:
		badge=Label3D.new();badge.name="AnimalComfort";root.add_child(badge)
		badge.position.y=4.0 if item.kind=="coop" else 3.2
		badge.font_size=28;badge.pixel_size=.007
		badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED;badge.outline_modulate=Color("294739")
	var active:=FarmAnimalCare.seconds(item)>0
	badge.visible=FarmAnimalCare.count(item)>0 and (highlighted or active)
	badge.text=("♡ Conforto" if active else "")+(" · " if active and highlighted else "")+(FarmAnimalCare.activity(item,elapsed) if highlighted else "")
	badge.modulate=Color("d8efbc")

	# The existing mud patch visibly becomes damp, without changing its collision.
	if item.kind=="pigsty" and root.get_meta("comfort_wet",-1)!=int(active):
		root.set_meta("comfort_wet",int(active))
		var mud:=root.find_child("MudSurface",true,false) as MeshInstance3D
		if mud:
			if active:
				var source:=mud.mesh.surface_get_material(0) as StandardMaterial3D
				if source:
					var wet:=source.duplicate() as StandardMaterial3D
					wet.albedo_color=source.albedo_color.darkened(.22);wet.roughness=.3
					mud.material_override=wet
			else:mud.material_override=null
