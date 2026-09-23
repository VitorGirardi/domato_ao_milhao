extends SceneTree
var calls:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_animal_audio.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false);game.audio.set_process(false)
	game.state=FarmState.new();game.state.unlimited_money=true;game.state.claim(Vector2(4,-2));game.state.land_size=40;game.state.farm_xp=950
	assert(game.state.place("coop",Vector2(0,0),0).is_empty())
	assert(game.state.place("corral",Vector2(12,0),0).is_empty());game.state.items[-1].dairy.owned=true
	game.world.rebuild(game.state);game._action("start");game.build_mode=false
	game.player.position=Vector3(6,.1,1);game.horse.position=Vector3(7,0,3)
	var bird:=Node3D.new();game.world.add_child(bird);bird.position=Vector3(8,3,0)
	game.world.landscape.birds.append({"node":bird,"home":Vector3.ZERO,"phase":0})
	game.audio.animal_called.connect(func(kind:String):calls.append(kind))
	for i in range(70):game.audio._process(.1)
	assert(calls.has("cow") and calls.has("chicken"),"Both livestock species must get a turn even with nearby birds")
	assert(calls.has("horse_neigh") or calls.has("horse_snort"))
	assert(calls.has("bird_0") or calls.has("bird_1") or calls.has("bird_2"))
	var before:int=calls.size();game.hud.menu(game.state)
	for i in range(60):game.audio._process(.1)
	assert(calls.size()==before,"Menus stop new animal calls")
	game.hud.close_modal();game.horse.mount(game.player,game.avatar,game.actor)
	game.audio._process(.01);assert(calls[-1]=="horse_neigh","Mounting produces a whinny")
	before=calls.size();assert(game.horse.encourage())
	assert(calls.size()==before+1 and calls[-1]=="horse_sprint")
	assert(not game.horse.encourage() and calls.size()==before+1,"Rejected sprint cannot make another sound")
	game.horse.pat_time=0;game.horse.stamina=0
	assert(not game.horse.encourage() and calls.size()==before+1,"No stamina means no sprint sound")
	assert(game.audio.horse_voice.get_parent()==game.horse,"Voice follows the moving horse")
	game.horse.reset_rider(game.player,game.avatar,game.actor)
	game.player.position=Vector3(150,0,140);calls.clear()
	for i in range(200):game.audio._process(.1)
	assert(not calls.has("cow") and not calls.has("chicken") and not calls.has("horse_neigh") and not calls.has("horse_snort"),"Distant livestock stays silent")
	game.session_started=false;game.audio.stop_all();await create_timer(.15).timeout
	game.queue_free();await process_frame
	print("ANIMAL_AUDIO_OK: species fairness, nearby calls, menu pause, mount whinny, accepted sprint only, horse-following source and distance")
	quit()
