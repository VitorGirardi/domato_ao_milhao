"""Original neighborhood noticeboard, built with the installed Blender."""
import bpy
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color):
    rgb=tuple(int(color[i:i+2],16)/255 for i in (0,2,4))
    mat=bpy.data.materials.new(name)
    mat.diffuse_color=(*rgb,1)
    mat.use_nodes=True
    nodes=mat.node_tree.nodes
    nodes.clear()
    shader=nodes.new('ShaderNodeBsdfPrincipled')
    shader.inputs['Base Color'].default_value=(*rgb,1)
    shader.inputs['Roughness'].default_value=.85
    output=nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    return mat

M={key:material(key,color) for key,color in {'Wood':'876241','Frame':'c2a270','Header':'345344','Paper':'fff0d0','Mint':'cddfc5','Gold':'efd285','Ink':'806c50','Pin':'ac6046'}.items()}

def box(name,pos,size,key):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
    obj=bpy.context.object
    obj.name=name
    obj.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(M[key])

for x in [-1.11,1.11]: box('Post',(x,0,1.31),(.16,.20,2.62),'Wood')
box('Board',(0,0,1.78),(2.25,.12,1.42),'Wood')
for z in [1.04,2.53]: box('Frame',(0,-.015,z),(2.51,.20,.14),'Frame')
box('Header',(0,-.09,2.24),(2.10,.05,.34),'Header')
for x,key in [(-.70,'Paper'),(0,'Mint'),(.70,'Gold')]:
    box('Note',(x,-.095,1.60),(.60,.025,.73),key)
    box('Pin',(x,-.13,1.91),(.08,.035,.08),'Pin')
    for z in [1.40,1.33]: box('Writing',(x,-.117,z),(.35,.012,.018),'Ink')
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art'/'source'/'trade_board.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets'/'models'/'trade_board.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_cameras=False,export_lights=False)
print('TRADE_ASSET_OK trade_board')
