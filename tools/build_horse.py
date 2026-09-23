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
def loft(name,rings,m,parent,axis='z'):
 # Cross-sections define the silhouette directly, instead of piling up spheres.
 # Each ring is (axis position, center on the other axis, half width, half depth).
 vertices=[];faces=[];steps=24
 for along,center,width,depth in rings:
  for i in range(steps):
   a=2*math.pi*i/steps;x=width*math.cos(a);r=depth*math.sin(a)
   vertices.append((x,center+r,along) if axis=='z' else (x,along,center+r))
 for j in range(len(rings)-1):
  for i in range(steps):
   a=j*steps+i;b=j*steps+(i+1)%steps
   faces.append((a,b,b+steps,a+steps))
 faces.extend([tuple(reversed(range(steps))),tuple((len(rings)-1)*steps+i for i in range(steps))])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
 o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);o.data.materials.append(m)
 # Correct winding for both cross-section orientations before voxel fusion.
 bpy.context.view_layer.objects.active=o;o.select_set(True)
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
 for f in mesh.polygons:f.use_smooth=True
 o.select_set(False)
 return attach(o,parent)
body=pivot('HorseBody',(0,0,1.45))
oval('Barrel',(0,.02,1.48),(.46,.93,.44),coat,body)
oval('Rump',(0,.57,1.49),(.47,.42,.46),coat,body)
neck=pivot('HorseNeck',(0,-.50,1.53),body)
loft('Tapered neck',[(1.40,-.46,.18,.18),(1.60,-.59,.29,.29),(1.70,-.67,.28,.28),
 (1.83,-.75,.25,.265),(2.00,-.85,.215,.235),(2.16,-.95,.18,.205),
 (2.32,-1.03,.16,.18),(2.47,-1.075,.15,.14),(2.55,-1.10,.10,.08)],coat,neck)
loft('Equine head',[(-.99,2.43,.12,.15),(-1.10,2.45,.19,.22),(-1.23,2.41,.195,.215),
 (-1.36,2.32,.165,.19),(-1.51,2.23,.155,.15),(-1.64,2.17,.17,.13),(-1.73,2.15,.14,.105)],coat,neck,'y')
muzzle_mat=mat('Soft chestnut muzzle',(.19,.12,.075))
oval('Muzzle',(0,-1.715,2.145),(.175,.115,.105),muzzle_mat,neck)
# Chestnut face: no protruding white patch; facial markings must follow the skin.
for x in [-.185,.185]:
 oval('Eye',(x,-1.20,2.50),(.028,.044,.039),eye,neck)
 oval('Eye glint',(x*1.17,-1.215,2.51),(.007,.008,.009),cream,neck)
 o=oval('Ear',(x*.70,-1.06,2.67),(.055,.065,.11),coat,neck);o.rotation_euler.y=-x*.8
 oval('Inner ear',(x*.70,-1.115,2.685),(.026,.017,.060),dark,neck)
 oval('Nostril',(x*.86,-1.76,2.17),(.020,.036,.020),eye,neck)
loft('Mane crest',[(1.73,-.46,.065,.07),(1.93,-.57,.065,.075),(2.12,-.70,.062,.07),
 (2.30,-.84,.055,.065),(2.47,-.94,.06,.065),(2.57,-1.025,.075,.07)],dark,neck)
for x in [-.35,.35]:
 for y in [-.58,.58]:
  name=('Front' if y<0 else 'Hind')+('L' if x<0 else 'R')
  upper=pivot(name,(x,y,1.34))
  oval(name+' thigh',(x,y,1.09),(.12 if y<0 else .175,.145 if y<0 else .20,.40),coat,upper)
  oval(name+' knee',(x,y,.70),(.09,.10,.105),coat,upper)
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
 attach(beam((x*.69,-1.64,2.19),(x*.71,-1.09,2.59),.018,leather),neck)
 rein=attach(beam((x*.69,-1.62,2.18),(x,-.32,2.06),.018,leather),body);rein.name='ReinL' if x<0 else 'ReinR'
# Continuous anatomical surface. Rigid pivots above keep tack and facial details attached.
coat_objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and len(o.data.materials) and o.data.materials[0]==coat and not o.name.startswith('Ear')]
bpy.ops.object.select_all(action='DESELECT')
for o in coat_objects:
 matrix=o.matrix_world.copy();o.parent=None;o.matrix_world=matrix;o.select_set(True)
bpy.context.view_layer.objects.active=coat_objects[0];bpy.ops.object.join();skin=bpy.context.object;skin.name='HorseContinuousSkin'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
remesh=skin.modifiers.new('Continuous anatomy','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.021;remesh.use_smooth_shade=True
bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth=skin.modifiers.new('Relax surface','SMOOTH');smooth.factor=.65;smooth.iterations=14;bpy.ops.object.modifier_apply(modifier=smooth.name)
decimate=skin.modifiers.new('Game topology','DECIMATE');decimate.ratio=.38;bpy.ops.object.modifier_apply(modifier=decimate.name)
for poly in skin.data.polygons:poly.use_smooth=True
arm_data=bpy.data.armatures.new('HorseAnatomy');rig=bpy.data.objects.new('HorseRig',arm_data);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);skin.select_set(False);bpy.ops.object.mode_set(mode='EDIT')
positions={'HorseBody':(0,0,1.45),'HorseNeck':(0,-.50,1.53)}
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
 neck_w=smoothstep(1.40,1.88,z)*(1-smoothstep(-.80,-.30,y))
 weights['HorseNeck']=(1-leg_w)*neck_w;weights['HorseBody']=(1-leg_w)*(1-neck_w)
 for key,w in weights.items():
  if w>0:groups[key].add([v.index],w,'REPLACE')
 assert abs(sum(weights.values())-1)<1e-6,'Every skin vertex must follow the rig with normalized weights'
mod=skin.modifiers.new('Horse deformation','ARMATURE');mod.object=rig;skin.parent=rig
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/source/horse.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/models/horse.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('HORSE_ASSET_OK')
