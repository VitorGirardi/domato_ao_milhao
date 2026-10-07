class_name FarmMineLayout
extends RefCounted
## Shared authored footprint; Blender uses the same cells with depth = -z.
const ORIGIN := Vector3(900,81,-220)
const CELLS := [Vector2(0,-4),Vector2(0,-12),Vector2(0,-20),Vector2(-8,-20),Vector2(-16,-20),Vector2(-16,-28),Vector2(-16,-36),Vector2(-8,-36),Vector2(0,-36),Vector2(8,-36),Vector2(16,-36),Vector2(16,-44),Vector2(16,-52),Vector2(8,-52),Vector2(0,-52),Vector2(0,-60),Vector2(0,-68),Vector2(0,-76),Vector2(8,-76),Vector2(16,-76),Vector2(16,-84),Vector2(16,-92),Vector2(8,-92),Vector2(0,-92),Vector2(-8,-92),Vector2(-16,-92),Vector2(-16,-100),Vector2(-8,-100),Vector2(0,-100)]
const GALLERY_AT := [Vector2(900,-233),Vector2(909,-256)]
const GATES := [Vector3(0,0,-16),Vector3(12,0,-36)]
const TITLES := ["Galeria do Ferro", "Salão dos Cristais"]

static func floor_offset(local_z:float) -> float:
	var depth:float=-local_z
	return -clampf(depth-16,0,16)*.375-clampf(depth-40,0,16)*.5-clampf(depth-80,0,16)*.5

static func floor_y(p:Vector2) -> float:
	return ORIGIN.y+floor_offset(p.y-ORIGIN.z)

static func inside(p:Vector2, margin:float=0.0) -> bool:
	# Height queries cover the entire valley, while the mine occupies a tiny part.
	if p.x<880-margin or p.x>920+margin or p.y< -324-margin or p.y> -220+margin:return false
	var local:=p-Vector2(ORIGIN.x,ORIGIN.z)
	for cell in CELLS:
		if absf(local.x-cell.x)<=4+margin and absf(local.y-cell.y)<=4+margin:return true
	return false

static func clearance(p:Vector2) -> float:
	# Fast rejection matters: this runs for every terrain sample in the region.
	if p.x<866 or p.x>934 or p.y < -340 or p.y > -206:return 100.0
	var local:=p-Vector2(ORIGIN.x,ORIGIN.z)
	var distance:=100.0
	# The ground mesh samples columns every 6m; clear those surrounding samples
	# as well so interpolated grass cannot poke through the gallery floor.
	for cell in CELLS:distance=minf(distance,maxf(absf(local.x-cell.x)-10,absf(local.y-cell.y)-10))
	return distance

static func interior_weight(observer:Vector3) -> float:
	var p:=Vector2(observer.x,observer.z)
	if not inside(p) or observer.y<floor_y(p)-1 or observer.y>floor_y(p)+7:return 0.0
	return smoothstep(2,10,-220-observer.z)
