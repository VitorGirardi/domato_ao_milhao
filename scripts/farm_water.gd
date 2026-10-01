class_name FarmWater
extends RefCounted
## Depth uses the actual terrain triangles, never an invisible water collider.
static func depth(at:Vector3) -> float:
	var p:=Vector2(at.x,at.z)
	var level:=FarmRegion.water_level(p)
	if level==-INF or (FarmRegion.on_bridge(p) and at.y>3.5):return 0.0
	return maxf(0,level-FarmLandscape.ground_height(p))

static func swimming_at(at:Vector3) -> bool:
	return depth(at)>1.35 and at.y<FarmRegion.water_level(Vector2(at.x,at.z))-.65

static func immersion(at:Vector3) -> float:
	if depth(at)<=0:return 0.0
	return maxf(0,FarmRegion.water_level(Vector2(at.x,at.z))-at.y)

static func velocity(at:Vector3,current:Vector3,direction:Vector3,delta:float,running:bool) -> Vector3:
	var immersed:=immersion(at)
	var swimming:=swimming_at(at)
	var speed:= (3.5 if running else 2.5) if swimming else lerpf(7.5 if running else 4.5,2.1,clampf(immersed/1.3,0,1))
	var wanted:=direction*speed
	if swimming and FarmRegion.river_distance(Vector2(at.x,at.z))<19:wanted.z+=.45
	var result:=current
	var response:=1-exp(-delta*(5.0 if swimming else 18.0))
	result.x=lerpf(current.x,wanted.x,response);result.z=lerpf(current.z,wanted.z,response)
	if swimming:
		var target:=FarmRegion.water_level(Vector2(at.x,at.z))-1.15
		result.y+=((target-at.y)*22.0-result.y*8.0)*delta
		result.y=clampf(result.y,-3.0,2.5)
	else:result.y-=18.0*delta
	return result
