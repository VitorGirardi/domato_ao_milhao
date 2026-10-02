extends SceneTree

func _initialize() -> void:
	var farm:=FarmState.new_farm("sandbox")
	assert(farm.claim(Vector2(4,-2)).is_empty())
	var keys:Array=["carrot","wheat","corn","egg","milk","cheese"]+FarmResources.FISH_KEYS+FarmResources.ORE_KEYS
	for key in keys:
		assert(farm.stock_text(key)=="∞")
		var available:=farm.stock(key)
		for i in range(3):farm.consume_stock(key,available)
		assert(farm.stock(key)==available)
	assert(farm.stock("invalid")==0)
	assert(farm.sell_product("egg",500)==5000 and farm.inventory.egg==0)
	assert(FarmDairy.sell(farm,500)==9000 and farm.milk_stock==0)
	assert(FarmCheese.sell(farm,500)==26000 and farm.cheese_stock==0)
	for key in FarmResources.FISH_KEYS+FarmResources.ORE_KEYS:
		assert(FarmResources.sell(farm,key)==FarmResources.PRICES[key])
		assert(farm.resources.stock[key]==0)
	assert(farm.deliver_contract() and farm.inventory.carrot==0)
	assert(farm.accept_order("nena").is_empty())
	assert(farm.deliver_order("nena").is_empty())
	assert(farm.place("cheesery",Vector2(4,-2),0).is_empty())
	assert(FarmCheese.start(farm,0,4).is_empty() and farm.milk_stock==0)
	assert(farm.sell_all()>0 and farm.stock_text("milk")=="∞")
	for i in range(20):
		assert(FarmArmory.fire(farm.armory))
		FarmArmory.reload_magazine(farm.armory,farm.infinite_resources())
	assert(farm.armory.reserve==FarmArmory.MAX_RESERVE)
	assert(FarmResources.catch_fish(farm,0).is_empty())
	assert(FarmResources.extract(farm,8).is_empty())
	var data:Dictionary=JSON.parse_string(JSON.stringify(farm.serialize()))
	var restored:=FarmState.new()
	assert(restored.restore(data))
	assert(restored.resources==farm.resources and restored.inventory==farm.inventory)
	assert(restored.stock_text("milk")=="∞" and restored.items[0].cheese.batch==4)
	assert(restored.farm_xp==farm.farm_xp and restored.armory==farm.armory)
	# Earlier sandbox saves receive unlocks without changing stored products/progress.
	data.resources=FarmResources.fresh();data.armory=FarmArmory.fresh()
	data.watering_upgrade=false;data.professional_watering=false
	data.inventory.egg=17;data.milk_stock=9
	assert(restored.restore(data))
	assert(restored.resources.gallery_level==2 and restored.armory.pistol and restored.professional_watering)
	assert(restored.inventory.egg==17 and restored.milk_stock==9 and restored.farm_xp==farm.farm_xp)
	var survival:=FarmState.new_farm("survival")
	survival.unlimited_money=true # Money alone must never grant infinite products.
	assert(survival.stock("egg")==0 and survival.stock_text("milk")=="0")
	survival.inventory.egg=8;survival.consume_stock("egg",3)
	assert(survival.inventory.egg==5 and survival.sell_product("egg",6)==0)
	assert(not survival.resources.mine_owned and not FarmLevels.unlocked(survival,"cheesery"))
	print("SANDBOX_RESOURCES_OK: all products, repeated consumption, orders, cheese production, ammo, saves and survival isolation")
	quit()
