extends Node3D

const Art=preload("res://workshop.gd")
const Town=preload("res://district.gd")
var art=Art.new()
var town=Town.new()
var truck:Node3D
var couch:Node3D
var sack:Node3D
var barrel:Node3D
var cam:=Camera3D.new()
var info:=Label.new()
var elapsed:=0.0
var lane:=0.0
var velocity:=0.0
var hit:=false
var judged:=false
var paused:=false
var record:=false
const SPEED:=5.3
const END:=72.0

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

func block(d:float,side:float,h:float,dimensions:Vector3,col:String)->void:
	var n=art.box(self,pos(d,side,h),dimensions,col)
	n.rotation.y=heading(d)

func ribbon(start:float,end:float,inside:float,outside:float,h:float,col:String)->void:
	var s:=SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count:=ceili(end-start)
	for i in count:
		var a:=lerpf(start,end,float(i)/count)
		var b:=lerpf(start,end,float(i+1)/count)
		for point:Vector3 in [pos(a,inside,h),pos(b,inside,h),pos(b,outside,h),pos(a,inside,h),pos(b,outside,h),pos(a,outside,h)]:
			s.set_normal(Vector3.UP)
			s.add_vertex(point)
	var mesh:=MeshInstance3D.new()
	mesh.mesh=s.commit()
	var mat=art.material(col).duplicate()
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=mat
	add_child(mesh)

func _ready()->void:
	record=OS.get_cmdline_user_args().has("--film")
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("#a7d0df")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("#d7e6e3")
	env.environment.ambient_light_energy=0.65
	env.environment.fog_enabled=true
	env.environment.fog_light_color=Color("#a7c9d1")
	env.environment.fog_density=0.0035
	add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-46,0)
	sun.light_energy=1.04
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=125
	add_child(sun)
	var water=art.box(self,Vector3(25,-3.6,-10),Vector3(450,0.3,450),"#528f9a")
	var waves:=ShaderMaterial.new()
	waves.shader=preload("res://coast.gdshader")
	water.material_override=waves
	ribbon(-14,90,-4.7,4.7,0.0,"#bdab91")
	for side in [-1,1]:
		ribbon(-14,90,side*4.53,side*4.7,0.023,"#e5d4ab")
	for i in range(-6,46):
		var d:=i*2.0
		var bridge:=d>=24 and d<=36
		if bridge:
			block(d,0,-0.46,Vector3(2.12,0.89,9.5),"#ae967b")
			for side in [-1,1]:
				block(d,side*4.65,0.39,Vector3(2.03,0.78,0.32),"#d6c39e")
			if i%3==0: block(d,0,-2.15,Vector3(0.85,3.5,8.7),"#a48d75")
		else:
			var cliff=art.ball(self,pos(d,0,-2.28),Vector3(7.0,4.25,13.3),"#b59e80",true)
			cliff.rotation.y=heading(d)
			if i%2==0:
				block(d,-4.59,0.29,Vector3(1.22,0.58,0.36),"#decaab")
		if i%3==0:
			block(d,0,0.02,Vector3(1.42,0.026,0.105),"#e1d0aa")
		if not bridge and i%4==0:
			var lot:=pos(d,9.5,-1.3)
			art.ball(self,lot,Vector3(12,3.0,12),"#97a178",true)
			town.house(self,lot+Vector3.UP*1.4,1.2,"#e1c99e")
			art.cypress(self,lot+Vector3(2.3,1.4,1.4),1.3)
	for i in 18:
		var island:=Vector3(25+i*5,-5,-29.0-absf(sin(i))*20)
		art.ball(self,island,Vector3(18,10+i%4*2,16),"#819d94",true)
		if i%3==0: town.house(self,island+Vector3.UP*5.2,0.95,Art.SAND)
	var hill:=Vector3(73,1,-27)
	art.ball(self,hill,Vector3(22,17,21),"#a4a58a",true)
	for x in [-3,-1,1,3]:
		art.column(self,hill+Vector3(x,8,0),3.1)
	art.box(self,hill+Vector3(0,11.3,0),Vector3(8.0,0.56,3.6),Art.CREAM)
	art.tile_roof(self,hill+Vector3(0,11.85,0),8.4,4.1)
	for d in [0.0,END]:
		block(d,4.5,0.26,Vector3(5.0,0.50,3.3),Art.WOOD)
		town.house(self,pos(d,7.4,0),1.05,Art.CREAM)
		art.crate(self,pos(d+1.7,4.7,0.52),0.82)
	barrel=art.group(self,pos(17,0.9,0.58))
	var body=art.cyl(barrel,Vector3.ZERO,0.58,0.58,1.24,Art.WOOD)
	body.rotation.x=PI/2
	for z in [-0.47,0.47]:
		var band=art.ring(barrel,Vector3(0,0,z),0.59,0.045,Art.DARK)
		band.rotation.x=PI/2
	truck=art.truck(self)
	couch=art.bed(truck)
	couch.position=Vector3(-0.78,1.11,-0.43)
	couch.rotation.y=PI/2
	sack=art.sack(truck)
	sack.position=Vector3(-1.6,1.11,0.66)
	add_child(cam)
	cam.fov=53
	cam.current=true
	add_child(info)
	info.position=Vector2(30,24)
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Microsoft YaHei","SimHei"])
	info.add_theme_font_override("font",font)
	info.add_theme_font_size_override("font_size",23)
	info.add_theme_constant_override("outline_size",7)
	info.add_theme_color_override("font_outline_color",Color("#244548"))
	draw_frame(0)

func draw_frame(dt:float)->void:
	var drive:=clampf(elapsed-3.0,0,END/SPEED)
	var d:=drive*SPEED
	var arrival:=maxf(0,elapsed-3.0-END/SPEED)
	var move:=float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))
	if record: move=-1 if d>4 and d<8 else (1 if d>23 and d<27 else 0)
	velocity=move_toward(velocity,move*2.4,dt*7)
	if d>0 and d<END: lane=clampf(lane+velocity*dt,-2.55,2.55)
	truck.position=pos(d,lane,0.09)
	truck.rotation.y=heading(d)
	var entered:=smoothstep(0.45,3.4,elapsed)
	var exited:=smoothstep(0.0,2.8,arrival)
	var chase:=entered*(1-exited)
	# A common rear hemisphere and a persistent cargo target keep the cut continuous.
	var yaw:=lerpf(-0.68,0.0,chase)+heading(d)
	var offset:=Vector3(-cos(yaw)*10.0,lerpf(10.7,7.8,chase),sin(yaw)*10.0)
	var eye:=pos(d,lane*0.72,0)+offset
	var target:=pos(d+lerpf(0.0,4.2,chase),lane*0.64,0.77)
	cam.position=eye
	cam.look_at(target)
	barrel.position=pos(17,0.72+sin(elapsed*1.4)*0.38,0.58)
	barrel.rotation.z=elapsed*1.8
	if not judged and d>=14.8:
		judged=true
		hit=absf(lane-(0.72+sin(elapsed*1.4)*0.38))<1.28
	var jolt:=maxf(0,1-absf(d-16)/3) if hit else 0.0
	couch.rotation.x=sin(d*2)*0.16*jolt
	sack.rotation.x=-velocity*0.08+sin(d*2)*jolt*0.29
	var load_u:=smoothstep(0.05,1.45,elapsed)
	var unload_u:=smoothstep(1.0,3.20,arrival)
	sack.position.z=0.66+3.5*(1-load_u+unload_u)
	sack.position.y=1.11+sin(load_u*PI)*1.15+sin(unload_u*PI)*1.05-0.55*(1-load_u+unload_u)
	var stage:="提货  ·  西风号装车" if elapsed<3 else ("交货  ·  西风港" if arrival>0 else "在途  ·  西风岬")
	info.text=stage+"\n"+"A / D 换道     空格 暂停     R 重看"
	if judged and d<23: info.text+="\n"+("碰到酒桶，注意货物倾斜" if hit else "已避开酒桶")
	for wheel in get_tree().get_nodes_in_group("wheels"):
		wheel.rotation.z=-d*1.7

func _process(dt:float)->void:
	if not paused:
		elapsed+=dt
		draw_frame(dt)
	if record and elapsed>=21.3: get_tree().quit()

func _unhandled_key_input(e:InputEvent)->void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode==KEY_SPACE: paused=not paused
		elif e.keycode==KEY_R:
			elapsed=0; lane=0; velocity=0; hit=false; judged=false; paused=false

