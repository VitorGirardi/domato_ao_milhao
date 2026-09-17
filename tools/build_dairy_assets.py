"""Original stylized dairy cow and small corral; Blender sources and GLBs."""
import bpy,runpy
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1]
a=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
for k,c in {'Ivory':'F3E6C8','Patch':'393D3B','Pink':'D89C8C','Hoof':'565A50','Wood':'A77C4E','Roof':'618A7B','Hay':'DAC16C','Water':'72BCC5','Metal':'9DAFA8','Black':'202D29'}.items():a['M'][k]=a['material'](k,c)
e=a['ellipsoid'];b=a['box'];t=a['tube']
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def export(key):
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{key}.blend'))
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{key}.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
 print('DAIRY_ASSET_OK',key)
def pivot(name,at,objects):
 p=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(p);p.matrix_world=Matrix.Translation(Vector(at))
 for o in objects:
  mat=o.matrix_world.copy();o.parent=p;o.matrix_parent_inverse=Matrix.Identity(4);o.matrix_basis=p.matrix_world.inverted() @ mat
 return p
clear()
e('CowBody',(0,.05,1.36),(.60,1.03,.64),'Ivory',.8)
for x,y,z,sz in [(.48,.24,1.59,(.16,.48,.36)),(-.48,-.10,1.45,(.16,.43,.42)),(.28,.75,1.73,(.28,.28,.20))]:e('BlackPatch',(x,y,z),sz,'Patch',.8)
e('Shoulder',(0,-.59,1.53),(.43,.45,.56),'Ivory',.85)
for side,x in [('L',-.38),('R',.38)]:
 for end,y in [('F',-.66),('B',.72)]:
  parts=[e('Leg',(x,y,.69),(.17,.19,.57),'Ivory',.7),b('Hoof',(x,y-.03,.16),(.32,.36,.24),'Hoof',.075)]
  pivot('Leg'+end+side,(x,y,1.13),parts)
e('Udder',(0,.61,.79),(.32,.37,.22),'Pink')
for x in [-.14,.14]:
 for y in [.45,.69]:e('Teat',(x,y,.60),(.047,.047,.12),'Pink')
head=[]
head.append(e('Head',(0,-1.04,1.67),(.37,.47,.43),'Ivory',.85))
head.append(e('Muzzle',(0,-1.40,1.44),(.40,.30,.24),'Pink',.8))
for x in [-.19,.19]:head.append(e('Nostril',(x,-1.66,1.48),(.065,.021,.039),'Patch'))
for side in [-1,1]:
 head.append(e('Ear',(side*.49,-.91,1.94),(.26,.13,.10),'Ivory'))
 head.append(e('InnerEar',(side*.49,-.99,1.96),(.16,.055,.057),'Pink'))
 head.append(e('EyeWhite',(side*.30,-1.28,1.80),(.086,.07,.104),'Ivory'))
 head.append(e('Eye',(side*.32,-1.33,1.80),(.05,.044,.065),'Black'))
 head.append(e('EyeGlint',(side*.32-.013,-1.363,1.824),(.013,.012,.018),'Ivory'))
 head.append(t('Horn',[(side*.22,-.9,1.99),(side*.24,-.86,2.17),(side*.17,-.85,2.28)],.07,'Hay',radii=[1,.65,.1]))
head.append(e('ForeheadPatch',(0,-1.22,1.98),(.19,.12,.12),'Patch',.8))
neck_head=pivot('CowHead',(0,-.70,1.65),head)
pivot('CowNeck',(0,-.30,1.50),[bpy.data.objects['Shoulder'],neck_head])
tail=t('TailStem',[(0,.95,1.60),(.06,1.18,1.12),(.15,1.18,.73)],.045,'Ivory')
tip=e('TailTuft',(.15,1.18,.70),(.095,.085,.18),'Patch')
pivot('CowTail',(0,.94,1.60),[tail,tip])
export('cow')
clear()
for x in [-3.7,3.7]:
 for y in [-2.7,0,2.7]:b('FencePost',(x,y,.57),(.16,.16,1.14),'Wood')
 for z in [.40,.87]:b('SideRail',(x,0,z),(.10,5.5,.10),'Wood')
for z in [.40,.87]:
 b('RearRail',(0,2.7,z),(7.5,.10,.10),'Wood')
 for side in [-1,1]:b('FrontRail',(side*2.55,-2.7,z),(2.30,.10,.10),'Wood')
for x in [-1.35,1.35]:b('GatePost',(x,-2.7,.57),(.17,.17,1.14),'Wood')
b('Gate',(0,-2.70,.65),(2.60,.12,.82),'Wood',.015)
for x in [-3.3,-.7]:
 for y in [1.8,2.4]:b('ShelterPost',(x,y,1.25),(.18,.18,2.5),'Wood')
roof=b('Roof',(-2,2.1,2.53),(3.0,1.25,.15),'Roof');roof.rotation_euler.x=.07
b('HayBale',(-2.7,2.15,.42),(1.10,.83,.78),'Hay',.12)
b('FeedTrough',(2.65,2.25,.32),(1.7,.65,.54),'Wood',.07)
b('Feed',(2.65,2.25,.60),(1.5,.50,.06),'Hay',.02)
b('WaterTrough',(3.0,-1.45,.34),(1.35,.73,.56),'Metal',.09)
b('Water',(3.0,-1.45,.63),(1.16,.54,.03),'Water',.025)
b('GatePlaque',(0,-2.81,.87),(.67,.05,.33),'Ivory')
pivot('GateHinge',(-1.35,-2.70,.0),[bpy.data.objects['Gate'],bpy.data.objects['GatePlaque']])
export('corral')
