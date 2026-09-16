extends SceneTree

var checks := 0

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		push_error("FAILED: "+message)
		quit(1)

func _initialize() -> void:
	var farm:=FarmState.new()
	check(not farm.claim(Vector2(-30,0)).is_empty(),"Reject river/road claims")
	check(farm.money==1600 and not farm.claimed,"Invalid claim is atomic")
	check(farm.claim(Vector2(4,0)).is_empty(),"Claim valid terrain")
	check(farm.money==1200,"Claim charges exactly once")
	farm.claim(Vector2(6,2))
	check(farm.money==1200,"Cannot buy starter land twice")
	check(farm.place("plot",Vector2(4,0),0,"carrot").is_empty(),"Build and seed plot")
	check(not farm.place("barn",Vector2(4,0),0).is_empty(),"Reject overlapping construction")
	check(farm.items.size()==1 and farm.money==1180,"Rejected build changes nothing")
	check(not farm.place("plot",Vector2(30,0),0).is_empty(),"Reject out-of-property build")
	farm.tick(90)
	check(farm.items[0].growth==0,"Unwatered plants do not grow")
	farm.tend(0)
	farm.tick(32)
	check(farm.items[0].growth==1,"Watered carrot matures")
	farm.tend(0)
	check(farm.inventory.carrot==3 and farm.harvests==1,"Harvest produces exact yield")
	farm.tend(0)
	check(farm.inventory.carrot==3 and farm.money==1176,"Second interaction replants instead of duplicating harvest")
	check(farm.sale_value()==36,"Crop valuation")
	check(farm.sell_all()==36 and farm.money==1212,"Sale income")
	check(farm.sell_all()==0 and farm.money==1212,"Empty sale is idempotent")
	check(farm.place("coop",Vector2(10,-6),0).is_empty(),"Coop construction")
	farm.tick(91)
	check(farm.inventory.egg==4,"Coop handles multiple production cycles")
	check(not farm.deliver_contract(),"Contract requires stock")
	farm.inventory.carrot=6
	check(farm.deliver_contract(),"Contract consumes carrots and pays")
	var balance:=farm.money
	farm.inventory.carrot=6
	check(not farm.deliver_contract() and farm.money==balance,"Contract cannot pay twice")
	check(farm.expand().is_empty() and farm.land_size==32,"Paid expansion")
	check(not farm.expand().is_empty() and farm.land_size==32,"Insufficient money expansion changes nothing")
	farm.items[1].paint=2
	farm.farm_name="Sítio do João"
	var data:Variant=JSON.parse_string(JSON.stringify(farm.serialize()))
	var restored:=FarmState.new()
	check(restored.restore(data),"JSON roundtrip must restore")
	check(restored.money==farm.money and restored.inventory==farm.inventory,"Money and stock persist")
	check(restored.items.size()==2 and restored.items[1].paint==2,"Construction and paint persist")
	check(restored.farm_name=="Sítio do João","Unicode farm name persists")
	data.items[0].crop="invalid"
	check(not restored.restore(data),"Reject malformed crop data")
	check(restored.money==farm.money and restored.items[0].crop=="carrot","Invalid save is atomic")
	check(not restored.restore(null),"Reject unreadable JSON")
	data=farm.serialize()
	data.items.append(data.items[0].duplicate())
	check(not restored.restore(data),"Reject overlapping saved structures")
	farm.money=0
	check(not farm.place("fence",Vector2(0,6),0).is_empty(),"Prevent negative balance")
	print("SIMULATION_OK: %d checks"%checks)
	quit()
