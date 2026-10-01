"""Original authored waterfall cliff. Coordinates authored in Godot space then converted.
Run Blender --background --python tools/build_region_waterfall.py.
Animated water is supplied by FarmWaterfall; the .blend contains the editable cliff.
"""
import bpy, random, math
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
random.seed(623)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,c):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 n=m.node_tree.nodes.get('Principled BSDF')
 if n is None:
  n=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');out=next((x for x in m.node_tree.nodes if x.type=='OUTPUT_MATERIAL'),None) or m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(n.outputs['BSDF'],out.inputs['Surface'])
 n.inputs['Base Color'].default_value=(*c,1);n.inputs['Roughness'].default_value=.83
 return m
stone=[mat('Granite warm gray',(.33,.36,.32)),mat('Granite light',(.43,.46,.39)),mat('Wet granite',(.23,.30,.29))]
moss=mat('Velvet moss',(.18,.31,.075));leaf=mat('Fern green',(.20,.39,.11))
def rock(name,p,s,material):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(p[0],-p[2],p[1]))
 o=bpy.context.object;o.name=('SolidRock_' if material in stone else 'Vegetation_')+name;o.scale=(s[0],s[2],s[1]);o.rotation_euler[2]=random.uniform(-.3,.3)
 for v in o.data.vertices:v.co*=random.uniform(.87,1.13)
 o.data.materials.append(material);return o
# A closed rock core backs the whole water curtain; it has no hidden cavern.
# The curved face is set behind the water by .5m, descending below the pool.
profile=[(-3.6,2.5),(0,2.5),(4,.15),(8,-2.55),(12,-4.65),(15.7,-6.4)]
vs=[]
for y,z in profile:vs.extend([(-5.3,-z,y),(5.3,-z,y),(-5.3,14,y),(5.3,14,y)])
fs=[]
for k in range(len(profile)-1):
 i=k*4;j=i+4
 fs.extend([(i,i+1,j+1,j),(i+2,j+2,j+3,i+3),(i,j,i+2+4,i+2),(i+1,i+3,j+3,j+1)])
fs.extend([(0,2,3,1),(len(vs)-4,len(vs)-3,len(vs)-1,len(vs)-2)])
me=bpy.data.meshes.new('Closed wet cliff');me.from_pydata(vs,[],fs);me.materials.append(stone[2])
o=bpy.data.objects.new('SolidRock_ContinuousBackdrop',me);bpy.context.collection.objects.link(o)
# Recalculate outward normals for the exported closed solid.
bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');o.select_set(False)
# Overlapping solid boulders, submerged feet, and a narrower crown source.
# An embedded asymmetric amphitheatre: open middle leaves moving water exposed.
for side in [-1,1]:
 for k in range(4):
  p=(side*(5.6+random.uniform(-.4,.7)),k*4+1.2,-k*2.1-1.7)
  rock('Cliff ledge',p,(3.6,3.5,4),stone[k%3])
  rock('Moss shelf',(p[0],p[1]+2.7,p[2]),(2.7,.33,2.5),moss)
for x in [-6,-2,2,6]:
 rock('Spring crown',(x,15,-10),(3.4,2.2,3.4),stone[1])
 rock('Crown moss',(x,16.8,-10),(2.9,.28,2.7),moss)
# Boulder toes sit partly below water, and never bridge the plunge pool.
for x,z,s in [(-7,3,2.5),(7,2,2.1),(-10,0,2),(10,-3,2.6),(-4,-4,1.1)]:
 rock('Shore boulder',(x,-.3,z),(s,s*.7,s*.8),stone[2])
# Fern tufts at ledge edges, distinct from the cliff's large silhouettes.
for x,y,z in [(-7,4,0),(7,8,-4),(-6,12,-5),(5,17,-9),(-9,1,2)]:
 for i in range(7):
  a=i*math.tau/7;tip=(x+math.cos(a)*1.3,y+.5,z+math.sin(a)*.8)
  vs=[(x,-z,y),(tip[0],-tip[2],tip[1]),(x+math.cos(a+.4)*.7,-z-math.sin(a+.4)*.5,y+.7)]
  me=bpy.data.meshes.new('Fern');me.from_pydata(vs,[],[(0,1,2)]);me.materials.append(leaf)
  o=bpy.data.objects.new('Vegetation_Fern',me);bpy.context.collection.objects.link(o)
# Keep boulders separate: runtime uses their convex volumes, never hollow shells.
bpy.ops.object.select_all(action='SELECT')
(R/'art/source').mkdir(exist_ok=True,parents=True);(R/'assets/models').mkdir(exist_ok=True,parents=True)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/source/region_waterfall.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/models/region_waterfall.glb'),export_format='GLB',use_selection=True,export_apply=True)
# Static water is preview-only; runtime sheet has animated foam and ripples.
water=mat('Preview flowing blue',(.25,.69,.83))
vs=[]
for y,z,w in [(16,-6,3),(13,-4.8,3.2),(8,-2.3,3.5),(3,1,3.7),(-.35,3.3,4.5)]:
 vs += [(-w,-z,y),(w,-z,y)]
me=bpy.data.meshes.new('PreviewWater');me.from_pydata(vs,[],[(i,i+1,i+3,i+2) for i in range(0,8,2)]);me.materials.append(water)
o=bpy.data.objects.new('PreviewWater',me);bpy.context.collection.objects.link(o)
bpy.ops.mesh.primitive_plane_add(size=140);bpy.context.object.location.z=-.1;bpy.context.object.data.materials.append(water)
bpy.ops.object.camera_add(location=(25,-40,24));cam=bpy.context.object;cam.rotation_euler=(Vector((0,4,8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=33;bpy.context.scene.camera=cam
bpy.ops.object.light_add(type='SUN');bpy.context.object.rotation_euler=(.4,-.5,-.7);bpy.context.object.data.energy=2
scene=bpy.context.scene;scene.world.color=(.35,.48,.65);scene.render.engine='CYCLES';scene.cycles.samples=20;scene.render.resolution_x=1000;scene.render.resolution_y=850;scene.render.resolution_percentage=100
(R/'test-results').mkdir(exist_ok=True);scene.render.filepath=str(R/'test-results/waterfall-blender.png');bpy.ops.render.render(write_still=True)
