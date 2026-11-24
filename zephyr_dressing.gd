extends RefCounted
## Fixed coastal landmarks, wayside shrines and fields share the playable terrain.
const Art=preload("res://workshop.gd")
const Craft=preload("res://coastal_craft.gd")
const Mats=preload("res://harbour_materials.gd")
var art:=Art.new()
var craft:=Craft.new()
var land
var set:Node3D
var rng:=RandomNumberGenerator.new()
var wheat_material:=ShaderMaterial.new()
var flow_lines:Array[MeshInstance3D]=[]
var ribbons:Array[Node3D]=[]
var seal_root:Node3D
var bread_tray:Node3D
var oven_glow:MeshInstance3D
var baker:Node3D
var signal_lamp:MeshInstance3D
const FIELD:=preload("res://zephyr_stalks.gdshader")

func fixed(p:Vector2)->Node3D:return art.group(set,land.surface(p))
func blocks(p:Vector2,size:Vector2)->void:land.obstacle(p,size)
func slab(p:Node3D,at:Vector3,sz:Vector3,col:String)->MeshInstance3D:
	var n:=art.box(p,at,sz,col);n.material_override=Mats.sample(0,col,3.1,true,.54);return n
func pier(p:Node3D,v:Vector3)->void:
	slab(p,v+Vector3.UP*.24,Vector3(.97,.48,.93),"#ae9974")
	slab(p,v+Vector3.UP*.83,Vector3(.77,.87,.73),"#c9b48a")
	slab(p,v+Vector3.UP*1.37,Vector3(.90,.19,.87),"#d2bf9d")
func waypost(p:Vector2,yaw:float,tone:String,symbol:String)->void:
	var n:=fixed(p);n.rotation.y=yaw
	pier(n,Vector3.ZERO)
	art.box(n,Vector3.UP*2.1,Vector3(.15,1.7,.15),"#805337")
	var board:=art.box(n,Vector3(-.10,2.67,0),Vector3(.13,.89,1.49),tone)
	for z in [-.59,.59]:art.box(n,board.position+Vector3(-.08,0,z),Vector3(.045,.80,.045),"#dfbf7b")
	if symbol=="bridge":
		for sign_z in [-1,1]:
			art.beam(n,Vector3(-.21,2.69,sign_z*.46),Vector3(-.21,2.69,sign_z*.15),.047,"#ffdc99")
			art.beam(n,Vector3(-.21,2.46,sign_z*.40),Vector3(-.21,2.69,sign_z*.40),.04,"#ffdc99")
		art.beam(n,Vector3(-.21,2.63,-.14),Vector3(-.21,2.76,.14),.04,"#ffdc99")
	else:
		for j in 3:
			art.beam(n,Vector3(-.21,2.63+j*.06,-.37+j*.28),Vector3(-.21,2.63+j*.06,-.18+j*.28),.046,"#e6d5a8")
func shrine(p:Vector2)->void:
	var n:=fixed(p);n.rotation.y=.16
	for i in 3:slab(n,Vector3.UP*(i*.21+.12),Vector3(2.7-i*.34,.24,2.7-i*.34),"#b5a080")
	var column:=art.cyl(n,Vector3.UP*1.64,.63,.50,2.0,"#d4c49e",12)
	column.material_override=Mats.sample(0,"#cab68d",2.,true,.6)
	slab(n,Vector3.UP*2.69,Vector3(1.51,.28,1.52),"#c7ae81")
	# Wind god in profile, with two swept wings and five hollow bronze pipes.
	art.ball(n,Vector3(0,3.22,0),Vector3(.78,.85,.66),"#728c7e",true)
	art.ball(n,Vector3(-.37,3.27,.02),Vector3(.40,.27,.30),"#82998b",true)
	for s in [-1,1]:
		for j in 4:
			var at:=Vector3(.23+j*.16,3.35+j*.13,s*(.20+j*.13))
			var quill:=art.ball(n,at,Vector3(.65,.20,.22),"#8ea292",true);quill.rotation.z=.45
		art.ring(n,Vector3(-.10,3.23,.32*s),.075,.029,"#d7b36a").rotation.x=PI/2
	for j in 5:
		var h:=.5+.12*j
		art.cyl(n,Vector3(-.78,1.29+h*.5,(j-2)*.15),.067,.067,h,"#c69c58",8)
		art.cyl(n,Vector3(-.78,1.30+h,(j-2)*.15),.048,.048,.021,"#4d5147",8)
func cliff_village()->void:
	for i in 7:
		var p:=Vector3(9+i*17,1.3+2*sin(i*.93),-46-i%3*1.8)
		craft.outcrop(set,p-Vector3.UP*3.3,Vector3(25,15,17),81+i)
		var top:=p+Vector3.UP*3.05
		craft.villa(set,top,4.5+i%3*.45,3.5+.45*(i%3),i*.28,i)
		if i%2==0:craft.villa(set,top+Vector3(4.4,-.19,-1.4),3.9,3.2,.2*i,3-i)
		art.cypress(set,top+Vector3(-3.3,-.15,1.12),1.55)
	# Islands beyond the destination close the skyline at driving height.
	for i in 7:
		var p:=Vector3(125+i%3*11,-8.2,-59+i*17)
		var h:=22.+4.3*(i%3)
		craft.outcrop(set,p,Vector3(35.,h,28.),132+i)
		if i in [1,3,6]:
			var top:=p+Vector3.UP*(h*.43)
			if i==3:craft.temple(set,top)
			else:craft.villa(set,top,5.1,4.5,.8*i,i)
			for j in 4:art.cypress(set,top+Vector3(-6.1+j*2.1,0,1.3+sin(j)),1.5+(j%3)*.24)
	for i in 4:
		var n:=fixed(Vector2(32+i*7,-30.4+i%2*.9))
		craft.villa(n,Vector3.ZERO,4.+i%2*.7,3.5+i%2*.71,.24*i,i)
		art.cypress(n,Vector3(-3.5,0,1.6),1.45)
func market()->void:
	var stall:=fixed(land.BANK+Vector2(-9.8,5.35))
	for x in [-1.48,1.48]:
		for z in [-.75,.75]:
			art.beam(stall,Vector3(x,0,z),Vector3(x,2.9,z),.071,"#79563c")
	for j in 8:
		var roof:=art.box(stall,Vector3((j-3.5)*.43,2.88,0),Vector3(.44,.080,2.20),"#ad5d49" if j%2 else "#dcc38e")
		roof.rotation.x=-.11
		art.box(stall,Vector3((j-3.5)*.43,2.70,-1.08),Vector3(.43,.18,.05),"#ad5d49" if j%2 else "#dcc38e")
	art.box(stall,Vector3.UP*.84,Vector3(3.3,.17,1.18),"#956e4a");blocks(land.BANK+Vector2(-9.8,5.35),Vector2(3.0,1.25))
	for j in 6:art.jar(stall,Vector3(-1.18+j*.45,.93,.1*sin(j)),.34+.1*(j%3),"#a96743" if j%2 else "#4f817c")
	for p:Vector2 in [Vector2(-13.0,4),Vector2(-12.1,4.3),Vector2(-14.4,-1.3)]:
		craft.barrel(set,land.surface(land.BANK+p),.9)
	craft.plant(stall,Vector3(-1.98,.16,.42),3)
	shrine(Vector2(11.3,-6.4))
	waypost(Vector2(38.5,-4.3),-.18,"#346e65","lane");waypost(Vector2(44.1,3.7),.13,"#9d563d","bridge")
	# Two gates suggest the fork before either route disappears behind the trees.
	for p:Vector2 in [Vector2(44.6,-9.5),Vector2(40.2,-14.2)]:
		var g:=fixed(p);pier(g,Vector3.ZERO)
	for p:Vector2 in [Vector2(33,6.3),Vector2(40,7.6),Vector2(52,-8.3),Vector2(89,-7)]:
		var n:=fixed(p);art.cypress(n,Vector3.ZERO,1.50);art.cypress(n,Vector3(1.38,0,.74),1.09)
func make_field(st:SurfaceTool,p:Vector2,scale_s:float,tint:Color)->void:
	var ground:Vector3=land.surface(p)
	var angle:=rng.randf_range(-PI,PI)
	for j in 4:
		var a:=angle+j*1.8;var right:=Vector3(cos(a),0,sin(a))*.047*scale_s
		var base:=ground+Vector3(j*.040,0,j*.030)
		var mid:=base+Vector3(.055,.39,.02)*scale_s
		var tip:=mid+Vector3(.095,.28+j*.031,.036)*scale_s
		for v:Vector3 in [base-right*.32,base+right*.32,mid,mid-right,mid+right,tip]:
			st.set_color(tint);st.set_uv(Vector2(0,clampf((v.y-ground.y)/.75,0,1)));st.set_normal(Vector3.UP);st.add_vertex(v)
func farms()->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for plot:Vector4 in [Vector4(-30,20,12,5),Vector4(8,12,19,7),Vector4(20,-17,20,9),Vector4(37,16,14,8),Vector4(57,-12,13,6),Vector4(85,17,15,8),Vector4(93,-20,19,9),Vector4(107,9,12,10)]:
		for row in ceili(plot.w*2.0):
			for col in ceili(plot.z*1.95):
				if rng.randf()<.10:continue
				var p:=Vector2(plot.x-plot.z*.5+col*.51+rng.randf_range(-.19,.19),plot.y-plot.w*.5+row*.50+rng.randf_range(-.10,.10))
				var t:=rng.randf()
				make_field(st,p,rng.randf_range(.7,1.36),Color("#a07536").lerp(Color("#e4be67"),t).srgb_to_linear())
	wheat_material.shader=FIELD
	var harvest:=MeshInstance3D.new();harvest.mesh=st.commit();harvest.material_override=wheat_material;land.add_child(harvest)
	for i in 47:
		var x:=rng.randf_range(-12,107)
		var z:=rng.randf_range(-27,21)
		var p:=Vector2(x,z)
		if absf(z)<6 or p.distance_to(land.TOWER)<11 or land.route_distance(p,land.HOLLOW)<4.4 or land.route_distance(p,land.STONE_ROAD)<4.2:continue
		var n:=fixed(p)
		if i%4==0:craft.plant(n,Vector3.UP*.15,i)
		else:
			art.cypress(n,Vector3.ZERO,rng.randf_range(.9,1.75))
			if i%3==0:art.cypress(n,Vector3(1.1,0,.33),.88)
func verge()->void:
	for i in 62:
		var p:=Vector2(rng.randf_range(-12,99),rng.randf_range(-27,22))
		if p.distance_to(land.TOWER)<9 or absf(p.y)<4.3 or land.route_distance(p,land.STONE_ROAD)<3.2 or land.route_distance(p,land.HOLLOW)<3.5:continue
		var n:=fixed(p)
		for j in 3:
			var v:=Vector3(j*.29,.13+(.05 if j%2 else 0),sin(j*3.1)*.25)
			art.ball(n,v,Vector3(.91-j*.18,.43,.63),"#998d72" if j%2 else "#b5a68a",true)
	for i in 11:
		var p:=Vector2(35+i*4.1,-14.1-12*sin(i*.32))
		var n:=fixed(p);pier(n,Vector3.ZERO)
	for i in 8:
		var p:=Vector2(52+i*3.4,19.4+.55*sin(i*.77));var n:=fixed(p)
		art.beam(n,Vector3.ZERO,Vector3(.06,1.03,-.02),.085,"#826346")
		if i<7:
			var dest:=Vector2(52+(i+1)*3.4,19.4+.55*sin((i+1)*.77))
			art.beam(set,land.surface(p)+Vector3.UP*.78,land.surface(dest)+Vector3.UP*.78,.042,"#b49b6c")
func build(terrain)->void:
	land=terrain;rng.seed=39731
	set=art.group(terrain)
	cliff_village();market();farms();verge();craft.batch(set)
