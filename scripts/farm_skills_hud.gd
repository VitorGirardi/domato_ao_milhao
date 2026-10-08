class_name FarmSkillsHUD
extends RefCounted
const PRACTICE:={"fishing":"Capture um peixe: +10 XP.","farming":"Colha um canteiro ou laranjeira: +10 XP.","mining":"Conclua uma extração: +10 XP.","handling":"Conforto +8 XP · ovo +1 XP · litro de leite +2 XP."}

static func draw(h:FarmHUD,p:Control,s:FarmState) -> void:
	h.label(p,"Aprenda fazendo. A prática da fazenda é compartilhada no cooperativo.",Vector2(28,162),Vector2(1024,28),17)
	for i in range(FarmSkills.KEYS.size()):
		var key:String=FarmSkills.KEYS[i]
		var xp:int=s.skills[key]
		var rank:=FarmSkills.level(xp)
		var card:=FarmGameUI.card(h,p,Rect2(26+(i%2)*522,204+(i/2)*242,506,230))
		h.label(card,"%s · Nível %d"%[FarmSkills.NAMES[key],rank],Vector2(16,10),Vector2(474,30),23)
		var next:int=FarmSkills.THRESHOLDS[rank] if rank<5 else xp
		h.label(card,"%s · %d / %d XP"%[FarmSkills.RANKS[rank-1],xp,next] if rank<5 else "Mestre · nível máximo · %d XP"%xp,Vector2(16,45),Vector2(474,26),16)
		var progress:=float(xp-FarmSkills.THRESHOLDS[rank-1])/float(next-FarmSkills.THRESHOLDS[rank-1]) if rank<5 else 1.0
		FarmGameUI.meter(h,card,Rect2(16,78,474,10),progress,Color("71a06a"))
		FarmGuideHUD.wrapped(h,card,"Agora: "+FarmSkills.benefit(key,rank),Rect2(16,99,474,48),17,FarmHUD.INK)
		var future:="Benefício máximo alcançado. Continue aproveitando sua habilidade."
		if rank<5:
			var target:=rank+1
			future="No nível %d: %s"%[target,FarmSkills.benefit(key,target)]
		FarmGuideHUD.wrapped(h,card,future,Rect2(16,155,474,62),16,FarmHUD.MUTED)
	FarmGuideHUD.wrapped(h,p,"Somente ações manuais concluídas dão XP. Trabalho dos ajudantes, tentativas e ações canceladas não contam. O benefício de uma ação usa o nível que você tinha ao começar a recompensa.",Rect2(28,694,1024,50),16,FarmHUD.MUTED)
	FarmGameUI.action(h,p,"Como ganhar experiência",Rect2(26,749,420,36),"guide:practice")
	FarmGameUI.action(h,p,"Voltar ao campo",Rect2(734,749,320,36),"close",true)

static func practice(h:FarmHUD) -> void:
	var p:=FarmGameUI.open(h,"skills_help","Aprender com a prática","book",820,520)
	var i:=0
	for key in FarmSkills.KEYS:
		FarmGuideHUD.wrapped(h,p,FarmSkills.NAMES[key]+" — "+PRACTICE[key],Rect2(28,120+i*65,764,55),19,FarmHUD.INK)
		i+=1
	FarmGameUI.action(h,p,"Voltar às habilidades",Rect2(220,440,380,46),"guide:tab:skills",true)
