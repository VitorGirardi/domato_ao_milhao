"""Original stylized, fictional game props. Only exports new armory assets."""
import bpy, math, runpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
a=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
palette={'Steel':'596970','Edge':'86969A','Dark':'252F32','Grip':'76513A',
         'Brass':'C9A765','Wood':'886447','LightWood':'B99361','Cloth':'344E47',
         'Paper':'E6DCC0','Red':'B7513C'}
a['mesh'].__globals__['M']={k:a['material']('armory_'+k,v) for k,v in palette.items()}
box=a['box'];tube=a['tube'];ell=a['ellipsoid']
def reset():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def export(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{name}.glb'),export_format='GLB',use_selection=True,export_apply=True,export_cameras=False,export_lights=False)
reset()
# Fictional P-8: generous silhouette, beveled frame, warm grip inlays.
box('P8 frame',(0,-.045,.13),(.072,.26,.061),'Dark',.012)
box('P8 slide',(0,-.06,.188),(.080,.33,.075),'Steel',.012)
box('Slide highlight',(0,-.06,.226),(.063,.285,.008),'Edge',.003)
grip=box('Grip',(0,.043,.049),(.069,.10,.155),'Dark',.014)
grip.rotation_euler.x=math.radians(-13)
for s in [-1,1]:
    p=box('Walnut grip inlay',(s*.034,.043,.04),(.011,.080,.119),'Grip',.010);p.rotation_euler.x=math.radians(-13)
    for z in [.005,.073]:ell('Grip stud',(s*.041,.043,z),(.004,.009,.009),'Brass',rings=8,segments=12)
    for y in [.019,.043,.067]:box('Slide detail',(s*.040,y,.188),(.004,.007,.041),'Dark',.002)
tube('Guard',[(0,.007,.129),(0,-.065,.103),(0,-.064,.052),(0,.007,.043)],.011,'Dark')
box('Front sight',(0,-.185,.235),(.016,.022,.018),'Dark',.003)
box('Rear sight',(0,.078,.236),(.044,.018,.016),'Dark',.003)
box('Muzzle inset',(0,-.226,.184),(.031,.003,.029),'Dark',.007)
export('pistol_p8')
reset()
box('Bench top',(0,0,1.04),(2.15,.80,.13),'LightWood',.045)
for x in [-.85,.85]:
    for y in [-.25,.25]:box('Bench leg',(x,y,.48),(.12,.12,.96),'Wood',.015)
box('Lower shelf',(0,0,.26),(1.91,.67,.07),'Wood',.012)
box('Working mat',(0,-.03,1.112),(1.4,.59,.014),'Cloth',.025)
box('Storage case',(.58,.09,1.22),(.55,.38,.21),'Dark',.035)
box('Case latch',(.58,-.11,1.22),(.10,.025,.06),'Brass',.006)
for x in [-.52,-.24]:box('Ammunition carton',(x,.11,1.17),(.20,.23,.12),'Paper',.015)
export('gunsmith_bench')
reset()
for x in [-.28,.28]:box('Target support',(x,.05,.71),(.07,.10,1.42),'Wood',.008)
box('Target board',(0,0,1.56),(1.0,.08,1.0),'LightWood',.025)
for radius,col,depth in [(.43,'Paper',-.047),(.31,'Red',-.051),(.21,'Paper',-.055),(.105,'Red',-.059)]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=radius,depth=.006,location=(0,depth,1.56),rotation=(math.pi/2,0,0))
    o=bpy.context.object;o.name='Target ring';o.data.materials.append(a['mesh'].__globals__['M'][col])
for x in [-.28,.28]:box('Foot',(x,0,.045),(.13,.60,.09),'Wood',.012)
export('practice_target')
print('PISTOL_PROPS_OK')
