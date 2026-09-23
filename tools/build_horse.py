"""Original stylized horse: continuous skinned anatomy, separate tack and joint rig."""
import bpy,math
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
def mat(name,c):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 node=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
 if node is None:node=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
 out=next((n for n in m.node_tree.nodes if n.type=='OUTPUT_MATERIAL'),None)
 if out is None:out=m.node_tree.nodes.new('ShaderNodeOutputMaterial')
 m.node_tree.links.new(node.outputs['BSDF'],out.inputs['Surface']);node.inputs['Base Color'].default_value=(*c,1);node.inputs['Roughness'].default_value=.85
 return m
wood=mat('Weathered chestnut',(.29,.15,.065));light=mat('Honey edges',(.52,.32,.13));stone=mat('Warm plaster',(.64,.58,.38));roof=mat('Terracotta',(.40,.12,.065));metal=mat('Iron',(.12,.16,.15));cream=mat('Linen',(.89,.79,.54));red=mat('Picnic coral',(.60,.16,.09));orange=mat('Pumpkin',(.83,.35,.065));green=mat('Stalk',(.18,.25,.07))
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def cube(name,p,s,m,bevel=.04):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.scale=s
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if bevel:
  mod=o.modifiers.new('Soft handmade corners','BEVEL');mod.width=bevel;mod.segments=2
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def beam(a,b,width,m):
 d=Vector(b)-Vector(a);o=cube('Timber', (Vector(a)+Vector(b))/2,(width,width,d.length),m,.025);o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return o
def cone(p,r1,r2,h,m,verts=12):
 bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=h,location=p);o=bpy.context.object;o.data.materials.append(m);return o
def export(name):
 bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH');bpy.ops.object.convert(target='MESH');bpy.ops.object.join()
 o=bpy.context.object;o.name=name;bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/source'/f'{name}.blend'))
 bpy.ops.export_scene.gltf(filepath=str(R/'assets/models'/f'{name}.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)

clear()
coat=mat('Horse chestnut',(.32,.135,.055));dark=mat('Mane espresso',(.065,.036,.025));sock=mat('Cream socks',(.82,.73,.51));eye=mat('Warm black',(.015,.018,.014));leather=mat('Saddle worn leather',(.14,.065,.035));blanket=mat('Saddle blanket teal',(.07,.27,.26))
def pivot(name,p,parent=None):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=p
 if parent:attach(o,parent)
 return o
def attach(o,parent):
 bpy.context.view_layer.update();matrix=o.matrix_world.copy();o.parent=parent;o.matrix_world=matrix;return o
def oval(name,p,s,m,parent=None):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,radius=1,location=p);o=bpy.context.object;o.name=name;o.scale=s;o.data.materials.append(m)
 for f in o.data.polygons:f.use_smooth=True
 if parent:attach(o,parent)
 return o
body=pivot('HorseBody',(0,0,1.45))
oval('Barrel',(0,.05,1.48),(.48,.87,.43),coat,body)
oval('Chest',(0,-.56,1.53),(.40,.36,.46),coat,body)
oval('Rump',(0,.57,1.49),(.47,.42,.46),coat,body)
neck=pivot('HorseNeck',(0,-.56,1.78),body)
o=oval('Neck',(0,-.79,1.97),(.235,.30,.55),coat,neck);o.rotation_euler.x=-.45
oval('Head',(0,-1.15,2.43),(.235,.33,.27),coat,neck)
o=oval('Long face',(0,-1.40,2.25),(.205,.35,.245),coat,neck);o.rotation_euler.x=-.45
oval('Muzzle',(0,-1.66,2.12),(.215,.205,.16),dark,neck)
# Chestnut face: no protruding white patch; facial markings must follow the skin.
for x in [-.225,.225]:
 oval('Eye',(x*.93,-1.25,2.50),(.040,.058,.054),eye,neck)
 oval('Eye glint',(x*.99,-1.27,2.515),(.011,.012,.014),cream,neck)
 o=oval('Ear',(x*.72,-1.00,2.76),(.063,.08,.15),coat,neck);o.rotation_euler.y=-x*.7
 oval('Inner ear',(x*.72,-1.08,2.78),(.032,.022,.085),dark,neck)
 oval('Nostril',(x*.55,-1.818,2.14),(.032,.018,.026),eye,neck)
for i in range(7):oval('Mane',(0,-.49-i*.09,1.88+i*.135),(.16,.13,.20),dark,neck)
for x in [-.35,.35]:
 for y in [-.58,.58]:
  name=('Front' if y<0 else 'Hind')+('L' if x<0 else 'R')
  upper=pivot(name,(x,y,1.34))
  oval(name+' thigh',(x,y,1.09),(.12 if y<0 else .175,.145 if y<0 else .20,.40),coat,upper)
  oval(name+' knee',(x,y,.70),(.105,.115,.12),coat,upper)
  lower=pivot(name+'Lower',(x,y,.69),upper)
  oval(name+' shank',(x,y,.43),(.082,.09,.35),coat,lower)
  oval(name+' sock',(x,y,.21),(.10,.115,.15),sock,lower)
  oval(name+' hoof',(x,y-.03,.09),(.135,.17,.10),dark,lower)
tail=pivot('HorseTail',(0,.79,1.65),body)
o=oval('Tail',(0,1.00,1.09),(.16,.20,.62),dark,tail);o.rotation_euler.x=.28
attach(cube('Blanket',(0,.04,1.88),(.95,.73,.07),blanket,.09),body)
attach(cube('Saddle',(0,.05,1.95),(.61,.53,.10),leather,.07),body)
for y in [-.26,.29]:oval('Saddle rim',(0,y,2.0),(.31,.075,.10),leather,body)
for x in [-.49,.49]:
 attach(cube('Girth',(x,0,1.50),(.04,.11,.65),leather,.015),body)
 attach(cube('Stirrup',(x,-.10,1.20),(.08,.22,.05),metal,.01),body)
# Bridle and reins remain attached to the head/body instead of floating props.
for x in [-.25,.25]:
 attach(beam((x*.83,-1.60,2.17),(x*.88,-1.01,2.59),.025,leather),neck)
 rein=attach(beam((x*.83,-1.55,2.22),(x,-.32,2.06),.025,leather),body);rein.name='ReinL' if x<0 else 'ReinR'
# Continuous anatomical surface. Rigid pivots above keep tack and facial details attached.
coat_objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and len(o.data.materials) and o.data.materials[0]==coat and not o.name.startswith('Ear')]
bpy.ops.object.select_all(action='DESELECT')
for o in coat_objects:
 matrix=o.matrix_world.copy();o.parent=None;o.matrix_world=matrix;o.select_set(True)
bpy.context.view_layer.objects.active=coat_objects[0];bpy.ops.object.join();skin=bpy.context.object;skin.name='HorseContinuousSkin'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
remesh=skin.modifiers.new('Continuous anatomy','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.028;remesh.use_smooth_shade=True
bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth=skin.modifiers.new('Relax surface','SMOOTH');smooth.factor=.65;smooth.iterations=5;bpy.ops.object.modifier_apply(modifier=smooth.name)
decimate=skin.modifiers.new('Game topology','DECIMATE');decimate.ratio=.38;bpy.ops.object.modifier_apply(modifier=decimate.name)
for poly in skin.data.polygons:poly.use_smooth=True
arm_data=bpy.data.armatures.new('HorseAnatomy');rig=bpy.data.objects.new('HorseRig',arm_data);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);skin.select_set(False);bpy.ops.object.mode_set(mode='EDIT')
positions={'HorseBody':(0,0,1.45),'HorseNeck':(0,-.56,1.78)}
for x in [-.35,.35]:
 for y in [-.58,.58]:
  key=('Front' if y<0 else 'Hind')+('L' if x<0 else 'R');positions[key]=(x,y,1.34);positions[key+'Lower']=(x,y,.69)
for key,pos in positions.items():
 bone=arm_data.edit_bones.new('Skin'+key);bone.head=pos;bone.tail=Vector(pos)+Vector((0,0,.25))
for key in positions:
 if key=='HorseNeck':arm_data.edit_bones['Skin'+key].parent=arm_data.edit_bones['SkinHorseBody']
 elif key.endswith('Lower'):arm_data.edit_bones['Skin'+key].parent=arm_data.edit_bones['Skin'+key[:-5]]
bpy.ops.object.mode_set(mode='OBJECT')
groups={key:skin.vertex_groups.new(name='Skin'+key) for key in positions}
def smoothstep(a,b,value):
 t=max(0,min(1,(value-a)/(b-a)));return t*t*(3-2*t)
for v in skin.data.vertices:
 x,y,z=v.co;weights={}
 leg=('Front' if y<0 else 'Hind')+('L' if x<0 else 'R')
 # Anatomical leg sockets blend gradually into shoulders and hindquarters.
 leg_w=(1-smoothstep(1.16,1.48,z))*smoothstep(.14,.28,abs(x))*smoothstep(.25,.42,abs(y))
 low=1-smoothstep(.55,.84,z)
 weights[leg]=leg_w*(1-low);weights[leg+'Lower']=leg_w*low
 neck_w=smoothstep(1.63,2.03,z)*(1-smoothstep(-.83,-.44,y))
 weights['HorseNeck']=(1-leg_w)*neck_w;weights['HorseBody']=(1-leg_w)*(1-neck_w)
 for key,w in weights.items():
  if w>0:groups[key].add([v.index],w,'REPLACE')
mod=skin.modifiers.new('Horse deformation','ARMATURE');mod.object=rig;skin.parent=rig
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/source/horse.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/models/horse.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('HORSE_ASSET_OK')
