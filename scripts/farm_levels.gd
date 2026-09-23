class_name FarmLevels
extends RefCounted
## Total lifetime XP; never spent. Building upgrades keep their own levels.
const THRESHOLDS := [0, 30, 120, 280, 550, 950]
const BUILDINGS := ["plot", "coop", "barn", "workshop", "corral", "cheesery"]
const ICONS := ["seed", "chicken", "barn", "workshop", "cow", "cheese"]
const HARVEST := 10
const EGG := 2
const MILK := 3
const CHEESE := 8
const ORDER := 30

static func level(xp:int) -> int:
	var result:=1
	for threshold in THRESHOLDS:
		if xp>=threshold: result+=1
	return mini(result-1,THRESHOLDS.size())

static func required(kind:String) -> int:
	return 5 if kind=="stable" else maxi(1,BUILDINGS.find(kind)+1)

static func unlocked(state:FarmState,kind:String) -> bool:
	return level(state.farm_xp)>=required(kind)

static func next_text(xp:int) -> String:
	var current:=level(xp)
	if current==THRESHOLDS.size(): return "Todas as construções liberadas"
	return "%s em %d XP"%["Curral e estrebaria" if current==4 else FarmState.ITEMS[BUILDINGS[current]].name,THRESHOLDS[current]-xp]

static func legacy_xp(state:FarmState) -> int:
	# Old saves already had an unrestricted catalog. Recognize evidence of ownership,
	# including retained workers/equipment after removing their workplace.
	var minimum:=1
	for item in state.items: minimum=maxi(minimum,required(item.kind))
	if state.staff.hired or state.milestones.get("coop",false): minimum=maxi(minimum,2)
	if state.watering_upgrade: minimum=maxi(minimum,4)
	if state.dairy_worker.hired or state.milk_stock>0: minimum=maxi(minimum,5)
	if state.cheese_worker.hired or state.cheese_stock>0 or state.cheese_order.active or state.cheese_order.cycle>0: minimum=6
	var earned:=state.harvests*HARVEST
	for record in state.trade.values(): earned+=int(record.reputation)*ORDER
	return mini(1000000000,maxi(THRESHOLDS[minimum-1],earned))
