"""Original open rural garage. Coordinates below are game X / Y(up) / Z(front)."""
import bpy, math
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def pos(p): return (p[0], -p[2], p[1])
def material(name, color, metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    shader=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if shader is None:shader=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
    output=next((n for n in m.node_tree.nodes if n.type=='OUTPUT_MATERIAL'),None)
    if output is None:output=m.node_tree.nodes.new('ShaderNodeOutputMaterial')
    m.node_tree.links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Roughness'].default_value=.68
    shader.inputs['Metallic'].default_value=metal
    return m
def box(name,p,size,mat,bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos(p))
    o=bpy.context.object;o.name=name;o.scale=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new('Rounded working metal','BEVEL');mod.width=bevel;mod.segments=3
        bpy.ops.object.modifier_apply(modifier=mod.name)
        o.modifiers.new('Weighted corners','WEIGHTED_NORMAL')
    return o

def rod(name,a,b,r,mat):
    start,end=Vector(pos(a)),Vector(pos(b));d=end-start
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=d.length,location=(start+end)/2)
    o=bpy.context.object;o.name=name;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(mat)
    return o

def join(parts,name,origin):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.convert(target='MESH');bpy.ops.object.join()
    o=bpy.context.object;o.name=name
    bpy.context.scene.cursor.location=pos(origin);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return o


wood=material('Weathered garage wood',(.38,.23,.12));trim=material('Honey timber',(.61,.43,.23));roof=material('Corrugated sage metal',(.24,.34,.29),.45);iron=material('Old iron',(.16,.2,.18),.6);cream=material('Garage sign cream',(.9,.82,.64));red=material('Toolbox red',(.58,.19,.12))
# Tall open bay with a seven-meter opening. No raised floor to catch the bumper.
for x in [-3.6,3.6]:
 for z in [-4.5,0,4.5]:box('Timber post',(x,2.2,z),(.25,4.4,.25),wood)
 box('Side boards',(x,1.75,0),(.16,3.5,9.0),wood)
 for z in range(-4,5):box('Side batten',(x*1.005,1.8,z),(.19,3.5,.05),trim,.01)
box('Rear boards',(0,1.8,-4.5),(7.3,3.6,.18),wood)
box('Entrance beam',(0,4.25,4.5),(7.45,.35,.28),trim)
box('Roof sheet',(0,4.75,0),(7.8,.18,9.7),roof)
for x in range(-7,8):box('Roof corrugation',(x*.5,4.87,0),(.07,.06,9.7),roof,.015)
for z in [-4.8,4.8]:box('Eave',(0,4.69,z),(7.85,.24,.12),trim)
box('Sign board',(0,4.08,4.72),(2.1,.5,.12),cream)
# A wheel emblem and crossed tools are readable without baked typography.
for i in range(16):
 a=i*math.tau/16
 box('Wheel emblem',(.23*math.cos(a),4.08+.23*math.sin(a),4.80),(.08,.08,.04),iron,.02)
rod('Wrench',(-.78,3.94,4.80),(-.43,4.24,4.80),.045,iron)
rod('Hammer',(.43,3.94,4.80),(.75,4.24,4.80),.035,iron)
box('Hammer head',(.73,4.23,4.81),(.28,.11,.06),iron)
box('Workbench',(-2.8,1.16,-3.6),(1.15,.14,1.2),trim)
for x in [-3.25,-2.35]:
 for z in [-4.05,-3.15]:box('Bench leg',(x,.55,z),(.10,1.1,.10),wood)
box('Toolbox',(-2.8,1.4,-3.75),(.72,.35,.46),red)
box('Toolbox handle',(-2.8,1.62,-3.75),(.3,.08,.10),iron)
for x in [-1.8,1.8]:
 for z in [-3,-1,1,3]:box('Parking guide',(x,.015,z),(.07,.025,1.4),cream,.0)
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.ops.object.convert(target='MESH');bpy.ops.object.join();o=bpy.context.object;o.name='Garage'
bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/garage.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/garage.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('GARAGE_MODEL_OK')
