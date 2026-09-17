class_name FarmGameUI
extends RefCounted

static func icon(parent:Control,key:String,rect:Rect2) -> TextureRect:
	var node:=TextureRect.new()
	node.texture=load("res://assets/ui/%s.svg"%key)
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.position=rect.position; node.size=rect.size
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func open(hud:FarmHUD,kind:String,title:String,key:String,width:float,height:float) -> Panel:
	var p:=hud._modal(kind,height)
	p.position.x=(1440-width)/2; p.size.x=width
	var frame:=hud.style(Color("eee0ba"),12,Color("78573b"))
	frame.set_border_width_all(5); frame.shadow_size=14
	p.add_theme_stylebox_override("panel",frame)
	hud.panel(p,Rect2(8,8,width-16,86),Color("304c3d"))
	icon(p,key,Rect2(23,18,64,64))
	hud.label(p,title,Vector2(102,29),Vector2(width-192,46),32,FarmHUD.CREAM)
	action(hud,p,"×",Rect2(width-65,28,42,42),"close",false).tooltip_text="Fechar • Esc"
	return p

static func action(hud:FarmHUD,p:Control,text:String,rect:Rect2,value:String,primary:bool=false) -> Button:
	var b:=hud.button(p,text,rect,value,primary)
	for state in ["normal","hover","pressed","disabled"]:
		var color:=Color("eabc5b") if primary else Color("4d725b")
		if state=="hover": color=color.lightened(0.12)
		if state=="pressed": color=color.darkened(0.1)
		if state=="disabled": color=Color("d3c8aa")
		var box:=hud.style(color,6,Color("9c875f") if state=="disabled" else Color("36533f"))
		box.shadow_size=0; box.set_border_width_all(2); box.border_width_bottom=4
		b.add_theme_stylebox_override(state,box)
	for key in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(key,FarmHUD.INK if primary else FarmHUD.CREAM)
	b.add_theme_color_override("font_disabled_color",Color("716d5b"))
	return b

static func card(hud:FarmHUD,p:Control,rect:Rect2) -> Panel:
	var node:=hud.panel(p,rect,Color("faf0d5"))
	var face:=hud.style(Color("faf0d5"),8,Color("c6af7e"))
	face.shadow_size=0; face.set_border_width_all(2)
	node.add_theme_stylebox_override("panel",face)
	return node

static func meter(hud:FarmHUD,p:Control,rect:Rect2,value:float,color:Color) -> void:
	hud.panel(p,rect,Color("d6c6a1"))
	var fill:=ColorRect.new()
	fill.position=rect.position+Vector2(3,3)
	fill.size=Vector2(maxf(0,(rect.size.x-6)*clampf(value,0,1)),rect.size.y-6)
	fill.color=color; fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	p.add_child(fill)
