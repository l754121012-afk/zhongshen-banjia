extends Node3D

signal surfaced(recovered:bool,rescue_cost:int)
const Art=preload("res://workshop.gd")
const DockArt=preload("res://tide_art.gd")
const BELL:=Vector2(-10,3.8)
const KEY_SITE:=Vector2(-7.7,-2.65)
const SOCKET:=Vector2(0.20,-2.15)
const RELIC:=Vector2(10.8,-2.2)
const AIR:=[Vector2(-0.9,3.5),Vector2(10.5,3.6)]
const LEDGES:=[Rect2(-4.9,-4.7,1.12,5.4),Rect2(4.05,-4.7,1.0,4.65),Rect2(4.05,3.0,1.0,3.65)]
var art:=Art.new()
var design:=DockArt.new()
var pilot:Node3D
var shell:Node3D
var cog:Node3D
var gate:Node3D
var pearl:Node3D
var iris:Node3D
var camera:=Camera3D.new()
var spots:Array[Node3D]=[]
var bubbles:Array[Node3D]=[]
var rays:Array[Node3D]=[]
var fish:Array[Node3D]=[]
var weeds:Array[Node3D]=[]
var tether:Node3D
var hud:=CanvasLayer.new()
var title:=Label.new()
var task:=Label.new()
var oxygen_text:=Label.new()
var hint:=Label.new()
var controls:=Label.new()
var compass:=Label.new()
var font:=preload("res://harbour_fonts.gd").body()
var pos:=BELL
var velocity:=Vector2.ZERO
var direction:=1.0
var pocket:=""
var gate_open:=false
var gate_height:=0.0
var air:=38.0
var air_max:=38.0
var lamp_unlocked:=false
var boost:=0.0
var boost_rearm:=0.0
var elapsed:=0.0
var sting:=""
var sting_time:=0.0
var rescue:=false
var rescue_time:=0.0
var source_sound
var ambience:=AudioStreamPlayer.new()
var font_color:=Color("#bdece2")

func _ready()->void:
	add_child(camera);camera.current=true
	camera.fov=46
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("#133c50")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("#7fc4c0")
	env.ambient_light_energy=0.65
	env.fog_enabled=true;env.fog_density=0.021
	env.fog_light_color=Color("#1a5868")
	camera.environment=env
	var key_light:=DirectionalLight3D.new()
	key_light.light_color=Color("#b5e8d4");key_light.light_energy=0.88
	key_light.rotation_degrees=Vector3(-54,-28,0)
	add_child(key_light)
	build_ruin()
	build_diver()
	if lamp_unlocked:
		air_max=46;air=air_max
		var brim:=art.ring(pilot,Vector3(0,0.42,0.41),0.29,0.038,DockArt.BRASS);brim.rotation.x=PI/2
		var torch:=OmniLight3D.new();torch.light_color=Color("#ffe1a3");torch.light_energy=2.5;torch.omni_range=7;torch.position=Vector3(0,0.45,1.2);pilot.add_child(torch)
	add_child(ambience);ambience.stream=preload("res://audio/styx_depth.wav");ambience.volume_db=-13;ambience.finished.connect(func():ambience.play());ambience.play()
	build_hud()
	settle(1.0)
	announce("灯匠的潜水灯 · 密封气室多出 8 秒余量" if lamp_unlocked else "潜水钟已抵达 · 海草和气泡会告诉你水流方向",2.3)

func pool_surface(n:MeshInstance3D)->void:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://abyss_caustic.gdshader")
	n.material_override=mat

func put_light(at:Vector3,col:Color,energy:float,size:float)->void:
	var lamp:=OmniLight3D.new()
	lamp.position=at;lamp.light_color=col;lamp.light_energy=energy;lamp.omni_range=size
	add_child(lamp)

func gridpos(p:Vector2,z:=0.0)->Vector3: return Vector3(p.x,p.y,z)

func make_relic()->Node3D:
	var root:=art.group(self,gridpos(RELIC))
	design.light_stone(root,Vector3.ZERO,Vector3(0.56,0.87,0.46),"#8ff5d4")
	for k in 3:
		var r:=art.ring(root,Vector3.ZERO,0.54-k*0.08,0.038,DockArt.BRASS)
		r.rotation=Vector3(PI/2,k*PI/3,0.22)
	return root

func build_ruin()->void:
	var floor_mesh:=art.box(self,Vector3(0,-4.8,-2),Vector3(32,1.4,14),DockArt.SHADE)
	pool_surface(floor_mesh)
	for i in 10:
		var stone:=art.box(self,Vector3(-13+i*3.1,-3.8,-1),Vector3(3.07,0.5,7.1),"#617f77")
		stone.rotation.z=0.05*sin(i*2.0)
	for i in 7:
		design.arch(self,Vector3(-13+i*4.4,-3.55,-6-i%2),1.60,3.3+i%3,1.3)
	for i in 13:
		var p:=Vector3(-17+i*3.15,-3.6,-10-i%3*2)
		var cliff:=art.ball(self,p,Vector3(8.6,11+i%4*2.5,9.0),"#355d64",true)
		pool_surface(cliff)
	for r:Rect2 in LEDGES:
		var size:=Vector3(r.size.x,r.size.y,2.7)
		var pillar:=art.box(self,gridpos(r.get_center(),-0.4),size,"#607875")
		pool_surface(pillar)
		art.box(self,Vector3(r.get_center().x,r.end.y,-0.4),Vector3(size.x+0.26,0.25,2.99),DockArt.SALT)
	for i in 22:
		var x:float=-13.5+i*1.28
		var plant:=art.group(self,Vector3(x,-3.48,-2.8-(i%3)*0.36))
		for j in 3:
			var b:=art.ball(plant,Vector3((j-1)*0.25,0.65+0.15*j,0),Vector3(0.16,1.35+0.30*(i%3),0.22),"#528c74",true)
			b.rotation.z=(j-1)*0.35
		weeds.append(plant)
	for i in 11:
		var school:=art.group(self,Vector3(-11+i*2.3,1.3+sin(i*1.7)*2.2,-3.8-i%3))
		art.ball(school,Vector3.ZERO,Vector3(0.58,0.25,0.18),"#a7caad",true)
		var tail:=art.ball(school,Vector3(-0.32,0,0),Vector3(0.24,0.3,0.09),DockArt.BRASS,true)
		tail.rotation.z=0.28
		fish.append(school)
	for site:Vector2 in AIR:
		var vent:=art.group(self,gridpos(site))
		var hood:=art.ball(vent,Vector3(0,0.9,-0.55),Vector3(3.5,0.52,2.5),"#77978a",true)
		design.light_stone(vent,Vector3(-1.22,0.50,-0.2),Vector3.ONE*0.27,DockArt.SIGNAL)
		for i in 7:
			var bubble:=art.ball(vent,Vector3(sin(i*2.2)*0.58,-1.7+i*0.43,i%2*-0.31),Vector3.ONE*(0.095+i%3*0.045),"#9bd5c7")
			bubbles.append(bubble)
		spots.append(vent)
		put_light(gridpos(site,0.4),Color("#72e3b7"),1.7,4.5)
	var lamp:=art.group(self,gridpos(BELL))
	art.cyl(lamp,Vector3.UP*0.72,1.05,0.83,1.8,"#9f8155",12)
	art.ball(lamp,Vector3.UP*1.61,Vector3(1.72,0.8,1.72),DockArt.BRASS)
	var port:=art.ring(lamp,Vector3(0,0.8,0.92),0.34,0.08,DockArt.INK)
	port.rotation.x=PI/2
	art.beam(lamp,Vector3.UP*1.94,Vector3.UP*10.0,0.06,DockArt.INK)
	put_light(gridpos(BELL,1),Color("#ffc988"),2.2,6)
	cog=art.group(self,gridpos(KEY_SITE))
	var hub:=art.ring(cog,Vector3.ZERO,0.42,0.14,DockArt.BRASS)
	hub.rotation.x=PI/2
	for j in 8:
		var a:=j*TAU/8
		var tooth:=art.box(cog,Vector3(cos(a)*0.53,sin(a)*0.53,0),Vector3(0.23,0.17,0.24),DockArt.BRASS)
		tooth.rotation.z=a
	iris=art.group(self,gridpos(SOCKET))
	var seat:=art.ring(iris,Vector3.ZERO,0.68,0.11,DockArt.BRASS)
	seat.rotation.x=PI/2
	art.beam(self,gridpos(SOCKET)+Vector3.DOWN*0.7,gridpos(Vector2(4.55,-2.8)),0.064,DockArt.BRASS)
	gate=art.group(self,Vector3(4.55,0,0))
	for y in [0.25,1.0,1.75,2.50]:
		art.box(gate,Vector3(0,y,0),Vector3(0.82,0.30,2.6),DockArt.BRASS)
	for z in [-1.05,1.05]: art.box(gate,Vector3(0,1.5,z),Vector3(0.26,3,0.21),DockArt.INK)
	pearl=make_relic()
	put_light(gridpos(RELIC,0.6),Color("#78ffe6"),2.2,5.5)
	for i in 6:
		var shaft:=art.cyl(self,Vector3(-11+i*4.65,2.4,-4-i%2),0.69,0.18,12,"#8ad8c3",12)
		var m:=StandardMaterial3D.new()
		m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color=Color(0.56,0.90,0.78,0.055)
		shaft.material_override=m;shaft.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shaft.rotation.z=-0.30
		rays.append(shaft)

func build_diver()->void:
	pilot=art.group(self,gridpos(pos,0.45))
	var body:=art.courier(pilot)
	body.scale=Vector3.ONE*0.59;body.position=Vector3(0,-0.63,0)
	shell=art.ball(pilot,Vector3(0,0.46,0),Vector3(0.75,0.67,0.72),"#bc9557")
	var porthole:=art.cyl(pilot,Vector3(0,0.48,0.32),0.22,0.22,0.10,DockArt.INK)
	porthole.rotation.x=PI/2
	var rim:=art.ring(pilot,Vector3(0,0.48,0.39),0.22,0.045,DockArt.BRASS)
	rim.rotation.x=PI/2
	design.light_stone(pilot,Vector3(0.30,0.58,0.12),Vector3.ONE*0.17,"#f9d694")
	for x in [-0.22,0.22]:
		art.cyl(pilot,Vector3(x,0.05,-0.27),0.14,0.14,0.78,DockArt.BLUE)
	tether=art.beam(self,gridpos(BELL,0.15),gridpos(BELL+Vector2(0.1,-0.3),0.25),0.026,DockArt.INK)

func style(label:Label,size:int)->void:
	label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("#e5ebd9"))
	var bg:=StyleBoxFlat.new();bg.bg_color=Color("#123442ed")
	bg.set_corner_radius_all(8);bg.content_margin_left=14;bg.content_margin_right=14
	bg.content_margin_top=7;bg.content_margin_bottom=7;label.add_theme_stylebox_override("normal",bg)

func build_hud()->void:
	add_child(hud)
	for l in [title,task,oxygen_text,hint,controls,compass]:hud.add_child(l);style(l,16)
	title.add_theme_font_size_override("font_size",23);title.position=Vector2(26,22)
	title.text="北岬海峡　/　沉没的潮印库"
	task.position=Vector2(26,73);oxygen_text.position=Vector2(1050,22)
	controls.position=Vector2(26,652);controls.text="WASD 游动　 空格 蹬水冲刺　 E 拾取 / 安装 / 回钟　 Esc 紧急回船"
	compass.position=Vector2(26,119)
	hint.position=Vector2(420,575)
	for data in [[BELL,"潜水钟"],[KEY_SITE,"青铜齿轮"],[SOCKET,"绞盘"],[RELIC,"潮印"]]:
		var label:=Label3D.new();label.text=data[1];label.font=font;label.font_size=26;label.pixel_size=0.011
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=font_color
		label.outline_size=6;label.position=gridpos(data[0])+Vector3.UP*1.0;add_child(label)

func announce(words:String,duration:=1.4)->void:sting=words;sting_time=duration
func cue(id:String)->void:
	if is_instance_valid(source_sound):source_sound.play_cue(id)
func near(p:Vector2,r:=1.40)->bool:return pos.distance_to(p)<r

func interact()->void:
	if rescue:return
	if near(BELL):
		surfaced.emit(pocket=="relic",0);return
	if near(KEY_SITE) and pocket=="" and not gate_open:
		pocket="key";cue("grab");announce("拿到青铜齿轮 · 带去金色绞盘");return
	if near(SOCKET) and pocket=="key":
		pocket="";gate_open=true;cue("load");announce("水门升起 · 顺流穿过遗迹",1.75);return
	if near(RELIC) and gate_open and pocket=="":
		pocket="relic";cue("snap");announce("潮印已取出 · 带回潜水钟",1.9);return
	announce("靠近目标后再操作",0.8)

func _unhandled_key_input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_E:interact();get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			cue("wind");surfaced.emit(false,0 if near(BELL) else 6);get_viewport().set_input_as_handled()
		KEY_SPACE:
			if not rescue and boost_rearm<=0 and air>=3.5:
				boost=0.38;boost_rearm=1.0;air-=2.0;cue("wind")

func blocked(p:Vector2)->bool:
	if p.x< -12.2 or p.x>12.8 or p.y< -3.1 or p.y>5.75:return true
	for r:Rect2 in LEDGES:
		if r.grow(0.29).has_point(p):return true
	if not gate_open and Rect2(3.76,-0.25,1.60,3.63).has_point(p):return true
	return false

func _physics_process(dt:float)->void:
	elapsed+=dt;sting_time=maxf(0,sting_time-dt)
	if rescue:
		rescue_time+=dt
		if rescue_time>1.2:surfaced.emit(false,6)
		return
	var move:=Vector2(float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))-float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))).limit_length(1)
	if absf(move.x)>0.1:direction=signf(move.x)
	boost=maxf(0,boost-dt);boost_rearm=maxf(0,boost_rearm-dt)
	var current:float=smoothstep(-4.0,-1.5,pos.x)*(1-smoothstep(6,8.5,pos.x))*(0.4+0.46*sin(elapsed*1.4))
	var intent:=move*(3.6 if pocket=="" else 2.85)
	if boost>0: intent+=(move if move.length()>0.1 else Vector2(direction,0))*4.7
	velocity=velocity.move_toward(intent+Vector2(current,-0.11),dt*8.7)
	var dx:=Vector2(velocity.x*dt,0);var dy:=Vector2(0,velocity.y*dt)
	if not blocked(pos+dx):pos+=dx
	else:velocity.x=0
	if not blocked(pos+dy):pos+=dy
	else:velocity.y=0
	var breathing:=near(BELL,1.5) or near(AIR[0],1.5) or near(AIR[1],1.5)
	air=clampf(air+(8.0 if breathing else -1.0)*dt,0,air_max)
	if air<=0:
		rescue=true;rescue_time=0;announce("氧气耗尽 · 绞盘回收，救援费 6 枚",1.3);cue("warn")
	settle(dt)
	var instruction:="潮印锁在水门后。左下方有只齿轮，能装回绞盘。"
	if pocket=="key":instruction="携齿轮抵达底部绞盘 · E 安装"
	elif gate_open:instruction="穿过抬起的水门，取出潮印" if pocket=="" else "潮印已回收 · 回左侧潜水钟"
	task.text=instruction
	compass.text="气穴补氧中" if breathing else ("潮印在手 · 回程负重" if pocket=="relic" else "金色钟罩可安全上浮")
	oxygen_text.text="氧气　%02d 秒"%ceili(air)
	oxygen_text.modulate=Color("#ff906f") if air<9 else Color.WHITE
	var local:=""
	if near(BELL):local="E 返回渡船"+(" · 交付潮印" if pocket=="relic" else "")
	elif near(KEY_SITE) and not gate_open and pocket=="":local="E 拾起青铜齿轮"
	elif near(SOCKET) and pocket=="key":local="E 安装齿轮，抬门"
	elif near(RELIC) and gate_open and pocket=="":local="E 取出潮印"
	hint.text=sting if sting_time>0 else local
	hint.visible=not hint.text.is_empty()
	hint.reset_size();hint.position.x=(1280-hint.size.x)/2

func settle(dt:float)->void:
	pilot.position=gridpos(pos,0.45)+Vector3.UP*(sin(elapsed*3.5)*0.035)
	pilot.rotation.z=lerpf(pilot.rotation.z,-velocity.x*0.075,1-exp(-dt*7))
	var end:=pilot.position+Vector3(0,0.1,-0.22)
	var origin:=gridpos(BELL,0.16)+Vector3.DOWN*0.25
	tether.position=(end+origin)/2;tether.scale.y=end.distance_to(origin)/0.33
	if origin.distance_to(end)>0.001:tether.quaternion=Quaternion(Vector3.UP,origin.direction_to(end))
	if pocket=="key":cog.position=pilot.position+Vector3(direction*0.48,-0.18,0)
	elif gate_open:cog.position=gridpos(SOCKET,0.25);cog.rotation.z=elapsed*0.5
	if pocket=="relic":pearl.position=pilot.position+Vector3(direction*0.55,0.05,0.15)
	else:pearl.position=gridpos(RELIC)+Vector3.UP*sin(elapsed*2)*0.13
	pearl.rotation.y=elapsed*0.7
	gate_height=move_toward(gate_height,3.6 if gate_open else 0,dt*2.4)
	gate.position.y=gate_height
	for i in bubbles.size():
		bubbles[i].position.y=-2.2+fposmod(elapsed*0.82+i*0.43,3.3)
	for i in fish.size():
		fish[i].position.x=-11+i*2.3+sin(elapsed*0.45+i)*1.17
		fish[i].rotation.y=0 if cos(elapsed*0.45+i)>0 else PI
	for i in weeds.size():weeds[i].rotation.z=0.12*sin(elapsed*1.8+i)
	var center:=Vector3(clampf(pos.x*0.66,-6.2,6.8),clampf(pos.y*0.33,-0.5,1.5),0)
	camera.position=camera.position.lerp(center+Vector3(0,1.45,14.4),1-exp(-dt*5))
	camera.basis=Basis.looking_at(Vector3(0,-1.45,-14.4),Vector3.UP)

