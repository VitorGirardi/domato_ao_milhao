extends SceneTree
func _initialize() -> void:
	var f:=FarmState.new();var before:=f.serialize()
	assert(not FarmParcels.buy(f,"east").is_empty() and f.serialize()==before)
	f.claim(Vector2(4,-2));f.farm_xp=950
	var snapshot:=f.serialize()
	assert(not FarmParcels.buy(f,"east").is_empty() and f.serialize()==snapshot)
	f.unlimited_money=true
	var finite:int=f.serialize().money
	for i in range(100):f.money-=999999
	assert(f.money==1000000000 and f.serialize().money==finite)
	for key in FarmParcels.LOTS:
		var p:Vector2=FarmParcels.LOTS[key].center
		assert(not f.place("coop",p,0).is_empty())
		assert(FarmParcels.buy(f,key).is_empty())
		assert(not FarmParcels.buy(f,key).is_empty())
		assert(f.place("coop",p,0).is_empty())
		for x in range(int(p.x)-14,int(p.x)+15):
			for z in range(int(p.y)-14,int(p.y)+15):assert(is_zero_approx(FarmLandscape.height_at(Vector2(x,z))))
		assert(f.owns_area(f.item_rect("coop",p,0)))
	assert(f.serialize().money==finite)
	var disk:Variant=JSON.parse_string(JSON.stringify(f.serialize()));var restored:=FarmState.new()
	assert(restored.restore(disk) and restored.unlimited_money and restored.owned_parcels==f.owned_parcels)
	assert(restored.items.size()==3 and restored.money==f.money)
	var good:=restored.serialize()
	for bad in [null,{},"yes",1]:
		var data:=good.duplicate(true);data.version=14;data.unlimited_money=bad
		assert(not restored.restore(data) and restored.serialize()==good)
	for bad in [["east","east"],["missing"],"east",null]:
		var data:=good.duplicate(true);data.owned_parcels=bad
		assert(not restored.restore(data) and restored.serialize()==good)
	var old:=FarmState.new().serialize();old.version=14;old.erase("owned_parcels");old.erase("unlimited_money")
	assert(restored.restore(old) and restored.owned_parcels.is_empty())
	print("V021_STATE_OK: infinite wallet, atomic purchase, parcel construction, terrain, migration and malformed saves")
	quit()
