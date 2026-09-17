class_name FarmCrewHUD
extends RefCounted

static func show(hud:FarmHUD,state:FarmState) -> void:
	var p:=hud._modal("crew",738)
	hud.label(p,"EQUIPE • TRABALHO SIMULTÂNEO",Vector2(30,24),Vector2(550,27),13,FarmHUD.MUTED)
	hud.label(p,"Mais mãos na fazenda",Vector2(30,61),Vector2(550,44),29)
	hud.label(p,"Dois ajudantes, cada um com sua tarefa e sua pausa.\nSó há cobrança ao concluir serviços. Saldo: $%d"%state.money,Vector2(30,118),Vector2(550,57),16)
	for i in range(2):
		var field:=i==1
		var worker:Dictionary=state.field_staff if field else state.staff
		var kind:="field" if field else "coop"
		var y:=195+i*223
		hud.panel(p,Rect2(24,y,562,208),Color("eee5ce"))
		hud.label(p,("Bento da Horta" if field else "Zeca do Trato")+" • Nível %d"%FarmCrew.level(worker),Vector2(38,y+12),Vector2(530,30),22)
		var status:="Disponível • contratação $120"
		if worker.hired: status="Pausado" if worker.paused else ("Na irrigação" if field else "No galinheiro")
		if not field and state.legacy_irrigation(): status="Na irrigação (rotina anterior)"
		var details:="%s • Gasto total: $%d\n%s"%[status,worker.spent,("%d regas • $%d por canteiro concluído"%[worker.watered,FarmCrew.fee(worker)]) if field else ("Trato: $%d + ração • checagem a cada %d s"%[FarmCrew.fee(worker),FarmStaff.interval(worker)])]
		hud.label(p,details,Vector2(38,y+48),Vector2(530,58),16)
		if field:
			var action:=hud.button(p,"Escolher canteiros" if worker.hired else "Contratar • Ver custos",Rect2(38,y+116,310,38),"irrigation" if worker.hired else "crew_hire_review",true)
			action.disabled=not worker.hired and state.money<120
			var pause:=hud.button(p,"Retomar" if worker.paused else "Pausar",Rect2(360,y+116,212,38),"crew_pause")
			pause.disabled=not worker.hired
		else:
			hud.button(p,"Gerenciar galinheiro / contratar",Rect2(38,y+116,534,38),"staff",true)
		var train:=hud.button(p,"Treinado • Nível 2" if FarmCrew.level(worker)==2 else "Treinar • Ver ganhos",Rect2(38,y+161,310,35),"crew_train_review:"+kind)
		train.disabled=not worker.hired or FarmCrew.level(worker)==2
		if field:
			var dismiss:=hud.button(p,"Dispensar…",Rect2(360,y+161,212,35),"crew_dismiss_review")
			dismiss.disabled=not worker.hired
	hud.label(p,"Bento rega os canteiros escolhidos; não planta nem colhe.\nMenus, construção e jogo fechado pausam os dois.",Vector2(30,650),Vector2(550,42),14,FarmHUD.MUTED)
	hud.button(p,"Voltar ao campo",Rect2(30,694,550,33),"close")

static func confirm(hud:FarmHUD,state:FarmState,kind:String) -> void:
	var p:=hud._modal("crew_confirm",440)
	var title:="Contratar Bento da Horta?"
	var body:="Contratação: $120. Depois, $2 por canteiro regado.\nEscolha os canteiros após contratar. Sem trabalho, sem cobrança.\nZeca pode continuar cuidando das galinhas ao mesmo tempo.\nCada ajudante pode ser pausado separadamente."
	var action:="crew_hire"
	var button_text:="Contratar por $120"
	var price:=120
	if kind=="dismiss":
		title="Dispensar Bento?"
		body="Encerra a irrigação e as cobranças dele.\nZeca continua na tarefa dele. Os produtos ficam com você.\nContratação não é reembolsada. Recontratar custa $120.\nO treinamento adquirido permanece."
		action="crew_dismiss"; button_text="Confirmar dispensa"; price=0
	elif kind in ["coop","field"]:
		title="Treinar %s • Nível 2"%("Zeca" if kind=="coop" else "Bento")
		body="Custo único: $240. Caminhada 40% mais rápida.\n"
		body+=("Checagem do trato: 15 → 10 segundos.\nServiço: $2 → $1, mais o custo normal da ração." if kind=="coop" else "Rega 40% mais rápida; custo por canteiro: $2 → $1.\nAtende somente os canteiros secos que você escolheu.")
		body+="\nA economia melhora seu lucro; não gera moedas extras."
		action="crew_train:"+kind; button_text="Confirmar treinamento • $240"; price=240
	hud.label(p,title,Vector2(30,29),Vector2(550,43),27)
	hud.label(p,body,Vector2(30,104),Vector2(550,166),17)
	var confirm_button:=hud.button(p,button_text,Rect2(30,315,550,44),action,true)
	confirm_button.disabled=state.money<price
	hud.button(p,"Voltar sem alterar",Rect2(30,380,550,37),"crew")
