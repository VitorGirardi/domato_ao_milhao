extends SceneTree

# Interpolate the actual terrain grid, rather than only checking the height function.
func terrain_surface(p:Vector2) -> float:
	var x:float=floor(p.x*2)/2;var z:float=floor(p.y)
	var u:float=(p.x-x)*2;var v:float=p.y-z
	var a:=FarmLandscape.height_at(Vector2(x,z))
	var b:=FarmLandscape.height_at(Vector2(x+.5,z))
	var c:=FarmLandscape.height_at(Vector2(x,z+1))
	var d:=FarmLandscape.height_at(Vector2(x+.5,z+1))
	return a+(b-a)*u+(c-a)*v if u+v<=1 else d+(c-d)*(1-u)+(b-d)*(1-v)

func _initialize() -> void:
	var landscape:=FarmLandscape.new()
	landscape._river()
	var water:MeshInstance3D=landscape.get_node("LivingRiver")
	var vertices:PackedVector3Array=water.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for i in range(0,vertices.size(),6):
		for t in [0.0,.25,.5,.75,1.0]:
			var left:Vector3=vertices[i].lerp(vertices[i+2],t)
			var right:Vector3=vertices[i+1].lerp(vertices[i+4],t)
			assert(terrain_surface(Vector2(left.x,left.z))>left.y+.05,"Exposed left water edge")
			assert(terrain_surface(Vector2(right.x,right.z))>right.y+.05,"Exposed right water edge")
			var middle:Vector3=(left+right)/2
			assert(terrain_surface(Vector2(middle.x,middle.z))<middle.y-.4,"River bed above water")
	landscape.meadow.free();landscape.nature.free();landscape.free()
	print("RIVER_BANKS_OK: both mesh edges buried along full river; channel remains submerged")
	quit()
