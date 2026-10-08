"""Original rural pickup. Coordinates below are game X / Y(up) / Z(front)."""
import bpy, math
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def pos(p): return (p[0], -p[2], p[1])
def material(name, color, metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    shader=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if shader is None:shader=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
    output=next((n for n in m.node_tree.nodes if n.type=='OUTPUT_MATERIAL'),None)
    if output is None:output=m.node_tree.nodes.new('ShaderNodeOutputMaterial')
    m.node_tree.links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Roughness'].default_value=.68
    shader.inputs['Metallic'].default_value=metal
    return m
green=material('Faded pasture green',(.22,.39,.30),.2)
cream=material('Warm ivory roof',(.88,.81,.61))
dark=material('Blackened chassis',(.06,.075,.065),.3)
rubber=material('Dusty all terrain rubber',(.065,.065,.055))
steel=material('Aged zinc',(.47,.51,.46),.6)
wood=material('Sun worn timber',(.48,.28,.12))
grain=material('Wood grain',(.28,.14,.06))
seat=material('Saddle brown vinyl',(.30,.14,.07))
lamp=material('Warm headlight lens',(1,.85,.46))
red=material('Red tail lens',(.68,.085,.04))
blue=material('Blue pale windshield',(.45,.66,.65))

def box(name,p,size,mat,bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos(p))
    o=bpy.context.object;o.name=name;o.scale=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new('Rounded working metal','BEVEL');mod.width=bevel;mod.segments=3
        bpy.ops.object.modifier_apply(modifier=mod.name)
        o.modifiers.new('Weighted corners','WEIGHTED_NORMAL')
    return o

def rod(name,a,b,r,mat):
    start,end=Vector(pos(a)),Vector(pos(b));d=end-start
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=d.length,location=(start+end)/2)
    o=bpy.context.object;o.name=name;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(mat)
    return o

def join(parts,name,origin):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.convert(target='MESH');bpy.ops.object.join()
    o=bpy.context.object;o.name=name
    bpy.context.scene.cursor.location=pos(origin);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return o

# Strong silhouette: narrow old cab, curved hood, open wood-lined working bed.
box('Frame',(0,.73,-.05),(1.85,.28,5.5),dark)
box('Body sills',(0,1.15,-.08),(2.36,.52,5.3),green,.12)
box('Hood',(0,1.72,1.84),(2.20,.59,1.88),green,.20)
box('Hood ivory spear',(0,2.025,1.95),(.08,.03,1.32),cream,.01)
box('Grille surround',(0,1.44,2.83),(2.15,.8,.14),cream,.09)
box('Grille recess',(0,1.44,2.915),(1.12,.43,.035),dark,.05)
for y in [1.29,1.39,1.49,1.59]:box('Grille horizontal bar',(0,y,2.94),(1.09,.045,.04),steel,.015)
for x in [-.82,.82]:
    rod('Headlight ring',(x,1.55,2.90),(x,1.55,3.0),.235,steel)
    rod('Round headlight',(x,1.55,2.99),(x,1.55,3.04),.19,lamp)
box('Front bumper',(0,.89,3.03),(2.65,.20,.28),steel,.08)
box('Rear bumper',(0,.86,-2.95),(2.57,.19,.22),steel,.05)
box('Rear plate',(0,1.08,-2.97),(.56,.20,.035),cream,.02)
box('Front plate',(0,.98,3.19),(.56,.20,.03),cream,.02)

# Real openings instead of opaque windows: the driver can be seen in the cab.
box('Cab floor',(0,1.30,.13),(2.15,.16,1.95),dark)
box('Cab rear lower',(0,1.92,-.92),(2.23,1.24,.14),green,.09)
box('Cab rear glass',(0,2.97,-.92),(1.66,.99,.055),blue,.04)
box('Roof',(0,3.72,.10),(2.46,.18,2.23),cream,.11)
door_parts=[]
for x in [-1.08,1.08]:
    rod('Windscreen pillar',(x,2.10,1.04),(x,3.65,.88),.065,cream)
    rod('Rear window pillar',(x,2.13,-.89),(x,3.66,-.89),.075,cream)
    before_door=set(bpy.context.scene.objects)
    box('Door',(x,1.85,.07),(.15,1.10,1.79),green,.07)
    box('Door ivory strip',(x*1.065,2.14,.08),(.03,.10,1.75),cream,.02)
    box('Door handle',(x*1.08,2.27,-.48),(.08,.055,.21),steel,.015)
    rod('Mirror stalk',(x,2.50,.79),(x*1.28,2.48,.72),.03,steel)
    box('Wing mirror',(x*1.31,2.51,.72),(.18,.28,.12),steel,.04)
    if x<0:door_parts.extend(o for o in bpy.context.scene.objects if o not in before_door)
    box('Running board',(x*1.14,.89,.12),(.34,.13,1.95),dark,.04)
box('Windshield lower rail',(0,2.17,1.03),(2.18,.12,.13),cream,.04)
box('Split windscreen center',(0,2.93,.95),(.05,1.43,.06),cream,.01)
box('Dash',(0,2.00,.86),(1.98,.22,.33),dark,.05)
for x in [-.53,.53]:
    box('Seat cushion',(x,1.71,-.19),(.81,.22,.68),seat,.10)
    box('Seat back',(x,2.16,-.48),(.84,.88,.17),seat,.09)
rod('Steering column',(-.53,1.95,.75),(-.53,2.30,.50),.055,dark)
bpy.ops.mesh.primitive_torus_add(major_radius=.25,minor_radius=.025,major_segments=24,minor_segments=8,location=pos((-.53,2.30,.50)),rotation=(math.radians(45),0,0))
bpy.context.object.name='SteeringWheel';bpy.context.object.data.materials.append(dark)
for x in [-.72,.72]:rod('Wiper',(x,2.23,1.08),(x+.22,2.51,1.03),.018,dark)

# Wooden cargo bed, steel stake pockets and honest wear patches.
for x in [-.85,-.51,-.17,.17,.51,.85]:
    box('Bed plank',(x,1.46,-1.95),(.31,.11,1.78),wood,.018)
    box('Timber grain',(x+.06,1.52,-1.96),(.018,.006,1.48),grain,.001)
for x in [-1.08,1.08]:
    for y in [1.72,2.02]:box('Bed side timber',(x,y,-1.94),(.09,.23,1.85),wood,.025)
    for z in [-2.8,-1.02]:box('Steel bed stake',(x,y-.04,z),(.13,.87,.13),green,.025)
for y in [1.72,2.02]:box('Tailgate plank',(0,y,-2.85),(2.12,.23,.10),wood,.025)
for x in [-.85,.85]:
    box('Tail lamp',(x,1.21,-2.94),(.25,.22,.07),red,.045)
    box('Mud flap',(x*1.24,.43,-2.26),(.50,.38,.06),rubber,.02)
for x,z in [(-1.15,-2.18),(1.15,1.55)]:box('Paint wear',(x,1.43,z),(.015,.11,.31),wood,.015)

driver_door=join(door_parts,'DriverDoor',(-1.08,1.85,.965))
body=join([o for o in bpy.context.scene.objects if o!=driver_door],'PickupBody',(0,0,0))
for front,z in [('F',1.84),('R',-1.85)]:
    for side,x in [('L',-1.18),('R',1.18)]:
        existing=set(bpy.context.scene.objects)
        rod('Tire',(x-.21,.65,z),(x+.21,.65,z),.65,rubber)
        outward=-1 if x<0 else 1
        face=x+outward*.225
        rod('Cream steel rim',(face,.65,z),(face+outward*.025,.65,z),.37,cream)
        rod('Round hub',(face+outward*.03,.65,z),(face+outward*.065,.65,z),.16,steel)
        for i in range(20):
            a=i*math.tau/20
            o=box('Tire tread',(x,.65+math.sin(a)*.635,z+math.cos(a)*.635),(.46,.075,.14),rubber,.013)
            o.rotation_euler.x=-a
        for i in range(5):
            a=i*math.tau/5
            rod('Wheel bolt',(face+outward*.025,.65+math.sin(a)*.23,z+math.cos(a)*.23),(face+outward*.06,.65+math.sin(a)*.23,z+math.cos(a)*.23),.033,dark)
        join([o for o in bpy.context.scene.objects if o not in existing],'Wheel_'+front+side,(x,.65,z))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/farm_pickup.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/farm_pickup.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('FARM_PICKUP_MODEL_OK')
