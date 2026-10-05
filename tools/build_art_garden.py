"""Original cozy garden kit; Blender 5.2 --background --python tools/build_art_garden.py -- --render.
Meters, ground Z=0, front -Y. glTF exports Godot Y-up, front +Z.
Six independent collections at origin; no runtime hooks or collisions.
"""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models'; SRC=ROOT/'art/source'; QA=ROOT/'test-results/garden-models'
for p in (OUT,SRC,QA):p.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
assets={};current=None

def mat(name,c):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
 if p is None:
  p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');o=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs['BSDF'],o.inputs['Surface'])
 p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=.85
 return m
wood=mat('Garden honey oak',(.48,.285,.12));light=mat('Fresh cut warm oak',(.63,.41,.21));dark=mat('End grain and bark',(.25,.13,.055));soil=mat('Rich planting soil',(.16,.10,.045))
leaf=mat('Vegetable leaf',(.24,.46,.085));leaf2=mat('Leaf sunlit tips',(.40,.60,.12));shade=mat('Orchard dark green',(.12,.29,.065));orange=mat('Ripe orange harvest',(.96,.35,.035));cream=mat('Cream garden labels',(.86,.78,.57));teal=mat('Sage painted accents',(.16,.39,.33));metal=mat('Dark garden iron',(.14,.16,.13));rope=mat('Jute ties',(.61,.50,.29))
def begin(name):
 global current
 current=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(current);assets[name]=current

def finish(o,name,m):
 o.name=name
 for c in list(o.users_collection):c.objects.unlink(o)
 current.objects.link(o);o.data.materials.append(m);return o

def box(name,at,size,m,bevel=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,name,m)
 if bevel:
  mod=o.modifiers.new('Hand softened edges','BEVEL');mod.width=bevel;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o

def ell(name,at,scale,m,sub=1):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=at);o=bpy.context.object;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,m)

def rod(name,a,b,r,m,r2=None,vertices=7):
 a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return finish(o,name,m)

def foliage(name,x,y,z,size=.2,m=leaf):
 for k in range(5):
  a=k*math.tau/5;o=ell(name,(x+math.cos(a)*size*.35,y+math.sin(a)*size*.35,z),(.10*size/.2,.25*size/.2,.065),m);o.rotation_euler=(.35*math.sin(a),.35*math.cos(a),a)

def label(x,y,z):
 rod('Plant label stake',(x,y,.15),(x,y,z),.025,wood)
 box('Cream plant marker',(x,y-.025,z),(.28,.06,.17),cream,.018)
 box('Teal marker stripe',(x,y-.058,z),(.16,.01,.033),teal)

begin('farm_art_raised_bed')
box('Closed base of soil',(0,0,.17),(2.25,1.25,.34),soil,.03)
for z in (.12,.35):
 for y in (-.65,.65):box('Long bed boards',(0,y,z),(2.4,.10,.21),wood if z<.2 else light,.018)
 for x in (-1.15,1.15):box('End bed boards',(x,0,z),(.10,1.2,.21),wood,.015)
for x in (-1.13,1.13):
 for y in (-.63,.63):
  box('Bed corner post',(x,y,.255),(.15,.15,.51),dark,.016)
  for z in (.15,.37):ell('Iron nail',(x,y-.085,z),(.026,.012,.026),metal)
for x in (-.78,-.27):
 for y in (-.34,.04,.38):
  ell('Carrot shoulder',(x,y,.39),(.09,.09,.10),orange)
  for k in range(4):
   a=k*math.tau/4;rod('Carrot frond',(x,y,.44),(x+.13*math.cos(a),y+.13*math.sin(a),.70),.024,leaf,r2=.008)
for x in (.30,.78):
 for y in (-.29,.29):
  foliage('Lettuce outer leaves',x,y,.46,.23,leaf);foliage('Lettuce heart',x,y,.52,.15,leaf2)
label(.04,-.54,.74)

begin('farm_art_trellis')
for x in (-.92,.92):box('Trellis sturdy upright',(x,0,1),(.12,.16,2),wood,.018)
for z in (.38,.76,1.14,1.52,1.9):box('Horizontal trellis batten',(0,0,z),(2,.08,.065),light,.008)
for x in (-.60,-.30,0,.30,.60):box('Vertical trellis batten',(x,.045,1.12),(.06,.07,1.65),wood,.008)
for plant,x in enumerate((-.65,0,.63)):
 ell('Plant soil mound',(x,0,.065),(.25,.24,.065),soil)
 last=(x,-.12,.04)
 for k in range(8):
  z=.16+k*.23;xx=x+.09*math.sin(k*1.1+plant)
  rod('Climbing bean stem',last,(xx,-.12,z),.017,shade);last=(xx,-.12,z)
  side=-1 if k%2 else 1
  o=ell('Heart shaped bean leaf',(xx+side*.12,-.16,z+.025),(.17,.05,.105),leaf2 if k%3==0 else leaf);o.rotation_euler.y=side*.35
  if k in (2,4,6):rod('Hanging bean pod',(xx,-.19,z),(xx+.035,-.20,z-.19),.028,leaf2,r2=.01)
  if k in (3,6):box('Jute vine tie',(x,-.065,z),(.13,.025,.035),rope)
label(.78,-.30,.43)

def tree(mature):
 begin('farm_art_orchard_mature' if mature else 'farm_art_orchard_young')
 h=4.2 if mature else 2.0
 ell('Root soil collar',(0,0,.04),(.48 if mature else .32,.41 if mature else .29,.04),soil)
 rod('Tapered fruit tree trunk',(0,0,.01),(.10,0,h*.66),.19 if mature else .075,dark,r2=.085 if mature else .035)
 for k in range(5 if mature else 3):
  a=k*math.tau/(5 if mature else 3)+.2;reach=.91 if mature else .40
  end=(math.cos(a)*reach,math.sin(a)*reach,h*.71)
  rod('Fruit branch',(.06,0,h*.39),end,.085 if mature else .035,wood,r2=.027)
  ell('Rounded orchard canopy',end,(1.0 if mature else .47,.87 if mature else .43,.93 if mature else .45),leaf if k%2 else shade,2)
 ell('Sunlit crown',(.03,.06,h-.71 if mature else h-.38),(.92 if mature else .42,.85 if mature else .39,.71 if mature else .38),leaf2,2)
 if mature:
  for k in range(16):
   a=k*math.tau/16;r=1.72 if k%3 else 1.60;z=2.78+.24*math.sin(k*2.1)
   x,y=math.cos(a)*r,math.sin(a)*r
   ell('Ripe orange',(x,y,z),(.14,.14,.15),orange,2);rod('Orange stalk',(x,y,z+.08),(x,y,z+.18),.015,dark)
 else:
  for x in (-.28,.28):rod('Young tree support stake',(x,0,0),(x,0,1.12),.035,light)
  box('Soft jute trunk support',(0,-.045,.96),(.60,.045,.065),rope)
  label(.32,-.18,.47)
tree(False);tree(True)

begin('farm_art_compost')
for x in (-.65,.65):
 for y in (-.65,.65):box('Compost corner post',(x,y,.60),(.12,.12,1.20),dark,.014)
for row in range(5):
 z=.13+row*.22
 for x in (-.65,.65):box('Compost side slat',(x,0,z),(.09,1.36,.17),wood if row%2 else light,.008)
 box('Compost rear slat',(0,.65,z),(1.35,.09,.17),wood,.01)
 if row<3:box('Removable front slat',(0,-.65,z),(1.35,.09,.17),light,.01)
box('Compost dark fill',(0,0,.34),(1.20,1.2,.68),soil,.04)
for k in range(9):
 x=(k%3-1)*.32;y=(k//3-1)*.32;ell('Composting scraps',(x,y,.73),(.22,.17,.075),shade if k%2 else wood)
box('Teal compost plaque',(0,-.716,.44),(.43,.045,.17),teal,.012)
for x in (-.12,0,.12):box('Cream vent mark',(x,-.742,.44),(.05,.012,.065),cream)

def crate(x,y,z,w=.76,d=.56,filled=True):
 box('Crate bottom',(x,y,z+.05),(w,d,.10),wood)
 for xx in (-w/2+.04,w/2-.04):
  for yy in (-d/2+.04,d/2-.04):box('Crate corner',(x+xx,y+yy,z+.24),(.065,.065,.48),dark)
 for height in (.15,.32,.47):
  for yy in (-d/2,d/2):box('Crate long slat',(x,y+yy,z+height),(w,.045,.115),light,.008)
  for xx in (-w/2,w/2):box('Crate end slat',(x+xx,y,z+height),(.045,d,.115),wood,.008)
 if filled:
  for k in range(9):
   xx=x+(k%3-1)*.18;yy=y+(k//3-1)*.14
   ell('Harvest oranges',(xx,yy,z+.46),(.095,.095,.10),orange,2)
 box('Cream crate label',(x,y-d/2-.027,z+.30),(.25,.018,.14),cream)
 box('Teal harvest seal',(x,y-d/2-.039,z+.30),(.10,.012,.07),teal)
begin('farm_art_produce_crates')
crate(-.42,.05,0);crate(.42,.08,0);crate(-.42,.05,.52)
box('Resting carrot crate bottom',(.43,-.45,.04),(.64,.38,.08),wood)
for k in range(5):
 x=.18+k*.12;rod('Harvest carrot',(x,-.50,.08),(x,-.36,.23),.035,orange,r2=.07)
 foliage('Harvest carrot tops',x,-.35,.28,.09,leaf)

stats={}
for name,col in assets.items():
 bpy.context.view_layer.update();bpy.ops.object.select_all(action='DESELECT');objs=list(col.objects)
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0]
 points=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box]
 stats[name]={'meshes':len(objs),'vertices':sum(len(o.data.vertices) for o in objs),'blender_min':[round(min(p[i] for p in points),3) for i in range(3)],'blender_max':[round(max(p[i] for p in points),3) for i in range(3)]}
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_cameras=False,export_lights=False)
bpy.ops.object.select_all(action='DESELECT');bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'art_garden.blend'))
(QA/'model_stats.json').write_text(json.dumps(stats,indent=2));print('GARDEN_ART_OK '+json.dumps(stats))
if '--render' in sys.argv:
 offsets=[(-4,-2,0),(0,1,0),(-4,2,0),(4,2,0),(0,-2,0),(3,-2,0)]
 for col,offset in zip(assets.values(),offsets):
  for o in col.objects:o.location+=Vector(offset)
 bpy.ops.mesh.primitive_plane_add(size=200);bpy.context.object.data.materials.append(mat('QA grass',(.27,.34,.18)))
 bpy.ops.object.camera_add(location=(12,-20,16));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=16
 scene=bpy.context.scene;scene.camera=cam;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.world.color=(.4,.45,.54)
 bpy.ops.object.light_add(type='AREA',location=(-4,-8,15));bpy.context.object.data.energy=2500;bpy.context.object.data.size=10;bpy.context.object.rotation_euler=(Vector((0,0,0))-bpy.context.object.location).to_track_quat('-Z','Y').to_euler()
 scene.render.resolution_x=1600;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.render.filepath=str(QA/'garden_models.png');bpy.ops.render.render(write_still=True)
