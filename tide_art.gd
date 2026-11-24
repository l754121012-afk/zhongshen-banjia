extends RefCounted

const Finish=preload("res://harbour_materials.gd")
const Art=preload("res://workshop.gd")
const SALT:="#e4d2ac"
const STONE:="#a99b82"
const SHADE:="#576d70"
const BRASS:="#db9e43"
const BLUE:="#326e83"
const INK:="#213f49"
const SIGNAL:="#80e6cc"
const CLAY:="#c35f4d"
var art:=Art.new()
var lamps:Dictionary={}
var board_gate:Node3D
var hatch:Node3D
var mast:Node3D
var sail:Node3D
var wheel:Node3D
var furled:Node3D
var lighthouse_rays:Node3D
var wake:Array[MeshInstance3D]=[]
var tide_water:Node3D
var lock_front:Node3D
var lock_back:Node3D
var lock_float:Node3D
var tower_beacon:Node3D
var pennants:Array[Node3D]=[]
var dock_lights:Array[Node3D]=[]

func glow(color:String)->StandardMaterial3D:
	if not lamps.has(color):
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=Color(color)
		mat.emission_enabled=true
		mat.emission=Color(color)
		mat.emission_energy_multiplier=0.8
		lamps[color]=mat
	return lamps[color]

func light_stone(p:Node3D,point:Vector3,size:Vector3,color:String)->MeshInstance3D:
	var m:=art.ball(p,point,size,color,true)
	m.material_override=glow(color)
	return m

func water(p:Node3D,point:Vector3,size:Vector3,dark:String,bright:String)->Node3D:
	var m:=art.box(p,point,size,dark)
	var shader:=ShaderMaterial.new()
	shader.shader=preload("res://tide_sea.gdshader")
	shader.set_shader_parameter("deep",Color(dark))
	shader.set_shader_parameter("shallows",Color(bright))
	m.material_override=shader
	return m

func arch(p:Node3D,base:Vector3,radius:float,spring:float,depth:float,yaw:=0.0)->Node3D:
	var root:=art.group(p,base)
	root.rotation.y=yaw
	var thick:=clampf(radius*0.22,0.42,1.24)
	for side in [-1,1]:
		art.box(root,Vector3(side*(radius+thick/2),spring/2,0),Vector3(thick,spring,depth),SALT)
		art.box(root,Vector3(side*(radius+thick/2),spring,0),Vector3(thick+0.23,0.23,depth+0.18),STONE)
	for j in 13:
		var a:=PI*(j+0.5)/13
		var mid:=radius+thick*0.5
		var stone:=art.box(root,Vector3(cos(a)*mid,spring+sin(a)*mid,0),Vector3(2*mid*tan(PI/26)+0.05,thick,depth),SALT if j%3 else "#cbb794")
		stone.rotation.z=a+PI/2
		stone.material_override=Finish.sample(0,SALT if j%3 else "#c3ae8d",3.6,true,0.59)
	return root

func flag(p:Node3D,point:Vector3,color:String)->Node3D:
	art.beam(p,point,point+Vector3.UP*2.4,0.055,Art.WOOD)
	var n:=art.group(p,point+Vector3.UP*2.1)
	var cloth:=art.box(n,Vector3(0.51,-0.12,0),Vector3(1.02,0.45,0.055),color)
	cloth.rotation.z=-0.14
	pennants.append(n)
	return n

func lens(p:Node3D)->Node3D:
	var root:=art.group(p)
	art.cyl(root,Vector3.UP*0.13,0.70,0.62,0.26,BRASS)
	var jewel:=light_stone(root,Vector3.UP*0.86,Vector3(1.02,1.18,1.02),"#72dbc8")
	jewel.rotation.z=0.18
	for j in 2:
		var ring:=art.ring(root,Vector3.UP*0.91,0.67+j*0.07,0.051,BRASS)
		ring.rotation=Vector3(PI/2,j*PI/2,0.20)
	art.ball(root,Vector3.UP*1.60,Vector3.ONE*0.18,Art.GOLD)
	return root

func ballast(p:Node3D)->Node3D:
	var n:=art.group(p)
	for i in 3:
		art.box(n,Vector3(0,0.17+i*0.29,0),Vector3(1.13-i*0.13,0.27,0.97-i*0.1),SHADE)
	for x in [-0.33,0.33]:
		art.box(n,Vector3(x,0.52,0),Vector3(0.085,1.03,0.80),BRASS)
	var ring:=art.ring(n,Vector3.UP*1.05,0.22,0.062,BRASS)
	ring.rotation.x=PI/2
	return n

func cart(p:Node3D)->Node3D:
	var n:=art.group(p)
	art.box(n,Vector3.UP*0.17,Vector3(1.49,0.2,1.44),Art.WOOD)
	for x in [-0.56,0.56]:
		for z in [-0.54,0.54]:
			var w:=art.cyl(n,Vector3(x,0.11,z),0.17,0.17,0.12,INK)
			w.rotation.z=PI/2
	return n

func socket(p:Node3D,point:Vector3,color:String)->Node3D:
	var n:=art.group(p,point)
	art.box(n,Vector3(0,0.018,0),Vector3(1.64,0.035,1.64),INK)
	var rim:=art.ring(n,Vector3.UP*0.05,0.62,0.058,color)
	rim.material_override=glow(color)
	for dx in [-0.72,0.72]:
		for dz in [-0.72,0.72]: art.box(n,Vector3(dx,0.06,dz),Vector3(0.16,0.045,0.16),color)
	return n

func build_depot(p:Node3D,blocked:Array[Vector2i])->void:
	art.box(p,Vector3(8,-0.67,6),Vector3(18.5,1.06,14.3),STONE)
	for x in 9:
		for z in 7:
			var base:=Vector3(x*2,-0.065,z*2)
			var slab:=art.box(p,base,Vector3(1.96,0.13,1.96),SALT)
			slab.material_override=Finish.sample(2,"#d2be9c" if (x+z)%3 else "#caba99",4.1,true,0.5)
			if z in [2,4] and x>0:
				for off in [-0.48,0.48]: art.box(p,base+Vector3(0,0.083,off),Vector3(2,0.035,0.055),"#857b69")
	for cell in blocked:
		var center:=Vector3(cell.x*2,0,cell.y*2)
		var pedestal:=art.box(p,center+Vector3.UP*0.55,Vector3(1.89,1.1,1.88),STONE)
		art.box(p,center+Vector3.UP*1.12,Vector3(1.93,0.16,1.90),SALT)
		if cell.y%2==0:
			art.jar(p,center+Vector3(0.32,1.18,0),0.98,CLAY)
			art.jar(p,center+Vector3(-0.46,1.18,-0.25),0.72,BLUE)
		else:
			art.crate(p,center+Vector3.UP*1.19,1.2)
	for x in [-1.2,3.4,8.0,12.6,17.2]:
		art.column(p,Vector3(x,0,-1.15),4.3)
	for x in [1.1,5.7,10.3,14.9]:
		arch(p,Vector3(x,0,-1.35),1.92,2.1,0.72)
	art.box(p,Vector3(8,4.55,-1.2),Vector3(20.0,0.28,1.2),CLAY)
	for x in [0.4,5.2,14.5]:
		var tapestry:=art.box(p,Vector3(x,2.35,-1.67),Vector3(1.9,3.2,0.09),BLUE)
		var med:=art.ring(tapestry.get_parent(),Vector3(x,2.9,-1.57),0.53,0.055,BRASS)
		med.rotation.x=PI/2
	for z in [2,6,10]:
		arch(p,Vector3(-1.3,0,z),1.65,1.35,0.6,PI/2)
	board_gate=art.group(p,Vector3(10,0,8))
	for z in [-0.77,0.77]:
		art.cyl(board_gate,Vector3(0,0.75,z),0.1,0.1,1.5,BRASS)
	for h in [0.43,1.0]: art.box(board_gate,Vector3(0,h,0),Vector3(0.2,0.15,1.72),BLUE)
	var chain:=art.group(p,Vector3(9.6,1.45,8))
	art.beam(chain,Vector3.ZERO,Vector3(0,2.0,-2.0),0.048,BRASS)
	for j in 4:
		art.box(p,Vector3(17.35+j*0.39,-0.02,8),Vector3(0.36,0.16,3.0),Art.WOOD)
	for z in [3.8,11.7]: flag(p,Vector3(17.1,0,z),CLAY)
	# Painted line links the physical plate to the raised portcullis.
	for x in range(6,11): art.box(p,Vector3(x,0.035,4),Vector3(0.93,0.027,0.085),BRASS)
	for z in range(5,9): art.box(p,Vector3(10,0.035,z),Vector3(0.085,0.027,0.93),BRASS)

func sail_mesh(p:Node3D)->Node3D:
	var cloth:=art.group(p)
	for j in 8:
		var mesh:=SurfaceTool.new()
		mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		for k in 5:
			for d:Vector2i in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.ONE,Vector2i.ZERO,Vector2i.ONE,Vector2i.DOWN]:
				var u:float=(j+d.x)/8.0
				var v:float=(k+d.y)/5.0
				var point:=Vector3(0.28+sin(v*PI)*sin(u*PI)*0.88+v*0.55,1.4+v*3.0,(u-0.5)*(3.8-v*0.8))
				mesh.add_vertex(point)
		mesh.generate_normals()
		var panel:=art.shape(cloth,mesh.commit(),Vector3.ZERO,CLAY if j%3!=0 else "#e2ac7a")
		panel.material_override=Finish.sample(3,CLAY if j%3!=0 else "#e2b683",0.76,false,.54)
	return cloth

func shipwright(hull:Node3D)->void:
	var section_x:=[-5.45,-4.6,-3.5,2.9,4.6,5.5,6.15]
	var breadth:=[1.89,2.65,2.76,2.76,2.40,1.37,0.12]
	for flank in [-1,1]:
		for row in 4:
			for j in 6:
				var x0:float=section_x[j];var x1:float=section_x[j+1]
				var v:=float(row)/4
				var h0:= -0.76+v*0.92+maxf(0,absf(x0)-4.4)*0.17
				var h1:= -0.76+v*0.92+maxf(0,absf(x1)-4.4)*0.17
				var a:=Vector3(x0,h0,float(flank)*breadth[j]*(0.83+0.17*v))
				var b:=Vector3(x1,h1,float(flank)*breadth[j+1]*(0.83+0.17*v))
				var c:=Vector3(x0,h0+0.25,float(flank)*breadth[j]*(0.88+0.17*v))
				var d:=Vector3(x1,h1+0.25,float(flank)*breadth[j+1]*(0.88+0.17*v))
				var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
				for point:Vector3 in [a,b,c,b,d,c]:st.set_normal(Vector3(0,0,flank));st.add_vertex(point)
				var mat:=art.material(["#3a534f","#335f60","#397470","#c39458"][row]).duplicate() as StandardMaterial3D
				mat.cull_mode=BaseMaterial3D.CULL_DISABLED
				var n:=MeshInstance3D.new();n.mesh=st.commit();n.material_override=mat;hull.add_child(n)
				if row==3:art.beam(hull,c,d,0.075,Art.WOOD)
		for x in [-3.5,-2.4,-1.3,0.0,1.3,2.4,3.5]:
			var side:=Vector3(x,-0.12,flank*2.76)
			art.ball(hull,side,Vector3(.10,.095,.12),BRASS,true)
		for j in 4:
			var a:=Vector3(3.1+j*0.43,0.12,flank*(1.74-j*0.30))
			art.beam(hull,a,a+Vector3(.34,0.018,-flank*.25),.042,SALT)
	for j in 6:
		var x:=4.55+j*.255
		art.box(hull,Vector3(x,0.065+j*0.043,0),Vector3(.245,.16,maxf(.40,4.65-j*.82)),"#b0835e")
	for side in [-1,1]:
		art.beam(hull,Vector3(4.25,.34,side*2.24),Vector3(5.98,.70,side*.15),.081,BRASS)
	var curl:=art.ring(hull,Vector3(6.03,.92,0),.42,.095,BRASS);curl.rotation.x=PI/2
	for z in [-1.87,1.87]:
		for j in 4:art.ring(hull,Vector3(-3.92,0.10+j*.041,z),.32-j*.032,.031,"#d2ae78")
	for i in 3:
		var wood:=art.box(hull,Vector3(-4.70-i*0.18,.065,.07),Vector3(.19,.14,4.65),Art.WOOD)
		wood.rotation.z=-0.08
	for j in 5:
		var a:=j*TAU/5
		art.beam(hull,Vector3(3.91,1.01,0),Vector3(3.91,1.01+cos(a)*.55,sin(a)*.55),.037,Art.WOOD)

func make_ferry(p:Node3D)->Node3D:
	var n:=art.group(p)
	art.box(n,Vector3(0,-0.36,0),Vector3(9.6,0.62,5.4),BLUE)
	for side in [-1,1]:
		art.box(n,Vector3(0,-0.14,side*2.74),Vector3(9.7,0.20,0.12),BRASS)
		for x in [-4.4,0.0,4.4]:
			var fender:=art.ring(n,Vector3(x,-0.32,side*2.81),0.32,0.095,INK)
			fender.rotation.x=PI/2
	for x in range(17):
		var plank:=art.box(n,Vector3((x-8)*0.54,0,0),Vector3(0.515,0.13,5.38),Art.WOOD)
		plank.material_override=Finish.sample(1,"#bf9369" if x%3 else "#ab835d",4.9,false,.76)
	for z in [-2.47,2.47]:
		for x in [-4.45,3.9]:
			art.cyl(n,Vector3(x,0.43,z),0.095,0.115,0.84,BRASS)
		art.beam(n,Vector3(-4.45,0.64,z),Vector3(3.9,0.64,z),0.046,Art.WOOD)
	mast=art.group(n,Vector3(2.4,0.06,0))
	art.cyl(mast,Vector3.UP*2.42,0.14,0.085,4.84,Art.WOOD)
	art.beam(mast,Vector3(0.8,4.42,-1.65),Vector3(0.8,4.42,1.65),0.076,BRASS)
	sail=sail_mesh(mast)
	furled=art.group(mast,Vector3(.8,4.43,0))
	var roll:=art.cyl(furled,Vector3.ZERO,.19,.19,3.7,"#c8996b");roll.rotation.x=PI/2
	for z in [-1.4,-.49,.49,1.4]:
		var lashing:=art.ring(furled,Vector3(0,0,z),.19,.026,Art.WOOD);lashing.rotation.x=PI/2
	for flank in [-1,1]:
		art.beam(mast,Vector3(.81,4.46,flank*1.65),Vector3(.08,1.18,flank*2.05),.027,"#a2865d")
		art.beam(mast,Vector3(.06,4.66,0),Vector3(-1.10,.11,flank*2.0),.029,"#977c5b")
	shipwright(n)
	flag(mast,Vector3(0,3.15,0),Art.TEAL)
	wheel=art.ring(n,Vector3(3.9,1.02,0),0.45,0.07,BRASS)
	wheel.rotation.z=PI/2
	art.cyl(n,Vector3(3.9,0.44,0),0.18,0.13,0.8,Art.WOOD)
	for side in [-1,1]:
		for j in 3:
			var foam:=art.ball(n,Vector3(-4.8-j*1.45,-0.49,side*(1.6+j*0.73)),Vector3(2.2,0.12,0.28),"#a9d7cc")
			wake.append(foam)
	return n

func reef(p:Node3D,point:Vector2,radius:float)->void:
	var center:=Vector3(point.x,-0.62,point.y)
	art.ball(p,center,Vector3(radius*2,1.85,radius*1.75),"#a18c78",true)
	art.ball(p,center+Vector3(-0.15*radius,0.62,0),Vector3(radius*1.5,1.5,radius*1.24),"#b9a88a",true)
	if radius>2.5:
		art.ball(p,center+Vector3(0.4,1.37,-0.2),Vector3(radius*1.1,0.57,radius*0.9),"#779078",true)
		art.cypress(p,center+Vector3(-0.5,1.43,-0.15),1.03)
	for i in 3:
		var a:=i*TAU/3
		art.ball(p,center+Vector3(cos(a)*radius*0.8,0.36,sin(a)*radius*0.8),Vector3(radius*0.57,0.87,radius*0.70),STONE,true)

func buoy(p:Node3D,point:Vector2,color:String)->Node3D:
	var n:=art.group(p,Vector3(point.x,-0.5,point.y))
	art.cyl(n,Vector3.UP*0.22,0.48,0.25,0.52,color)
	art.cyl(n,Vector3.UP*0.81,0.18,0.12,0.78,BRASS)
	light_stone(n,Vector3.UP*1.31,Vector3(0.42,0.54,0.42),color)
	return n

func tower(p:Node3D,base:Vector3)->Node3D:
	var n:=art.group(p,base)
	art.cyl(n,Vector3.UP*2.3,2.0,1.60,4.6,SALT,12)
	art.cyl(n,Vector3.UP*5.25,1.62,1.35,1.5,CLAY,12)
	art.cyl(n,Vector3.UP*7.2,1.35,1.1,2.7,SALT,12)
	art.cyl(n,Vector3.UP*8.68,1.6,1.58,0.30,BRASS)
	for j in 6:
		var dir:=Vector3(cos(j*TAU/6),0,sin(j*TAU/6))
		art.beam(n,dir*1.12+Vector3.UP*8.83,dir*1.12+Vector3.UP*11,0.07,INK)
	art.cyl(n,Vector3.UP*11.36,1.53,0.08,0.96,CLAY)
	tower_beacon=light_stone(n,Vector3.UP*9.88,Vector3.ONE*1.23,SIGNAL)
	tower_beacon.hide()
	lighthouse_rays=art.group(n,Vector3.UP*9.88)
	var mat:=StandardMaterial3D.new();mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color(1.0,.88,.56,.09);mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	for side in [-1,1]:
		var ray:=art.cyl(lighthouse_rays,Vector3(side*8.0,0,0),1.80,.14,16,BRASS,20);ray.rotation.z=side*PI/2
		ray.material_override=mat;ray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lighthouse_rays.hide()
	return n

func build_coast(p:Node3D,reefs:Array[Vector3])->void:
	water(p,Vector3(100,-0.79,0),Vector3(460,0.4,310),"#104569","#238c9a")
	for rock in reefs: reef(p,Vector2(rock.x,rock.z),rock.y)
	# Low abandoned aqueduct: clearance is visible from the mast, an outer channel stays open.
	for z in [-7.8,0.0,7.8]:
		arch(p,Vector3(65,-1.1,z),3.38,1.63,2.0,PI/2)
	art.box(p,Vector3(65,4.7,0),Vector3(2.3,0.39,24.5),STONE)
	for z in [-4.0,4.0]:
		flag(p,Vector3(65,4.92,z),CLAY)
	for point:Vector2 in [Vector2(54,-3),Vector2(54,3),Vector2(76,-3),Vector2(76,3)]:
		buoy(p,point,SIGNAL)
	for point:Vector2 in [Vector2(57,-14),Vector2(76,-15),Vector2(110,10)]:
		buoy(p,point,"#f2bc65")
	# Distant islands sit behind the harbours and do not define the course.
	for i in 14:
		var x:=i*13.5+6
		var z:float=-34-6*sin(i*1.4)
		var h:float=2.6+2.5*(1+sin(i*0.8))
		art.ball(p,Vector3(x,-2.4,z),Vector3(26,h*2,16),"#b4a28c",true)

	for i in 8:
		art.ball(p,Vector3(30+i*25,-5,-64-i%3*6),Vector3(40,21+i%4*4,24),"#8c9f99",true)
		if i%3==0: arch(p,Vector3(32+i*23,-0.8,35),4.5,2.9,3.0)
	for i in 6:
		var pos:=Vector3(85+i*17,-0.8,24+sin(i)*4)
		art.ball(p,pos,Vector3(7.0,3.5,6.2),STONE,true)
	for x in [128,153]:
		for z in [-9.8,3.8]: flag(p,Vector3(x,2.0,z),BLUE)
	for side in [-1,1]:
		var z:float=-3+side*6.0
		art.box(p,Vector3(144,1.45,z),Vector3(25,4.9,1.48),STONE)
		art.box(p,Vector3(144,4.0,z),Vector3(25.3,0.28,1.65),SALT)
		for j in 7:
			art.box(p,Vector3(133+j*3.65,1.28,z),Vector3(0.63,5.22,1.85),SALT)
	tide_water=water(p,Vector3(144,-0.70,-3),Vector3(24,0.19,10.55),"#397d81","#70a79c")
	lock_back=art.group(p,Vector3(132,0,-3))
	lock_front=art.group(p,Vector3(156,0,-3))
	for barrier:Node3D in [lock_back,lock_front]:
		for i in 9:
			art.box(barrier,Vector3(0,1.55,i*1.25-5),Vector3(0.58,5.3,1.20),Art.WOOD)
		for y in [0.22,2.65]:
			art.box(barrier,Vector3(0,y,0),Vector3(0.72,0.26,11.3),BRASS)
	lock_back.position.y=-6.3
	var gauge:=art.group(p,Vector3(146,0,-8.05))
	art.box(gauge,Vector3.UP*2.4,Vector3(1.9,5.2,0.18),INK)
	for i in 11: art.box(gauge,Vector3(0.42,i*0.44,0.16),Vector3(0.48 if i%2==0 else 0.27,0.055,0.06),SALT)
	art.box(gauge,Vector3(-0.17,3.55,0.20),Vector3(1.28,0.32,0.09),SIGNAL)
	lock_float=art.group(gauge)
	art.box(lock_float,Vector3(0,0,0.36),Vector3(1.73,0.095,0.12),BRASS)
	for z in [-10.6,4.6]:
		art.box(p,Vector3(174,0.85,z),Vector3(38,5.0,3.4),STONE)
	water(p,Vector3(174,2.82,-3),Vector3(38,0.28,12),"#397d81","#70a79c")
	for x in [160,168,176,184]:
		for z in [-8.2,2.2]: buoy(p,Vector2(x,z),SIGNAL).position.y=3
	var island:=Vector3(196,2.92,-4)
	art.box(p,island,Vector3(14,1.4,17),SALT)
	arch(p,island+Vector3(4,0.7,-5),2.3,2.3,1.0)
	tower(p,Vector3(203.2,15.05,40))
	for i in 5:
		art.box(p,Vector3(190+i*0.46,3.2+i*0.15,-4),Vector3(0.52,0.4,3.3),SALT)
