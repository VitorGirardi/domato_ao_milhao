class_name FarmVehicleTransition
extends RefCounted
## Door, body and grips share one reversible timeline. No physics root motion.
const POSES=preload("res://assets/animations/vehicle_entry.gd").FRAMES
const DURATION:=3.0
var active:=false
var exiting:=false
var elapsed:=0.0
var outside:=Vector3.ZERO
var origin:=Transform3D.IDENTITY

func begin(truck:FarmPickup,leaving:bool,at:Vector3) -> void:
	active=true;exiting=leaving;elapsed=0;outside=at
	origin=truck.game.avatar.global_transform

func apply(truck:FarmPickup,delta:float) -> bool:
	elapsed=minf(DURATION,elapsed+delta)
	var progress:=elapsed/DURATION
	var t:=1.0-progress if exiting else progress
	var game:Node3D=truck.game
	game.player.velocity=Vector3.ZERO
	game.actor.animate(0,false,false)
	var sit:=smoothstep(.35,.72,t)
	var approach:=smoothstep(0,.15,t)
	var at:=outside.lerp(truck.model.to_global(Vector3(-.53,.35,-.02)),sit)
	at.y+=sin(sit*PI)*.38
	var facing:=truck.global_basis*truck.model.basis
	if not exiting and t<.15:
		at=origin.origin.lerp(outside,approach)
		facing=origin.basis.orthonormalized().slerp(facing.orthonormalized(),approach)
	game.avatar.global_transform=Transform3D(facing,at)
	var sample:=t*(POSES.size()-1);var index:=mini(floori(sample),POSES.size()-2)
	for bone in POSES[index]:
		var a:Array=POSES[index][bone];var b:Array=POSES[index+1][bone]
		game.actor.pose_bone(bone,Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),sample-index))
	var door:=smoothstep(.12,.32,t)*(1.0-smoothstep(.72,.95,t))
	truck.driver_door.rotation.y=door*1.15
	# Reach the moving inner handle before pulling the door closed.
	var handle:=truck.driver_door.to_global(Vector3(-.085,.42,-1.445))
	var handle_weight:=smoothstep(.08,.2,t)*(1.0-smoothstep(.86,.98,t))
	game.actor.reach_rein_hand("L",handle,handle_weight)
	game.actor.reach_rein_hand("R",truck.model.to_global(Vector3(-.31,2.30,.50)),smoothstep(.55,.8,t))
	game.actor.reach_rein_hand("L",truck.model.to_global(Vector3(-.75,2.30,.50)),smoothstep(.88,1.0,t))
	return elapsed>=DURATION

func clear(truck:FarmPickup) -> void:
	active=false;elapsed=0
	if is_instance_valid(truck.driver_door):truck.driver_door.rotation.y=0
