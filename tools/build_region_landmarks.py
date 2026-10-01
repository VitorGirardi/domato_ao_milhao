"""Original Vale e Serra timber landmarks, authored and exported with Blender.

Run: blender --background --python tools/build_region_landmarks.py
Coordinates in the helpers are Godot Y-up; Blender receives (x, -z, y).
Deck top is precisely zero. Collisions are supplied by the game separately.
Previews are written outside the repository to the system temporary directory.
"""
import math
import random
import tempfile
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
RNG = random.Random(370)


def material(name, color, roughness=0.82, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = roughness
    p.inputs['Metallic'].default_value = metallic
    return m


WOOD = [material('Honey timber %d' % i, c) for i, c in enumerate([
    (.43, .255, .115), (.49, .30, .145), (.38, .215, .095),
    (.53, .34, .17), (.455, .28, .14)])]
DARK = material('Weathered chestnut structure', (.245, .132, .064))
CAP = material('Warm polished handrails', (.36, .19, .085))
IRON = material('Forged iron fittings', (.10, .13, .13), .55, .5)


def xyz(p):
    return Vector((p[0], -p[2], p[1]))


def cube(name, p, size, mat, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(p))
    o = bpy.context.object
    o.name = name
    o.scale = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    if bevel:
        modifier = o.modifiers.new('Hand softened timber edges', 'BEVEL')
        modifier.width = bevel
        modifier.segments = 1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return o


def beam(name, a, b, width, mat=DARK):
    a, b = xyz(a), xyz(b)
    delta = b - a
    bpy.ops.mesh.primitive_cube_add(size=1, location=(a+b)/2)
    o = bpy.context.object
    o.name = name
    o.scale = (width, width, delta.length)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.rotation_euler = delta.to_track_quat('Z', 'Y').to_euler()
    o.data.materials.append(mat)
    modifier = o.modifiers.new('Soft timber edges', 'BEVEL')
    modifier.width = .025
    modifier.segments = 1
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return o


def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def railing(a, b, panels, skip_first_post=False):
    """Open, crossed timber rails keep the landscape visible."""
    a, b = Vector(a), Vector(b)
    for i in range(panels+1):
        if i == 0 and skip_first_post:
            continue
        p = a.lerp(b, i/panels)
        cube('Rail post', (p.x, .56, p.z), (.22, 1.48, .22), DARK)
        cube('Post cap', (p.x, 1.315, p.z), (.29, .09, .29), CAP)
        cube('Iron post collar', (p.x, .12, p.z), (.235, .085, .235), IRON, .005)
    beam('Continuous handrail', (a.x, 1.23, a.z), (b.x, 1.23, b.z), .20, CAP)
    beam('Lower edge rail', (a.x, .23, a.z), (b.x, .23, b.z), .13)
    for i in range(panels):
        p, q = a.lerp(b, i/panels), a.lerp(b, (i+1)/panels)
        beam('Rail diagonal', (p.x, .30, p.z), (q.x, 1.10, q.z), .085, CAP)
        beam('Rail diagonal', (q.x, .30, q.z), (p.x, 1.10, p.z), .085, CAP)


def bridge():
    clear()
    # Eight metres overall, clear horse passage between the rails is 7.5 m.
    for i in range(92):
        cube('Crosswise deck plank %03d' % i, (-22.75+i*.5, -.13, 0),
             (.488, .26, 8), RNG.choice(WOOD))
    for z in [-3.65, 0, 3.65]:
        cube('Longitudinal carrying beam', (0, -.53, z), (46, .62, .38), DARK)
    for x in [-20, -10, 0, 10, 20]:
        cube('Pier crosshead', (x, -.91, 0), (.50, .40, 8.30), DARK)
        for z in [-3.4, 3.4]:
            cube('River pier', (x, -2.25, z), (.50, 3.5, .50), DARK)
            for dx in [-2.1, 2.1]:
                beam('Pier knee brace', (x, -2.3, z), (x+dx, -.75, z), .25)
        beam('Pier cross bracing', (x, -3.65, -3.4), (x, -1.15, 3.4), .22)
        beam('Pier cross bracing', (x, -3.65, 3.4), (x, -1.15, -3.4), .22)
    for z in [-3.90, 3.90]:
        railing((-22.9, 0, z), (22.9, 0, z), 16)


def lookout():
    clear()
    # Wide platform, unobstructed southern approach (Godot +Z).
    for row in range(25):
        z = -4.8+row*.4
        for x in [-4, 0, 4]:
            cube('Mirante deck plank', (x, -.12, z), (3.986, .24, .388), RNG.choice(WOOD))
    for x in [-5.55, 0, 5.55]:
        cube('Platform bearer', (x, -.46, 0), (.36, .6, 10), DARK)
    for z in [-4.5, 0, 4.5]:
        cube('Cross bearer', (0, -.79, z), (12, .34, .36), DARK)
        for x in [-5.5, 5.5]:
            cube('Mirante tall pier', (x, -2.30, z), (.44, 4.60, .44), DARK)
            for dx in [1.2 if x < 0 else -1.2]:
                beam('Platform knee brace', (x, -2.25, z), (x+dx, -.73, z), .22)
        beam('Underfloor cross brace', (-5.5, -4.2, z), (5.5, -1.0, z), .22)
        beam('Underfloor cross brace', (5.5, -4.2, z), (-5.5, -1.0, z), .22)
    railing((-5.85, 0, -4.85), (5.85, 0, -4.85), 4)
    for x in [-5.85, 5.85]:
        railing((x, 0, -4.85), (x, 0, 4.85), 4, skip_first_post=True)
    # Seats face the panorama; the centre remains free for horses and players.
    for x in [-3.6, 3.6]:
        for z in [-3.8, -3.52]:
            cube('View bench seat', (x, .49, z), (2.4, .14, .25), CAP)
        for dx in [-.82, .82]:
            cube('Bench foot', (x+dx, .2, -3.66), (.18, .4, .5), DARK)


def export_and_preview(name, camera, target, scale):
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
    bpy.ops.object.join()
    model = bpy.context.object
    model.name = name
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    model.data.calc_loop_triangles()
    points = [model.matrix_world @ Vector(p) for p in model.bound_box]
    print(name, 'triangles=', len(model.data.loop_triangles), 'BLENDER_BOUNDS=',
          tuple(min(p[i] for p in points) for i in range(3)),
          tuple(max(p[i] for p in points) for i in range(3)))
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{name}.glb'),
        export_format='GLB', use_selection=True, export_apply=True, export_yup=True)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 24
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.world.color = (.35, .35, .35)
    bpy.ops.object.camera_add(location=xyz(camera))
    cam = bpy.context.object
    cam.rotation_euler = (xyz(target)-cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = scale
    scene.camera = cam
    bpy.ops.object.light_add(type='AREA', location=xyz((-12, 25, 12)))
    bpy.context.object.data.energy = 6000
    bpy.context.object.data.shape = 'DISK'
    bpy.context.object.data.size = 20
    scene.render.film_transparent = False
    scene.view_settings.view_transform = 'AgX'
    scene.render.filepath = str(Path(tempfile.gettempdir())/f'{name}_preview.png')
    bpy.ops.render.render(write_still=True)


bridge()
export_and_preview('region_bridge', (31, 25, 37), (0, -1, 0), 57)
lookout()
export_and_preview('region_lookout', (17, 14, 22), (0, -.8, 0), 21)
print('REGION_LANDMARKS_OK')
