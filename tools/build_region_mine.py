"""Editable original Serra mine entrance; run with Blender --background --python.
Blender -Y is the entrance/front (glTF +Z). Separate MineBarrier is removable.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R = Path(__file__).resolve().parents[1]
random.seed(471)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def mat(name, color):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    n=m.node_tree.nodes.get('Principled BSDF')
    if n is None:
        n=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
        out=next((x for x in m.node_tree.nodes if x.type=='OUTPUT_MATERIAL'),None) or m.node_tree.nodes.new('ShaderNodeOutputMaterial')
        m.node_tree.links.new(n.outputs['BSDF'],out.inputs['Surface'])
    n.inputs['Base Color'].default_value=(*color,1); n.inputs['Roughness'].default_value=.92
    return m
stone=[mat('Warm limestone',(.34,.35,.28)),mat('Sunlit limestone',(.45,.45,.35)),mat('Ochre limestone',(.38,.36,.26)),mat('Cool limestone',(.27,.30,.26))]
inner=mat('Cave shaded rock',(.085,.105,.09)); earth=mat('Mineral earth',(.22,.17,.105))
green=[mat('Moss sage',(.17,.29,.072)),mat('Moss deep',(.095,.20,.045))]
yellow=mat('Warning golden yellow',(.98,.66,.055)); black=mat('Warning charcoal',(.035,.042,.035)); wood=mat('Weathered posts',(.22,.13,.055))
root=bpy.data.objects.new('RegionMine',None); bpy.context.collection.objects.link(root)
barrier=bpy.data.objects.new('MineBarrier',None); bpy.context.collection.objects.link(barrier); barrier.parent=root

def mesh(name,vs,fs,materials,parent=root):
    data=bpy.data.meshes.new(name); data.from_pydata(vs,[],fs); data.materials.clear()
    for m in materials:data.materials.append(m)
    o=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(o); o.parent=parent
    return o

def rock(name,p,s,material,sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=p)
    o=bpy.context.object; o.name=name; o.scale=s; o.parent=root
    for v in o.data.vertices:v.co*=random.uniform(.90,1.10)
    o.data.materials.append(material)
    bevel=o.modifiers.new('Soft stone edges','BEVEL');bevel.width=.065;bevel.segments=1
    return o

# A continuous open horseshoe passage: irregular mouth, shrinking recessed tunnel.
N=21
rings=[]
for depth,rx,h in [(0,3.65,5.25),(2.8,3.55,5.05),(6.2,3.0,4.7),(10.8,2.45,4.1)]:
    ring=[]
    for i in range(N):
        t=math.pi*i/(N-1); jitter=1+.055*math.sin(i*3.7+depth)
        ring.append((math.cos(t)*rx*jitter,depth+.10*math.sin(i*2.7),max(0,math.sin(t)*h*jitter)))
    rings.append(ring)
vs=[v for ring in rings for v in ring];fs=[]
for d in range(3):
    for i in range(N-1):
        a=d*N+i;fs.append((a,a+N,a+N+1,a+1))
# Explicit inner normals face into passage; glTF materials remain double-sided.
tunnel=mesh('Continuous carved tunnel',vs,fs,[inner])
# Front cliff blends into outer contours, leaving a genuine clear arch.
outer=[]
for i in range(N):
    t=math.pi*i/(N-1)
    outer.append((math.cos(t)*8.0,.65+math.sin(i*1.7)*.4,math.sin(t)*9.3))
front=mesh('Irregular cliff facade',rings[0]+outer,[(i,i+1,N+i+1,N+i) for i in range(N-1)],stone)
for p in front.data.polygons:p.material_index=random.randrange(len(stone))
# Upper/back shell seals top while preserving the tunnel.
back=[(x*.82,11.6,z*.79) for x,y,z in outer]
mid=[(x*1.025,5.7+math.sin(i*2.1)*.45,z*(.98+.045*math.sin(i*1.9))) for i,(x,y,z) in enumerate(outer)]
shell=mesh('Cliff crown shell',outer+mid+back,[(d*N+i,(d+1)*N+i,(d+1)*N+i+1,d*N+i+1) for d in range(2) for i in range(N-1)],stone)
for f in shell.data.polygons:f.material_index=random.choice([0,0,2,3])
mesh('Deep passage back wall',[(-2.45,11,0),(2.45,11,0),(2.45,11,4.5),(-2.45,11,4.5)],[(0,1,2,3)],[inner])
mesh('Passage earth floor',[(-3.7,-1,0),(3.7,-1,0),(3.2,6.2,0),(2.45,11.3,0),(-2.45,11.3,0),(-3.2,6.2,0)],[(0,1,2,3,4,5)],[earth])
for v in bpy.data.objects['Passage earth floor'].data.vertices:v.co.z=.025
# Broad asymmetric strata outcrops, kept outside the playable opening.
for i in range(19):
    t=.05+(math.pi-.1)*i/18
    x=math.cos(t)*5.7; z=.2+math.sin(t)*7.25
    s=(random.uniform(1.05,1.85),random.uniform(.7,1.3),random.uniform(1.05,1.7))
    rock('Limestone outcrop %02d'%i,(x,random.uniform(.35,1.5),z),s,stone[i%4])
for side in [-1,1]:
    for i in range(5):
        rock('Side buttress',(side*(6.1+random.uniform(0,.3)),2.2+i*1.9,1.6+random.uniform(0,.5)),(1.5,1.6,2.0),stone[i%4])
# Moss hugs selected cliff surfaces; bushes at feet do not obstruct mouth.
for i in range(28):
    t=random.uniform(.13,math.pi-.13); x=math.cos(t)*random.uniform(5.6,6.7);z=math.sin(t)*7.9+.1
    rock('Moss cushion',(x,-.15,z),(.65,.35,.28),green[i%2],1)
for side in [-1,1]:
    for i in range(8):
        x=side*random.uniform(4.6,7.1); y=random.uniform(-.7,1.2)
        rock('Fern bank',(x,y,.28),(.7,.65,.4),green[i%2],1)
        # Several fine leaf blades create readable vegetation silhouettes.
        for j in range(5):
            a=j*math.tau/5;h=random.uniform(.35,.8)
            mesh('Fern blade',[(x-.025,y,.12),(x+.025,y,.12),(x+math.cos(a)*.48,y+math.sin(a)*.48,h)],[(0,1,2)],[green[j%2]])
for i in range(15):
    side=-1 if i%2 else 1
    rock('Loose threshold stone',(side*random.uniform(3.65,5.1),random.uniform(-.5,1.8),.15),(.3,.27,.22),stone[i%4],1)

def beam(name,a,b,r,material):
    delta=Vector(b)-Vector(a)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=r,depth=delta.length,location=(Vector(a)+Vector(b))*.5)
    o=bpy.context.object;o.name=name;o.rotation_euler=delta.to_track_quat('Z','Y').to_euler();o.parent=barrier;o.data.materials.append(material)
for x in [-3.35,3.35]:beam('Barrier post',(x,-.4,0),(x,-.4,2.25),.1,wood)
# Two yellow ribbons with black diagonal bands; all nested under MineBarrier.
for row in [0,1]:
    def ribbon_z(x):return 1.05+row*.73+(.07 if row==0 else -.055)*x-.10*(1-(x/3.35)**2)
    for j in range(30):
        a=-3.35+j*6.7/30;b=-3.35+(j+1)*6.7/30
        mesh('Warning tape',[(a,-.44,ribbon_z(a)),(b,-.44,ribbon_z(b)),(b,-.44,ribbon_z(b)+.17),(a,-.44,ribbon_z(a)+.17)],[(0,1,2,3)],[yellow],barrier)
    for j in range(14):
        a=-3.25+j*.48;b=a+.18
        mesh('Black warning stripe',[(a,-.451,ribbon_z(a)),(b,-.451,ribbon_z(b)),(b+.12,-.451,ribbon_z(b+.12)+.17),(a+.12,-.451,ribbon_z(a+.12)+.17)],[(0,1,2,3)],[black],barrier)
# Apply scales before exporting, keep useful hierarchy (especially purchase barrier).
for o in list(bpy.context.scene.objects):
    if o.type=='MESH':
        bpy.context.view_layer.objects.active=o;o.select_set(True)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        o.select_set(False)
# Merge geometry into two render meshes while preserving the removable barrier.
for parent,name in [(root,'MineRockAndVegetation'),(barrier,'MineBarrierMesh')]:
    bpy.ops.object.select_all(action='DESELECT')
    parts=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==parent]
    for o in parts:
        bpy.context.view_layer.objects.active=o
        for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
        o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
    bpy.context.object.name=name
assets=[o for o in bpy.context.scene.objects]
for o in assets:o.select_set(True)
(R/'art/source').mkdir(parents=True,exist_ok=True)
(R/'assets/models').mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'art/source/region_mine.blend'))
bpy.ops.export_scene.gltf(filepath=str(R/'assets/models/region_mine.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
points=[o.matrix_world@Vector(v) for o in assets if o.type=='MESH' for v in o.bound_box]
print('MINE_BLENDER_BOUNDS',[(min(p[i] for p in points),max(p[i] for p in points)) for i in range(3)])
print('MINE_TRIANGLES_BASE',sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in assets if o.type=='MESH'))
# Preview only, not part of the exported model.
bpy.ops.mesh.primitive_plane_add(size=200);bpy.context.object.data.materials.append(mat('Preview meadow',(.22,.33,.115)))
bpy.ops.object.camera_add(location=(16,-25,13));cam=bpy.context.object;cam.rotation_euler=(Vector((0,2,3.8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=24;bpy.context.scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(-6,-10,16));bpy.context.object.data.energy=2400;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=12
bpy.ops.object.light_add(type='SUN',location=(0,0,15));bpy.context.object.rotation_euler=(.45,-.5,-.6);bpy.context.object.data.energy=2
scene=bpy.context.scene;scene.world.color=(.32,.45,.62);scene.render.engine='CYCLES';scene.cycles.samples=24
scene.render.resolution_x=1100;scene.render.resolution_y=850;scene.render.resolution_percentage=100
scene.render.filepath=str(R/'region_mine_preview.png');bpy.ops.render.render(write_still=True)
