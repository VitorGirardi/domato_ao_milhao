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
wood.name="PaintStableWood"
# Open-front rural shelter; broad eaves, timber frame and readable horseshoe sign.
for x in [-2.65,2.65]:
 for y in [-2.55,2.55]:cube('Post',(x,y,1.65),(.25,.25,3.3),wood)
for y in [-2.55,2.55]:
 cube('Crossbeam',(0,y,3.05),(5.65,.22,.25),wood)
for x in [-2.65,2.65]:
 cube('Side wall',(x,0,.8),(.18,5.2,1.6),wood)
 for z in [.22,.7,1.2,1.6]:cube('Side trim',(x,0,z),(.24,5.3,.065),light,.015)
 for y in [-2.4,-1.6,-.8,0,.8,1.6,2.4]:cube('Wall seam',(x,y,.8),(.20,.04,1.55),light,.008)
cube('Back wall',(0,2.55,1.4),(5.25,.18,2.8),wood)
for x in [-2,-1,0,1,2]:cube('Back batten',(x,2.43,1.4),(.07,.06,2.75),light,.01)
for x in [-1.48,1.48]:
 o=cube('Roof',(x,0,3.5),(3.3,5.95,.14),roof,.035);o.rotation_euler.y=(.23 if x>0 else -.23)
for y in [-2.95,2.95]:
 beam((-3,y,3.17),(0,y,3.87),.16,light);beam((0,y,3.87),(3,y,3.17),.16,light)
cube('Ridge',(0,0,3.88),(.2,6.05,.16),roof)
cube('Sign board',(0,-2.73,2.84),(1.35,.12,.61),cream)
# Horseshoe composed of rounded iron links on the sign.
for i in range(10):
 a=math.pi+i*math.pi/9
 o=cube('Horseshoe',(.23*math.cos(a),-2.815,2.96+.23*math.sin(a)),(.12,.06,.13),metal,.04)
# Straw bedding and bales sit against the back wall, leaving the entrance clear.
hay=mat('Golden straw',(.70,.49,.16))
cube('Bedding',(0,.45,.035),(4.7,3.4,.07),hay,.12)
for x in [-1.95,-1.05]:
 cube('Hay bale',(x,1.8,.39),(.75,.95,.72),hay,.12)
 for y in [1.55,2.04]:cube('Bale rope',(x,y,.76),(.74,.045,.02),cream,.007)
cube('Water trough',(1.9,1.7,.32),(.85,1.12,.58),wood,.07)
water=mat('Fresh trough water',(.13,.44,.47));cube('Water',(1.9,1.7,.62),(.70,.98,.025),water,.02)
export('stable')
print('STABLE_ASSET_OK')
