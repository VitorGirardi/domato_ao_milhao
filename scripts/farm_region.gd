class_name FarmRegion
extends RefCounted
## Authored geography. Stable coordinates leave room for future adjacent regions.
const MIN := Vector2(-34, -450)
const MAX := Vector2(1050, 450)
const LAKES := [Vector4(285, 260, 48, 32), Vector4(810, -235, 56, 38)]
const LAKE_LEVELS := [5.0, 68.0]
const ROUTES := [
	[Vector3(160, 2, -20), Vector3(205, 3, -8), Vector3(250, 5, 10), Vector3(295, 7, 18), Vector3(340, 6, 12), Vector3(380, 5, 0), Vector3(420, 5, 0), Vector3(460, 5, 0), Vector3(500, 9, -12), Vector3(540, 16, -42), Vector3(565, 24, -80), Vector3(565, 32, -125), Vector3(535, 41, -165), Vector3(530, 49, -210), Vector3(565, 58, -245), Vector3(615, 82, -260), Vector3(665, 104, -285), Vector3(705, 120, -325)],
	[Vector3(615, 82, -260), Vector3(650, 75, -220), Vector3(690, 65, -195), Vector3(730, 67, -175), Vector3(780, 70, -178), Vector3(820, 70, -185), Vector3(868, 74, -185), Vector3(900, 81, -220)],
	[Vector3(250, 5, 10), Vector3(275, 7, 55), Vector3(310, 8, 100), Vector3(345, 9, 135), Vector3(352, 9, 180), Vector3(340, 8, 225), Vector3(350, 7, 285), Vector3(322, 7, 314), Vector3(280, 7, 306), Vector3(230, 8, 300), Vector3(190, 6, 260), Vector3(166, 4, 200), Vector3(133, 2, 90)],
	[Vector3(500, 9, -12), Vector3(535, 11, 35), Vector3(565, 14, 90), Vector3(580, 17, 150), Vector3(630, 21, 198), Vector3(690, 24, 222), Vector3(750, 26, 245), Vector3(820, 30, 285)]
]
const PLACES := {
	"serra_view": {"name": "Mirante da Serra", "at": Vector2(705, -325), "notice": "Vista do vale e do Rio Azul"},
	"serra_mine": {"name": "Mina da Pedra Clara", "at": Vector2(900, -216), "notice": "Compre na entrada · cobre, ferro e quartzo"},
	"valley_lake": {"name": "Lago do Sossego · pesca", "at": Vector2(280, 295), "notice": "Vara de pesca + E na margem"},
	"mountain_lake": {"name": "Lago da Serra · pesca", "at": Vector2(820, -193), "notice": "Vara de pesca + E na margem"},
	"river_fishing": {"name": "Rio Azul · pesca", "at": Vector2(430,45), "notice": "Vara de pesca + E na margem"},
	"blue_bridge": {"name": "Ponte do Rio Azul", "at": Vector2(420, 0), "notice": "Travessia para a serra"},
	"east_meadow": {"name": "Campos do Horizonte", "at": Vector2(820, 285), "notice": "Pastagens e espaço para futuras propriedades"}
}

static func weight(p: Vector2) -> float:
	return smoothstep(0, 70, maxf(p.x-180, absf(p.y)-145)) if p.x >= -34 else 0.0

static func river_x(z: float) -> float:
	return 420.0 + sin(z*0.009)*44.0 + sin(z*0.021)*12.0

static func river_distance(p: Vector2) -> float:
	return absf(p.x-river_x(p.y))

static func road_sample(p: Vector2) -> Vector2:
	var best := Vector2(INF, 0)
	for route in ROUTES:
		for i in range(route.size()-1):
			var a: Vector3 = route[i]; var b: Vector3 = route[i+1]
			var start := Vector2(a.x, a.z); var ab := Vector2(b.x-a.x, b.z-a.z)
			var t := clampf((p-start).dot(ab)/ab.length_squared(), 0, 1)
			var d := p.distance_to(start+ab*t)
			if d < best.x: best = Vector2(d, lerpf(a.y, b.y, t))
	return best

static func highland_height(p: Vector2) -> float:
	var ridge := exp(-pow((p.x-755)/235.0, 2)-pow((p.y+310)/215.0, 2))
	var h := 7.0 + 104.0*ridge + 19.0*exp(-pow((p.x-920)/250.0, 2)-pow((p.y-265)/210.0, 2))
	h += (sin(p.x*.022)*cos(p.y*.017)*4.5 + sin(p.y*.031+p.x*.008)*2.5) * (0.3+ridge)
	h = lerpf(3.2, h, smoothstep(16, 82, river_distance(p)))
	for i in range(LAKES.size()):
		var lake: Vector4 = LAKES[i]
		var d := (Vector2(p.x-lake.x, p.y-lake.y)/Vector2(lake.z, lake.w)).length()
		h = lerpf(LAKE_LEVELS[i]+1.1, h, smoothstep(1.0, 1.7, d))
	var road := road_sample(p)
	var result := lerpf(road.y, h, smoothstep(7, 50, road.x))
	var cave_back := exp(-pow((p.x-900)/45.0,2)-pow((p.y+252)/45.0,2)) * smoothstep(0,16,-220-p.y)
	result += cave_back*24.0
	# Clear the ground beneath the Blender tunnel; its mesh supplies the roof.
	var tunnel_clearance := minf(maxf(absf(p.x-900)-9, absf(p.y+225)-11),FarmMineLayout.clearance(p))
	result = lerpf(81.0,result,smoothstep(0,10,tunnel_clearance))
	return result

static func water_level(p: Vector2) -> float:
	if weight(p) < .99: return -INF
	if river_distance(p) < 12: return 2.0
	for i in range(LAKES.size()):
		var lake: Vector4 = LAKES[i]
		if (Vector2(p.x-lake.x, p.y-lake.y)/Vector2(lake.z, lake.w)).length() < 1:
			return LAKE_LEVELS[i]
	return -INF

static func bed(p: Vector2, h: float) -> float:
	if weight(p) < .99: return h
	h = lerpf(0.6, h, smoothstep(8.5, 15, river_distance(p)))
	for i in range(LAKES.size()):
		var lake: Vector4 = LAKES[i]
		var d := (Vector2(p.x-lake.x, p.y-lake.y)/Vector2(lake.z, lake.w)).length()
		h = lerpf(LAKE_LEVELS[i]-2.0, h, smoothstep(.80, 1.08, d))
	return h

static func on_bridge(p: Vector2) -> bool:
	return Rect2(397, -4, 46, 8).has_point(p)

static func water_blocked(p: Vector2) -> bool:
	var level := water_level(p)
	if level == -INF or on_bridge(p): return false
	return level > bed(p, highland_height(p))+.3

static func reserved(p: Vector2) -> bool:
	if FarmMineLayout.inside(p,7):return true
	if road_sample(p).x < 8 or water_level(p) > -INF: return true
	for place in PLACES.values():
		if p.distance_to(place.at) < 14: return true
	return false
