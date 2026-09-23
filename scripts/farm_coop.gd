class_name FarmCoop
extends RefCounted
## Cooperative farming saves never use the solo save path.
static func path_for(solo:String) -> String:
	return solo.get_basename()+"_coop.json"

static func load_farm(path:String) -> FarmState:
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var data:Variant=read_json(candidate)
		if not data is Dictionary or data.get("coop_version")!=1:continue
		var state:=FarmState.new()
		if state.restore(data.get("farm")):
			state.unlimited_money=true;return state
	return null

static func save_farm(path:String,state:FarmState) -> bool:
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify({"coop_version":1,"farm":state.serialize()},"",true,true));file.flush()
	var error:=file.get_error();file.close()
	if error!=OK:return false
	# Only a validated primary may replace the previous backup.
	if FileAccess.file_exists(path):
		var data:Variant=read_json(path)
		var valid:=FarmState.new()
		if data is Dictionary and data.get("coop_version")==1 and valid.restore(data.get("farm")):
			if DirAccess.copy_absolute(path,path+".bak")!=OK:return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK

static func operation(item:Dictionary) -> String:
	if item.kind!="plot":return ""
	if not item.planted:return "plant"
	if item.growth>=1:return "harvest"
	if not item.watered:return "water"
	return ""

static func tick(state:FarmState,delta:float) -> void:
	# Other economic systems are deliberately not advanced until replicated.
	state.elapsed+=delta
	for item in state.items:
		if item.kind=="plot" and item.planted and item.watered:
			item.growth=minf(1,item.growth+delta/float(FarmState.CROPS[item.crop].seconds))

static func read_json(path:String) -> Variant:
	var parser:=JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(path))==OK else null
