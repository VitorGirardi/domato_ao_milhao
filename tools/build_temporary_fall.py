"""Blender-authored reusable impact, collapse and get-up curves (Godot model axes).
Run blender --background --python tools/build_temporary_fall.py.
The .blend contains editable actions, one collection per species; runtime samples
are exported as a GDScript resource so Godot packs them without export filters.
"""
import bpy, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
poses={
 'human': {'Spine':(.22,0,.18),'Chest':(-.12,0,.12),'Head':(.12,.1,-.18),'UpperArm.L':(-.55,0,.5),'UpperArm.R':(-.7,0,-.25),'Forearm.L':(-1.1,0,0),'Forearm.R':(-.8,0,0),'Thigh.L':(-.7,0,.18),'Thigh.R':(-.36,0,-.16),'Shin.L':(1.15,0,0),'Shin.R':(.8,0,0),'Foot.L':(-.2,0,0),'Foot.R':(-.25,0,0)},
 'horse':{'HorseNeck':(.32,0,.15),'HorseTail':(0,.15,.3),'FrontL':(-.8,0,-.12),'FrontR':(-.5,0,.1),'HindL':(.62,0,-.1),'HindR':(.45,0,.15),'FrontLLower':(1.3,0,0),'FrontRLower':(1.1,0,0),'HindLLower':(-1.1,0,0),'HindRLower':(-.9,0,0)},
 'cow':{'CowNeck':(.35,0,.1),'CowHead':(-.1,0,.18),'LegFL':(-.85,0,-.15),'LegFR':(-.55,0,.1),'LegBL':(.65,0,-.15),'LegBR':(.45,0,.12),'CowTail':(0,.3,.2)},
 'pig':{'PigHead':(.22,0,.17),'LegFL':(-.85,0,-.15),'LegFR':(-.55,0,.1),'LegBL':(.65,0,-.15),'LegBR':(.45,0,.12),'PigEarL':(0,0,-.3),'PigEarR':(0,0,.25)},
 'cat':{'CatHead':(.2,.1,.25),'CatLegFL':(-.8,0,-.1),'CatLegFR':(-.5,0,.1),'CatLegBL':(.8,0,-.1),'CatLegBR':(.6,0,.1),'CatShinFL':(.5,0,0),'CatShinFR':(.4,0,0),'CatShinBL':(-1.2,0,0),'CatShinBR':(-1,0,0),'CatEarL':(0,0,-.2),'CatEarR':(0,0,.2)},
 'chicken':{'LegL':(-1,0,-.2),'LegR':(-.8,0,.2)}
}
# Timeline: 0..30 collapse, 30..90 recover. Distinct recovery starts on
# the elbow / folded forelegs, then unfolds the knees before standing.
frames=[0,5,13,23,30,40,53,68,80,90]
weights=[0,-.18,.65,1.12,1,1,.8,.6,.25,0]
rolls=[0,-.08,.25,1.35,1.48,1.45,.72,.16,.02,0]
scene=bpy.context.scene;scene.render.fps=30;scene.frame_end=90
tracks={}
for index,(kind,bones) in enumerate(poses.items()):
 col=bpy.data.collections.new(kind);scene.collection.children.link(col)
 tracks[kind]={}
 for name,angles in {'ROOT':(0,0,1),**bones}.items():
  ob=bpy.data.objects.new(kind+'__'+name,None);col.objects.link(ob)
  ob.empty_display_type='ARROWS';ob.empty_display_size=.25;ob.location=(index*3,0,0)
  for frame,w,roll in zip(frames,weights,rolls):
   ob.rotation_euler=(0,0,roll) if name=='ROOT' else tuple(a*w for a in angles)
   ob.keyframe_insert('rotation_euler',frame=frame)
  tracks[kind][name]=ob
out={}
for kind,objects in tracks.items():
 out[kind]={}
 for name,ob in objects.items():
  samples=[]
  for f in range(91):
   scene.frame_set(f);samples.append([round(v,5) for v in ob.rotation_euler])
  out[kind][name]=samples
scene.frame_set(30)
(ROOT/'assets/animations').mkdir(exist_ok=True)
(ROOT/'assets/animations/temporary_fall.gd').write_text('extends RefCounted\n# Generated from editable Blender actions. 30 FPS; fall 0..30, recovery 30..90.\nconst DATA = '+json.dumps(out,separators=(',',':'))+'\n',encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/temporary_fall.blend'))
print('TEMPORARY_FALL_ACTIONS_OK: 6 species, 91 articulated frames each')
