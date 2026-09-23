class_name FarmCharacters
extends RefCounted
## Local identity: never serialized into the host's shared farm snapshot.
const PROFILE_PATH:="user://character_profile.cfg"
const IDS:=["farmer","farmer_woman"]
static func valid(id:Variant) -> bool:return id is String and id in IDS
static func model_path(id:String) -> String:
	return "res://assets/models/"+(id if valid(id) else "farmer")+".glb"
static func load_choice(path:String=PROFILE_PATH) -> String:
	var profile:=ConfigFile.new()
	if profile.load(path)!=OK:return "farmer"
	var value:Variant=profile.get_value("character","id","farmer")
	return value if valid(value) else "farmer"
static func save_choice(id:String,path:String=PROFILE_PATH) -> Error:
	if not valid(id):return ERR_INVALID_PARAMETER
	var profile:=ConfigFile.new();profile.set_value("character","id",id)
	var temporary:=path+".tmp"
	var error:=profile.save(temporary)
	if error!=OK:return error
	error=DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))
	if error!=OK:DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	return error
static func instantiate_model(id:String) -> Node3D:
	var model:Node3D=load(model_path(id)).instantiate()
	FarmAvatar.prepare_model(model);model.set_meta("character_id",id if valid(id) else "farmer")
	return model
static func apply_to_game(game:Node3D,id:String) -> void:
	assert(valid(id))
	if game.avatar.get_meta("character_id","farmer")==id:
		game.avatar.set_meta("character_id",id);return
	game.weapons.holster();game.actor.stop_emote()
	var previous:Node3D=game.avatar
	var replacement:=instantiate_model(id)
	game.player.add_child(replacement);replacement.transform=previous.transform;replacement.visible=previous.visible
	var next_actor:=FarmAvatar.new();next_actor.setup(replacement,game.world)
	game.weapons.pistol.reparent(next_actor.hand_socket,false)
	game.avatar=replacement;game.actor=next_actor
	game.horse.rider_actor=next_actor
	if game.horse.mounted:game.horse.pose_rider(replacement,next_actor)
	previous.get_parent().remove_child(previous);previous.queue_free()
