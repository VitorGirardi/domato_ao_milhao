"""Blender 5.2: isolated farm fences, gates, well and wash tub; no game integration."""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models'
QA = ROOT / 'test-results/art-fences'
OUT.mkdir(parents=True, exist_ok=True)
QA.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for col in list(bpy.data.collections):
    if col.name != 'Collection': bpy.data.collections.remove(col)

def mat(name, color, rough=.8, metal=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    m.node_tree.nodes.clear()
    p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled'); output=m.node_tree.nodes.new('ShaderNodeOutputMaterial'); m.node_tree.links.new(p.outputs['BSDF'],output.inputs['Surface']); p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=rough; p.inputs['Metallic'].default_value=metal
    return m
wood=mat('Honey aged timber',(.32,.16,.065)); light=mat('Warm exposed end grain',(.53,.31,.12))
cream=mat('Chalk cream paint',(.86,.80,.61)); teal=mat('Weathered teal',(.10,.31,.29))
iron=mat('Forged charcoal iron',(.065,.085,.075),.48,.65)
stone=[mat('Sandstone '+str(i),c) for i,c in enumerate([(.50,.48,.36),(.63,.60,.45),(.57,.54,.40)])]
roof=mat('Terracotta roof',(.55,.22,.10)); rope=mat('Hemp rope',(.55,.40,.20))
water=mat('Clean blue water',(.07,.40,.54),.23,.15); dark=mat('Well interior',(.055,.075,.06))
assets={}; current=None

def register(o,name,m,parent=None):
    o.name=name
    for c in list(o.users_collection): c.objects.unlink(o)
    current.objects.link(o)
    if m: o.data.materials.append(m)
    if parent: o.parent=parent
    return o

def box(name,p,s,m,bevel=.018,parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p); o=register(bpy.context.object,name,m,parent); o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Soft handmade edges','BEVEL'); mod.width=bevel;mod.segments=1
        o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return o

def cyl(name,p,r,depth,m,verts=12,rotation=None,parent=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=p)
    o=register(bpy.context.object,name,m,parent)
    if rotation:o.rotation_euler=rotation
    return o

def beam(name,a,b,width,m,parent=None):
    mid=(Vector(a)+Vector(b))/2; d=Vector(b)-Vector(a)
    o=box(name,mid,(width,width,d.length),m,parent=parent); o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return o

def torus(name,p,major,minor,m,rotation=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=20,minor_segments=6,location=p,major_radius=major,minor_radius=minor)
    o=register(bpy.context.object,name,m)
    if rotation:o.rotation_euler=rotation
    return o

def start(key):
    global current
    current=bpy.data.collections.new('farm_art_'+key);bpy.context.scene.collection.children.link(current);assets[key]=current

def fence(painted=False):
    start('fence_painted' if painted else 'fence_rustic'); m=cream if painted else wood
    for x in [-.91,.91]:
        box('Square post',(x,0,.60),(.18,.20,1.20),m)
        box('Post cap',(x,0,1.22),(.18,.24,.08),teal if painted else light)
    for z in [.37,.88]:
        box('Continuous two metre rail',(0,.035,z),(2,.11,.16),m)
    if painted:
        for x in [-.6,-.3,0,.3,.6]:
            box('Cream picket',(x,-.045,.61),(.095,.095,.92),cream)
    else:
        beam('Diagonal timber brace',(-.83,-.05,.28),(.83,-.05,.96),.065,light)
    for x in [-.91,.91]:
        for z in [.37,.88]:cyl('Iron nail',(x,-.08,z),.022,.018,iron,8,(math.pi/2,0,0))

def gate(painted=False):
    start('gate_painted' if painted else 'gate_rustic'); m=cream if painted else wood
    for x in [-1.52,1.52]:
        box('Gateway post',(x,0,.72),(.24,.27,1.44),m)
        box('Gateway cap',(x,0,1.46),(.31,.34,.09),teal if painted else light)
    # Named empties are hinge pivots in glTF, local Y-up after export.
    for side in [-1,1]:
        pivot=bpy.data.objects.new('GateHingeLeft' if side==-1 else 'GateHingeRight',None);current.objects.link(pivot)
        pivot.location=(side*1.40,0,0)
        objects=[]
        for z in [.28,1.04]:objects.append(box('Gate horizontal rail',(side*.72,-.02,z),(1.32,.12,.14),m))
        for x in [side*.08,side*1.35]:objects.append(box('Gate upright',(x,-.02,.66),(.12,.12,.96),m))
        a=(side*1.29,-.085,.32); b=(side*.15,-.085,.99)
        objects.append(beam('Gate diagonal brace',a,b,.09,teal if painted else light))
        for z in [.30,1.04]:
            objects.append(box('Forged hinge strap',(side*1.25,-.105,z),(.36,.035,.065),iron))
            objects.append(cyl('Hinge pin',(side*1.40,0,z),.035,.20,iron))
        for o in objects:
            world=o.matrix_world.copy();o.parent=pivot;o.matrix_world=world
    box('Center sliding latch',(0,-.12,.90),(.31,.055,.06),iron)
    cyl('Latch grip',(.06,-.16,.94),.024,.10,iron)

def well():
    start('well')
    cyl('Deep shadow inside well',(0,0,.07),.75,.14,dark,24)
    cyl('Water below rim',(0,0,.30),.64,.02,water,24)
    for row in range(3):
        for i in range(12):
            angle=2*math.pi*(i+(row%2)*.5)/12
            o=box('Individual stone block',(.83*math.cos(angle),.83*math.sin(angle),.15+row*.28),(.46,.28,.29),stone[(row+i)%3],.04)
            o.rotation_euler.z=angle+math.pi/2
    for x in [-1.05,1.05]:box('Roof support',(x,0,1.34),(.15,.18,2.68),wood)
    beam('Roof ridge',(-1.30,0,2.83),(1.30,0,2.83),.15,wood)
    for side in [-1,1]:
        for i in range(10):
            x=-1.17+i*.26
            beam('Separate roof plank',(x,0,2.86),(x,side*.98,2.31),.27,roof)
        beam('Roof edge',(-1.35,side*.97,2.29),(1.35,side*.97,2.29),.11,wood)
    cyl('Windlass axle',(0,0,1.66),.09,2.46,wood,12,(0,math.pi/2,0))
    for i in range(8):torus('Rope winding',(-.14+i*.04,0,1.66),.105,.022,rope,(0,math.pi/2,0))
    beam('Hanging rope',(0,-.12,.63),(0,-.12,1.63),.025,rope)
    beam('Crank arm',(1.30,0,1.66),(1.30,0,1.38),.065,iron)
    beam('Crank grip',(1.28,0,1.38),(1.55,0,1.38),.065,light)
    bucket((.72,-1.05,.02))

def bucket(p):
    x,y,z=p
    for i in range(10):
        a=i*2*math.pi/10;o=box('Bucket stave',(x+.16*math.cos(a),y+.16*math.sin(a),z+.17),(.11,.05,.32),light,.009);o.rotation_euler.z=a+math.pi/2
    cyl('Bucket base',(x,y,z+.025),.15,.035,wood)
    for dz in [.07,.26]:torus('Bucket iron band',(x,y,z+dz),.172,.016,iron)
    beam('Bucket handle left',(x-.18,y,z+.28),(x-.18,y,z+.48),.025,iron)
    beam('Bucket handle right',(x+.18,y,z+.28),(x+.18,y,z+.48),.025,iron)
    beam('Bucket handle grip',(x-.18,y,z+.48),(x+.18,y,z+.48),.027,iron)

def wash():
    start('wash_tub')
    # Continuous basin with a visible water surface below its rim.
    box('Trough bottom',(0,0,.18),(1.55,.80,.20),wood)
    for x in [-.76,.76]:box('Trough short wall',(x,0,.45),(.12,.90,.56),wood)
    for y in [-.39,.39]:box('Trough long wall',(0,y,.45),(1.55,.12,.56),light)
    box('Water in trough',(0,0,.61),(1.39,.65,.025),water,.005)
    for x in [-.52,.52]:
        for y in [-.3,.3]:box('Short foot',(x,y,.075),(.18,.18,.15),wood)
        for y in [-.46,.46]:box('Black iron band',(x,y,.43),(.045,.025,.58),iron,.005)
    box('Pump plinth',(0,.68,.15),(.57,.48,.30),stone[1],.035)
    cyl('Pump foot',(0,.68,.33),.20,.08,teal)
    cyl('Pump column',(0,.68,.78),.105,.86,teal)
    cyl('Pump cap',(0,.68,1.22),.14,.09,teal)
    beam('Pump spout',(0,.68,1.05),(0,.22,1.05),.10,teal)
    beam('Spout down',(0,.22,1.05),(0,.22,.91),.10,teal)
    beam('Pump lever hinge',(.10,.68,1.16),(.33,.68,1.16),.06,iron)
    beam('Pump lever',(.30,.68,1.16),(.59,.68,1.43),.055,iron)
    beam('Pump wooden handle',(.59,.58,1.43),(.59,.83,1.43),.065,light)
    bucket((1.15,-.1,0))

fence();fence(True);gate();gate(True);well();wash()
manifest={}
for key,col in assets.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in col.objects:o.select_set(True)
    path=OUT/('farm_art_'+key+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
    deps=bpy.context.evaluated_depsgraph_get();points=[]
    for o in col.objects:
        if o.type=='MESH':points += [o.matrix_world@Vector(v) for v in o.evaluated_get(deps).bound_box]
    lo=[min(p[i] for p in points) for i in range(3)];hi=[max(p[i] for p in points) for i in range(3)]
    manifest[key]={'bounds_godot':{'min':[lo[0],lo[2],-hi[1]],'max':[hi[0],hi[2],-lo[1]]},'mesh_count':sum(o.type=='MESH' for o in col.objects),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

# Source keeps each asset at its natural origin; render staging is not exported.
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/art_fences.blend'))
for index,(key,col) in enumerate(assets.items()):
    offset=Vector(((index%3)*3.8,(index//3)*4.3,0))
    for o in col.objects:
        if not o.parent:o.location+=offset
current=bpy.data.collections.new('QA staging');bpy.context.scene.collection.children.link(current)
ground=mat('QA warm ground',(.24,.31,.18));box('Ground',(3.8,2.1,-.11),(14,12,.2),ground)
bpy.ops.object.camera_add(location=(12,-13,12));camera=bpy.context.object;camera.rotation_euler=(Vector((3.8,2,1))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=14.5;bpy.context.scene.camera=camera
bpy.ops.object.light_add(type='AREA',location=(2,-4,12));bpy.context.object.data.energy=2000;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=8
scene=bpy.context.scene;scene.world.color=(.38,.45,.55);scene.render.engine='CYCLES';scene.cycles.samples=40
scene.render.resolution_x=1600;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.filepath=str(QA/'fences_overview.png');bpy.ops.render.render(write_still=True)
(QA/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('ART_FENCES_OK '+json.dumps(manifest))
