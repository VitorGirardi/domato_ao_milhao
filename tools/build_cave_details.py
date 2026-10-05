"""Original cave detail pack. Run: blender --background --python tools/build_cave_details.py.
Meters, Blender Z-up exported glTF Y-up. No collision, lights or cameras in GLBs.
Ground props pivot at floor; hanging props at ceiling; wall front is Blender -Y
(Godot +Z), so turn 180 degrees around Y when facing Godot -Z is wanted.
Source contains named asset collections at their local origin. Render is QA only.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models'; SRC=ROOT/'art/source'; QA=ROOT/'test-results/cave-details'
for p in (OUT,SRC,QA): p.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for c in list(bpy.data.collections):
    if c.name!='Collection': bpy.data.collections.remove(c)
random.seed(68427)
def material(name,color,metal=0,emit=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p is None:
        p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled'); output=m.node_tree.nodes.new('ShaderNodeOutputMaterial'); m.node_tree.links.new(p.outputs['BSDF'],output.inputs['Surface'])
    p.inputs['Base Color'].default_value=(*color,1); p.inputs['Roughness'].default_value=.82; p.inputs['Metallic'].default_value=metal
    if emit: p.inputs['Emission Color'].default_value=(*color,1); p.inputs['Emission Strength'].default_value=emit
    return m
stone=[material('Basalt warm '+str(i),c) for i,c in enumerate([(.28,.28,.29),(.36,.35,.34),(.43,.40,.37),(.32,.34,.35)])]
copper=[material('Copper oxide jade',(.19,.49,.40),.2), material('Copper raw orange',(.64,.34,.15),.45),material('Copper sun face',(.77,.46,.22),.3)]
iron=[material('Iron slate',(.23,.30,.34),.35),material('Iron rust',(.46,.24,.13)),material('Iron glint',(.40,.49,.52),.5)]
crystal=[material('Quartz ice',(.38,.75,.82),.15,.16),material('Quartz lilac',(.57,.46,.77),.1,.13),material('Quartz pale',(.68,.86,.84),.1,.12)]
wood=material('Timber honey',(.34,.20,.10)); end=material('Timber end grain',(.49,.32,.16)); bark=material('Roots old bark',(.24,.16,.105)); metal=material('Forged iron',(.12,.15,.16),.5); rope=material('Hemp',(.59,.44,.24)); amber=material('Lantern amber luminous', (1,.49,.105),0,2.2)
assets={}; current=None
def asset(name):
    global current
    current=bpy.data.collections.new('DETAIL_'+name); bpy.context.scene.collection.children.link(current); assets[name]=current

def finish(o,name,mat):
    o.name=name
    for c in list(o.users_collection): c.objects.unlink(o)
    current.objects.link(o); o.data.materials.append(mat); return o

def cube(name,loc,scale,mat,bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    finish(o,name,mat)
    if bevel:
        mod=o.modifiers.new('Soft hand hewn edges','BEVEL'); mod.width=bevel; mod.segments=1
        bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    return o

def ico(name,loc,scale,mat,sub=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=loc); o=bpy.context.object; o.scale=scale
    for v in o.data.vertices: v.co*=random.uniform(.88,1.10)
    return finish(o,name,mat)

def rod(name,a,b,r,mat,r2=None,n=8):
    a,b=Vector(a),Vector(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=n,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)/2)
    o=bpy.context.object; o.rotation_euler=d.to_track_quat('Z','Y').to_euler(); return finish(o,name,mat)

def ring(name,loc,major,minor,mat,rotation=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=5,location=loc,major_radius=major,minor_radius=minor,rotation=rotation); return finish(bpy.context.object,name,mat)

for name,ore in [('ore_copper',copper),('ore_iron',iron)]:
    asset(name)
    ico('Weathered ore boulder',(0,0,.4),(1,.69,.55),stone[2 if name=='ore_copper' else 0],2)
    for i in range(11):
        x=random.uniform(-.73,.73); y=random.uniform(-.48,.25); z=.4+.55*math.sqrt(max(.1,1-x*x-(y/.69)**2))
        ico('Exposed mineral seam %02d'%i,(x,y,z),(random.uniform(.12,.24),.12,.16),ore[i%3])
    for x,y in [(-.8,-.45),(.74,-.4),(.37,.5)]: ico('Loose ore chip',(x,y,.10),(.21,.18,.15),ore[0])
asset('crystals')
ico('Quartz bed',(0,0,.13),(.86,.64,.20),stone[1],2)
for i,(x,y,h,r) in enumerate([(-.12,.1,1.73,.25),(.31,.12,1.35,.23),(-.45,0,1.03,.2),(.12,-.3,.87,.20),(.55,-.13,.62,.16),(-.39,-.34,.53,.17)]):
    rod('Hexagonal quartz shaft', (x,y,.13),(x,y,h*.76),r,crystal[i%3],r*.84,6)
    rod('Quartz termination',(x,y,h*.76),(x+.035,y,h),r*.84,crystal[i%3],0,6)
asset('stalactites')
for i,(x,y,l,r) in enumerate([(-.68,.08,1.15,.34),(0,0,2.1,.43),(.63,.1,1.52,.32),(.3,-.32,.78,.24)]):
    rod('Limestone tapered pendant',(x,y,-l),(x,y,-.13),.025,stone[i%4],r,7)
    ico('Ceiling attachment',(x,y,-.05),(r*1.3,r*1.05,.18),stone[2])
asset('roots')
for i,x in enumerate([-.8,-.4,.05,.43,.78]):
    pts=[(x,0,0),(x+.14,-.08,-.45),(x-.1,-.05,-.94),(x+.09,-.08,-1.45),(x-.12,-.12,-1.9+random.random()*.4)]
    for j in range(4): rod('Tapered hanging root',pts[j],pts[j+1],.085-j*.017,bark,.066-j*.016,7)
    rod('Fine lateral root',pts[2],(x-.35,-.04,-1.35),.035,bark,.009,6)
asset('support')
for x in [-3.23,3.23]:
    cube('Hand hewn upright',(x,0,2.4),(.46,.60,4.8),wood,.05)
    cube('Iron foot shoe',(x,0,.25),(.49,.64,.22),metal,.025)
    cube('Upper iron binding',(x,0,4.52),(.49,.64,.17),metal,.015)
    for z in [.26,4.52]: ico('Square nail',(x,-.333,z),(.045,.019,.045),iron[1])
cube('Timber lintel',(0,0,5.07),(6.94,.68,.54),wood,.065)
for x in [-2.9,-1.7,0,1.7,2.9]:
    cube('Chisel mark',(x,-.346,5.07),(.13,.013,.12),end,.012)
# Short exterior braces preserve the full 6m by 4.8m opening.
for sign in [-1,1]: rod('Outer pegged brace',(sign*3.44,0,4.20),(sign*3.72,0,4.83),.105,wood,n=4)
asset('lantern')
rod('Octagonal foot',(0,0,.035),(0,0,.12),.25,metal,n=8)
rod('Amber glass',(0,0,.13),(0,0,.54),.175,amber,n=8)
for a in [0,math.pi/2,math.pi,math.pi*1.5]:
    x,y=math.cos(a)*.19,math.sin(a)*.19; rod('Protective frame',(x,y,.1),(x,y,.57),.025,metal,n=6)
rod('Pitched lantern hood',(0,0,.55),(0,0,.7),.27,metal,.08,8)
ring('Carry loop',(0,0,.80),.12,.023,metal,(math.pi/2,0,0))
asset('tools')
rod('Pickaxe ash handle',(-.65,0,.1),(.06,.07,1.5),.055,wood,.043)
rod('Pickaxe iron centre',(-.19,.07,1.39),(.32,.07,1.61),.073,metal,.06)
rod('Pickaxe pointed blade',(.32,.07,1.61),(.62,.08,1.45),.06,metal,.008)
rod('Pickaxe chisel',(-.19,.07,1.39),(-.48,.07,1.28),.073,metal,.025)
# Open stave bucket: individual tapered boards, visible hollow top.
for i in range(12):
    a=2*math.pi*i/12; o=cube('Bucket wooden stave',(.52+.24*math.cos(a),-.12+.24*math.sin(a),.27),(.115,.055,.5),end,.01); o.rotation_euler.z=a+math.pi/2
rod('Bucket bottom',(.52,-.12,.04),(.52,-.12,.07),.235,wood,n=12)
for z in [.10,.42]: ring('Bucket iron band',(.52,-.12,z),.25,.026,metal)
ring('Bucket handle',(.52,-.12,.55),.24,.017,metal,(math.pi/2,0,0))
for i in range(5): ring('Coiled hemp rope',(-.31,-.42,.047+i*.043),.27-i*.008,.028,rope)
asset('wall')
# Closed irregular mesh tiles form a visually solid modular rock face.
cube('Solid rock core',(0,.13,2.5),(8,.38,5),stone[0],.04)
for row in range(5):
    for col in range(8):
        x=-3.5+col+(.25 if row%2 else -.1); z=.50+row
        ico('Faceted wall stratum %d %d'%(row,col),(x+random.uniform(-.12,.12),-.05,z+random.uniform(-.1,.1)),(random.uniform(.62,.87),random.uniform(.23,.36),random.uniform(.63,.84)),stone[(row+col)%4],1)
# Normalize the declared mounting planes. Preserve support opening measurements.
bpy.context.view_layer.update()
for name,col in assets.items():
    bounds=[o.matrix_world@Vector(c) for o in col.objects for c in o.bound_box]
    low=[min(v[i] for v in bounds) for i in range(3)]; high=[max(v[i] for v in bounds) for i in range(3)]
    if name=='wall':
        factor=Vector((8/(high[0]-low[0]),.6/(high[1]-low[1]),5/(high[2]-low[2])))
        center=Vector(((high[0]+low[0])/2,(high[1]+low[1])/2,low[2]))
        for o in col.objects:
            o.location=(o.location-center)*factor; o.scale*=factor
    else:
        dz=-high[2] if name in ('stalactites','roots') else -low[2]
        for o in col.objects: o.location.z+=dz
# Exports are selection-only. Explicitly forbid camera/light export.
report={}
for name,col in assets.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in col.objects: o.select_set(True)
    bpy.context.view_layer.update()
    bounds=[o.matrix_world@Vector(c) for o in col.objects for c in o.bound_box]
    lo=[min(v[i] for v in bounds) for i in range(3)]; hi=[max(v[i] for v in bounds) for i in range(3)]
    report[name]={'blender_min':lo,'blender_max':hi,'mesh_objects':len(col.objects)}
    bpy.ops.export_scene.gltf(filepath=str(OUT/('cave_detail_'+name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_cameras=False,export_lights=False)
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'cave_details.blend'))
(QA/'dimensions.json').write_text(json.dumps(report,indent=2))
# Contact sheet arranged as three by three independent miniatures.
current=bpy.data.collections.new('QA presentation only'); bpy.context.scene.collection.children.link(current)
for i,(name,col) in enumerate(assets.items()):
    b=report[name]; lo,hi=b['blender_min'],b['blender_max']; s=3.25/max(hi[0]-lo[0],hi[2]-lo[2],1.0)
    offset=Vector(((i%3-1)*4.5, (1-i//3)*4.5, .3-lo[2]*s))
    for o in col.objects: o.location=o.location*s+offset; o.scale*=s
    cube('Display plinth',(offset.x,offset.y,.06),(3.9,3.6,.12),stone[0],.06)
    bpy.ops.object.text_add(location=(offset.x-1.65,offset.y-1.80,.20),rotation=(math.radians(65),0,0))
    txt=bpy.context.object; txt.data.body=name.replace('_',' ').upper(); txt.data.size=.21; txt.data.extrude=.002; txt.data.materials.append(crystal[2])
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=32
scene.world.color=(.21,.21,.21)
bpy.ops.object.camera_add(location=(11,-21,24)); cam=bpy.context.object; cam.rotation_euler=(Vector((0,0,.4))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO';cam.data.ortho_scale=19;scene.camera=cam
for loc,power,size in [((0,-7,13),2400,8),((-9,2,8),1800,7),((8,6,10),2100,6)]:
    bpy.ops.object.light_add(type='AREA',location=loc); l=bpy.context.object;l.data.energy=power;l.data.shape='DISK';l.data.size=size;l.rotation_euler=(-l.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=1600;scene.render.resolution_y=1600;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.filepath=str(QA/'contact-sheet.png');bpy.ops.render.render(write_still=True)
print('CAVE_DETAILS_COMPLETE '+str(QA/'contact-sheet.png'))

