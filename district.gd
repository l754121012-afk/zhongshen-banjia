extends RefCounted
const W = preload("res://workshop.gd")
var w = W.new()
var truck: Node3D
var road_props: Node3D
var pennants: Array[Node3D] = []
var pads: Array[Node3D] = []
var sky_movers: Array[Node3D] = []
var shutter: Node3D
var road_set: Node3D
var open_shutter:=false
var distance_markers: Array[Node3D]=[]
var moving_objects: Array[Dictionary]=[]
var signs: Array[Node3D]=[]
var driver_home: Node3D
var paving: ShaderMaterial
func pave(mesh: MeshInstance3D,col: String,grout: String) -> void:
	if paving==null:
		paving=ShaderMaterial.new()
		paving.shader=preload("res://paving.gdshader")
		paving.set_shader_parameter("stone",Color(col))
		paving.set_shader_parameter("mortar",Color(grout))
	mesh.material_override=paving

func foundation(p: Node3D, pos: Vector3, size: Vector3, col: String) -> void:
	w.box(p,pos-Vector3(0,0.68,0),size+Vector3(0,1.1,0),"#bd8f72")
	w.box(p,pos,size,col)

func house(p: Node3D, pos: Vector3, s: float, color: String) -> void:
	var n: Node3D = w.group(p,pos)
	n.scale=Vector3.ONE*s
	w.box(n,Vector3(0,1.25,0),Vector3(2.5,2.5,2.2),color)
	w.tile_roof(n,Vector3(0,2.78,0),2.95,2.7)
	w.box(n,Vector3(0,0.15,0),Vector3(2.58,0.30,2.29),"#c7ad87")
	for side in [-1,1]:
		var wall=w.group(n,Vector3(side*1.26,1.42,0.09))
		wall.rotation.y=side*PI/2
		w.window(wall,Vector3.ZERO,0.58,0.71)
		for edge in [-1,1]:
			w.box(wall,Vector3(edge*0.405,0,0.046),Vector3(0.185,0.74,0.07),W.TEAL)
		w.box(wall,Vector3(0,-0.41,0.095),Vector3(0.94,0.11,0.25),W.CREAM)
		w.box(wall,Vector3(0,-0.35,0.175),Vector3(0.63,0.12,0.21),"#a76448")
		for bud in 4:
			w.ball(wall,Vector3(-0.24+bud*0.16,-0.24+0.02*(bud%2),0.18),Vector3(0.20,0.15,0.16),"#63885b",true)
		w.ball(wall,Vector3(0.07,-0.18,0.19),Vector3.ONE*0.105,W.RED,true)
	w.window(n,Vector3(-0.48,1.5,1.11),0.59,0.68)
	w.box(n,Vector3(0.58,0.62,1.14),Vector3(0.65,1.24,0.12),W.TEAL)
	w.box(n,Vector3(0.83,3.01,-0.47),Vector3(0.36,1.1,0.43),W.CREAM)

func backdrop(p: Node3D) -> void:
	var water=w.box(p,Vector3(0,-3.75,-8),Vector3(260,0.3,180),"#78b8bd")
	var water_material:=ShaderMaterial.new()
	water_material.shader=preload("res://coast.gdshader")
	water.material_override=water_material
	var rng := RandomNumberGenerator.new()
	rng.seed=13411
	for i in 18:
		var x := -47.0+i*5.1
		var z := rng.randf_range(-40,-21)
		var h := rng.randf_range(5,13)
		var mountain: Node3D = w.ball(p,Vector3(x,-3.5,z),Vector3(15,h*2,10),["#9dbab0","#aac0b8","#88aca7"][i%3],true)
		mountain.rotation.y = x
	for i in 16:
		var x := rng.randf_range(-25,25)
		var z := rng.randf_range(-16,-10)
		var knoll=w.ball(p,Vector3(x,-2.20,z),Vector3(rng.randf_range(6,11),5.1,5.8),"#bdad91",true)
		knoll.rotation.y=x
		w.ball(p,Vector3(x,-0.52,z),Vector3(5.2,1.45,3.7),"#839774",true)
		if i%2 == 0:
			house(p, Vector3(x,0,z), rng.randf_range(0.55,0.9),["#e6bc8a","#e5cba0"][i%2])
		else:
			w.cypress(p,Vector3(x,0,z),rng.randf_range(0.7,1.1))
	for i in 5:
		var cloud: Node3D = w.group(p,Vector3(-26+i*13,6+sin(i)*1.3,-25-i%2*5))
		sky_movers.append(cloud)
		for j in 3:
			w.ball(cloud,Vector3(j*0.95,sin(j*2.2)*0.2,0),Vector3(2.6,0.8+j%2*0.45,1.0),"#fff0cf",true)
	for i in 15:
		w.box(p,Vector3(-30+i*4.3,-3.55,-7-i%3*2.4),Vector3(1.7+i%3,0.05,0.13),"#cae0ce")

func flag_line(p: Node3D, a: Vector3,b: Vector3) -> void:
	var mid := (a+b)*0.5-Vector3.UP*0.38
	w.beam(p,a,mid,0.027,W.WOOD)
	w.beam(p,mid,b,0.027,W.WOOD)
	for i in 9:
		var t: float=(i+0.5)/9.0
		var pos: Vector3=a.lerp(b,t)-Vector3.UP*(0.38*(1-absf(t*2-1)))
		var f: Node3D=w.cyl(p,pos-Vector3.UP*0.17,0.025,0.19,0.34,[W.RED,W.GOLD,W.MINT,W.CREAM][i%4],3)
		pennants.append(f)

func depot(p: Node3D) -> void:
	backdrop(p)
	foundation(p,Vector3(0,-0.16,0),Vector3(19.7,0.30,11.4),"#beb590")
	var street=w.box(p,Vector3(4.49,0.008,0.1),Vector3(9.0,0.04,5.3),"#a9a398")
	pave(street,"#9c9f94","#7f847d")
	for i in 19:
		w.box(p,Vector3(0.35+i*0.5,0.036,2.73),Vector3(0.46,0.07,0.29),W.CREAM)
	# Villa floor and a cutaway wall section. The camera-facing edges stay low.
	w.box(p,Vector3(-4.75,0.045,-0.34),Vector3(7.85,0.12,7.9),"#cfb087")
	for x in 8:
		for z in 8:
			w.box(p,Vector3(-8.15+x*0.96,0.12,-3.76+z*0.96),Vector3(0.943,0.035,0.943),["#c2c8c0","#b5c3bc","#c9c9c0"][(x*7+z*11)%3])
	w.box(p,Vector3(-4.69,1.49,-4.22),Vector3(8.0,2.98,0.33),"#f2c99e")
	w.box(p,Vector3(-4.69,0.35,-3.98),Vector3(8.0,0.46,0.16),"#69aaa1")
	w.box(p,Vector3(-4.69,2.99,-4.22),Vector3(8.15,0.19,0.52),W.CREAM)
	for x in [-7.1,-4.7,-2.3]:
		w.window(p,Vector3(x,1.76,-4.01),0.96,1.28)
		for side in [-1,1]:
			w.box(p,Vector3(x+side*0.68,1.75,-3.91),Vector3(0.25,1.20,0.11),W.TEAL)
	w.box(p,Vector3(-8.62,0.64,-0.33),Vector3(0.25,1.28,7.9),"#e5bd91")
	for span in [Vector2(-4.16,-1.49)]:
		var z: float=(span.x+span.y)/2
		w.box(p,Vector3(-0.8,0.55,z),Vector3(0.33,1.1,span.y-span.x),"#e5b78a")
		w.box(p,Vector3(-0.8,1.14,z),Vector3(0.42,0.13,span.y-span.x+0.05),W.CREAM)
	shutter=w.group(p,Vector3(-0.8,0.12,2.48))
	for j in 6:
		w.box(shutter,Vector3(0,0.47,-1.06+j*0.42),Vector3(0.16,0.93,0.37),"#819996" if j%2==0 else "#9baba0")
		w.box(shutter,Vector3(0.09,0.47,-1.06+j*0.42),Vector3(0.045,0.13,0.39),W.SAND)
	w.column(p,Vector3(-0.8,0,-1.55),1.58)
	w.box(shutter,Vector3(0,0.73,-0.93),Vector3(0.39,1.48,0.32),W.TEAL)
	var latch=w.ring(shutter,Vector3(0,0.82,-0.13),0.20,0.053,W.GOLD)
	latch.rotation.z=PI/2
	# Warm runner directs the eye straight through the threshold to the van.
	for x in [-2.0,-1.25,-0.5,0.25,1.0]:
		var tile=w.box(p,Vector3(x,0.155,0),Vector3(0.32,0.025,0.32),W.GOLD)
		tile.rotation.y=PI/4
	w.box(p,Vector3(-3.65,0.157,-1.08),Vector3(2.9,0.035,3.7),"#9e6256")
	w.box(p,Vector3(-3.65,0.179,-1.08),Vector3(2.67,0.015,3.48),"#d39670")
	for side in [-1,1]:
		w.box(p,Vector3(-3.65+side*1.15,0.2,-1.08),Vector3(0.065,0.02,3.1),W.SAND)
	w.jar(p,Vector3(-7.9,0.13,-3.25),0.8,W.RED)
	w.jar(p,Vector3(-7.32,0.13,-3.40),0.58,W.TEAL)
	w.moon(p,Vector3(-4.7,2.70,-3.97),0.25)
	for pos in [Vector3(-9,0,-4.7),Vector3(8.8,0,-4.9),Vector3(7.8,0,-4.7),Vector3(-9.2,0,4.4)]:
		w.cypress(p,pos,1.1)
	house(p,Vector3(5.7,0,-5.3),0.88,"#e4b58a")
	for i in 7:
		w.box(p,Vector3(-8.3+i*2.4,-0.73,5.72),Vector3(1.68,0.57,0.15),"#cd967b")
	for x in [-8.1,0.85]:
		w.cyl(p,Vector3(x,2.15,-4.25),0.085,0.065,4.3,W.WOOD)
	flag_line(p,Vector3(-8.1,4.3,-4.25),Vector3(0.85,4.3,-4.25))
	w.crate(p,Vector3(7.7,0.04,3.28),0.8)
	w.crate(p,Vector3(8.37,0.04,3.62),0.64)
	dress_depot(p)
	truck=w.truck(p)
	truck.position=Vector3(4.75,0.055,0)
	var ramp=w.box(p,Vector3(1.05,0.55,0),Vector3(1.82,0.14,1.93),"#b6865b")
	ramp.rotation.z=0.49
	for i in 5:
		w.box(p,Vector3(0.37+i*0.31,0.29+i*0.155,0),Vector3(0.08,0.09,1.87),W.SAND)
	for i in 2:
		var pad=w.ring(p,Vector3(2.78+1.88*i,1.17,0),0.56,0.044,W.GOLD)
		pads.append(pad)

func dress_depot(p: Node3D) -> void:
	var kit:="furnishings/"
	w.prop(p,kit+"bookcaseOpen",Vector3(-6.08,0.15,-3.61),1.78,0)
	w.prop(p,kit+"books",Vector3(-6.16,0.85,-3.49),0.28,0.06)
	w.prop(p,kit+"books",Vector3(-5.94,1.33,-3.50),0.23,-0.15)
	w.prop(p,kit+"loungeChairRelax",Vector3(-7.71,0.14,-1.87),1.17,0.52)
	w.prop(p,kit+"lampRoundFloor",Vector3(-8.01,0.15,-2.71),1.82,0)
	w.prop(p,kit+"sideTable",Vector3(-7.77,0.15,-0.32),0.73,-0.1)
	w.prop(p,kit+"radio",Vector3(-7.77,0.88,-0.32),0.38,-0.05)
	w.prop(p,kit+"coatRackStanding",Vector3(-1.45,0.15,-3.34),1.74,0)
	w.prop(p,kit+"pottedPlant",Vector3(-7.95,0.14,2.84),1.04,0.1)
	w.prop(p,kit+"cardboardBoxClosed",Vector3(7.61,0.06,2.81),0.72,0.18)
	w.prop(p,kit+"cardboardBoxClosed",Vector3(7.65,0.78,2.82),0.47,-0.13)
	w.prop(p,kit+"chairCushion",Vector3(8.23,0,-2.2),0.91,-1.3)
	w.prop(p,kit+"tableCoffee",Vector3(7.37,0,-2.72),0.52,0)
	w.jar(p,Vector3(7.4,0.55,-2.72),0.37,W.RED)
	for i in 3:
		var x: float=-8.4+i*3.28
		w.box(p,Vector3(x+1.21,2.94,-4.17),Vector3(2.37,0.2,0.54),"#bd6f51")
	for i in 8:
		var x: float=-7.85+i*0.31
		w.ball(p,Vector3(x,2.81+sin(i*2.2)*0.12,-3.94),Vector3(0.52,0.32,0.30),"#477c61",true)
		for j in 2:
			w.ball(p,Vector3(x+0.09*j,2.69+sin(i*5+j)*0.15,-3.79),Vector3.ONE*0.15,"#ba78a1",true)
	for z in [-3.35,3.56]:
		for j in 14:
			w.box(p,Vector3(0.17+j*0.63,0.015,z),Vector3(0.55,0.047,0.33),"#b4ad92" if j%2 else "#cec1a5")
	for i in 14:
		var x: float=-8.75+i*1.34
		var z: float=4.72+0.19*sin(i)
		w.prop(p,"garden/"+(["flower_purpleA","flower_redA","flower_yellowB"][i%3]),Vector3(x,0.02,z),0.37+i%3*0.07,i*1.04)
		if i%3==0:
			w.prop(p,"garden/plant_bushDetailed",Vector3(x+0.42,0.02,z+0.23),0.49,i)
	for i in 8:
		w.prop(p,"garden/grass_large",Vector3(-8.6+i*2.28,0.02,4.41),0.28,i)
	for j in 6:
		w.prop(p,"garden/rock_smallB",Vector3(-8.6+j*3.25,-0.92,5.69),0.82+j%3*0.12,j)
	# The front balustrade frames the playable plane and leaves the central area legible.
	for start in [-8.2,4.3]:
		for j in 4:
			var x: float=start+j*0.85
			w.cyl(p,Vector3(x,0.30,5.0),0.13,0.10,0.6,W.CREAM,10)
		w.box(p,Vector3(start+1.27,0.62,5.0),Vector3(2.86,0.15,0.29),W.SAND)
	driver_home=w.group(p,Vector3(7.6,0.0,-3.47))
	w.cyl(driver_home,Vector3(0,1.17,0),0.11,0.09,2.32,W.WOOD)
	w.box(driver_home,Vector3(0,2.20,0),Vector3(1.6,0.65,0.15),W.TEAL)
	sign_text(driver_home,"西风货运",Vector3(0,2.22,0.10),0.007)

func winery(p: Node3D) -> void:
	var bench=w.group(p,Vector3(-6.80,0.16,2.15))
	w.box(bench,Vector3(0,0.40,0),Vector3(1.24,0.76,0.78),"#694e62")
	w.box(bench,Vector3(0,0.84,0),Vector3(1.36,0.13,0.87),W.WOOD)
	w.cyl(bench,Vector3(-0.30,1.0,0),0.16,0.18,0.31,W.RED)
	w.cyl(bench,Vector3(0.25,0.98,0),0.15,0.13,0.23,W.GOLD)
	var tag=sign_text(bench,"封蜡台",Vector3(0,1.68,0),0.006)
	tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	tag.outline_size=7
	for j in 4:
		var grape=w.group(p,Vector3(-7.05+j*0.93,2.74,-3.73))
		for k in 5:
			w.ball(grape,Vector3((k%2)*0.12,-k*0.068,0),Vector3.ONE*0.18,"#76557b",true)

func sign_text(p: Node3D,caption: String,pos: Vector3,px: float) -> Label3D:
	var n:=Label3D.new()
	var font:=preload("res://harbour_fonts.gd").body()
	font.font_weight=700
	n.font=font
	n.font_size=52
	n.pixel_size=px
	n.outline_size=0
	n.modulate=Color("#fff1d2")
	n.text=caption
	p.add_child(n)
	n.position=pos
	return n

func blow_gate() -> void:
	if open_shutter: return
	open_shutter=true
	var tw=shutter.create_tween()
	tw.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(shutter,"rotation:z",-PI/2,0.48)

func heading(d:float)->float:
	return clampf((d-36.0)/24.0,0,1)*1.05

func anchor(d:float)->Vector3:
	var arc:=clampf(d-36,0,24)
	var r:=24.0/1.05
	var a:=arc/r
	var tail:=maxf(0,d-60.0)
	return Vector3(minf(d,36)+r*sin(a)+tail*cos(a),0,-r*(1-cos(a))-tail*sin(a))

func pos(d:float,side:float,h:=0.0)->Vector3:
	var a:=heading(d)
	return anchor(d)+Vector3(sin(a)*side,h,cos(a)*side)

func highway(p: Node3D, ferry: bool, hard: bool) -> void:
	var sea=w.box(p,Vector3(0,-3.5,-1.0),Vector3(520,0.20,520),"#609ba5")
	var waves:=ShaderMaterial.new()
	waves.shader=preload("res://coast.gdshader")
	sea.material_override=waves
	road_set=w.group(p)
	# The vehicle advances through a laid-out course. The continuous shoreline gives
	# motion cues while road sections open into a real gap or a wooden pontoon.
	var span_begin:=103.0 if not ferry else 98.0
	var span_end:=107.0 if not ferry else 112.0
	for i in range(-8,74):
		var px:=i*2.4
		if px>span_begin and px<span_end: continue
		var seg=w.group(road_set,Vector3(px,0,0))
		var cobbles=w.box(seg,Vector3(0,-0.27,0),Vector3(2.68,0.50,6.65),"#b9a381")
		pave(cobbles,"#b4a28b","#999384")
		w.box(seg,Vector3(0,-0.90,0),Vector3(2.40,0.86,6.89),"#b58d6b")
		w.box(seg,Vector3(0,-1.70,0),Vector3(2.37,0.74,6.70),"#c29a78")
		for z in [-3.36,3.36]:
			w.box(seg,Vector3(0,-0.17,z),Vector3(2.39,0.27,0.27),"#ddc8aa")
		if i%2==0:
			w.box(seg,Vector3(0,0.012,-2.97),Vector3(0.91,0.026,0.07),"#efe1bf")
			w.box(seg,Vector3(0,0.012,2.97),Vector3(0.91,0.026,0.07),"#efe1bf")
		if i%4==0:
			w.box(seg,Vector3(0,0.28,-3.3),Vector3(0.31,0.56,0.31),W.CREAM)
			w.box(seg,Vector3(0,0.39,-3.3),Vector3(0.32,0.11,0.32),W.RED)
		if i%9==0:
			w.cypress(seg,Vector3(0,-0.1,-4.06),0.83)
		if i%7==0:
			w.prop(seg,"garden/flower_yellowB",Vector3(0.52,-0.01,-3.24),0.48,px)
		if i%11==1:
			w.prop(seg,"garden/rock_largeA",Vector3(0,-2.54,3.20),1.05,px)
	if ferry:
		var ferry_deck=w.group(road_set,Vector3(105,0,0))
		ferry_deck.name="Pontoon"
		w.box(ferry_deck,Vector3(0,-0.39,0),Vector3(15.1,0.67,6.55),W.TEAL)
		for i in 22:
			w.box(ferry_deck,Vector3(-7.25+i*0.69,-0.025,0),Vector3(0.65,0.13,6.37),"#b7885e" if i%2==0 else "#c29b6d")
		for x in [-5,0,5]:
			w.cyl(ferry_deck,Vector3(x,0.41,-3.04),0.12,0.12,0.82,W.WOOD)
		w.beam(ferry_deck,Vector3(-5,0.69,-3.02),Vector3(5,0.69,-3.02),0.06,W.CREAM)
		w.cyl(ferry_deck,Vector3(0,1.35,-3),0.075,0.06,2.72,W.WOOD)
		w.box(ferry_deck,Vector3(0.5,2.35,-3),Vector3(1.00,0.53,0.055),W.RED)
	else:
		for j in 7:
			var plank=w.box(road_set,Vector3(102.8+j*0.55,-0.37-0.30*sin(j*PI/7.0),0),Vector3(0.39,0.14,3.32),"#936d50")
			plank.rotation.z=-0.10+0.038*j
		for z in [-3.15,3.15]:
			w.box(road_set,Vector3(101.35,0.61,z),Vector3(0.37,1.2,0.37),W.RED)
			w.box(road_set,Vector3(107.85,0.61,z),Vector3(0.37,1.2,0.37),W.RED)
	# Landmarks are spaced in travel order. Their lower contrast leaves the truck readable.
	for i in range(-2,14):
		var px:=i*13.4
		var v=w.group(road_set,Vector3(px,-0.6,-8.5-i%3*1.4))
		w.ball(v,Vector3(0,-2.12,0),Vector3(10.9,4.92,5.8),"#b4997c",true)
		w.ball(v,Vector3(0,-0.55,0),Vector3(7.5,1.68,4.35),"#90a17f",true)
		if i%3==0:
			for cx in [-2.1,-0.7,0.7,2.1]: w.column(v,Vector3(cx,0,0),2.27)
			w.box(v,Vector3(0,2.51,0),Vector3(5.6,0.45,2.32),W.CREAM)
			w.tile_roof(v,Vector3(0,2.93,0),5.9,2.69)
		else:
			house(v,Vector3(-1.65,0,0),0.82,"#eac296")
			w.cypress(v,Vector3(1.43,0,0),1.09)
	for pair in [[5.8,"酒桶",0.98],[13.1,"落石",-0.78],[21.0,"渡口" if ferry else "断桥",0.0]]:
		road_event(float(pair[0]),str(pair[1]),float(pair[2]))
	if hard: road_event(28.0,"酒桶",-0.95)
	for node: Node3D in road_set.get_children():
		var original:=node.position
		node.position=pos(original.x,original.z,original.y)
		node.rotation.y+=heading(original.x)
	for i in range(24):
		var island:=pos(i*8.4,29.0+sin(i)*8,-4.9)
		w.ball(p,island,Vector3(17,9+i%4*2,15),"#879e92",true)
		var ridge:=float(9+i%4*2)*0.5
		if i%4==0:
			house(p,island+Vector3.UP*(ridge-0.17),1.05,W.SAND)
		if i%3!=1:
			w.cypress(p,island+Vector3(1.9,ridge-0.42,-0.8),1.24)
			w.cypress(p,island+Vector3(3.2,ridge-0.74,-0.1),0.88)
	truck=w.truck(p)
	truck.scale=Vector3.ONE*1.13

func road_event(at: float,title: String,lane: float) -> void:
	var x:=at*5.0+2.9
	var sign_node=w.group(road_set,Vector3(x-11.0,0,-3.17))
	sign_node.rotation.y=-1.20
	w.cyl(sign_node,Vector3(0,0.91,0),0.088,0.075,1.82,W.WOOD)
	w.box(sign_node,Vector3(0,1.64,0),Vector3(1.62,0.78,0.12),W.RED if title=="断桥" else W.TEAL)
	sign_text(sign_node,title,Vector3(0,1.64,0.085),0.009)
	if title=="酒桶":
		var barrel=w.group(road_set,Vector3(x,0.43,lane))
		var wood=w.cyl(barrel,Vector3.ZERO,0.43,0.43,1.0,"#9f6c46")
		wood.rotation.x=PI/2
		for z in [-0.38,0.38]:
			var band=w.ring(barrel,Vector3(0,0,z),0.436,0.044,W.DARK)
			band.rotation.x=PI/2
		moving_objects.append({"model":barrel,"lane":lane,"at":at,"kind":"barrel"})
	elif title=="落石":
		for j in 4:
			w.prop(road_set,"garden/rock_smallB",Vector3(x+j*0.47,0,lane+(j%2)*0.4),0.40+j%3*0.16,j)

func travel(time: float) -> void:
	if not is_instance_valid(road_set): return
	for thing in moving_objects:
		thing.model.position=pos(float(thing.at)*5.0+2.9,float(thing.lane)+sin(time*0.82)*0.41,0.43)
		thing.model.rotation.z=time*1.43
	var pontoon:=road_set.get_node_or_null("Pontoon")
	if pontoon:
		pontoon.position.y=0.09*sin(time*2.2)

func tick(t: float, speed: float, delta: float) -> void:
	for i in pennants.size():
		pennants[i].rotation.z=0.10*sin(t*2.8+i*0.7)
	for i in sky_movers.size():
		sky_movers[i].position.x=-26+i*13+sin(t*0.074+i)*1.55
	if is_instance_valid(road_props):
		for item in road_props.get_children():
			item.position.x-=speed*delta
			if item.position.x < -23.0:
				item.position.x+=59.4



