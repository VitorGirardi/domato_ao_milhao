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
		var count:int=s.resources.stock[key]
		var card:=FarmGameUI.card(h,p,Rect2(26+(i%2)*453,312+(i/2)*94,439,82))
		h.label(card,FarmResources.NAMES[key],Vector2(14,8),Vector2(198,27),20)
		h.label(card,"%d no estoque · $%d cada"%[count,FarmResources.PRICES[key]],Vector2(14,44),Vector2(230,24),15,FarmHUD.MUTED)
		var sell:=FarmGameUI.action(h,card,"Vender · $%d"%(count*FarmResources.PRICES[key]),Rect2(248,20,176,42),"resource:sell:"+key)
		sell.disabled=count==0
	h.label(p,"Estoque e propriedade compartilhados no cooperativo. Veios renovam em 2 minutos de jogo.",Vector2(28,607),Vector2(894,28),15,FarmHUD.MUTED)
	FarmGameUI.action(h,p,"Voltar ao campo",Rect2(28,642,288,34),"close")
	FarmGameUI.action(h,p,"Encontrar no mapa",Rect2(330,642,288,34),"map")
	FarmGameUI.action(h,p,"Armazém",Rect2(632,642,288,34),"market")
