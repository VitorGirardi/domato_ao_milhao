"""Original farm barn stages. Blender 5.2 --background --python tools/build_art_barns.py.

Append -- --render for front/rear QA sheets. Meters, ground 0; Blender -Y front
exports Godot +Z. Closed exterior meshes only; no gameplay/collision changes.
"""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models'; SRC=ROOT/'art/source'; QA=ROOT/'test-results/art-barns'
for p in (OUT,SRC,QA): p.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def mat(name,color):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p is None:
        p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled'); out=m.node_tree.nodes.new('ShaderNodeOutputMaterial'); m.node_tree.links.new(p.outputs['BSDF'],out.inputs['Surface'])
    p.inputs['Base Color'].default_value=(*color,1); p.inputs['Roughness'].default_value=.86
    return m
wood=mat('Weathered honey timber',(.43,.245,.105)); light=mat('Fresh oak',(.56,.34,.16))
dark=mat('Dark wood',(.23,.12,.065)); red=mat('Barn ochre red',(.53,.17,.095))
red2=mat('Barn warm red boards',(.64,.23,.13)); cream=mat('Cream trim',(.86,.77,.54))
roof=mat('Terracotta',(.57,.175,.075)); roof2=mat('Sunlit clay seams',(.70,.265,.105))
iron=mat('Forged iron',(.105,.12,.105)); hay=mat('Golden hay',(.70,.49,.14))
stone=mat('Fieldstone',(.37,.39,.34)); glass=mat('Lantern amber',(.95,.62,.18))
teal=mat('Sage painted fittings',(.12,.36,.30)); oldroof=mat('Weathered grey roof',(.31,.34,.30))
assets={}; current=None
def register(o,name,m):
    o.name=name
    for c in list(o.users_collection):c.objects.unlink(o)
    current.objects.link(o); o.data.materials.append(m); return o
def box(name,loc,size,m):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); return register(o,name,m)
def beam(name,a,b,w,m):
    a,b=Vector(a),Vector(b); o=box(name,(a+b)/2,(w,w,(b-a).length),m)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler(); return o
def extrusion(name,profile,y0,y1,m):
    n=len(profile); vs=[(x,y,z) for y in (y0,y1) for x,z in profile]
    fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(vs,[],fs); mesh.update()
    o=bpy.data.objects.new(name,mesh); current.objects.link(o); o.data.materials.append(m)
    # Recalculate outward normals, including concave-looking gambrel profile.
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.mesh.normals_make_consistent(inside=False); bpy.ops.object.mode_set(mode='OBJECT'); o.select_set(False)
    return o
def door(x,y,z,w,h,paint,trim):
    box('Closed timber door',(x,y,z+h/2),(w,.16,h),paint)
    for i in range(7):box('Door plank joint',(x-w/2+(i+1)*w/8,y-.095,z+h/2),(.025,.025,h-.06),dark)
    for zz in (z+.15,z+h-.15):box('Door crossrail',(x,y-.13,zz),(w,.10,.12),trim)
    beam('Diagonal door brace',(x-w/2+.08,y-.19,z+.19),(x+w/2-.08,y-.19,z+h-.19),.12,trim)
    box('Door latch',(x+w*.29,y-.21,z+h*.48),(.12,.08,.23),iron)
def bale(x,y,z):
    box('Straw bale',(x,y,z+.32),(1,.65,.64),hay)
    for xx in (-.30,.30):box('Hay binding',(x+xx,y,z+.33),(.04,.68,.66),dark)
def build(up):
    global current
    key='farm_art_barn_upgrade' if up else 'farm_art_barn_starter'
    current=bpy.data.collections.new(key); bpy.context.scene.collection.children.link(current); assets[key]=current
    w,d,h=(7.2,6.7,3.5) if up else (5.8,5.2,2.8); front=-d/2
    wall=red if up else wood; trim=cream if up else light
    box('Solid stone footing',(0,0,.14),(w+.16,d+.16,.28),stone)
    box('Closed barn shell',(0,0,(h+.22)/2),(w,d,h-.22),wall)
    # Closely spaced siding and all four corner posts make every angle finished.
    for y in (-d/2-.022,d/2+.022):
        for i in range(int(w/.3)):
            x=-w/2+.15+i*.3
            box('Vertical weatherboard',(x,y,(h+.28)/2),(.265,.055,h-.28),red2 if up and i%3==0 else wall if up else light if i%4==0 else wood)
    for x in (-w/2-.022,w/2+.022):
        for i in range(int(d/.3)):box('Side weatherboard',(x,-d/2+.15+i*.3,(h+.28)/2),(.055,.265,h-.28),wall if i%3 else red2 if up else light)
    for x in (-w/2,w/2):
        for y in (-d/2,d/2):box('Corner post',(x,y,h/2),(.18,.18,h),trim)
    # Solid roof prism guarantees complete watertight silhouette including gables.
    profile=[(-w/2-.35,h-.06),(-w*.32,h+1.55),(0,h+2.35),(w*.32,h+1.55),(w/2+.35,h-.06)] if up else [(-w/2-.3,h-.08),(0,h+1.35),(w/2+.3,h-.08)]
    extrusion('Closed gambrel roof' if up else 'Closed gable roof',profile,front-.34,d/2+.34,roof if up else oldroof)
    for a,b in zip(profile,profile[1:]):
        for y in (front-.38,d/2+.38):beam('Roof edge fascia',(a[0],y,a[1]),(b[0],y,b[1]),.14,trim)
        for j in range(17 if up else 12):
            y=front-.29+j*(d+.55)/(16 if up else 11)
            beam('Standing roof seam',(a[0],y,a[1]+.04),(b[0],y,b[1]+.04),.04,roof2 if up else iron)
    beam('Roof ridge cap',(0,front-.41,h+(2.4 if up else 1.4)),(0,d/2+.41,h+(2.4 if up else 1.4)),.18,roof2 if up else dark)
    # Double doors, clear front focal point, no openings requiring an interior.
    for x in (-.77,.77):door(x,front-.13,.28,1.48,2.3 if up else 2.1,teal if up else dark,trim)
    box('Front lintel',(0,front-.16,2.72 if up else 2.52),(3.35,.25,.18),trim)
    if up:
        door(0,front-.39,3.77,1.25,1.12,red,cream)
        beam('Loft hoist',(0,front+.2,5.26),(0,front-1,5.26),.15,dark)
        beam('Hoist brace',(0,front+.12,4.76),(0,front-.6,5.26),.09,cream)
        beam('Hoist rope',(0,front-.83,5.2),(0,front-.83,4.65),.025,hay)
        for x in (-2.6,2.6):
            box('Lamp bracket',(x,front-.3,2.55),(.1,.4,.1),iron)
            box('Amber lantern',(x,front-.44,2.32),(.20,.20,.34),glass)
            for z in (2.12,2.52):box('Lantern cap',(x,front-.44,z),(.30,.30,.07),iron)
            for xx in (-.11,.11):beam('Lantern cage',(x+xx,front-.56,2.15),(x+xx,front-.56,2.5),.03,iron)
        bale(2.5,front-.6,.28); bale(2.5,front-.6,.94)
    else:
        bale(2.03,front-.55,.0)
        for i in range(3):box('Repaired roof patch',(-1.7+i*.22,1.0,h+.57+i*.1),(.25,.65,.09),light)
        beam('Pitchfork handle',(-2,front-.34,.12),(-2.2,front-.25,1.9),.065,light)
        for i in range(3):beam('Pitchfork tine',(-2.1+i*.1,front-.34,.1),(-2.1+i*.1,front-.34,.48),.035,iron)
    # Rear and side ventilation details, sealed with dark recessed panels.
    for x in (-w/2-.08,w/2+.08):
        for yy in (-1.45,1.45):
            box('Side vent',(x,yy,2.06),(.08,.85,.75),dark)
            for zz in (1.81,2.06,2.31):box('Vent louver',(x*1.006,yy,zz),(.11,.90,.07),trim)
    box('Rear boarded vent',(0,d/2+.08,h-.6),(1.15,.12,.65),dark)
    for x in (-.4,0,.4):box('Rear vent rail',(x,d/2+.16,h-.6),(.055,.08,.66),trim)
build(False); build(True)
manifest={}
for key,col in assets.items():
    bpy.ops.object.select_all(action='DESELECT')
    points=[]
    for o in col.objects:
        o.select_set(True); points.extend(o.matrix_world@Vector(v) for v in o.bound_box)
    bpy.context.view_layer.update()
    points=[o.matrix_world@Vector(v) for o in col.objects for v in o.bound_box]
    low=[min(v[i] for v in points) for i in range(3)]; high=[max(v[i] for v in points) for i in range(3)]
    manifest[key]={'godot_min':[low[0],low[2],-high[1]],'godot_max':[high[0],high[2],-low[1]],'meshes':len(col.objects),'vertices':sum(len(o.data.vertices) for o in col.objects)}
    bpy.ops.export_scene.gltf(filepath=str(OUT/(key+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_materials='EXPORT')
(QA/'manifest.json').write_text(json.dumps(manifest,indent=2))
# Source presents stages side-by-side; exports above retain identical origin.
for j,col in enumerate(assets.values()):
    for o in col.objects:o.location.x+=(j-.5)*11
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'art_barns.blend'))
if '--render' in sys.argv:
    scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=32
    scene.world.color=(.35,.35,.35); scene.render.resolution_x=1500; scene.render.resolution_y=850; scene.render.resolution_percentage=100
    bpy.ops.mesh.primitive_plane_add(size=200); bpy.context.object.data.materials.append(mat('QA ground',(.20,.27,.17)))
    bpy.ops.object.light_add(type='AREA',location=(0,-8,17)); bpy.context.object.data.energy=2200; bpy.context.object.data.shape='DISK'; bpy.context.object.data.size=12
    bpy.ops.object.light_add(type='SUN',location=(8,-10,18)); bpy.context.object.data.energy=2; bpy.context.object.rotation_euler=(.4,-.3,-.4)
    bpy.ops.object.camera_add(); camera=bpy.context.object; camera.data.type='ORTHO'; camera.data.ortho_scale=25; scene.camera=camera
    for label,loc in [('front',(14,-24,16)),('rear',(-14,24,16))]:
        camera.location=loc; camera.rotation_euler=(Vector((0,0,2))-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(QA/(label+'.png')); bpy.ops.render.render(write_still=True)
print('BARN_ART_OK',json.dumps(manifest))
