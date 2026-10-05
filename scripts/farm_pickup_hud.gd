class_name FarmPickupHUD
extends Control
## Compact driving instruments; the center of the road stays unobstructed.
var speed:Label
var gear:Label
var status:Label
var leave:Button
var wheel_angle:=0.0

func setup(hud:FarmHUD) -> void:
	position=Vector2(1086,514);size=Vector2(330,338);mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.walking.root.add_child(self)
	speed=hud.label(self,"0",Vector2(20,36),Vector2(155,58),43,FarmHUD.CREAM)
	hud.label(self,"CAMIONETINHA",Vector2(20,12),Vector2(285,24),15,FarmHUD.CREAM)
	hud.label(self,"km/h",Vector2(23,94),Vector2(70,24),15,FarmHUD.CREAM)
	gear=hud.label(self,"N",Vector2(96,92),Vector2(80,26),18,Color("edbc61"))
	status=hud.label(self,"",Vector2(20,133),Vector2(290,35),15,Color("edbc61"))
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hud.label(self,"W / S  acelerar · frear / ré\nA / D  virar     Espaço  freio",Vector2(20,181),Vector2(290,47),15,FarmHUD.CREAM)
	FarmGameUI.action(hud,self,"V · Caçamba",Rect2(18,230,294,34),"pickup:cargo")
	leave=FarmGameUI.action(hud,self,"E · Sair",Rect2(18,278,294,42),"nearby_interact",true)
	leave.add_theme_font_size_override("font_size",18)
	visible=false

func update_drive(vehicle:FarmPickup) -> void:
	visible=vehicle.mounted and vehicle.available() and vehicle.game.hud.modal_kind.is_empty()
	speed.text=str(roundi(absf(vehicle.speed)*3.6))
	gear.text="RÉ" if vehicle.speed<-.2 else "D" if vehicle.speed>.2 else "N"
	status.text=vehicle.blocked_reason if not vehicle.blocked_reason.is_empty() else "Carga · %d / %d unidades"%[FarmPickupCargo.count(FarmPickupCargo.contents(vehicle.game.state)),FarmPickupCargo.CAPACITY]
	leave.disabled=absf(vehicle.speed)>1.2
	leave.text="Pare para sair" if leave.disabled else "E · Sair da camionetinha"
	wheel_angle=vehicle.steering*2.5;queue_redraw()

func _draw() -> void:
	var panel:=StyleBoxFlat.new();panel.bg_color=Color(.07,.16,.12,.9);panel.set_corner_radius_all(18)
	panel.set_border_width_all(1);panel.border_color=Color(.8,.78,.6,.4)
	draw_style_box(panel,Rect2(Vector2.ZERO,size))
	var center:=Vector2(249,87);var cream:=Color("eee2bc")
	draw_arc(center,45,0,TAU,64,Color("17271e"),13,true)
	draw_arc(center,45,0,TAU,64,cream,5,true)
	for angle in [0.0,PI,PI/2]:
		var end:=Vector2.from_angle(angle+wheel_angle)*40
		draw_line(center,center+end,cream,7,true)
	draw_circle(center,13,Color("73957b"),true,-1,true)
	draw_circle(center,6,cream,true,-1,true)
