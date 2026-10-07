"""Original low-poly fungal colony, not a scientific depiction of glowworms."""
import bpy, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,emission=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.85
    p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
    return m
stem=mat('Pale cave stem',(.29,.43,.35));cap=mat('Fictional luminous fungus',(.16,.72,.49),.6)
for i,(x,y,h,r) in enumerate([(-.3,0,.62,.24),(.12,.1,.95,.34),(.44,-.12,.40,.20),(-.1,-.24,.31,.16)]):
    bpy.ops.mesh.primitive_cone_add(vertices=7,radius1=.06,radius2=.035,depth=h,location=(x,y,h/2))
    bpy.context.object.name='Fungus stem';bpy.context.object.data.materials.append(stem)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10,ring_count=5,radius=1,location=(x,y,h))
    bpy.context.object.name='Luminous cap';bpy.context.object.scale=(r,r,r*.4);bpy.context.object.data.materials.append(cap)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/cave_detail_fungi.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/cave_detail_fungi.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False)
