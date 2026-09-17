"""Level-two additions; share each building's origin and existing footprint."""
import bpy, runpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
api=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
for name,color in {'Paint':'698579','Roof':'4F6369','Wood':'A97243','Cream':'FFEAC1','Metal':'94A9A5','Gold':'E8B94D','Dark':'3E4848'}.items():
    api['M'][name]=api['material'](name,color)
box=api['box'];tube=api['tube']
def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def export(kind):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{kind}_level2.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{kind}_level2.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
    print('PROGRESSION_ASSET_OK',kind)
def badge(y,z):
    box('Level plaque',(0,y,z),(.75,.08,.42),'Gold',.05)
    for x in [-.10,.10]: box('Level II',(x,y-.06,z),(.06,.04,.25),'Cream',.01)
clear()
for x in [-2,2]:
    for z in [.28,.84]:
        box('Storage crate',(x,-2.53,z),(.82,.65,.5),'Wood',.025)
        for offset in [-.31,.31]:box('Crate strap',(x+offset,-2.87,z),(.06,.04,.48),'Cream',.01)
box('Storage awning',(0,-2.60,2.62),(3.1,.68,.12),'Roof',.025)
for x in [-1.48,1.48]:box('Awning support',(x,-2.69,2.25),(.10,.12,.7),'Cream',.02)
badge(-2.73,2.72)
export('barn')
clear()
for y in [-.65,.45]:
    box('Extra nest',(-1.53,y,1.10),(.64,.82,.63),'Wood',.03)
    box('Nest roof',(-1.53,y,1.46),(.78,.95,.10),'Roof',.02)
    box('Nest access',(-1.87,y,1.15),(.035,.45,.32),'Dark',.01)
box('Vent tower',(0,.25,2.83),(.65,.65,.62),'Cream',.025)
box('Tower cap',(0,.25,3.18),(.86,.85,.12),'Roof',.03)
for x in [-.2,0,.2]:box('Vent slat',(x,-.09,2.86),(.09,.04,.35),'Dark',.01)
badge(-1.42,2.02)
export('coop')
clear()
box('Tool cabinet',(-1.22,.48,.90),(.57,.93,1.72),'Paint',.03)
for z in [.38,.88,1.38]:
    box('Cabinet drawer',(-1.22,-.005,z),(.48,.06,.42),'Metal',.025)
    box('Drawer grip',(-1.22,-.05,z),(.2,.06,.055),'Gold',.012)
box('Lathe base',(.30,.83,1.14),(1.12,.46,.22),'Metal',.025)
for x in [-.13,.72]:box('Lathe mount',(x,.83,1.40),(.18,.34,.42),'Paint',.025)
tube('Lathe spindle',[(-.02,.83,1.43),(.6,.83,1.43)],.095,'Gold')
box('Upper fascia',(0,-1.57,2.52),(3.5,.14,.25),'Cream',.025)
badge(-1.67,2.55)
export('workshop')
