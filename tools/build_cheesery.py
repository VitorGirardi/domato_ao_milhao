"""Original small rural cheesery, editable Blender source and game GLB."""
import bpy,runpy,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
a=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
for k,c in {'Wall':'E6D4A4','Roof':'AB6347','Wood':'99724D','Trim':'F5EACD','Door':'567F70','Glass':'9CC5C1','Cheese':'F2C556','Hole':'BE8935'}.items():a['M'][k]=a['material'](k,c)
b=a['box']
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
b('Foundation',(0,0,.12),(5.45,5.1,.24),'Wood',.05)
b('Walls',(0,0,1.45),(5.1,4.7,2.6),'Wall',.06)
for side in [-1,1]:
 r=b('Roof',(side*1.3,0,3.03),(2.93,5.15,.20),'Roof',.04);r.rotation_euler.y=side*.30
for x in [-2.45,2.45]:b('CornerTrim',(x,-2.40,1.47),(.16,.16,2.64),'Trim',.01)
b('Door',(0,-2.43,1.02),(1.22,.15,1.84),'Door',.025)
for x in [-.67,.67]:b('DoorFrame',(x,-2.52,1.02),(.10,.12,1.95),'Trim',.01)
b('DoorFrame',(0,-2.52,2.0),(1.45,.12,.10),'Trim',.01)
b('Handle',(.40,-2.56,1.0),(.08,.10,.23),'Wood',.02)
for x in [-1.65,1.65]:
 b('Window',(x,-2.43,1.47),(1.03,.14,.95),'Glass',.03)
 for dx in [-.54,0,.54]:b('WindowFrame',(x+dx,-2.53,1.47),(.07,.09,1.08),'Trim',.01)
 for z in [1.0,1.47,1.96]:b('WindowFrame',(x,-2.53,z),(1.15,.09,.07),'Trim',.01)
b('Sign',(0,-2.49,2.45),(2.78,.16,.54),'Door',.03)
bpy.ops.object.text_add(location=(-1.17,-2.59,2.29),rotation=(math.pi/2,0,0))
label=bpy.context.object;label.name='QueijariaSign';label.data.body='QUEIJARIA';label.data.size=.34;label.data.extrude=.005;label.data.materials.append(a['M']['Trim'])
bpy.ops.object.convert(target='MESH')
b('Bench',(-1.6,-2.64,.55),(1.1,.45,.12),'Wood',.03)
for x in [-2.02,-1.18]:b('BenchLeg',(x,-2.64,.29),(.12,.30,.5),'Wood',.02)
for x in [-1.8,-1.38]:
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.18,depth=.17,location=(x,-2.64,.70))
 wheel=bpy.context.object;wheel.name='CheeseWheel';wheel.data.materials.append(a['M']['Cheese'])
b('Chimney',(1.6,1.5,3.4),(.48,.52,1.1),'Wood',.025)
b('ChimneyCap',(1.6,1.5,3.98),(.67,.70,.15),'Trim',.02)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/cheesery.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/cheesery.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('CHEESERY_ASSET_OK')
