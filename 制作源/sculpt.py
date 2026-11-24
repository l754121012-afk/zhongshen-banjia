"""Build original beveled toy-scale hero assets. Coordinates use the engine's Y-up convention."""
import bpy, math, sys
from mathutils import Vector
from pathlib import Path
from math import pi,sin,cos
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
out.mkdir(parents=True,exist_ok=True)
def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
def conv(p): return (p[0],-p[2],p[1])
def lin(c):
    v=c/255
    return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def mat(color):
    m=bpy.data.materials.get(color)
    if m:return m
    m=bpy.data.materials.new(color);m.use_nodes=True
    rgb=tuple(lin(int(color[i:i+2],16)) for i in (0,2,4))
    s=m.node_tree.nodes.get('Principled BSDF')
    s.inputs['Base Color'].default_value=(*rgb,1)
    s.inputs['Roughness'].default_value=.46 if color in [brass,gold] else .68
    if color in [brass,gold]:s.inputs['Metallic'].default_value=.24
    m.diffuse_color=(*rgb,1)
    return m
teal='267875';light='469995';dark='21454C';red='BC5849';cream='E7D8B9';gold='E4A647';brass='B57B3F';wood='A76C47';rubber='273841'
def finish(o,name,color):
    o.name=name;o.data.materials.append(mat(color));return o
def smooth(o):
    for p in o.data.polygons:p.use_smooth=True
    return o
def box(name,p,d,color,b=.07):
    bpy.ops.mesh.primitive_cube_add(size=1,location=conv(p));o=bpy.context.object
    o.dimensions=(d[0],d[2],d[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if b:
        m=o.modifiers.new('soft cast edges','BEVEL');m.width=min(b,min(d)*.43);m.segments=3
        m=o.modifiers.new('weighted normals','WEIGHTED_NORMAL');m.keep_sharp=True
    return finish(o,name,color)
def orb(name,p,d,color):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=.5,location=conv(p));o=bpy.context.object
    o.scale=(d[0],d[2],d[1]);return finish(smooth(o),name,color)
def cylinder(name,a,b,r,color,r2=None):
    aa,bb=Vector(conv(a)),Vector(conv(b));dv=bb-aa
    bpy.ops.mesh.primitive_cone_add(vertices=20,radius1=r,radius2=r if r2 is None else r2,depth=dv.length,location=(aa+bb)/2)
    o=bpy.context.object;o.rotation_euler=dv.to_track_quat('Z','Y').to_euler()
    return finish(smooth(o),name,color)
def pipe(name,pts,r,color):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=6;c.bevel_depth=r;c.bevel_resolution=3;c.use_fill_caps=True
    s=c.splines.new('BEZIER');s.bezier_points.add(len(pts)-1)
    for bp,pt in zip(s.bezier_points,pts):
        bp.co=conv(pt);bp.handle_left_type=bp.handle_right_type='AUTO'
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(mat(color))
    return o
def arch(name,x,y,z,r,color,depth):
    pts=[(x+cos(i*pi/16)*r,y+sin(i*pi/16)*r,z) for i in range(17)]
    pipe(name,pts,depth,color)
def export(name):
    # Join static surfaces by material to keep the render cost small.
    bpy.ops.object.select_all(action='DESELECT')
    for o in list(bpy.context.scene.objects):
        bpy.context.view_layer.objects.active=o;o.select_set(True)
        if o.type=='CURVE' or len(o.modifiers):
            bpy.ops.object.convert(target='MESH')
        o.select_set(False)
    grouped={}
    for o in list(bpy.context.scene.objects):
        if o.type!='MESH':continue
        part='body'
        key=o.name.split('.')[0]
        if name=='moon_couch':
            if key in ['sleep face','hair','curl','lid','nose','sleep wing']:part='head'
            elif key in ['quilt','folded silk','embroidered star','blanket piping']:part='quilt'
        if name=='wind_sack' and key in ['bag frill','knotted neck','cord','tassel']:part='mouth'
        grouped.setdefault((part,o.data.materials[0].name),[]).append(o)
    for key,objs in grouped.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objs:o.select_set(True)
        bpy.context.view_layer.objects.active=objs[0]
        if len(objs)>1:bpy.ops.object.join()
        bpy.context.object.name=key[0]+'_'+key[1]
    for groupname,pivot in [('head',(0,.96,-.83)),('quilt',(0,.77,.22)),('mouth',(0,1.14,0))]:
        children=[o for o in bpy.context.scene.objects if o.name.startswith(groupname+'_')]
        if not children:continue
        e=bpy.data.objects.new(groupname.title()+'Pivot',None);bpy.context.collection.objects.link(e)
        e.location=conv(pivot);bpy.context.view_layer.update()
        for o in children:
            m=o.matrix_world.copy();o.parent=e;o.matrix_world=m
    bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),export_format='GLB',export_yup=True,export_cameras=False,export_lights=False)
clear()
box('chassis',(0,.55,0),(6.0,.32,2.25),dark)
box('flatbed',(-.72,.88,0),(4.68,.27,2.48),teal)
for i in range(11):
    box('deck board',(-2.81+i*.415,1.025,0),(.402,.10,2.32),['C99967','B98151','D0A272'][i%3],.018)
for z in [-1.19,1.19]:
    box('brass rim',(-.72,1.008,z),(4.7,.09,.075),brass,.018)
    box('painted sill',(-.72,.78,z*1.025),(4.62,.14,.09),light)
    for x in [-2.75,-1.82,-.89,.04,.97]:
        orb('rivet',(x,.79,z*1.08),(.056,.066,.036),gold)
for i in range(4):
    x=-2.92+i*1.40
    box('stake',(x,1.38,-1.2),(.13,.81,.13),teal,.028)
for h in [1.22,1.53]:
    box('back rail',(-.82,h,-1.20),(4.34,.18,.11),light,.027)
box('cab lower',(1.99,1.14,0),(1.52,1.04,2.19),teal,.21)
box('cab shoulders',(1.93,1.60,0),(1.33,.45,2.14),light,.16)
box('far side glass',(1.89,1.98,-.96),(1.05,.69,.055),'68939A',.09)
box('split windscreen',(2.43,2.01,0),(.078,.69,1.81),'8DB6B7',.065)
box('glass divide',(2.48,2.01,0),(.064,.77,.052),cream,.022)
box('near sill',(1.89,1.64,1.03),(1.24,.13,.13),cream,.045)
box('driver bench',(1.63,1.64,0),(.47,.16,1.64),'875F4A',.06)
for z in [-.42,.36]:
    cylinder('mirror stalk',(2.29,1.91,z*2.4),(2.30,2.07,z*3),.029,brass)
    box('wing mirror',(2.30,2.10,z*3),(.18,.20,.07),teal,.04)
box('rear cab',(1.29,1.98,0),(.14,.86,2.04),teal)
for z in [-.98,.98]:
    for x in [1.36,2.42]:
        pipe('cab pillar',[(x,1.60,z),(x,2.13,z*.96),(x-.05,2.38,z*.88)],.071,cream)
    box('door',(1.95,1.35,z*1.10),(1.05,.55,.074),light,.09)
    box('handle',(1.58,1.55,z*1.16),(.22,.065,.06),brass,.025)
    orb('insignia',(1.92,1.33,z*1.16),(.28,.29,.032),gold)
    for k in range(3):
        orb('wing motif',(1.72-k*.085,1.35+k*.052,z*1.16),(.16-.022*k,.048,.04),cream)
box('roof lip',(1.87,2.42,0),(1.62,.17,2.34),cream,.10)
box('cab roof',(1.86,2.53,0),(1.65,.26,2.39),red,.13)
box('bonnet',(2.77,1.23,0),(.99,.69,1.79),teal,.24)
pipe('hood ridge',[(2.42,1.57,0),(2.87,1.57,0),(3.18,1.48,0)],.027,gold)
box('radiator surround',(3.26,1.19,0),(.14,.68,1.30),brass,.10)
box('recessed grille',(3.34,1.19,0),(.05,.56,1.17),dark,.07)
for i in range(9):box('chrome grille',(3.382,1.19,-.49+i*.125),(.052,.48,.038),cream,.017)
box('front bumper',(3.35,.72,0),(.20,.16,2.31),cream,.07)
box('tail bumper',(-3.12,.63,0),(.16,.16,2.36),cream,.05)
for z in [-.91,.91]:
    orb('headlamp housing',(3.16,1.35,z),(.42,.40,.37),brass)
    orb('headlamp lens',(3.32,1.35,z),(.13,.31,.28),'FFE6A7')
    for j in range(4):box('hood vent',(2.60+j*.12,1.25,z),(.055,.23,.04),dark,.015)
    orb('tail light',(-3.07,.86,z),(.09,.20,.18),red)
for x in [-1.89,2.20]:
    for side in [-1,1]:
        z=side*1.12
        cylinder('tire',(x,.54,z-.16),(x,.54,z+.16),.535,rubber)
        cylinder('rim',(x,.54,z+side*.16),(x,.54,z+side*.195),.335,cream)
        cylinder('hub',(x,.54,z+side*.198),(x,.54,z+side*.22),.25,teal)
        orb('hub cap',(x,.54,z+side*.22),(.28,.28,.11),brass)
        for i in range(6):
            a=i*pi/3
            orb('wheel lug',(x+.195*cos(a),.54+.195*sin(a),z+side*.23),(.045,.045,.04),gold)
        arch('painted fender',x,.55,z,.61,teal,.107)
pipe('exhaust',[(1.06,.69,-.79),(1.06,1.82,-.99),(.99,2.04,-.99)],.065,dark)
export('westwind')
clear()
for x in [-.57,.57]:
    for z in [-1.21,1.21]:
        pipe('curved leg',[(x*.90,.42,z*.93),(x,.22,z),(x*.92,.09,z*1.04)],.082,brass)
        orb('caster',(x*.92,.095,z*1.04),(.18,.18,.18),gold)
box('frame',(0,.43,0),(1.43,.26,2.86),teal,.11)
box('gilt',(0,.54,0),(1.45,.09,2.88),gold,.035)
box('cushion',(0,.69,0),(1.38,.34,2.73),cream,.16)
for z in [-1.38,1.38]:
    box('headboard',(0,.82,z),(1.4,.63,.15),teal,.074)
    pipe('gilt rim',[(-.67,1.05,z),(-.48,1.12,z),(0,1.23 if z<0 else 1.02,z),(.48,1.12,z),(.67,1.05,z)],.046,gold)
    for x in [-.65,.65]:
        orb('finial',(x,1.15,z),(.16,.22,.16),gold)
for x in [-.72,.72]:
    pipe('apron scroll',[(x,.60,-1.22),(x,.43,-.85),(x,.42,.72),(x,.57,1.22)],.036,gold)
box('pillow',(0,.90,-.87),(1.09,.26,.68),'F8ECD2',.12)
orb('sleep face',(0,1.06,-.77),(.48,.42,.49),'E7A57E')
orb('hair',(0,1.12,-.89),(.51,.38,.42),'79483C')
for i in range(7):
    a=i*pi/6;orb('curl',(.227*cos(a),1.16+.04*sin(a),-.85-.11*sin(a)),(.15,.15,.14),'754839')
for x in [-.12,.12]:
    pipe('lid',[(x-.044,1.10,-.552),(x,1.084,-.54),(x+.044,1.10,-.552)],.012,dark)
orb('nose',(0,1.065,-.513),(.11,.09,.075),'DC936E')
for x in [-1,1]:
    orb('sleep wing',(x*.25,1.19,-.83),(.21,.11,.13),cream)
orb('quilt',(0,.90,.27),(1.36,.57,1.86),'4F789B')
box('folded silk',(0,1.02,-.42),(1.22,.24,.23),'7EA2AC',.1)
for z in [-.04,.43,.81]:
    for x in [-.31,.17]:
        top=.90+.285*math.sqrt(max(.04,1-(x/.68)**2-((z-.27)/.93)**2))
        o=box('embroidered star',(x,top+.008,z),(.097,.027,.097),gold,.009);o.rotation_euler.z=pi/4
for side in [-1,1]:
    pipe('blanket piping',[(side*.46,1.03,-.43),(side*.64,.98,-.12),(side*.65,.96,.52),(side*.49,.96,.92)],.025,gold)
pts=[(.24*cos(-1.12+i*4.6/14),1.40+.24*sin(-1.12+i*4.6/14),-1.385) for i in range(15)]
pipe('crescent crest',pts,.046,gold)
export('moon_couch')
clear()
orb('sack body',(0,.58,0),(1.12,1.17,1.0),'E4A84B')
cylinder('gather',(0,1.0,0),(0,1.27,0),.32,'D79843',.125)
for i in range(7):
    a=i*2*pi/7
    pipe('silk seam',[(.17*cos(a),.10,.16*sin(a)),(.49*cos(a),.45,.45*sin(a)),(.46*cos(a),.89,.40*sin(a)),(.14*cos(a),1.23,.13*sin(a))],.016,'BD7D3E')
    orb('bag frill',(.14*cos(a),1.39,.13*sin(a)),(.30,.27,.26),'EAB75C')
for y in [1.17,1.24]:
    pts=[(.185*cos(i*2*pi/14),y+.014*sin(i*4*pi/14),.17*sin(i*2*pi/14)) for i in range(16)]
    pipe('knotted neck',pts,.037,teal)
pipe('cord',[(.14,1.18,.08),(.43,1.18,.19),(.47,.91,.36),(.46,.75,.39)],.032,teal)
orb('tassel',(.46,.70,.39),(.15,.24,.13),teal)
for side in [-1,1]:
    pipe('wind embroidery',[(-.32,.55,.39*side),(-.17,.63,.46*side),(.08,.60,.50*side),(.25,.71,.43*side),(.19,.80,.41*side),(.1,.75,.44*side)],.030,cream)
export('wind_sack')


