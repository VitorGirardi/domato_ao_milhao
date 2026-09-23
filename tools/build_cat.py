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
    'CatCollar': (.62,.025,.035), 'CatGold': (.85,.48,.075),
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
    p = pivot(name, (side*.125,-.015,.115), parent)
    verts = [(-.09,-.055,-.025),(.09,-.055,-.025),(side*.045,.002,.165),
             (-.07,.055,.012),(.07,.055,.012),(side*.042,.045,.155)]
    mesh = bpy.data.meshes.new(name+'Mesh')
    mesh.from_pydata(verts,[],[(0,1,2),(3,5,4),(0,3,4,1),(0,2,5,3),(1,4,5,2)])
    mesh.materials.append(M['CatCoat'])
    obj = bpy.data.objects.new(name+'Shape',mesh)
    bpy.context.collection.objects.link(obj);obj.parent=p
    bevel=obj.modifiers.new('Soft ear edge','BEVEL');bevel.width=.012;bevel.segments=3
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    for face in obj.data.polygons:face.use_smooth=True
    inner = bpy.data.meshes.new(name+'Inner')
    inner.from_pydata([(-.055,-.057,.027),(.055,-.057,.027),(side*.04,-.008,.132)],[],[(0,1,2)])
    inner.materials.append(M['CatEar'])
    obj = bpy.data.objects.new(name+'Inner',inner)
    bpy.context.collection.objects.link(obj);obj.parent=p

# Blender forward -Y becomes Godot +Z. Meter scale, paws rest at ground.
root = pivot('Cat', (0,0,0))
body = pivot('CatBody', (0,0,.40), root)
ellipsoid('Torso',(0,.05,0),(.195,.315,.195),'CatCoat',body)
ellipsoid('Chest',(0,-.20,.025),(.167,.17,.195),'CatCoat',body)
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
# Cream bib belongs to the surface instead of floating above it.
coat.data.materials.append(M['CatCream'])
for face in coat.data.polygons:
    center=face.center+coat.location
    if center.y<-.325 and abs(center.x)<.105 and center.z<.10:face.material_index=len(coat.data.materials)-1
head = pivot('CatHead',(0,-.275,.17),body)
ellipsoid('Head',(0,-.02,.04),(.233,.19,.205),'CatCoat',head)
ellipsoid('Chin',(0,-.168,-.053),(.085,.048,.040),'CatCream',head)
for side in [-1,1]:
    ellipsoid('Muzzle'+str(side),(side*.045,-.196,-.025),(.055,.035,.038),'CatCream',head)
    eye = pivot('CatEyeL' if side<0 else 'CatEyeR',(side*.095,-.194,.083),head)
    ellipsoid('EyeRim',(0,0,0),(.068,.011,.056),'CatStripe',eye)
    ellipsoid('Iris',(0,-.008,0),(.054,.009,.047),'CatEye',eye)
    ellipsoid('Pupil',(0,-.017,0),(.018,.008,.041),'CatPupil',eye)
    ellipsoid('Glint',(-.015,-.025,.016),(.011,.004,.012),'CatGlint',eye,12,8)
    lid=pivot('CatClosedEyeL' if side<0 else 'CatClosedEyeR',(side*.095,-.194,.083),head)
    tube('ClosedLid',[(-.052,-.025,0),(-.026,-.029,-.012),(0,-.031,-.016),(.026,-.029,-.012),(.052,-.025,0)],.0035,'CatStripe',lid)
    ear('CatEarL' if side<0 else 'CatEarR',side,head)
    for j in range(3):
        tube('Whisker',[(side*.071,-.230,-.027+j*.014),(side*.155,-.237,-.037+j*.024),(side*.25,-.225,-.065+j*.04)],.0022,'CatCream',head)
ellipsoid('Nose',(0,-.239,.009),(.025,.014,.018),'CatNose',head,12,8)
tube('Mouth',[(0,-.234,-.010),(0,-.237,-.044),(-.025,-.229,-.055)],.003,'CatStripe',head)
tube('Mouth',[(0,-.237,-.044),(.025,-.229,-.055)],.003,'CatStripe',head)

for name, x, y in [('FL',-.118,-.21),('FR',.118,-.21),('BL',-.115,.22),('BR',.115,.22)]:
    leg = pivot('CatLeg'+name,(x,y,-.045),body)
    back = name[0]=='B'
    ellipsoid('Haunch' if back else 'Shoulder',(0,0,-.055),(.090,.115,.150) if back else (.063,.075,.135),'CatCoat',leg)
    shin = pivot('CatShin'+name,(0,.025 if back else 0,-.145),leg)
    ellipsoid('Shin',(0,-.006,-.065),(.057,.065,.110),'CatCoat',shin)
    ellipsoid('Paw',(0,-.025,-.155),(.068,.097,.047),'CatCream',shin)
    for dx in [-.019,.019]:
        tube('Toe',[(dx,-.115,-.148),(dx,-.113,-.169)],.002,'CatStripe',shin)

# Red collar follows the neck/body, with a small rounded brass tag.
bpy.ops.mesh.primitive_torus_add(major_radius=.168,minor_radius=.016,major_segments=48,minor_segments=12)
collar=bpy.context.object;collar.name='RedCollar';collar.parent=body;collar.location=(0,-.245,-.012)
collar.scale=(1,.87,1.4);collar.data.materials.append(M['CatCollar'])
for face in collar.data.polygons:face.use_smooth=True
ellipsoid('CollarTag',(0,-.402,-.051),(.024,.010,.028),'CatGold',body)

# One continuous skinned tail, so bends never expose bead-like joints.
tail = pivot('CatTail0',(0,.285,.055),body)
arm = bpy.data.armatures.new('CatTailRig')
rig = bpy.data.objects.new('CatTailRig',arm)
bpy.context.collection.objects.link(rig);rig.parent=tail
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
centers=[Vector((0, .066*i-.040*max(0,i-4)**2, .061*i-.013*max(0,i-5)**2)) for i in range(8)]
for i in range(7):
    bone=arm.edit_bones.new('TailBone%d'%i)
    bone.head=centers[i];bone.tail=centers[i+1]
    if i:bone.parent=arm.edit_bones['TailBone%d'%(i-1)];bone.use_connect=True
bpy.ops.object.mode_set(mode='OBJECT')
verts=[];faces=[];weights=[]
for r in range(29):
    t=r/4;seg=min(6,int(t));fraction=t-seg
    p0=centers[max(0,seg-1)];p1=centers[seg];p2=centers[seg+1];p3=centers[min(7,seg+2)]
    u=fraction
    center=.5*((2*p1)+(-p0+p2)*u+(2*p0-5*p1+4*p2-p3)*u*u+(-p0+3*p1-3*p2+p3)*u*u*u)
    direction=(centers[seg+1]-centers[seg]).normalized()
    across=Vector((1,0,0));other=direction.cross(across).normalized()
    radius=.048*(1-.72*(r/28)**1.7)
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
