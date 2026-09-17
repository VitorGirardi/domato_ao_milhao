extends SceneTree

func _initialize() -> void:
	var farm:=FarmState.new()
	farm.claim(Vector2.ZERO)
	farm.place("coop",Vector2.ZERO,0)
	var before:=farm.serialize()
	var motion:=FarmStaffMotion.new()
	motion.plan(Vector3(-4,0,0),Vector3(4,0,0),farm)
	assert(not motion.blocked and motion.path.size()>10)
	var length:=0.0
	for i in range(motion.path.size()):
		assert(motion.walkable(motion.path[i],farm))
		if i>0: length+=motion.path[i].distance_to(motion.path[i-1])
	assert(length>8.0,"Route must go around the coop")
	motion.plan(Vector3(-4,0,0),Vector3.ZERO,farm)
	assert(motion.blocked and motion.path.is_empty(),"Occupied destination must not be crossed")
	assert(farm.serialize()==before,"Visual route must never charge or change inventory")
	farm.hire_staff(0)
	farm.items[0].flock.nest=4
	var money:=farm.money
	farm.staff_accessible=false
	farm.tick(15)
	assert(farm.money==money and farm.inventory.egg==0 and farm.staff.services==0)
	farm.staff_accessible=true
	farm.tick(15)
	assert(farm.money==money-2 and farm.inventory.egg==4 and farm.staff.services==1)
	print("V09_NAVIGATION_OK: detour, clearance, blocked target, unchanged economy")
	quit()
