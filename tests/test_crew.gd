extends SceneTree
var checks:=0
func check(ok:bool,why:String) -> void:
	checks+=1
	assert(ok,why)
func _initialize() -> void:
	var farm:=FarmState.new();farm.farm_xp=950
	farm.claim(Vector2.ZERO)
	farm.money=5000
	farm.place("coop",Vector2(-6,0),0)
	farm.place("plot",Vector2(0,0),0)
	farm.place("plot",Vector2(2,0),0)
	farm.hire_staff(0)
	var money:=farm.money
	check(farm.hire_field_staff().is_empty() and farm.money==money-120,"Second employee charges one hire")
	check(not farm.hire_field_staff().is_empty() and farm.money==money-120,"No duplicate hire")
	check(farm.configure_irrigation([1,2]).is_empty() and not farm.legacy_irrigation(),"Bento leaves Zeca available for coop")
	farm.items[0].flock.nest=4
	farm.tick(15)
	check(farm.inventory.egg==4 and farm.staff.services==1 and not farm.items[1].watered,"Coop continues while Bento has garden assignment")
	farm.pause_staff()
	money=farm.money
	check(farm.irrigate(1).is_empty() and farm.money==money-2 and farm.field_staff.watered==1,"Bento works while Zeca is paused")
	farm.pause_field_staff()
	check(not farm.irrigate(2).is_empty() and not farm.items[2].watered,"Bento pause is independent")
	farm.pause_staff()
	farm.items[0].flock.nest=2
	farm.tick(15)
	check(farm.inventory.egg==6,"Zeca works while Bento is paused")
	money=farm.money
	check(farm.train_worker("coop").is_empty() and farm.train_worker("field").is_empty() and farm.money==money-480,"Independent training costs")
	money=farm.money
	check(not farm.train_worker("field").is_empty() and farm.money==money,"No repeated training charge")
	farm.items[0].flock.nest=2
	farm.tick(10)
	check(farm.money==money-1 and farm.inventory.egg==8,"Trained Zeca completes service in ten seconds for one coin")
	farm.pause_field_staff()
	money=farm.money
	check(farm.irrigate(2).is_empty() and farm.money==money-1,"Trained Bento costs one coin per plot")
	check(FarmCrew.speed(farm.field_staff)>FarmCrew.speed(FarmCrew.fresh()),"Training accelerates movement and watering")
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))) and restored.field_staff==farm.field_staff and restored.staff.level==2,"Team levels, pauses, spending and assignments persist")
	var invalid:=farm.serialize()
	invalid.field_staff.level=3
	check(not restored.restore(invalid),"Invalid crew level rejected")
	invalid=farm.serialize(); invalid.field_staff.spent=-1
	check(not restored.restore(invalid),"Invalid crew ledger rejected")
	farm.items[1].watered=false
	farm.money=0
	check(not farm.irrigate(1).is_empty() and farm.field_staff.paused and not farm.staff.paused and farm.money==0,"Insufficient funds pauses only irrigation without overdraft")
	farm.dismiss_staff()
	check(farm.field_staff.hired and farm.irrigation.enabled,"Dismissing Zeca preserves Bento assignment")
	farm.money=10; farm.pause_field_staff()
	check(farm.irrigate(1).is_empty(),"Bento does not require an employed Zeca")
	farm.dismiss_field_staff()
	check(not farm.irrigation.enabled and farm.field_staff.level==2,"Dismissal stops irrigation and preserves training")
	var solo:=FarmState.new();solo.farm_xp=950
	solo.claim(Vector2.ZERO); solo.place("plot",Vector2.ZERO,0)
	check(solo.hire_field_staff().is_empty() and solo.configure_irrigation([0]).is_empty() and solo.irrigate(0).is_empty(),"Bento can be hired without a coop")
	var legacy:=solo.serialize()
	legacy.version=7; legacy.erase("field_staff"); legacy.irrigation.enabled=false
	check(restored.restore(legacy) and not restored.field_staff.hired,"Older saves never silently hire a second worker")
	print("CREW_STATE_OK: %d checks"%checks)
	quit()
