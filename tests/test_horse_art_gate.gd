extends SceneTree
func _init():
 var s=FarmState.new()
 s.items=[]
 for turn in range(4):
  s.items=[{"kind":"gate_rustic","x":0.0,"z":0.0,"turn":turn}]
  assert(FarmHorse.structures_clear(Vector2.ZERO,s))
  var post=Vector3(1.52,0,0).rotated(Vector3.UP,turn*PI/2)
  assert(not FarmHorse.structures_clear(Vector2(post.x,post.z),s))
  var flank=Vector3(.9,0,0).rotated(Vector3.UP,turn*PI/2)
  assert(not FarmHorse.structures_clear(Vector2(flank.x,flank.z),s))
 s.items=[{"kind":"gate_rustic","x":0.0,"z":0.0,"turn":0},{"kind":"fence","x":2.675,"z":0.0,"turn":0},{"kind":"fence","x":-2.675,"z":0.0,"turn":0}]
 for z in [-2.0,-1.0,0.0,1.0,2.0]: assert(FarmHorse.structures_clear(Vector2(0,z),s))
 s.items.append({"kind":"fence","x":0.0,"z":0.0,"turn":0})
 assert(not FarmHorse.structures_clear(Vector2.ZERO,s))
 print("HORSE_ART_GATE_CLEARANCE_OK")
 quit()
