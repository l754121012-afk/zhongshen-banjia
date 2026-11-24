extends Node3D

const Art=preload("res://workshop.gd")
var art=Art.new()
var spring_bridge:=false
var town=preload("res://district.gd").new()
var solids: Array[Rect2]=[]
const CELLAR:=Vector2(-6,2)
const STEPS:=Vector2(183,-4)
const SIDE:=Vector2(190,4)
const MARKET:=Vector2(175,5)
const LODGE:=Vector2(3,9)
const GROVE:=Vector2(36,8)
const BRIDGE_Z:=-2.0

func path_z(x:float)->float:
	if x>=42 and x<=142:
		var knots:=[Vector2(42,-2),Vector2(67,10),Vector2(94,-10),Vector2(119,10),Vector2(142,-2)]
		for i in range(1,knots.size()):
			var b:Vector2=knots[i]
			if x<=b.x:
				var a:Vector2=knots[i-1]
				return lerpf(a.y,b.y,smoothstep(a.x,b.x,x))
	return lerpf(1.5,-8.0,smoothstep(5,24,x))+6.0*smoothstep(29,45,x)

func coast_edge(x:float)->float:
	return 19.+27.*smoothstep(43.,66.,x)*(1.-smoothstep(108.,137.,x))

func cove_path(x:float)->float:
	return 12.+(coast_edge(x)-19.)*.83+sin(x*.14)*1.8

func ground(p:Vector2)->float:
	var x:=p.x
	var z:=p.y
	if z>15. and coast_edge(x)>19.01:
		var coast_blend:=smoothstep(15.,25.,z)
		var inland:=ground(Vector2(x,15.))
		var shelf:=-.3+.44*sin(x*.095)+.27*cos(z*.31)
		return lerpf(inland,shelf,coast_blend)
	if x>=146 and x<=160:
		if spring_bridge and absf(z-3.5)<=2.45:return 0.
		if p.y>5.5: return sin(PI*(x-146)/14)*(-0.90+0.13*cos((x-146)*2.3))
		return 0.66*sin(PI*(x-146)/14)+0.19*exp(-pow((z+3.5)/0.50,2))*sin(PI*(x-146)/14)
	if x>42 and x<142:
		var blend:=smoothstep(42,53,x)*(1.0-smoothstep(131,142,x))
		var crest:=1.9+1.5*sin((x-50)*0.084)+0.18*z
		var rut:=smoothstep(2.2,5.8,absf(z-path_z(x)))
		return blend*(crest+rut*0.26*sin(x*1.46+z*0.65))
	var hill:=smoothstep(6,24,x)*(1.0-smoothstep(27,44,x))
	return hill*(3.0+0.22*sin(x*0.8))*smoothstep(-6,5,z)*(1.0-smoothstep(10,19,z))

func surface(p:Vector2)->Vector3:
	return Vector3(p.x,ground(p),p.y)

func valid(p:Vector2,on_foot:=false)->bool:
	var west_edge:=-15.95 if on_foot else -12.0
	if p.x<west_edge or p.x>199 or p.y< -16.5 or p.y>coast_edge(p.x)-2.5: return false
	if p.x>145.8 and p.x<160.2 and absf(p.y-BRIDGE_Z)>2.55 and absf(p.y-9)>2.35 and not (spring_bridge and absf(p.y-3.5)<=2.4): return false
	for rect in solids:
		if rect.has_point(p): return false
	return true

func obstacles(p:Vector2,h:Vector2)->void:
	solids.append(Rect2(p-h,2*h))

func sign_at(p:Vector2, words:String)->void:
	var n:=art.group(self,surface(p))
	art.cyl(n,Vector3.UP*1.05,0.09,0.08,2.1,Art.WOOD)
	var board:=art.group(n,Vector3.UP*1.95)
	board.rotation.y=-1.26
	art.box(board,Vector3.ZERO,Vector3(2.65,0.70,0.15),Art.TEAL)
	town.sign_text(board,words,Vector3(0,0,0.10),0.008)

func build_land(start:int,end:int)->void:
	var surf:=SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(start,end):
		for z in range(-19,ceili(maxf(coast_edge(x),coast_edge(x+1)))):
			for uv:Vector2i in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.RIGHT,Vector2i.ONE,Vector2i.DOWN]:
				var p:=Vector2(x+uv.x,z+uv.y)
				p.y=minf(p.y,coast_edge(p.x))
				var shore:=absf(p.y)/(coast_edge(p.x) if p.y>0. else 19.)
				var color:=Color("#92aa63").lerp(Color("#bcc583"),0.45+0.25*sin(p.x*0.48+p.y*0.7))
				var trail:=1.0-smoothstep(1.6,3.15,absf(p.y-path_z(p.x)))
				if coast_edge(p.x)>19.2:trail=maxf(trail,1.-smoothstep(1.55,3.45,absf(p.y-cove_path(p.x))))
				if p.x<5 or p.x>166: trail=maxf(trail,1-smoothstep(8.0,13.0,absf(p.y)))
				color=color.lerp(Color("#cdbb91"),trail)
				surf.set_color(color)
				var dx:=ground(p+Vector2.RIGHT*0.5)-ground(p-Vector2.RIGHT*0.5)
				var dz:=ground(p+Vector2.DOWN*0.5)-ground(p-Vector2.DOWN*0.5)
				surf.set_normal(Vector3(-dx,1,-dz).normalized())
				surf.add_vertex(surface(p)-Vector3.UP*smoothstep(0.90,1,shore)*1.8)
	var n:=MeshInstance3D.new()
	n.mesh=surf.commit()
	var m:=StandardMaterial3D.new()
	m.vertex_color_use_as_albedo=true
	m.vertex_color_is_srgb=true
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	n.material_override=m
	add_child(n)

func _ready()->void:
	var water:=art.box(self,Vector3(94,-2.6,0),Vector3(450,0.25,210),"#65a8ad")
	var wave:=ShaderMaterial.new()
	wave.shader=preload("res://coast.gdshader")
	water.material_override=wave
	build_land(-16,146)
	build_land(160,204)
	for x in range(-16,205,3):
		if x>145 and x<161: continue
		for side_z in [-18.0,18.0]:
			if side_z>0.:side_z=coast_edge(x)-1.
			art.ball(self,Vector3(x,-2.2,side_z),Vector3(6.8,3.5,5),"#b19e81",true)
			if x%5!=0 and x%4!=0: art.cypress(self,Vector3(x,0,side_z*0.95),0.95+0.15*abs(x%4))
	# A low causeway joins the two banks beside the old bridge.
	for i in 14:
		var x:=146.5+i
		var y:=ground(Vector2(x,9))
		var slab:=art.box(self,Vector3(x,y-0.26,9),Vector3(1.04,0.52,6.45),"#b7b39b" if i%3 else "#9f9f8d")
		slab.rotation.z=atan(ground(Vector2(x+0.45,9))-ground(Vector2(x-0.45,9)))
		if i%3==0:
			for side in [-1,1]:
				var foot:=Vector3(x,y-0.38,9+side*3.19)
				art.cyl(self,foot+Vector3.UP*0.56,0.12,0.10,1.1,Art.WOOD)
				art.ball(self,foot+Vector3.UP*1.17,Vector3(0.29,0.35,0.29),Art.GOLD)
	sign_at(Vector2(143,12),"低潮石堤")
	sign_at(Vector2(163,12),"低潮石堤")
	for x in [145.2,160.8]:
		for z in range(-17,18,3):
			art.ball(self,Vector3(x,-2.25,z),Vector3(3.8,4.3,5.6),"#ac997c",true)
	for i in 14:
		var x:=146.5+i
		var deck:=art.box(self,Vector3(x,ground(Vector2(x,-2))-0.26,-2),Vector3(1.07,0.52,7.7),"#c8b597")
		deck.rotation.z=atan(ground(Vector2(x+0.5,-2))-ground(Vector2(x-0.5,-2)))
		for side in [-1,1]:
			art.box(self,Vector3(x,deck.position.y+0.52,-2+3.84*side),Vector3(1.01,0.72,0.38),"#d6c3a5")
		var rut:=art.box(self,Vector3(x,ground(Vector2(x,-3.5))+0.012,-3.5),Vector3(1.06,0.06,0.58),"#aa967b")
		rut.rotation.z=deck.rotation.z
		if i%5==1: art.box(self,Vector3(x,-1.45,-2),Vector3(1.12,3.65,7.5),"#aa9176")
	town.house(self,Vector3(-5,0,-6),2.25,Art.CREAM)
	obstacles(Vector2(-5,-6),Vector2(2.8125,2.475))
	art.box(self,Vector3(-6,0.18,-1.2),Vector3(5,0.36,1.7),Art.WOOD)
	for j in 4: art.jar(self,Vector3(-8+j*0.95,0.37,-1.35),0.72,"#9f6652")
	sign_at(Vector2(-9,-0.8),"葡萄酒庄")
	for x in range(10,38,4):
		for z in [-14,13]:
			var p:=Vector2(x,z)
			var v:=art.group(self,surface(p))
			art.beam(v,Vector3(0,0,0),Vector3(0,1.35,0),0.075,Art.WOOD)
			art.ball(v,Vector3(0,1.08,0),Vector3(3.6,1.05,1.5),"#52734a",true)
			for k in 3:
				art.ball(v,Vector3(-0.75+k*0.62,0.84,0.53),Vector3(0.31,0.46,0.26),"#776083",true)
			obstacles(p,Vector2(1.9,0.85))
	sign_at(Vector2(9,-5),"沿岸田埂")
	sign_at(Vector2(142,-7),"西湾石桥")
	var temple:=art.group(self,Vector3(188,0,-7))
	art.box(temple,Vector3(0,0.36,0),Vector3(10.8,0.72,6.8),Art.SAND)
	for x in [-4,-2,0,2,4]:
		for z in [-2.5,2.5]: art.column(temple,Vector3(x,0.70,z),4)
	art.box(temple,Vector3(0,4.88,0),Vector3(11,0.45,7.0),Art.CREAM)
	art.tile_roof(temple,Vector3(0,5.63,0),11.5,7.4)
	obstacles(Vector2(188,-7),Vector2(5.55,3.4))
	for k in 3: art.box(self,Vector3(184.3,0.10+k*0.10,-3+k*-0.42),Vector3(4,0.20+k*0.2,0.9),Art.CREAM)
	art.box(self,Vector3(191,0.36,6.4),Vector3(6.6,0.72,2.3),Art.WOOD)
	obstacles(Vector2(191,6.4),Vector2(3.4,1.2))
	sign_at(Vector2(181,-6),"神庙正阶")
	sign_at(Vector2(194,4),"侧院卸货")
	for x in [170,179,197]:
		town.house(self,Vector3(x,0,13.5),1.45,Art.SAND)
		obstacles(Vector2(x,13.5),Vector2(2.5,2.2))
	for cx in [172,178]:
		var stall:=art.group(self,Vector3(cx,0,8.6))
		for sx in [-1.4,1.4]:
			for sz in [-0.78,0.78]:
				art.beam(stall,Vector3(sx,0,sz),Vector3(sx,2.15,sz),0.065,Art.WOOD)
		for j in 7:
			var cloth:=art.box(stall,Vector3(-1.5+j*0.50,2.15,0),Vector3(0.51,0.10,2.1),Art.CREAM if j%2==0 else Art.RED)
			cloth.rotation.x=-0.12
		art.box(stall,Vector3(0,0.72,0),Vector3(2.85,0.16,1.32),Art.WOOD)
		for j in 5: art.jar(stall,Vector3(-1.1+j*0.53,0.82,0),0.46,"#b06f49")
		obstacles(Vector2(cx,8.6),Vector2(1.65,0.99))
	for i in 16:
		art.ball(self,Vector3(i*9-16,-3.8,-35-i%4*3),Vector3(14,8+i%5,12),"#97a993",true)
	town.house(self,Vector3(3,0,14.0),1.55,"#b6c5b3")
	obstacles(Vector2(3,14),Vector2(2.25,1.95))
	art.moon(self,Vector3(3,5.1,14),0.8)
	sign_at(LODGE+Vector2(0,2.5),"月桂客舍")
	sign_at(GROVE+Vector2(0,3),"静风亭")
	for off in [-2.2,2.2]:
		art.cypress(self,surface(GROVE+Vector2(off,4)),1.2)
	art.box(self,surface(GROVE+Vector2(0,3.5))+Vector3.UP*0.4,Vector3(2.5,0.18,0.6),Art.WOOD)
	# The hairpins wind between visible rock spurs, with room to crawl around either tip.
	for data in [[68.0,-6.0,11.8],[95.0,6.0,11.8],[119.0,-6.0,11.8]]:
		var cx:float=data[0]
		var cz:float=data[1]
		var span:float=data[2]
		if cx==95:
			# A stepped vineyard and a press tower mark the sheltered side of the pass.
			var ledge:=Vector2(cx,cz)
			store_wall(ledge,Vector2(4.2,2*(span+0.5)),1.35)
			store_wall(ledge+Vector2(0,2),Vector2(3.4,span*1.35),2.05)
			town.house(self,surface(Vector2(cx,cz))+Vector3.UP*2.1,1.35,Art.CREAM)
			for row in range(4):
				var vine:=ledge+Vector2(0,row*2.8-5.0)
				art.ball(self,surface(vine)+Vector3.UP*2.1,Vector3(3.3,1.2,1.7),"#517647",true)
			obstacles(Vector2(cx,cz),Vector2(1.9,span+0.5))
			continue
		for k in 5:
			var p:=Vector2(cx+(k%2)*0.35,cz-span+k*span*0.5)
			art.ball(self,surface(p)+Vector3.UP*1.35,Vector3(5.0,5.2+k%2,span*0.64),"#ab9b80",true)
		obstacles(Vector2(cx,cz),Vector2(1.9,span+0.5))
	for x in range(47,140,6):
		var edge:=Vector2(x,path_z(x)-3.4)
		art.cyl(self,surface(edge)+Vector3.UP*0.25,0.17,0.14,0.51,Art.CREAM)
	for x in [82,110]:
		var p:=Vector2(x,-5.8)
		art.beam(self,surface(p),surface(p)+Vector3.UP*3.3,0.075,Art.WOOD)
		art.box(self,surface(p)+Vector3(0.05,3.0,0.75),Vector3(0.1,0.48,1.5),Art.RED)
	sign_at(Vector2(51,8),"岬角山道")
	sign_at(Vector2(128,-6),"横风口")

	# A wine press splits the vineyard into a high and low approach.
	town.house(self,surface(Vector2(23,0)),1.95,Art.CREAM)
	obstacles(Vector2(23,0),Vector2(2.6,2.30))
	for x in [19,27]:
		art.cypress(self,surface(Vector2(x,0)),1.15)
		obstacles(Vector2(x,0),Vector2(0.45,0.45))
	# Rooftop and trees reveal the market only after rounding the last bluff.
	town.house(self,surface(Vector2(135,-8)),1.7,Art.SAND)
	obstacles(Vector2(135,-8),Vector2(2.25,1.95))
	art.cypress(self,surface(Vector2(132,-9)),1.4)

	loading_aisle(Vector2(-6,6.6))
	loading_aisle(Vector2(175,-5.2))
	enclosed_store(Vector2(-6,6.6),1)
	enclosed_store(Vector2(175,-5.2),-1)

func loading_aisle(door:Vector2)->void:
	for side in [-1,1]:
		var center:=door+Vector2(side*2.78,0)
		obstacles(center,Vector2(1.92,0.36))
		for j in 4:
			var crate:=art.crate(self,surface(center+Vector2(j*0.94-1.41,0)),0.99)
			if j%3==1: art.crate(crate,Vector3(0,0.90,0),0.83)
		var post:=door+Vector2(side*0.92,0)
		art.cyl(self,surface(post)+Vector3.UP*0.69,0.085,0.085,1.38,Art.TEAL)
		art.ball(self,surface(post)+Vector3.UP*1.40,Vector3.ONE*0.22,Art.GOLD)

func store_wall(center:Vector2,size:Vector2,height:float)->void:
	obstacles(center,size*0.5)
	var base:=surface(center)
	art.box(self,base+Vector3.UP*(height*0.5),Vector3(size.x,height,size.y),"#eed8ac")
	art.box(self,base+Vector3.UP*height,Vector3(size.x+0.10,0.13,size.y+0.10),Art.RED)
	art.box(self,base+Vector3.UP*0.22,Vector3(size.x+0.04,0.42,size.y+0.04),"#b69d75")

func enclosed_store(door:Vector2,inside:float)->void:
	for side in [-1,1]:
		store_wall(door+Vector2(side*4.74,inside*4.30),Vector2(0.46,8.75),1.57)
	store_wall(door+Vector2(0,inside*8.60),Vector2(9.88,0.50),2.35)
	# An offset rack breaks the straight line from the stock bay to the door.
	var rack:=door+Vector2(-2.1,inside*4.35)
	store_wall(rack,Vector2(4.30,0.46),1.05)
	for n in 4:
		art.jar(self,surface(rack)+Vector3(n*0.9-1.35,1.14,0),0.52,Art.WOOD)
