class_name FarmMapView
extends Control
## North is -Z. Both views project the actual world geometry, never a separate map.
signal picked(point:Vector2)
const REGION:=Rect2(-54,-151,240,302)
var state:FarmState
var player_at:=Vector2.ZERO
var horse_at:=Vector2.ZERO
var heading:=0.0
var full:=false
var destination:=Vector2.ZERO
var has_destination:=false
var terrain:Texture2D
var trees:Array[Vector2]=[]
var locations:Array=[]

static func background() -> Texture2D:
	var img:=Image.create(240,302,false,Image.FORMAT_RGB8)
	for z in range(302):
		for x in range(240):
			var p:=REGION.position+Vector2(x,z)
			var hill:=clampf(FarmLandscape.base_height(p)/4,0,1)
			var color:=Color("849860").lerp(Color("607b52"),hill)
			if absf(p.x-(-42+sin(p.y*.065)*2.6))<5:color=Color("4e959b")
			img.set_pixel(x,z,color)
	return ImageTexture.create_from_image(img)

func bounds() -> Rect2:
	return REGION if full else Rect2(player_at-Vector2(55,44),Vector2(110,88))

func scale_factor() -> float:return minf(size.x/bounds().size.x,size.y/bounds().size.y)
func origin() -> Vector2:return (size-bounds().size*scale_factor())/2
func project(p:Vector2) -> Vector2:return origin()+(p-bounds().position)*scale_factor()
func unproject(p:Vector2) -> Vector2:return bounds().position+(p-origin())/scale_factor()

func _ready() -> void:
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_STOP

func _gui_input(event:InputEvent) -> void:
	if full and event is InputEventMouseMotion:
		tooltip_text="Clique para marcar um destino"
		for entry in locations:
			if project(entry.at).distance_to(event.position)<14:tooltip_text=entry.name;break
	if full and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var point:=unproject(event.position)
		if Rect2(FarmLandscape.WALK_MIN,FarmLandscape.WALK_MAX-FarmLandscape.WALK_MIN).has_point(point):picked.emit(point)
		accept_event()

func line_route(route:Array,width:float,color:Color) -> void:
	var points:=PackedVector2Array()
	for p in route:points.append(project(p))
	draw_polyline(points,color,width,true)

func area(rect:Rect2,color:Color) -> void:
	var screen:=Rect2(project(rect.position),rect.size*scale_factor())
	draw_rect(screen,Color(color,.25));draw_rect(screen,color,false,2)

func marker(p:Vector2,color:Color,radius:float=5) -> void:
	var at:=project(p)
	draw_circle(at,radius+2,Color("294739"));draw_circle(at,radius,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("243f35"))
	if terrain==null or state==null:return
	draw_texture_rect(terrain,Rect2(project(REGION.position),REGION.size*scale_factor()),false)
	for point in trees:
		var at:=project(point)
		draw_circle(at,3*scale_factor(),Color("58794e"))
		draw_circle(at+Vector2(-1,-1),2*scale_factor(),Color("678756"))
	var road:Array=[]
	for z in range(-151,153,3):road.append(Vector2(-27+sin(z*.07)*smoothstep(42,66,absf(z))*3,z))
	line_route(road,maxf(3,5*scale_factor()),Color("d0b98a"));road.clear()
	for x in range(-54,190,3):road.append(Vector2(x,30+sin(x*.09)*smoothstep(44,75,x)*3))
	line_route(road,maxf(3,5*scale_factor()),Color("d0b98a"))
	for route in FarmTrails.ROUTES:line_route(route,maxf(2,3*scale_factor()),Color("c5b282"))
	area(Rect2(FarmLandscape.WALK_MIN,FarmLandscape.WALK_MAX-FarmLandscape.WALK_MIN),Color("cbd2ad"))
	if state.claimed:area(Rect2(state.center-Vector2.ONE*state.land_size/2,Vector2.ONE*state.land_size),Color("f5d774"))
	for key in FarmParcels.LOTS:area(FarmParcels.area(key),Color("f5d774") if key in state.owned_parcels else Color("e4ead0"))
	for item in state.items:
		var rect:=state.item_rect(item.kind,Vector2(item.x,item.z),item.turn)
		draw_rect(Rect2(project(rect.position),rect.size*scale_factor()),Color("936043") if item.kind!="plot" else Color("675742"))
	for stop in FarmTrails.STOPS.values():marker(stop.at,Color("f5d774"),4)
	if full:
		for key in ["mill","orchard","stones","flowers","cart"]:
			var stop:Dictionary=FarmTrails.STOPS[key]
			var title:String={"mill":"Mirante","orchard":"Pomar","stones":"Pedras","flowers":"Flores","cart":"Abóboras"}[key]
			var at:=project(stop.at)+Vector2(8,-8)
			draw_string_outline(ThemeDB.fallback_font,at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,4,Color("344d39"))
			draw_string(ThemeDB.fallback_font,at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("fff6df"))
	marker(Vector2(-24,15),Color("fff1cb"),5)
	marker(Vector2(-33.5,22),Color("c8b2d5"),4)
	marker(horse_at,Color("bc7843"),5)
	if has_destination:
		var target:=project(destination).clamp(Vector2(12,12),size-Vector2(12,12))
		draw_line(project(player_at),target,Color("f8e193"),2,true)
		draw_circle(target,9,Color("342e25"));draw_circle(target,6,Color("ffcf5e"))
		draw_line(target-Vector2(0,12),target+Vector2(0,12),Color.WHITE,2)
		draw_line(target-Vector2(12,0),target+Vector2(12,0),Color.WHITE,2)
	var at:=project(player_at)
	var direction:=Vector2(sin(heading),cos(heading))
	var side:=Vector2(-direction.y,direction.x)
	draw_circle(at,10,Color("294739"))
	draw_colored_polygon(PackedVector2Array([at+direction*12,at-direction*7+side*7,at-direction*3,at-direction*7-side*7]),Color("ffffff"))
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(10,20),"N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("fff6df"))
	var meters:=50 if full else 20
	var start:=Vector2(14,size.y-15)
	draw_line(start,start+Vector2(meters*scale_factor(),0),Color("fff6df"),3)
	draw_string(font,start+Vector2(0,-6),"%d m"%meters,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff6df"))
