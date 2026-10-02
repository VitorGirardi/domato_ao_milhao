class_name FarmShoulderCamera
extends RefCounted

var side:=1.0

func compose(player:Vector3,normal_target:Vector3,normal_distance:float,normal_pitch:float,yaw:float,blend:float,requested_side:float,aim_pitch:float,delta:float,immediate:bool=false) -> Dictionary:
	side=requested_side if immediate else lerpf(side,requested_side,1.0-exp(-delta*12.0))
	var right:=Vector3(cos(yaw),0,-sin(yaw))
	var anchor:=normal_target.lerp(player+Vector3.UP*1.95,blend)
	var target:=anchor+right*.95*side*blend
	var distance:=lerpf(normal_distance,3.2,blend)
	var angle:=lerpf(normal_pitch,clampf(aim_pitch,-.6,.8),blend)
	return {"anchor":anchor,"target":target,"offset":Vector3(sin(yaw)*cos(angle),sin(angle),cos(yaw)*cos(angle))*distance}
