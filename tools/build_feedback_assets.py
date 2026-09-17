"""Articulated farmer and interaction props, authored in Blender. No third-party assets."""
import bpy
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT/'assets'/'models'
SOURCE = ROOT/'art'/'source'
EXPORT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)

def material(name, value):
    color = tuple(int(value[i:i+2], 16)/255 for i in (0,2,4))
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color,1)
    mat.use_nodes=True
    nodes=mat.node_tree.nodes
    nodes.clear()
    shader=nodes.new('ShaderNodeBsdfPrincipled')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Roughness'].default_value=.85
    output=nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    return mat

M={name:material(name,color) for name,color in {
    'Boot':'4c3830','Denim':'3d727e','Skin':'eeb882','Cream':'fff1ce',
    'Hat':'d8ae59','Wood':'98603c','Eye':'252f30','Can':'45999b',
    'Green':'3e863c','Leaf':'70a84c','Orange':'e37827','Gold':'efb53c'
}.items()}

def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def finish(obj, color):
    obj.data.materials.append(M[color])
    return obj

def box(pos,size,color,bevel=.02):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
    obj=bpy.context.object
    obj.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        modifier=obj.modifiers.new('Soft edges','BEVEL')
        modifier.width=bevel
        modifier.segments=1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return finish(obj,color)

def sphere(pos,scale,color):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=pos)
    obj=bpy.context.object
    obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(obj,color)

def cone(pos,radius,depth,color,top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=10,radius1=radius,radius2=radius if top is None else top,depth=depth,location=pos)
    return finish(bpy.context.object,color)

def group(name, members, pivot):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in members: obj.select_set(True)
    bpy.context.view_layer.objects.active=members[0]
    bpy.ops.object.join()
    result=bpy.context.object
    result.name=name
    bpy.context.scene.cursor.location=pivot
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return result

def export(name, merge=True):
    if merge:
        group(name,list(bpy.context.scene.objects),(0,0,0))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(EXPORT/f'{name}.glb'),export_format='GLB',
        use_selection=True,export_apply=True,export_cameras=False,export_lights=False,export_yup=True)
    print('FEEDBACK_ASSET_OK',name)

# The approved cartoon design owns the farmer mesh and its articulation pivots.
import runpy
runpy.run_path(str(ROOT/'tools'/'build_cartoon_characters.py'))['build']('farmer')

clear()
cone((0,0,.22),.24,.4,'Can',.20)
cone((0,0,.43),.19,.035,'Cream')
spout=cone((0,-.35,.3),.065,.5,'Can',.10)
spout.rotation_euler.x=math.radians(65)
rose=cone((0,-.57,.4),.13,.055,'Cream')
rose.rotation_euler.x=math.radians(65)
for x in [-.23,.23]: box((x,.06,.54),(.04,.05,.27),'Can',.01)
box((0,.06,.68),(.5,.05,.05),'Cream',.01)
export('watering_can')

clear()
for x in [-.52,0,.52]:
    for y in [-.52,0,.52]:
        cone((x,y,.18),.015,.25,'Green')
        for side in [-1,1]:
            leaf=sphere((x+side*.08,y,.26),(.12,.055,.035),'Leaf')
            leaf.rotation_euler.y=side*-.4
export('sprout')

for crop in ['carrot','corn','wheat']:
    clear()
    if crop=='carrot':
        carrot=cone((0,0,.25),.035,.5,'Orange',.14)
        for a in range(3):
            leaf=box((.06*math.sin(a*2.1),0,.63),(.06,.04,.3),'Green',.005)
            leaf.rotation_euler.y=(a-1)*.3
    elif crop=='corn':
        sphere((0,0,.3),(.14,.14,.32),'Gold')
        for x in [-.13,.13]: sphere((x,0,.15),(.055,.14,.25),'Green')
    else:
        for x in [-.1,0,.1]:
            cone((x,0,.25),.018,.5,'Gold')
            sphere((x,0,.62),(.07,.08,.23),'Gold')
    export('harvest_'+crop)
print('FEEDBACK_ASSETS_COMPLETE')
