extends SceneTree
var checks:=0
func check(ok:bool,why:String) -> void:
	checks+=1;assert(ok,why)
func _initialize() -> void:
	var f:=FarmState.new();f.claim(Vector2(4,-2));f.money=5000;f.milk_stock=16
	f.place("cheesery",Vector2(4,0),0)
	var before:=f.money
	check(FarmCheeseWorker.hire(f).is_empty() and f.money==before-160,"Hiring price")
	check(not FarmCheeseWorker.hire(f).is_empty() and f.money==before-160,"No duplicate hire")
	check(not FarmCheeseWorker.configure(f,99,2,8).is_empty(),"Valid assignment required")
	check(FarmCheeseWorker.configure(f,0,2,8).is_empty(),"Configure routine")
	check(FarmCheeseWorker.job(f)=="start","Start job")
	check(FarmCheeseWorker.complete(f,0,"start") and f.milk_stock==12 and f.cheese_worker.spent==4,"Atomic inputs and fee")
	check(not FarmCheeseWorker.complete(f,0,"start") and f.cheese_worker.spent==4,"No duplicate start")
	check(FarmCheeseWorker.configure(f,0,2,8).is_empty() and f.cheese_worker.spent==4,"Editing does not renew budget")
	var snapshot:=f.serialize();var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(snapshot))) and restored.cheese_worker==f.cheese_worker,"Persist assignment budget and reports")
	f.tick(90);f.money=0
	check(FarmCheeseWorker.job(f)=="collect" and FarmCheeseWorker.complete(f,0,"collect") and f.cheese_stock==2,"Free collection with no balance")
	check(not FarmCheeseWorker.complete(f,0,"collect") and f.cheese_stock==2,"Collect once")
	check(f.cheese_worker.paused and f.cheese_worker.reason=="funds","No balance pauses next start")
	f.money=100;f.cheese_worker.paused=false
	check(FarmCheeseWorker.complete(f,0,"start") and f.cheese_worker.spent==8,"Second exact fee")
	f.tick(90);FarmCheeseWorker.complete(f,0,"collect")
	check(FarmCheeseWorker.job(f).is_empty() and f.cheese_worker.reason=="budget" and f.cheese_worker.paused,"Budget cap enforced")
	check(not FarmCheeseWorker.configure(f,0,2,4).is_empty() and f.cheese_worker.spent==8,"Cannot silently erase usage")
	check(FarmCheeseWorker.configure(f,0,2,4,true).is_empty() and f.cheese_worker.spent==0 and f.cheese_worker.total_spent==8,"Explicit renewal preserves total")
	f.milk_stock=3
	check(FarmCheeseWorker.job(f).is_empty() and not f.cheese_worker.paused and f.cheese_worker.reason=="milk","Wait for full batch without charging")
	f.milk_stock=4
	check(FarmCheeseWorker.complete(f,0,"start") and f.milk_stock==0,"Resume when milk supplied")
	f.cheese_worker.paused=true;f.tick(90)
	check(not FarmCheeseWorker.complete(f,0,"collect") and f.items[0].cheese.ready==2,"Manual pause prevents collection")
	FarmCheeseWorker.dismiss(f)
	check(not f.cheese_worker.hired and f.items[0].cheese.ready==2,"Dismiss preserves batch")
	f.money=300;var report:int=f.cheese_worker.total_spent
	check(FarmCheeseWorker.hire(f).is_empty() and f.cheese_worker.total_spent==report and f.cheese_worker.spent==4,"Rehire preserves used budget")
	FarmCheese.collect(f,0)
	check(f.remove_item(0).is_empty() and f.cheese_worker.site== -1 and f.cheese_worker.paused,"Removal detaches assignment")
	var base:=restored.serialize()
	for field in ["spent","budget","site","batch_size","total_spent","hired"]:
		var bad:=snapshot.duplicate(true);bad.cheese_worker[field]="invalid"
		check(not restored.restore(bad) and restored.serialize()==base,"Corrupt worker rejected atomically")
	var bad:=snapshot.duplicate(true);bad.cheese_worker.spent=99
	check(not restored.restore(bad),"Overspent save rejected")
	var old:=snapshot.duplicate(true);old.version=11;old.erase("cheese_worker")
	check(restored.restore(old) and not restored.cheese_worker.hired and restored.items[0].cheese.batch==2,"Migration keeps batch without auto-hiring")
	var missing:=snapshot.duplicate(true);missing.erase("cheese_worker")
	check(not restored.restore(missing),"v12 requires worker")
	var remap:=FarmState.new();remap.claim(Vector2(4,-2));remap.money=5000
	remap.place("plot",Vector2(-4,0),0);remap.place("cheesery",Vector2(4,0),0);FarmCheeseWorker.hire(remap);FarmCheeseWorker.configure(remap,1,1,4)
	remap.remove_item(0)
	check(remap.cheese_worker.site==0,"Removing earlier item remaps assignment")
	print("V017_STATE_OK: %d checks"%checks);quit()
