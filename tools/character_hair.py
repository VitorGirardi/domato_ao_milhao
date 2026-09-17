"""A continuous scalp shell fitted to the same superellipsoid as the head."""
import math

def build(api,hx,hy,hz,cz,power,vendor):
    verts=[]; faces=[]; segments=64; rows=18
    signed=api['signed']
    for j in range(rows+1):
        t=j/rows
        for i in range(segments):
            a=math.tau*i/segments
            front=max(0,-math.sin(a)); back=max(0,math.sin(a))
            boundary=1.76+.24*front**3-(.34 if vendor else .23)*back**2
            # A shallow swept fringe belongs to the scalp, not floating blobs.
            boundary-=.035*front**6*(.5+.5*math.cos(a*3+.6))
            lat_end=math.asin(math.copysign(abs((boundary-cz)/hz)**(1/power),boundary-cz))
            lat=math.pi/2+(lat_end-math.pi/2)*t
            x=(hx+.016)*signed(math.cos(lat),power)*signed(math.cos(a),power)
            y=(hy+.017)*signed(math.cos(lat),power)*signed(math.sin(a),power)
            z=cz+(hz+.016)*signed(math.sin(lat),power)
            if not vendor:
                r=math.sqrt((x/.72)**2+(y/.56)**2); angle=math.atan2(y/.56,x/.72)
                z=min(z,2.035+.05*r*r*math.cos(2*angle+.4)+.048*r*math.cos(angle)-.012)
            verts.append((x,y,z))
    for j in range(rows):
        for i in range(segments):
            a=j*segments+i; b=j*segments+(i+1)%segments
            faces.append((a,a+segments,b+segments,b))
    result=[api['mesh']('Continuous fitted scalp',verts,faces,'Hair')]
    if vendor:
        # Two tapered locks blend into the lower cap; no detached bead chains.
        for side in [-1,1]:
            points=[(side*.405,.13,1.68),(side*.45,.14,1.53),(side*.47,.12,1.36),(side*.435,.08,1.22)]
            result.append(api['tube']('Tapered hair lock',points,.105,'Hair',[1.05,1,.8,.18]))
            result.append(api['ellipsoid']('Hair tie',(side*.456,.11,1.34),(.083,.077,.025),'Band'))
            result.append(api['ellipsoid']('Gold earring',(side*(hx+.035),-.02,1.50),(.027,.027,.033),'Gold'))
    return result
