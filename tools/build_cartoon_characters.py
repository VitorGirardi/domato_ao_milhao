"""Original smooth cartoon characters. Blender mesh authoring, no image-to-mesh dependency.

Coordinates: Z up, face toward -Y. Six named rigid articulation groups are the
runtime animation contract. Facial patches conform to the head's curved surface.
"""
import bpy
import math
import sys
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
M={}

def signed(v,p): return math.copysign(abs(v)**p,v)

def material(name,hexcode):
    # Palette values are sRGB; Blender shader values are linear.
    rgb=[int(hexcode[i:i+2],16)/255 for i in (0,2,4)]
    rgb=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    mat=bpy.data.materials.new(name)
    mat.diffuse_color=(*rgb,1)
    mat.use_nodes=True
    shader=next(node for node in mat.node_tree.nodes if node.type=='BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value=(*rgb,1)
    shader.inputs['Roughness'].default_value=.78
    return mat

def finish(obj,name,color,smooth=True):
    obj.name=name
    obj.data.materials.append(M[color])
    if smooth:
        for face in obj.data.polygons: face.use_smooth=True
    return obj

def mesh(name,verts,faces,color,smooth=True):
    data=bpy.data.meshes.new(name)
    data.from_pydata(verts,[],faces)
    data.update()
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    return finish(obj,name,color,smooth)

def ellipsoid(name,pos,size,color,power=1.0,rings=16,segments=24):
    verts=[(pos[0],pos[1],pos[2]-size[2])]
    for j in range(1,rings):
        lat=-math.pi/2+math.pi*j/rings
        for i in range(segments):
            a=math.tau*i/segments
            verts.append((pos[0]+size[0]*signed(math.cos(lat),power)*signed(math.cos(a),power),
                          pos[1]+size[1]*signed(math.cos(lat),power)*signed(math.sin(a),power),
                          pos[2]+size[2]*signed(math.sin(lat),power)))
    top=len(verts)
    verts.append((pos[0],pos[1],pos[2]+size[2]))
    faces=[]
    for i in range(segments):
        ni=(i+1)%segments
        faces.append((0,1+ni,1+i))
        for j in range(rings-2):
            a=1+j*segments+i; b=1+j*segments+ni
            faces.append((a,b,b+segments,a+segments))
        faces.append((1+(rings-2)*segments+i,1+(rings-2)*segments+ni,top))
    return mesh(name,verts,faces,color)

def box(name,pos,size,color,bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
    obj=bpy.context.object
    obj.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=obj.modifiers.new('Rounded tailored edges','BEVEL')
    mod.width=bevel; mod.segments=3
    bpy.ops.object.modifier_apply(modifier=mod.name)
    finish(obj,name,color)
    mod=obj.modifiers.new('Weighted surface normals','WEIGHTED_NORMAL')
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def tube(name,points,radius,color,radii=None):
    data=bpy.data.curves.new(name,'CURVE')
    data.dimensions='3D'; data.resolution_u=8
    data.bevel_depth=radius; data.bevel_resolution=2
    data.use_fill_caps=True
    spl=data.splines.new('BEZIER'); spl.bezier_points.add(len(points)-1)
    for i,(point,co) in enumerate(zip(spl.bezier_points,points)):
        point.co=co; point.handle_left_type='AUTO'; point.handle_right_type='AUTO'
        if radii: point.radius=radii[i]
    obj=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.convert(target='MESH')
    return finish(bpy.context.object,name,color)

def group(name,objects,pivot):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    obj=bpy.context.object; obj.name=name
    bpy.context.scene.cursor.location=pivot
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    return obj

def build(name,zeca=False):
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    palette={'Skin':'E5A36D' if zeca else 'F1B381','Cheek':'DF9364','Shirt':'C86A43' if zeca else 'FFF3DA',
             'Denim':'647044' if zeca else '287CC0','Seam':'879365' if zeca else '63A5D3',
             'Boot':'75452B','Sole':'453529','Glove':'97603D','Hair':'66351F','Brow':'5A2C1C',
             'White':'FFFAEA','Dark':'281D19','Eye':'181512','Gold':'EFB34A',
             'Hat':'578577' if zeca else 'DDB45C','Band':'34574C' if zeca else 'AE803D'}
    global M
    M={key:material(name+'_'+key,value) for key,value in palette.items()}
    wide=1.40 if zeca else 1.0
    # Legs, rolled cuffs and oversized rounded work boots.
    for side,sign in [('L',-1),('R',1)]:
        x=sign*.175*wide
        objs=[ellipsoid('Trouser',(x,0,.43),(.16*wide,.17,.28),'Denim',.88),
              box('Rolled cuff',(x,-.005,.28),(.325*wide,.355,.11),'Seam',.04),
              box('Rubber sole',(x,-.09,.06),(.35*wide,.53,.105),'Sole',.045),
              ellipsoid('Boot toe',(x,-.13,.155),(.18*wide,.255,.125),'Boot',.72),
              ellipsoid('Boot ankle',(x,.02,.205),(.14*wide,.155,.155),'Boot',.8)]
        for z in [.20,.245]: objs.append(tube('Boot lace',[(x-.085,-.177,z),(x,-.19,z-.008),(x+.085,-.177,z)],.009,'Band'))
        group('Leg'+side,objs,(x,0,.64))
    # Rounded torso, bib, rounded pocket, shoulder straps and brass fasteners.
    objs=[ellipsoid('Work shirt',(0,0,.94),(.325*wide,.22*wide,.28),'Shirt',.88),
          ellipsoid('Overall waist',(0,0,.715),(.33*wide,.245*wide,.25),'Denim',.83),
          ellipsoid('Neck',(0,0,1.17),(.12,.13,.15),'Skin')]
    front=-.235*wide
    objs.append(box('Overall bib',(0,front,.945),(.455*wide,.075,.335),'Denim',.07))
    objs.append(box('Chest pocket',(0,front-.047,.895),(.255*wide,.042,.17),'Seam',.045))
    objs.append(box('Pocket front',(0,front-.071,.902),(.225*wide,.012,.147),'Denim',.038))
    for sign in [-1,1]:
        x=sign*.205*wide
        objs.append(tube('Thick overall strap',[(x,front-.01,1.065),(x,-.13,1.18),(x,.045,1.205),(x,.18,1.09),(x,.23*wide,1.0),(x,.245*wide,.84)],.035,'Denim'))
        objs.append(ellipsoid('Brass button',(x,front-.061,1.06),(.036,.014,.036),'Gold',rings=10,segments=16))
        objs.append(tube('Bib seam',[(sign*.205*wide,front-.044,1.02),(sign*.205*wide,front-.044,.835),(sign*.15*wide,front-.044,.79)],.006,'Seam'))
    if zeca:
        objs.append(box('Pocket patch',(.07,front-.085,.89),(.10,.014,.09),'Seam',.012))
        for x in [.025,.07,.115]: objs.append(tube('Patch stitch',[(x,front-.096,.925),(x,front-.096,.946)],.004,'White'))
    group('Body',objs,(0,0,.72))
    # Arms retain shoulder pivots for the existing walking / watering animation.
    for side,sign in [('L',-1),('R',1)]:
        x=sign*.435*wide
        objs=[ellipsoid('Rounded sleeve',(x,0,1.05),(.145,.16,.165),'Shirt',1.0),
              ellipsoid('Forearm',(x+sign*.035,-.014,.87),(.11,.125,.18),'Skin'),
              ellipsoid('Palm',(x+sign*.035,-.02,.71),(.12,.11,.12),'Skin' if zeca else 'Glove',.8),
              ellipsoid('Thumb',(x-sign*.06,-.09,.745),(.057,.065,.075),'Skin' if zeca else 'Glove')]
        if zeca: objs.append(tube('Rolled shirt cuff',[(x-.1,-.12,.96),(x,-.16,.95),(x+.1,-.12,.96)],.023,'Shirt'))
        for j in range(3):
            objs.append(ellipsoid('Finger',(x+sign*.035+(j-1)*.055,-.09,.681),(.033,.049,.055),'Skin' if zeca else 'Glove',rings=8,segments=12))
        group('Arm'+side,objs,(x,0,1.12))
    # A curved rounded-square head; facial features hug its real surface.
    hx=.55 if zeca else .495
    hy=.37; hz=.47; cz=1.655; power=.85
    def face(x,z,offset=0):
        surface=max(.005,1-(abs(x)/hx)**(2/power)-(abs(z-cz)/hz)**(2/power))
        return -hy*surface**(power/2)-offset
    objs=[ellipsoid('Sculpted head',(0,0,cz),(hx,hy,hz),'Skin',power,rings=24,segments=40),
          ellipsoid('Hair back',(0,.15,1.81),(.505,.31,.35),'Hair',.9,rings=16,segments=32)]
    for sign in [-1,1]:
        objs.append(ellipsoid('Ear',(sign*(hx+.005),0,1.62),(.115,.10,.15),'Skin'))
        objs.append(ellipsoid('Ear inner',(sign*(hx+.022),-.084,1.62),(.061,.025,.088),'Cheek'))
        objs.append(ellipsoid('Sideburn',(sign*.44,-.13,1.82),(.065,.055,.20),'Hair'))
        x=sign*.192; z=1.765
        objs.append(ellipsoid('Eye white',(x,face(x,z,.006),z),(.159,.046,.181),'White',rings=18,segments=28))
        objs.append(ellipsoid('Eye dark outline',(x,face(x,z,.002),z),(.169,.027,.19),'Brow',rings=18,segments=28))
        objs.append(ellipsoid('Large dark pupil',(x-sign*.008,face(x,z,.053),z-.009),(.111,.025,.136),'Eye',rings=18,segments=28))
        objs.append(ellipsoid('Eye highlight',(x-.034,face(x,z,.079),z+.065),(.034,.010,.043),'White',rings=10,segments=16))
        objs.append(ellipsoid('Eye glint',(x+.033,face(x,z,.078),z-.053),(.012,.005,.016),'White',rings=8,segments=12))
        points=[(sign*.09,face(sign*.09,1.997,.04),1.997),
                (sign*.19,face(sign*.19,2.025,.04),2.025),
                (sign*.315,face(sign*.315,1.968,.04),1.968)]
        if zeca and sign==1: points=[(x,y,z+.018) for x,y,z in points]
        objs.append(tube('Expressive eyebrow',points,.037,'Brow',[.6,1,.5]))
    # Smile is a curved ribbon of ivory within a dark lip silhouette.
    def smile_patch(name,width,top,bottom,color,offset):
        verts=[]; segments=32
        for row in range(5):
            t=row/4
            for i in range(segments+1):
                u=-1+2*i/segments; x=width*u
                za=top[0]+top[1]*u*u; zb=bottom[0]+bottom[1]*u*u
                z=za*(1-t)+zb*t
                verts.append((x,face(x,z,offset),z))
        faces=[]
        for row in range(4):
            for i in range(segments):
                a=row*(segments+1)+i; faces.append((a,a+segments+1,a+segments+2,a+1))
        return mesh(name,verts,faces,color)
    objs.append(smile_patch('Broad smile outline',.235 if zeca else .324,(1.445,.067),(1.285,.227),'Dark',.014))
    objs.append(smile_patch('Single cartoon smile',.211 if zeca else .299,(1.434,.066),(1.315,.185),'White',.019))
    for sign in [-1,1]:
        x=sign*.322; z=1.51
        if not zeca: objs.append(tube('Smile corner',[(x-sign*.012,face(x,z,.022),z-.012),(x,face(x,z,.018),z+.013)],.010,'Brow',[1,.1]))
    objs.append(ellipsoid('Button nose',(0,face(0,1.572,.031),1.572),(.105 if zeca else .069,.073,.070 if zeca else .049),'Skin',rings=16,segments=24))
    # Clean sculpted hair tufts; no individual strands or photoreal skin texture.
    for x,z,angle in [(-.30,2.085,-.35),(-.12,2.09,-.20),(.07,2.095,.18),(.27,2.08,.5)]:
        tuft=ellipsoid('Swept fringe',(x,-.25,z),(.155,.115,.077),'Hair',rings=12,segments=20)
        center=Vector((x,-.25,z))
        for v in tuft.data.vertices:
            d=v.co-center
            v.co=center+Vector((d.x*math.cos(angle)-d.z*math.sin(angle),d.y,d.x*math.sin(angle)+d.z*math.cos(angle)))
        objs.append(tuft)
    if zeca:
        for sign in [-1,1]:
            objs.append(tube('Sculpted moustache',[(sign*.014,-.43,1.55),(sign*.13,-.445,1.535),(sign*.28,-.36,1.55)],.086,'Hair',[.85,1,.18]))
    # Solid curved, asymmetric hat brim with a softly rounded crown.
    verts=[]; seg=64
    for layer in [0,1]:
        for r in [.0,.55,1.0]:
            for i in range(seg):
                a=math.tau*i/seg
                x=.72*r*math.cos(a); y=.56*r*math.sin(a)
                z=2.105+.05*r*r*math.cos(2*a+.4)+.048*r*math.cos(a)+layer*.038
                verts.append((x,y,z))
    faces=[]
    for layer in [0,1]:
        for ring in range(2):
            for i in range(seg):
                a=layer*3*seg+ring*seg+i; b=layer*3*seg+ring*seg+(i+1)%seg
                faces.append((a,b,b+seg,a+seg) if layer==0 else (a,a+seg,b+seg,b))
    for i in range(seg):
        a=2*seg+i; b=2*seg+(i+1)%seg; faces.append((a,b,b+3*seg,a+3*seg))
    objs.append(mesh('Wavy hat brim',verts,faces,'Hat'))
    objs.append(ellipsoid('Rounded hat crown',(0,.014,2.238),(.405,.315,.20),'Hat',.72,rings=16,segments=32))
    band=[]
    for i in range(33):
        a=math.tau*i/32; band.append((.41*math.cos(a),.326*math.sin(a)+.014,2.156))
    objs.append(tube('Hat band',band,.024,'Band'))
    for x in [-.115,-.063]: objs.append(tube('Hat repair',[(x,-.311,2.22),(x-.008,-.296,2.34)],.0045,'Band'))
    for z in [2.26,2.303]: objs.append(tube('Hat repair', [(-.145,-.317+(z-2.22)*.17,z),(-.035,-.317+(z-2.22)*.17,z)],.0045,'Band'))
    group('Head',objs,(0,0,1.19))
    bpy.ops.object.select_all(action='SELECT')
    # Preserve the six mesh groups, their pivots and material identities in GLB.
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source'/f'{name}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models'/f'{name}.glb'),export_format='GLB',
        use_selection=True,export_apply=True,export_cameras=False,export_lights=False,export_yup=True)
    triangles=sum(sum(len(p.vertices)-2 for p in obj.data.polygons) for obj in bpy.context.scene.objects if obj.type=='MESH')
    print('CARTOON_ASSET_OK',name,'triangles',triangles)

if __name__=='__main__':
    wanted=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    if not wanted or 'farmer' in wanted: build('farmer')
    if not wanted or 'helper' in wanted: build('helper',True)
