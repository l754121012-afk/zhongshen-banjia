extends Node3D

const Art=preload("res://workshop.gd")
const Bay=preload("res://tide_art.gd")
const Craft=preload("res://coastal_craft.gd")
const Materials=preload("res://harbour_materials.gd")
const Wind=preload("res://zephyr_weather.gd")
const BRIDGE_START:=59.0
const BRIDGE_END:=72.5
const TOWER:=Vector2(100,-4)
const PAD:=Vector2(94,-0.8)
const BANK:=preload("res://zephyr_coast.gd").START
const APPROACH:=preload("res://zephyr_coast.gd").ROAD
const MILL_PORT:=Vector2(93,2.4)
const LOW:=Vector2(66,12)
const STONE_ROAD:=[Vector2(30,0),Vector2(39,-6),Vector2(47,-17),Vector2(57,-23),Vector2(68,-24),Vector2(76,-17.8),Vector2(84,-12.5),Vector2(92,-3)]
const HOLLOW:=[Vector2(46,5),Vector2(52,10),Vector2(60,14),Vector2(69,14.5),Vector2(76,12.4),Vector2(83,8),Vector2(93,2.4)]
var art:=Art.new()
var design:=Bay.new()
var craft:=Craft.new()
var solids:Array[Rect2]=[]
var flags:Array[Node3D]=[]
var leaves:Array[Node3D]=[]
var leaf_roots:Array[Vector2]=[]
var cloths:Array[Node3D]=[]
var banners:Array[Node3D]=[]
var wheels:Array[Node3D]=[]
var flour_sacks:Array[Node3D]=[]
var shutters:Array[Node3D]=[]
var channels:Array[Node3D]=[]
var dust:Array[Node3D]=[]
var rings:Array[Node3D]=[]
var target_ring:Node3D
var miller:Node3D
var apprentice:Node3D
var port_crank:Node3D
var winding:Node3D
var blades:Node3D
var bakery_smoke:Array[Node3D]=[]
var front_cart:Node3D
var shadow_cart:Node3D
var rope_hand:Node3D
var cart_rope:MeshInstance3D
var winding_post:Node3D
var fabric_root:Node3D
var mill_angle:=0.0
var front_cart_pos:=Vector2.ZERO
var front_cart_speed:=0.0
var release_wave:=1000.0
var release_origin:=Vector2.ZERO
var courier_film:=0.0
var result_blend:=0.0
var target_result:=0.0
var festival:=preload("res://zephyr_festival.gd").new()
var canvas_wings:Array[Node3D]=[]
var orchard:=preload("res://zephyr_orchard.gd").new()
var people:=preload("res://zephyr_people.gd").new()
var tower_root:Node3D
var bake_root:Node3D
var coastal:=preload("res://zephyr_coast.gd").new()
var dressing:=preload("res://zephyr_dressing.gd").new()
var theme_font:=preload("res://harbour_fonts.gd").body()

var harbour_end:=false
func ground(p:Vector2)->float:
	var upland:=smoothstep(11,43,p.x)*6.3
	var valley:=smoothstep(49,61,p.x)*(1.0-smoothstep(71.5,86,p.x))
	var northern_rim:=1.0-smoothstep(9,21,-p.y)
	var banks:=smoothstep(16,38,p.x)*(1-smoothstep(83,94,p.x))
	var base:=upland-valley*northern_rim*10.8+banks*.32*sin(p.x*.22+p.y*.13)
	if harbour_end:
		base=lerpf(base,-10.4,smoothstep(100.5,111.5,p.x)*smoothstep(-24.,-14.,p.y))
	var shore:=maxf(smoothstep(22.8+1.8*sin(p.x*.11),33.2+sin(p.x*.13)*2.4,p.y),smoothstep(29.5,40.,-p.y))
	shore=maxf(shore,maxf(smoothstep(110.,122.,p.x),smoothstep(65.,76.,-p.x)))
	return lerpf(base,-11.0+1.3*sin(p.x*.50+p.y*.34),shore)

func surface(p:Vector2)->Vector3:return Vector3(p.x,ground(p),p.y)
func deck(p:Vector2)->bool:
	return absf(p.y)<3.10 and ((p.x>=47.5 and p.x<=BRIDGE_START) or (p.x>=BRIDGE_END and p.x<=86.0))
func deck_y(p:Vector2)->float:return lerpf(ground(Vector2(47.5,0)),6.74,clampf((p.x-47.5)/7.,0,1)) if p.x<60 else lerpf(6.60,ground(Vector2(86,0)),smoothstep(79,86,p.x))
func surface_kind(p:Vector2,at_y:float)->int:
	if deck(p) and at_y>deck_y(p)-.52:return 3
	if p.x>49 and p.x<87 and p.y>5. and ground(p)<4.6:return 2
	if p.x>28 and p.x<92 and route_distance(p,STONE_ROAD)<4.0:return 0
	if p.x<3 and route_distance(p,APPROACH)<3.9:return 0
	if (p.x<50 or p.x>84) and absf(p.y-.8*sin(p.x*.12))<3.8:return 0
	return 1

func ground_for_wheels(p:Vector2,y:float)->float:
	var g:=ground(p)
	if deck(p) and y>=deck_y(p)-.50:return maxf(g,deck_y(p))
	return g
func valid(p:Vector2,on_foot:=false)->bool:
	if p.x<(-71. if on_foot else -65.) or p.x>111.4 or p.y< -29.5 or p.y>24.5:return false
	for rect in solids:
		if rect.grow(.13 if on_foot else .34).has_point(p):return false
	return true
func obstacle(at:Vector2,sz:Vector2)->void:solids.append(Rect2(at-sz/2,sz))

func label(parent:Node3D,at:Vector3,words:String,sz:=.011)->Label3D:
	var l:=Label3D.new();l.font=theme_font;l.text=words;l.font_size=26;l.pixel_size=sz
	l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.outline_size=6;l.outline_modulate=Color("#244149");l.modulate=Color("#fff0bf")
	parent.add_child(l);l.position=at;return l
func node_at(p:Vector2)->Node3D:return art.group(self,surface(p))
func route_distance(p:Vector2,nodes:Array)->float:
	var best:=INF
	for i in nodes.size()-1:
		var a:Vector2=nodes[i];var b:Vector2=nodes[i+1]
		best=minf(best,Geometry2D.get_closest_point_to_segment(p,a,b).distance_to(p))
	return best

func build_land()->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-78,125,2):
		for z in range(-38,35,2):
			for k:Vector2i in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.RIGHT,Vector2i.ONE,Vector2i.DOWN]:
				var p:=Vector2(x+k.x*2,z+k.y*2)
				var d:=minf(route_distance(p,STONE_ROAD),route_distance(p,HOLLOW))
				var direct:=absf(p.y-.8*sin(p.x*.12))
				if p.x>=1 and p.x<49 or p.x>84:d=minf(d,direct)
				if p.x<3:
					d=route_distance(p,APPROACH)
					d=minf(d,route_distance(p,[Vector2(-36,11),Vector2(-24,11.7),Vector2(-20,11),Vector2(-17,5),Vector2(-19,-2)])+.78)
				var rock:=smoothstep(0.28,.78,absf(ground(p+Vector2.RIGHT)-ground(p)))
				var col:=Color("#627b46").lerp(Color("#91a060"),.48+.23*sin(p.x*.19+p.y*.4))
				col=col.lerp(Color("#9e886e"),rock)
				col=col.lerp(Color("#bb9d79"),1-smoothstep(2.55,4.6,d))
				if p.distance_to(BANK)<9 or p.x>89:col=col.lerp(Color("#baa780"),.8*(1-smoothstep(7,14,absf(p.y))))
				var dx:=ground(p+Vector2.RIGHT*.5)-ground(p-Vector2.RIGHT*.5)
				var dz:=ground(p+Vector2.DOWN*.5)-ground(p-Vector2.DOWN*.5)
				st.set_uv(Vector2(1-smoothstep(2.8,4.4,d),0));st.set_color(col.srgb_to_linear());st.set_normal(Vector3(-dx,1,-dz).normalized());st.add_vertex(surface(p))
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit()
	var mat:=ShaderMaterial.new();mat.shader=preload("res://zephyr_ground.gdshader");mesh.material_override=mat;add_child(mesh)
	design.water(self,Vector3(50,-9.5,0),Vector3(340,.5,310),"#174d64","#3c9494")
	for i in 13:
		var p:=Vector3(-18+i*13,-2,-48-9*sin(i*.81))
		craft.outcrop(self,p,Vector3(25,16+i%4*3,20),i+2)
	for i in 10:
		var p:=Vector3(-16+i*15,-3.0,35+i%3*1.4)
		craft.outcrop(self,p,Vector3(19,14+i%3*2,13),i+31)

func mast(p:Vector2,tint:String,high:=3.1)->void:
	var n:=node_at(p)
	art.beam(n,Vector3.ZERO,Vector3.UP*high,.055,Art.WOOD)
	var pivot:=art.group(n,Vector3.UP*(high-.18));pivot.rotation.y=-Wind.FLOW.angle()
	for j in 3:
		var pennant:=art.box(pivot,Vector3(.29+j*.51,-.21-j*.06,0),Vector3(.55,.40-j*.095,.034),tint if j!=1 else "#e7c68e")
		pennant.rotation.z=-.11
	flags.append(pivot)
func olive(parent:Node3D,p:Vector2,size:float,seed_i:int)->void:
	var root:=art.group(parent,surface(p))
	root.scale=Vector3.ONE*size
	art.beam(root,Vector3(-.15,0,0),Vector3(.10,1.8,.05),.20,"#715b4b")
	for j in 3:
		var a:=j*TAU/3+seed_i
		art.beam(root,Vector3(.06,1,0),Vector3(.82*cos(a),2.15,.82*sin(a)),.12,"#88745a")
	var crown:=art.group(root,Vector3(0,1.97,0))
	for j in 5:
		var a:=j*2.39+seed_i
		var point:=Vector3(cos(a)*.88,.32+.35*sin(a*2),sin(a)*.73)
		var leaf:=art.ball(crown,point,Vector3(1.55,.80,1.13),"#4c6546" if j%2 else "#6b7d56",true)
		var glint:=art.ball(crown,point-Vector3.UP*.26,Vector3(1.21,.40,.98),"#bdc4a1",true)
		glint.rotation.z=.22
	leaves.append(crown);leaf_roots.append(p)
func plank(p:Node3D,at:Vector3,sz:Vector3,col:String)->Node3D:
	var b:=art.box(p,at,sz,col);b.material_override=Materials.sample(1,col,5.2,false,.65);return b
func brick(p:Node3D,at:Vector3,sz:Vector3,col:String)->Node3D:
	var b:=art.box(p,at,sz,col);b.material_override=Materials.sample(0,col,3.5,true,.57);return b
func wingwheel(parent:Node3D,at:Vector3,rad:float,flank:int)->Node3D:
	var rotor:=art.group(parent,at)
	for j in 8:
		var wing:=art.group(rotor);wing.rotation.x=TAU*j/8
		art.beam(wing,Vector3.ZERO,Vector3(0,rad,0),rad*.018,Art.WOOD)
		var reef:=art.group(wing);canvas_wings.append(reef)
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var top:=Vector3(flank*.045,rad*.98,0)
		var inner:=Vector3(flank*.045,rad*.18,0)
		var trailing:=Vector3(flank*.092,rad*.63,rad*.44)
		var belly:=Vector3(flank*.155,rad*.65,rad*.15)
		for v:Vector3 in [top,inner,belly,inner,trailing,belly,trailing,top,belly]:
			st.set_normal(Vector3(flank,0,0));st.add_vertex(v)
		var panel:=MeshInstance3D.new();panel.mesh=st.commit();panel.material_override=Materials.sample(3,"#f1d4a2" if j%2 else "#d7ae73",1.15,false,.63);reef.add_child(panel)
		art.beam(reef,inner,trailing,.032,"#a88b62")
		art.beam(reef,trailing,top,.032,"#a28664")
		art.beam(reef,Vector3(flank*.08,rad*.46,.04),Vector3(flank*.14,rad*.75,rad*.29),.022,"#be9566")
		art.beam(wing,Vector3(0,rad*.91,0),Vector3(0,rad*.91*cos(TAU/8),rad*.91*sin(TAU/8)),.026,"#a28b67")
	var hub:=art.cyl(rotor,Vector3.ZERO,rad*.114,rad*.10,.44,Bay.BRASS);hub.rotation.z=PI/2
	return rotor

func build_bridge()->void:
	for side in [0,1]:
		var a:=47.5 if side==0 else BRIDGE_END;var b:=BRIDGE_START if side==0 else 86.0
		for j in ceili((b-a)/.82):
			var x:=a+.40+j*.82
			if x>b:break
			plank(self,Vector3(x,deck_y(Vector2(x,0))-.1,0),Vector3(.81,.22,6.0),"#b38a61")
		for flank in [-1,1]:
			var z:float=flank*3.05
			art.beam(self,Vector3(a,deck_y(Vector2(a,0))-.3,z),Vector3(b,deck_y(Vector2(b,0))-.3,z),.21,Art.WOOD)
			var j:=a+.5
			while j<b:
				art.beam(self,Vector3(j,deck_y(Vector2(j,0)),z),Vector3(j,deck_y(Vector2(j,0))+1.03,z),.11,"#956d49")
				j+=2.85
			art.beam(self,Vector3(a+.4,deck_y(Vector2(a,0))+.77,z),Vector3(b-.4,deck_y(Vector2(b,0))+.77,z),.035,"#a0825c")
		var end:=a if side==1 else b
		for z in [-2.45,2.45]:
			var o:=Vector3(end,deck_y(Vector2(end,0))-.14,z)
			art.beam(self,o,o+Vector3(-1.12 if side else 1.12,-1.44,.29),.13,Art.WOOD)
	design.arch(self,Vector3(56,ground(Vector2(56,0))-.35,0),2.9,1.8,.85)
	design.arch(self,Vector3(76,ground(Vector2(76,0))-.35,0),2.65,1.45,.85)
	for x in [45,51,56,74,80]:mast(Vector2(x,-3.45),Bay.CLAY,2.5)
	for j in 6:olive(self,Vector2(56+j*3.3,5.1+sin(j)*1.8),1.10+j%3*.13,21+j)
	for j in 6:
		var p:Vector2=STONE_ROAD[j+1];p.y-=5.5
		var n:=node_at(p);brick(n,Vector3.UP*.43,Vector3(2.8,.86,.62),Bay.SALT);obstacle(p,Vector2(2.65,.56))
		n.rotation.y=-.3*sin(j)
	for p:Vector2 in [Vector2(41,-9.6),Vector2(49,-19.5),Vector2(68,-27),Vector2(80,-16.2)]:mast(p,"#648a81",2.45)
	for j in 8:
		var p:=Vector2(53+j*3.2,16.3+sin(j*.8))
		var n:=node_at(p);art.jar(n,Vector3.ZERO,.64+.18*(j%3),Bay.BLUE)
		if j%2==0:mast(p,Bay.SIGNAL,2.1)
	var old:=node_at(Vector2(65,21))
	brick(old,Vector3.UP*1.15,Vector3(5.2,2.3,3.6),"#a89a80")
	design.arch(old,Vector3(0,0,-2),1.25,1.03,.67)
	var cracked:=art.ring(old,Vector3(2.5,1.6,-1.89),1.53,.20,Art.WOOD);cracked.rotation.x=PI/2
	for k in 4:
		var spoke:=art.box(old,Vector3(2.5,1.6,-1.89),Vector3(3,.10,.13),Art.WOOD);spoke.rotation.z=k*PI/4

func banner_frame(parent:Node3D,at:Vector3)->void:
	var n:=art.group(parent,at)
	for side in [-1,1]:art.beam(n,Vector3(side*1.45,0,0),Vector3(side*1.45,3.3,0),.10,Art.WOOD)
	art.beam(n,Vector3(-1.55,3.27,0),Vector3(1.55,3.27,0),.085,Art.WOOD)
	var fabric:=art.group(n,Vector3(0,3.15,0))
	for k in 7:
		var panel:=art.box(fabric,Vector3(-1.21+k*.405,-1.14+.04*sin(k),.06*sin(k*1.3)),Vector3(.43,2.28,.065),Bay.CLAY if k%3 else "#efc890")
		panel.material_override=Materials.sample(3,Bay.CLAY if k%3 else "#efc890",.75,false,.54)
	cloths.append(fabric)
func flour(parent:Node3D,at:Vector3)->Node3D:
	var n:=art.group(parent,at)
	art.ball(n,Vector3.UP*.54,Vector3(.87,1.11,.78),"#d7b887",true)
	art.cyl(n,Vector3.UP*1.07,.18,.12,.18,"#997650")
	var knot:=art.ring(n,Vector3.UP*.98,.20,.033,Bay.BLUE)
	return n
func make_mill(parent:Node3D,at:Vector2)->void:
	var n:=art.group(parent,surface(at));tower_root=n
	for i in 2:art.cyl(n,Vector3.UP*(.2+i*.30),4.4-i*.32,4.4-i*.32,.32,Bay.SALT,24)
	var wall:=art.cyl(n,Vector3.UP*4.40,3.35,2.54,7.75,"#dcc69c",24)
	wall.material_override=Materials.sample(0,"#ddcda9",5.45,true,.45)
	art.cyl(n,Vector3.UP*8.45,2.96,.15,2.18,"#bd7751",16)
	for k in 3:art.cyl(n,Vector3.UP*(2.9+k*2.35),3.26-k*.24,3.24-k*.24,.18,"#bcaa8f",24)
	blades=wingwheel(n,Vector3(-3.02,6.05,0),5.33,-1)
	art.box(n,Vector3(-3.27,1.12,0),Vector3(.17,2.1,1.34),Bay.BLUE)
	for j in 3:
		var g:=art.group(n,Vector3(-2.62,4.23,(j-1)*1.26));g.rotation.y=-PI/2
		art.window(g,Vector3.ZERO,.76,1.0)
	var shelter:=art.group(n,Vector3(-4.6,.1,-3.3))
	for z in [-1.22,1.22]:art.column(shelter,Vector3(0,0,z),2.7)
	craft.cloth(shelter,Vector3(-.1,2.84,0),3.3,Bay.BLUE)
	winding=art.group(n,Vector3(-4.31,1.5,-.40))
	art.ring(winding,Vector3.ZERO,.83,.085,Art.WOOD).rotation.z=PI/2
	for j in 4:
		var spoke:=art.box(winding,Vector3.ZERO,Vector3(.11,1.61,.11),Bay.BRASS);spoke.rotation.x=j*PI/4
	for i in 3:flour_sacks.append(flour(n,Vector3(-4.32,.05,-1.7-i*.74)))
	for j in 3:banner_frame(n,Vector3(1.6+j*3.55,0,5.1))
	var bread:=art.group(n,Vector3(-2.2,0,-9.9));bake_root=bread
	craft.villa(bread,Vector3.ZERO,5.8,4.5,-PI/2,1)
	obstacle(at+Vector2(-2.2,-9.9),Vector2(3.9,5.6))
	for j in 2:
		var pivot:=art.group(bread,Vector3(-2.14,2.42,-.57+j*1.2))
		art.box(pivot,Vector3(0,0,(j*2-1)*.26),Vector3(.13,1.12,.53),Bay.BLUE)
		shutters.append(pivot)
	for j in 5:bakery_smoke.append(art.ball(bread,Vector3(1.2,5.2+j*.39,-.55),Vector3.ONE*.5,"#d8d5c1",true))
	obstacle(at,Vector2(6,6))
	miller=art.courier(n);miller.position=Vector3(-5.1,0,1.7);miller.rotation.y=-PI/2
	var g:=node_at(PAD)
	art.cyl(g,Vector3.DOWN*.09,1.6,1.59,.18,Bay.STONE,20)
	var socket:=art.ring(g,Vector3.UP*.06,.81,.084,Bay.BRASS)
	for i in 9:
		var tube:=art.cyl(n,Vector3(-5.5+i*.58,.32,.42+i*.19),.36,.34,.68,Bay.BLUE,10);tube.rotation.z=PI/2
		var flange:=art.ring(n,tube.position+Vector3(.30,0,0),.375,.040,Bay.BRASS);flange.rotation.z=PI/2
		var spark:=art.ball(n,tube.position+Vector3.UP*.35,Vector3.ONE*.23,"#ecd394",true);channels.append(spark)
func build_home()->void:
	var g:=node_at(BANK+Vector2(-11,-7.5))
	craft.villa(g,Vector3.ZERO,6.3,4.1,.08,0)
	craft.cloth(g,Vector3(0,3.41,2.43),5.2,Bay.CLAY)
	obstacle(BANK+Vector2(-11,-7.5),Vector2(6.3,4))
	apprentice=art.courier(self);apprentice.position=surface(BANK+Vector2(-9,-2));apprentice.rotation.y=1.2
	var winch:=node_at(BANK+Vector2(-10,-3.2))
	for z in [-.55,.55]:art.box(winch,Vector3(0,.62,z),Vector3(.23,1.24,.23),Art.WOOD)
	port_crank=art.group(winch,Vector3.UP*1.18)
	art.cyl(port_crank,Vector3.ZERO,.34,.34,1.16,Bay.BRASS).rotation.x=PI/2
	art.beam(port_crank,Vector3(0,0,-.73),Vector3(.37,.26,-.73),.06,Art.WOOD)
	flour(winch,Vector3(0,0,1.35))
	for p:Vector2 in [Vector2(-12,8.5),Vector2(-14,3.2),Vector2(4,-8),Vector2(14,9.1),Vector2(22,-9),Vector2(35,9),Vector2(49,-12),Vector2(88,13),Vector2(98,11)]:
		olive(self,BANK+p if p.x<0 else p,1.1+fmod(absf(p.x),4)*.10,int(p.x))
	for i in 5:
		var at:=Vector2(6+i*6.2,-5.7-(i%2))
		mast(at,Bay.CLAY,2.8+i%2*.35)
	for i in 7:
		var g2:=node_at(Vector2(2.8+i*2.55,4.75))
		art.beam(g2,Vector3.ZERO,Vector3.UP*1.45,.08,Bay.BRASS)
		var horn:=art.group(g2,Vector3.UP*1.60);horn.rotation.x=-1.15
		art.cyl(horn,Vector3.ZERO,.12,.38,.62,"#b59353",12)
		art.cyl(horn,Vector3.UP*.32,.33,.34,.014,"#496a65",12)
		art.ring(horn,Vector3.UP*.34,.36,.041,"#dac18b")
	for j in 6:
		var v:=BANK+Vector2(-6+j*1.53,9.0);var n:=node_at(v)
		craft.plant(n,Vector3.UP*.23,j)
	target_ring=art.ring(self,surface(MILL_PORT)+Vector3.UP*.10,2.31,.076,Bay.BRASS)
	front_cart=art.group(self);plank(front_cart,Vector3.UP*.52,Vector3(1.58,.24,2.0),Art.WOOD)
	for flank in [-1,1]:
		for z in [-.65,.65]:
			var wheel:=art.cyl(front_cart,Vector3(flank*.90,.38,z),.40,.40,.14,Bay.INK,10);wheel.rotation.z=PI/2
			wheels.append(wheel)
	for x in [-.68,.68]:art.beam(front_cart,Vector3(x,.65,.83),Vector3(x,.99,2.38),.06,Art.WOOD)
	art.crate(front_cart,Vector3(-.1,.67,-.17),.70)
	var hauler:=node_at(Vector2(29.6,-7.16))
	rope_hand=art.courier(hauler);rope_hand.rotation.y=.15
	art.cyl(rope_hand,Vector3(0,1.78,0),.41,.38,.10,"#c2a87b",12)
	winding_post=art.group(hauler,Vector3(-.83,.92,.17));art.cyl(winding_post,Vector3.ZERO,.29,.29,.74,"#936e4f").rotation.z=PI/2
	for j in 3:art.ring(winding_post,Vector3((j-1)*.22,0,0),.32,.035,"#ba9b65").rotation.z=PI/2
	cart_rope=art.cyl(self,Vector3.ZERO,.024,.024,1.0,"#987a51",7)
	shadow_cart=art.group(self);art.ring(shadow_cart,Vector3.ZERO,.76,.07,Bay.CLAY)
	for k in 14:
		var o:=art.ball(self,Vector3.ZERO,Vector3(.45,.035,.13),"#c8c8a2",true);dust.append(o)

func _ready()->void:
	build_land();build_home();build_bridge();make_mill(self,TOWER);dressing.build(self);coastal.build(self);people.build(self,tower_root,bake_root);festival.build(self)
	orchard.leaves(self);orchard.sampler()
	var mural_p:=BANK+Vector2(-5.27,-5.62)
	orchard.mural(self,surface(mural_p),4.49,2.97,-.16,true);obstacle(mural_p,Vector2(4.6,.32))
	var altar:=coastal.shrine
	orchard.mural(altar,Vector3(0,.09,.85),1.93,1.65,PI)
	# The storage rack leaves open space around both ends and ample access to the original ramp.
	var rack_p:=BANK+Vector2(-7.67,-.97)
	var rack:=node_at(rack_p)
	plank(rack,Vector3.UP*.12,Vector3(.99,.24,2.39),"#987249")
	for k in 3:art.crate(rack,Vector3(0,.24,(k-1)*.71),.72)
	art.crate(rack,Vector3(.03,.87,-.48),.64)
	obstacle(rack_p,Vector2(.91,2.20))
	target_ring.visible=false
func apply_result(level:int,immediate:=false)->void:
	target_result=float(level)
	if immediate:result_blend=target_result
func gust_cart_z(t:float)->float:
	var phase:=fposmod(t-Vector2(29.,-4.).dot(Wind.FLOW)/10.,Wind.PERIOD)
	if phase<1.28:return -6.35
	if phase<3.42:return lerpf(-6.35,6.75,smoothstep(1.28,3.42,phase))
	return lerpf(6.75,-6.35,smoothstep(4.15,8.05,phase))
func pulse(origin:Vector2)->void:release_origin=origin;release_wave=0
func tick(dt:float,t:float)->void:
	orchard.tick(t,release_origin,release_wave)
	dressing.wheat_material.set_shader_parameter("wind_time",t)
	release_wave+=dt
	for n in flags:
		var p:=Vector2(n.global_position.x,n.global_position.z)
		var gust:=Wind.pressure(p,t)
		n.rotation.z=-.97+gust*.89+.07*sin(t*6+p.x*.32)
	for j in leaves.size():
		var g:=Wind.breeze(leaf_roots[j],t)
		var wave:=exp(-absf(leaf_roots[j].distance_to(release_origin)-release_wave*16)*.52) if release_wave<2.5 else 0.
		leaves[j].rotation.z=-.06-g*.21-wave*.73
		leaves[j].rotation.x=.055*sin(t*2+j)-wave*.24
	var last:=front_cart_pos
	front_cart_pos=Vector2(29,gust_cart_z(t));front_cart.position=surface(front_cart_pos)
	front_cart.rotation.y=.12*sin(t*2);front_cart_speed=(front_cart_pos.y-last.y)/maxf(dt,.001)
	for n in wheels:n.rotate_x(-front_cart_speed*dt*2)
	var start:=winding_post.global_position
	var end:=front_cart.global_position+Vector3(-.34,.64,-.7)
	cart_rope.position=(start+end)*.5;cart_rope.scale.y=start.distance_to(end)
	cart_rope.quaternion=Quaternion(Vector3.UP,start.direction_to(end));cart_rope.visible=front_cart_speed<-.32
	rope_hand.get_node("ArmR").rotation.x=-.72+.49*sin(t*5.4)*clampf(-front_cart_speed/3.,0,1)
	winding_post.rotation.x+=dt*front_cart_speed
	shadow_cart.position=surface(Vector2(29,-4))+Vector3.UP*.09
	shadow_cart.visible=Wind.pressure(Vector2(29,-7),t)>.1 and front_cart_pos.y< -2.1
	for j in dust.size():
		var anchor:=Vector2(12+j*5.9,-3+sin(j*1.9)*6.5)
		var g:=Wind.pressure(anchor,t)
		dust[j].visible=g>.20
		if g>.20:
			var p:=anchor+Wind.FLOW*(fposmod(t*6+j*1.31,6)-3)
			dust[j].position=surface(p)+Vector3.UP*(.16+.23*sin(t*2+j));dust[j].rotation.y=-Wind.FLOW.angle()
	result_blend=move_toward(result_blend,target_result,dt*.78)
	festival.tick(t,result_blend)
	for i in canvas_wings.size():
		var pleat:=.41 if i%4==0 else .105
		canvas_wings[i].scale.z=lerpf(pleat,1.,smoothstep(.96,1.98,result_blend))
	mill_angle+=dt*(.047 if result_blend<.05 else .11+.70*result_blend)
	blades.rotation.x=mill_angle if result_blend>1.05 else sin(t*.66)*.023
	winding.rotation.x+=dt*(.17+result_blend*1.55)
	port_crank.rotation.z=t*1.22
	apprentice.get_node("ArmR").rotation.x=-.85+.62*sin(t*2.0)
	miller.get_node("ArmR").rotation.x=lerpf(-.82+.52*sin(t*2),-.18,clampf(result_blend,0,1))
	for i in flour_sacks.size():flour_sacks[i].position.y=.05+.27*(1+sin(t*1.4+i))*minf(result_blend,1)
	for i in cloths.size():
		var open:=clampf(result_blend-1.0,0,1)
		cloths[i].scale.y=.12+.88*open
		cloths[i].rotation.x=.18*sin(t*3+i)*open
	for i in shutters.size():shutters[i].rotation.y=(1 if i==0 else -1)*clampf(result_blend-1.,0,1)*1.42
	for i in bakery_smoke.size():
		bakery_smoke[i].visible=result_blend>1.32
		if bakery_smoke[i].visible:
			var u:=fposmod(t*.33+i*.2,1)
			bakery_smoke[i].position=Vector3(1.2+u*2.24,5.42+u*3.4,-.55+sin(u*2)*.53)
			bakery_smoke[i].scale=Vector3.ONE*(.48+u*1.23)
	for i in channels.size():channels[i].visible=result_blend>.03 and fposmod(t*5-i,9)<1.85

