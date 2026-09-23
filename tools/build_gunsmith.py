"""Original Damião character. Run with Blender --background --python tools/build_gunsmith.py.

Uses the farm's continuous body topology and rig, with authored tank-top material
regions, a new face, close-cropped hair and a restrained, serious expression.
Only writes gunsmith assets. Preview is outside the runtime export selection.
"""
import bpy, math, runpy, sys
import numpy as np
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
api = runpy.run_path(str(ROOT / 'tools/build_cartoon_characters.py'))
body_api = runpy.run_path(str(ROOT / 'tools/character_body.py'))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
palette = {'Skin':'75472F','Cheek':'8D5640','Shirt':'E6DDC5',
           'Denim':'475447','Seam':'778169','Boot':'594337','Sole':'292B27',
           'Glove':'75472F','Hair':'211F1C','Brow':'29221D','White':'F3E8D7',
           'Dark':'422A23','Eye':'171915','Iris':'62452C','Gold':'B28B4D',
           'Hat':'475447','Band':'AE9874'}
M = {k:api['material']('gunsmith_'+k,v) for k,v in palette.items()}
api['mesh'].__globals__['M'] = M
api['M'] = M
body, old_details = body_api['build_body'](api, True)
for obj in old_details: bpy.data.objects.remove(obj, do_unlink=True)
# Resolve the smooth surface before tailoring material boundaries. This keeps
# the neckline continuous across the coarse body's shoulder support loops.
bpy.context.view_layer.objects.active=body
bpy.ops.object.modifier_apply(modifier=body.modifiers[0].name)
names=list(M)
core=body.vertex_groups['TorsoTopology'].index
# A packed UV cloth mask gives a smooth tailored neckline without cutting the
# connected skinned body or exposing polygonal material-region boundaries.
sz=1024
xx,zz=np.meshgrid((np.arange(sz)+.5)/sz,(np.arange(sz)+.5)/sz)
front=xx<.5
x=(np.where(front,xx*2,(xx-.5)*2)-.5)*1.6
z=.90+zz*1.0
neck=np.where(front,1.49+.23*np.minimum(1,np.abs(x)/.20)**2,1.65+.08*np.minimum(1,np.abs(x)/.20)**2)
edge=.49-.19*np.clip((z-1.30)/.16,0,1)
mask=np.clip((neck-z)/.004+.5,0,1)*np.clip((edge-np.abs(x))/.004+.5,0,1)
skin=np.array([int(palette['Skin'][i:i+2],16)/255 for i in (0,2,4)])
cloth=np.array([int(palette['Shirt'][i:i+2],16)/255 for i in (0,2,4)])
pixels=np.ones((sz,sz,4),dtype=np.float32);pixels[:,:,:3]=skin[None,None,:]*(1-mask[:,:,None])+cloth[None,None,:]*mask[:,:,None]
texture=bpy.data.images.new('Damiao tailored tank',sz,sz)
texture.pixels.foreach_set(pixels.ravel());texture.pack()
tailored=api['material']('gunsmith_tailored_tank','FFFFFF')
tex=tailored.node_tree.nodes.new('ShaderNodeTexImage');tex.image=texture
tailored.node_tree.links.new(tex.outputs['Color'],next(n for n in tailored.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'])
body.data.materials.append(tailored);tailored_index=len(body.data.materials)-1
uv=body.data.uv_layers.new(name='TankTailoring')
for face in body.data.polygons:
    p=sum((body.data.vertices[i].co for i in face.vertices),Vector())/len(face.vertices)
    if p.z<1.055: continue
    face.material_index=tailored_index
    for loop_index in face.loop_indices:
        v=body.data.vertices[body.data.loops[loop_index].vertex_index].co
        uv.data[loop_index].uv=((v.x/1.6+.5)*.5+(0 if p.y<0 else .5),v.z-.90)
details=[]
box=api['box']; tube=api['tube']; ell=api['ellipsoid']
details.append(tube('Tank hem',[(.39*math.cos(a),.255*math.sin(a),1.062) for a in [i*math.tau/48 for i in range(49)]],.014,'Shirt'))
for sign in [-1,1]:
    details.append(box('Cargo pocket',(sign*.25,-.14,.78),(.19,.04,.18),'Denim',.025))
    details.append(box('Cargo pocket flap',(sign*.25,-.165,.855),(.19,.017,.045),'Seam',.009))
    for z in [.14,.18]:
        details.append(tube('Boot lace',[(sign*.217-.06,-.165,z),(sign*.217,-.185,z-.008),(sign*.217+.06,-.165,z)],.006,'Band'))
details.append(tube('Fine brass chain',[(-.17,-.14,1.68),(-.12,-.195,1.58),(0,-.228,1.54),(.12,-.195,1.58),(.17,-.14,1.68)],.008,'Gold'))
details.append(box('Pendant',(0,-.237,1.518),(.035,.012,.047),'Gold',.008))

hx,hy,hz,cz,power=.54,.38,.475,1.655,.88
def face_y(x,z,offset=0):
    t=max(.006,1-(abs(x)/hx)**(2/power)-(abs(z-cz)/hz)**(2/power))
    return -hy*t**(power/2)-offset
parts=[ell('Head sculpt',(0,0,cz),(hx,hy,hz),'Skin',power,24,40)]
eyes=[]; closed=[]
for s in [-1,1]:
    parts.append(ell('Ear',(s*.54,0,1.66),(.098,.087,.14),'Skin'))
    parts.append(ell('Inner ear',(s*.548,-.076,1.66),(.05,.015,.079),'Cheek'))
    x=s*.193;z=1.775
    eyes.extend([ell('Eye white',(x,face_y(x,z,.01),z),(.104,.03,.072),'White'),
                 ell('Iris',(x,face_y(x,z,.043),z),(.045,.012,.054),'Iris'),
                 ell('Pupil',(x,face_y(x,z,.055),z),(.025,.008,.039),'Eye'),
                 ell('Catchlight',(x-.014,face_y(x,z,.064),z+.02),(.012,.005,.014),'White',rings=8,segments=12)])
    parts.append(tube('Heavy upper eyelid',[(x-.105,face_y(x-.105,z+.025,.016),z+.025),(x,face_y(x,z+.068,.018),z+.068),(x+.105,face_y(x+.105,z+.025,.016),z+.025)],.02,'Skin',[.4,1,.4]))
    parts.append(tube('Serious brow',[(s*.08,face_y(s*.08,1.879,.032),1.879),(s*.19,face_y(s*.19,1.91,.033),1.91),(s*.30,face_y(s*.30,1.895,.03),1.895)],.031,'Brow',[.75,1,.45]))
    closed.append(tube('Blink crease',[(x-.095,face_y(x-.095,z,-.03),z),(x,face_y(x,z,-.03),z-.006),(x+.095,face_y(x+.095,z,-.03),z)],.008,'Brow',[.25,1,.25]))
parts.append(ell('Nose bridge',(0,-.365,1.655),(.077,.074,.106),'Skin'))
parts.append(ell('Nose tip',(0,-.41,1.602),(.099,.074,.06),'Skin'))
for s in [-1,1]:
    parts.append(ell('Nose wing',(s*.078,-.399,1.592),(.049,.04,.041),'Skin'))
    parts.append(ell('Nostril',(s*.064,-.433,1.576),(.022,.008,.011),'Dark',rings=8,segments=12))
parts.append(tube('Closed mouth',[(-.155,face_y(-.155,1.443,.015),1.443),(0,face_y(0,1.451,.021),1.451),(.155,face_y(.155,1.443,.015),1.443)],.012,'Dark',[.25,1,.25]))
parts.append(tube('Lower lip',[(-.10,face_y(-.10,1.426,.013),1.426),(0,face_y(0,1.419,.018),1.419),(.10,face_y(.10,1.426,.013),1.426)],.014,'Cheek',[.25,1,.25]))
# Close-cropped cap follows the skull; tiny curls break the silhouette gently.
verts=[];faces=[]
for j in range(9):
    lat=.60+(math.pi/2-.60)*j/9
    for i in range(48):
        a=math.tau*i/48
        verts.append((.546*api['signed'](math.cos(lat),power)*api['signed'](math.cos(a),power),.389*api['signed'](math.cos(lat),power)*api['signed'](math.sin(a),power),cz+.488*api['signed'](math.sin(lat),power)))
for j in range(8):
    for i in range(48):
        a=j*48+i;b=j*48+(i+1)%48;faces.append((a,b,b+48,a+48))
verts.append((0,0,cz+.488))
for i in range(48):faces.append((384+i,384+(i+1)%48,432))
parts.append(api['mesh']('Close cropped hair',verts,faces,'Hair'))
for j in range(4):
    lat=.65+j*.21
    for i in range(20):
        a=math.tau*(i+.5*(j%2))/20
        p=(.546*api['signed'](math.cos(lat),power)*api['signed'](math.cos(a),power),.390*api['signed'](math.cos(lat),power)*api['signed'](math.sin(a),power),cz+.490*api['signed'](math.sin(lat),power))
        parts.append(ell('Short curl',p,(.028,.025,.023),'Hair',rings=6,segments=8))
for s in [-1,1]:
    parts.append(tube('Sideburn',[(s*.458,-.13,1.91),(s*.479,-.12,1.79),(s*.474,-.10,1.71)],.029,'Hair',[1,1,.4]))
    parts.append(tube('Jaw stubble',[(s*.414,face_y(s*.414,1.46,.008),1.46),(s*.31,face_y(s*.31,1.32,.012),1.32),(s*.15,face_y(s*.15,1.245,.012),1.245),(0,face_y(0,1.23,.012),1.23)],.024,'Hair',[.4,.8,1,.9]))
for objects,label in [(eyes,'BlinkEyes'),(closed,'BlinkCrease')]:
    for o in objects:
        g=o.vertex_groups.new(name=label);g.add(list(range(len(o.data.vertices))),1,'REPLACE')
head=api['group']('Head',parts+eyes+closed,(0,0,1.19))
head.shape_key_add(name='Basis');blink=head.shape_key_add(name='Blink')
ei=head.vertex_groups['BlinkEyes'].index;ci=head.vertex_groups['BlinkCrease'].index
for v in head.data.vertices:
    groups={g.group for g in v.groups};p=blink.data[v.index].co
    if ei in groups:
        p.z=(1.775-1.19)+(p.z-(1.775-1.19))*.02;p.y=face_y(p.x,p.z+1.19,-.02)
    elif ci in groups:p.y=face_y(p.x,p.z+1.19,.018)
body_api['rig_export']('gunsmith',body,details,head,True)

if '--preview' in sys.argv:
    # Studio portrait uses the same authored mesh, with no model regeneration.
    for o in bpy.data.objects:
        if o.type=='MESH' and o.data.shape_keys:
            for k in o.data.shape_keys.key_blocks:k.value=0
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=40
    scene.render.resolution_x=1200;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
    scene.world.color=(.12,.12,.12)
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,.0))
    floor=bpy.context.object;floor.data.materials.append(api['material']('Backdrop','293C35'))
    def light(name,at,power,size):
        d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size
        o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.location=at
        o.rotation_euler=(Vector((0,0,1.2))-o.location).to_track_quat('-Z','Y').to_euler()
    light('Large softbox',(-3,-4,6),450,4);light('Fill',(3,-2,3),180,3);light('Rim',(1,3,4),500,3)
    bpy.ops.object.camera_add(location=(3.3,-6,3.05))
    cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.17))-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=3.05;scene.camera=cam
    scene.view_settings.view_transform='AgX'
    out=ROOT/'test-results/gunsmith';out.mkdir(parents=True,exist_ok=True)
    scene.render.filepath=str(out/'damiao-studio.png');bpy.ops.render.render(write_still=True)
print('GUNSMITH_ASSET_OK')
