"""Original cozy farmhouse stages. Blender 5.2 --background --python this_file.

Meters; Z-up Blender exports Y-up Godot. Front Blender -Y = Godot +Z.
Both front doors at (0, -2.4), both root pivots/ground at zero. Exterior only.
No runtime hooks, collisions or save changes. --render adds QA contact sheet.
"""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT, SRC, QA = ROOT/'assets/models', ROOT/'art/source', ROOT/'test-results/houses-models'
for p in (OUT, SRC, QA): p.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
assets = {}
current = None

def material(name, color):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if p is None:
        p = m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
        output = m.node_tree.nodes.new('ShaderNodeOutputMaterial')
        m.node_tree.links.new(p.outputs['BSDF'], output.inputs['Surface'])
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = .86
    return m

wood = material('Honey weathered wood', (.43,.245,.105))
wood2 = material('Warm plank variation', (.56,.34,.16))
trim = material('Cut oak trim', (.25,.125,.057))
cream = material('Limewashed warm plaster', (.86,.77,.54))
stone = material('Foundation warm stone', (.37,.39,.34))
stone2 = material('Foundation light stone', (.49,.50,.43))
roof = material('Terracotta roof', (.57,.175,.075))
roof2 = material('Sunlit terracotta tile', (.70,.265,.105))
oldroof = material('Old clay roof', (.38,.19,.11))
teal = material('Painted sage teal', (.12,.36,.30))
glass = material('Deep blue window glass', (.075,.18,.21))
iron = material('Dark iron fittings', (.105,.12,.105))
leaf = material('Garden green', (.19,.37,.08))
flower = material('Golden flowers', (.99,.60,.08))
flower2 = material('Coral flowers', (.82,.20,.12))

def begin(name):
    global current
    current = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(current)
    assets[name] = current

def finish(obj, name, mat):
    obj.name = name
    for c in list(obj.users_collection): c.objects.unlink(obj)
    current.objects.link(obj)
    obj.data.materials.append(mat)
    return obj

def box(name, loc, size, mat, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    finish(obj,name,mat)
    if bevel:
        mod=obj.modifiers.new('Soft handmade corners','BEVEL'); mod.width=bevel; mod.segments=1
        bpy.context.view_layer.objects.active=obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def beam(name,a,b,width,mat):
    a,b=Vector(a),Vector(b)
    o=box(name,(a+b)/2,(width,width,(b-a).length),mat)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return o

def prism(name, width, front, back, eaves, peak, mat):
    # Closed triangular extrusion; gables remain solid from every view.
    verts=[(-width/2,front,eaves),(width/2,front,eaves),(0,front,peak),
           (-width/2,back,eaves),(width/2,back,eaves),(0,back,peak)]
    faces=[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)]
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new(name,mesh); current.objects.link(obj); obj.data.materials.append(mat)
    return obj

def window(x,y,z,side=False,upgraded=False):
    # Build in local front plane, rotate as a group for side wall.
    before=set(current.objects)
    box('Inset blue window',(0,-.03,0),(1.03,.11,1.04),glass)
    for xx in (-.55,.55): box('Window casing',(xx,-.13,0),(.10,.15,1.24),cream if upgraded else wood2)
    for zz in (-.57,0,.57): box('Window crossbar',(0,-.14,zz),(1.14,.16,.075),cream if upgraded else wood2)
    box('Window mullion',(0,-.145,0),(.07,.17,1.15),cream if upgraded else wood2)
    box('Projecting sill',(0,-.20,-.64),(1.35,.35,.12),trim)
    if upgraded:
        for xx in (-.88,.88):
            box('Teal shutter',(xx,-.08,0),(.48,.12,1.16),teal)
            for zz in (-.39,-.13,.13,.39): box('Shutter slat',(xx,-.16,zz),(.42,.05,.045),wood2)
    for o in set(current.objects)-before:
        if side:
            old=o.location.copy(); o.location=(x-old.y,y+old.x,z+old.z); o.rotation_euler.z=math.pi/2
        else: o.location+=Vector((x,y,z))

def flowers(x,y,z):
    box('Window flower box',(x,y,z),(1.38,.43,.32),teal,.025)
    box('Flower box soil',(x,y,z+.17),(1.22,.33,.04),trim)
    for i in range(5):
        xx=x-.48+i*.24
        beam('Flower stem',(xx,y,z+.2),(xx,y,z+.48),.035,leaf)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.15,location=(xx,y,z+.48))
        finish(bpy.context.object,'Garden blossom',flower if i%2 else flower2)
        box('Garden leaf',(xx+.04,y,z+.32),(.20,.13,.08),leaf)

def house(upgrade):
    begin('farm_house_upgrade' if upgrade else 'farm_house_starter')
    w=6.6 if upgrade else 5.2
    front=-2.4; back=3 if upgrade else 2.4
    eaves=3.45 if upgrade else 2.95
    peak=5.15 if upgrade else 4.45
    center=(front+back)/2
    box('Ground foundation',(0,center,.16),(w+.20,back-front+.20,.32),stone,.04)
    box('House closed walls',(0,center,(eaves+.32)/2),(w,back-front,eaves-.32),cream if upgrade else wood)
    # Solid gable and thin separate roof slopes.
    prism('Closed plaster gables' if upgrade else 'Closed timber gables',w,front,back,eaves,peak-.10,cream if upgrade else wood2)
    half=w/2+.32; ridge=peak+.14; low=eaves-.05
    slope=(ridge-low)/half; angle=math.atan(slope)
    for s in (-1,1):
        o=box('Solid clay roof slope',(s*half/2,center,(ridge+low)/2),(math.hypot(half,ridge-low),back-front+.75,.15),roof if upgrade else oldroof)
        o.rotation_euler.y=s*angle
        # Raised seams / individual patches communicate hand-laid clay without noise.
        for row in range(5):
            xx=(row+.5)*half/5
            for col in range(7):
                yy=front-.23+(col+.5)*(back-front+.46)/7
                o=box('Clay tile course',(s*xx,yy,ridge-slope*xx+.085),(half/5/math.cos(angle)-.025,(back-front+.46)/7-.035,.055),roof2 if upgrade and (row+col)%3==0 else (roof if upgrade else (roof if (row+col)%5==0 else oldroof)))
                o.rotation_euler.y=s*angle
    box('Roof ridge cap',(0,center,ridge+.10),(.25,back-front+.86,.18),roof2 if upgrade else trim,.035)
    for y in (front-.41,back+.41):
        for s in (-1,1): beam('Gable oak fascia',(0,y,ridge),(s*half,y,low),.15,cream if upgrade else trim)
    for x in (-w/2+.055,w/2-.055):
        for y in (front-.03,back+.03): box('Corner timber',(x,y,(eaves+.32)/2),(.15,.14,eaves-.32),trim)
    if not upgrade:
        for i in range(12):
            z=.43+i*.205
            for y in (front-.018,back+.018): box('Horizontal plank seam',(0,y,z),(w-.12,.04,.028),trim)
            for x in (-w/2-.018,w/2+.018): box('Side plank seam',(x,center,z),(.04,back-front,.028),trim)
    for i in range(int(w/.65)):
        x=-w/2+.32+i*.65
        for y in (front-.065,back+.065): box('Foundation face stone',(x,y,.18),(.58,.12,.23),stone2 if i%2 else stone,.018)
    box('Door dark frame',(0,front-.085,1.31),(1.24,.18,2.10),trim)
    box('Closed welcoming door',(0,front-.19,1.31),(1.03,.12,1.91),teal if upgrade else wood2)
    for x in (-.34,0,.34): box('Door planks',(x,front-.258,1.30),(.025,.028,1.82),trim)
    for z in (.67,1.83): box('Door crossbrace',(0,front-.28,z),(.97,.06,.11),trim)
    box('Door handle',(.33,front-.31,1.26),(.055,.08,.17),iron,.015)
    for x in (-1.7,1.7): window(x,front-.04,1.89,upgraded=upgrade)
    window(w/2+.015,.65,1.90,side=True,upgraded=upgrade)
    if upgrade:
        box('Porch stone deck',(0,-3.15,.24),(6.8,1.55,.32),stone2,.035)
        # Monopitch porch canopy, tucked into facade under the main eave.
        canopy=box('Solid porch terracotta canopy',(0,-3.2,2.92),(7.16,1.88,.14),roof)
        canopy.rotation_euler.x=math.radians(10)
        for x in (-3.13,3.13):
            box('Porch oak post',(x,-3.85,1.54),(.17,.17,2.28),wood2)
            for dx in (-.38,.38): beam('Porch diagonal bracket',(x,-3.85,2.20),(x+dx,-3.85,2.69),.11,trim)
        box('Porch front fascia',(0,-4.1,2.75),(7.17,.13,.20),cream)
        for x in (-2.0,2.0): flowers(x,-2.77,1.17)
        box('Brick chimney',(1.9,1.5,4.47),(.65,.72,1.62),roof)
        for z in (3.9,4.18,4.46,4.74,5.02): box('Chimney mortar',(1.9,1.5,z),(.67,.74,.035),cream)
        box('Chimney crown',(1.9,1.5,5.33),(.86,.91,.18),stone)
        box('Chimney dark flue',(1.9,1.5,5.43),(.49,.54,.025),iron)
        box('Porch bench seat',(-2.25,-3.43,.83),(1.2,.43,.12),wood2)
        for x in (-2.72,-1.78): box('Bench legs',(x,-3.43,.57),(.12,.33,.44),trim)
        stepy=-4.12
    else:
        box('Small covered doorstep',(0,-2.89,.29),(1.80,.86,.16),wood2)
        box('Door rain awning',(0,-2.85,2.58),(1.9,1.0,.13),oldroof).rotation_euler.x=.10
        for x in (-.75,.75): beam('Awning bracket',(x,-2.48,2.17),(x,-3.13,2.55),.10,trim)
        stepy=-3.41
    box('Broad entrance step',(0,stepy,.095),(1.70,.40,.19),stone2,.025)

house(False)
house(True)
stats={}
for name,collection in assets.items():
    bpy.ops.object.select_all(action='DESELECT')
    objects=list(collection.objects)
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    points=[o.matrix_world@Vector(c) for o in objects for c in o.bound_box]
    stats[name]={'meshes':len(objects),'vertices':sum(len(o.data.vertices) for o in objects),
                 'blender_min':[round(min(p[i] for p in points),3) for i in range(3)],
                 'blender_max':[round(max(p[i] for p in points),3) for i in range(3)]}
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_cameras=False,export_lights=False)

bpy.ops.object.select_all(action='DESELECT')
# Collections overlap intentionally: solo the desired collection for authoring/export.
assets['farm_house_upgrade'].hide_viewport=True
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'farm_houses.blend'))
(QA/'model_stats.json').write_text(json.dumps(stats,indent=2))
print('FARM_HOUSES_EXPORTED '+json.dumps(stats))

if '--render' in sys.argv:
    assets['farm_house_upgrade'].hide_viewport=False
    for i,(name,col) in enumerate(assets.items()):
        for obj in col.objects: obj.location.x+=(i-.5)*10
    bpy.ops.mesh.primitive_plane_add(size=200)
    plane=bpy.context.object; plane.name='QA ground'; plane.data.materials.append(material('QA grass',(.25,.34,.17)))
    bpy.ops.object.camera_add(location=(14,-22,15))
    camera=bpy.context.object; camera.rotation_euler=(Vector((0,0,1.4))-camera.location).to_track_quat('-Z','Y').to_euler(); camera.data.type='ORTHO'; camera.data.ortho_scale=23
    scene=bpy.context.scene; scene.camera=camera; scene.render.engine='CYCLES'; scene.cycles.samples=32
    scene.world.color=(.38,.44,.52)
    bpy.ops.object.light_add(type='AREA',location=(-4,-10,17)); bpy.context.object.data.energy=2400; bpy.context.object.data.shape='DISK'; bpy.context.object.data.size=11
    bpy.context.object.rotation_euler=(Vector((0,0,0))-bpy.context.object.location).to_track_quat('-Z','Y').to_euler()
    scene.render.resolution_x=1600; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
    scene.render.filepath=str(QA/'houses_models.png'); bpy.ops.render.render(write_still=True)
