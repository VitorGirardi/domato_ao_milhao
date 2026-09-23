extends SceneTree
var checks:=0
func check(ok:bool,why:String) -> void:
	checks+=1;assert(ok,why)
func _initialize() -> void:
	var f:=FarmState.new();f.farm_xp=950;f.claim(Vector2(4,-2));f.money=5000
	check(f.place("corral",Vector2(4,0),0).is_empty(),"Place corral")
	var before:=f.money
	check(FarmDairyWorker.hire(f).is_empty() and f.money==before-140,"Hire exact cost")
	check(not FarmDairyWorker.hire(f).is_empty() and f.money==before-140,"Duplicate hire rejected")
	check(not FarmDairyWorker.configure(f,20,60).is_empty(),"Invalid site rejected")
	check(FarmDairyWorker.configure(f,0,60).is_empty(),"Assignment")
	check(FarmDairyWorker.job(f).is_empty() and f.dairy_worker.reason=="cow" and not f.dairy_worker.paused,"Wait for purchased cow")
	FarmDairy.care(f,0,"buy")
	check(FarmDairyWorker.job(f).is_empty(),"No pointless services")
	var d:Dictionary=f.items[0].dairy;d.milk=4;before=f.money
	check(FarmDairyWorker.complete(f,0,"milk") and f.milk_stock==4 and f.money==before-2,"Milk transferred once with fee")
	check(not FarmDairyWorker.complete(f,0,"milk") and f.milk_stock==4,"No duplicate milk")
	d.water=35;before=f.money
	check(FarmDairyWorker.complete(f,0,"water") and d.water==100 and f.money==before-2,"Water material free; labor two")
	d.food=35;before=f.money
	check(FarmDairyWorker.cost(f,"food")==10 and FarmDairyWorker.complete(f,0,"food") and f.money==before-10 and d.food==100,"Feed plus labor atomic")
	check(f.dairy_worker.spent==14 and f.dairy_worker.services==3 and f.dairy_worker.collected==4,"Ledger includes feed")
	check(FarmDairyWorker.configure(f,0,14).is_empty() and f.dairy_worker.spent==14,"Edit preserves used budget")
	d.milk=4;before=f.money
	check(FarmDairyWorker.job(f).is_empty() and f.dairy_worker.reason=="budget" and f.money==before and d.milk==4,"Budget stops before resource mutation")
	check(not FarmDairyWorker.configure(f,0,13).is_empty(),"Cannot silently reset spending")
	check(FarmDairyWorker.configure(f,0,10,true).is_empty() and f.dairy_worker.spent==0 and f.dairy_worker.total_spent==14,"Explicit renewal")
	f.money=1
	check(not FarmDairyWorker.complete(f,0,"milk") and f.dairy_worker.reason=="funds" and d.milk==4,"Insufficient funds preserve milk")
	f.money=100;f.dairy_worker.paused=false;d.water=100;d.food=30
	check(FarmDairyWorker.job(f).is_empty() and f.dairy_worker.reason=="budget" and d.food==30,"Full feed cost included in cap")
	FarmDairyWorker.configure(f,0,60,true);d.food=100
	f.dairy_worker.paused=true
	check(not FarmDairyWorker.complete(f,0,"milk") and d.milk==4,"Pause prevents work")
	var saved:=f.serialize();var other:=FarmState.new()
	check(other.restore(JSON.parse_string(JSON.stringify(saved))) and other.dairy_worker==f.dairy_worker,"JSON roundtrip")
	var base:=other.serialize()
	for field in ["site","budget","spent","total_spent","services","collected","hired"]:
		var bad:=saved.duplicate(true);bad.dairy_worker[field]="invalid"
		check(not other.restore(bad) and other.serialize()==base,"Bad worker rejected atomically")
	var missing:=saved.duplicate(true);missing.erase("dairy_worker")
	check(not other.restore(missing),"v13 requires worker")
	missing.version=12
	check(other.restore(missing) and not other.dairy_worker.hired and other.items[0].dairy.milk==4,"Migrate v12 preserving cow")
	FarmDairyWorker.dismiss(f)
	check(not f.dairy_worker.hired and d.milk==4,"Dismiss keeps milk")
	f.money=300;FarmDairyWorker.hire(f)
	check(f.dairy_worker.total_spent==14,"Rehire preserves ledger")
	var remap:=FarmState.new();remap.farm_xp=950;remap.claim(Vector2(4,-2));remap.money=5000
	remap.place("plot",Vector2(-4,0),0);remap.place("corral",Vector2(4,0),0)
	FarmDairyWorker.hire(remap);FarmDairyWorker.configure(remap,1,60)
	remap.remove_item(0);check(remap.dairy_worker.site==0,"Remap earlier item")
	remap.remove_item(0);check(remap.dairy_worker.site== -1 and remap.dairy_worker.paused,"Removed empty corral detaches")
	print("V018_STATE_OK: %d checks"%checks);quit()
