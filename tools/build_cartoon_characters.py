"""Original smooth cartoon characters. Blender mesh authoring, no image-to-mesh dependency.

Coordinates: Z up, face toward -Y. A continuous body and humanoid skin rig are the
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
             'White':'FFFAEA','Dark':'281D19','Eye':'181512','Iris':'806039','Gold':'EFB34A',
             'Hat':'578577' if zeca else 'DDB45C','Band':'34574C' if zeca else 'AE803D'}
    global M
    M={key:material(name+'_'+key,value) for key,value in palette.items()}
    import runpy
    body_builder=runpy.run_path(str(ROOT/'tools'/'character_body.py'))
    api={'M':M,'mesh':mesh,'box':box,'ellipsoid':ellipsoid,'tube':tube}
    body,details=body_builder['build_body'](api,zeca)
    # A curved rounded-square head; facial features hug its real surface.
    hx=.55 if zeca else .495
    hy=.37; hz=.47; cz=1.655; power=.85
    def face(x,z,offset=0):
        surface=max(.005,1-(abs(x)/hx)**(2/power)-(abs(z-cz)/hz)**(2/power))
        return -hy*surface**(power/2)-offset
    objs=[ellipsoid('Sculpted head',(0,0,cz),(hx,hy,hz),'Skin',power,rings=24,segments=40),
          ellipsoid('Hair back',(0,.15,1.81),(.505,.31,.35),'Hair',.9,rings=16,segments=32)]
    eye_parts=[]
    closed_parts=[]
    for sign in [-1,1]:
        objs.append(ellipsoid('Ear',(sign*(hx+.005),0,1.62),(.115,.10,.15),'Skin'))
        objs.append(ellipsoid('Ear inner',(sign*(hx+.022),-.084,1.62),(.061,.025,.088),'Cheek'))
        objs.append(ellipsoid('Sideburn',(sign*.44,-.13,1.82),(.065,.055,.20),'Hair'))
        x=sign*.192; z=1.765
        eye_parts.extend([
            ellipsoid('Eye white',(x,face(x,z,.008),z),(.108,.035,.119),'White',rings=18,segments=28),
            ellipsoid('Eye outline',(x,face(x,z,.003),z),(.114,.023,.125),'Brow',rings=18,segments=28),
            ellipsoid('Hazel iris',(x,face(x,z,.042),z),(.064,.017,.078),'Iris',rings=18,segments=28),
            ellipsoid('Pupil',(x,face(x,z,.057),z),(.034,.010,.050),'Eye',rings=16,segments=24),
            ellipsoid('Eye highlight',(x-.016,face(x,z,.067),z+.030),(.016,.006,.020),'White',rings=10,segments=16)])
        closed_parts.append(tube('Closed eyelid',[(x-.095,face(x-.095,z,-.024),z+.008),
            (x,face(x,z,-.024),z-.012),(x+.095,face(x+.095,z,-.024),z+.008)],.009,'Brow',[.3,1,.3]))
        points=[(sign*.09,face(sign*.09,1.94,.025),1.94),
                (sign*.19,face(sign*.19,1.963,.025),1.963),
                (sign*.295,face(sign*.295,1.925,.025),1.925)]
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
    for parts,label in [(eye_parts,'BlinkEyes'),(closed_parts,'BlinkCrease')]:
        for obj in parts:
            vg=obj.vertex_groups.new(name=label)
            vg.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    head=group('Head',objs+eye_parts+closed_parts,(0,0,1.19))
    head.shape_key_add(name='Basis')
    blink=head.shape_key_add(name='Blink')
    eyes_index=head.vertex_groups['BlinkEyes'].index
    crease_index=head.vertex_groups['BlinkCrease'].index
    for vertex in head.data.vertices:
        groups={g.group for g in vertex.groups}
        co=blink.data[vertex.index].co
        if eyes_index in groups:
            co.z=(1.765-1.19)+(co.z-(1.765-1.19))*.015
            co.y=face(co.x,co.z+1.19,-.018)
        elif crease_index in groups:
            co.y=face(co.x,co.z+1.19,.014)
    body_builder['rig_export'](name,body,details,head,zeca)

if __name__=='__main__':
    wanted=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    if not wanted or 'farmer' in wanted: build('farmer')
    if not wanted or 'helper' in wanted: build('helper',True)
