"""Original lake bank miniatures. Blender --background --python tools/build_lake_shore.py.

Meters, grounded center origin; GLBs use Godot Y up. Geometry/materials only,
no collisions or external textures. Named collections remain editable in .blend.
"""
import bpy
import math
import random
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
random.seed(442)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)


def material(name, color):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    node = next((n for n in nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if node is None:
        node = nodes.new('ShaderNodeBsdfPrincipled')
    out = next((n for n in nodes if n.type == 'OUTPUT_MATERIAL'), None)
    if out is None:
        out = nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(node.outputs['BSDF'], out.inputs['Surface'])
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Roughness'].default_value = .88
    return mat


greens = [material('Reed olive', (.24, .39, .075)),
          material('Reed sunlit', (.39, .51, .11)),
          material('Reed deep', (.13, .29, .09))]
brown = material('Velvet cattail', (.25, .11, .045))
pad_green = material('Lily jade', (.10, .38, .19))
vein_green = material('Lily fresh veins', (.28, .52, .22))
petal_pink = material('Lotus rose', (.93, .38, .48))
petal_cream = material('Lotus cream', (1, .83, .70))
pollen = material('Golden pollen', (1, .61, .08))
stones = [material('Pebble slate', (.37, .43, .43)),
          material('Pebble warm', (.53, .51, .42)),
          material('Pebble silver', (.58, .64, .61))]
moss = material('Soft bank moss', (.26, .37, .13))


def mesh(name, verts, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.materials.append(mat)
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    return obj


def ellipsoid(name, position, scale, mat, segments=10, rings=6):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings,
                                       radius=1, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    return obj


def stem(name, a, b, radius, mat):
    direction = Vector(b) - Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=radius,
                                   radius2=radius*.8, depth=direction.length,
                                   location=(Vector(a)+Vector(b))/2)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = direction.to_track_quat('Z', 'Y').to_euler()
    obj.data.materials.append(mat)
    return obj


def leaf(x, y, angle, height, reach, mat):
    verts = []
    for j in range(6):
        t = j/5
        radius = reach*t*t
        width = .037 * math.sin(math.pi*t)**.7 + .002
        z = height*(math.sin(t*1.9)/math.sin(1.9))
        center = Vector((x+math.cos(angle)*radius, y+math.sin(angle)*radius, z))
        side = Vector((-math.sin(angle)*width, math.cos(angle)*width, 0))
        verts.extend([tuple(center-side), tuple(center+Vector((0, 0, .008))), tuple(center+side)])
    faces = []
    for j in range(5):
        a = j*3
        faces.extend([(a, a+3, a+4, a+1), (a+1, a+4, a+5, a+2)])
    obj = mesh('Arched reed blade', verts, faces, mat)
    modifier = obj.modifiers.new('Leaf thickness', 'SOLIDIFY')
    modifier.thickness = .004


assets = {}


def finish(name, before):
    objects = [o for o in bpy.context.scene.objects if o not in before]
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    for obj in objects:
        for old in list(obj.users_collection):
            old.objects.unlink(obj)
        collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    # One mesh per prop, material-batched: repeated reeds should not cost a
    # separate draw call for every blade. Keep originals editable in the source.
    bpy.ops.object.duplicate()
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.join()
    merged = bpy.context.object
    merged.name = name
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{name}.glb'),
                              export_format='GLB', use_selection=True,
                              export_apply=True, export_yup=True)
    bpy.data.objects.remove(merged, do_unlink=True)
    assets[name] = objects


before = set(bpy.context.scene.objects)
for i in range(7):
    angle = i*2.399
    r = .22*math.sqrt(i/6)
    x, y = math.cos(angle)*r, math.sin(angle)*r
    h = [.90, .73, .84, .96, .66, .81, .70][i]
    tip = (x+.045*math.cos(angle), y+.045*math.sin(angle), h)
    stem('Cattail stalk', (x, y, 0), tip, .010, greens[0])
    ellipsoid('Velvet seed head', (tip[0], tip[1], h-.035), (.033, .033, .105), brown)
    stem('Cattail needle', tip, (tip[0], tip[1], h+.098), .004, brown)
    for j in range(3):
        leaf(x, y, angle+j*2.1, h*(.57+.11*j), .24+.06*j, greens[(i+j)%3])
finish('lake_reeds', before)

before = set(bpy.context.scene.objects)
for index, (x, y, radius, angle) in enumerate([(-.23, -.12, .27, -.6), (.20, .10, .24, 1.5), (-.16, .34, .20, 2.7)]):
    # The open V notch is modeled, not a transparent texture.
    n = 22
    verts = [(x, y, .009)]
    for i in range(n+1):
        a = angle+.20+(math.tau-.4)*i/n
        verts.append((x+math.cos(a)*radius, y+math.sin(a)*radius, .014+.003*math.sin(a*3)))
    faces = [(0, i+1, i+2) for i in range(n)]
    obj = mesh('Notched floating leaf', verts, faces, pad_green)
    modifier = obj.modifiers.new('Fleshy edge', 'SOLIDIFY')
    modifier.thickness = .009
    for a in [angle+1.0, angle+2.1, angle+3.1, angle+4.2, angle+5.2]:
        stem('Leaf vein', (x, y, .017), (x+math.cos(a)*radius*.84, y+math.sin(a)*radius*.84, .018), .0022, vein_green)
    if index == 1:
        for layer, count, length, height, mat in [(0, 7, .065, .029, petal_pink), (1, 6, .046, .040, petal_cream)]:
            for i in range(count):
                a = i*math.tau/count+layer*.35
                obj = ellipsoid('Water flower petal', (x+math.cos(a)*length*.65, y+math.sin(a)*length*.65, height), (length, length*.38, .013), mat)
                obj.rotation_euler[2] = a
        ellipsoid('Flower golden center', (x, y, .052), (.022, .022, .009), pollen)
finish('lake_lilies', before)

before = set(bpy.context.scene.objects)
for i, (x, y, sx, sy, sz) in enumerate([(-.30, 0, .40, .32, .20), (.22, .16, .30, .28, .15), (.12, -.31, .25, .19, .105), (-.57, -.26, .15, .13, .07), (.52, -.10, .17, .13, .085)]):
    obj = ellipsoid('Rounded shore stone', (x, y, sz*.86), (sx, sy, sz), stones[i%3], 10, 6)
    obj.rotation_euler[2] = random.uniform(-.7, .7)
    for vertex in obj.data.vertices:
        vertex.co *= random.uniform(.95, 1.05)
        vertex.co.z = max(vertex.co.z, -.86)
    if i < 2:
        ellipsoid('Small moss cushion', (x-.035, y+.02, sz*1.75), (sx*.54, sy*.45, .025), moss)
finish('lake_bank_stones', before)

bpy.ops.object.select_all(action='DESELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/lake_shore.blend'))

# Disposable composition for visual QA; never exported as game geometry.
for name, objects in assets.items():
    dx = {'lake_reeds': -1.2, 'lake_lilies': 0, 'lake_bank_stones': 1.2}[name]
    for obj in objects:
        obj.location.x += dx
ground = material('Preview blue water', (.13, .37, .46))
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -.018))
bpy.context.object.data.materials.append(ground)
bpy.ops.object.camera_add(location=(2.2, -4.3, 3.1))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, .05, .35))-camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 4.3
scene = bpy.context.scene
scene.camera = camera
bpy.ops.object.light_add(type='AREA', location=(-3, -4, 7))
bpy.context.object.data.energy = 650
bpy.context.object.data.shape = 'DISK'
bpy.context.object.data.size = 5
scene.world.color = (.45, .45, .45)
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.render.resolution_x = 1100
scene.render.resolution_y = 650
scene.render.resolution_percentage = 100
preview = ROOT/'test-results/lake-shore-preview.png'
preview.parent.mkdir(exist_ok=True, parents=True)
scene.render.filepath = str(preview)
bpy.ops.render.render(write_still=True)
print('LAKE_SHORE_ASSETS_OK')
