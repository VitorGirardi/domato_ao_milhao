"""Chico's skinned character and carried dairy props, original Blender sources."""
import bpy,runpy,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
a=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
a['build']('cheesemaker',True)
a['M']=a['build'].__globals__['M']
for key,color in {'Tin':'A9BFC0','Cream':'FFF0CE','Cheese':'F1C35B','Wood':'A78254'}.items():a['M'][key]=a['material'](key,color)
def cylinder(name,at,radius,depth,material):
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=radius,depth=depth,location=at)
 obj=bpy.context.object;obj.name=name;obj.data.materials.append(a['M'][material]);return obj
def export(name):
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{name}.blend'))
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{name}.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
for name in ['milk_can','cheese_tray']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 if name=='milk_can':
  cylinder('MilkCan',(0,0,.23),.19,.44,'Tin');cylinder('Rim',(0,0,.47),.21,.05,'Tin');cylinder('Milk',(0,0,.487),.17,.008,'Cream')
  for side in [-1,1]:a['tube']('Handle',[(side*.17,0,.39),(side*.28,0,.34),(side*.28,0,.20),(side*.17,0,.18)],.025,'Tin')
 else:
  a['box']('Tray',(0,0,.04),(.66,.42,.08),'Wood',.035)
  for x in [-.17,.17]:cylinder('Cheese',(x,0,.15),.135,.18,'Cheese')
 export(name)
print('CHICO_ASSETS_OK')
