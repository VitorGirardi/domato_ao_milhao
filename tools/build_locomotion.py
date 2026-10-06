"""Author editable Blender locomotion controls and bake both shipped farmer rigs.

Controls store Godot model-axis rotations (+Y up, +Z forward) in radians.
Each control and preview armature keeps separate idle/walk/run Actions. The
generated game file is sampled from Blender F-curves, never from a hidden rig
replacement. Existing character sources and GLBs are read-only inputs.
Run: blender --background --python tools/build_locomotion.py [-- --render]
"""
import bpy, json, math, sys
from pathlib import Path
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/previews/locomotion'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.fps = 30
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x = 880; scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = 'AgX'
scene.world.color = (.35, .40, .38)

BONES = ['Pelvis', 'Spine', 'Chest', 'Neck', 'Head'] + [
    f'{bone}.{side}' for side in ['L', 'R']
    for bone in ['Clavicle', 'UpperArm', 'Forearm', 'Hand', 'Thigh', 'Shin', 'Foot']]
control_collection = bpy.data.collections.new('EDIT ME - Godot model axis angles')
scene.collection.children.link(control_collection)
controls = {}
for name in BONES:
    ob = bpy.data.objects.new('Angles/' + name, None)
    control_collection.objects.link(ob)
    ob.empty_display_type = 'ARROWS'; ob.empty_display_size = .1
    ob['units'] = 'location XYZ = rotation radians in Godot model axes; NOT a position'
    controls[name] = ob
control_collection.hide_render = True

# Contact, weight acceptance, passing, push-off, lifted toe, swing, extension.
# Foot pitch is authored separately, keeping a heel-to-toe roll instead of a
# rigid foot glued to the shin. Runtime handles ground contact and turn lean.
WALK_LEG = [(-.46,.12,.22),(-.30,.24,.06),(.02,.05,-.07),(.36,.12,-.20),
            (.42,.40,-.34),(.18,.95,-.56),(-.40,.70,-.15),(-.60,.20,.25)]
RUN_LEG = [(-.68,.25,.37),(-.10,.46,-.35),(.60,.50,-.70),(.60,1.30,-.52),
           (.10,1.55,-.35),(-.65,1.25,-.28),(-.95,.80,.10),(-.90,.38,.38)]

def pose(cycle, phase):
    angles = {name: [0., 0., 0.] for name in BONES}
    s = math.sin(phase * math.tau); c = math.cos(phase * math.tau)
    if cycle == 'idle':
        angles['Spine'] = [.009*c, 0., .004*s]
        angles['Chest'] = [-.006*c, 0., 0.]
        angles['Neck'] = [-.003*c, 0., 0.]
        angles['Head'] = [.006*s, .006*s, 0.]
        for side, sign in [('L', -1), ('R', 1)]:
            angles['UpperArm.'+side] = [0., 0., -sign*(.19+.005*c)]
            angles['Forearm.'+side] = [-.18, 0., 0.]
            angles['Shin.'+side] = [.018, 0., 0.]
            angles['Foot.'+side] = [-.018, 0., 0.]
        return angles
    running = cycle == 'run'
    legs = RUN_LEG if running else WALK_LEG
    angles['Pelvis'] = [0., (.065 if running else .045)*c, (.022 if running else .015)*s]
    angles['Spine'] = [.075 if running else .012, -.05*c, -.012*s]
    angles['Chest'] = [.025 if running else -.006, -.035*c, 0.]
    angles['Neck'] = [-.04 if running else -.008, .02*c, 0.]
    angles['Head'] = [-.025 if running else 0., .018*c, 0.]
    for side, offset, sign in [('L', 0, -1), ('R', 4, 1)]:
        index = (round(phase*8)+offset) % 8
        thigh, shin, foot = legs[index]
        angles['Thigh.'+side] = [thigh, -.012*sign*c, .015*sign]
        angles['Shin.'+side] = [shin, 0., 0.]
        angles['Foot.'+side] = [foot, 0., 0.]
        angles['Clavicle.'+side] = [0., .018*c*sign, .01*s]
        angles['UpperArm.'+side] = [-thigh*(.78 if running else .72), 0., -sign*(.17 if running else .19)]
        angles['Forearm.'+side] = [-.90-.12*math.sin((phase+offset/8)*math.tau) if running else -.29-.10*math.sin((phase+offset/8)*math.tau), 0., 0.]
        angles['Hand.'+side] = [-.045 if running else -.018, 0., .025*sign]
    return angles

SETTINGS = {'idle': (60, 0.), 'walk': (30, 2.3), 'run': (24, 3.5)}
data = {}
control_actions = {}
for cycle, (end, distance) in SETTINGS.items():
    control_actions[cycle] = {}
    for name, ob in controls.items():
        ob.animation_data_create()
        action = bpy.data.actions.new('CONTROL '+cycle+' / '+name)
        action.use_fake_user = True; ob.animation_data.action = action
        control_actions[cycle][name] = action
        for i in range(9):
            ob.location = pose(cycle, i/8)[name]
            ob.keyframe_insert('location', frame=i*end/8, group='Godot angles')
        for channel in action.layers[0].strips[0].channelbags[0].fcurves:
            for key in channel.keyframe_points:
                key.interpolation = 'BEZIER'
                key.handle_left_type = 'AUTO_CLAMPED'; key.handle_right_type = 'AUTO_CLAMPED'
    frames = []
    for frame in range(end+1):
        scene.frame_set(frame)
        frames.append({name: [round(v, 6) for v in ob.location] for name, ob in controls.items()})
    assert frames[0] == frames[-1]
    data[cycle] = {'duration': end/30, 'stride_length': distance, 'frames': frames}

rigs = {}
collections = {}
for person, offset in [('farmer', -1.1), ('farmer_woman', 1.1)]:
    collection = bpy.data.collections.new('PREVIEW - '+person)
    scene.collection.children.link(collection); collections[person] = collection
    with bpy.data.libraries.load(str(ROOT/'art/source'/f'{person}.blend'), link=False) as (source, target):
        target.objects = source.objects
    imported = [ob for ob in target.objects if ob and ob.type not in {'CAMERA', 'LIGHT'}]
    for ob in imported:
        collection.objects.link(ob)
        if ob.type=='MESH' and ob.data.shape_keys:
            for shape in ob.data.shape_keys.key_blocks:
                if shape.name=='Blink':shape.value=0
    rig = next(ob for ob in imported if ob.type == 'ARMATURE')
    rigs[person] = rig
    for ob in imported:
        if ob.parent is None: ob.location.x += offset
    rig.show_in_front = True
    rig['animation_notes'] = '30 fps baked preview. Actions: idle/walk/run. Controls use Godot model axes.'
    rest = {name: rig.data.bones[name].matrix_local.to_quaternion() for name in BONES}
    for cycle, values in data.items():
        rig.animation_data_create()
        action = bpy.data.actions.new(person+' / '+cycle)
        action.use_fake_user = True; rig.animation_data.action = action
        for frame, angles in enumerate(values['frames']):
            for name, xyz in angles.items():
                # Model axes converted through Blender's rest basis. This is
                # equivalent to FarmAvatar.pose_bone's conjugated rotation.
                rotation = Quaternion((1,0,0),xyz[0]) @ Quaternion((0,0,1),xyz[1]) @ Quaternion((0,-1,0),xyz[2])
                bone = rig.pose.bones[name]; bone.rotation_mode = 'QUATERNION'
                bone.rotation_quaternion = rest[name].inverted() @ rotation @ rest[name]
                bone.keyframe_insert('rotation_quaternion', frame=frame, group=name)
        for curve in action.layers[0].strips[0].channelbags[0].fcurves:
            for key in curve.keyframe_points:key.interpolation='LINEAR'

def set_cycle(cycle):
    for name, ob in controls.items():ob.animation_data.action=control_actions[cycle][name]
    for person, rig in rigs.items():rig.animation_data.action=bpy.data.actions[person+' / '+cycle]
    scene.frame_end=SETTINGS[cycle][0]

# Inspect the actual deformed sole, not a guessed capsule. This auxiliary
# curve is a contact reference for runtime IK; it is NOT root translation in
# the exported angle frames. Preview Actions include its inverse so the
# Blender contact sheets show weight on the floor instead of floating boots.
sole_report={}
for cycle, values in data.items():
    set_cycle(cycle)
    sole_report[cycle]={}
    for person, rig in rigs.items():
        minimum=[]
        for frame in range(len(values['frames'])):
            scene.frame_set(frame);bpy.context.view_layer.update()
            dependency=bpy.context.evaluated_depsgraph_get()
            heights=[]
            for ob in collections[person].objects:
                if ob.type!='MESH':continue
                evaluated=ob.evaluated_get(dependency);mesh=evaluated.to_mesh()
                heights.extend((evaluated.matrix_world@vertex.co).z-rig.location.z for vertex in mesh.vertices)
                evaluated.to_mesh_clear()
            minimum.append(round(min(heights),6))
        sole_report[cycle][person]=minimum
        for frame,height in enumerate(minimum):
            rig.location.z=-height
            rig.keyframe_insert('location',index=2,frame=frame,group='Preview only - sole contact')
        rig.location.z=0
    values['support_y']=sole_report[cycle]['farmer']
    values['support_y_female']=sole_report[cycle]['farmer_woman']
    values['support_note']='Minimum deformed skin height without correction; Blender preview offsets rig only. Runtime may solve contact independently.'
(OUT/'sole_report.json').write_text(json.dumps(sole_report,indent=2),encoding='utf8')

def material(name, color):
    mat=bpy.data.materials.new(name);mat.diffuse_color=(*color,1)
    return mat
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.015))
floor=bpy.context.object;floor.name='Preview ground - not exported'
floor.data.materials.append(material('Sage studio',(.24,.32,.27)))
for name, at, energy, size in [('Key',(2,-5,7),850,5),('Fill',(-4,-1,4),450,5),('Rim',(0,4,6),750,4)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=energy;light.shape='DISK';light.size=size
    ob=bpy.data.objects.new(name,light);scene.collection.objects.link(ob);ob.location=at
    ob.rotation_euler=(Vector((0,0,1.2))-ob.location).to_track_quat('-Z','Y').to_euler()
camera_data=bpy.data.cameras.new('Contact sheet camera');camera=bpy.data.objects.new('Contact sheet camera',camera_data)
scene.collection.objects.link(camera);scene.camera=camera;camera_data.type='ORTHO';camera_data.ortho_scale=4.4

def camera_at(at, target):
    camera.location=at;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
camera_at((4,-8,3.4),(0,0,1.25))
set_cycle('walk');scene.frame_set(0)
scene['README']='Editable Godot angle controls and real pose-keyed male/female rigs. Select a rig Action idle/walk/run; rig locationZ is preview-only sole contact compensation. Runtime angle frames have no root translation.'
scene['cycle_distance']='Suggested world travel per cycle: walk 2.3 m, run 3.5 m. Runtime phase follows actual horizontal travel; collisions do not advance feet.'
(ROOT/'assets/animations/locomotion.gd').write_text('extends RefCounted\n# Authored/sampled in Blender by tools/build_locomotion.py; radians in Godot model axes.\n# 30 fps, closed endpoints; root translation is intentionally absent.\nconst DATA = '+json.dumps(data,separators=(',',':'))+'\n',encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/locomotion.blend'))
if '--render' in sys.argv:
    scene.render.image_settings.file_format='PNG'
    for cycle in ['walk','run']:
        set_cycle(cycle)
        for view in ['front','side']:
            # Side views separate the characters along camera horizontal so
            # both silhouettes remain readable instead of hiding each other.
            if view=='front':camera_at((0,-9,2.9),(0,0,1.15))
            else:
                camera_at((8,-4.5,2.5),(0,0,1.15))
            for i, phase in enumerate([0,.125,.25,.375]):
                scene.frame_set(round(phase*SETTINGS[cycle][0]))
                scene.render.filepath=str(OUT/f'{cycle}_{view}_{i}.png')
                bpy.ops.render.render(write_still=True)
    set_cycle('walk');scene.frame_set(0)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/locomotion.blend'))
print('LOCOMOTION_BLENDER_OK: idle/walk/run, both editable rigs, 30fps closed curves')
