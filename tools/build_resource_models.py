"""Original cozy fishing/mining props. Run with Blender --background --python.

Helpers use Godot metres and Y-up; GLB export converts Blender coordinates.
Rod/pickaxe pivot at the handle base, along +Y. Fish faces +X.
Ore rocks rest at Y=0. No textures or external dependencies. Preview PNGs are
written to the OS temporary folder; only mesh objects are included in exports.
"""
import math
import random
import tempfile
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]

def xyz(p):
    return Vector((p[0], -p[2], p[1]))

def material(name, color, metal=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = .64
    p.inputs['Metallic'].default_value = metal
    return m

WOOD = material('Honey ash wood', (.43, .235, .09))
CORD = material('Cream linen', (.83, .73, .49))
METAL = material('Forged charcoal iron', (.11, .15, .17), .6)
SILVER = material('Silver edge', (.50, .62, .64), .7)
GREEN = material('River fish teal back', (.065, .35, .32))
BELLY = material('River fish pale belly', (.56, .77, .63))
FIN = material('Amber fins', (.78, .39, .12))
EYE = material('Black eyes', (.008, .018, .016))
ROCK = [material('Stone %d'%i, c) for i,c in enumerate([
    (.26,.29,.28), (.32,.34,.30), (.21,.24,.24), (.37,.38,.32)])]

def rod(name, a, b, radius, mat, radius_end=None, vertices=8):
    a,b=xyz(a),xyz(b)
    d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius,
        radius2=radius if radius_end is None else radius_end, depth=d.length,
        location=(a+b)/2)
    o=bpy.context.object
    o.name=name
    o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    o.data.materials.append(mat)
    return o

def ico(name, p, scale, mat, subdivision=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivision, radius=1, location=xyz(p))
    o=bpy.context.object
    o.name=name
    o.scale=(scale[0],scale[2],scale[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat)
    return o

def mesh(name, vertices, faces, mat):
    m=bpy.data.meshes.new(name)
    m.from_pydata([xyz(p) for p in vertices],[],faces)
    m.update()
    o=bpy.data.objects.new(name,m)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    return o

def fishing_rod():
    rod('Cork grip',(0,0,0),(0,.31,0),.031,WOOD)
    rod('Bamboo pole',(0,.27,0),(.10,1.99,0),.018,WOOD,.006)
    for y in [.04,.12,.20,.28, .52,1.03,1.52,1.94]:
        x=max(0,y-.27)/1.72*.1
        rod('Linen binding',(x,y,0),(x,y+.022,0),.023 if y<.3 else .015,CORD)
    rod('Reel axle',(0,.23,-.015),(0,.23,.085),.018,METAL)
    rod('Reel spool',(0,.23,.037),(0,.23,.069),.063,METAL,vertices=12)
    rod('Reel line',(0,.23,.035),(0,.23,.071),.046,CORD,vertices=12)
    rod('Line',(.10,1.99,.018),(.14,1.55,.018),.0024,CORD,vertices=4)
    ico('Small red float',(.14,1.54,.018),(.017,.034,.017),FIN,2)

def pickaxe():
    rod('Ash handle',(0,0,0),(0,.87,0),.028,WOOD,.033)
    for y in [.03,.065,.1,.135,.17]:
        rod('Grip cord',(0,y,0),(0,y+.02,0),.03,CORD)
    ico('Iron socket',(0,.80,0),(.075,.085,.065),METAL,2)
    for side in [-1,1]:
        rod('Forged pick', (0,.83,0),(side*.24,.78,0),.057,METAL,.032)
        rod('Polished pick tip',(side*.24,.78,0),(side*.39,.68,0),.034,SILVER,.002)

def fish():
    ico('Fish body',(0,.06,0),(.135,.065,.038),GREEN,2)
    ico('Pale belly',(.006,.039,0),(.114,.037,.035),BELLY,2)
    ico('Head',(.108,.062,0),(.060,.051,.034),GREEN,2)
    for s in [-1,1]:
        ico('Eye',(.132,.077,s*.027),(.010,.010,.005),EYE,2)
        mesh('Side fin',[(-.004,.048,s*.028),(-.04,.015,s*.073),(-.055,.042,s*.025)],[(0,1,2),(2,1,0)],FIN)
    mesh('Tail fin',[(-.105,.06,0),(-.183,.122,0),(-.166,.06,0),(-.183,.006,0)],[(0,1,2),(0,2,3),(2,1,0),(3,2,0)],FIN)
    mesh('Dorsal fin',[(-.065,.103,0),(-.035,.155,0),(.048,.12,0)],[(0,1,2),(2,1,0)],FIN)

def ore(kind):
    rng=random.Random(78)
    colors={'copper':[(.71,.32,.10),(.26,.57,.43)],
            'iron':[(.34,.43,.47),(.58,.32,.18)],
            'quartz':[(.76,.86,.83),(.95,.87,.68)]}
    ore_mats=[material(kind+' mineral %d'%i,c,.35 if kind!='quartz' else .08) for i,c in enumerate(colors[kind])]
    for i,(p,scale) in enumerate([((0,.40,0),(.91,.56,.70)),((-.49,.22,.20),(.45,.30,.43)),((.50,.20,.14),(.43,.27,.48))]):
        obj=ico('Host stone',p,scale,ROCK[i],2)
        for v in obj.data.vertices:
            v.co *= rng.uniform(.88,1.10)
            v.co.z=max(v.co.z,-p[1])
        obj.data.materials.append(ROCK[3])
        for poly in obj.data.polygons:
            poly.material_index=1 if rng.random()<.18 else 0
    for i in range(13):
        angle=i*2.399
        x=math.cos(angle)*rng.uniform(.18,.62)
        z=math.sin(angle)*rng.uniform(.15,.43)
        # Embed roots near the host surface, leaving readable mineral crowns.
        y=.88-(x*x+z*z)*.48
        a=(x,y,z)
        b=(x+x*.22,y+rng.uniform(.16,.33),z+z*.22)
        rod('Visible '+kind+' crystal',a,b,rng.uniform(.07,.12),ore_mats[i%2],.018,5 if kind=='quartz' else 6)

def save(name, preview_scale):
    models=ROOT/'assets/models'
    sources=ROOT/'art/source'
    models.mkdir(parents=True,exist_ok=True)
    sources.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in meshes:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(models/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True)
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=24
    scene.render.resolution_x=640
    scene.render.resolution_y=640
    scene.render.resolution_percentage=100
    scene.world.color=(.32,.32,.32)
    center=Vector((0,0,preview_scale*.38))
    bpy.ops.object.camera_add(location=center+Vector((2,-3,1.7))*preview_scale)
    camera=bpy.context.object
    camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'
    camera.data.ortho_scale=preview_scale*1.35
    scene.camera=camera
    for loc,power,size in [((3,-4,6),700,5),((-3,-1,3),400,4)]:
        bpy.ops.object.light_add(type='AREA', location=Vector(loc)*preview_scale)
        light=bpy.context.object
        light.data.energy=power*preview_scale**2
        light.data.shape='DISK'
        light.data.size=size*preview_scale
        light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
    scene.render.image_settings.file_format='PNG'
    scene.render.filepath=str(Path(tempfile.gettempdir())/(name+'-preview.png'))
    bpy.ops.wm.save_as_mainfile(filepath=str(sources/(name+'.blend')))
    bpy.ops.render.render(write_still=True)
    for o in meshes:o.data.calc_loop_triangles()
    print('RESOURCE_EXPORTED',name,'triangles',sum(len(o.data.loop_triangles) for o in meshes))

for name,builder,size in [('resource_fishing_rod',fishing_rod,2.0),('resource_pickaxe',pickaxe,1.0),('resource_fish',fish,.36)]+[('resource_ore_'+kind,lambda k=kind:ore(k),1.8) for kind in ['copper','iron','quartz']]:
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    builder()
    save(name,size)
