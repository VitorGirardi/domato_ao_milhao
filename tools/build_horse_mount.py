"""Editable Blender mount controls, sampled into Godot model-axis poses."""
import bpy, json
from pathlib import Path
from mathutils import Quaternion
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.fps=30;scene.frame_end=48
BONES=['Pelvis','Spine','Chest','Neck','Head']+[b+'.'+s for s in ['L','R'] for b in ['Clavicle','UpperArm','Forearm','Hand','Thigh','Shin','Foot']]
def pose(stage):
    p={n:[0.,0.,0.] for n in BONES}
    for s,sign in [('L',-1),('R',1)]:
        p['UpperArm.'+s]=[-.60,0,-sign*.45];p['Forearm.'+s]=[-.85,0,0]
        p['Thigh.'+s]=[-.72,0,sign*.85];p['Shin.'+s]=[1.05,0,0];p['Foot.'+s]=[-.38,0,0]
    p['Spine']=[.08,0,0]
    if stage==0:
        for s,sign in [('L',-1),('R',1)]:
            p['UpperArm.'+s]=[0,0,-sign*.19];p['Forearm.'+s]=[-.18,0,0]
            p['Thigh.'+s]=[0,0,0];p['Shin.'+s]=[.02,0,0];p['Foot.'+s]=[-.02,0,0]
        p['Spine']=[0,0,0]
    if stage in [1,2]:
        p['Spine']=[.20,-.15,-.10];p['Chest']=[.06,-.08,0]
        p['Thigh.L']=[-1.00,0,-.28];p['Shin.L']=[1.35,0,0];p['Foot.L']=[-.35,0,0]
        p['Thigh.R']=[.10,0,.06];p['Shin.R']=[.20,0,0];p['Foot.R']=[-.15,0,0]
        if stage==2:
            p['Thigh.L']=[-.45,0,-.35];p['Shin.L']=[.70,0,0]
            p['Thigh.R']=[.30,-.25,1.35];p['Shin.R']=[.70,0,0]
    if stage==3:
        p['Spine']=[.24,0,-.09];p['Thigh.R']=[-.25,-.25,1.15];p['Shin.R']=[.90,0,0]
    return p
keys=[0,12,26,36,48]
roots=[[-1.22,0,-.10],[-.98,.10,-.10],[-.55,.80,-.12],[-.20,1.20,-.08],[0,1.04,-.04]]
controls={}
for n in BONES+['Travel','Facing']:
    ob=bpy.data.objects.new('CONTROL '+n,None);scene.collection.objects.link(ob);controls[n]=ob
    ob['meaning']='Godot XYZ position' if n=='Travel' else 'Godot model-axis XYZ rotation radians'
    for stage,frame in enumerate(keys):
        ob.location=roots[stage] if n=='Travel' else ([0,[0,1.570796,.75,.2,0][stage],0] if n=='Facing' else pose(stage)[n]);ob.keyframe_insert('location',frame=frame)
    for curve in ob.animation_data.action.layers[0].strips[0].channelbags[0].fcurves:
        for k in curve.keyframe_points:k.interpolation='BEZIER';k.handle_left_type='AUTO_CLAMPED';k.handle_right_type='AUTO_CLAMPED'
frames=[]
for frame in range(49):
    scene.frame_set(frame);frames.append({n:[round(v,6) for v in ob.location] for n,ob in controls.items()})
for person,offset in [('farmer',-2),('farmer_woman',2)]:
    with bpy.data.libraries.load(str(ROOT/'art/source'/f'{person}.blend'),link=False) as (src,dst):dst.objects=src.objects
    objects=[o for o in dst.objects if o and o.type not in {'CAMERA','LIGHT'}]
    for ob in objects:scene.collection.objects.link(ob)
    rig=next(o for o in objects if o.type=='ARMATURE')
    rig.animation_data_clear();rig['README']='Mount 0-48, reverse for dismount. Left foot receives weight before right leg sweeps saddle.'
    for i,values in enumerate(frames):
        for name in BONES:
            xyz=values[name];rest=rig.data.bones[name].matrix_local.to_quaternion()
            q=Quaternion((1,0,0),xyz[0])@Quaternion((0,0,1),xyz[1])@Quaternion((0,-1,0),xyz[2])
            bone=rig.pose.bones[name];bone.rotation_mode='QUATERNION';bone.rotation_quaternion=rest.inverted()@q@rest;bone.keyframe_insert('rotation_quaternion',frame=i,group=name)
        x,y,z=values['Travel'];rig.location=(x+offset,-z,y);rig.keyframe_insert('location',frame=i)
        rig.rotation_euler.z=values['Facing'][1];rig.keyframe_insert('rotation_euler',frame=i)
    rig.animation_data.action.name=person+' Mount and reverse dismount';rig.animation_data.action.use_fake_user=True
scene.frame_set(26)
scene['README']='Editable angle controls and baked male/female actions. Runtime mirrors for right side, solves hand grips, and adapts path to collision-checked ground.'
(ROOT/'assets/animations/horse_mount.gd').write_text('extends RefCounted\n# Sampled from Blender editable controls.\nconst DATA = '+json.dumps({'duration':1.6,'frames':frames},separators=(',',':'))+'\n',encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/horse_mount.blend'))
print('HORSE_MOUNT_BLENDER_OK')
