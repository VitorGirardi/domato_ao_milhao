"""Original modular pig enclosure. Blender Z-up, entrance -Y (Godot +Z).

Visual assets only: no economy, collision or navigation behavior is embedded.
Run Blender --background --python tools/build_pigsty.py to rebuild the five GLBs.
"""
import bpy
import math
import runpy
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
a=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
for key,color in {'Wood':'AC7950','LightWood':'CDA579','DarkWood':'74513C',
                  'Roof':'AE5948','RoofEdge':'D28260','Metal':'515E5B',
                  'Grain':'D4AB54','GrainLight':'EAD084','Straw':'C4A463',
                  'Stone':'8E9B94','Water':'66B3B6','WaterLight':'A6D7CB',
                  'Mud':'6D5140','WetMud':'83634B','Soil':'A08760',
                  'Pink':'DBA08A','Nostril':'965F55'}.items():
    a['M'][key]=a['material']('Pigsty_'+key,color)
for key,roughness in [('Water',.24),('WetMud',.42)]:
    shader=next(node for node in a['M'][key].node_tree.nodes if node.type=='BSDF_PRINCIPLED')
    shader.inputs['Roughness'].default_value=roughness
b,e,t=a['box'],a['ellipsoid'],a['tube']

def empty(name,at=(0,0,0)):
    node=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(node)
    node.location=at
    return node

def parent(objects,node):
    bpy.context.view_layer.update()
    for obj in objects:
        matrix=obj.matrix_world.copy();obj.parent=node
        obj.matrix_parent_inverse=Matrix.Identity(4)
        obj.matrix_basis=node.matrix_world.inverted()@matrix

def batch(name,objects):
    return a['group'](name,objects,(0,0,0))

def beam(name,start,end,width,depth,key):
    direction=Vector(end)-Vector(start)
    obj=b(name,(Vector(start)+Vector(end))*.5,(width,depth,direction.length),key,.015)
    obj.rotation_euler=direction.to_track_quat('Z','Y').to_euler()
    return obj

def roof_panel(name,side,y,width,z_offset,key):
    # Explicit world-space corners avoid the roll ambiguity of a tracked beam.
    verts=[]
    for lower in [0,-.06]:
        for x,z in [(side*1.76,1.86),(0,2.46)]:
            for edge in [-1,1]:verts.append((x,y+edge*width*.5,z+z_offset+lower))
    faces=[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]
    # Mirror the left panel's winding along with its position.
    if side==1:faces=[tuple(reversed(face)) for face in faces]
    return a['mesh'](name,verts,faces,key,smooth=False)

def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def export(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{name}.glb'),
        export_format='GLB',use_selection=True,export_apply=True,export_yup=True,
        export_cameras=False,export_lights=False)
    print('PIGSTY_ASSET_OK',name)

def feeder():
    root=empty('FeedTrough')
    parts=[b('Bottom',(0,0,.15),(1.55,.64,.10),'DarkWood')]
    for side in [-1,1]:
        parts.append(b('SideBoard',(0,side*.32,.30),(1.64,.075,.30),'Wood',.025))
        parts.append(b('EndBoard',(side*.78,0,.30),(.09,.64,.30),'LightWood',.025))
        parts.append(b('Skid',(side*.53,0,.07),(.17,.85,.13),'DarkWood'))
        parts.append(b('Band',(side*.59,-.365,.30),(.075,.027,.31),'Metal',.008))
        for z in [.21,.38]:parts.append(e('Rivet',(side*.59,-.383,z),(.022,.012,.022),'Metal',rings=8,segments=10))
    parent([batch('FeedTroughStatic',parts)],root)
    fill=empty('FeedFill',(0,0,.205));parent([fill],root)
    grain=[b('FeedBed',(0,0,.265),(1.40,.51,.12),'Grain',.04)]
    for i in range(48):
        x=math.sin(i*2.399)*(.13+(i%7)*.077)
        y=math.cos(i*2.399)*(.07+(i%3)*.060)
        grain.append(e('Grain',(x,y,.332),(.035,.023,.019),'GrainLight',rings=6,segments=8))
    parent([batch('FeedGrain',grain)],fill)
    return root

def waterer():
    root=empty('WaterTrough')
    parts=[b('BasinBase',(0,0,.095),(1.20,.78,.15),'Stone',.075)]
    for side in [-1,1]:
        parts.append(b('BasinLongWall',(0,side*.36,.25),(1.18,.09,.29),'Stone',.035))
        parts.append(b('BasinEndWall',(side*.55,0,.25),(.10,.66,.29),'Stone',.035))
    parts.append(t('WaterPipe',[(.39,.44,.08),(.39,.44,.68),(.39,.14,.68),(.39,.10,.56)],.029,'Metal'))
    parts.append(b('Valve',(.39,.43,.56),(.16,.035,.04),'Roof',.01))
    parent([batch('WaterTroughStatic',parts)],root)
    fill=empty('WaterFill',(0,0,.17));parent([fill],root)
    surface=[b('WaterSurface',(0,0,.285),(1.02,.61,.025),'Water',.035)]
    for radius in [.06,.12]:
        points=[(.33+radius*math.cos(i*math.tau/24),.04+radius*.65*math.sin(i*math.tau/24),.301) for i in range(25)]
        surface.append(t('Ripple',points,.007,'WaterLight'))
    parent([batch('WaterSurface',surface)],fill)
    return root

def oval(name,rx,ry,z,key,seed=0):
    verts=[(0,0,z)]
    for i in range(64):
        angle=i*math.tau/64
        radius=1+.035*math.sin(angle*5+seed)+.02*math.cos(angle*9)
        verts.append((math.cos(angle)*rx*radius,math.sin(angle)*ry*radius,z-.008))
    faces=[(0,1+i,1+(i+1)%64) for i in range(64)]
    return a['mesh'](name,verts,faces,key)

def mud():
    root=empty('MudPatch')
    parts=[oval('MudBank',1.27,.87,.019,'Mud'),oval('WetCentre',1.11,.72,.024,'WetMud',2)]
    for i in range(12):
        angle=i*2.4
        parts.append(e('Bank',(math.cos(angle)*1.13,math.sin(angle)*.77,.018),(.12,.075,.025),'Mud',rings=6,segments=10))
    for i in range(7):
        x=-.7+i*.21;y=.13*math.sin(i*2)
        for side in [-1,1]:parts.append(e('HoofMark',(x+side*.034,y,.028),(.028,.048,.008),'Mud',rings=6,segments=8))
    parent([batch('MudSurface',parts)],root)
    return root

def shelter():
    root=empty('PigShelter')
    parts=[]
    for x in [-1.5,1.5]:
        for y in [-.85,.85]:parts.append(b('Post',(x,y,.91),(.16,.16,1.82),'DarkWood'))
    for i in range(14):
        parts.append(b('BackPlank',(-1.43+i*.22,.86,.76),(.207,.09,1.47),'Wood' if i%3 else 'LightWood',.012))
    for side in [-1,1]:
        for i in range(8):parts.append(b('SidePlank',(side*1.5,-.72+i*.205,.55),(.09,.195,1.05),'Wood',.012))
        parts.append(beam('FrontBrace',(side*1.47,-.85,1.24),(side*.97,-.85,1.81),.12,.12,'DarkWood'))
    parts.append(b('Lintel',(0,-.85,1.80),(3.24,.17,.18),'LightWood'))
    # Sloped board tiles produce a readable clay roof without hidden textures.
    for side in [-1,1]:
        parts.append(roof_panel('RoofUnderlay',side,0,2.32,-.065,'Roof'))
        for strip in range(9):
            y=-1.04+strip*.26
            parts.append(roof_panel('RoofTile',side,y,.255,0,'Roof' if strip%3 else 'RoofEdge'))
        for y in [-1.17,1.17]:parts.append(beam('Fascia',(side*1.80,y,1.84),(0,y,2.46),.11,.13,'RoofEdge'))
    parts.append(b('Ridge',(0,0,2.48),(.12,2.43,.12),'RoofEdge',.035))
    parts.append(b('StrawBed',(0,.1,.037),(2.71,1.38,.06),'Straw',.10))
    for i in range(36):
        x=math.sin(i*2.4)*1.19;y=math.cos(i*2.4)*.54+.1
        straw=b('Straw',(x,y,.076),(.20,.018,.014),'GrainLight',.006);straw.rotation_euler.z=i*1.7;parts.append(straw)
    parent([batch('ShelterStatic',parts)],root)
    return root

def pigsty():
    clear();root=empty('Pigsty')
    parts=[]
    for x in [-3.7,3.7]:
        for y in [-2.7,0,2.7]:
            parts.append(b('FencePost',(x,y,.52),(.18,.18,1.04),'DarkWood'))
            parts.append(b('PostCap',(x,y,1.06),(.23,.23,.09),'LightWood'))
        for z in [.31,.71]:parts.append(b('SideRail',(x,0,z),(.095,5.4,.16),'Wood'))
    for y in [-2.7,2.7]:
        for side in [-1,1]:
            for z in [.31,.71]:parts.append(b('Rail',(side*2.38,y,z),(2.52,.095,.16),'Wood'))
    for z in [.31,.71]:parts.append(b('BackRail',(0,2.7,z),(2.2,.095,.16),'Wood'))
    for x in [-1.1,1.1]:parts.append(b('GatePost',(x,-2.7,.53),(.18,.18,1.06),'DarkWood'))
    parent([batch('FenceStatic',parts)],root)
    hinge=empty('GateHinge',(1.1,-2.7,0));parent([hinge],root)
    gate=[]
    for x in [-.99,.99]:gate.append(b('GateStile',(x,-2.7,.50),(.12,.13,.79),'LightWood'))
    for z in [.22,.78]:gate.append(b('GateRail',(0,-2.7,z),(2.10,.13,.13),'LightWood'))
    gate.append(beam('GateDiagonal',(-.93,-2.71,.27),(.93,-2.71,.73),.105,.09,'Wood'))
    gate.append(b('Latch',(-1.0,-2.80,.74),(.27,.035,.07),'Metal',.012))
    # Sculpted pig emblem makes the gate recognizable without UI text.
    gate.append(b('Plaque',(0,-2.81,.58),(.57,.055,.41),'DarkWood',.07))
    gate.append(e('PigEmblem',(0,-2.856,.58),(.20,.036,.13),'Pink'))
    for side in [-1,1]:gate.append(e('EmblemNostril',(side*.075,-2.89,.58),(.026,.014,.04),'Nostril',rings=8,segments=12))
    parent([batch('GateLeaf',gate)],hinge)
    for create,name,position in [(shelter,'PigShelter',(-1.66,1.45,0)),
            (feeder,'FeedTrough',(2.6,1.56,0)),(waterer,'WaterTrough',(2.8,-1.37,0)),
            (mud,'MudPatch',(-1.72,-.93,0))]:
        node=create();parent([node],root);node.location=position
    for name,pos in [('PigSpawn1',(-.1,.0,-.015)),('PigSpawn2',(-1.72,-.93,.015)),
                     ('PigSpawn3',(-1.66,1.30,.06)),('GateApproach',(0,-3.15,0))]:
        marker=empty(name,pos);parent([marker],root)
    export('pigsty')

if __name__=='__main__':
    for name,create in [('pig_feeder',feeder),('pig_waterer',waterer),('pig_mud',mud),('pig_shelter',shelter)]:
        clear();create();export(name)
    pigsty()
