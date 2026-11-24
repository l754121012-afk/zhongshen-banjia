extends RefCounted

const A=preload("res://workshop.gd")
const B=preload("res://tide_art.gd")
var a:=A.new()
var b:=B.new()
var mats:Dictionary={}
func mineral(base:String,mortar:String)->ShaderMaterial:
	var key:=base+mortar
	if not mats.has(key):
		var m:=ShaderMaterial.new();m.shader=preload("res://coastal_masonry.gdshader")
		m.set_shader_parameter("base",Color(base));m.set_shader_parameter("mortar",Color(mortar));mats[key]=m
	return mats[key]
func plant(p:Node3D,at:Vector3,seed_value:int,flowers:=true)->void:
	var g:=a.group(p,at)
	for j in 7:
		var pos:=Vector3((j-3)*0.36,sin(j*2.45+seed_value)*0.30,-sin(j*1.8)*0.18)
		a.ball(g,pos,Vector3(0.83,0.65,0.76),"#476a51" if j%3 else "#759050",true)
		if flowers:
			for k in 3:
				a.ball(g,pos+Vector3(sin(k*1.7)*0.20,0.27+(k%2)*0.12,0.22*cos(k*1.2)),Vector3(0.29,0.20,0.24),"#b9566b" if j%2 else "#cc7291",true)

func barrel(p:Node3D,at:Vector3,s:float)->void:
	var g:=a.group(p,at);g.scale=Vector3.ONE*s
	a.cyl(g,Vector3.UP*0.65,0.56,0.55,1.30,A.WOOD,12)
	for y in [0.15,0.95,1.24]:a.cyl(g,Vector3.UP*y,0.57,0.57,0.072,B.INK,12)
	a.box(g,Vector3.UP*1.32,Vector3(0.85,0.04,0.065),"#b88a59")
func cloth(p:Node3D,at:Vector3,width:float,tint:String)->void:
	var g:=a.group(p,at)
	for i in 9:
		var x:=width*((i+0.5)/9.0-0.5)
		var col:=tint if i%2==0 else "#ead7b1"
		var roof:=a.box(g,Vector3(x,-0.24,0.85),Vector3(width/9.0+0.016,0.082,1.88),col);roof.rotation.x=0.25
		a.box(g,Vector3(x,-0.55,1.72),Vector3(width/9.0,0.33,0.08),col)
	for side in [-1,1]:
		a.beam(g,Vector3(side*width*0.48,-0.46,1.72),Vector3(side*width*0.48,-1.9,0.1),0.042,A.WOOD)
func windows(p:Node3D,at:Vector3,open:bool,col:String)->void:
	var g:=a.group(p,at)
	a.box(g,Vector3.ZERO,Vector3(0.88,1.2,0.09),"#344b50")
	for j in [-1,1]:
		a.box(g,Vector3(j*0.25,0,0.062),Vector3(0.055,1.20,0.05),"#ceb691")
		a.box(g,Vector3(0,j*0.56,0.092),Vector3(1.04,0.12,0.12),"#ece0b9")
		var shutter:=a.group(g,Vector3(j*(0.69 if open else 0.27),0,0.10))
		shutter.rotation.y=j*0.20 if open else 0
		a.box(shutter,Vector3.ZERO,Vector3(0.44,1.13,0.074),col)
		for row in 5:a.box(shutter,Vector3(0,-0.4+row*0.19,0.052),Vector3(0.36,0.044,0.040),"#699186")
func villa(p:Node3D,at:Vector3,width:float,height:float,yaw:float,theme:int)->Node3D:
	var g:=a.group(p,at);g.rotation.y=yaw
	var depth:=width*0.70
	var plaster:String=["#ddbd91","#e5d3ad","#cda27e","#e1c89f"][posmod(theme,4)]
	a.box(g,Vector3(0,height*0.5,0),Vector3(width,height,depth),plaster)
	a.box(g,Vector3(0,0.30,0),Vector3(width+0.12,0.60,depth+0.10),"#beac8f")
	a.box(g,Vector3(0,height-0.10,0),Vector3(width+0.16,0.21,depth+0.15),"#e3d3b2")
	# Tile runs across a symmetric pitched roof.
	for flank in [-1,1]:
		var panel:=a.box(g,Vector3(0,height+0.44,flank*depth*0.26),Vector3(width+0.55,0.23,depth*0.55+0.24),"#b86947")
		panel.rotation.x=flank*0.30
		for j in range(1,ceili(width/0.39)+1):
			var x:= -width/2+j*0.39-0.20
			a.beam(g,Vector3(x,height+0.48+depth*0.084,0),Vector3(x,height+0.42-depth*0.079,flank*(depth*0.50+0.17)),0.057,"#cd8255")
	a.beam(g,Vector3(-width*0.53,height+0.56+depth*0.084,0),Vector3(width*0.53,height+0.56+depth*0.084,0),0.12,"#d38e62")
	var front:=depth/2
	for j in 3:
		windows(g,Vector3((j-1)*width*0.31,height*0.69,front+0.03),j%2==0 or theme%3!=0,"#327871")
	a.box(g,Vector3(width*0.21,0.90,front+0.045),Vector3(1.1,1.80,0.11),"#39766e")
	a.box(g,Vector3(width*0.21,1.86,front+0.07),Vector3(1.36,0.20,0.18),"#ead5ab")
	if theme%2==0:
		cloth(g,Vector3(-width*0.22,height*0.47,front+0.13),width*0.48,"#6a9890")
	else:
		a.box(g,Vector3(-width*0.20,height*0.53,front+0.42),Vector3(width*0.49,0.15,0.91),"#e2cfab")
		for j in 7:a.cyl(g,Vector3(-width*0.43+j*width*0.075,height*0.53+0.32,front+0.80),0.055,0.07,0.56,B.INK,7)
		a.beam(g,Vector3(-width*0.45,height*0.53+0.63,front+0.80),Vector3(width*0.02,height*0.53+0.63,front+0.80),0.06,A.WOOD)
	plant(g,Vector3(-width*0.22,height*0.51,front+0.91),theme)
	for j in 2:
		a.jar(g,Vector3(width*0.38+(j-0.5)*0.65,0,front+0.60),0.65+0.28*j,"#a5644d")
	a.box(g,Vector3(width*0.29,height+0.96,-0.16*depth),Vector3(0.53,1.32,0.42),plaster)
	return g

func outcrop(p:Node3D,at:Vector3,dimensions:Vector3,seed_no:int)->void:
	var sides:=17
	var rng:=RandomNumberGenerator.new();rng.seed=seed_no*6323+41
	var contour:=PackedFloat32Array();var cap:=PackedFloat32Array()
	for j in sides:
		contour.append(rng.randf_range(.79,1.13))
		cap.append(rng.randf_range(-.09,.07))
	var verts:Array[PackedVector3Array]=[]
	var heights:=[-.53,-.32,-.08,.12,.33,.44]
	var widths:=[.78,1.04,1.01,.93,.82,.64]
	for k in heights.size():
		var level:=PackedVector3Array()
		for j in sides:
			var a:=TAU*j/sides+0.061*sin(j*1.1+seed_no)
			var r:float=widths[k]*contour[j]*(1.0+0.053*sin(k*1.26+j*.93))
			level.append(Vector3(cos(a)*dimensions.x*.5*r,dimensions.y*(float(heights[k])+cap[j]*(.38+k*.12)),sin(a)*dimensions.z*.5*r))
		verts.append(level)
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in heights.size():
		for i in sides:
			var j:=(i+1)%sides
			var a:Vector3=verts[k][i];var b:Vector3=verts[k][j]
			var points:Array[Vector3]
			if k+1<heights.size():points=[a,verts[k+1][i],b,b,verts[k+1][i],verts[k+1][j]]
			else:points=[b,a,Vector3(dimensions.x*.065,dimensions.y*.46,-dimensions.z*.055)]
			var tone:float=rng.randf_range(.43,.99)
			for tri in points.size()/3:
				var n:Vector3=(points[tri*3+1]-points[tri*3]).cross(points[tri*3+2]-points[tri*3]).normalized()
				if k+1<heights.size() and n.dot(Vector3(a.x,0,a.z))<0:n=-n
				elif k+1==heights.size() and n.y<0:n=-n
				for k2 in 3:st.set_color(Color(tone,tone,tone));st.set_normal(n);st.add_vertex(points[tri*3+k2])
	var n:=MeshInstance3D.new();n.mesh=st.commit();n.position=at
	if not mats.has("cliffs"):
		var shader:=ShaderMaterial.new();shader.shader=preload("res://aegean_cliff.gdshader");shader.set_shader_parameter("tint",Color("#b8a188"));mats["cliffs"]=shader
	n.material_override=mats["cliffs"];p.add_child(n)

func crag(p:Node3D,at:Vector3,scale3:Vector3,seed_no:int)->void:
	outcrop(p,at,scale3,seed_no)

func headland_props(p:Node3D)->void:
	for i in 5:
		var at:Vector3=[Vector3(208,4.4,-8),Vector3(216,5.8,8.5),Vector3(248.2,8,5.6),Vector3(245,10.9,32),Vector3(229,12.8,54.8)][i]
		a.prop(p,"garden/tree_oak",at,3.9+(i%3)*.65,i*.83)
		a.prop(p,"garden/plant_bushDetailed",at+Vector3(.75,0,.60),.9,i*.43)
	# A working mill marks the village approach from the offshore channel.
	var mill:=a.group(p,Vector3(249.8,8.0,-7.9))
	a.cyl(mill,Vector3.UP*2.75,1.73,1.31,5.5,"#ddcba8",16)
	a.cyl(mill,Vector3.UP*5.85,1.68,.09,1.0,"#aa7651",18)
	a.box(mill,Vector3(-1.52,1.01,.30),Vector3(.25,2.02,1.0),B.BLUE)
	var sail:=a.group(mill,Vector3(-1.44,4.67,.0));sail.name="MillSails";p.set_meta("mill_sails_path",p.get_path_to(sail))
	for j in 6:
		var arm:=a.group(sail);arm.rotation.x=j*TAU/6
		a.beam(arm,Vector3.ZERO,Vector3(0,2.45,0),.054,A.WOOD)
		var canvas:=a.box(arm,Vector3(.02,1.55,.27),Vector3(.055,1.52,.60),"#eadaae");canvas.rotation.x=.09
	a.cyl(sail,Vector3.ZERO,.28,.28,.52,B.BRASS).rotation.z=PI/2

func temple(p:Node3D,at:Vector3)->void:
	var g:=a.group(p,at);g.rotation.y=0.42
	for i in 3:a.box(g,Vector3.UP*(0.23+i*0.30),Vector3(10.2-i*0.52,0.32,6.6-i*0.46),B.SALT)
	for side in [-1,1]:
		for i in 6:a.column(g,Vector3(-4.05+i*1.62,0.84,side*2.12),4.1)
	a.box(g,Vector3.UP*5.06,Vector3(9.6,0.42,5.7),B.SALT)
	a.box(g,Vector3.UP*5.34,Vector3(9.87,0.18,5.96),"#b39c72")
	for k in [-1,1]:
		var roof:=a.box(g,Vector3(0,5.92,k*1.54),Vector3(10.1,0.26,3.32),"#b77351");roof.rotation.x=k*0.32

func boathouse(p:Node3D)->void:
	var artset:=a.group(p)
	var rear:=a.box(artset,Vector3(8.1,1.8,-3.18),Vector3(19.8,4.2,0.52),"#a99778");rear.material_override=mineral("#c0ac89","#8f806a")
	for i in 5:
		var x:float=-0.8+i*4.3
		a.box(artset,Vector3(x,2.51,-2.77),Vector3(0.25,4.6,0.32),A.WOOD)
		a.beam(artset,Vector3(x,4.63,-2.85),Vector3(x+1.22,3.53,-2.81),0.095,A.WOOD)
		var plaque:=a.box(artset,Vector3(x+1.65,2.6,-2.84),Vector3(1.06,1.72,0.12),B.BLUE)
		for j in 3:a.box(artset,Vector3(x+1.65,2.19+j*0.35,-2.72),Vector3(0.67-j*0.12,0.055,0.07),B.BRASS)
	cloth(artset,Vector3(2.1,4.63,-2.05),6.3,"#a76447")
	cloth(artset,Vector3(14.0,4.63,-2.05),4.6,"#a76447")
	for i in 5:barrel(artset,Vector3(-2.65+(i%2)*0.85,-0.1,3.0+i*1.28),0.82+0.12*(i%2))
	for z in [1.3,6.5,11.8]:
		a.box(artset,Vector3(-2.0,0.03,z),Vector3(2.0,0.32,2.0),B.STONE)
		plant(artset,Vector3(-1.93,1.11,z),int(z))
	for j in 6:
		a.box(artset,Vector3(18.9+0.50*j,-0.15,8),Vector3(0.46,0.15,4.1),A.WOOD)
	for j in 3:a.cyl(artset,Vector3(18.7+j*1.02,0.12,9.93),0.13,0.13,1.52,A.WOOD)
	batch(artset)

func coast(p:Node3D)->void:
	var set:=a.group(p)
	for i in 8:
		var xx:=12.0+i*21
		var zz:float=-37-5*sin(i*1.6)
		var at:=Vector3(xx,2,zz)
		crag(set,at,Vector3(22,12,16),i+1)
		var top:=Vector3(xx,5,zz)
		a.cyl(set,top-Vector3.UP*0.36,5.8,5.3,0.76,"#899367",12)
		villa(set,top+Vector3(-1.4,0,-0.7),5.3+(i%2),3.8+i%3*0.55,0.13*sin(i),i)
		if i%2==0:
			villa(set,top+Vector3(4.8,0.25,-4.4),4.5,4.9,-0.29,i+1)
			a.cypress(set,top+Vector3(3.7,0,0.14),1.8)
		plant(set,top+Vector3(0,0.1,4.6),i)
	for j in 5:
		var x:=16+j*38.0;var y:=3.7+2.0*sin(j*1.5)
		crag(set,Vector3(x,-1.1,37+2.6*j),Vector3(23,y*2.3,14),j+11)
		a.cypress(set,Vector3(x+0.3,y*0.54,36+2.6*j),2.05)
	crag(set,Vector3(138,6,-62),Vector3(28,23,23),13)
	temple(set,Vector3(137,13.4,-62))
	for i in 18:
		var x:=11+i*11.9
		var j:=i%6
		a.cypress(set,Vector3(x,1.7+j*0.15,-35.4-sin(i)*6),1.12+j*0.17)
	# Rugged cliff edges frame the last stretch of the upper canal.
	for z in [-1,1]:
		for j in 5:crag(set,Vector3(161+j*6.4,-0.3,-3+z*(9.2+j*0.27)),Vector3(7,6,5),j+3)
	batch(set)

func hill_village(p:Node3D)->void:
	var set:=a.group(p)
	var homes:=[Vector3(234,7.0,-10),Vector3(244,7.7,-9),Vector3(259,8.0,0),Vector3(258,8.7,10),Vector3(251.8,9.2,26)]
	for i in homes.size():
		var pt:Vector3=homes[i]
		var wall:=a.box(set,pt-Vector3.UP*3.9,Vector3(8.7,7.7,8.4),B.STONE);wall.material_override=mineral("#b4a084","#96836c")
		var house:=villa(set,pt,5.1+0.57*(i%3),3.9+0.72*(i%2),0.12 if i<2 else -1.42,i)
		a.cypress(set,pt+Vector3(2.95,0,2.95),1.81)
		plant(set,pt+Vector3(1.2,0.4,3.6),i)
	var wall:=a.box(set,Vector3(209,8,47),Vector3(11.4,14,10.6),B.STONE);wall.material_override=mineral("#ae9a80","#8f7e6e")
	for j in 6:crag(set,Vector3(204+j*1.9,4.6,52.2),Vector3(5.9,17-j%2*2,6),j)
	for j in 4:
		var pt:=Vector3(202+j*1.19,15.05,51.4)
		plant(set,pt+Vector3.UP*0.4,j)
	a.cypress(set,Vector3(203.2,15,50.9),2.12)
	batch(set)
	headland_props(p)

func batch(root:Node3D)->void:
	# Static decorative pieces share meshes and materials. Batch each group in local space.
	var inverse:=root.global_transform.affine_inverse()
	var buckets:Dictionary={}
	for n:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		if n.mesh==null or n.material_override==null:continue
		var key:=Vector2i(n.mesh.get_instance_id(),n.material_override.get_instance_id())
		if not buckets.has(key):buckets[key]=[n.mesh,n.material_override,[]]
		buckets[key][2].append(inverse*n.global_transform)
	for child in root.get_children():child.free()
	for entry:Array in buckets.values():
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=entry[0];multi.instance_count=entry[2].size()
		for i in multi.instance_count:multi.set_instance_transform(i,entry[2][i])
		var n:=MultiMeshInstance3D.new();n.multimesh=multi;n.material_override=entry[1];root.add_child(n)
