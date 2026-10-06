extends "res://tests/test_animal_care.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var s:=fixture();s.items[1].dairy.owned=false;s.items[2].pigs.count=0;s.inventory.egg=6
	var old:=s.serialize();var money:=s.money
	for i in range(3):assert(FarmYoung.adopt(s,i).is_empty())
	assert(s.money==money-720 and s.stock("egg")==0)
	assert(s.items[0].flock.names.size()==6 and FarmYoung.adults(s.items[0])==3)
	assert(FarmYoung.progress(s.items[1])==0 and s.items[2].pigs.count==1)
	assert(not FarmYoung.adopt(s,0).is_empty() and not FarmYoung.adopt(s,1).is_empty())
	assert(FarmPigs.care(s,2,"buy").is_empty() and FarmYoung.progress(s.items[2],1)==1)
	assert(FarmYoung.adopt(s,2).is_empty());assert(not FarmYoung.adopt(s,2).is_empty())
	assert(FarmCoop.save_farm("user://young.json",s))
	var loaded:=FarmCoop.load_farm("user://young.json");assert(loaded!=null)
	for i in range(3):assert(loaded.items[i].young_ages==s.items[i].young_ages)
	# Mature boundaries, supply depletion, and comfort expiry agree at different frame rates.
	for i in range(3):
		var a:Dictionary=s.items[i].duplicate(true)
		for j in range(a.young_ages.size()):
			if FarmYoung.progress(a,j)<1:a.young_ages[j]=FarmYoung.DURATIONS[a.kind]-12.5
		a.animal_care={"seconds":17.25,"visits":1}
		FarmAnimalCare.needs(a).food=20.;FarmAnimalCare.needs(a).water=25.
		var b:=a.duplicate(true)
		FarmAnimalCare.tick(a,120)
		for f in range(1200):FarmAnimalCare.tick(b,.1)
		for j in range(a.young_ages.size()):assert(is_equal_approx(a.young_ages[j],b.young_ages[j]))
		if i==0:assert(a.flock.nest==b.flock.nest and is_equal_approx(a.egg_time,b.egg_time))
		if i==1:assert(a.dairy.milk==b.dairy.milk and is_equal_approx(a.dairy.timer,b.dairy.timer))
		assert(is_equal_approx(FarmAnimalCare.needs(a).food,FarmAnimalCare.needs(b).food))
	# Young animals consume supplies, never produce early; no water pauses growth.
	var calf:Dictionary=s.items[1];FarmAnimalCare.tick(calf,60)
	assert(calf.dairy.milk==0 and calf.dairy.timer==0 and calf.young_ages[0]==60)
	calf.dairy.water=0;FarmAnimalCare.tick(calf,100);assert(calf.young_ages[0]==60)
	calf.dairy.water=100;calf.dairy.food=100;calf.young_ages[0]=1430.
	FarmAnimalCare.tick(calf,70);assert(calf.dairy.milk==2 and FarmYoung.progress(calf)==1)
	assert(loaded.restore(old))
	for item in loaded.items:assert(not item.has("young_ages") and not FarmYoung.growing(item))
	for value in [null,{},[],[0.0],[480,480,-1],[480,480,NAN],[480,480,true],[480,480,481]]:
		var bad:=old.duplicate(true);bad.items[0].young_ages=value
		var before:=loaded.serialize();assert(not loaded.restore(bad) and loaded.serialize()==before)
	var bad:=s.serialize();bad.items[1].young_ages=[0.];assert(not loaded.restore(bad))
	assert(s.move_item(2,Vector2(13,8),1).is_empty());assert(s.items[2].young_ages.size()==3)
	for c in [{"action":"young:adopt","index":-1},{"action":"young:adopt","index":1.5},{"action":"young:cheat","index":1}]:assert(not FarmCoopCommands.run(s,c).is_empty())
	var sandbox:=fixture("sandbox");sandbox.items[1].dairy.owned=false
	assert(FarmYoung.adopt(sandbox,1).is_empty() and sandbox.unlimited_money and sandbox.infinite_resources())
	# Gait follows distance at different frame rates and settles when blocked.
	var phases:Array=[]
	for fps in [30,60,120]:
		var node:=Node3D.new();node.scale=Vector3.ONE*.43
		var gait:Dictionary
		for f in range(fps*2):
			var before:=node.position;node.position.x+=.3/fps
			gait=FarmYoungVisual.stride(node,before,1.0/fps,.62)
		phases.append(gait.phase)
		var held:float=gait.phase
		for f in range(fps):gait=FarmYoungVisual.stride(node,node.position,1.0/fps,.62)
		assert(gait.phase==held and gait.blend<.001)
		node.free()
	assert(is_equal_approx(phases[0],phases[1]) and is_equal_approx(phases[1],phases[2]))
	print("YOUNG_OK: acquisition, adult alternatives, costs, saves, old farms, frame invariance, growth pause, production boundary, invalid snapshots, move and sandbox")
	quit()
