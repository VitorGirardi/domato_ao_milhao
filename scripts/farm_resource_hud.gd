class_name FarmResourceHUD
extends RefCounted

static func show(game:Node3D) -> void:
	var h:FarmHUD=game.hud
	var s:FarmState=game.state
	var p:=FarmGameUI.open(h,"resources","Pesca e mineração","coins",950,690)
	var entries:=["rod","pickaxe","mine"]
	var titles:=["Vara de pesca","Picareta","Mina da Pedra Clara"]
	for i in range(3):
		var key:String=entries[i]
		var owned:bool=s.resources.mine_owned if key=="mine" else bool(s.resources[key])
		var card:=FarmGameUI.card(h,p,Rect2(26+i*302,112,288,142))
		h.label(card,titles[i],Vector2(14,10),Vector2(260,30),20)
		h.label(card,["Peixes dos lagos e do rio","Cobre, ferro e quartzo","Propriedade da fazenda"][i],Vector2(14,46),Vector2(260,25),15,FarmHUD.MUTED)
		var buy:=FarmGameUI.action(h,card,"Adquirido" if owned else "Comprar · $%d"%FarmResources.PRICES[key],Rect2(14,85,260,42),"resource:buy:"+key,true)
		buy.disabled=owned or not s.claimed or s.money<FarmResources.PRICES[key]
		if key=="mine" and game.player.position.distance_to(FarmResourceSites.point(FarmResourceSites.MINE_AT))>3:
			buy.disabled=true
			if not owned:buy.text="Compre na entrada da mina"
	h.label(p,"Aproxime-se dos pontos no mapa e use E. Mexer-se ou abrir um menu cancela a coleta.",Vector2(28,270),Vector2(894,30),16,FarmHUD.MUTED)
	var keys:Array=FarmResources.FISH_KEYS+FarmResources.ORE_KEYS
	for i in range(keys.size()):
		var key:String=keys[i]
		var count:int=1 if s.infinite_resources() else s.stock(key)
		var card:=FarmGameUI.card(h,p,Rect2(26+(i%2)*453,312+(i/2)*94,439,82))
		h.label(card,FarmResources.NAMES[key],Vector2(14,8),Vector2(198,27),20)
		h.label(card,"%s no estoque · $%d cada"%[s.stock_text(key),FarmResources.PRICES[key]],Vector2(14,44),Vector2(230,24),15,FarmHUD.MUTED)
		var sell:=FarmGameUI.action(h,card,("Vender 1 · $%d" if s.infinite_resources() else "Vender · $%d")%(count*FarmResources.PRICES[key]),Rect2(248,20,176,42),"resource:sell:"+key)
		sell.disabled=count==0
	h.label(p,"Estoque e propriedade compartilhados no cooperativo. Veios renovam em 2 minutos de jogo.",Vector2(28,607),Vector2(894,28),15,FarmHUD.MUTED)
	FarmGameUI.action(h,p,"Voltar ao campo",Rect2(28,642,288,34),"close")
	FarmGameUI.action(h,p,"Encontrar no mapa",Rect2(330,642,288,34),"map")
	FarmGameUI.action(h,p,"Armazém",Rect2(632,642,288,34),"market")

static func show_galleries(game:Node3D) -> void:
	var h:FarmHUD=game.hud
	var s:FarmState=game.state
	var p:=FarmGameUI.open(h,"mine_gallery","As galerias da Pedra Clara","coins",880,570)
	h.label(p,"Use os minérios da mina para abrir novos caminhos.",Vector2(28,110),Vector2(824,32),21)
	for i in range(2):
		var key:="gallery_%d"%(i+1)
		var ore:="copper" if i==0 else "iron"
		var count:=8 if i==0 else 10
		var opened:bool=s.resources.gallery_level>i
		var near:bool=game.player.position.distance_to(FarmResourceSites.point(FarmMineLayout.GALLERY_AT[i]))<=3
		var card:=FarmGameUI.card(h,p,Rect2(28,160+i*150,824,138))
		h.label(card,FarmMineLayout.TITLES[i],Vector2(18,12),Vector2(450,30),24)
		h.label(card,"Mais cobre e ferro entre os túneis." if i==0 else "Veios de quartzo no coração da montanha.",Vector2(18,48),Vector2(470,26),17,FarmHUD.MUTED)
		h.label(card,"$%d + %d %s · estoque: %s"%[FarmResources.PRICES[key],count,FarmResources.NAMES[ore],s.stock_text(ore)],Vector2(18,88),Vector2(490,28),18)
		var button:=FarmGameUI.action(h,card,"Passagem aberta" if opened else "Liberar passagem",Rect2(535,43,268,46),"resource:buy:"+key,true)
		button.disabled=opened or not near or not s.resources.mine_owned or not s.resources.pickaxe or s.resources.gallery_level!=i or s.money<FarmResources.PRICES[key] or s.stock(ore)<count
		if not opened and not near:button.text="Vá até a passagem"
	h.label(p,"As passagens abertas e os minérios são compartilhados no cooperativo.",Vector2(28,470),Vector2(824,32),17,FarmHUD.MUTED)
	FarmGameUI.action(h,p,"Voltar à exploração",Rect2(28,520,396,34),"close")
	FarmGameUI.action(h,p,"Estoque e ferramentas",Rect2(452,520,400,34),"resources")
