class_name FarmCompanionPath
extends RefCounted
## Bounded search on demand, followed by swept movement in the animal controller.
static func route(start:Vector2,goal:Vector2,clear:Callable,step:float=1.0) -> Array[Vector2]:
	var result:Array[Vector2]=[]
	if start.distance_to(goal)>65 or not clear.call(goal):return result
	var direct:=true
	var samples:=maxi(1,ceili(start.distance_to(goal)/.35))
	for i in range(1,samples+1):
		if not clear.call(start.lerp(goal,float(i)/samples)):direct=false;break
	if direct:result.append(goal);return result
	var origin:=start
	var finish:=Vector2i(roundi((goal.x-start.x)/step),roundi((goal.y-start.y)/step))
	var open:Array[Vector2i]=[Vector2i.ZERO]
	var cost:Dictionary={Vector2i.ZERO:0.0};var from:Dictionary={};var closed:Dictionary={}
	var extent:=Vector2i(absi(finish.x)+8,absi(finish.y)+8)
	for iteration in range(700):
		if open.is_empty():break
		var best:=0;var score:=INF
		for i in range(open.size()):
			var value:float=cost[open[i]]+Vector2(open[i]-finish).length()
			if value<score:score=value;best=i
		var cell:=open[best];open.remove_at(best);closed[cell]=true
		if cell==finish:
			result.push_front(goal)
			while cell!=Vector2i.ZERO:
				result.push_front(origin+Vector2(cell)*step);cell=from[cell]
			return result
		for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]:
			var next:Vector2i=cell+offset
			if closed.has(next) or absi(next.x)>extent.x or absi(next.y)>extent.y:continue
			var at:=origin+Vector2(cell)*step;var to:=origin+Vector2(next)*step
			var safe:=true
			for k in range(1,5):
				if not clear.call(at.lerp(to,k/4.0)):safe=false;break
			if not safe:continue
			var price:float=cost[cell]+Vector2(offset).length()
			if price<float(cost.get(next,INF)):
				cost[next]=price;from[next]=cell
				if next not in open:open.append(next)
	return result
