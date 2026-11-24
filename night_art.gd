extends RefCounted

const Art=preload("res://workshop.gd")
const Bay=preload("res://tide_art.gd")
const OBSIDIAN:="#293748"
const MARBLE:="#879392"
const COPPER:="#a98059"
const GILT:="#d4a763"
var art:=Art.new()
var bay:=Bay.new()
var flames:Array[Node3D]=[]
var wisps:Array[Node3D]=[]
var moon:Node3D
var oars:Array[Node3D]=[]
var rudder:Node3D
var lantern:Node3D
var water_mat:ShaderMaterial

func emission(col:String,power:float)->StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=Color(col);m.emission_enabled=true;m.emission=Color(col);m.emission_energy_multiplier=power
	return m
func glow(p:Node3D,at:Vector3,sz:Vector3,col:String,power:=1.5)->MeshInstance3D:
	var n:=art.ball(p,at,sz,col,true);n.material_override=emission(col,power);return n
func lamp(p:Node3D,at:Vector3,col:String,power:float,radius:float)->void:
	var l:=OmniLight3D.new();l.light_color=Color(col);l.light_energy=power;l.omni_range=radius;l.position=at;p.add_child(l)
func flame(p:Node3D,at:Vector3,col:String)->void:
	art.cyl(p,at+Vector3.UP*0.45,0.48,0.34,0.9,OBSIDIAN,8)
	art.cyl(p,at+Vector3.UP*0.92,0.37,0.56,0.26,COPPER,10)
	var f:=art.group(p,at+Vector3.UP*1.07)
	var outer:=art.ball(f,Vector3(-.015,.22,0),Vector3(.41,.52,.36),"#df793b",true)
	outer.material_override=emission("#db702f",.40)
	var tip:=art.cyl(f,Vector3(.045,.49,0),.17,.015,.41,"#e18f40",8);tip.rotation.z=-.27;tip.material_override=emission("#e18c43",.51)
	var wick:=art.ball(f,Vector3(-.06,.16,.065),Vector3(.22,.36,.23),"#f9b964",true);wick.material_override=emission("#f8b760",.66)
	flames.append(f)
func label(p:Node3D,at:Vector3,words:String,face:Font,tint:String)->Label3D:
	var l:=Label3D.new();l.position=at;l.text=words;l.font=face;l.font_size=29;l.pixel_size=0.019
	l.modulate=Color(tint);l.outline_modulate=Color("#142434");l.outline_size=7;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	p.add_child(l);return l

func horizon(p:Node3D)->void:
	var sea:=art.box(p,Vector3(0,-0.76,0),Vector3(330,0.40,300),"#293654")
	water_mat=ShaderMaterial.new();water_mat.shader=preload("res://stygian_water.gdshader");sea.material_override=water_mat
	for i in 27:
		var a:=i*TAU/27;var dir:=Vector3(cos(a),0,sin(a))
		var at:Vector3=dir*(66+i%5*2.9)
		var h:float=8.3+(i%7)*3.3+sin(i*1.72)*3
		var crag:=art.ball(p,at-Vector3.UP*2.6,Vector3(18+i%6*1.8,h,15.0),"#485368" if i%3 else "#65627a",true)
		crag.rotation.y=i*1.4
		if i%3==1:
			var c:=art.group(p,at+Vector3.UP*(h*0.42-2.8))
			for j in 4:
				art.cyl(c,Vector3(j*1.5,1.6,0),0.31,0.23,3.2,MARBLE,8)
			art.box(c,Vector3(2.25,3.35,0),Vector3(6,0.42,1.0),MARBLE)
	var rng:=RandomNumberGenerator.new();rng.seed=89014
	for i in 100:
		var a:=rng.randf()*TAU;var height:=rng.randf_range(0.13,1.18)
		var dir:=Vector3(cos(a)*cos(height),sin(height),sin(a)*cos(height))
		var star:=glow(p,dir*122,Vector3.ONE*rng.randf_range(0.06,0.22),"#b1ccd2",1.45)
		star.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	moon=glow(p,Vector3(42,27,-91),Vector3.ONE*10.5,"#f1d8af",1.35)
	for i in 18:
		var w:=glow(p,Vector3(rng.randf_range(-37,39),rng.randf_range(0.3,2.2),rng.randf_range(-28,28)),Vector3.ONE*0.11,"#89c6bb",1.2)
		wisps.append(w)

func terrace(p:Node3D,at:Vector3,dir:Vector2,index:int,col:String)->Node3D:
	var root:=art.group(p,at)
	root.rotation.y=-dir.angle()
	# The seaward nose ends at the embarkation light; all solid architecture sits landward.
	art.ball(root,Vector3(9.2,-0.52,0),Vector3(18,4.8,15),OBSIDIAN,true)
	art.cyl(root,Vector3(9,1.23,0),6.5,6.2,0.90,MARBLE,12)
	for j in 10:art.box(root,Vector3(0.28+j*0.58,0.0+j*0.125,0),Vector3(0.66,0.25,3.65),COPPER if j%3==0 else MARBLE)
	for z in [-2.13,2.13]:
		art.cyl(root,Vector3(1.2,0.6,z),0.20,0.18,1.8,COPPER,8)
		flame(root,Vector3(4.4,0.87,z),col)
	lamp(root,Vector3(3.1,3,0),col,2.6,8.7)
	match index:
		0:
			for z in [-3.1,3.1]:
				art.cyl(root,Vector3(8,3.7,z),0.63,0.44,4.1,MARBLE,10)
				art.box(root,Vector3(8,5.88,z),Vector3(1.55,0.33,1.50),GILT)
			art.box(root,Vector3(8,6.24,0),Vector3(1.85,0.50,8.2),MARBLE)
			for z in [-1.6,0,1.6]:
				art.beam(root,Vector3(8,6.1,z),Vector3(8,4.85,z),0.035,GILT)
				var token:=art.ring(root,Vector3(8,4.6,z),0.32,0.071,GILT);token.rotation.z=PI/2
		1:
			for j in 7:
				var a:=j*TAU/7
				var tree:=art.group(root,Vector3(9.2+cos(a)*3.5,1.65,sin(a)*3.55))
				art.cyl(tree,Vector3.UP*1.6,0.23,0.15,3.2,COPPER,8)
				art.ball(tree,Vector3.UP*3.45,Vector3(2.45,2.5,2.28),"#486c70",true)
				for k in 4:
					var b:=k*TAU/4+j
					glow(tree,Vector3(cos(b)*0.88,2.9+0.23*(k%2),sin(b)*0.88),Vector3.ONE*0.32,"#f6a16b",0.7)
		2:
			for tier in 5:
				var radius:=3.0+tier*0.83
				for j in 13:
					var a:float=lerpf(-PI*0.64,PI*0.64,j/12.0)
					var seat:=art.box(root,Vector3(7+cos(a)*radius,1.70+tier*0.51,sin(a)*radius),Vector3(0.94,0.62,radius*0.37),"#a4a5a0" if tier%2 else "#757d81")
					seat.rotation.y=-a
					seat.material_override=preload("res://harbour_materials.gd").sample(0,"#a7a7a1" if tier%2 else "#80868a",3.2,true,.63)
			for z in [-4.8,4.8]:flame(root,Vector3(8,2,z),col)
			var lyre:=art.ring(root,Vector3(7,4,0),1.05,0.13,GILT);lyre.rotation.z=PI/2
			for j in 5:art.beam(root,Vector3(7,3.19,(j-2)*0.23),Vector3(7,4.83,(j-2)*0.26),0.029,GILT)
		3:
			for z in [-2.45,2.45]:
				art.ball(root,Vector3(9.6,3.1,z),Vector3(4.1,4.5,3.8),"#976851",true)
				art.cyl(root,Vector3(10.25,5.45,z),0.67,0.48,2.8,COPPER,10)
				var door:=art.ball(root,Vector3(7.73,2.42,z),Vector3(0.23,1.4,1.2),"#f4a46e",true)
				door.material_override=emission("#f6a568",2.0)
				flame(root,Vector3(9.5,6.95,z),col)
	return root

func NightColor(id:int)->String:return "#b3b1a1" if id<4 else "#4e5769"

func ghost(p:Node3D,id:int,col:String)->Node3D:
	var g:=art.group(p)
	var hem:=art.cyl(g,Vector3.UP*0.65,0.47,0.27,1.20,col,10)
	hem.material_override=emission(col,0.34)
	var hood:=art.ball(g,Vector3.UP*1.58,Vector3(0.73,0.82,0.64),col,true)
	hood.material_override=emission(col,0.42)
	art.ball(g,Vector3(0.28,1.55,0),Vector3(0.22,0.45,0.42),OBSIDIAN,true)
	for z in [-0.09,0.09]:glow(g,Vector3(0.39,1.60,z),Vector3.ONE*0.063,"#f7eaba",1.1)
	var mantle:=art.ball(g,Vector3(0,1.15,0),Vector3(.76,.47,.69),col,true)
	mantle.material_override=emission(col,.22)
	for j in 7:
		var q:float=TAU*j/7
		var lower:=Vector3(cos(q)*.385,.18+.057*(j%3),sin(q)*.385)
		var upper:=Vector3(cos(q)*.24,1.07,sin(q)*.24)
		art.beam(g,lower,upper,.019,NightColor(id))
	for flank in [-1,1]:
		var arm:=art.ball(g,Vector3(.16,1.06,flank*.32),Vector3(.30,.41,.20),col,true);arm.rotation.z=.42
		art.ball(g,Vector3(.29,.96,flank*.33),Vector3(.18,.17,.14),"#e3c5a2",true)
	if id==4:
		var badge:=art.ring(g,Vector3(-.29,1.0,0),.155,.029,GILT);badge.rotation.z=PI/2
		for j in 4:art.ball(g,Vector3(-.33,.78+j*.062,(j-1.5)*.07),Vector3(.065,.11,.14),GILT,true)
	if id==0:
		var l:=art.ring(g,Vector3(0.32,0.91,0.36),0.31,0.069,GILT);l.rotation.z=PI/2
	elif id==1:glow(g,Vector3(0.26,0.86,0.41),Vector3(0.28,0.55,0.28),"#ffbc68",1.65)
	elif id==2:art.ball(g,Vector3(0.27,0.81,0.32),Vector3.ONE*0.66,"#ac7153",true)
	else:
		art.box(g,Vector3(0.19,1.72,0),Vector3(0.68,0.18,0.62),GILT)
	return g

func ferry(p:Node3D)->Node3D:
	var n:=art.group(p)
	var hull:=art.ball(n,Vector3(0,-0.04,0),Vector3(7.8,1.16,2.68),"#343343",true)
	art.box(n,Vector3(0,0.31,0),Vector3(5.75,0.15,2.38),"#865d4d")
	for j in 13:
		var plank:=art.box(n,Vector3((j-6)*0.42,0.40,0),Vector3(0.38,0.065,2.2),COPPER)
		plank.material_override=preload("res://harbour_materials.gd").sample(1,"#9d7857" if j%3==0 else "#866952",3.40,false,.68)
	for side in [-1,1]:
		var z:float=side*1.23
		art.beam(n,Vector3(-2.9,0.47,z),Vector3(2.9,0.47,z),0.084,GILT)
		for end in [-1,1]:
			art.beam(n,Vector3(end*2.9,0.47,z),Vector3(end*3.85,1.0,0),0.12,GILT)
			art.beam(n,Vector3(end*3.85,1.0,0),Vector3(end*4.03,1.53,0),0.12,GILT)
		var o:=art.group(n,Vector3(-1.48,0.7,z*0.83))
		art.beam(o,Vector3(0.36,0.07,-side*0.47),Vector3(-0.43,-0.42,side*1.28),0.065,COPPER)
		art.ball(o,Vector3(-0.48,-0.49,side*1.42),Vector3(0.38,0.13,0.60),GILT,true)
		oars.append(o)
	for x in [0.02,1.43]:art.box(n,Vector3(x,0.60,0),Vector3(0.50,0.28,2.0),COPPER)
	var ferryman:=ghost(n,4,"#778799");ferryman.position=Vector3(-2.08,0.40,0);ferryman.scale=Vector3.ONE*1.14
	art.beam(n,Vector3(-2.64,0.42,-0.5),Vector3(-1.86,3.22,0.39),0.075,GILT)
	art.beam(n,Vector3(2.46,0.46,-0.71),Vector3(2.46,2.62,-0.71),0.075,COPPER)
	art.beam(n,Vector3(2.46,2.63,-0.71),Vector3(2.89,2.63,-0.71),0.056,COPPER)
	lantern=glow(n,Vector3(2.9,2.15,-0.71),Vector3(0.39,0.57,0.39),"#ffd28a",2.2)
	lamp(n,Vector3(1.48,2.15,-0.35),"#ffbf83",4.7,8.5)
	return n
