extends SceneTree

var checks:=0
var failures:=0

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error("FAILED: "+message)

func supplies(farm: FarmState, key: String) -> void:
	var offer:=FarmTrade.offer(key,farm.trade[key])
	for product in offer.needs: farm.inventory[product]=int(offer.needs[product])

func _initialize() -> void:
	var farm:=FarmState.new();farm.farm_xp=950
	check(farm.trade.size()==3 and farm.active_orders()==0,"Three neighbors start without active commitments")
	check(not farm.accept_order("nena").is_empty(),"Orders require owned land")
	farm.claim(Vector2(4,0))
	var snapshot:=farm.serialize()
	check(not farm.accept_order("unknown").is_empty() and farm.serialize()==snapshot,"Unknown neighbor rejected atomically")
	var first:=FarmTrade.offer("nena",farm.trade.nena)
	check(first.needs=={"carrot":6,"egg":2} and first.reward==115 and first.base==92,"Opening Nena order has clear fixed requirements and premium")
	check(first.seconds==480 and first.tier==0,"Entry order allows eight active minutes")
	check(FarmTrade.offer("bento",farm.trade.bento).needs!=first.needs,"Neighbors have different specialties")
	farm.tick(1000)
	check(FarmTrade.offer("nena",farm.trade.nena)==first,"Unaccepted offer has no deadline")
	farm.inventory={"carrot":10,"wheat":4,"corn":2,"egg":3}
	farm.place("barn",Vector2(10,6),0)
	farm.reserve.carrot=6
	var balance:=farm.money
	check(farm.sell_product("carrot",3)==36 and farm.money==balance+36,"Selective sale pays exact amount")
	check(farm.inventory.carrot==7 and farm.inventory.wheat==4 and farm.inventory.egg==3,"Sale leaves other products and unsold quantity untouched")
	check(farm.reserve.carrot==6,"Selective sale cannot touch barn reserve")
	snapshot=farm.serialize()
	for amount in [0,-1,8]: check(farm.sell_product("carrot",amount)==0 and farm.serialize()==snapshot,"Invalid sale quantity is atomic")
	check(farm.sell_product("gold",1)==0 and farm.serialize()==snapshot,"Unknown product cannot be sold")
	check(farm.accept_order("nena").is_empty(),"Accept available order")
	check(farm.active_orders()==1 and farm.trade.nena.active.accepted_at==farm.elapsed,"Accepted order records start time")
	snapshot=farm.serialize()
	check(not farm.accept_order("nena").is_empty() and farm.serialize()==snapshot,"Double accept cannot extend timer")
	check(not farm.deliver_order("bento").is_empty() and farm.serialize()==snapshot,"Cannot deliver unaccepted order")
	farm.inventory.egg=0
	snapshot=farm.serialize()
	check(not farm.deliver_order("nena").is_empty() and farm.serialize()==snapshot,"Missing one ingredient never partially consumes the others")
	farm.inventory.carrot=0
	farm.inventory.egg=2
	snapshot=farm.serialize()
	check(not farm.deliver_order("nena").is_empty() and farm.serialize()==snapshot,"Reserved products do not satisfy orders silently")
	farm.transfer_reserve("carrot",false)
	balance=farm.money
	check(farm.deliver_order("nena").is_empty() and farm.money==balance+115,"Delivery consumes matching products and pays quoted reward")
	check(farm.inventory.carrot==0 and farm.inventory.egg==0 and farm.inventory.wheat==4,"Only requested ingredients are consumed")
	check(farm.trade.nena.reputation==1 and farm.trade.nena.cycle==1 and farm.active_orders()==0,"Successful delivery grants one reputation and next offer")
	snapshot=farm.serialize()
	check(not farm.deliver_order("nena").is_empty() and farm.serialize()==snapshot,"Repeated delivery cannot duplicate reward or reputation")
	check(FarmTrade.offer("nena",farm.trade.nena).title!=first.title,"Next order varies after delivery")
	farm.accept_order("nena")
	supplies(farm,"nena")
	farm.deliver_order("nena")
	var partner:=FarmTrade.offer("nena",farm.trade.nena)
	check(farm.trade.nena.reputation==2 and partner.tier==1,"Two deliveries unlock partner orders")
	check(partner.seconds==600 and partner.needs.corn==12,"Partner order has larger quantities and longer time")
	check(partner.reward>partner.base,"Partner reward beats ordinary market value")
	for i in range(3):
		farm.accept_order("nena")
		supplies(farm,"nena")
		farm.deliver_order("nena")
	check(FarmTrade.tier(farm.trade.nena.reputation)==2 and FarmTrade.rank_name(farm.trade.nena.reputation)=="Preferido","Five deliveries unlock final reputation tier")
	check(FarmTrade.offer("nena",farm.trade.nena).seconds==720,"Preferred orders give twelve minutes")
	check(farm.trade.bento.reputation==0 and farm.trade.lola.reputation==0,"Reputation is independent for each neighbor")
	var legacy_contract:=FarmState.new()
	legacy_contract.claim(Vector2(4,0))
	legacy_contract.trade.nena.reputation=1
	legacy_contract.accept_order("nena")
	var accepted:=FarmTrade.offer("nena",legacy_contract.trade.nena)
	legacy_contract.inventory.carrot=12
	legacy_contract.inventory.egg=2
	check(legacy_contract.deliver_contract() and legacy_contract.trade.nena.reputation==2,"Original Nena contract grants recognition once")
	check(FarmTrade.offer("nena",legacy_contract.trade.nena)==accepted,"Active offer does not change when reputation rises elsewhere")
	balance=legacy_contract.money
	check(not legacy_contract.deliver_contract() and legacy_contract.money==balance,"Introductory contract remains one-time")
	check(legacy_contract.deliver_order("nena").is_empty() and legacy_contract.money==balance+accepted.reward,"Frozen active reward survives tier unlock")
	var timer:=FarmState.new();timer.farm_xp=950
	timer.claim(Vector2(4,0))
	for key in FarmTrade.KEYS: timer.accept_order(key)
	check(timer.active_orders()==3,"Three neighbors can have independent active orders")
	timer.tick(479)
	check(timer.active_orders()==3,"Orders remain active before deadline")
	var inventory:=timer.inventory.duplicate()
	balance=timer.money
	timer.tick(1)
	check(timer.active_orders()==0 and timer.trade_notices.size()==3,"Exact deadline expires all relevant orders")
	check(timer.money==balance and timer.inventory==inventory and timer.trade.nena.reputation==0,"Expiry does not remove money, products or reputation")
	check(timer.trade.nena.cycle==1 and timer.trade.nena.last_result=="expired","Expiry advances to a new offer")
	timer.tick(1)
	check(timer.trade_notices.size()==3 and timer.trade.nena.cycle==1,"Expired order is processed only once")
	timer.accept_order("bento")
	supplies(timer,"bento")
	inventory=timer.inventory.duplicate()
	balance=timer.money
	check(timer.cancel_order("bento").is_empty(),"Active order can be declined")
	check(timer.inventory==inventory and timer.money==balance and timer.trade.bento.reputation==0,"Cancellation has no economic penalty")
	snapshot=timer.serialize()
	check(not timer.cancel_order("bento").is_empty() and timer.serialize()==snapshot,"Repeated cancellation cannot skip extra offers")
	timer.accept_order("lola")
	supplies(timer,"lola")
	timer.elapsed=timer.trade.lola.active.deadline
	inventory=timer.inventory.duplicate()
	balance=timer.money
	check(not timer.deliver_order("lola").is_empty() and timer.inventory==inventory and timer.money==balance,"Late delivery cannot win a reward at the exact deadline")
	farm.accept_order("bento")
	farm.tick(25)
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))),"Trade JSON roundtrip")
	check(restored.trade==farm.trade and restored.money==farm.money,"Offers, deadlines, reputation and money persist")
	var deadline:float=restored.trade.bento.active.deadline
	check(restored.elapsed==farm.elapsed and restored.trade.bento.active.deadline==deadline,"Loading does not advance or restart active deadline")
	var before:=restored.serialize()
	var invalid:=farm.serialize()
	invalid.erase("trade")
	check(not restored.restore(invalid) and restored.serialize()==before,"Current save cannot silently lose trade data")
	for field in [["reputation",-1],["reputation",0.5],["cycle",-1],["cycle","1"],["last_result","free_money"],["active",null]]:
		invalid=farm.serialize()
		invalid.trade.bento[field[0]]=field[1]
		check(not restored.restore(invalid) and restored.serialize()==before,"Malformed neighbor record rejected atomically")
	for field in [["tier",3],["tier",1.5],["accepted_at",farm.elapsed+1],["deadline",0],["deadline",INF]]:
		invalid=farm.serialize()
		invalid.trade.bento.active[field[0]]=field[1]
		check(not restored.restore(invalid) and restored.serialize()==before,"Malformed active deadline or tier rejected")
	invalid=farm.serialize()
	invalid.trade.bento.active.deadline+=100
	check(not restored.restore(invalid),"Edited duration is rejected")
	invalid=farm.serialize()
	invalid.trade.erase("lola")
	check(not restored.restore(invalid),"Missing neighbor rejected")
	for version in [1,2,3]:
		var old:=farm.serialize()
		old.version=version
		old.contract_done=true
		old.erase("trade")
		check(restored.restore(JSON.parse_string(JSON.stringify(old))),"Older schema %d migrates"%version)
		check(restored.trade.nena.reputation==1 and restored.active_orders()==0,"Migration recognizes old introductory delivery without inventing active orders")
		check(restored.money==farm.money and restored.inventory==farm.inventory and restored.reserve==farm.reserve,"Migration preserves existing economy and reserve")
		check(restored.restore(JSON.parse_string(JSON.stringify(restored.serialize()))) and restored.trade.nena.reputation==1,"Reload does not grant migration reputation again")
	var overdue:=farm.serialize()
	overdue.elapsed=overdue.trade.bento.active.deadline
	check(restored.restore(overdue) and restored.trade.bento.active.is_empty(),"Overdue stored order resolves on load")
	var cycle:int=restored.trade.bento.cycle
	check(restored.restore(restored.serialize()) and restored.trade.bento.cycle==cycle,"Reload does not re-expire a settled order")
	check(FarmTrade.time_label(480)=="08:00" and FarmTrade.time_label(0)=="00:00","Countdown uses clear minute and second values")
	print("V05_SIMULATION: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
