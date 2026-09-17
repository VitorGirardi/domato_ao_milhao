"""Zeca: a distinct version of our original articulated Blender farmer."""
import bpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/farmer.blend'))
for name, value in {'Denim':'6e8052','Cream':'dc9256','Hat':'719f91','Wood':'315950','Skin':'c68d63'}.items():
    mat = bpy.data.materials.get(name)
    if mat:
        rgba = tuple(int(value[i:i+2],16)/255 for i in (0,2,4))+(1,)
        mat.diffuse_color = rgba
        for node in mat.node_tree.nodes:
            if node.type == 'BSDF_PRINCIPLED': node.inputs['Base Color'].default_value = rgba
# A broad moustache, authored into the head mesh, distinguishes the caretaker.
head=bpy.data.objects['Head']
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(0,-.272,1.57))
moustache=bpy.context.object
moustache.scale=(.13,.045,.045)
moustache.data.materials.append(bpy.data.materials['Boot'])
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
bpy.ops.object.select_all(action='DESELECT')
head.select_set(True)
moustache.select_set(True)
bpy.context.view_layer.objects.active=head
bpy.ops.object.join()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/helper.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/helper.glb'),export_format='GLB',
    use_selection=True,export_apply=True,export_cameras=False,export_lights=False,export_yup=True)
print('STAFF_ASSET_OK helper')
