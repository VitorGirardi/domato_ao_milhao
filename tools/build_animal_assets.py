"""Original low-poly animal-care props, authored and exported with installed Blender."""
import bpy
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def material(name, hex_value):
    color = tuple(int(hex_value[i:i+2], 16)/255 for i in (0,2,4))
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color,1)
    result.use_nodes = True
    nodes = result.node_tree.nodes
    nodes.clear()
    shader = nodes.new('ShaderNodeBsdfPrincipled')
    shader.inputs['Base Color'].default_value = (*color,1)
    shader.inputs['Roughness'].default_value = .8
    output = nodes.new('ShaderNodeOutputMaterial')
    result.node_tree.links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    return result

M = {key:material(key,value) for key,value in {
    'Wood':'996741', 'Edge':'d9b578', 'Grain':'e6ad45', 'Bowl':'4c929b',
    'Water':'73cbd1', 'Straw':'d1a456', 'Shell':'fff1d5'
}.items()}

def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def finish(obj, name, key):
    obj.name=name
    obj.data.materials.append(M[key])
    return obj

def box(name, pos, size, key):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
    obj=bpy.context.object
    obj.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(obj,name,key)

def cylinder(name,pos,radius,depth,key):
    bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=radius,depth=depth,location=pos)
    return finish(bpy.context.object,name,key)

def export(name):
    # Keep fill as a separate node so the game can show the supply level.
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art'/'source'/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets'/'models'/f'{name}.glb'),
        export_format='GLB',use_selection=True,export_apply=True,export_yup=True,
        export_cameras=False,export_lights=False)
    print('ANIMAL_ASSET_OK',name)

clear()
box('Base',(0,0,.08),(.78,.55,.16),'Wood')
for y in [-.28,.28]: box('Side',(0,y,.22),(.84,.055,.26),'Edge')
for x in [-.4,.4]: box('End',(x,0,.22),(.055,.55,.26),'Wood')
box('Feed',(0,0,.20),(.73,.48,.08),'Grain')
export('feeder')

clear()
cylinder('Base',(0,0,.055),.37,.11,'Bowl')
bpy.ops.mesh.primitive_torus_add(major_radius=.325,minor_radius=.055,
    major_segments=12,minor_segments=6,location=(0,0,.18))
finish(bpy.context.object,'Rim','Bowl')
cylinder('Water',(0,0,.14),.29,.045,'Water')
export('waterer')

clear()
box('Bottom',(0,0,.065),(.90,.68,.13),'Wood')
box('Straw',(0,0,.145),(.8,.57,.055),'Straw')
for z in [.14,.26]:
    for y in [-.35,.35]: box('Rail',(0,y,z),(.96,.055,.075),'Edge')
    for x in [-.46,.46]: box('Rail',(x,0,z),(.055,.7,.075),'Wood')
for x in [-.44,.44]:
    for y in [-.32,.32]: box('Post',(x,y,.2),(.075,.075,.40),'Wood')
export('nest')

clear()
bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=1,location=(0,0,.13))
egg=bpy.context.object
for vertex in egg.data.vertices:
    vertex.co.x*=.09*(1-.15*vertex.co.z)
    vertex.co.y*=.09*(1-.15*vertex.co.z)
    vertex.co.z*=.13
finish(egg,'Egg','Shell')
export('egg')
