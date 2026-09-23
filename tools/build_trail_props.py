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
cone((0,0,1.9),1.35,.88,3.8,stone)
cone((0,0,4.15),1.17,0,1.3,roof)
for x in [-.47,.47]:beam((x,-1.05,.06),(x,-.86,1.7),.11,wood)
cube('Door',(0,-1.33,.88),(.83,.10,1.6),wood)
for z in [.3,.7,1.1,1.5]:cube('Door slats',(0,-1.40,z),(.78,.06,.05),light,.01)
cube('Loft window',(0,-.96,3.05),(.51,.07,.65),metal)
for x in [-.30,.30]:cube('Window edge',(x,-1.01,3.05),(.10,.08,.8),light)
beam((0,0,3.4),(0,-1.22,4.8),.18,wood)
export('trail_windmill')
clear()
# Rotor is authored in the X/Z plane; the origin is the spinning axle.
for i in range(4):
 a=i*math.pi/2
 def rot(x,z):return (math.cos(a)*x-math.sin(a)*z,0,math.sin(a)*x+math.cos(a)*z)
 beam(rot(0,.13),rot(0,2.22),.10,wood)
 for k in range(7):
  z=.7+k*.21;o=cube('Wind sail',rot(.22,z),(.59,.10,.15),cream,.025);o.rotation_euler.y=-a
bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.21);bpy.context.object.data.materials.append(metal)
export('trail_rotor')
clear()
for x in [-.92,.92]:
 beam((x,-.55,0),(x,.25,.86),.14,wood);beam((x,.55,0),(x,-.25,.86),.14,wood)
for y in [-.34,-.11,.12,.35]:cube('Table plank',(0,y,.92),(2.5,.21,.12),light)
for y in [-.96,.96]:
 cube('Seat',(0,y,.51),(2.7,.34,.12),light)
 for x in [-.95,.95]:cube('Bench leg',(x,y,.23),(.16,.25,.46),wood)
cube('Tablecloth',(0,0,1.0),(1.20,.89,.025),cream,.008)
for x in [-.48,-.16,.16,.48]:cube('Cloth stripe',(x,0,1.017),(.09,.9,.005),red,.001)
cube('Basket',(.53,.03,1.18),(.55,.38,.35),wood)
for z in [1.07,1.16,1.25,1.34]:cube('Basket weave',(.53,-.17,z),(.56,.027,.035),light,.008)
cone((-.30,-.07,1.13),.09,.11,.20,cream)
export('trail_picnic')
clear()
for y in [-.45,-.22,0,.22,.45]:cube('Cart bed',(0,y,.72),(2.5,.20,.14),wood)
for y in [-.61,.61]:
 for z in [.94,1.20]:cube('Side plank',(0,y,z),(2.6,.09,.19),light)
 for x in [-1.14,1.14]:cube('Cart stake',(x,y,1.06),(.13,.13,.92),wood)
for x in [-.8,.8]:
 beam((x,-.95,.51),(x,.95,.51),.10,metal)
 for y in [-.87,.87]:
  bpy.ops.mesh.primitive_torus_add(major_segments=20,minor_segments=6,major_radius=.43,minor_radius=.065,location=(x,y,.50),rotation=(math.pi/2,0,0));bpy.context.object.data.materials.append(wood)
  for i in range(6):
   a=i*math.pi/3;beam((x,y,.5),(x+math.cos(a)*.42,y,.5+math.sin(a)*.42),.045,light)
for y in [-.48,.48]:beam((1.2,y,.73),(2.2,y,.40),.11,wood)
for x,y,s in [(-.7,-.15,.36),(0,.10,.46),(.7,-.12,.33)]:
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=1,location=(x,y,.83+s*.7));o=bpy.context.object;o.scale=(s,s,s*.77);o.data.materials.append(orange)
 for v in o.data.vertices:
  a=math.atan2(v.co.y,v.co.x);v.co.x*=1+.06*math.cos(a*6);v.co.y*=1+.06*math.cos(a*6)
 beam((x,y,.83+s*1.4),(x+.03,y,.83+s*1.4+.14),.065,green)
export('trail_cart')
print('TRAIL_PROPS_OK')
