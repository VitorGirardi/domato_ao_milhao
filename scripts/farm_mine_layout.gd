class_name FarmMineLayout
extends RefCounted
## Shared authored footprint; Blender uses the same cells with depth = -z.
const ORIGIN := Vector3(900,81,-220)
const CELLS := [Vector2(0,-4),Vector2(0,-12),Vector2(0,-20),Vector2(-8,-20),Vector2(-16,-20),Vector2(-16,-28),Vector2(-16,-36),Vector2(-8,-36),Vector2(0,-36),Vector2(8,-36),Vector2(16,-36),Vector2(16,-44),Vector2(16,-52),Vector2(8,-52),Vector2(0,-52),Vector2(0,-60),Vector2(0,-68)]
const GALLERY_AT := [Vector2(900,-233),Vector2(909,-256)]
const GATES := [Vector3(0,0,-16),Vector3(12,0,-36)]
const TITLES := ["Galeria do Ferro", "Salão dos Cristais"]

static func inside(p:Vector2, margin:float=0.0) -> bool:
	var local:=p-Vector2(ORIGIN.x,ORIGIN.z)
	for cell in CELLS:
		if absf(local.x-cell.x)<=4+margin and absf(local.y-cell.y)<=4+margin:return true
	return false

static func clearance(p:Vector2) -> float:
	# Fast rejection matters: this runs for every terrain sample in the region.
	if p.x<866 or p.x>934 or p.y < -306 or p.y > -206:return 100.0
	var local:=p-Vector2(ORIGIN.x,ORIGIN.z)
	var distance:=100.0
	for cell in CELLS:distance=minf(distance,maxf(absf(local.x-cell.x)-6,absf(local.y-cell.y)-6))
	return distance
