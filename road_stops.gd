extends Node3D

var art=preload("res://workshop.gd").new()
var stops: Array[Dictionary]=[]
var sails: Node3D
var feather:=false
var earnings:=0

func build(town, ferry: bool, expert: bool) -> void:
	build_meadow(town)
	add_stop(town,3.0,-1.3,"coin")
	add_stop(town,9.4,1.15,"hurdle")
	add_stop(town,16.8,-1.35,"feather")
	add_stop(town,23.6,1.15 if ferry else -1.15,"express")
	if expert: add_stop(town,30.4,1.35,"hurdle")
	var bluff:=art.group(self,town.pos(77,-13,-2))
	art.ball(bluff,Vector3.ZERO,Vector3(13,5.4,9),"#b3a58a",true)
	var mill:=art.group(bluff,Vector3(0,2.43,0))
	art.cyl(mill,Vector3(0,2.2,0),1.42,1.9,4.4,art.CREAM)
	art.cyl(mill,Vector3(0,4.95,0),0.02,1.68,1.22,art.RED)
	art.box(mill,Vector3(0,1.0,1.73),Vector3(0.84,1.95,0.12),art.TEAL)
	sails=art.group(mill,Vector3(0,3.48,1.72))
	for k in 4:
		var arm:=art.group(sails)
		arm.rotation.z=k*PI/2
		art.beam(arm,Vector3.ZERO,Vector3(0,2.65,0),0.065,art.WOOD)
		art.box(arm,Vector3(0.27,1.80,0),Vector3(0.48,1.46,0.075),art.SAND)
		for rib in 3:
			art.box(arm,Vector3(0.25,1.17+rib*0.58,0.06),Vector3(0.54,0.06,0.05),art.WOOD)
	art.ball(sails,Vector3.ZERO,Vector3.ONE*0.44,art.GOLD)
	var beacon:=art.group(self,town.pos(106,0,0))
	beacon.rotation.y=town.heading(106)
	for side in [-1,1]:
		art.column(beacon,Vector3(0,0,side*3.5),3.8)
		art.ball(beacon,Vector3(0,4.0,side*3.5),Vector3.ONE*0.68,art.GOLD)
	art.beam(beacon,Vector3(0,3.8,-3.5),Vector3(0,3.8,3.5),0.10,art.GOLD)
	art.box(beacon,Vector3(0,3.95,0),Vector3(0.17,0.87,2.7),art.TEAL)
	var title=town.sign_text(beacon,"渡船" if ferry else "风桥",Vector3(-0.12,3.95,0),0.011)
	title.rotation.y=-PI/2

func add_stop(town, at: float, side: float, kind: String) -> void:
	var stand:=art.group(self,town.pos(at*5+2.9,side,0))
	stand.rotation.y=town.heading(at*5+2.9)
	var token:=art.group(stand)
	token.position.y=1.25
	var gold: String=art.GOLD
	if kind=="feather":
		var glass=art.ball(token,Vector3.ZERO,Vector3(0.74,1.05,0.74),"#42bed3",true)
		art.ring(glass,Vector3.ZERO,0.53,0.065,gold)
		art.cyl(token,Vector3(0,0.57,0),0.20,0.14,0.20,gold)
		for side_sign in [-1,1]:
			for j in 3:
				var plume=art.ball(token,Vector3(0,0.06+j*0.13,side_sign*(0.29+j*0.11)),Vector3(0.12,0.39,0.19),art.CREAM,true)
				plume.rotation.x=side_sign*0.60
	elif kind=="express":
		for side_sign in [-1,1]:
			art.cyl(stand,Vector3(0,1.35,side_sign*1.16),0.11,0.075,2.7,gold)
			art.box(stand,Vector3(0,2.55,side_sign*0.92),Vector3(0.11,0.43,0.56),art.RED)
		token.position.y=2.5
	else:
		if kind=="hurdle":
			for z in [-0.70,0.70]:
				art.box(stand,Vector3(0,0.26,z),Vector3(0.42,0.52,0.20),art.WOOD)
			art.box(stand,Vector3(0,0.47,0),Vector3(0.22,0.37,1.92),art.RED)
			for z in [-0.64,0,0.64]:
				var stripe=art.box(stand,Vector3(-0.125,0.47,z),Vector3(0.028,0.35,0.20),art.CREAM)
				stripe.rotation.x=0.28
			token.position.y=2.15
	if kind!="feather":
		var medallion=art.cyl(token,Vector3.ZERO,0.39,0.39,0.13,gold)
		medallion.rotation.z=PI/2
		var face=art.ring(token,Vector3(-0.085,0,0),0.28,0.035,art.CREAM)
		face.rotation.z=PI/2
	for j in 3:
		for sign_z in [-1,1]:
			var mark=art.box(stand,Vector3(-2.1-j*1.75,0.025,sign_z*0.24),Vector3(0.56,0.03,0.10),art.CREAM if kind=="hurdle" else gold)
			mark.rotation.y=sign_z*0.52
	stops.append({"at":at,"side":side,"kind":kind,"token":token,"height":token.position.y,"done":false})

func advance(game, height: float) -> void:
	sails.rotation.z=game.t*0.52
	for stop in stops:
		if stop.done: continue
		var token: Node3D=stop.token
		token.position.y=stop.height+sin(game.t*3.4)*0.12
		token.rotation.y=sin(game.t*2.0)*0.55
		if game.road_t<stop.at: continue
		stop.done=true
		if absf(game.lane_z-float(stop.side))>1.04: continue
		var prize:=0
		match stop.kind:
			"feather":
				feather=true
				game.message("收到西风瓶！空中再按空格借风",1.8)
			"hurdle":
				if height<0.39:
					game.calm=maxf(0,game.calm-5)
					game.bounce=0.76
					game.cargo_velocity+=Vector2(1.3*(0.25 if game.strap==0 else 1.0),2.4*(0.25 if game.strap==1 else 1.0))
					game.audio.play_cue("bonk")
					game.message("擦上路障 · 货况 −5",1.4)
					continue
				prize=5
			"express":
				if game.drive_speed<1.39:
					game.message("错过急送赏金 · 冲刺穿门可领",1.2)
					continue
				prize=7
			"coin": prize=3
		game.sparks(token.global_position,art.GOLD,9)
		token.hide()
		game.audio.play_cue("snap")
		earnings+=prize
		if prize>0: game.message("急送赏金 +%d 枚" % prize,1.35)

func preview(progress: float) -> String:
	for stop in stops:
		var ahead:=float(stop.at)-progress
		if not stop.done and ahead>0 and ahead<2.65:
			var side: String="左侧" if stop.side<0 else "右侧"
			match stop.kind:
				"coin": return side+"金币 · 靠近领取"
				"hurdle": return side+"跳栏 · 空格跃过领 5 枚，也可绕开"
				"express": return side+"金门 · 按住 W 冲过领 7 枚"
				"feather": return side+"西风瓶 · 收集后可在前方免费借风"
	return ""

# Sample the same surface under the wheels and at the visible terrain vertices.
func meadow_width(d: float) -> float:
	return 10.2*smoothstep(43,54,d)*(1.0-smoothstep(82,99,d))

func ground(d: float, z: float) -> float:
	var ridge:=smoothstep(45,62,d)*(1.0-smoothstep(64,87,d))
	return ridge*smoothstep(2.5,9.2,z)*(3.85+0.28*sin(d*0.48))+mud(d,z)*(-0.16+0.065*sin(d*2.9))

func mud(d: float,z: float) -> float:
	return smoothstep(52,57,d)*(1.0-smoothstep(74,80,d))*smoothstep(2.9,4,z)*(1.0-smoothstep(5.5,7,z))

func vertex_color(d: float,z: float) -> Color:
	var grass:=Color("#678454").lerp(Color("#93a568"),0.5+0.5*sin(d*0.67+z*0.54))
	return grass.lerp(Color("#674935"),mud(d,z))

func build_meadow(town) -> void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(42,101):
		for j in 14:
			for uv: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var d:=float(x+uv.x)
				var side:=lerpf(2.82,4.2+meadow_width(d),float(j+uv.y)/14)
				surface.set_color(vertex_color(d,side))
				var forward: Vector3=town.pos(d+0.25,side,ground(d+0.25,side))-town.pos(d-0.25,side,ground(d-0.25,side))
				var across: Vector3=town.pos(d,side+0.25,ground(d,side+0.25))-town.pos(d,side-0.25,ground(d,side-0.25))
				surface.set_normal(across.cross(forward).normalized())
				surface.add_vertex(town.pos(d,side,ground(d,side)+0.045))
	var land:=MeshInstance3D.new()
	land.mesh=surface.commit()
	var mat:=StandardMaterial3D.new()
	mat.vertex_color_is_srgb=true
	mat.vertex_color_use_as_albedo=true
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	land.material_override=mat
	add_child(land)
	for d in range(44,100,3):
		var edge:=meadow_width(d)+3.8
		var base:=ground(d,edge)
		art.ball(self,town.pos(d,edge-0.8,base-2.5),Vector3(5.8,5.0,5.0),"#af9f79",true)
		if d%2==0:
			art.cypress(self,town.pos(d,edge+0.45,base-0.18),0.67)
	for d in range(51,89,2):
		var mid:=3.65+0.82*meadow_width(d)
		for wheel_z in [-0.80,0.80]:
			var z: float=mid+wheel_z
			var soil:=art.box(self,town.pos(d,z,ground(d,z)+0.075),Vector3(1.5,0.035,0.21),"#927957")
			soil.rotation.y=town.heading(d)
			soil.rotation.z=atan((ground(d+0.4,z)-ground(d-0.4,z))/0.8)
		if d%4==1:
			var z:=mid+1.8
			art.prop(self,"garden/grass_large",town.pos(d,z,ground(d,z)+0.04),0.50,d)
	for d in [50,88]:
		var post:=art.group(self,town.pos(d,4.0,ground(d,4.0)))
		post.rotation.y=town.heading(d)-1.1
		art.cyl(post,Vector3(0,0.85,0),0.075,0.07,1.7,art.WOOD)
		art.box(post,Vector3(0,1.55,0),Vector3(1.75,0.56,0.11),art.TEAL)
		town.sign_text(post,"山脊便道" if d==50 else "回主路",Vector3(0,1.55,0.08),0.006)