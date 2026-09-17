class_name FarmCrewHUD
extends RefCounted

static func show(hud:FarmHUD,state:FarmState) -> void:
	var p:=FarmGameUI.open(hud,"crew","Equipe da fazenda","worker",860,622)
	for i in range(2):
		var field:=i==1
		var worker:Dictionary=state.field_staff if field else state.staff
		var kind:="field" if field else "coop"
		var c:=FarmGameUI.card(hud,p,Rect2(26+i*412,118,396,397))
		FarmGameUI.icon(c,"seed" if field else "chicken",Rect2(18,20,60,60))
		hud.label(c,"Bento" if field else "Zeca",Vector2(94,21),Vector2(280,35),29)
		hud.label(c,"Plantação" if field else "Galinheiro",Vector2(94,60),Vector2(280,28),18)
		var status:="Disponível para contratar"
		if worker.hired: status="Pausado" if worker.paused else "Em serviço"
		if field and worker.hired and not state.irrigation.enabled: status="Escolha uma rotina"
		hud.label(c,status,Vector2(20,112),Vector2(356,29),21)
		hud.label(c,"Nível %d • $%d por serviço"%[FarmCrew.level(worker),FarmCrew.fee(worker)],Vector2(20,151),Vector2(356,28),18)
		hud.label(c,"+ sementes" if field else "+ ração utilizada",Vector2(20,183),Vector2(356,25),16,FarmHUD.MUTED)
		var manage:=FarmGameUI.action(hud,c,("Rotina e orçamento" if worker.hired else "Contratar • $120") if field else ("Cuidar do galinheiro" if worker.hired else "Contratar • $120"),Rect2(16,226,364,47),("cultivation" if worker.hired else "crew_hire_review") if field else "staff",true)
		manage.disabled=not worker.hired and state.money<120
		var train:=FarmGameUI.action(hud,c,"✓ Treinado" if FarmCrew.level(worker)==2 else "Treinar • $240",Rect2(16,287,364,43),"crew_train_review:"+kind)
		train.disabled=not worker.hired or FarmCrew.level(worker)==2 or state.money<240
		if field:
			var pause:=FarmGameUI.action(hud,c,"Retomar" if worker.paused else "Pausar",Rect2(16,345,176,36),"crew_pause")
			pause.disabled=not worker.hired
			var dismiss:=FarmGameUI.action(hud,c,"Dispensar…",Rect2(204,345,176,36),"crew_dismiss_review")
			dismiss.disabled=not worker.hired
		else:
			hud.label(c,"Uma tarefa por vez",Vector2(20,349),Vector2(356,26),16,FarmHUD.MUTED)
	FarmGameUI.icon(p,"coins",Rect2(28,544,38,38))
	hud.label(p,"$%d"%state.money,Vector2(78,548),Vector2(245,33),25)
	FarmGameUI.action(hud,p,"Chico · Queijaria",Rect2(330,538,504,48),"chico")

static func confirm(hud:FarmHUD,state:FarmState,kind:String) -> void:
	var p:=FarmGameUI.open(hud,"crew_confirm","Equipe • confirmar","worker",780,515)
	var title:="Contratar Bento da Horta?"
	var body:="Contratação: $120. Serviço: $2 por tarefa concluída.\nSementes são cobradas à parte ao replantar.\nEscolha tarefas, canteiros e orçamento depois de contratar.\nSem trabalho, sem cobrança. Zeca segue no galinheiro."
	var action:="crew_hire"
	var button_text:="Contratar por $120"
	var price:=120
	if kind=="dismiss":
		title="Dispensar Bento?"
		body="Encerra a rotina e as cobranças dele.\nZeca continua na tarefa dele. Os produtos ficam com você.\nContratação não é reembolsada. Recontratar custa $120.\nO treinamento adquirido permanece."
		action="crew_dismiss"; button_text="Confirmar dispensa"; price=0
	elif kind in ["coop","field"]:
		title="Treinar %s • Nível 2"%("Zeca" if kind=="coop" else "Bento")
		body="Custo único: $240. Caminhada 40% mais rápida.\n"
		body+=("Checagem do trato: 15 → 10 segundos.\nServiço: $2 → $1, mais o custo normal da ração." if kind=="coop" else "Tarefas 40% mais rápidas; serviço: $2 → $1.\nSementes continuam à parte; respeita os canteiros escolhidos.")
		body+="\nA economia melhora seu lucro; não gera moedas extras."
		action="crew_train:"+kind; button_text="Confirmar treinamento • $240"; price=240
	hud.label(p,title,Vector2(28,114),Vector2(724,43),27)
	hud.label(p,body,Vector2(28,180),Vector2(724,146),18)
	var confirm_button:=FarmGameUI.action(hud,p,button_text,Rect2(28,362,724,47),action,true)
	confirm_button.disabled=state.money<price
	FarmGameUI.action(hud,p,"Voltar sem alterar",Rect2(28,436,724,43),"crew")
