"""Continuous quad body topology and a deforming humanoid armature.

Shoulder openings and the crotch share vertices with their limb loops. Clothing
boundaries are material regions on that same surface, not disconnected balls.
"""
import bpy
import bmesh
import math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]

def smooth(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)))
    return t*t*(3-2*t)

def build_body(api,zeca):
    wide=1.35 if zeca else 1.0
    verts=[]; faces=[]; colors=[]
    def vert(co):
        verts.append(tuple(co)); return len(verts)-1
    def face(indices,color):
        faces.append(tuple(indices)); colors.append(color)
    def bridge(a,b,color):
        assert len(a)==len(b)
        for i in range(len(a)): face((a[i],a[(i+1)%len(a)],b[(i+1)%len(b)],b[i]),color)
    profile=[(.97,.27,.155),(1.045,.275,.16),(1.13,.25,.15),
             (1.23,.245,.15),(1.35,.28,.165),(1.48,.30,.165),
             (1.58,.305,.15),(1.68,.26,.115),(1.735,.105,.09),(1.81,.097,.087)]
    if zeca:
        profile=[(.97,.30,.19),(1.045,.33,.215),(1.13,.35,.24),
                 (1.23,.355,.25),(1.35,.34,.235),(1.48,.31,.19),
                 (1.58,.305,.16),(1.68,.26,.12),(1.735,.105,.09),(1.81,.097,.087)]
    torso=[]
    for z,rx,ry in profile:
        depth=ry*(1.27 if zeca and z<1.4 else wide)
        torso.append([vert((rx*wide*math.cos(math.tau*i/16),depth*math.sin(math.tau*i/16),z)) for i in range(16)])
    for j in range(len(torso)-1):
        for i in range(16):
            # Each shoulder is a 4 x 2 quad opening, bounded by twelve vertices.
            if j in [5,6] and i in [14,15,0,1,6,7,8,9]: continue
            ids=(torso[j][i],torso[j][(i+1)%16],torso[j+1][(i+1)%16],torso[j+1][i])
            center=sum((Vector(verts[k]) for k in ids),Vector())/4
            x,y,z=center
            color='Shirt'
            if z<1.20: color='Denim'
            if z<1.51 and y<-.045 and abs(x)<.21*wide: color='Denim'
            if 1.20<z<1.66 and .14*wide<abs(x)<.225*wide and abs(y)>.04: color='Denim'
            if z>1.70: color='Skin'
            face(ids,color)
    face(tuple(reversed(torso[-1])),'Skin')
    # Arms: shoulder -> upper arm -> elbow supports -> wrist -> palm -> fingers.
    for side,sign,center_index in [('R',1,0),('L',-1,8)]:
        indices=[(center_index+sign*k)%16 for k in [-2,-1,0,1,2]]
        root=[torso[7][i] for i in indices]+[torso[6][indices[-1]]]+[torso[5][i] for i in reversed(indices)]+[torso[6][indices[0]]]
        assert len(root)==12
        previous=root
        arms=[(.34,0,1.585,.103,.102),(.375,0,1.49,.094,.092),
              (.397,-.004,1.415,.086,.083),(.41,-.008,1.385,.073,.072),
              (.423,-.011,1.345,.070,.068),(.437,-.014,1.305,.071,.066),
              (.461,-.024,1.235,.075,.064),(.485,-.031,1.15,.059,.052),
              (.5,-.035,1.105,.052,.044),(.511,-.043,1.074,.052,.044),
              (.525,-.063,1.02,.061,.04),(.540,-.075,.963,.06,.040),
              (.547,-.08,.935,.032,.027)]
        palm=None; knuckles=None
        for r,(x,y,z,ru,rv) in enumerate(arms):
            # Surface normals across the arm follow its inclined longitudinal axis.
            u=Vector((sign*.91,0,.415))
            v=Vector((0,1,0))
            center=Vector((sign*x*wide,y,z))
            ring=[vert(center+u*(ru*math.cos(-math.pi/3+math.tau*i/12))+v*(rv*math.sin(-math.pi/3+math.tau*i/12))) for i in range(12)]
            color='Shirt' if z>=1.415 else ('Glove' if z<1.074 and not zeca else 'Skin')
            if r==11:
                # Leave a single palm-side opening for an integrated thumb.
                for i in range(12):
                    if i!=8: face((previous[i],previous[(i+1)%12],ring[(i+1)%12],ring[i]),color)
                palm=previous; knuckles=ring
            else: bridge(previous,ring,color)
            previous=ring
        face(tuple(reversed(previous)),'Skin' if zeca else 'Glove')
        boundary=[palm[8],palm[9],knuckles[9],knuckles[8]]
        center=sum((Vector(verts[i]) for i in boundary),Vector())/4
        previous=boundary
        for step,scale in [(Vector((-sign*.045,-.024,.038)),.78),(Vector((-sign*.078,-.033,.03)),.40)]:
            ring=[vert(center+step+(Vector(verts[i])-center)*scale) for i in boundary]
            bridge(previous,ring,'Skin' if zeca else 'Glove'); previous=ring
        face(tuple(reversed(previous)),'Skin' if zeca else 'Glove')
    # A shared crotch chain divides the hip opening into two leg openings.
    crotch_front=vert((0,-.065,.925)); crotch_mid=vert((0,0,.90)); crotch_back=vert((0,.065,.925))
    leg_angles=[-math.pi/2+math.pi*i/8 for i in range(9)]+[3*math.pi/4,math.pi,5*math.pi/4]
    for sign in [-1,1]:
        outer=[torso[0][(12+sign*i)%16] for i in range(9)]
        previous=outer+[crotch_back,crotch_mid,crotch_front]
        legs=[(.155,0,.865,.125,.136),(.165,0,.76,.116,.125),
              (.164,-.01,.64,.097,.106),(.16,-.022,.59,.087,.096),
              (.16,-.026,.545,.085,.09),(.16,-.014,.50,.087,.088),
              (.161,.007,.40,.092,.087),(.161,.009,.31,.082,.073),
              (.161,.007,.26,.079,.072),(.161,0,.23,.085,.080),
              (.161,-.027,.185,.094,.12),(.161,-.062,.12,.106,.166),
              (.161,-.067,.065,.110,.170),(.161,-.067,.027,.110,.169)]
        for x,y,z,rx,ry in legs:
            center=Vector((sign*x*wide,y,z))
            ring=[vert(center+Vector((sign*rx*math.cos(a),ry*math.sin(a),0))) for a in leg_angles]
            color='Denim' if z>=.26 else ('Seam' if z>=.23 else ('Sole' if z<.065 else 'Boot'))
            bridge(previous,ring,color); previous=ring
        face(tuple(reversed(previous)),'Sole')
    data=bpy.data.meshes.new('ContinuousBody_Quads')
    data.from_pydata(verts,[],faces); data.update()
    body=bpy.data.objects.new('BodySkin',data); bpy.context.collection.objects.link(body)
    names=list(api['M'])
    for key in names: data.materials.append(api['M'][key])
    for poly,color in zip(data.polygons,colors): poly.material_index=names.index(color); poly.use_smooth=True
    bm=bmesh.new(); bm.from_mesh(data)
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges), 'Body contains an open seam'
    reached=set(); pending=[next(iter(bm.verts))]
    while pending:
        v=pending.pop()
        if v in reached: continue
        reached.add(v); pending.extend(e.other_vert(v) for e in v.link_edges)
    assert len(reached)==len(bm.verts), 'Body has disconnected components'
    bm.to_mesh(data); bm.free()
    core_positions={tuple(round(c,6) for c in verts[i]) for ring in torso for i in ring}
    core_group=body.vertex_groups.new(name='TorsoTopology')
    for vertex in data.vertices:
        if tuple(round(c,6) for c in vertex.co) in core_positions:
            core_group.add([vertex.index],1,'REPLACE')
    body['continuous_components']=1
    body['closed_manifold']=True
    body['design']='Connected shoulders, torso, hips and limbs; supporting loops at elbows and knees'
    subdiv=body.modifiers.new('Smooth continuous quad surface','SUBSURF')
    subdiv.levels=2; subdiv.render_levels=2
    # Small clothing details follow the same weight field as the body beneath.
    details=[]
    depth=.292 if zeca else .172
    details.append(api['box']('Flat chest pocket',(0,-depth-.009,1.405),(.19,.018,.145),'Denim',.025))
    for sign in [-1,1]:
        details.append(api['ellipsoid']('Overall fastener',(sign*.145*wide,-.157*wide,1.51),(.020,.009,.020),'Gold',rings=8,segments=12))
        for z in [.145,.174]:
            x=sign*.161*wide
            details.append(api['tube']('Boot lace',[(x-.058,-.16,z),(x,-.175,z-.008),(x+.058,-.16,z)],.005,'Band'))
    return body,details

def weights(co,zeca,torso=False):
    x,y,z=co; wide=1.35 if zeca else 1.0
    sign='R' if x>=0 else 'L'; ax=abs(x)/wide
    if z<1.04:
        if ax>.39: return {'Hand.'+sign:1.0}
        if z>.835:
            t=(1-smooth(.84,1.08,z))*smooth(.015,.16,ax)
            return {'Pelvis':1-t,'Thigh.'+sign:t}
        if z>.645: return {'Thigh.'+sign:1.0}
        if z>.445:
            t=smooth(.445,.645,z)
            return {'Thigh.'+sign:t,'Shin.'+sign:1-t}
        if z>.29: return {'Shin.'+sign:1.0}
        t=smooth(.14,.29,z)
        return {'Shin.'+sign:t,'Foot.'+sign:1-t}
    arm_threshold=.22
    if not torso and ax>arm_threshold and z<1.70:
        if z>1.45:
            t=smooth(.245,.355,ax)
            return {'Clavicle.'+sign:1-t,'UpperArm.'+sign:t}
        if z>1.245:
            t=smooth(1.245,1.405,z)
            return {'UpperArm.'+sign:t,'Forearm.'+sign:1-t}
        t=smooth(1.055,1.155,z)
        return {'Forearm.'+sign:t,'Hand.'+sign:1-t}
    if z>1.72:
        t=smooth(1.73,1.81,z)
        return {'Neck':1-t,'Head':t}
    if z>1.60:
        t=smooth(1.60,1.73,z)
        return {'Chest':1-t,'Neck':t}
    if z>1.30:
        t=smooth(1.30,1.49,z)
        base={'Spine':1-t,'Chest':t}
        shoulder=smooth(.19,.30,ax)*smooth(1.38,1.52,z)
        return {**{k:v*(1-shoulder) for k,v in base.items()},'Clavicle.'+sign:shoulder}
    t=smooth(1.065,1.30,z)
    return {'Pelvis':1-t,'Spine':t}

def rig_export(name,body,details,head,zeca):
    wide=1.35 if zeca else 1.0
    # Keep the cartoon face but give the body room for human limb proportions.
    head.scale=(.73,)*3; head.location=(0,0,1.74)
    bpy.ops.object.select_all(action='DESELECT'); head.select_set(True)
    bpy.context.view_layer.objects.active=head
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    head.name='HeadSkin'
    arm_data=bpy.data.armatures.new('FarmerHumanoid')
    arm=bpy.data.objects.new('CharacterRig',arm_data)
    bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active=arm
    arm.select_set(True); head.select_set(False)
    bpy.ops.object.mode_set(mode='EDIT')
    specs=[('Root',(0,0,0),(0,0,.18),None),
           ('Pelvis',(0,0,.97),(0,0,1.15),'Root'),
           ('Spine',(0,0,1.15),(0,0,1.42),'Pelvis'),
           ('Chest',(0,0,1.42),(0,0,1.64),'Spine'),
           ('Neck',(0,0,1.64),(0,0,1.79),'Chest'),
           ('Head',(0,0,1.79),(0,0,2.18),'Neck')]
    for suffix,sign in [('L',-1),('R',1)]:
        def point(x,y,z): return (sign*x*wide,y,z)
        specs.extend([
            ('Clavicle.'+suffix,point(.06,0,1.61),point(.30,0,1.59),'Chest'),
            ('UpperArm.'+suffix,point(.30,0,1.59),point(.43,-.01,1.325),'Clavicle.'+suffix),
            ('Forearm.'+suffix,point(.43,-.01,1.325),point(.50,-.035,1.105),'UpperArm.'+suffix),
            ('Hand.'+suffix,point(.50,-.035,1.105),point(.547,-.08,.94),'Forearm.'+suffix),
            ('Thigh.'+suffix,point(.155,0,.97),point(.16,-.026,.545),'Pelvis'),
            ('Shin.'+suffix,point(.16,-.026,.545),point(.161,0,.19),'Thigh.'+suffix),
            ('Foot.'+suffix,point(.161,0,.19),point(.161,-.16,.085),'Shin.'+suffix)])
    for bone_name,start,end,parent in specs:
        bone=arm_data.edit_bones.new(bone_name); bone.head=start; bone.tail=end
        if parent: bone.parent=arm_data.edit_bones[parent]
        bone.use_deform=True
    bpy.ops.object.mode_set(mode='OBJECT')
    arm.show_in_front=True
    for obj in [body,*details,head]:
        for bone_name,_,_,_ in specs: obj.vertex_groups.new(name=bone_name)
        for vertex in obj.data.vertices:
            core=obj.vertex_groups.get('TorsoTopology')
            is_core=core is not None and any(g.group==core.index for g in vertex.groups)
            assignment={'Head':1.0} if obj==head else weights(obj.matrix_world@vertex.co,zeca,is_core)
            assignment={key:value for key,value in assignment.items() if value>0.000001}
            total=sum(assignment.values())
            assert total>0 and len(assignment)<=4
            for key,value in assignment.items(): obj.vertex_groups[key].add([vertex.index],value/total,'REPLACE')
        modifier=obj.modifiers.new('Humanoid skin deformation','ARMATURE'); modifier.object=arm
        # Godot's standard GLB path uses linear skinning: preview that same method.
        modifier.use_deform_preserve_volume=False
        obj.parent=arm
    arm['rig_version']=2
    arm['animation_axes']='Runtime converts model-space axes through each global bone rest basis'
    bpy.context.view_layer.objects.active=body
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{name}.glb'),export_format='GLB',
        use_selection=True,export_apply=True,export_skins=True,export_animations=False,
        export_cameras=False,export_lights=False,export_yup=True)
    print('RIGGED_CHARACTER_OK',name,'bones',len(specs),'body_control_vertices',len(body.data.vertices),'manifold',True,'components',1)
