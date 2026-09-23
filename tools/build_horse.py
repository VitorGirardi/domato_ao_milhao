"""Original roadside landmarks; Blender sources and game GLBs."""
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
oval('Barrel',(0,.05,1.48),(.47,.83,.48),coat,body)
oval('Chest',(0,-.56,1.53),(.43,.39,.51),coat,body)
oval('Rump',(0,.57,1.49),(.46,.40,.49),coat,body)
neck=pivot('HorseNeck',(0,-.56,1.78),body)
o=oval('Neck',(0,-.78,2.00),(.29,.36,.62),coat,neck);o.rotation_euler.x=-.45
oval('Head',(0,-1.20,2.48),(.27,.45,.30),coat,neck)
o=oval('Long face',(0,-1.46,2.27),(.24,.42,.28),coat,neck);o.rotation_euler.x=-.45
oval('Muzzle',(0,-1.69,2.13),(.26,.22,.19),dark,neck)
oval('Blaze',(0,-1.54,2.47),(.073,.065,.25),sock,neck)
for x in [-.25,.25]:
 oval('Eye',(x,-1.29,2.56),(.040,.058,.054),eye,neck)
 oval('Eye glint',(x*1.09,-1.31,2.58),(.011,.012,.014),cream,neck)
 o=oval('Ear',(x*.72,-1.00,2.86),(.082,.11,.20),coat,neck);o.rotation_euler.y=-x*.7
 oval('Inner ear',(x*.72,-1.08,2.88),(.044,.025,.12),dark,neck)
 oval('Nostril',(x*.70,-1.86,2.16),(.039,.027,.035),eye,neck)
for i in range(7):oval('Mane',(0,-.49-i*.09,1.88+i*.135),(.16,.13,.20),dark,neck)
for x in [-.35,.35]:
 for y in [-.58,.58]:
  name=('Front' if y<0 else 'Hind')+('L' if x<0 else 'R')
  upper=pivot(name,(x,y,1.34))
  oval(name+' thigh',(x,y,1.09),(.135 if y<0 else .19,.16,.37),coat,upper)
  lower=pivot(name+'Lower',(x,y,.69),upper)
  oval(name+' shank',(x,y,.43),(.09,.10,.31),coat,lower)
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
 attach(beam((x,-1.68,2.17),(x,-1.01,2.63),.025,leather),neck)
 attach(beam((x,-1.50,2.26),(x,-.32,2.06),.025,leather),body)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/source/horse.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/models/horse.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('HORSE_ASSET_OK')
