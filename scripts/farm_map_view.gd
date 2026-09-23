class_name FarmMapView
extends Control
## North is -Z. Both views project the actual world geometry, never a separate map.
signal picked(point:Vector2)
signal place_picked(key:String)
var zoom:=1.0
var focus:=REGION.get_center()
var icons:Dictionary={}
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
	return Rect2(focus-REGION.size/zoom/2,REGION.size/zoom) if full else Rect2(player_at-Vector2(55,44),Vector2(110,88))

func scale_factor() -> float:return minf(size.x/bounds().size.x,size.y/bounds().size.y)
func origin() -> Vector2:return (size-bounds().size*scale_factor())/2
func project(p:Vector2) -> Vector2:return origin()+(p-bounds().position)*scale_factor()
func unproject(p:Vector2) -> Vector2:return bounds().position+(p-origin())/scale_factor()

func _ready() -> void:
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_STOP

func nearest(point:Vector2) -> Dictionary:
	var closest:Dictionary={}
	var distance:=16.0
	for entry in locations:
		var d:=project(entry.at).distance_to(point)
		if d<distance and d<(15 if entry.has("icon") else 6):distance=d;closest=entry
	return closest

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseMotion:
		var entry:=nearest(event.position)
		tooltip_text=entry.name+"\n"+entry.get("notice","") if not entry.is_empty() else "Clique para marcar um destino"
	if full and event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var before:=unproject(event.position)
			zoom=clampf(zoom*(1.3 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.3),1,6)
			focus+=before-unproject(event.position)
			var half:=REGION.size/zoom/2
			focus=focus.clamp(REGION.position+half,REGION.end-half)
			queue_redraw();accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			var entry:=nearest(event.position)
			var point:=unproject(event.position)
			if not entry.is_empty():place_picked.emit(entry.key)
			elif Rect2(FarmLandscape.WALK_MIN,FarmLandscape.WALK_MAX-FarmLandscape.WALK_MIN).has_point(point):picked.emit(point)
			accept_event()

func place_icon(entry:Dictionary) -> void:
	if not entry.has("icon"):return
	var at:=project(entry.at)
	if not Rect2(Vector2(12,24),size-Vector2(24,48)).has_point(at):return
	var key:String=entry.icon
	if not icons.has(key):icons[key]=load("res://assets/ui/%s.svg"%key)
	var radius:=13.0 if full else 10.0
	draw_circle(at,radius+2,Color("294739"))
	draw_circle(at,radius,Color("fff1cb") if entry.key!="friend" else Color("80d7e0"))
	draw_texture_rect(icons[key],Rect2(at-Vector2.ONE*(radius-1),Vector2.ONE*(radius-1)*2),false)
	if not entry.get("notice","").is_empty():
		var badge:=at+Vector2(radius-2,-radius+1)
		draw_circle(badge,7,Color("f6bd53"))
		draw_string(ThemeDB.fallback_font,badge+Vector2(-2,4),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("302f23"))

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
	for entry in locations:
		if entry.get("group","")!="Companhia":place_icon(entry)
	for entry in locations:
		if entry.get("group","")=="Companhia":place_icon(entry)
	if has_destination:
		var target:=project(destination).clamp(Vector2(12,12),size-Vector2(12,12))
		draw_line(project(player_at),target,Color("f8e193"),2,true)
		draw_arc(target,17,0,TAU,40,Color("342e25"),5,true)
		draw_arc(target,17,0,TAU,40,Color("ffcf5e"),2,true)
	var at:=project(player_at)
	var direction:=Vector2(sin(heading),cos(heading))
	var side:=Vector2(-direction.y,direction.x)
	draw_circle(at,10,Color("294739"))
	draw_colored_polygon(PackedVector2Array([at+direction*12,at-direction*7+side*7,at-direction*3,at-direction*7-side*7]),Color("ffffff"))
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(10,20),"N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("fff6df"))
	var meters:=roundi(50/zoom) if full else 20
	var start:=Vector2(14,size.y-15)
	draw_line(start,start+Vector2(meters*scale_factor(),0),Color("fff6df"),3)
	draw_string(font,start+Vector2(0,-6),"%d m"%meters,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff6df"))
