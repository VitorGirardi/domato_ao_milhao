"""Editable Blender car entry body poses, sampled to Godot model-space angles."""
import bpy, json
from pathlib import Path
from mathutils import Quaternion
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.fps=30;scene.frame_end=90
names=['Spine','Chest','Head']+[b+'.'+s for s in ['L','R'] for b in ['UpperArm','Forearm','Thigh','Shin','Foot']]
controls={}
for name in names:
    ob=bpy.data.objects.new('Control '+name,None);scene.collection.objects.link(ob);controls[name]=ob
    ob['units']='Godot model space XYZ angles in radians'
    for frame in [0,18,32,48,65,78,90]:
        t=frame/90;seat=max(0,min(1,(t-.35)/.35));duck=max(0,1-abs(t-.5)/.25)
        xyz=[0.,0.,0.]
        if name=='Spine':xyz=[.06*seat+.28*duck,-.12*duck,0.]
        if name=='Chest':xyz=[.1*duck,0.,0.]
        if name=='Head':xyz=[-.15*duck,0.,0.]
        leg=max(0,min(1,seat+(.22 if name.endswith('R') else -.16)*duck))
        if name.startswith('Thigh'):xyz=[-1.3*leg-.35*duck,0.,(-.1 if name.endswith('L') else .1)*seat]
        if name.startswith('Shin'):xyz=[1.5*leg+.45*duck,0.,0.]
        if name.startswith('Foot'):xyz=[-.15*seat,0.,0.]
        if name.startswith('UpperArm'):xyz=[-.6*seat-.3*duck,0.,(.2 if name.endswith('L') else -.2)]
        if name.startswith('Forearm'):xyz=[-.2-.8*seat,0.,0.]
        ob.location=xyz;ob.keyframe_insert('location',frame=frame)
    for curve in ob.animation_data.action.layers[0].strips[0].channelbags[0].fcurves:
        for key in curve.keyframe_points:
            key.interpolation='BEZIER';key.handle_left_type='AUTO_CLAMPED';key.handle_right_type='AUTO_CLAMPED'
frames=[]
for frame in range(91):
    scene.frame_set(frame);frames.append({n:[round(v,6) for v in o.location] for n,o in controls.items()})
for person,offset in [('farmer',-1.5),('farmer_woman',1.5)]:
    with bpy.data.libraries.load(str(ROOT/'art/source'/f'{person}.blend'),link=False) as (source,target):target.objects=source.objects
    objects=[o for o in target.objects if o and o.type in {'ARMATURE','MESH'}]
    for ob in objects:
        scene.collection.objects.link(ob)
        if ob.parent is None:ob.location.x+=offset
    rig=next(o for o in objects if o.type=='ARMATURE');rig.animation_data_clear()
    for frame,angles in enumerate(frames):
        for name,xyz in angles.items():
            rest=rig.data.bones[name].matrix_local.to_quaternion()
            q=Quaternion((1,0,0),xyz[0])@Quaternion((0,0,1),xyz[1])@Quaternion((0,-1,0),xyz[2])
            bone=rig.pose.bones[name];bone.rotation_mode='QUATERNION';bone.rotation_quaternion=rest.inverted()@q@rest
            bone.keyframe_insert('rotation_quaternion',frame=frame,group=name)
    rig.animation_data.action.name=person+' vehicle entry';rig.animation_data.action.use_fake_user=True
scene.frame_set(48)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/vehicle_entry.blend'))
(ROOT/'assets/animations/vehicle_entry.gd').write_text('extends RefCounted\nconst FRAMES = '+json.dumps(frames,separators=(',',':'))+'\n',encoding='utf8')
print('VEHICLE_ENTRY_BLENDER_OK')
