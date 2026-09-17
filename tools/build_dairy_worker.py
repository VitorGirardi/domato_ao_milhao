"""Raul do Curral: original skinned Blender character."""
import runpy
from pathlib import Path
r=Path(__file__).resolve().parents[1]
a=runpy.run_path(str(r/'tools/build_cartoon_characters.py'))
a['build']('dairyman',True)
import bpy
a['M']=a['build'].__globals__['M']
a['M']['Sack']=a['material']('Sack','BFA16A')
a['M']['Tie']=a['material']('Tie','72513B')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
a['ellipsoid']('FeedSack',(0,0,.25),(.24,.18,.30),'Sack',.8)
a['tube']('Tie',[(-.13,0,.48),(0,0,.51),(.13,0,.48)],.022,'Tie')
a['box']('Patch',(0,-.177,.28),(.19,.018,.17),'Tie',.02)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(r/'art/source/feed_sack.blend'))
bpy.ops.export_scene.gltf(filepath=str(r/'assets/models/feed_sack.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('RAUL_ASSET_OK')
