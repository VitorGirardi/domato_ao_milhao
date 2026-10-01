extends SceneTree
var calls:=0
var maximum_slice:=0
func _initialize() -> void:call_deferred("run")
func can_stand(_point:Vector2) -> bool:
	calls+=1
	OS.delay_usec(100)
	return true
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var route:=FarmHorseRoute.new()
	var start:=Vector2(160,-20)
	var finish:=Vector2(160.1,-20)
	for iteration in range(90):
		calls=0
		route.begin(start,Vector2(705,-325),can_stand)
		assert(route.pending and route._preparing)
		if iteration%3!=0:
			for step in range(3):
				var clock:=Time.get_ticks_usec()
				route.advance()
				maximum_slice=maxi(maximum_slice,Time.get_ticks_usec()-clock)
				if calls>0:break
			assert(route.pending and route._preparing,"Expected suspended preparation")
		if iteration%3==2:
			route.begin(start,finish,can_stand)
			for step in range(100):
				route.advance()
				if not route.pending:break
			assert(not route.pending and not route._preparing)
			assert(route.result.size()==1 and route.result[0]==finish,"Stale coroutine overwrote replacement route")
		else:
			route.cancel()
			assert(not route.pending and not route._preparing and route.result.is_empty())
			route.advance()
			assert(not route.pending and not route._preparing and route.result.is_empty())
		assert(route.get_signal_connection_list("_resume_preparation").is_empty(),"Suspended callback left after cancellation/completion")
	var weak:WeakRef=weakref(route)
	route=null
	assert(weak.get_ref()==null,"Route retained after all preparation ended")
	var companion:=FarmCompanions.new()
	companion.set_process(false)
	companion.add_child(companion.purr)
	companion.add_child(companion.whistle)
	root.add_child(companion)
	companion.horse_route.begin(start,Vector2(705,-325),can_stand)
	companion.horse_route.advance()
	var companion_route=weakref(companion.horse_route)
	companion.queue_free()
	await process_frame
	await process_frame
	assert(companion_route.get_ref()==null,"Companion teardown retained suspended route")
	print("ROUTE_CANCEL_OK: 30 begin/cancel, 30 advance/cancel, 30 active restart, teardown; max slice usec ",maximum_slice)
	quit()

