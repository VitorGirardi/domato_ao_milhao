class_name FarmLevelsHUD
extends RefCounted
var root:Button
var title:Label
var progress:ProgressBar
var detail:Label

func setup(hud:FarmHUD,parent:Control,rect:Rect2,compact:bool=false) -> void:
	root=FarmGameUI.action(hud,parent,"",rect,"farm_levels")
	title=hud.label(root,"",Vector2(12,3),Vector2(rect.size.x-24,25),14 if compact else 18,FarmHUD.CREAM)
	detail=hud.label(root,"",Vector2(12,24 if compact else 30),Vector2(rect.size.x-24,22),12 if compact else 14,FarmHUD.CREAM)
	progress=ProgressBar.new();progress.position=Vector2(12,rect.size.y-10);progress.size=Vector2(rect.size.x-24,5)
	progress.add_theme_font_size_override("font_size",1)
	progress.add_theme_constant_override("outline_size",0)
	progress.show_percentage=false;progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for key in ["background","fill"]:
		var box:=StyleBoxFlat.new();box.bg_color=Color("304c3d") if key=="background" else Color("edbd64")
		box.set_corner_radius_all(2);progress.add_theme_stylebox_override(key,box)
	root.add_child(progress)
	progress.set_deferred("size",Vector2(rect.size.x-24,5))
	root.tooltip_text="Ver níveis e construções • XP por produção e encomendas"

func update(state:FarmState) -> void:
	var level:=FarmLevels.level(state.farm_xp)
	title.text="FAZENDA · NÍVEL %d"%level
	detail.text=FarmLevels.next_text(state.farm_xp)
	var start:int=FarmLevels.THRESHOLDS[level-1]
	progress.max_value=FarmLevels.THRESHOLDS[level]-start if level<6 else 1
	progress.value=state.farm_xp-start if level<6 else 1

static func show(hud:FarmHUD,state:FarmState) -> void:
	var level:=FarmLevels.level(state.farm_xp)
	var p:=FarmGameUI.open(hud,"farm_levels","Sua fazenda · Nível %d"%level,"upgrade",860,640)
	hud.label(p,FarmLevels.next_text(state.farm_xp),Vector2(28,111),Vector2(804,34),24)
	hud.label(p,"%d XP no total  •  Produza e entregue encomendas para crescer."%state.farm_xp,Vector2(28,149),Vector2(804,26),16)
	for i in range(6):
		var kind:String=FarmLevels.BUILDINGS[i]
		var unlocked:=level>=i+1
		var card:=FarmGameUI.card(hud,p,Rect2(28+(i%3)*272,193+(i/3)*150,260,138))
		FarmGameUI.icon(card,FarmLevels.ICONS[i],Rect2(12,18,57,57))
		hud.label(card,"Curral + estrebaria" if kind=="corral" else FarmState.ITEMS[kind].name,Vector2(78,16),Vector2(172,30),16 if kind=="corral" else 20)
		hud.label(card,"Nível %d · %d XP"%[i+1,FarmLevels.THRESHOLDS[i]],Vector2(78,52),Vector2(172,25),14)
		var b:=FarmGameUI.action(hud,card,"Liberado" if unlocked else "Bloqueado",Rect2(12,91,236,35),"close",unlocked)
		b.disabled=true
		b.icon=load("res://assets/ui/%s.svg"%("check" if unlocked else "lock"));b.expand_icon=true;b.add_theme_constant_override("icon_max_width",20)
		if unlocked: b.add_theme_color_override("font_disabled_color",Color("304c3d"))
	hud.label(p,"Colheita +10  •  Ovo +2  •  Leite +3/L  •  Queijo +8  •  Encomenda +30",Vector2(28,504),Vector2(804,25),16)
	hud.label(p,"Ajudantes também dão XP. Construções liberadas ainda custam moedas.",Vector2(28,534),Vector2(804,25),15,FarmHUD.MUTED)
	FarmGameUI.action(hud,p,"Bora cuidar da fazenda!",Rect2(260,578,340,42),"close",true)
