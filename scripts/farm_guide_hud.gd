class_name FarmGuideHUD
extends RefCounted
var tab:="next"
var page:=0
var pinned:=""
var tracked_state:FarmState
var tracker:Button

func setup(hud:FarmHUD) -> void:
	FarmGameUI.action(hud,hud.walking.root,"Caderno do Fazendeiro",Rect2(24,704,335,42),"guide")
	tracker=FarmGameUI.action(hud,hud.walking.root,"",Rect2(24,752,335,43),"guide")
	tracker.add_theme_font_size_override("font_size",14)
	tracker.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	tracker.hide()
	FarmGameUI.action(hud,hud.construction.root,"Caderno",Rect2(710,22,190,56),"guide")

func update(s:FarmState) -> void:
	if tracked_state!=s:pinned="";tracked_state=s
	tracker.visible=not pinned.is_empty()
	if pinned.is_empty():return
	for row in FarmGuide.entries(s):
		if row.key!=pinned:continue
		tracker.text=("✓ " if row.done else "Seguindo · ")+row.title
		tracker.tooltip_text=row.benefit+"\n"+row.detail
		return
	pinned="";tracker.hide()

func show(h:FarmHUD,s:FarmState) -> void:
	update(s)
	var rows:=FarmGuide.select_rows(s,tab)
	var pages:=maxi(1,ceili(rows.size()/3.0))
	page=clampi(page,0,pages-1)
	var p:=FarmGameUI.open(h,"guide","Caderno do Fazendeiro","book",1080,800)
	for i in range(3):
		var key:String=["next","all","done"][i]
		FarmGameUI.action(h,p,["Próximos passos","Todos os caminhos","Concluídos"][i],Rect2(26+i*345,110,334,42),"guide:tab:"+key,tab==key)
	h.label(p,"Escolha seu caminho. As dicas acompanham sua fazenda; não há prazo nem obrigação.",Vector2(28,162),Vector2(1024,28),17)
	if rows.is_empty():h.label(p,"Nenhuma etapa nesta página. Explore os outros caminhos do caderno.",Vector2(28,230),Vector2(1000,60),22)
	for i in range(3):
		var index:=page*3+i
		if index>=rows.size():break
		var row:Dictionary=rows[index]
		var card:=FarmGameUI.card(h,p,Rect2(26,204+i*169,1028,158))
		h.label(card,("✓ " if row.done else "")+row.title,Vector2(16,8),Vector2(760,30),23)
		wrapped(h,card,row.benefit,Rect2(16,43,768,40),17,FarmHUD.INK)
		wrapped(h,card,row.detail,Rect2(16,88,768,61),16,FarmHUD.MUTED)
		FarmGameUI.action(h,card,"Deixar de seguir" if pinned==row.key else "Acompanhar",Rect2(804,20,208,44),"guide:pin:"+row.key,pinned==row.key)
		var b:=FarmGameUI.action(h,card,"Ver orientação",Rect2(804,85,208,44),"guide:open:"+row.key)
		b.disabled=row.action.is_empty()
	FarmGameUI.action(h,p,"‹ Anterior",Rect2(26,733,190,42),"guide:page:-1").disabled=page==0
	h.label(p,"Página %d de %d"%[page+1,pages],Vector2(230,740),Vector2(250,30),18)
	FarmGameUI.action(h,p,"Próxima ›",Rect2(480,733,190,42),"guide:page:1").disabled=page==pages-1
	FarmGameUI.action(h,p,"Voltar ao campo",Rect2(734,733,320,42),"close",true)

static func wrapped(h:FarmHUD,parent:Control,text:String,rect:Rect2,font:int,color:Color) -> Label:
	# Set wrapping before text: Label's unwrapped minimum otherwise expands its width.
	var label:=h.label(parent,"",rect.position,rect.size,font,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.text=text
	label.size=rect.size
	return label

func handle(game:Node3D,value:String) -> bool:
	if value!="guide" and not value.begins_with("guide:"):return false
	if not game.session_started:return true
	if value=="guide:mine":
		game.navigator.select(FarmResourceSites.MINE_AT,"Mina da Pedra Clara","mine")
		game.hud.close_modal();return true
	if value.begins_with("guide:building:"):
		var kind:=value.get_slice(":",2)
		for item in game.state.items:
			if item.kind==kind:
				game.navigator.select(Vector2(item.x,item.z),FarmState.ITEMS[kind].name)
				game.hud.close_modal();return true
		show(game.hud,game.state);return true
	if value.begins_with("guide:tab:"):tab=value.get_slice(":",2);page=0
	elif value.begins_with("guide:page:"):page+=int(value.get_slice(":",2))
	elif value.begins_with("guide:pin:"):
		var key:=value.get_slice(":",2)
		pinned="" if pinned==key else key
		update(game.state);game.hud.close_modal();return true
	elif value.begins_with("guide:open:"):
		for row in FarmGuide.entries(game.state):
			if row.key==value.get_slice(":",2) and not row.action.is_empty():
				game.hud.close_modal();game._action(row.action);return true
	show(game.hud,game.state)
	return true
