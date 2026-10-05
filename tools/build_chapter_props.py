"""Original first chapter props. Blender 5.2: --background --python this_file.
Meters; Blender Z-up exports Godot Y-up. Ground pivots at zero. Front Godot +Z.
No collisions or gameplay nodes: the game owns interaction/collision placement.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models'
SRC = ROOT / 'art/source'
QA = ROOT / 'test-results/chapter-props'
for folder in (OUT, SRC, QA): folder.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
assets = {}
current = None

def mat(name, rgb, emission=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    p = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if p is None:
        p = m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
        o = m.node_tree.nodes.new('ShaderNodeOutputMaterial')
        m.node_tree.links.new(p.outputs['BSDF'], o.inputs['Surface'])
    p.inputs['Base Color'].default_value = (*rgb, 1)
    p.inputs['Roughness'].default_value = .82
    if emission:
        p.inputs['Emission Color'].default_value = (*rgb, 1)
        p.inputs['Emission Strength'].default_value = emission
    return m

wood = mat('Chapter honey timber', (.43, .25, .105))
light = mat('Chapter fresh cut timber', (.68, .44, .21))
dark = mat('Chapter weathered timber', (.27, .22, .16))
iron = mat('Chapter forged iron', (.11, .15, .16))
cloth = mat('Chapter bakery gingham cream', (.93, .83, .61))
red = mat('Chapter bakery gingham red', (.63, .16, .11))
orange = mat('Chapter carrots', (.92, .32, .055))
green = mat('Chapter carrot tops', (.19, .42, .10))
amber = mat('Chapter warm lantern glass', (1, .57, .16), 1.3)

def asset(name):
    global current
    current = bpy.data.collections.new('CHAPTER_' + name)
    bpy.context.scene.collection.children.link(current)
    assets[name] = current

def finish(o, name, material):
    o.name = name
    for collection in list(o.users_collection): collection.objects.unlink(o)
    current.objects.link(o)
    o.data.materials.append(material)
    return o

def cube(name, xyz, dims, material, bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz)
    o = bpy.context.object
    o.scale = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    finish(o, name, material)
    if bevel:
        mod = o.modifiers.new('Soft worn edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return o

def rod(name, a, b, radius, material, radius2=None, sides=8):
    a, b = Vector(a), Vector(b)
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=radius,
        radius2=radius if radius2 is None else radius2, depth=(b-a).length, location=(a+b)/2)
    o = bpy.context.object
    o.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    return finish(o, name, material)

asset('delivery_basket')
cube('Basket solid bottom', (0, 0, .035), (.70, .46, .07), wood)
for i in range(5):
    z = .095 + i*.048
    for y in [-.235, .235]: cube('Woven willow long band', (0, y, z), (.74, .026, .031), light, .006)
    for x in [-.36, .36]: cube('Woven willow end band', (x, 0, z), (.026, .48, .031), wood, .006)
for x in [-.31, -.155, 0, .155, .31]:
    for y in [-.24, .24]: cube('Basket vertical weave', (x, y, .17), (.021, .025, .28), wood, .004)
for x in [-.365, .365]:
    for y in [-.18, 0, .18]: cube('End weave', (x, y, .17), (.025, .021, .28), light, .004)
cube('Cream checked tea towel', (0, 0, .29), (.68, .43, .04), cloth)
for x in [-.24, 0, .24]: cube('Red towel stripe', (x, 0, .313), (.055, .435, .005), red, 0)
for y in [-.13, .13]: cube('Red cross stripe', (0, y, .316), (.685, .04, .005), red, 0)
for i in range(3):
    x = -.19 + i*.18
    rod('Fresh carrot', (x, -.12, .345), (x+.055, .14, .42), .025, orange, .056)
    for dx in [-.055, 0, .055]: rod('Carrot leafy crown', (x+.055, .14, .42), (x+.055+dx, .24, .48), .018, green, .006, 5)
for i in range(14):
    a, b = math.pi*i/14, math.pi*(i+1)/14
    rod('Arched willow carrying handle', (.35*math.cos(a), 0, .28+.41*math.sin(a)), (.35*math.cos(b), 0, .28+.41*math.sin(b)), .026, wood, sides=6)

asset('rescue_fence')
for x in [-1.38, 1.38]:
    cube('Weathered fence upright', (x, 0, .59), (.18, .19, 1.18), dark)
    cube('Fence post cap', (x, 0, 1.19), (.23, .24, .08), light)
    for z in [.45, .88]:
        cube('Old square nail', (x, -.112, z), (.037, .016, .037), iron, .003)
for sign in [-1, 1]:
    for z in [.43, .87]:
        o = cube('Snapped fence rail', (sign*.98, -.015, z), (.77, .105, .13), dark)
        o.rotation_euler.y = sign*.10
        rod('Exposed jagged split', (sign*.58, -.01, z), (sign*.35, -.01, z-.04), .063, light, .004, 4)
for x, y, rot in [(-.19, -.27, .34), (.32, .19, -.58)]:
    o = cube('Fallen removable rail', (x, y, .085), (1.30, .11, .13), dark)
    o.rotation_euler.z = rot

def bench():
    for x in [-.79, .79]:
        for y in [-.22, .22]: cube('Bench pegged leg', (x, y, .235), (.11, .12, .47), wood)
        cube('Bench seat cross support', (x, 0, .44), (.12, .66, .12), dark)
        cube('Bench back upright', (x, .27, .64), (.11, .105, .79), wood)
    for y in [-.24, -.08, .08, .24]: cube('Repaired seat plank', (0, y, .515), (1.98, .145, .075), light)
    for z in [.78, .97]: cube('Backrest fresh plank', (0, .27, z), (1.98, .085, .15), light)
    cube('Lower stretcher', (0, .12, .24), (1.64, .085, .09), wood)
    for x in [-.79, .79]:
        for z in [.78, .97]: rod('Backrest iron pin', (x, .217, z), (x, .208, z), .019, iron, sides=6)

asset('fishing_bench')
bench()
cube('Lantern broad foot', (1.24, .25, .055), (.30, .30, .11), dark)
rod('Lantern hand cut post', (1.24, .25, .11), (1.24, .25, 1.69), .065, wood, sides=6)
rod('Lantern hanging arm', (1.24, .25, 1.67), (1.0, .25, 1.67), .033, iron)
rod('Lantern hook', (1.0, .25, 1.67), (1.0, .25, 1.46), .018, iron)
rod('Lantern amber panes', (1.0, .25, 1.14), (1.0, .25, 1.43), .105, amber)
for z in [1.12, 1.45]: cube('Lantern iron rim', (1.0, .25, z), (.27, .25, .055), iron)
for x in [.9, 1.1]:
    for y in [.15, .35]: rod('Lantern corner frame', (x, y, 1.14), (x, y, 1.43), .014, iron)

asset('fishing_debris')
for i, (x, y, angle) in enumerate([(-.22,-.19,.18),(.16,.1,-.25),(0,.28,.06)]):
    o = cube('Discarded weathered bench plank', (x, y, .05+i*.06), (1.75, .17, .09), dark)
    o.rotation_euler.z = angle
for x in [-.7, .65]: cube('Broken bench support', (x, .2, .20), (.14, .38, .4), wood)

stats = {}
for name, collection in assets.items():
    bpy.ops.object.select_all(action='DESELECT')
    points = []
    for o in collection.objects:
        o.select_set(True)
        points.extend(o.matrix_world @ Vector(corner) for corner in o.bound_box)
    bpy.ops.export_scene.gltf(filepath=str(OUT / ('chapter_'+name+'.glb')), export_format='GLB', use_selection=True, export_yup=True)
    low = [min(p[i] for p in points) for i in range(3)]
    high = [max(p[i] for p in points) for i in range(3)]
    stats[name] = {'blender_min':low, 'blender_max':high, 'meshes':len(collection.objects)}
bpy.ops.wm.save_as_mainfile(filepath=str(SRC / 'chapter_props.blend'))
(QA/'dimensions.json').write_text(json.dumps(stats, indent=2))
print('CHAPTER_PROPS_EXPORTED', json.dumps(stats))

# Arrange only the QA render after saving the edit-friendly source at local origins.
for name, x in [('delivery_basket',-3.5), ('rescue_fence',0), ('fishing_bench',3.5), ('fishing_debris',0)]:
    for o in assets[name].objects: o.location += Vector((x, 2.2 if name=='fishing_debris' else 0, 0))
groundmat = mat('QA sage ground', (.22,.30,.20))
cube('QA ground', (0,0,-.10), (200,200,.18), groundmat, 0)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.world.color = (.35,.35,.35)
bpy.ops.object.light_add(type='AREA', location=(-3,-4,8))
bpy.context.object.data.energy = 1800
bpy.context.object.data.shape='DISK'
bpy.context.object.data.size=8
bpy.ops.object.camera_add(location=(7,-11,8))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,.4))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO'
camera.data.ortho_scale=12
scene.camera=camera
scene.render.resolution_x=1400
scene.render.resolution_y=850
scene.render.resolution_percentage=100
scene.render.filepath=str(QA/'chapter_props.png')
bpy.ops.render.render(write_still=True)
