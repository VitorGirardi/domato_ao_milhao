"""Open-front rural workshop: timber shed, workbench and tool board."""
import bpy,runpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
api=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
for name,color in {'Paint':'698579','Roof':'4F6369','Wood':'9F7046','Cream':'F4DBAA','Metal':'9AA5A0','Gold':'DFAC42'}.items():
    api['M'][name]=api['material'](name,color)
box=api['box']; tube=api['tube']; ellipsoid=api['ellipsoid']
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
box('Plinth',(0,0,.07),(3.7,3.3,.14),'Wood',.025)
box('Rear wall',(0,1.47,1.24),(3.4,.12,2.4),'Paint',.025)
for x in [-1.65,1.65]:
    box('Side wall',(x,.1,.91),(.12,2.8,1.7),'Paint',.025)
    for y in [-1.4,1.4]: box('Post',(x,y,1.25),(.16,.16,2.5),'Wood',.025)
roof=box('Sheet roof',(0,0,2.55),(3.95,3.65,.13),'Roof',.03)
roof.rotation_euler.x=-.10
for x in [-1.55,-1,-.5,0,.5,1,1.55]:
    bar=box('Roof rib',(x,0,2.63),(.045,3.65,.035),'Metal',.012);bar.rotation_euler.x=-.10
box('Front beam',(0,-1.46,2.28),(3.5,.15,.18),'Wood',.02)
box('Workshop sign',(0,-1.56,2.27),(1.45,.08,.35),'Cream',.025)
# Crossed tools on the sign.
tube('Spanner', [(-.29,-1.615,2.16),(.19,-1.615,2.39)],.035,'Metal')
tube('Tool handle', [(.29,-1.62,2.15),(-.20,-1.62,2.39)],.033,'Wood')
box('Hammer head',(-.22,-1.62,2.40),(.22,.07,.08),'Metal',.015)
box('Workbench top',(0,.87,.98),(2.8,.78,.14),'Wood',.03)
for x in [-1.16,1.16]:
    for y in [.59,1.12]: box('Bench leg',(x,y,.48),(.1,.1,.85),'Wood',.015)
box('Toolboard',(0,1.34,1.72),(2.3,.08,.85),'Wood',.02)
for x in [-.8,-.32,.3,.8]:
    tube('Hanging tool',[(x,1.25,1.46),(x,1.25,1.92)],.025,'Metal')
    box('Tool grip',(x,1.25,1.51),(.07,.055,.2),'Gold',.018)
box('Toolbox',(.65,.72,1.18),(.65,.35,.25),'Paint',.025)
box('Toolbox handle',(.65,.72,1.37),(.27,.07,.07),'Metal',.012)
box('Crate',(-1.1,-.9,.31),(.6,.55,.5),'Wood',.02)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/workshop.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/workshop.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
print('WORKSHOP_OK')
