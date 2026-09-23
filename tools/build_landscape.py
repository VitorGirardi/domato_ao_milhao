"""Original rounded countryside vegetation. Blender 5.x, deterministic and editable."""
import bpy, math, random
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
random.seed(2020)
def material(name,c):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 node=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
 if node is None:node=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
 out=next((n for n in m.node_tree.nodes if n.type=='OUTPUT_MATERIAL'),None)
 if out is None:out=m.node_tree.nodes.new('ShaderNodeOutputMaterial')
 m.node_tree.links.new(node.outputs['BSDF'],out.inputs['Surface'])
 node.inputs['Base Color'].default_value=(*c,1);node.inputs['Roughness'].default_value=.9
 return m
M=[material('Bark honey',(.24,.13,.064)),material('Leaf sage',(.095,.20,.045)),material('Leaf sun',(.17,.29,.072)),material('Leaf deep',(.065,.145,.03)),material('Wild cream',(.95,.86,.58)),material('Wild lavender',(.46,.28,.58)),material('Pollen',(.88,.53,.10)),material('Granite warm',(.35,.36,.29))]
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def ico(name,p,s,mat,sub=2):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=p)
 o=bpy.context.object;o.name=name;o.scale=s;o.data.materials.append(M[mat])
 for v in o.data.vertices:v.co*=random.uniform(.94,1.06)
 for f in o.data.polygons:f.use_smooth=True
 return o
def branch(a,b,r1,r2,mat=0):
 v=Vector(b)-Vector(a)
 bpy.ops.mesh.primitive_cone_add(vertices=9,radius1=r1,radius2=r2,depth=v.length,location=(Vector(a)+Vector(b))/2)
 o=bpy.context.object;o.rotation_euler=v.to_track_quat('Z','Y').to_euler();o.data.materials.append(M[mat])
def export(name):
 bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);bpy.ops.object.join()
 o=bpy.context.object;o.name=name;bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/source'/f'{name}.blend'))
 bpy.ops.export_scene.gltf(filepath=str(R/'assets/models'/f'{name}.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
 print('LANDSCAPE_ASSET_OK',name,len(o.data.polygons))
clear();branch((0,0,0),(.12,.06,3.7),.33,.12)
for a in [0,2.2,4.3]:
 x,y=math.cos(a),math.sin(a);branch((.06,0,1.9),(x*1.4,y*1.4,3.9),.15,.06)
for p,s,m in [((0,0,4.8),(1.95,1.8,1.5),2),((-1.35,.3,3.9),(1.35,1.3,1.25),1),((1.3,.4,4.0),(1.4,1.4,1.2),2),((.1,-1.1,3.8),(1.65,1.2,1.2),1),((-.1,1.0,4.2),(1.5,1.2,1.3),3)]:ico('Oak canopy',p,s,m)
export('valley_oak')
clear();branch((0,0,0),(.06,0,5.3),.22,.055)
for z,s,m in [(2.9,1.05,3),(3.8,1.2,1),(4.8,.95,2),(5.6,.58,2)]:ico('Poplar crown',(0,0,z),(s,s*.8,1.2),m)
export('valley_poplar')
clear()
for i in range(5):
 a=i*2.4;ico('Hedgerow',(math.cos(a)*.45,math.sin(a)*.35,.48),(.6,.58,.57),1+i%2)
export('valley_shrub')
clear()
# Curved solid ribbons, deliberately broad silhouettes at gameplay distance.
verts=[];faces=[]
for i in range(9):
 a=i*2.399;x=random.uniform(-.25,.25);y=random.uniform(-.25,.25);h=random.uniform(.22,.48);w=.045
 base=len(verts)
 for z,bend,width in [(0,0,w),(.55*h,.06,w*.7),(h,.16,0)]:
  cx=x+math.cos(a)*bend;cy=y+math.sin(a)*bend
  verts.extend([(cx-math.sin(a)*width,cy+math.cos(a)*width,z),(cx+math.sin(a)*width,cy-math.cos(a)*width,z)])
 faces.extend([(base,base+1,base+3,base+2),(base+2,base+3,base+5,base+4)])
mesh=bpy.data.meshes.new('Bent blades');mesh.from_pydata(verts,[],faces);mesh.materials.append(M[1]);o=bpy.data.objects.new('Meadow blades',mesh);bpy.context.collection.objects.link(o)
export('valley_grass')
for name,petal in [('valley_daisy',4),('valley_lavender',5)]:
 clear()
 for i in range(5):
  x=random.uniform(-.45,.45);y=random.uniform(-.45,.45);h=random.uniform(.28,.55)
  branch((x,y,0),(x+.025,y,h),.018,.009,3)
  for j in range(5):
   a=j*math.tau/5;ico('Petal',(x+.10*math.cos(a),y+.10*math.sin(a),h),(.12,.055,.033),petal,1)
  ico('Pollen',(x,y,h+.014),(.053,.053,.04),6,1)
 export(name)
clear()
for p,s in [((0,0,.38),(1.05,.7,.6)),((.6,.3,.2),(.65,.6,.35))]:ico('River granite',p,s,7,1)
export('valley_stone')
print('LANDSCAPE_KIT_OK')
