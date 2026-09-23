"""A cohesive cartoon hen, authored in Blender; feet have explicit gait pivots."""
import bpy
import math
import runpy
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
api=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
palette=api['M']
for name,color in {'White':'fff0d1','Cream':'e4ce9f','EyeWhite':'ffffff',
                   'Eye':'28272c','Gold':'eaa32d','Red':'d94135','Mouth':'964726'}.items():
    palette[name]=api['material'](name,color)
ellipsoid=api['ellipsoid']; tube=api['tube']; group=api['group']; mesh=api['mesh']
def tilt(obj,center,angle):
    # Ellipsoid helper stores world-space vertices, so rotate about its center.
    from mathutils import Matrix, Vector
    rotation=Matrix.Rotation(angle,3,'X')
    for vertex in obj.data.vertices: vertex.co=Vector(center)+rotation@(vertex.co-Vector(center))
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
core=[ellipsoid('Breast',(0,-.015,.47),(.285,.38,.30),'White'),
      ellipsoid('Neck',(0,-.235,.68),(.185,.19,.26),'White'),
      ellipsoid('Head',(0,-.285,.83),(.205,.195,.19),'White')]
for side in [-1,1]:
    core.append(ellipsoid('Wing root',(side*.225,.04,.49),(.10,.245,.16),'White'))
body=group('HenBody',core,(0,0,0))
remesh=body.modifiers.new('Continuous breast neck and wings','REMESH')
remesh.mode='VOXEL'; remesh.voxel_size=.014
bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth=body.modifiers.new('Soft feather transitions','SMOOTH'); smooth.factor=1.1; smooth.iterations=4
bpy.ops.object.modifier_apply(modifier=smooth.name)
reduce=body.modifiers.new('Game surface','DECIMATE'); reduce.ratio=.45
bpy.ops.object.modifier_apply(modifier=reduce.name)
for face in body.data.polygons: face.use_smooth=True
details=[body]
# Shallow overlapping feather tips grow from the wing's continuous root.
for side in [-1,1]:
    for j in range(3):
        feather=ellipsoid('Wing feather',(side*(.278-j*.009),.035+j*.075,.46-j*.015),(.055,.15,.064),'Cream')
        tilt(feather,(side*(.278-j*.009),.035+j*.075,.46-j*.015),-.18)
        details.append(feather)
    details.append(ellipsoid('Eye white',(side*.152,-.415,.874),(.078,.051,.090),'EyeWhite'))
    details.append(ellipsoid('Pupil',(side*.157,-.456,.877),(.039,.024,.054),'Eye'))
    details.append(ellipsoid('Eye sparkle',(side*.150,-.477,.900),(.013,.008,.018),'EyeWhite',rings=8,segments=12))
# A broad tapered beak with a separate lower lip and a smile seam.
details.append(mesh('Upper beak',[(-.095,-.437,.80),(.095,-.437,.80),(0,-.60,.762),(0,-.465,.86)],[(0,2,1),(0,3,2),(1,2,3),(0,1,3)],'Gold'))
details.append(mesh('Lower beak',[(-.075,-.436,.777),(.075,-.436,.777),(0,-.568,.744),(0,-.453,.727)],[(0,1,2),(0,2,3),(1,3,2),(0,3,1)],'Gold'))
for x in [-.041,.041]: details.append(ellipsoid('Wattle',(x,-.419,.690),(.040,.040,.074),'Red'))
comb=[]
for y,z,r in [(-.40,1.008,.075),(-.285,1.055,.085),(-.165,1.019,.069)]:
    comb.append(ellipsoid('Comb lobe',(0,y,z),(.043,r,r),'Red'))
details.extend(comb)
for i in range(5):
    x=(i-2)*.052
    feather=ellipsoid('Tail feather',(x,.34+abs(i-2)*.016,.67-abs(i-2)*.025),(.056,.20,.18),'Cream')
    tilt(feather,(x,.34+abs(i-2)*.016,.67-abs(i-2)*.025),-.65)
    details.append(feather)
body=group('HenBody',details,(0,0,0))
# Deform the continuous neck together with every facial detail. Feet and tail
# stay planted: the hen reaches the soil without pitching its entire body.
from mathutils import Vector, Matrix
body.shape_key_add(name='Basis')
peck=body.shape_key_add(name='Peck')
anchor=Vector((0,-.10,.42))
for vertex in peck.data:
    co=vertex.co.copy()
    height=max(0,min(1,(co.z-.43)/.29))
    forward=max(0,min(1,(.12-co.y)/.25))
    weight=height*height*(3-2*height)*forward*forward*(3-2*forward)
    vertex.co=anchor+Matrix.Rotation(1.28*weight,3,'X')@(co-anchor)
for side,suffix in [(-1,'L'),(1,'R')]:
    x=side*.115
    leg=[tube('Shank',[(x,.015,.29),(x,.005,.15),(x,-.01,.052)],.027,'Gold')]
    for spread in [-1,0,1]:
        leg.append(tube('Toe',[(x,-.01,.052),(x+spread*.035,-.082,.028),(x+spread*.069,-.15+abs(spread)*.03,.025)],.017,'Gold',radii=[1,.85,.28]))
    leg.append(tube('Back toe',[(x,0,.045),(x,.072,.027)],.014,'Gold',radii=[1,.3]))
    group('Leg'+suffix,leg,(x,.015,.26))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/chicken.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/chicken.glb'),export_format='GLB',use_selection=True,
    export_apply=True,export_cameras=False,export_lights=False,export_yup=True)
print('CHICKEN_OK: connected breast/neck/wing roots, feather layers, expressive eyes, gait pivots')
