extends SceneTree
func _initialize() -> void:
	var farm:=FarmState.new()
	farm.claim(Vector2.ZERO); farm.money=2000; farm.place("coop",Vector2.ZERO,0)
	var alerts:=FarmFieldAlerts.new()
	assert(alerts.poll(farm).is_empty())
	farm.items[0].flock.nest=12
	assert(alerts.poll(farm).contains("Ninho cheio"))
	assert(alerts.poll(farm).is_empty())
	farm.items[0].flock.nest=0; alerts.poll(farm)
	farm.items[0].flock.nest=12
	assert(not alerts.poll(farm).is_empty())
	farm.hire_field_staff(); farm.field_staff.paused=true; farm.field_staff.reason="budget"
	assert(alerts.poll(farm).contains("Bento pausou"))
	assert(alerts.poll(farm).is_empty())
	farm.field_staff.reason="manual"
	assert(alerts.poll(farm).is_empty() and FarmFieldAlerts.paused_text(farm).is_empty())
	farm.field_staff.reason="funds"
	assert(alerts.poll(farm).contains("sem saldo"))
	farm.field_staff.hired=false
	assert(FarmFieldAlerts.paused_text(farm).is_empty())
	assert(FarmFieldAlerts.full_coops(farm)==[0])
	print("V013_ALERTS_OK: transitions, no duplicate alerts, manual pause, full nest recovery")
	quit()
