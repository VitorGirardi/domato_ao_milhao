extends SceneTree
var checks:=0
func check(ok:bool,why:String) -> void:
	checks+=1
	assert(ok,why)
func _initialize() -> void:
	var farm:=FarmState.new()
	farm.claim(Vector2.ZERO)
	farm.place("coop",Vector2(-6,0),0)
	farm.place("plot",Vector2(0,0),0)
	farm.place("plot",Vector2(2,0),0)
	farm.place("barn",Vector2(6,6),0)
	check(not farm.buy_watering_upgrade().is_empty(),"Barn cannot buy upgrades")
	check(not farm.configure_irrigation([1]).is_empty(),"Requires employee")
	farm.hire_staff(0)
	var before:=farm.serialize()
	check(not farm.configure_irrigation([]).is_empty() and farm.serialize()==before,"Empty selection leaves state intact")
	check(not farm.configure_irrigation([3]).is_empty() and farm.serialize()==before,"Reject non-plots")
	check(farm.configure_irrigation([1,2,1]).is_empty() and farm.irrigation.plots.size()==2,"Selection deduplicates")
	var money:=farm.money
	check(farm.irrigate(1).is_empty() and farm.money==money-2 and farm.items[1].watered,"Charge once on completion")
	check(not farm.irrigate(1).is_empty() and farm.money==money-2,"Cannot charge already watered crop")
	farm.items[0].flock.nest=4
	farm.tick(15)
	check(farm.items[0].flock.nest==4 and farm.staff.services==0,"Irrigation suspends coop service")
	farm.money=1
	check(not farm.irrigate(2).is_empty() and farm.staff.paused and not farm.items[2].watered and farm.money==1,"No partial charge at insufficient funds")
	farm.money=20
	farm.pause_staff()
	check(farm.irrigate(2).is_empty() and farm.money==18,"Explicit resume then watering")
	var saved:=farm.serialize()
	var loaded:=FarmState.new()
	check(loaded.restore(JSON.parse_string(JSON.stringify(saved))) and loaded.irrigation==farm.irrigation,"Schema 6 roundtrip")
	var invalid:=saved.duplicate(true)
	invalid.irrigation.plots=[0]
	check(not loaded.restore(invalid) and loaded.irrigation==farm.irrigation,"Invalid selection is atomic")
	invalid=saved.duplicate(true); invalid.irrigation.spent=-2
	check(not loaded.restore(invalid),"Reject negative totals")
	var legacy:=saved.duplicate(true)
	legacy.version=5; legacy.erase("irrigation"); legacy.watering_upgrade=true
	check(loaded.restore(legacy) and not loaded.irrigation.enabled and loaded.watering_upgrade,"Old save keeps purchased upgrade and starts with irrigation off")
	check(farm.remove_item(1).is_empty() and farm.irrigation.plots==[1],"Removing plot remaps selection")
	var removal:=FarmState.new()
	assert(removal.restore(farm.serialize()))
	check(removal.remove_item(1).is_empty() and not removal.irrigation.enabled and removal.staff.paused,"Removing last selected plot pauses worker instead of silently charging coop care")
	assert(removal.restore(farm.serialize()))
	removal.items[0].flock.nest=0
	assert(removal.remove_item(0).is_empty())
	assert(not removal.configure_irrigation([0]).is_empty() and removal.staff.paused)
	assert(FarmState.new().restore(removal.serialize()),"Removed home coop preserves a valid paused save")
	farm.assign_staff(0)
	check(not farm.irrigation.enabled,"Return to coop stops watering")
	check(farm.place("workshop",Vector2(-6,6),0).is_empty()==false,"Workshop respects available budget")
	farm.money=700
	check(farm.place("workshop",Vector2(-6,6),0).is_empty(),"Build workshop")
	assert(farm.paint_item(farm.items.size()-1,"walls",2).is_empty())
	assert(farm.paint_item(farm.items.size()-1,"roof",4).is_empty())
	assert(not farm.paint_item(farm.items.size()-1,"door",1).is_empty())
	money=farm.money
	check(farm.buy_watering_upgrade().is_empty() and farm.money==money-300,"Workshop charges upgrade once")
	check(not farm.buy_watering_upgrade().is_empty() and farm.money==money-300,"No repeat purchase")
	farm.remove_item(farm.items.size()-1)
	check(farm.watering_upgrade,"Removing workshop preserves acquired improvement")
	print("V010_STATE_OK: %d checks"%checks)
	quit()
