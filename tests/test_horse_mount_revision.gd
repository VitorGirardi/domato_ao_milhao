extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var game:Node3D=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://horse_revision.json";root.add_child(game)
	await process_frame;await physics_frame
	game.set_process(false);game.set_physics_process(false)
	var n:FarmNetwork=game.network
	var m:FarmCoopMount=n.mounts
	var h:FarmHorse=game.horse
	n.remote=CharacterBody3D.new();game.add_child(n.remote)
	n.active=true;n.ready_session=true;n.hosting=false
	game.avatar.rotation.y=.83
	var original_basis:Basis=game.avatar.global_basis
	var parked:Vector3=h.position
	var outside:=parked+Vector3(-1.65,.12,0)
	m._state(1,parked,0,parked,outside,"mount",outside,parked,.4,1)
	assert(h.transition_basis.is_equal_approx(original_basis),"Initial snapshot lost entry orientation")
	m._frame(1,1,parked,0,100,0,0,0,.7,1)
	m._frame(2,1,parked,0,100,0,0,0,.3,1)
	assert(is_equal_approx(h.transition_elapsed,.7),"Matching-state frame rewound phase")
	m._state(1,parked,0,parked,outside,"dismount",parked,outside,.15,2)
	m._frame(3,1,parked+Vector3.ONE,0,100,0,0,0,1.5,1)
	assert(is_equal_approx(h.transition_elapsed,.15) and h.position==parked,"Old mount frame corrupted new dismount")
	m._frame(4,1,parked+Vector3.ONE,0,100,0,0,0,0,3)
	assert(m.received==2 and h.position==parked,"Future frame ran before reliable state")
	m._state(1,parked,0,parked,outside,"",parked,outside,0,3)
	assert(not h.transition_active())
	m._state(1,parked,0,parked,outside,"mount",outside,parked,.2,2)
	assert(not h.transition_active() and m.received_revision==3,"Old reliable state restored finished transition")
	m._state(1,parked,0,parked,outside,"dismount",parked,outside,.2,4)
	var stable_basis:=h.transition_basis
	m._state(1,parked,0,parked,outside,"dismount",parked,outside,.1,5)
	assert(is_equal_approx(h.transition_elapsed,.2) and h.transition_basis.is_equal_approx(stable_basis),"Repeated snapshot restarted ongoing transition")
	m.reset();assert(m.state_revision==0 and m.received_revision==-1 and m.received==-1)
	n.active=false;n.ready_session=false
	print("HORSE_MOUNT_REVISION_OK: cross-channel old/future frames, monotonic phase, duplicate snapshots, entry basis and reset")
	game.audio.stop_all();await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
