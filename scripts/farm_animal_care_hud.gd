class_name FarmAnimalCareHUD
extends RefCounted

static func show(hud:FarmHUD,state:FarmState,index:int) -> void:
	if index<0 or index>=state.items.size() or state.items[index].kind not in FarmAnimalCare.KINDS:return
	hud.building_index=index
	var item:Dictionary=state.items[index]
	var icon:String={"coop":"chicken","corral":"cow","pigsty":"pig"}[item.kind]
	var p:=FarmGameUI.open(hud,"animal_care","Um cuidado a mais",icon,800,592)
	var card:=FarmGameUI.card(hud,p,Rect2(26,118,748,126))
	FarmGameUI.icon(card,icon,Rect2(18,19,88,88))
	hud.label(card,("Escovação · "+str(item.dairy.name)) if item.kind=="corral" else FarmAnimalCare.TITLES[item.kind],Vector2(126,18),Vector2(596,36),27)
	p.set_meta("care_activity",hud.label(card,FarmAnimalCare.activity(item,state.elapsed),Vector2(126,65),Vector2(596,30),21))
	var seconds:=FarmAnimalCare.seconds(item)
	var visits:=int(item.get("animal_care",{}).get("visits",0))
	var status:="Conforto ativo · %d min %02d s"%[int(ceil(seconds))/60,int(ceil(seconds))%60] if seconds>0 else "Prontos para receber um cuidado"
	p.set_meta("care_status",hud.label(p,status,Vector2(28,263),Vector2(744,34),21))
	FarmGameUI.meter(hud,p,Rect2(28,310,744,14),seconds/FarmAnimalCare.DURATION,Color("83ae72"))
	p.set_meta("care_meter",p.get_child(-1))
	var reward:=("Ovos deste galinheiro" if item.kind=="coop" else "Leite desta vaca")+": +20% de velocidade, sem ração extra." if item.kind!="pigsty" else "Porquinhos confortáveis. Companhia, sem produção."
	hud.label(p,reward+"\nDura 8 minutos ativos. O tempo para quando o jogo fecha.\nGrátis · água e ração a partir de 25% · aproxime-se a pé.",Vector2(28,343),Vector2(744,88),18)
	hud.label(p,"Cuidados realizados: %d · sem doença ou punição por ausência"%visits,Vector2(28,443),Vector2(744,29),16,FarmHUD.MUTED)
	FarmGameUI.action(hud,p,"Voltar ao cercado",Rect2(28,507,264,49),"animal:back")
	var button:=FarmGameUI.action(hud,p,FarmAnimalCare.ACTIONS[item.kind]+" · grátis",Rect2(308,507,464,49),"animal:care",true)
	p.set_meta("care_button",button)
	update(hud,state)

static func update(hud:FarmHUD,state:FarmState) -> void:
	if hud.modal_kind!="animal_care" or not is_instance_valid(hud.modal):return
	var index:=hud.building_index
	if index<0 or index>=state.items.size() or state.items[index].kind not in FarmAnimalCare.KINDS:return
	var p:=hud.modal
	if not p.has_meta("care_button"):return
	var item:Dictionary=state.items[index]
	var seconds:=FarmAnimalCare.seconds(item)
	var reason:=FarmAnimalCare.reason(state,index)
	p.get_meta("care_activity").text=FarmAnimalCare.activity(item,state.elapsed)
	p.get_meta("care_status").text=("Conforto ativo · %d min %02d s"%[int(ceil(seconds))/60,int(ceil(seconds))%60]) if seconds>0 else (reason if not reason.is_empty() else "Prontos para receber um cuidado")
	p.get_meta("care_meter").size.x=738*clampf(seconds/FarmAnimalCare.DURATION,0,1)
	var button:Button=p.get_meta("care_button")
	button.disabled=not reason.is_empty();button.tooltip_text=reason
	button.text="Conforto ativo" if seconds>0 else FarmAnimalCare.ACTIONS[item.kind]+" · grátis"
