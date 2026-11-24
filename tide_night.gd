extends Node3D

signal left_dock(pay:int)
var bread_fare:=8
signal basket_delivered
var bread_loaded:=false
var bread_delivered:=false
var basket:Node3D
const Art=preload("res://workshop.gd")
const Night=preload("res://night_art.gd")
const PORTS:=[Vector2(-30,13),Vector2(-16,-22),Vector2(21,-15),Vector2(26,19)]
const NAMES:=["渡税亭","石榴庭","沉剧场","双灯窑"]
const COLORS:=["#e6c483","#e39b91","#9bcfc6","#efb276"]
const ORIGINS:=[0,0,1,2]
const STOPS:=[2,3,0,1]
const GUESTS:=["琴师","灯匠","果农","面具匠"]
const TINTS:=["#8bc8c0","#dfb477","#ba929c","#a8b3d4"]
const REEF_DATA:=[Vector3(-20,2.2,-3),Vector3(-6,2.6,5),Vector3(2,2.0,-11),Vector3(12,2.1,13),Vector3(17,2.3,1),Vector3(-4,1.9,19),Vector3(-9,2.1,-15)]
const COIN_DATA:=[Vector2(-15,3),Vector2(8,-9),Vector2(13,17)]
var art:=Art.new()
var design:=Night.new()
var sound=preload("res://sound.gd").new()
var melody:=AudioStreamPlayer.new()
var horn:=AudioStreamPlayer.new()
var chord:=AudioStreamPlayer.new()
var cam:=Camera3D.new()
var boat:Node3D
var beacon_unlocked:=false
var traffic:=preload("res://styx_traffic.gd").new()
var arrivals:Dictionary={}
var destinies:Array[Node3D]=[]
const WISHES:=["好久没听见这里的回声了。","窑里的火，还等着我。","给岸上的人带一颗石榴。","这一次，我自己挑面具。"]
const GIFTS:=["鸣螺时平息横流","近礁持续显形","带着果篮，船速稍慢","演出结束后去果园"]
var docks:Array[Node3D]=[]
var quay_lights:Array[Node3D]=[]
var port_names:Array[Label3D]=[]
var guests:Array[Node3D]=[]
var bobbers:Array[Node3D]=[]
var reefs:Array[Vector3]=[]
var reveal:Array[float]=[]
var warning_rings:Array[Node3D]=[]
var coins:Array[Vector2]=[]
var found:Array[bool]=[]
var coin_reveal:Array[float]=[]
var coin_shapes:Array[Node3D]=[]
var states:Array[int]=[0,0,0,0]
var seats:Array[int]=[]
var manifests:=[0,0,0,0]
var stage:="sail"
var pos:=Vector2(-28.8,12.4)
var heading:=-0.32
var view_heading:=-0.32
var speed:=0.0
var time:=0.0
var waves:=0.0
var walked:=0.0
var pulse_age:=8.0
var pulse_origin:=Vector2.ZERO
var pulse_charge:=1.0
var collision_lock:=0.0
var damage:=0
var total:=0
var port:=0
var selected:=0
var port_cool:=0.0
var hush:=0.0
var message_left:=0.0
var note:=""
var hud:=CanvasLayer.new()
var title:=Label.new()
var task:=Label.new()
var guide:=Label.new()
var action:=Label.new()
var bill:=Label.new()
var deck:=Label.new()
var chart:=preload("res://tide_chart.gd").new()
var face:=preload("res://harbour_fonts.gd").body()
var cam_target:=Vector3.ZERO
var cam_ready:=false

func _ready()->void:
	add_child(sound);add_child(melody);add_child(horn);add_child(chord)
	melody.stream=preload("res://audio/styx_night.wav");melody.volume_db=-11;melody.finished.connect(func():melody.play());melody.play()
	horn.stream=preload("res://audio/styx_conch.wav");horn.volume_db=-5
	chord.stream=preload("res://audio/styx_chord.wav");chord.volume_db=-5
	add_child(cam);cam.current=true;cam.fov=54
	var env:=Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky:=ProceduralSkyMaterial.new();sky.sky_top_color=Color("#111a32");sky.sky_horizon_color=Color("#716779")
	sky.ground_horizon_color=Color("#504958");sky.sky_curve=0.31;sky.sun_angle_max=0.1
	env.sky=Sky.new();env.sky.sky_material=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("#aab3ca");env.ambient_light_energy=0.74
	env.fog_enabled=true;env.fog_light_color=Color("#706780");env.fog_density=0.0050;env.fog_aerial_perspective=0.29
	env.glow_enabled=true;env.glow_intensity=0.62;env.glow_bloom=0.13
	env.ssao_enabled=true;env.ssao_radius=1.05;env.ssao_intensity=1.50
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	cam.environment=env
	var moonlight:=DirectionalLight3D.new();moonlight.rotation_degrees=Vector3(-36,-61,0)
	moonlight.light_color=Color("#c4ceeb");moonlight.light_energy=0.69;moonlight.shadow_enabled=true;moonlight.directional_shadow_max_distance=65;add_child(moonlight)
	design.horizon(self);create_stations();create_channel();boat=design.ferry(self)
	basket=art.group(boat,Vector3(-.90,.70,.42))
	var hamper:=art.cyl(basket,Vector3.UP*.22,.42,.53,.42,"#a17b50",12)
	for j in 3:art.ring(basket,Vector3.UP*(.12+j*.12),.42+j*.05,.035,"#d1ac72")
	var arch:=art.ring(basket,Vector3.UP*.49,.34,.045,"#bf9c64");arch.rotation.x=PI/2
	for j in 4:
		var loaf:=art.ball(basket,Vector3((j%2-.5)*.38,.46,(j/2-.5)*.30),Vector3(.44,.28,.31),"#d6a463",true)
		art.box(loaf,Vector3.UP*.45,Vector3(.38,.07,.08),"#edcf93")
	basket.visible=bread_loaded
	traffic.active_beacon=beacon_unlocked;add_child(traffic);build_destinies()
	for i in 4:guests.append(design.ghost(self,i,TINTS[i]))
	build_hud();reset_run()

func create_stations()->void:
	for i in PORTS.size():
		var point:Vector2=PORTS[i];var outward:=point.normalized()
		var n:=design.terrace(self,Vector3(point.x,0,point.y),outward,i,COLORS[i]);docks.append(n)
		var light:=design.glow(n,Vector3(0,1.05,1.7),Vector3(0.38,0.63,0.38),COLORS[i],1.55);quay_lights.append(light)
		port_names.append(design.label(n,Vector3(4,4,0),NAMES[i],face,COLORS[i]))
		var b:=art.group(self,Vector3(point.x-outward.x*2.1,-0.4,point.y-outward.y*2.1))
		var ring:=art.ring(b,Vector3.ZERO,2.2,0.042,COLORS[i]);ring.material_override=design.emission(COLORS[i],0.8)
		bobbers.append(b)

func build_destinies()->void:
	for i in 4:
		var base:=docks[int(STOPS[i])]
		var gift:=art.group(base,Vector3(6.1,1.7,(i%2-0.5)*3.0))
		match i:
			0:
				for j in 5:
					var note_shape:=design.glow(gift,Vector3(j*0.42,0.7+(j%3)*0.41,0),Vector3(.28,.21,.24),"#9eeed6",1.05)
					art.beam(gift,note_shape.position,note_shape.position+Vector3.UP*0.51,0.028,Night.GILT)
			1:
				for j in 4:design.flame(gift,Vector3((j%2)*1.2,0,(j/2)*1.1),"#ffb16f")
				design.lamp(gift,Vector3.UP*2,"#ffc485",3.4,7)
			2:
				art.box(gift,Vector3.UP*0.25,Vector3(1.62,0.45,1.08),Night.COPPER)
				for j in 6:design.glow(gift,Vector3((j%3-1)*.42,.58,(j/3-.5)*.42),Vector3.ONE*.44,"#e39377",0.48)
			3:
				for j in 3:
					art.beam(gift,Vector3(j*.65,0,0),Vector3(j*.65,1.64,0),.052,Night.COPPER)
					design.glow(gift,Vector3(j*.65,1.75,0),Vector3(.47,.64,.27),"#e6cfa2",.73)
		gift.hide();destinies.append(gift)

func create_channel()->void:
	for rock:Vector3 in REEF_DATA:
		reefs.append(rock);reveal.append(0)
		var shoal:=art.group(self,Vector3(rock.x,-0.69,rock.z))
		var main:=art.ball(shoal,Vector3.UP*0.26,Vector3(rock.y*1.65,1.45,rock.y*1.5),"#596071",true)
		main.rotation.y=rock.x
		for j in 3:
			var a:=j*TAU/3
			art.ball(shoal,Vector3(cos(a)*rock.y*0.64,0.18,sin(a)*rock.y*0.64),Vector3(0.94,0.83,1.21),"#65727a",true)
		var edge:=art.ring(shoal,Vector3.UP*0.20,rock.y+0.63,0.056,"#e8ab98")
		edge.material_override=design.emission("#ffc1a5",1.25);edge.hide();warning_rings.append(edge)
	for point:Vector2 in COIN_DATA:
		coins.append(point);found.append(false);coin_reveal.append(0)
		var token:=art.group(self,Vector3(point.x,0.16,point.y))
		var coin:=art.cyl(token,Vector3.UP*0.50,0.40,0.40,0.12,"#c69b61",12);coin.rotation.x=PI/2
		var edge:=art.ring(token,Vector3(0,0.5,0.08),0.32,0.045,"#dfc27a");edge.rotation.x=PI/2;edge.material_override=design.emission("#f8d79c",1.4)
		token.hide();coin_shapes.append(token)

func style(l:Label,fsize:int,bg:String)->void:
	l.add_theme_font_override("font",face);l.add_theme_font_size_override("font_size",fsize);l.add_theme_color_override("font_color",Color("#f7e9cd"))
	var box:=StyleBoxFlat.new();box.bg_color=Color(bg);box.set_corner_radius_all(8);box.content_margin_left=13;box.content_margin_right=13;box.content_margin_top=7;box.content_margin_bottom=7
	l.add_theme_stylebox_override("normal",box)
func build_hud()->void:
	add_child(hud)
	for l in [title,task,guide,action,bill,deck]:hud.add_child(l);style(l,16,"#192b39ef")
	title.position=Vector2(24,20);title.add_theme_font_size_override("font_size",23);title.text="卡戎的夜班　/　冥河渡客"
	task.position=Vector2(24,72);deck.position=Vector2(24,119)
	guide.position=Vector2(24,651);guide.text="W S 划行 / 倒船　 A D 掌舵　 空格 鸣螺探浅　 E 停靠　 Q 选乘客　 Tab 展开航图　 Esc 返回"
	action.position=Vector2(420,566)
	bill.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;bill.position=Vector2(360,158);bill.custom_minimum_size.x=560;bill.add_theme_font_size_override("font_size",21)
	hud.add_child(chart);chart.mouse_filter=Control.MOUSE_FILTER_IGNORE;chart.face=face;chart.state=self;chart.set_large(false)

func reset_run()->void:
	bread_delivered=false
	pos=Vector2(-28.8,12.4);heading=-0.32;view_heading=heading;speed=0;time=0;walked=0;waves=0;pulse_age=8;pulse_charge=1;collision_lock=0;damage=0;total=0;selected=0;port_cool=0;hush=0
	arrivals.clear()
	for gift in destinies:gift.hide()
	seats.clear();stage="sail";bill.hide();chart.set_large(false)
	for i in 4:states[i]=0;manifests[i]=0
	for i in found.size():found[i]=false;coin_reveal[i]=0
	for i in reveal.size():reveal[i]=0
	sync_guests();port=0;cam_ready=false
	say("伊娅的面包已装船 · 捎到双灯窑可收 %d 枚，不占客座"%bread_fare if bread_loaded else "卡戎借出两张船票 · 在渡税亭按 E 接第一位乘客",3)
	pose(1,0);ui_update()

func sync_guests()->void:
	for i in guests.size():
		var g:=guests[i];g.show()
		if states[i]==0:
			var quay:=docks[int(ORIGINS[i])]
			if g.get_parent()!=quay:g.reparent(quay,false)
			g.position=Vector3(2.2+(i%2)*0.8,0.46,(i%2-0.5)*1.8);g.rotation.y=PI
		elif states[i]==1:
			if g.get_parent()!=boat:g.reparent(boat,false)
			var seat:=seats.find(i);g.position=Vector3(0.03+seat*1.43,0.57,-0.12 if seat==0 else 0.18);g.rotation.y=-0.25+seat*0.5
		else:
			var home:=docks[int(STOPS[i])]
			if g.get_parent()!=home:
				g.reparent(home,true)
				arrivals[i]={"from":g.position,"t":0.0}
				destinies[i].show()
func say(s:String,t:=1.6)->void:note=s;message_left=t
func delivered()->int:return states.count(2)
func waiting(index:int)->Array[int]:
	var a:Array[int]=[]
	for i in 4:
		if states[i]==0 and ORIGINS[i]==index:a.append(i)
	return a
func current_exposure(point:Vector2)->float:
	var nearest:=INF
	for dock:Vector2 in PORTS:nearest=minf(nearest,point.distance_to(dock))
	return smoothstep(3.8,7.4,nearest)

func nearest_port()->int:
	for i in 4:
		if pos.distance_to(PORTS[i])<5.6:return i
	return -1
func use()->void:
	if stage=="signed":left_dock.emit(total);return
	if port<0:say("对准岸边的灯环，慢航停靠");return
	if absf(speed)>2.7:say("收桨减速，再停靠接客");return
	if port_cool>0:return
	var moved:=false
	for i in seats.duplicate():
		if STOPS[i]==port:
			seats.erase(i);states[i]=2;chord.play();moved=true
			say(GUESTS[i]+"：「"+WISHES[i]+"」",2.6)
	if port==3 and bread_loaded:
		bread_loaded=false;bread_delivered=true;basket.reparent(docks[3],false);basket.position=Vector3(1.1,.54,1.64)
		basket_delivered.emit();chord.play();say("窑工：「是西湾第一炉的香气。」　捎货费 +%d 已入钱包"%bread_fare,3.75)
		moved=true
	if moved:
		sync_guests();port_cool=0.24
		return
	if port==0 and delivered()>=3:
		finish();return
	var can:=waiting(port)
	if can.is_empty():say("本站无人候船 · 航图标出各处码头");return
	if seats.size()>=2:say("两个座位已满 · 先送一位乘客下船");return
	var guest:int=can[posmod(int(manifests[port]),can.size())];states[guest]=1;seats.append(guest);speed=0;port_cool=0.27
	sound.play_cue("grab");say(GUESTS[guest]+"登船 · 前往"+NAMES[STOPS[guest]],1.35)
	sync_guests()
func pulse()->void:
	if pulse_charge<0.99:say("向前划行，海螺便会再次共鸣",0.95);return
	pulse_charge=0;pulse_age=0;pulse_origin=pos;horn.play()
	var yields:=traffic.whistle(pos)
	if 0 in seats:hush=5.8
	say("对向船收桨让行" if yields else ("琴声平息横流" if 0 in seats else "回声正在描出暗礁和遗钱"),1.15)
func finish()->void:
	var coins_pay:=found.count(true)*8
	var gratuity:=maxi(0,25-damage*3)
	total=delivered()*24+coins_pay+gratuity+(16 if delivered()==4 else 0)
	stage="signed";speed=0;chord.play();bill.show()
	bill.text="冥河末班　·　夜渡收班\n\n送达 %d / 4 位　船资 %d 枚\n遗钱 %d　稳渡小费 %d　全员抵达 %d\n\n夜班合计　%d 枚\n%s\nE 领取回公路　　R 再开一班"%[delivered(),delivered()*24,coins_pay,gratuity,16 if delivered()==4 else 0,total,"灯匠赠灯 · 下次日班潜水增加 8 秒氧气" if states[1]==2 else "码头已录入夜班航册"]
	if bread_delivered:bill.text+="\n西湾面包捎货费 %d 枚已单独入账"%bread_fare

func next_harbour()->Vector2:
	if not seats.is_empty():
		var best:int=seats[0]
		for i in seats:
			if pos.distance_squared_to(PORTS[STOPS[i]])<pos.distance_squared_to(PORTS[STOPS[best]]):best=i
		return PORTS[STOPS[best]]
	if delivered()>=3:return PORTS[0]
	var dest:=Vector2.ZERO;var lowest:=INF
	for i in 4:
		if states[i]==0 and pos.distance_to(PORTS[ORIGINS[i]])<lowest:lowest=pos.distance_to(PORTS[ORIGINS[i]]);dest=PORTS[ORIGINS[i]]
	return dest

func _unhandled_key_input(e:InputEvent)->void:
	if not e is InputEventKey or not e.pressed or e.echo:return
	match e.keycode:
		KEY_ESCAPE:left_dock.emit(total if stage=="signed" else 0);get_viewport().set_input_as_handled()
		KEY_E:use();get_viewport().set_input_as_handled()
		KEY_Q:
			if stage=="sail" and port>=0:manifests[port]+=1;message_left=0;ui_update()
		KEY_SPACE:
			if stage=="sail":pulse()
		KEY_TAB:
			chart.set_large(not chart.large);get_viewport().set_input_as_handled()
		KEY_R:
			if stage=="signed":reset_run()

func _physics_process(dt:float)->void:
	waves+=dt;message_left=maxf(0,message_left-dt);port_cool=maxf(0,port_cool-dt)
	var turn:=0.0
	if stage=="sail":
		time+=dt;collision_lock=maxf(0,collision_lock-dt);pulse_age+=dt;hush=maxf(0,hush-dt)
		var gas:=float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))-float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
		turn=float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		var cap:=8.0 if 2 in seats else (8.8 if seats.size()==2 else 9.7)
		speed=move_toward(speed,(cap if gas>0 else -2.5) if gas!=0 else 0,dt*(3.7 if gas>0 else 7.7 if gas<0 and speed>0 else 2.1))
		var pivot:=.44*(1.-current_exposure(pos))*(1.-smoothstep(.25,2.,absf(speed)))
		heading+=turn*dt*(0.55+pivot+0.57*minf(1,absf(speed)/4))*(-1 if speed< -0.2 else 1)
		var old:=pos
		var current:=Vector2(0.42*cos(waves*0.32),0.44*sin(waves*0.48+pos.x*0.12))*(0.12 if hush>0 else 1.0)
		current*=current_exposure(pos)
		pos+=(Vector2.from_angle(heading)*speed+current)*dt
		pos=pos.clamp(Vector2(-39,-30),Vector2(37,28))
		# Rounded shore boundaries keep the ferry from entering the spectator stands or trees.
		for j in 4:
			var b:Vector2=PORTS[j]+PORTS[j].normalized()*8.2
			if pos.distance_to(b)<8.65:pos=b+b.direction_to(pos)*8.65
		for i in reefs.size():
			var r:=reefs[i];var rpos:=Vector2(r.x,r.z)
			var distance:=pos.distance_to(rpos)
			var radius:=r.y+0.82
			if distance<radius:
				pos=rpos+rpos.direction_to(pos)*radius
				if absf(speed)>3.8 and collision_lock<=0:
					damage+=1;collision_lock=1.5;speed*=0.47;sound.play_cue("bonk");say("擦过暗礁 · 稳渡小费 −3");reveal[i]=3
			reveal[i]=maxf(0,reveal[i]-dt)
			if (1 in seats and distance<16.5) or distance<5.1 or (pulse_age<2.15 and absf(pulse_origin.distance_to(rpos)-pulse_age*17)<2.2):reveal[i]=maxf(reveal[i],4.0)
			warning_rings[i].visible=reveal[i]>0
		for i in coins.size():
			if found[i]:continue
			coin_reveal[i]=maxf(0,coin_reveal[i]-dt)
			if pulse_age<2.15 and absf(pulse_origin.distance_to(coins[i])-pulse_age*17)<2.2:coin_reveal[i]=9.0
			if coins[i].distance_to(pos)<2.25 and coin_reveal[i]>0:
				found[i]=true;sound.play_cue("snap");say("回声遗钱 · 加赏 8 枚")
		if traffic.tick(dt,pos,next_harbour(),collision_lock>0 or absf(speed)<2.6):
			damage+=1;collision_lock=1.7;speed*=0.43;sound.play_cue("bonk");say("擦碰商船 · 鸣螺可请对方收桨")
		var distance:=old.distance_to(pos)
		walked+=distance
		if absf(speed)>1:pulse_charge=minf(1,pulse_charge+distance/12.0)
		port=nearest_port()
	pose(dt,turn);ui_update()

func pose(dt:float,turn:float)->void:
	boat.position=Vector3(pos.x,0.08*sin(waves*2.5),pos.y)
	boat.rotation=Vector3(-turn*speed*0.012+0.027*sin(waves*1.3),-heading,0.024*cos(waves*1.6))
	for i in design.oars.size():design.oars[i].rotation.y=sin(waves*(1.7+absf(speed)*0.47))*(0.12+absf(speed)*0.055)*(1 if i else -1)
	for i in design.flames.size():
		design.flames[i].scale.y=0.86+0.14*sin(waves*6.8+i)
	for i in design.wisps.size():design.wisps[i].position.y=1.11+0.85*sin(waves*0.57+i)
	for i in 4:
		bobbers[i].position.y=-0.45+0.035*sin(waves*2.5+i)
		port_names[i].visible=pos.distance_to(PORTS[i])<32 or i==port
		if states[i]!=2:guests[i].position.y=(0.57 if states[i]==1 else 0.46)+0.10*sin(waves*2.3+i)
	for i:int in arrivals.keys():
		var transit:Dictionary=arrivals[i]
		var t:=minf(1.0,float(transit.t)+dt/1.35);transit.t=t
		var goal:=Vector3(4.22,1.1,0.86 if i%2 else -0.86)
		guests[i].position=Vector3(transit.from).lerp(goal,smoothstep(0,1,t))+Vector3.UP*(sin(t*PI)*0.69)
		guests[i].rotation.y=lerp_angle(guests[i].rotation.y,0.2,1-exp(-dt*5))
		if t>=1:arrivals.erase(i)
	for i in coins.size():
		coin_shapes[i].visible=not found[i] and coin_reveal[i]>0
		if coin_shapes[i].visible:coin_shapes[i].rotation.y=waves*2.3;coin_shapes[i].position.y=0.10+0.13*sin(waves*2)
	design.water_mat.set_shader_parameter("vessel",pulse_origin)
	design.water_mat.set_shader_parameter("echo_radius",pulse_age*17.0 if pulse_age<2.1 else -10.0)
	view_heading=lerp_angle(view_heading,heading,1-exp(-dt*4))
	var dir:=Vector3(cos(view_heading),0,sin(view_heading))
	var target:=boat.position+dir*2.65+Vector3.UP*1.38
	if not cam_ready:cam_target=target;cam_ready=true
	cam_target=cam_target.lerp(target,1-exp(-dt*5.8))
	var offset:=-dir*13.3+Vector3.UP*5.9+Vector3(-dir.z,0,dir.x)*2.2
	cam.position=cam_target+offset;cam.look_at(cam_target)
	chart.queue_redraw()

func ui_update()->void:
	task.text="送达 %d / 4 位 · 满三位可回渡税亭收班"%delivered()
	var manifest:=PackedStringArray()
	for guest in seats:manifest.append(GUESTS[guest]+" → "+NAMES[STOPS[guest]])
	deck.text="船上　"+("空座 × 2" if seats.is_empty() else "　/　".join(manifest))+("　·　面包篮 → 双灯窑" if bread_loaded else "")
	var prompt:=""
	if port>=0:
		var disembark:=false
		for guest in seats:
			if STOPS[guest]==port:disembark=true
		var options:=waiting(port)
		if disembark:prompt="E 靠岸下客"
		elif port==0 and delivered()>=3:prompt="E 结算夜班"+("　或继续接送最后一位" if delivered()==3 else "")
		elif not options.is_empty() and seats.size()<2:
			var id:int=options[posmod(int(manifests[port]),options.size())]
			prompt="E 接"+GUESTS[id]+"去"+NAMES[STOPS[id]]+" · "+GIFTS[id]+("　 Q 换乘客" if options.size()>1 else "")
		if port==3 and bread_loaded:prompt="E 靠岸 · 捎交面包篮"
		if absf(speed)>2.7 and not prompt.is_empty():prompt="慢航靠岸　·　"+NAMES[port]
	elif 1 in seats:prompt="灯匠举灯 · 近处暗礁持续显形"
	elif 0 in seats and hush>0:prompt="琴声止流"
	action.text=note if message_left>0 else prompt
	action.visible=stage=="sail" and not action.text.is_empty()
	action.reset_size();action.position.x=(1280-action.size.x)/2
	guide.visible=stage=="sail";task.visible=stage=="sail";deck.visible=stage=="sail";chart.visible=stage=="sail"
