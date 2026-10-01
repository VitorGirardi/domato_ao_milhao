class_name FarmHorseRoute
extends RefCounted
## Incremental world-scale search. Three-metre cells align both authored bridges;
## every edge is sampled at horse clearance, not just at its endpoints.
const STEP:=3.0
const NEIGHBORS:=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]
signal _resume_preparation
var _preparing:=false
var _cancelled:=false
var _deadline:=0
var clear:Callable
var pending:=false
var result:Array[Vector2]=[]
var destination:=Vector2.ZERO
var first:=Vector2i.ZERO
var last:=Vector2i.ZERO
var frontier:Array=[]
var costs:Dictionary={}
var previous:Dictionary={}
var closed:Dictionary={}
var safe_cache:Dictionary={}
var height_cache:Dictionary={}
var edge_cache:Dictionary={}
var prefix:Array[Vector2]=[]
var suffix:Array[Vector2]=[]

static func meeting_point(target:Vector2,horse:Vector2,can_stand:Callable) -> Vector2:
	# Galleries have narrow gates/ceilings: wait in daylight outside the mouth.
	if FarmMineLayout.inside(target,2):target=Vector2(900,-213)
	if Rect2(Vector2(697,-332),Vector2(16,14)).has_point(target):target=Vector2(705,-314)
	target=target.clamp(FarmLandscape.WALK_MIN+Vector2.ONE*3,FarmLandscape.WALK_MAX-Vector2.ONE*3)
	var bearing:=(horse-target).angle()
	for radius in range(0,101,2):
		var distance:=3.2+radius
		var count:=maxi(12,ceili(TAU*distance/3))
		for i in range(count):
			var p:=target+Vector2.from_angle(bearing+i*TAU/count)*distance
			if not FarmMineLayout.inside(p,2) and can_stand.call(p):return p
	return Vector2.INF

func safe(p:Vector2) -> bool:
	if not safe_cache.has(p):
		safe_cache[p]=p.x>=FarmLandscape.WALK_MIN.x+2 and p.x<=FarmLandscape.WALK_MAX.x-2 and p.y>=FarmLandscape.WALK_MIN.y+2 and p.y<=FarmLandscape.WALK_MAX.y-2 and not FarmMineLayout.inside(p,2) and clear.call(p)
	return safe_cache[p]

func elevation(p:Vector2) -> float:
	if not height_cache.has(p):height_cache[p]=FarmLandscape.height_at(p)
	return height_cache[p]

func segment(a:Vector2,b:Vector2) -> bool:
	var count:=maxi(1,ceili(a.distance_to(b)/1.5))
	var last_point:=a
	for i in range(1,count+1):
		var p:=a.lerp(b,float(i)/count)
		if not safe(p):return false
		if absf(elevation(p)-elevation(last_point))>p.distance_to(last_point)*.78+.05:return false
		last_point=p
	return true

func traversable(start:Vector2,path:Array[Vector2]) -> bool:
	var previous_point:=start
	for point in path:
		if not segment(previous_point,point):return false
		previous_point=point
	return true

func connector(at:Vector2) -> Array[Vector2]:
	var center:=Vector2i(roundi(at.x/STEP),roundi(at.y/STEP))
	var options:Array[Vector2]=[]
	for x in range(-3,4):
		for z in range(-3,4):options.append(Vector2(center+Vector2i(x,z))*STEP)
	options.sort_custom(func(a:Vector2,b:Vector2):return a.distance_squared_to(at)<b.distance_squared_to(at))
	for p in options:
		if await _checkpoint():return []
		if safe(p) and await _segment_sliced(at,p):return [p]
	# Detailed local search gets out from between farm buildings/trees.
	for p in options:
		if await _checkpoint():return []
		if not safe(p):continue
		var local:=await _local_route(at,p,1.2)
		if not local.is_empty() and await _traversable_sliced(at,local):return local
	return []

func cancel() -> void:
	_cancelled=true
	if _preparing:_resume_preparation.emit()
	_preparing=false;pending=false;result.clear()

func begin(start:Vector2,goal:Vector2,can_stand:Callable) -> void:
	cancel()
	_cancelled=false
	clear=can_stand;destination=goal;pending=false;result.clear();frontier.clear();costs.clear();previous.clear();closed.clear();safe_cache.clear();height_cache.clear();edge_cache.clear()
	prefix.clear();suffix.clear()
	if not goal.is_finite():return
	pending=true;_preparing=true
	_prepare(start,goal)

func _checkpoint() -> bool:
	if _cancelled:return true
	if Time.get_ticks_usec()>=_deadline:
		await _resume_preparation
	return _cancelled

func _prepare(start:Vector2,goal:Vector2) -> void:
	await _resume_preparation
	if _cancelled:_preparing=false;return
	if start.distance_to(goal)<55 and await _segment_sliced(start,goal):
		result=[goal];pending=false;_preparing=false;return
	if _cancelled:_preparing=false;return
	var roads:=await road_route(start,goal)
	if _cancelled:_preparing=false;return
	if not roads.is_empty():result=roads;pending=false;_preparing=false;return
	prefix=await connector(start)
	if _cancelled:_preparing=false;return
	suffix=await connector(goal)
	if _cancelled:_preparing=false;return
	_preparing=false
	if prefix.is_empty() or suffix.is_empty():pending=false;return
	first=Vector2i(roundi(prefix[-1].x/STEP),roundi(prefix[-1].y/STEP))
	last=Vector2i(roundi(suffix[-1].x/STEP),roundi(suffix[-1].y/STEP))
	costs[first]=0.0;push(first,0)

func _segment_sliced(a:Vector2,b:Vector2) -> bool:
	var count:=maxi(1,ceili(a.distance_to(b)/1.5))
	var last_point:=a
	for i in range(1,count+1):
		if await _checkpoint():return false
		var p:=a.lerp(b,float(i)/count)
		if not safe(p):return false
		if absf(elevation(p)-elevation(last_point))>p.distance_to(last_point)*.78+.05:return false
		last_point=p
	return true

func _traversable_sliced(start:Vector2,path:Array[Vector2]) -> bool:
	var previous_point:=start
	for point in path:
		if not await _segment_sliced(previous_point,point):return false
		previous_point=point
	return true

func road_route(start:Vector2,goal:Vector2) -> Array[Vector2]:
	var graph:=AStar2D.new()
	var ids:Dictionary={}
	for road in FarmRegion.ROUTES:
		var previous_id:=-1
		for edge in range(road.size()-1):
			var a:Vector3=road[edge];var b:Vector3=road[edge+1]
			var count:=maxi(1,ceili(a.distance_to(b)/12))
			for i in range(count+1):
				if await _checkpoint():return []
				var world:=a.lerp(b,float(i)/count);var point:=Vector2(world.x,world.z)
				var key:=Vector2i(roundi(point.x*100),roundi(point.y*100))
				if not ids.has(key):
					ids[key]=graph.get_available_point_id();graph.add_point(ids[key],point)
				var id:int=ids[key]
				if previous_id>=0 and previous_id!=id:graph.connect_points(previous_id,id)
				previous_id=id
	var starts:Array=[];var goals:Array=[]
	for id in graph.get_point_ids():
		starts.append(id);goals.append(id)
	starts.sort_custom(func(a:int,b:int):return graph.get_point_position(a).distance_squared_to(start)<graph.get_point_position(b).distance_squared_to(start))
	goals.sort_custom(func(a:int,b:int):return graph.get_point_position(a).distance_squared_to(goal)<graph.get_point_position(b).distance_squared_to(goal))
	var start_id:=-1;var goal_id:=-1
	for i in range(mini(starts.size(),18)):
		if await _checkpoint():return []
		var point:=graph.get_point_position(starts[i])
		if start.distance_to(point)<300 and await _segment_sliced(start,point):start_id=starts[i];break
	for i in range(mini(goals.size(),18)):
		if await _checkpoint():return []
		var point:=graph.get_point_position(goals[i])
		if goal.distance_to(point)<300 and await _segment_sliced(goal,point):goal_id=goals[i];break
	if start_id<0 or goal_id<0:return []
	var path:Array[Vector2]=[]
	var previous_point:=start
	for point in graph.get_point_path(start_id,goal_id):
		if await _checkpoint():return []
		if not safe(point):return []
		if not await _segment_sliced(previous_point,point):
			var detour:=await _local_route(previous_point,point,1.5)
			if detour.is_empty() or not await _traversable_sliced(previous_point,detour):return []
			path.append_array(detour)
		else:path.append(point)
		previous_point=point
	if path.is_empty():return []
	path.append(goal)
	return path

func push(cell:Vector2i,score:float) -> void:
	frontier.append([score,cell]);var index:=frontier.size()-1
	while index>0:
		var parent:=(index-1)/2
		if frontier[parent][0]<=score:break
		frontier[index]=frontier[parent];index=parent
	frontier[index]=[score,cell]

func pop() -> Vector2i:
	var cell:Vector2i=frontier[0][1];var tail:Array=frontier.pop_back()
	if frontier.is_empty():return cell
	var index:=0
	while index*2+1<frontier.size():
		var child:=index*2+1
		if child+1<frontier.size() and frontier[child+1][0]<frontier[child][0]:child+=1
		if tail[0]<=frontier[child][0]:break
		frontier[index]=frontier[child];index=child
	frontier[index]=tail;return cell

func advance(budget:int=32) -> void:
	if not pending:
		if _preparing:
			_cancelled=true
			_resume_preparation.emit()
			_cancelled=false
		return
	var deadline:=Time.get_ticks_usec()+5000
	if _preparing:
		_deadline=deadline
		_resume_preparation.emit()
		if _preparing or not pending:return
	for iteration in range(budget):
		if iteration>0 and Time.get_ticks_usec()>deadline:return
		if not pending:return
		if frontier.is_empty():pending=false;return
		var cell:=pop()
		if closed.has(cell):continue
		closed[cell]=true
		if cell==last:
			var middle:Array[Vector2]=[Vector2(last)*STEP]
			while cell!=first:
				cell=previous[cell];middle.push_front(Vector2(cell)*STEP)
			result=prefix.duplicate();result.append_array(middle)
			var ending:=suffix.duplicate();ending.reverse();result.append_array(ending);result.append(destination)
			pending=false;return
		var at:=Vector2(cell)*STEP
		for offset in NEIGHBORS:
			var next:Vector2i=cell+offset
			if closed.has(next):continue
			var to:=Vector2(next)*STEP
			if not safe(to):continue
			var key:=Vector4i(cell.x,cell.y,next.x,next.y)
			if not edge_cache.has(key):edge_cache[key]=segment(at,to)
			if not edge_cache[key]:continue
			# Authored roads are smoother and safer than crossing mountain faces.
			var road:=FarmRegion.road_sample(to).x<9 or FarmRegion.on_bridge(to)
			var price:float=costs[cell]+at.distance_to(to)*(.68 if road else 1.0)
			if price>=float(costs.get(next,INF)):continue
			costs[next]=price;previous[next]=cell
			push(next,price+to.distance_to(Vector2(last)*STEP)*.67)

func _local_route(start:Vector2,goal:Vector2,step:float) -> Array[Vector2]:
	var local_result:Array[Vector2]=[]
	if start.distance_to(goal)>65 or not safe(goal):return local_result
	var direct:=true
	var samples:=maxi(1,ceili(start.distance_to(goal)/.35))
	for i in range(1,samples+1):
		if await _checkpoint():return []
		if not safe(start.lerp(goal,float(i)/samples)):direct=false;break
	if direct:local_result.append(goal);return local_result
	var origin:=start
	var finish:=Vector2i(roundi((goal.x-start.x)/step),roundi((goal.y-start.y)/step))
	var open:Array[Vector2i]=[Vector2i.ZERO]
	var cost:Dictionary={Vector2i.ZERO:0.0};var from:Dictionary={};var closed:Dictionary={}
	var extent:=Vector2i(absi(finish.x)+8,absi(finish.y)+8)
	for iteration in range(700):
		if await _checkpoint():return []
		if open.is_empty():break
		var best:=0;var score:=INF
		for i in range(open.size()):
			var value:float=cost[open[i]]+Vector2(open[i]-finish).length()
			if value<score:score=value;best=i
		var cell:=open[best];open.remove_at(best);closed[cell]=true
		if cell==finish:
			local_result.push_front(goal)
			while cell!=Vector2i.ZERO:
				local_result.push_front(origin+Vector2(cell)*step);cell=from[cell]
			return local_result
		for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]:
			var next:Vector2i=cell+offset
			if closed.has(next) or absi(next.x)>extent.x or absi(next.y)>extent.y:continue
			var at:=origin+Vector2(cell)*step;var to:=origin+Vector2(next)*step
			var edge_safe:=true
			for k in range(1,5):
				if await _checkpoint():return []
				if not safe(at.lerp(to,k/4.0)):edge_safe=false;break
			if not edge_safe:continue
			var price:float=cost[cell]+Vector2(offset).length()
			if price<float(cost.get(next,INF)):
				cost[next]=price;from[next]=cell
				if next not in open:open.append(next)
	return local_result
