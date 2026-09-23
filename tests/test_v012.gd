extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,why:String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(why)
func fixture() -> FarmState:
	var farm:=FarmState.new();farm.farm_xp=950
	farm.claim(Vector2.ZERO); farm.money=10000
	farm.place("plot",Vector2.ZERO,0)
	farm.place("plot",Vector2(2,0),0)
	farm.hire_field_staff()
	return farm
func _initialize() -> void:
	var farm:=fixture()
	var tasks:={"water":true,"harvest":true,"plant":true}
	var plans:Array=[{"index":0,"crop":"wheat"}]
	var snapshot:=farm.serialize()
	check(not FarmCultivation.configure(farm,[],tasks,100).is_empty() and snapshot==farm.serialize(),"Empty plan is atomic")
	check(not FarmCultivation.configure(farm,plans,{"water":false,"harvest":false,"plant":false},100).is_empty(),"At least one task")
	check(not FarmCultivation.configure(farm,[{"index":0,"crop":"bad"}],tasks,100).is_empty(),"Invalid crop")
	check(not FarmCultivation.configure(farm,plans+plans,tasks,100).is_empty(),"Duplicate plot")
	check(not FarmCultivation.configure(farm,plans,tasks,-1).is_empty(),"Negative budget")
	farm.field_staff.hired=false
	check(not FarmCultivation.configure(farm,plans,tasks,100).is_empty(),"Hire required")
	farm.field_staff.hired=true
	farm.items[0].crop="carrot"; farm.items[0].planted=true; farm.items[0].growth=1.0
	check(FarmCultivation.configure(farm,plans,tasks,12).is_empty() and farm.items[0].crop=="carrot","Plan preserves standing crop")
	check(FarmCultivation.job(farm,0)=="harvest" and FarmCultivation.job(farm,1)=="","Only selected plots")
	var money:=farm.money
	check(FarmCultivation.complete(farm,0,"harvest").is_empty() and farm.inventory.carrot==3 and farm.money==money-2,"Harvest goes to inventory, no autosale")
	check(farm.farm_xp==960,"Bento awards crop XP once")
	check(FarmCultivation.job(farm,0)=="plant","Next task is replant")
	check(FarmCultivation.complete(farm,0,"plant").is_empty() and farm.items[0].crop=="wheat" and farm.money==money-10,"Replant charges service and wheat seeds")
	check(FarmCultivation.complete(farm,0,"water").is_empty() and farm.money==money-12,"Water completes exact budget")
	check(farm.cultivation.actions=={"water":1,"harvest":1,"plant":1} and farm.cultivation.services==6 and farm.cultivation.seeds==6,"Complete ledger")
	check(farm.cultivation.produced.carrot==3 and farm.cultivation.sown.wheat==1,"Per crop report")
	money=farm.money
	check(not FarmCultivation.complete(farm,0,"water").is_empty() and farm.money==money,"No duplicate or stale charge")
	check(farm.farm_xp==960,"Water, planting and rejected work do not award XP")
	farm.items[0].growth=1.0
	check(not FarmCultivation.complete(farm,0,"harvest").is_empty() and farm.field_staff.reason=="budget" and farm.money==money and farm.items[0].growth==1,"Budget pause is atomic")
	check(FarmCultivation.configure(farm,plans,tasks,12).is_empty() and farm.cultivation.spent==12,"Configuration never renews budget")
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))) and restored.cultivation==farm.cultivation,"Save restores budget and report")
	check(not FarmCultivation.complete(restored,0,"harvest").is_empty() and restored.field_staff.reason=="budget","Reload does not reset budget")
	check(FarmCultivation.renew(farm).is_empty() and farm.cultivation.spent==0 and farm.cultivation.services==6 and farm.money==money,"Explicit renewal retains total ledger, no charge")
	farm.cultivation.tasks.harvest=false
	check(FarmCultivation.job(farm,0)=="","Harvest toggle off")
	farm.items[0].planted=false; farm.cultivation.tasks.plant=false
	check(FarmCultivation.job(farm,0)=="","Plant toggle off")
	farm.items[0].planted=true; farm.items[0].growth=0; farm.items[0].watered=false; farm.cultivation.tasks.water=false
	check(FarmCultivation.job(farm,0)=="","Water toggle off")
	farm.cultivation.tasks=tasks.duplicate()
	farm.items[0].planted=false; farm.money=7
	check(not FarmCultivation.complete(farm,0,"plant").is_empty() and farm.money==7 and not farm.items[0].planted and farm.cultivation.spent==0 and farm.field_staff.reason=="funds","Full seed+service price required")
	farm.money=1000; farm.pause_field_staff(); farm.train_worker("field")
	money=farm.money
	check(FarmCultivation.complete(farm,0,"plant").is_empty() and farm.money==money-7,"Training lowers service, preserves seed cost")
	check(FarmCultivation.complete(farm,0,"water").is_empty() and farm.cultivation.spent==8,"Trained water fee")
	var bad:=farm.serialize(); bad.cultivation.plans[0].index=99
	snapshot=restored.serialize()
	check(not restored.restore(bad) and snapshot==restored.serialize(),"Invalid plan rejects entire save")
	bad=farm.serialize(); bad.cultivation.spent=-1
	check(not restored.restore(bad) and snapshot==restored.serialize(),"Invalid ledger rejects entire save")
	bad=farm.serialize(); bad.cultivation.tasks.water="true"
	check(not restored.restore(bad),"Invalid task type")
	var old:=farm.serialize(); old.version=8; old.erase("cultivation")
	check(restored.restore(old) and not restored.cultivation.enabled and restored.irrigation.enabled and restored.field_staff.hired,"V8 migration preserves water routine without enabling planting")
	check(FarmCultivation.configure(farm,[{"index":1,"crop":"corn"}],tasks,100).is_empty(),"Change plot")
	var spent:int=farm.cultivation.spent
	farm.remove_item(0)
	check(farm.cultivation.plans==[{"index":0,"crop":"corn"}] and farm.cultivation.spent==spent,"Removal remaps selected plot and retains budget")
	farm.remove_item(0)
	check(not farm.cultivation.enabled and farm.field_staff.paused,"Removing last plot stops routine")
	farm=fixture(); FarmCultivation.configure(farm,plans,tasks,100)
	farm.dismiss_field_staff()
	check(not farm.cultivation.enabled and FarmCultivation.job(farm,0)=="","Dismiss stops work")
	farm=fixture(); farm.items[0].planted=false
	FarmCultivation.configure(farm,plans,tasks,25)
	money=farm.money
	for cycle in range(10):
		FarmCultivation.complete(farm,0,"plant")
		FarmCultivation.complete(farm,0,"water")
		farm.items[0].growth=1.0
		FarmCultivation.complete(farm,0,"harvest")
	check(farm.cultivation.spent==24 and farm.money==money-24 and farm.inventory.wheat==6,"Repeated cycles never overspend")
	print("V012_STATE_OK: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
