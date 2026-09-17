class_name FarmEmotes
extends RefCounted
const DANCES:={"chicken":"Dança da galinha","shuffle":"Passinho do milho","victory":"Rei da colheita","six_seven":"Six Seven"}
const REACTIONS:={"laugh":"KKKK!","heart":"Só amor","angry":"Cadê meu milho?!"}
static func show(hud:FarmHUD) -> void:
	var p:=FarmGameUI.open(hud,"emotes","Hora da resenha","emote_laugh",800,678)
	var keys:=["chicken","shuffle","victory","laugh","heart","angry"]
	for i in range(6):
		var angle:float=-PI/2+i*TAU/6
		var center:=Vector2(400,366)+Vector2(cos(angle)*242,sin(angle)*181)
		var key:String=keys[i]
		var b:=FarmGameUI.action(hud,p,DANCES.get(key,REACTIONS.get(key,"")),Rect2(center-Vector2(105,45),Vector2(210,90)),"emote:"+key,i<3)
		b.add_theme_font_size_override("font_size",15)
		b.icon=load("res://assets/ui/emote_%s.svg"%key)
		b.expand_icon=true; b.add_theme_constant_override("icon_max_width",40)
	hud.label(p,"DANCINHAS",Vector2(305,111),Vector2(190,26),14,FarmHUD.MUTED).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var six:=FarmGameUI.action(hud,p,"Six Seven",Rect2(295,321,210,90),"emote:six_seven",true)
	six.icon=load("res://assets/ui/emote_six_seven.svg");six.expand_icon=true;six.add_theme_constant_override("icon_max_width",48)
	six.add_theme_font_size_override("font_size",19)
	hud.label(p,"WASD, pulo ou interação cancelam a dança",Vector2(28,614),Vector2(744,28),18).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

static func pose(actor:FarmAvatar,kind:String,t:float,blend:float) -> void:
	var beat:=sin(t*8)
	var sway:=sin(t*4)
	actor.pose_bone("Spine",Vector3(.10,0,sway*.12),blend)
	actor.pose_bone("Head",Vector3(-.05+beat*.07,0,-sway*.10),blend)
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="R" else -1.0
		var arm:=Vector3(-.25,0,-sign_value*.85)
		var forearm:=Vector3(-1.25,0,0)
		var hand:=Vector3(.12,0,0)
		var thigh:=0.0
		var knee:=.12
		match kind:
			"chicken":
				arm.z=sign_value*(.60+(beat+1)*.22)
				forearm=Vector3(-1.5,sign_value*.30,0)
				thigh=-.16-(beat+1)*.08; knee=-thigh*2
				actor.pose_bone("Chest",Vector3(.14,0,sway*.10),blend)
			"shuffle":
				var step:=maxf(0,beat*sign_value)
				thigh=-step*.65; knee=step*.90+.08
				arm=Vector3(-.45-beat*sign_value*.65,0,-sign_value*.30)
				forearm.x=-.95
				actor.pose_bone("Chest",Vector3(.05,sway*.22,0),blend)
			"six_seven":
				# Alternate the two open palms, like weighing six against seven.
				var lift:=sin(t*6.7)*sign_value
				arm=Vector3(-.30-lift*.22,0,-sign_value*.30)
				forearm=Vector3(-1.35-lift*.28,0,0)
				hand=Vector3(.12,0,sign_value*1.35)
				thigh=-.07; knee=.14
				actor.pose_bone("Chest",Vector3(.02,0,sway*.045),blend)
				actor.pose_bone("Spine",Vector3(.03,0,sway*.055),blend)
				actor.pose_bone("Head",Vector3(-.03+beat*.025,0,-sway*.04),blend)
			"victory":
				arm=Vector3(-2.3+(beat+1)*.16,0,-sign_value*.35)
				forearm.x=-.35
				thigh=-.08; knee=.16
				actor.pose_bone("Chest",Vector3(-.08,0,sway*.15),blend)
		actor.pose_bone("UpperArm."+side,arm,blend)
		actor.pose_bone("Forearm."+side,forearm,blend)
		actor.pose_bone("Hand."+side,hand,blend)
		actor.pose_bone("Thigh."+side,Vector3(thigh,0,sign_value*sway*.06),blend)
		actor.pose_bone("Shin."+side,Vector3(knee,0,0),blend)
		actor.pose_bone("Foot."+side,Vector3(-knee-thigh,0,0),blend)
	actor.root.position.y=-.03 if kind!="chicken" else -.04-(beat+1)*.025
