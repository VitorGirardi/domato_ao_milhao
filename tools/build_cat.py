"""Original farm companion; articulated, smooth stylized feline. Blender 5.x."""
import bpy
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = .76
    return m

M = {k: material(k, c) for k, c in {
    'CatCoat': (.48,.26,.105), 'CatCream': (.88,.79,.62),
    'CatStripe': (.20,.095,.036), 'CatNose': (.48,.20,.19),
    'CatEar': (.55,.31,.28), 'CatEye': (.38,.61,.23),
    'CatPupil': (.018,.025,.018), 'CatGlint': (1,.97,.88),
}.items()}

def pivot(name, pos, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.location = pos
    return obj

def ellipsoid(name, pos, scale, mat, parent=None, segments=20, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1)
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.location = pos
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(M[mat])
    for f in obj.data.polygons: f.use_smooth = True
    return obj

def tube(name, points, radius, mat, parent):
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions = '3D'
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    s = curve.splines.new('POLY')
    s.points.add(len(points)-1)
    for p, co in zip(s.points, points): p.co = (*co,1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    curve.materials.append(M[mat])
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    obj.select_set(False)
    return obj

def ear(name, side, parent):
    p = pivot(name, (side*.145,0,.16), parent)
    verts = [(-.09,-.055,0),(.09,-.055,0),(side*.045,.002,.185),
             (-.07,.055,.012),(.07,.055,.012),(side*.042,.045,.175)]
    mesh = bpy.data.meshes.new(name+'Mesh')
    mesh.from_pydata(verts,[],[(0,1,2),(3,5,4),(0,3,4,1),(0,2,5,3),(1,4,5,2)])
    mesh.materials.append(M['CatCoat'])
    obj = bpy.data.objects.new(name+'Shape',mesh)
    bpy.context.collection.objects.link(obj);obj.parent=p
    inner = bpy.data.meshes.new(name+'Inner')
    inner.from_pydata([(-.055,-.057,.027),(.055,-.057,.027),(side*.04,-.008,.151)],[],[(0,1,2)])
    inner.materials.append(M['CatEar'])
    obj = bpy.data.objects.new(name+'Inner',inner)
    bpy.context.collection.objects.link(obj);obj.parent=p

# Blender forward -Y becomes Godot +Z. Meter scale, paws rest at ground.
root = pivot('Cat', (0,0,0))
body = pivot('CatBody', (0,0,.47), root)
ellipsoid('Torso',(0,.05,0),(.205,.37,.215),'CatCoat',body)
ellipsoid('Chest',(0,-.225,.015),(.175,.18,.215),'CatCoat',body)
# Weld torso and chest into one soft silhouette.
bpy.ops.object.select_all(action='DESELECT')
for part in ['Torso','Chest']:bpy.data.objects[part].select_set(True)
bpy.context.view_layer.objects.active=bpy.data.objects['Torso']
bpy.ops.object.join()
coat=bpy.context.object;coat.name='CatTorso'
remesh=coat.modifiers.new('Continuous coat','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.012
bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth=coat.modifiers.new('Soft coat','SMOOTH');smooth.factor=.7;smooth.iterations=3
bpy.ops.object.modifier_apply(modifier=smooth.name)
for face in coat.data.polygons:face.use_smooth=True
ellipsoid('Bib',(0,-.335,-.022),(.122,.052,.158),'CatCream',body)
head = pivot('CatHead',(0,-.31,.19),body)
ellipsoid('Head',(0,-.02,.04),(.222,.185,.19),'CatCoat',head)
ellipsoid('Chin',(0,-.168,-.053),(.105,.07,.055),'CatCream',head)
for side in [-1,1]:
    ellipsoid('Muzzle'+str(side),(side*.057,-.191,-.018),(.073,.052,.054),'CatCream',head)
    eye = pivot('CatEyeL' if side<0 else 'CatEyeR',(side*.105,-.171,.076),head)
    ellipsoid('EyeRim',(0,0,0),(.063,.012,.049),'CatStripe',eye)
    ellipsoid('Iris',(0,-.008,0),(.050,.009,.038),'CatEye',eye)
    ellipsoid('Pupil',(0,-.017,0),(.015,.008,.038),'CatPupil',eye)
    ellipsoid('Glint',(-.015,-.025,.016),(.011,.004,.012),'CatGlint',eye,12,8)
    ear('CatEarL' if side<0 else 'CatEarR',side,head)
    for j in range(3):
        tube('Whisker',[(side*.071,-.230,-.027+j*.014),(side*.155,-.237,-.037+j*.024),(side*.25,-.225,-.065+j*.04)],.0022,'CatCream',head)
    for j in range(2):
        tube('CheekMark',[(side*.15,-.153,-.025+j*.032),(side*.20,-.10,-.02+j*.04)],.008,'CatStripe',head)
ellipsoid('Nose',(0,-.239,.009),(.034,.018,.025),'CatNose',head,12,8)
tube('Mouth',[(0,-.234,-.010),(0,-.237,-.044),(-.025,-.229,-.055)],.003,'CatStripe',head)
tube('Mouth',[(0,-.237,-.044),(.025,-.229,-.055)],.003,'CatStripe',head)
for x in [-.05,0,.05]:
    tube('BrowStripe',[(x,-.151,.16),(x*.85,-.075,.214)],.009,'CatStripe',head)

for name, x, y in [('FL',-.135,-.23),('FR',.135,-.23),('BL',-.15,.27),('BR',.15,.27)]:
    leg = pivot('CatLeg'+name,(x,y,-.055),body)
    back = name[0]=='B'
    ellipsoid('Haunch' if back else 'Shoulder',(0,0,-.055),(.108,.132,.172) if back else (.068,.078,.15),'CatCoat',leg)
    shin = pivot('CatShin'+name,(0,.025 if back else 0,-.19),leg)
    ellipsoid('Shin',(0,-.006,-.082),(.054,.062,.129),'CatCoat',shin)
    ellipsoid('Paw',(0,-.029,-.176),(.068,.097,.047),'CatCream',shin)
    for dx in [-.019,.019]:
        tube('Toe',[(dx,-.115,-.167),(dx,-.113,-.188)],.002,'CatStripe',shin)

# One continuous skinned tail, so bends never expose bead-like joints.
tail = pivot('CatTail0',(0,.345,.065),body)
arm = bpy.data.armatures.new('CatTailRig')
rig = bpy.data.objects.new('CatTailRig',arm)
bpy.context.collection.objects.link(rig);rig.parent=tail
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
centers=[Vector((0, .09*i-.012*max(0,i-4)**2, .08*i)) for i in range(8)]
for i in range(7):
    bone=arm.edit_bones.new('TailBone%d'%i)
    bone.head=centers[i];bone.tail=centers[i+1]
    if i:bone.parent=arm.edit_bones['TailBone%d'%(i-1)];bone.use_connect=True
bpy.ops.object.mode_set(mode='OBJECT')
verts=[];faces=[];weights=[]
for r in range(29):
    t=r/4;seg=min(6,int(t));fraction=t-seg
    center=centers[seg].lerp(centers[seg+1],fraction)
    direction=(centers[seg+1]-centers[seg]).normalized()
    across=Vector((1,0,0));other=direction.cross(across).normalized()
    radius=.044*(1-.72*(r/28)**1.7)
    if r==28:radius=.002
    for j in range(12):
        angle=j*math.tau/12
        verts.append(center+radius*(math.cos(angle)*across+math.sin(angle)*other))
        weights.append((seg,fraction))
        if r<28:faces.append((r*12+j,r*12+(j+1)%12,(r+1)*12+(j+1)%12,(r+1)*12+j))
mesh=bpy.data.meshes.new('ContinuousTail');mesh.from_pydata(verts,[],faces)
mesh.materials.append(M['CatCoat']);mesh.materials.append(M['CatStripe']);mesh.materials.append(M['CatCream'])
obj=bpy.data.objects.new('ContinuousTail',mesh);bpy.context.collection.objects.link(obj);obj.parent=tail
for poly in mesh.polygons:
    poly.use_smooth=True
    ring=poly.index//12
    poly.material_index=2 if ring>25 else (1 if ring in [8,9,16,17,23] else 0)
for i in range(7):obj.vertex_groups.new(name='TailBone%d'%i)
for index,(seg,fraction) in enumerate(weights):
    # Blend across each joint, keeping the base planted in the rump.
    nxt=min(6,seg+1)
    obj.vertex_groups[seg].add([index],1-fraction if nxt!=seg else 1,'REPLACE')
    if nxt!=seg:obj.vertex_groups[nxt].add([index],fraction,'REPLACE')
modifier=obj.modifiers.new('Tail deformation','ARMATURE');modifier.object=rig

bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/cat.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/cat.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_cameras=False,export_lights=False)
print('CAT_ASSET_OK')
