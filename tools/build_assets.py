"""Original low-poly asset kit. Run with Blender --background --python tools/build_assets.py.
Blender coordinates: Z up, front -Y; exported glTF uses Y up, front +Z.
Each asset is saved as editable .blend and as a runtime .glb.
"""
import bpy
import math
import random
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT / 'assets' / 'models'
SOURCE = ROOT / 'art' / 'source'
EXPORT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
random.seed(24)

def mat(name, hex_color):
    color = tuple(int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4))
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if bsdf is None:
        bsdf = m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
    output = next((n for n in m.node_tree.nodes if n.type == 'OUTPUT_MATERIAL'), None)
    if output is None:
        output = m.node_tree.nodes.new('ShaderNodeOutputMaterial')
    m.node_tree.links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = .85
    return m

M = {name: mat(name, color) for name, color in {
    'Paint':'b94d36', 'DoorBarn':'b94d36', 'DoorCoop':'503d30', 'Cream':'fff1ce', 'Roof':'344d52', 'Wood':'98603c',
    'DarkWood':'503d30', 'Leaf':'65a443', 'LightLeaf':'88b34d', 'Trunk':'76503a',
    'Gold':'efb53c', 'Orange':'e37827', 'Green':'3e863c', 'White':'fff2d9',
    'Red':'d54d37', 'Eye':'252f30', 'Boot':'4c3830', 'Denim':'3d727e',
    'Skin':'eeb882', 'Hat':'d8ae59', 'Stone':'969e99', 'Window':'84c0c3',
    'Soil':'85603d', 'Petal':'eac269'
}.items()}

def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def finish(obj, name, material):
    obj.name = name
    obj.data.materials.append(M[material])
    return obj

def box(name, pos, size, material, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Soft handmade edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj, name, material)

def sphere(name, pos, scale, material, subdivisions=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1, location=pos)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material)

def cylinder(name, pos, radius, depth, material, vertices=8, top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius,
        radius2=radius if top is None else top, depth=depth, location=pos)
    return finish(bpy.context.object, name, material)

def beam(name, a, b, width, material):
    a, b = Vector(a), Vector(b)
    obj = box(name, (a+b)/2, (width, width, (b-a).length), material)
    obj.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    return obj

def roof(width, depth, bottom, rise, material='Roof'):
    w, d = width/2, depth/2
    verts = [(-w,-d,bottom),(w,-d,bottom),(0,-d,bottom+rise),
             (-w,d,bottom),(w,d,bottom),(0,d,bottom+rise)]
    mesh = bpy.data.meshes.new('Pitched roof')
    mesh.from_pydata(verts, [], [(0,2,1),(3,4,5),(0,3,5,2),(2,5,4,1),(1,4,3,0)])
    mesh.update()
    obj=bpy.data.objects.new('Roof',mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj, 'Roof', material)
    for y in [-d-.02,d+.02]:
        beam('Gable trim',(-w,y,bottom),(0,y,bottom+rise),.13,'Cream')
        beam('Gable trim',(0,y,bottom+rise),(w,y,bottom),.13,'Cream')

def export(name):
    if '--only-buildings' in sys.argv and name not in ('barn', 'coop'):
        return
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = next(o for o in bpy.context.scene.objects if o.type=='MESH')
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(EXPORT / f'{name}.glb'), export_format='GLB',
                              use_selection=True, export_apply=True, export_cameras=False,
                              export_lights=False, export_yup=True)
    print('ASSET_OK',name)

clear()
box('Barn walls',(0,0,1.45),(5,4.5,2.9),'Paint',.05)
roof(5.65,5.15,2.92,1.6)
for x in [-2.4,2.4]:
    for y in [-2.29,2.29]: box('Corner trim',(x,y,1.45),(.16,.16,2.9),'Cream')
for x in [-2,-1.5,-1,1,1.5,2]: box('Front batten',(x,-2.29,1.45),(.06,.04,2.75),'Red')
box('Door frame',(0,-2.32,1.08),(2.18,.12,2.16),'Cream')
box('Double door',(0,-2.41,1.02),(1.96,.1,2.02),'DoorBarn')
for x in [-.96,0,.96]: box('Door stile',(x,-2.48,1.03),(.08,.05,2.04),'Cream')
beam('Door cross',(-.9,-2.49,.1),(.9,-2.49,1.95),.1,'Cream')
beam('Door cross',(.9,-2.49,.1),(-.9,-2.49,1.95),.1,'Cream')
box('Loft window',(0,-2.59,3.25),(.72,.06,.64),'Cream')
box('Loft glass',(0,-2.63,3.25),(.55,.03,.47),'Window')
for side in [-1,1]:
    for y in [-1,1]:
        box('Side frame',(side*2.53,y,1.6),(.09,1.05,1),'Cream')
        box('Side window',(side*2.59,y,1.6),(.03,.85,.8),'Window')
cylinder('Vent',(0,1,4.35),.25,.7,'Cream')
export('barn')

clear()
for x in [-1.25,1.25]:
    for y in [-1,1]: box('Leg',(x,y,.4),(.19,.19,.8),'Wood')
box('Coop walls',(0,0,1.25),(2.7,2.3,1.65),'Paint',.04)
roof(3.15,2.75,2.07,.8)
box('Chicken door',(0,-1.19,1),(.8,.1,1.1),'DoorCoop')
box('Door trim',(0,-1.26,1.56),(.96,.12,.12),'Cream')
for x in [-.47,.47]: box('Door jamb',(x,-1.25,1.03),(.1,.12,1.06),'Cream')
ramp=box('Ramp',(0,-1.63,.3),(.8,1.35,.08),'Wood')
ramp.rotation_euler.x=math.radians(19)
for y in [-2.1,-1.85,-1.6,-1.35]: box('Ramp rung',(0,y,.3+(y+1.63)*.32),(.85,.09,.07),'Cream')
box('Nest box',(1.48,.3,1.1),(.65,.9,.6),'Wood',.05)
box('Nest lid',(1.48,.3,1.44),(.8,1.02,.1),'Roof')
export('coop')

clear()
for x in [-.94,.94]:
    box('Fence post',(x,0,.57),(.14,.16,1.14),'Paint',.025)
    cylinder('Post cap',(x,0,1.17),.115,.14,'Cream',4,0)
for z in [.36,.8]: box('Fence rail',(0,0,z),(1.95,.11,.14),'Cream')
export('fence')

clear()
for x in [-.64,.64]: box('Sign post',(x,0,.7),(.14,.16,1.4),'Wood',.015)
box('Sign board',(0,0,1.4),(1.95,.18,.8),'Paint',.06)
box('Sign top trim',(0,0,1.84),(2.06,.24,.1),'Cream',.02)
export('sign')

clear()
cylinder('Trunk',(0,0,1.6),.31,3.2,'Trunk',7,.19)
for a in [0,2.1,4.2]:
    beam('Branch',(0,0,1.6),(.8*math.cos(a),.8*math.sin(a),2.7),.2,'Trunk')
for i,(pos,scale) in enumerate([((0,0,3.8),(1.7,1.65,1.65)),((-1,0,3.1),(1.3,1.2,1.1)),
                              ((1,0,3.25),(1.35,1.3,1.2)),((0,-.9,3.35),(1.2,1.25,1.2))]):
    sphere('Canopy',pos,scale,'Leaf' if i%2 else 'LightLeaf',2)
export('tree')

clear()
sphere('Rock',(0,0,.45),(1.1,.8,.72),'Stone',1)
sphere('Rock chip',(.7,.3,.15),(.5,.45,.3),'Stone',1)
export('rock')

clear()
sphere('Hen body',(0,0,.4),(.29,.4,.32),'White',2)
sphere('Wing',(-.27,.02,.43),(.1,.23,.18),'Cream',1)
sphere('Wing',(.27,.02,.43),(.1,.23,.18),'Cream',1)
sphere('Head',(0,-.26,.72),(.19,.2,.23),'White',2)
for x in [-.17,.17]: sphere('Eye',(x,-.33,.77),(.037,.04,.043),'Eye',1)
beak=cylinder('Beak',(0,-.49,.69),.09,.2,'Gold',4,0)
beak.rotation_euler.x=math.pi/2
for y in [-.37,-.26,-.15]: sphere('Comb',(0,y,.94),(.05,.065,.085),'Red',1)
sphere('Wattle',(0,-.38,.57),(.06,.07,.09),'Red',1)
for x in [-.13,.13]:
    cylinder('Leg',(x,0,.11),.025,.22,'Gold',6)
    box('Foot',(x,-.06,.025),(.09,.2,.04),'Gold')
for x in [-.1,0,.1]:
    feather=sphere('Tail',(x,.36,.58),(.08,.2,.17),'Cream',1)
    feather.rotation_euler.x=-.5
export('chicken')

clear()
for x in [-.18,.18]:
    box('Boot',(x,-.08,.15),(.25,.43,.3),'Boot',.035)
    box('Leg',(x,0,.5),(.22,.25,.55),'Denim',.03)
box('Overalls',(0,0,.95),(.68,.39,.6),'Denim',.06)
box('Shirt',(0,0,1.21),(.65,.4,.32),'Cream',.05)
for x in [-.22,.22]: box('Overall strap',(x,-.22,1.22),(.09,.05,.32),'Denim')
for x in [-.47,.47]:
    sphere('Sleeve',(x,0,1.16),(.16,.2,.22),'Cream',1)
    sphere('Hand',(x,0,.88),(.115,.12,.19),'Skin',2)
sphere('Head',(0,0,1.68),(.31,.27,.35),'Skin',2)
for x in [-.12,.12]: sphere('Eye',(x,-.247,1.72),(.035,.025,.04),'Eye',1)
sphere('Nose',(0,-.29,1.62),(.065,.07,.07),'Skin',1)
cylinder('Hat brim',(0,0,1.96),.49,.07,'Hat',12)
cylinder('Hat crown',(0,0,2.1),.3,.27,'Hat',10,.25)
cylinder('Hat ribbon',(0,0,2.01),.305,.075,'Wood',10)
export('farmer')

clear()
for x in [-1.6,1.6]:
    for y in [-.75,.75]: box('Market post',(x,y,1.35),(.14,.14,2.7),'Wood')
box('Counter',(0,0,.85),(3.5,1.8,.15),'Wood',.025)
box('Front panel',(0,-.85,.45),(3.35,.08,.8),'Paint')
for i in range(7):
    stripe=box('Awning stripe',(-1.65+i*.55,0,2.67),(.55,2.3,.12),'Cream' if i%2 else 'Gold')
    stripe.rotation_euler.x=.06
for x in [-1,0,1]:
    box('Crate',(x,0,1.02),(.8,.9,.26),'DarkWood')
    for j in range(4): sphere('Produce',(x-.2+(j%2)*.35,-.22+(j//2)*.35,1.22),(.16,.16,.17),'Orange' if x else 'Red',1)
export('market')

for crop in ['carrot','wheat','corn']:
    clear()
    for x in [-.52,0,.52]:
        for y in [-.52,0,.52]:
            if crop=='carrot':
                cylinder('Carrot',(x,y,.1),.105,.28,'Orange',6,0)
                for a in [0,2.1,4.2]:
                    leaf=box('Carrot leaf',(x+.08*math.cos(a),y+.08*math.sin(a),.29),(.065,.045,.4),'Green')
                    leaf.rotation_euler=(.35*math.cos(a),.35*math.sin(a),a)
            elif crop=='wheat':
                cylinder('Stem',(x,y,.42),.023,.84,'Gold',5)
                for z in [.65,.79,.92]:
                    sphere('Grain',(x-.06,y,z),(.07,.065,.11),'Gold',1)
                    sphere('Grain',(x+.06,y,z+.04),(.07,.065,.11),'Petal',1)
            else:
                cylinder('Corn stem',(x,y,.63),.035,1.26,'Green',6)
                for a in [-1,1]:
                    leaf=box('Corn leaf',(x+a*.15,y,.65),(.4,.12,.045),'Leaf')
                    leaf.rotation_euler.y=a*.5
                sphere('Corn cob',(x+.09,y,.9),(.09,.09,.28),'Gold',2)
                cylinder('Tassel',(x,y,1.38),.05,.2,'Gold',5,0)
    export(crop)

clear()
for a in range(5):
    angle=a*math.tau/5
    sphere('Petal',(.12*math.cos(angle),.12*math.sin(angle),.36),(.1,.1,.045),'Petal',1)
sphere('Flower heart',(0,0,.39),(.07,.07,.035),'Gold',1)
cylinder('Stem',(0,0,.18),.017,.36,'Green',5)
export('flower')
print('ALL_ASSETS_COMPLETE')

# The articulated character and action props supersede the original static farmer.
import runpy
if '--only-buildings' not in sys.argv:
    runpy.run_path(str(ROOT / 'tools' / 'build_feedback_assets.py'), run_name='__main__')
    runpy.run_path(str(ROOT / 'tools' / 'build_animal_assets.py'), run_name='__main__')
    runpy.run_path(str(ROOT / 'tools' / 'build_trade_assets.py'), run_name='__main__')
