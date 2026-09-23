"""Original cartoon livestock with stable named articulation; Blender 5.x.

Run with -- cow or -- pig to export one species. No arguments builds both.
"""
import bpy
import math
import runpy
import sys
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
a = runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
for key, color in {'Ivory':'F3E6C8','Patch':'393D3B','Pink':'D89C8C',
                   'Hoof':'565A50','Hay':'DAC16C','Black':'202D29',
                   'Pig':'DEA58E','Ear':'C57C72','Snout':'CE887A'}.items():
    a['M'][key] = a['material'](key, color)
e, b, t = a['ellipsoid'], a['box'], a['tube']

def pivot(name, at, objects):
    p = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(p)
    p.matrix_world = Matrix.Translation(Vector(at))
    for obj in objects:
        mat = obj.matrix_world.copy()
        obj.parent = p
        obj.matrix_parent_inverse = Matrix.Identity(4)
        obj.matrix_basis = p.matrix_world.inverted() @ mat
    return p

def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def export(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{name}.glb'),
        export_format='GLB', use_selection=True, export_apply=True,
        export_yup=True, export_cameras=False, export_lights=False)
    print('LIVESTOCK_OK', name)

def patches(body):
    # Color on the skin, rather than raised balls on the cow's flanks.
    coat=a['M']['Ivory'].copy();coat.name='CowCoat'
    colors=body.data.color_attributes.new(name='CoatColor',type='FLOAT_COLOR',domain='CORNER')
    body.data.color_attributes.active_color=colors
    ivory=a['M']['Ivory'].diffuse_color;dark=a['M']['Patch'].diffuse_color
    for loop in body.data.loops:
        c=body.data.vertices[loop.vertex_index].co
        fields=[4.0]
        if c.x<-.25:fields.append(((c.y+.12)/.48)**2+((c.z-1.48)/.46)**2)
        if c.x>.25:fields.append(((c.y-.25)/.55)**2+((c.z-1.58)/.40)**2)
        if c.y>.60:fields.append(((c.x-.1)/.4)**2+((c.z-1.75)/.28)**2)
        amount=max(0,min(1,(1.05-min(fields))/.12))
        amount=amount*amount*(3-2*amount)
        colors.data[loop.index].color=tuple(ivory[i]*(1-amount)+dark[i]*amount for i in range(3))+(1,)
    node=coat.node_tree.nodes.new('ShaderNodeVertexColor');node.layer_name='CoatColor'
    shader=next(n for n in coat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    coat.node_tree.links.new(node.outputs['Color'],shader.inputs['Base Color'])
    body.data.materials.clear();body.data.materials.append(coat)

def cow():
    clear()
    body=e('CowBody',(0,.05,1.36),(.60,1.03,.64),'Ivory',.86,rings=64,segments=96)
    patches(body)
    shoulder=e('Shoulder',(0,-.59,1.53),(.43,.45,.56),'Ivory',.90)
    for side,x in [('L',-.38),('R',.38)]:
        for end,y in [('F',-.66),('B',.72)]:
            parts=[e('Leg',(x,y,.69),(.155,.18,.57),'Ivory',.8)]
            for sign in [-1,1]:
                parts.append(b('ClovenHoof',(x+sign*.078,y-.025,.14),(.148,.34,.22),'Hoof',.045))
            pivot('Leg'+end+side,(x,y,1.13),parts)
    e('Udder',(0,.61,.79),(.30,.35,.20),'Pink')
    for x in [-.14,.14]:
        for y in [.45,.69]:e('Teat',(x,y,.61),(.044,.044,.10),'Pink')
    head=[e('Head',(0,-1.04,1.67),(.35,.46,.42),'Ivory',.90),
          e('Muzzle',(0,-1.40,1.45),(.38,.29,.22),'Pink',.9)]
    jaw=e('LowerLip',(0,-1.39,1.31),(.31,.235,.10),'Pink')
    head.append(pivot('CowJaw',(0,-1.09,1.40),[jaw]))
    for x in [-.18,.18]:head.append(e('Nostril',(x,-1.665,1.48),(.050,.016,.031),'Patch'))
    for side,suffix in [(-1,'L'),(1,'R')]:
        ear=[e('Ear',(side*.48,-.91,1.94),(.25,.13,.095),'Ivory'),
             e('InnerEar',(side*.48,-1.002,1.96),(.16,.041,.049),'Pink')]
        head.append(pivot('CowEar'+suffix,(side*.29,-.90,1.93),ear))
        head.extend([e('EyeWhite',(side*.29,-1.28,1.80),(.086,.066,.098),'Ivory'),
            e('Eye',(side*.31,-1.33,1.80),(.048,.035,.060),'Black'),
            e('EyeGlint',(side*.31-.013,-1.358,1.822),(.012,.010,.016),'Ivory'),
            t('Horn',[(side*.22,-.90,1.99),(side*.24,-.86,2.14),(side*.18,-.85,2.22)],.060,'Hay',radii=[1,.65,.1])])
    neck_head=pivot('CowHead',(0,-.70,1.65),head)
    pivot('CowNeck',(0,-.30,1.50),[shoulder,neck_head])
    tail=[t('TailStem',[(0,.95,1.60),(.06,1.18,1.12),(.15,1.18,.73)],.038,'Ivory'),
          e('TailTuft',(.15,1.18,.70),(.082,.075,.16),'Patch')]
    pivot('CowTail',(0,.94,1.60),tail)
    export('cow')

def pig():
    clear()
    e('PigBody',(0,.08,.68),(.44,.68,.43),'Pig',.90)
    for side,x in [('L',-.29),('R',.29)]:
        for end,y in [('F',-.37),('B',.46)]:
            parts=[e('Leg',(x,y,.29),(.13,.145,.23),'Pig')]
            for sign in [-1,1]:parts.append(b('ClovenHoof',(x+sign*.057,y-.02,.075),(.108,.21,.12),'Hoof',.028))
            pivot('Leg'+end+side,(x,y,.46),parts)
    head=[e('Head',(0,-.54,.73),(.33,.35,.34),'Pig',.9),
          e('Snout',(0,-.858,.63),(.215,.10,.14),'Snout',.8)]
    for side,suffix in [(-1,'L'),(1,'R')]:
        head.append(e('Nostril',(side*.085,-.951,.65),(.035,.014,.044),'Ear'))
        head.append(e('Eye',(side*.245,-.738,.855),(.032,.024,.041),'Black'))
        head.append(e('EyeGlint',(side*.245-.009,-.757,.866),(.008,.007,.010),'Ivory'))
        ear=e('FloppyEar',(side*.27,-.49,1.02),(.17,.075,.22),'Pig')
        inner=e('InnerEar',(side*.27,-.552,1.03),(.12,.025,.15),'Ear')
        for obj in [ear,inner]:
            for vertex in obj.data.vertices:
                height=max(0,(vertex.co.z-.9)/.34)
                vertex.co.x=side*.27+(vertex.co.x-side*.27)*(1-.6*height)
                vertex.co.y-=.16*height*height
        p=pivot('PigEar'+suffix,(side*.18,-.49,.91),[ear,inner])
        p.rotation_euler.y=side*.43
        head.append(p)
    pivot('PigHead',(0,-.30,.69),head)
    points=[(0,.67,.78)]
    for i in range(25):
        angle=i/24*math.tau*1.45
        points.append((.075*math.sin(angle),.72+i*.004,.84+.075*math.cos(angle)))
    pivot('PigTail',(0,.67,.78),[t('CurlyTail',points,.024,'Pig')])
    export('pig')

if __name__=='__main__':
    choices=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['cow','pig']
    for name in choices:
        {'cow':cow,'pig':pig}[name]()
