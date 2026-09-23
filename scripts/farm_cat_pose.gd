class_name FarmCatPose
extends RefCounted
## Pure presentation: callers own time, position and transitions.
static func node(cat:Node3D,key:String) -> Node3D:
	var cache:Dictionary=cat.get_meta("cat_joints",{})
	if not cache.has(key):
		var found:=cat.find_child(key,true,false) as Node3D
		assert(found!=null,"Missing feline joint: "+key)
		cache[key]={"node":found,"rest":found.transform}
		cat.set_meta("cat_joints",cache)
	return cache[key].node

static func pose(cat:Node3D,time:float,walk:float=0.0,sit:float=0.0,affection:float=0.0) -> void:
	walk=clampf(walk,0,1);sit=clampf(sit,0,1);affection=clampf(affection,0,1)
	# Always restore the authored rest pose: no accumulated deformation.
	for key in ["CatBody","CatHead","CatEarL","CatEarR","CatEyeL","CatEyeR","CatLegFL","CatLegFR","CatLegBL","CatLegBR","CatShinFL","CatShinFR","CatShinBL","CatShinBR","CatTail0"]:
		node(cat,key).transform=cat.get_meta("cat_joints")[key].rest
	var body:=node(cat,"CatBody")
	body.position.y+=sin(time*2.4)*.003*(1-walk)-.11*sit
	body.rotation.x=-.42*sit
	var head:=node(cat,"CatHead")
	head.rotation=Vector3(.42*sit-.18*affection,.07*sin(time*.8)*(1-walk),.14*sin(time*2.0)*affection)
	var blink:=pow(maxf(0,cos(fposmod(time+1.3,4.7)*TAU/4.7)),48)
	for key in ["CatEyeL","CatEyeR"]:node(cat,key).scale.y=maxf(.08,1-.92*maxf(blink,affection*.8))
	node(cat,"CatEarL").rotation.z=.10*sin(time*3)*pow(maxf(0,sin(time*.65)),10)-.12*affection
	node(cat,"CatEarR").rotation.z=.08*sin(time*3+1)*pow(maxf(0,sin(time*.65+2)),10)+.12*affection
	for key in ["FL","FR","BL","BR"]:
		if key.begins_with("F"):node(cat,"CatLeg"+key).position.y-=.04*sit
		var phase:float={"BL":0.0,"FL":PI*.5,"BR":PI,"FR":PI*1.5}[key]
		var stride:=sin(time*8+phase)*walk*(1-sit)
		node(cat,"CatLeg"+key).rotation.x=.36*stride+(.95 if key.begins_with("B") else .42)*sit
		node(cat,"CatShin"+key).rotation.x=-.30*maxf(0,-stride)-1.3*sit if key.begins_with("B") else -.25*maxf(0,-stride)
	var skeleton:Skeleton3D=cat.find_children("*","Skeleton3D",true,false)[0]
	if not skeleton.has_meta("cat_rest"):
		var rest:Array[Quaternion]=[]
		for i in range(skeleton.get_bone_count()):rest.append(skeleton.get_bone_pose_rotation(i))
		skeleton.set_meta("cat_rest",rest)
	for i in range(skeleton.get_bone_count()):
		var angle:=.05*sin(time*1.6-i*.5)+.045*affection*sin(time*3-i*.4)
		skeleton.set_bone_pose_rotation(i,skeleton.get_meta("cat_rest")[i]*Quaternion(Vector3.FORWARD,angle)*Quaternion(Vector3.RIGHT,-.10*sit))
