"""Original cave helpers: editable Blender rigs, meter scale, glTF Y-up.
Run Blender --background --python-exit-code 1 --python tools/build_cave_helpers.py.
Runtime animates the named bones from travelled distance and mining phase.
References are anatomical/mood references only; no third-party meshes/textures.
"""
import bpy, math, random
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
QA=ROOT/'test-results/cave-helpers'; QA.mkdir(parents=True,exist_ok=True)
random.seed(5901)

def material(name,color,metal=0,emit=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if p is None:
        p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');out=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs['BSDF'],out.inputs['Surface'])
    p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.78;p.inputs['Metallic'].default_value=metal
    if emit:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emit
    return m

def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

for tier,name in enumerate(['grunho','ferrugem','vigia']):
    clear();pieces=[];specs=[]
    skin=material(name+' cave skin',[(.36,.31,.20),(.31,.39,.36),(.57,.60,.59)][tier])
    shell=material(name+' mineral carapace',[(.21,.24,.17),(.22,.19,.15),(.15,.18,.25)][tier])
    edge=material(name+' growth ridges',[(.53,.41,.20),(.49,.27,.13),(.33,.29,.47)][tier])
    dark=material(name+' mouth shadow',(.035,.039,.042));claw=material(name+' worn ivory',(.64,.63,.47))
    glow=material(name+' mineral glow',[(.86,.60,.16),(.33,.69,.49),(.49,.44,.89)][tier],0,.85)
    leather=material('Woven cave satchel',(.27,.18,.10))
    def finish(o,label,mat,bone):
        o.name=label;o.data.materials.append(mat)
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        o.vertex_groups.new(name=bone).add(list(range(len(o.data.vertices))),1,'REPLACE')
        pieces.append(o);return o
    def ico(label,at,size,mat,bone='Body',sub=2):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=at)
        o=bpy.context.object;o.scale=size
        return finish(o,label,mat,bone)
    def rod(label,a,b,r,r2,mat,bone):
        a,b=Vector(a),Vector(b);d=b-a
        bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=r,radius2=r2,depth=d.length,location=(a+b)/2)
        o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
        return finish(o,label,mat,bone)
    def bone(label,a,b,parent='Body'):specs.append((label,a,b,parent))
    hip=[.67,.80,1.05][tier];shoulder=[1.10,1.32,1.87][tier];head=[1.44,1.57,2.30][tier]
    width=[.48,.40,.28][tier];thick=[.23,.18,.095][tier]
    bone('Root',(0,0,0),(0,0,.25),None)
    bone('Body',(0,0,hip),(0,0,shoulder),'Root')
    bone('Head',(0,-.03,shoulder),(0,-.1,head),'Body')
    bone('Jaw',(0,-.25,head-.1),(0,-.50,head-.13),'Head')
    ico('Pear shaped torso',(0,.10,(hip+shoulder)/2),(width,.30,(shoulder-hip)/2+.26),skin)
    ico('Heavy forward brow',(0,-.13,head),([.39,.34,.29][tier],.30,[.28,.24,.36][tier]),skin,'Head')
    ico('Lower mandible',(0,-.25,head-.20),(.28,.22,.12),shell,'Jaw')
    ico('Deep mouth crease',(0,-.412,head-.10),(.25,.035,.085),dark,'Head')
    for j in range(5):
        x=(j-2)*.085
        rod('Uneven mineral tooth',(x,-.442,head-.065),(x*1.12,-.45,head-.15-(j%2)*.027),.03,.008,claw,'Jaw')
    if tier<2:
        for side in [-1,1]:
            ico('Recessed eye socket',(side*.19,-.373,head+.045),(.10,.055,.095),shell,'Head')
            ico('Small luminous eye',(side*.19,-.419,head+.045),(.046,.023,.057),glow,'Head')
            ico('Vertical pupil',(side*.19,-.44,head+.045),(.012,.008,.040),dark,'Head')
    else:
        # A smooth sealed face and sensory crest replace visible eyes.
        rod('Sealed face seam',(0,-.43,head-.03),(0,-.39,head+.25),.024,.013,shell,'Head')
        for side in [-1,1]:ico('Sensory pit',(side*.16,-.365,head+.04),(.065,.025,.034),dark,'Head')
    for row in range(4):
        z=hip+.16+row*(shoulder-hip)/3
        ico('Overlapping dorsal shell',(0,.29,z),(width*1.10,.19,.17),shell)
        for side in [-1,1]:
            rod('Asymmetric back spine',(side*width*.7,.33,z),(side*(width+.08),.40,z+.18+row*.025),.09,.012,edge,'Body')
    for suffix,sign in [('L',-1),('R',1)]:
        a=(sign*width*.72,.03,hip);k=(sign*(width+.03),-.12,hip*.48);f=(sign*(width+.02),-.05,.12)
        bone('Thigh.'+suffix,a,k);bone('Shin.'+suffix,k,f,'Thigh.'+suffix)
        bone('Foot.'+suffix,f,(f[0],-.32,.08),'Shin.'+suffix)
        ico('Hip joint '+suffix,a,(thick,thick,thick),skin,'Thigh.'+suffix)
        rod('Upper leg '+suffix,a,k,thick,thick*.65,skin,'Thigh.'+suffix)
        ico('Knee '+suffix,k,(thick*.72,thick*.70,thick*.74),edge,'Shin.'+suffix)
        rod('Lower leg '+suffix,k,f,thick*.62,thick*.43,skin,'Shin.'+suffix)
        ico('Broad sole '+suffix,(f[0],-.18,.09),(.19 if tier==0 else .14,.29,.09),shell,'Foot.'+suffix)
        for j in range(3):
            x=f[0]+(j-1)*.08
            rod('Ground claw',(x,-.33,.08),(x,-.47-(j%2)*.04,.035),.048,.006,claw,'Foot.'+suffix)
        a=(sign*(width+.02),-.02,shoulder);e=(sign*(width+.28),-.04,shoulder*.65);h=(sign*(width+.19),-.34,.53)
        bone('UpperArm.'+suffix,a,e);bone('Forearm.'+suffix,e,h,'UpperArm.'+suffix)
        bone('Hand.'+suffix,h,(h[0],h[1]-.16,h[2]-.14),'Forearm.'+suffix)
        ico('Shoulder '+suffix,a,(thick*1.05,thick,thick*1.1),shell,'UpperArm.'+suffix)
        rod('Upper arm '+suffix,a,e,thick*.85,thick*.55,skin,'UpperArm.'+suffix)
        ico('Elbow '+suffix,e,(thick*.6,thick*.6,thick*.6),edge,'Forearm.'+suffix)
        rod('Long forearm '+suffix,e,h,thick*.58,thick*.45,skin,'Forearm.'+suffix)
        ico('Digging palm '+suffix,h,(.19,.12,.17),shell,'Hand.'+suffix)
        for j in range(3):
            x=h[0]+(j-1)*.10;tip=(x+sign*.06,h[1]-.22,h[2]-.24-(j%2)*.06)
            rod('Hooked digging digit',(x,h[1]-.05,h[2]-.08),tip,.055,.012,claw,'Hand.'+suffix)
        feeler=(sign*.20,-.04,head+.18);end=(sign*(.40+tier*.14),.01,head+.42+tier*.13)
        bone('Feeler.'+suffix,feeler,end,'Head')
        rod('Long sensory stalk '+suffix,feeler,end,.07 if tier==0 else .035,.017,edge,'Feeler.'+suffix)
        ico('Feeler luminous tip '+suffix,end,(.06,.05,.075),glow,'Feeler.'+suffix,1)
        if tier>0:
            a=(sign*.30,.23,hip+.1);k=(sign*(.80+tier*.10),.48,hip*.55);f=(sign*(.86+tier*.10),.25,.065)
            bone('AuxThigh.'+suffix,a,k);bone('AuxShin.'+suffix,k,f,'AuxThigh.'+suffix)
            rod('Extra bracing limb '+suffix,a,k,.075,.04,shell,'AuxThigh.'+suffix)
            rod('Stilt foot '+suffix,k,f,.045,.014,claw,'AuxShin.'+suffix)
    ico('Ore pouch',(0,.43,hip+.13),(width*.8,.15,.25),leather)
    for i in range(3):ico('Mineral in pouch',((i-1)*.12,.48,hip+.34),(.09,.08,.10),glow,sub=1)
    data=bpy.data.armatures.new(name+' editable skeleton');rig=bpy.data.objects.new('CaveHelperRig',data);bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for label,a,b,parent in specs:
        n=data.edit_bones.new(label);n.head=a;n.tail=b
        if parent:n.parent=data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True
    for o in pieces:
        o.parent=rig;mod=o.modifiers.new('Cave creature skin','ARMATURE');mod.object=rig
    bpy.ops.object.select_all(action='DESELECT')
    for o in pieces:o.select_set(True)
    bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();body=bpy.context.object;body.name='CreatureSkin'
    bpy.ops.object.select_all(action='SELECT')
    rig['species']=name;rig['role']='Recruitable cave miner';rig['forward']='Blender -Y / Godot +Z'
    rig['animation']='Distance-driven gait, breathing, mining anticipation/impact/recovery and carrying in FarmCaveCreature'
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/('cave_helper_'+name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/('cave_helper_'+name+'.glb')),export_format='GLB',use_selection=True,export_apply=False,export_skins=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True)
    print('CAVE_HELPER_RIG_OK',name,'bones',len(specs),'vertices',len(body.data.vertices))
    # Ground-level three-quarter portrait from the same rigged asset.
    bpy.ops.mesh.primitive_plane_add(size=200);bpy.context.object.data.materials.append(material('Preview floor',(.075,.09,.10)))
    bpy.ops.object.camera_add(location=(4,-6,3.1));cam=bpy.context.object;target=Vector((0,0,head*.57));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.8;bpy.context.scene.camera=cam
    for at,power,color,size in [((-3,-4,6),700,(1,.78,.54),5),((3,2,4),950,(.4,.63,1),4)]:
        bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.color=color;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
    scene=bpy.context.scene;scene.world.color=(.12,.14,.18);scene.render.engine='CYCLES';scene.cycles.samples=24
    scene.render.resolution_x=800;scene.render.resolution_y=900;scene.render.resolution_percentage=100
    scene.render.filepath=str(QA/(name+'.png'));bpy.ops.render.render(write_still=True)

# Additional valuable veins, separate from all nine existing node identities.
for name,color,metal in [('gold',(.84,.55,.13),.65),('amethyst',(.50,.22,.79),.15)]:
    clear();rock=material('Rare vein basalt',(.17,.19,.23));ore=material(name+' exposed mineral',color,metal,.18 if name=='amethyst' else 0)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(0,0,.38));o=bpy.context.object;o.name='RareOreBoulder';o.scale=(.85,.62,.49);o.data.materials.append(rock)
    for i in range(9):
        x=random.uniform(-.57,.57);y=random.uniform(-.38,.32);z=.45+.32*math.sqrt(max(.1,1-x*x-y*y))
        if name=='amethyst':bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=.16,radius2=.015,depth=.45+i*.035,location=(x,y,z+.14))
        else:bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.17,location=(x,y,z))
        o=bpy.context.object;o.name=name+' mineral cluster';o.data.materials.append(ore)
    bpy.ops.object.select_all(action='SELECT');bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/('resource_ore_'+name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/('resource_ore_'+name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False)
print('CAVE_ASSETS_COMPLETE')
