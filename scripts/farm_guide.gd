class_name FarmGuide
extends RefCounted
## Read-only advice: requirements come from the same catalogs as purchases.
static func entry(key:String,title:String,benefit:String,detail:String,done:bool,action:String="",ready:bool=true) -> Dictionary:
	return {"key":key,"title":title,"benefit":benefit,"detail":detail,"done":done,"action":action,"ready":ready}

static func building(s:FarmState,kind:String,benefit:String) -> Dictionary:
	var owned:=s.count_items(kind)>0
	var unlocked:=FarmLevels.unlocked(s,kind)
	var cost:int=FarmState.ITEMS[kind].cost
	var detail:="Já existe na sua fazenda." if owned else "TAB → Construir → %s · $%d."%[FarmState.ITEMS[kind].name,cost]
	if not owned and s.game_mode=="sandbox":detail="Liberado no Sandbox. Abra Construir e escolha um lugar."
	elif not owned and not unlocked:detail="Requer fazenda nível %d. Produza e entregue encomendas para ganhar XP. Custo: $%d."%[FarmLevels.required(kind),cost]
	elif not owned and s.money<cost:detail+=" Faltam $%d."%(cost-s.money)
	if not s.claimed:detail="Escolha seu primeiro terreno antes de construir. "+detail
	var action:="guide:building:"+kind if owned else "tool:"+kind if s.claimed else "objectives"
	return entry(kind,"Construa: "+FarmState.ITEMS[kind].name,benefit,detail,owned,action,s.claimed and unlocked and s.money>=cost)

static func entries(s:FarmState) -> Array[Dictionary]:
	var rows:Array[Dictionary]=[]
	for step in FarmState.JOURNEY:
		# Early guidance already records historical achievements in existing saves.
		var current:bool=s.journey_step()<FarmState.JOURNEY.size() and FarmState.JOURNEY[s.journey_step()].key==step.key
		var action:String={"land":"parcels","plots":"tool:plot","water":"objectives","harvest":"objectives","sale":"market","contract":"market_orders","coop":"tool:coop","expand":"parcels"}[step.key]
		# Use the actual journey handler for its current step: first-land selection,
		# the original carrot contract and the $900 expansion have distinct flows.
		if current:action="journey"
		var detail:="Concluído na jornada inicial." if s.milestones.get(step.key,false) else "Seu próximo passo na jornada." if current else "Você pode planejar esta etapa; avance na jornada inicial para chegar até ela."
		var body:String=step.body.replace("\n"," ")
		if step.key=="harvest":body="Caminhe pela fazenda enquanto a plantação cresce. Quando estiver pronta, aproxime-se e use E para colher."
		if s.game_mode=="sandbox" and step.key in ["land","coop","expand"]:detail+=" No Sandbox, o dinheiro é infinito."
		rows.append(entry("start_"+step.key,step.title,body,detail,s.milestones.get(step.key,false),action if s.claimed or step.key=="land" else "objectives",current))
	rows.append(building(s,"barn","Guarde produtos e organize a produção da fazenda."))
	rows.append(building(s,"workshop","Use a bancada e melhore seus regadores para cuidar de mais canteiros."))
	rows.append(building(s,"garage","Melhore o motor, os pneus e a caçamba da camionetinha."))
	rows.append(entry("rosa","Faça uma entrega a Dona Rosa","Entregas rendem dinheiro, confiança e influência no vale.","Visite a casa de Dona Rosa. Aceite o pedido e leve os produtos na caçamba da camionetinha.",s.residents.rosa.done>0,"residents",s.claimed))
	for key in ["rod","pickaxe","mine"]:
		var owned:bool=s.resources.mine_owned if key=="mine" else s.resources[key]
		var price:int=FarmResources.PRICES[key]
		var detail:="Adquirido." if owned else ("Compre na entrada da mina." if key=="mine" else "Compre no armazém, em Pesca e mineração.")
		if not owned:detail+=" Custo: $%d."%price
		if not owned and s.money<price:detail+=" Faltam $%d."%(price-s.money)
		rows.append(entry(key,"Adquira: "+FarmResources.NAMES[key],{"rod":"Pesque nos pontos de água e venda sua captura.","pickaxe":"Prepare sua ferramenta para extrair minérios.","mine":"Tenha acesso aos veios e aos materiais das melhorias do carro."}[key],detail,owned,"guide:mine" if key=="mine" else "resources",s.claimed and s.money>=price))
	rows.append(entry("fish","Faça sua primeira pescaria","Outra fonte de renda para variar o trabalho na fazenda.","Com a vara, encontre um ponto de pesca no mapa, aproxime-se e use E.",s.resources.caught>0,"map",s.resources.rod))
	rows.append(entry("ore","Extraia seu primeiro minério","Cobre e ferro servem para instalar melhorias na garagem.","Adquira a mina e uma picareta. Entre, aproxime-se de um veio e use E.",s.resources.mined>0,"guide:mine",s.resources.mine_owned and s.resources.pickaxe))
	for key in ["tires","bed","engine"]:
		var offer:Dictionary=FarmGarage.UPGRADES[key]
		var owned:bool=FarmGarage.config(s)[key]
		var detail:="Instalada na camionetinha." if owned else "Requer garagem. Estacione junto dela e fique perto do carro."
		if not owned:
			if s.game_mode=="sandbox":detail+=" Materiais e dinheiro liberados no Sandbox."
			else:detail+=" $%d + %d %s (estoque: %s)."%[offer.cost,offer.amount,FarmResources.NAMES[offer.ore],s.stock_text(offer.ore)]
		rows.append(entry("truck_"+key,offer.title,offer.detail,detail,owned,"garage:open",s.count_items("garage")>0 and s.money>=offer.cost and s.stock(offer.ore)>=offer.amount))
	rows.append(building(s,"corral","Cuide das vacas e recolha leite para vender ou fazer queijo."))
	rows.append(building(s,"stable","Construa um abrigo para seu cavalo e explore o vale montado."))
	rows.append(building(s,"cheesery","Transforme leite em queijo para vender produtos de maior valor."))
	for level in [1,2]:
		var key:="gallery_%d"%level
		var ready:bool=s.resources.mine_owned and s.resources.pickaxe and s.resources.gallery_level>=level-1 and s.money>=FarmResources.PRICES[key]
		rows.append(entry(key,"Explore: "+FarmResources.NAMES[key],"Encontre ferro e quartzo mais fundo." if level==1 else "Alcance os veios de ouro e ametista.","Requer mina, picareta e galeria anterior. Desbloqueio na entrada: $%d."%FarmResources.PRICES[key],s.resources.gallery_level>=level,"mine_gallery",ready))
	return rows

static func select_rows(s:FarmState,tab:String) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var pending:Array[Dictionary]=[]
	for row in entries(s):
		if tab=="all" or (tab=="done" and row.done):result.append(row)
		elif tab=="next" and not row.done:
			if row.ready:result.append(row)
			else:pending.append(row)
	if tab=="next":
		result.append_array(pending)
		if result.size()>3:result.resize(3)
	return result
