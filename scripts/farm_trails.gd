class_name FarmTrails
extends RefCounted
## Shared route geometry feeds ground shading and vegetation clearance.
const ROUTES:=[
	[Vector2(-27,-42),Vector2(-26,-50),Vector2(-19,-55),Vector2(-10,-58),Vector2(-3,-58)],
	[Vector2(-10,-58),Vector2(-9,-70),Vector2(-12,-78),Vector2(-10,-82)],
	[Vector2(-26,44),Vector2(-25,51),Vector2(-18,58),Vector2(-9,60),Vector2(-3,60)],
	[Vector2(-9,60),Vector2(-8,73),Vector2(0,80),Vector2(19,83),Vector2(36,82)],
	[Vector2(66,29),Vector2(75,24),Vector2(78,12),Vector2(78,-4),Vector2(74,-12),Vector2(73,-12)],
	[Vector2(57,27.5),Vector2(57,34),Vector2(60,37)]
]
const STOPS:={
	"mill":{"name":"Mirante dos Ventos","at":Vector2(-10,-85),"radius":5.0,"message":"Mirante dos Ventos • O moinho trabalha até no dia de folga."},
	"picnic":{"name":"Recanto da Prosa","at":Vector2(60,39),"radius":5.0,"message":"Recanto da Prosa • Aqui a única meta é deixar o café esfriar."},
	"cart":{"name":"Curva da Abóbora","at":Vector2(39,84),"radius":5.0,"message":"Curva da Abóbora • A carroça aposentou. As abóboras, não."}
}
var visited:Dictionary={}

static func distance_to_path(p:Vector2) -> float:
	var result:=INF
	for route in ROUTES:
		for i in range(route.size()-1):
			var a:Vector2=route[i];var b:Vector2=route[i+1];var direction:=b-a
			var t:=clampf((p-a).dot(direction)/direction.length_squared(),0,1)
			result=minf(result,p.distance_to(a+direction*t))
	return result

static func reserved(p:Vector2,extra:float=0) -> bool:
	for stop in STOPS.values():
		if p.distance_to(stop.at)<float(stop.radius)+extra:return true
	return false

static func shader_segments() -> PackedVector4Array:
	var segments:=PackedVector4Array()
	for route in ROUTES:
		for i in range(route.size()-1):
			var a:Vector2=route[i];var b:Vector2=route[i+1]
			segments.append(Vector4(a.x,a.y,b.x,b.y))
	return segments

func discover(p:Vector2) -> String:
	for key in STOPS:
		if not visited.has(key) and p.distance_to(STOPS[key].at)<7:
			visited[key]=true
			return STOPS[key].message
	return ""
