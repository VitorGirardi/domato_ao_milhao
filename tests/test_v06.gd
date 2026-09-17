extends SceneTree

var checks:=0
var failures:=0

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error("FAILED: "+message)

func setup_farm() -> FarmState:
	var farm:=FarmState.new()
	farm.claim(Vector2(4,0))
	farm.place("coop",Vector2(0,0),0)
	farm.place("coop",Vector2(8,0),0)
	farm.place("barn",Vector2(0,-7),0)
	farm.reserve.egg=5
	return farm

func _initialize() -> void:
	var farm:=FarmState.new()
	check(not farm.staff.hired and farm.staff.paused,"No employee or costs in a new farm")
	check(not farm.hire_staff(0).is_empty(),"Hiring requires a coop on owned land")
	farm=setup_farm()
	var snapshot:=farm.serialize()
	for index in [-1,2,99]: check(not farm.hire_staff(index).is_empty() and farm.serialize()==snapshot,"Invalid workplace cannot charge")
	farm.money=119
	snapshot=farm.serialize()
	check(not farm.hire_staff(0).is_empty() and farm.serialize()==snapshot,"Cannot hire below visible hiring price")
	farm.money=400
	check(farm.hire_staff(0).is_empty() and farm.money==280 and farm.staff.spent==120,"Hiring charges exactly 120")
	check(FarmStaff.running(farm.staff) and farm.staff.coop==0,"Hiring activates chosen workplace")
	snapshot=farm.serialize()
	check(not farm.hire_staff(1).is_empty() and farm.serialize()==snapshot,"Repeated hire cannot double charge or reassign")
	check(FarmStaff.quote(farm.items[0].flock)==0,"Full supplies and empty nest have no service fee")
	farm.tick(15)
	check(farm.money==280 and farm.staff.services==0,"Idle check is free")
	var flock:Dictionary=farm.items[0].flock
	flock.nest=4
	var other_before:Dictionary=farm.items[1].flock.duplicate(true)
	farm.tick(14)
	check(farm.inventory.egg==0 and flock.nest==4,"No early collection before interval")
	farm.tick(1)
	check(farm.inventory.egg==4 and flock.nest==0 and farm.money==278,"Service transfers eggs once for 2 coins")
	check(farm.staff.eggs==4 and farm.staff.services==1,"Ledger counts actual completed work")
	check(farm.reserve.egg==5 and farm.items[1].flock.nest==other_before.nest,"Reserve and other coop remain uncollected")
	FarmStaff.service(farm)
	check(farm.money==278 and farm.inventory.egg==4,"Empty repeat service neither charges nor duplicates eggs")
	flock.food=10
	flock.water=20
	flock.nest=6
	check(FarmStaff.quote(flock)==10,"Combined fee includes 2 service and exact 8 feed")
	FarmStaff.service(farm)
	check(flock.food==100 and flock.water==100 and flock.nest==0,"Combined care refills and collects atomically")
	check(farm.money==268 and farm.inventory.egg==10 and farm.staff.spent==132,"Care and hiring ledger reconcile with money")
	flock.water=25
	check(FarmStaff.quote(flock)==2,"Water-only work charges service but no water price")
	FarmStaff.service(farm)
	check(flock.water==100 and farm.money==266,"Water-only service works")
	flock.food=25
	check(FarmStaff.quote(flock)==8,"Threshold 25 includes exact six-coin feed refill")
	flock.food=25.1
	check(FarmStaff.quote(flock)==0,"No unnecessary refill above threshold")
	flock.food=0
	flock.water=0
	flock.nest=12
	farm.money=9
	var before_flock:=flock.duplicate(true)
	var before_inventory:=farm.inventory.duplicate()
	FarmStaff.service(farm)
	check(farm.money==9 and flock==before_flock and farm.inventory==before_inventory,"Insufficient service funds preserve entire transaction")
	check(farm.staff.paused and farm.staff.reason=="funds" and not farm.staff_notice.is_empty(),"Insufficient funds pause with explicit reason")
	farm.money=100
	farm.tick(15)
	check(farm.money==100 and farm.inventory==before_inventory,"Adding money never silently resumes charges")
	check(farm.pause_staff().is_empty() and not farm.staff.paused,"Player explicitly resumes")
	farm.tick(15)
	check(farm.money==90 and farm.inventory.egg==22,"Resumed caretaker completes pending care exactly once")
	farm.tick(7)
	var timer:float=farm.staff.timer
	check(farm.pause_staff().is_empty() and farm.staff.paused,"Manual pause works")
	var ledger:=farm.staff.duplicate(true)
	snapshot=farm.serialize()
	FarmStaff.service(farm)
	check(farm.serialize()==snapshot,"Service cannot bypass a manual pause")
	farm.tick(50)
	check(farm.staff==ledger and farm.money==90,"Paused employee preserves timer and ledger without costs")
	check(farm.items[0].flock.nest>0,"Farm production continues while employee is manually paused")
	check(farm.pause_staff().is_empty() and farm.staff.timer==timer,"Resume preserves partial interval")
	farm.tick(8)
	check(farm.staff.timer==0 and farm.staff.services==5,"Only remaining time is needed after pause")
	snapshot=farm.serialize()
	for index in [-1,2,30]: check(not farm.assign_staff(index).is_empty() and farm.serialize()==snapshot,"Reject invalid reassignment atomically")
	check(farm.assign_staff(1).is_empty() and farm.staff.coop==1 and farm.staff.timer==0,"Workplace change is free and resets check interval")
	farm.items[0].flock.nest=6
	farm.items[1].flock.nest=4
	farm.items[1].egg_time=0.0
	var before_eggs:int=farm.inventory.egg
	farm.tick(15)
	check(farm.inventory.egg==before_eggs+4 and farm.items[0].flock.nest>=6,"Only assigned coop is collected")
	check(farm.move_item(1,Vector2(10,6),1).is_empty() and farm.staff.coop==1,"Moving and rotating workplace preserve assignment")
	farm.items[0].flock.nest=0
	check(farm.remove_item(0).is_empty() and farm.staff.coop==0 and farm.items[0].x==10,"Removing earlier item adjusts workplace index")
	farm.items[0].flock.nest=2
	snapshot=farm.serialize()
	check(not farm.remove_item(0).is_empty() and farm.serialize()==snapshot,"Protected nest prevents workplace removal and employee mutation")
	farm.care_coop(0,"collect")
	check(farm.remove_item(0).is_empty() and farm.staff.coop==-1 and farm.staff.paused,"Removing empty workplace automatically pauses employee")
	check(not farm.pause_staff().is_empty() and farm.staff.paused,"Cannot resume without a workplace")
	farm.place("coop",Vector2(8,0),0)
	check(farm.assign_staff(1).is_empty() and farm.staff.paused,"Replacement workplace still requires explicit resume")
	farm.pause_staff()
	farm.tick(4.25)
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize(),"",true,true))),"Employee state round trips through JSON")
	check(restored.staff==farm.staff and restored.money==farm.money,"Timer, assigned coop and ledger survive reload without costs")
	snapshot=farm.serialize()
	farm.dismiss_staff()
	check(not farm.staff.hired and farm.staff.paused and farm.staff.coop==-1,"Dismiss ends employment")
	check(farm.money==snapshot.money and farm.items==snapshot.items and farm.inventory==snapshot.inventory,"Dismiss is free and preserves farm products")
	check(farm.staff.services==snapshot.staff.services and farm.staff.spent==snapshot.staff.spent,"Lifetime ledger survives dismissal")
	snapshot=farm.serialize()
	FarmStaff.service(farm)
	check(farm.serialize()==snapshot,"Dismissed employee cannot perform a stray service call")
	farm.tick(60)
	check(farm.money==snapshot.money,"Dismissed employee never charges")
	farm.money=200
	check(farm.hire_staff(1).is_empty() and farm.money==80,"Rehiring charges disclosed 120 again")
	check(farm.staff.spent==snapshot.staff.spent+120,"Rehire adds to lifetime cost ledger")
	var large:=setup_farm()
	large.money=1000
	large.hire_staff(0)
	large.items[0].flock.food=12
	large.items[0].flock.water=17
	var small:=FarmState.new()
	small.restore(large.serialize())
	large.tick(600)
	for i in range(2400): small.tick(0.25)
	check(large.money==small.money and large.inventory==small.inventory,"Large and small ticks agree on payments and production")
	check(large.staff==small.staff,"Large and small ticks agree on employee ledger")
	check(is_equal_approx(large.items[0].flock.food,small.items[0].flock.food) and is_equal_approx(large.items[0].flock.water,small.items[0].flock.water),"Care boundaries preserve welfare under long ticks")
	for version in [1,2,3,4]:
		var old:=large.serialize()
		old.version=version
		old.erase("staff")
		check(restored.restore(JSON.parse_string(JSON.stringify(old))),"Legacy schema %d loads"%version)
		check(not restored.staff.hired and restored.money==large.money and restored.inventory==large.inventory,"Legacy migration never hires or charges")
	var valid:=large.serialize()
	var invalid:=valid.duplicate(true)
	invalid.erase("staff")
	check(not restored.restore(invalid),"Current schema requires worker state")
	for field in [["hired",1],["paused",0],["coop",99],["coop",2],["coop",0.5],["timer",15],["timer",-1],["timer",INF],["spent",-1],["eggs",0.5],["services",-1],["reason","mystery"]]:
		invalid=valid.duplicate(true)
		invalid.staff[field[0]]=field[1]
		snapshot=restored.serialize()
		check(not restored.restore(invalid) and restored.serialize()==snapshot,"Invalid employee field rejected before live state changes")
	print("V06_SIMULATION: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
