class_name FarmOrchardStaffMotion
extends RefCounted
## One physical Zeca, one pending service; the domain commits only after arrival.
class OrchardRoute extends FarmStaffMotion:
	var stones: Array[Rect2] = []
	func prepare(world: FarmWorld, state: FarmState) -> void:
		stones.clear()
		for record in world.landscape.scenery:
			if record.key != "stone" or record.scale <= .6 or FarmLandscape.cleared(record, state): continue
			var radius: float = record.scale * .65 + .4
			stones.append(Rect2(record.p - Vector2.ONE * radius, Vector2.ONE * radius * 2))
	func walkable(at: Vector3, state: FarmState) -> bool:
		if not super.walkable(at, state): return false
		var p := Vector2(at.x, at.z)
		if FarmRegion.water_blocked(p): return false
		for stone in stones:
			if stone.has_point(p): return false
		var height := FarmLandscape.height_at(p)
		for offset in [Vector2(.4,0), Vector2(-.4,0), Vector2(0,.4), Vector2(0,-.4)]:
			if absf(FarmLandscape.height_at(p + offset) - height) > .32: return false
		return true
	func plan(start: Vector3, finish: Vector3, state: FarmState) -> void:
		path.clear(); target = finish
		var flat := Vector2(finish.x-start.x,finish.z-start.z)
		var count := maxi(1,ceili(flat.length()/.25))
		var direct := true
		for step in range(count+1):
			var point := start.lerp(finish,float(step)/count)
			if not walkable(point,state):
				direct = false
				break
		if direct:
			path.append(finish); blocked = false
			return
		# Never allocate a whole-map AStar grid for a remote parcel.
		if absf(start.x - finish.x) > 64 or absf(start.z - finish.z) > 64:
			path.clear(); target = finish; blocked = true
			return
		super.plan(start, finish, state)

var route := OrchardRoute.new()
var index := -1
var kind := ""
var pending: Dictionary = {}
var placement := Vector3.INF
var working := false
var signature := ""
var configuration: Dictionary = {}
var wait := 0.0

func reset() -> void:
	route.reset(0)
	index = -1
	kind = ""
	pending = {}
	placement = Vector3.INF
	working = false
	signature = ""
	configuration = {}
	wait = 0

func spawn(world: FarmWorld, state: FarmState) -> void:
	route.prepare(world, state)
	var origin := state.center
	for selected in state.orchard_staff.trees:
		if selected >= 0 and selected < state.items.size():
			origin = Vector2(state.items[selected].x, state.items[selected].z)
			break
	for radius in [3.0, 4.0, 5.0, 7.0, 10.0]:
		for step in range(16):
			var p: Vector2 = origin + Vector2(sin(step * TAU / 16), cos(step * TAU / 16)) * radius
			var candidate := Vector3(p.x, FarmLandscape.height_at(p), p.y)
			if route.walkable(candidate, state):
				world.staff_root.position = candidate
				return

func _valid(state: FarmState) -> bool:
	if index < 0 or index >= state.items.size() or index not in state.orchard_staff.trees: return false
	var item: Dictionary = state.items[index]
	return is_same(item, pending) and placement == Vector3(item.x, item.turn, item.z) and FarmOrchardStaff.job(state, index) == kind

func _blocked(world: FarmWorld, state: FarmState) -> void:
	reset()
	state.orchard_staff.paused = true
	state.orchard_staff.reason = "blocked"
	state.staff_notice = "Zeca pausou: caminho bloqueado ou distante. Libere a passagem e retome o pomar em H."
	world.staff_label.text = "ZECA • CAMINHO BLOQUEADO"
	world.staff_actor.action_time = 0

func _choose(world: FarmWorld, state: FarmState) -> bool:
	route.prepare(world, state)
	var candidates: Array[Dictionary] = []
	for selected in state.orchard_staff.trees:
		var job := FarmOrchardStaff.job(state, int(selected))
		if job.is_empty(): continue
		var tree: Dictionary = state.items[int(selected)]
		candidates.append({"index": int(selected), "kind": job, "distance": Vector2(tree.x, tree.z).distance_squared_to(Vector2(world.staff_root.position.x, world.staff_root.position.z))})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	for candidate in candidates:
		var tree: Dictionary = state.items[candidate.index]
		for offset in [Vector2(0,3), Vector2(3,0), Vector2(0,-3), Vector2(-3,0)]:
			var p: Vector2 = Vector2(tree.x, tree.z) + offset
			route.plan(world.staff_root.position, Vector3(p.x, FarmLandscape.height_at(p), p.y), state)
			if route.blocked: continue
			index = candidate.index
			kind = candidate.kind
			pending = tree
			placement = Vector3(tree.x, tree.turn, tree.z)
			return true
	if not candidates.is_empty(): _blocked(world, state)
	return false

func update(world: FarmWorld, state: FarmState, delta: float) -> void:
	if delta <= 0: return # Client presentation must never execute worker economics.
	delta = minf(delta, .1)
	var actor := world.staff_actor
	var node := world.staff_root
	var current := str(state.orchard_staff.trees) + str(state.orchard_staff.enabled) + str(state.orchard_staff.paused)
	if current != signature or not is_same(configuration,state.orchard_staff):
		reset()
		signature = current
		configuration = state.orchard_staff
		actor.action_time = 0
	if not FarmOrchardStaff.active(state) or state.temporary_down.get("npc:staff", false):
		reset()
		actor.action_time = 0
		world.staff_label.text = "ZECA • POMAR PAUSADO"
		actor.animate(delta, false, false, false)
		return
	if index >= 0 and not _valid(state):
		reset(); actor.action_time = 0
		return
	if working:
		if node.position.distance_to(route.target) > .18 or not route.walkable(node.position, state):
			_blocked(world, state)
			return
		actor.animate(delta * FarmCrew.speed(state.staff), false, false, false)
		world.staff_label.text = "ZECA • REGANDO" if kind == "water" else "ZECA • COLHENDO LARANJAS"
		if actor.action_time <= 0:
			var result := FarmOrchardStaff.complete(state, index, kind)
			if not result.is_empty():
				state.staff_notice = result
				if FarmOrchardStaff.active(state):
					state.orchard_staff.paused = true
					state.orchard_staff.reason = "manual"
			if result.is_empty() and kind == "harvest":
				world.irrigation_feedback.floating_text(Vector3(pending.x, FarmLandscape.height_at(Vector2(pending.x,pending.z)) + 2, pending.z), "+6 laranjas", Color("ffce72"))
			world.update_orchards(state)
			reset()
		return
	if index < 0:
		wait -= delta
		if wait > 0: return
		if not _choose(world, state):
			wait = .5
			if not state.orchard_staff.paused: world.staff_label.text = "ZECA • POMAR EM DIA"
			actor.animate(delta, false, false, false)
			return
	var remaining := delta * 1.6 * FarmCrew.speed(state.staff)
	var moving := false
	while not route.path.is_empty() and remaining > 0:
		var direction := route.path[0] - node.position
		direction.y = 0
		if direction.length() < .04:
			route.path.remove_at(0)
			continue
		var step := minf(remaining, direction.length())
		var next := node.position + direction.normalized() * step
		if not route.walkable(next, state):
			_blocked(world, state)
			return
		node.position = Vector3(next.x, FarmLandscape.height_at(Vector2(next.x,next.z)), next.z)
		node.rotation.y = lerp_angle(node.rotation.y, atan2(direction.x,direction.z), minf(delta * 8, 1))
		remaining -= step
		moving = true
	world.staff_label.text = "ZECA • INDO REGAR" if kind == "water" else "ZECA • INDO COLHER"
	actor.animate(delta * FarmCrew.speed(state.staff), moving, false, false)
	if node.position.distance_to(route.target) < .16 and _valid(state):
		var face := Vector3(pending.x,0,pending.z) - node.position
		node.rotation.y = atan2(face.x,face.z)
		actor.play(kind)
		actor.animate(.001, false, false, false)
		working = true
		world.staff_label.text = "ZECA • REGANDO" if kind == "water" else "ZECA • COLHENDO LARANJAS"
		if kind == "water":
			world.irrigation_feedback.water(Vector3(pending.x, node.position.y, pending.z), actor.can.global_position, false, "", actor.can)
