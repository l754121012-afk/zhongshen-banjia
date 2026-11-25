extends Node3D

const HEAD:=Vector2(120,9)
const GARDEN:=Vector2(36,7)
var a:=preload("res://workshop.gd").new()
var craft:=preload("res://coastal_craft.gd").new()
var dock:=preload("res://tide_art.gd").new()
var owner_game
var step:=0
var active:=false
var water:Array[Node3D]=[]
var flowers:Array[Node3D]=[]
var wheel:Node3D
var rotor:Node3D
var axle:Node3D
var cart_part:Node3D
var charge:=0.
var opening:=.20
var elapsed:=0.
var testing:=false
var pressure:=0.
var visitor:Node3D
var leaves:Array[Node3D]=[]
var planted:Array[Node3D]=[]
var bridge_open:=0.
var citrus:Node3D
var juice_stall:Node3D
var fruit_meshes:Array[Node3D]=[]
var chart:=preload("res://spring_chart.gd").new()
var picked:=false
var baskets:=0
var intact:=6
var impact_count:=0
var night_stock:=false
var night_sales:=0
var income:=0
var road_point:=Vector2.ZERO
var road_yaw:=PI
var checkpoint:=Vector2.ZERO
var previous_pos:=Vector2.ZERO
var previous_yaw:=0.
var previous_speed:=0.
var turnaround:=0.
var turn_from:=0.
var board_note:=""
var note_time:=0.
var ceremony:=0.
var cove:=preload("res://spring_cove.gd").new()
var wrapped:=false
var discovered:=false
var heat:=0.
var last_pos:=Vector2.ZERO
var shroud:Node3D
var transfer:=0.
var cargo_start:=Vector3.ZERO
var shower:=preload("res://spring_shower.gd").new()
var potter:Node3D
var loading_part:Node3D
var stop_labels:Array[Label3D]=[]
var inspection:=0.
var admire:=0.
var garden_worker:Node3D
var speaker:=AudioStreamPlayer3D.new()
var local_trade:=0
var port_trade:=0

func save_state(cfg:ConfigFile)->void:
	for key in ["step","picked","baskets","intact","income","night_stock","night_sales","road_point","road_yaw","local_trade","port_trade","wrapped","heat","discovered"]:
		cfg.set_value("spring",key,get(key))

func load_state(cfg:ConfigFile)->void:
	step=clampi(cfg.get_value("spring","step",0),0,4)
	discovered=bool(cfg.get_value("spring","discovered",false))
	wrapped=bool(cfg.get_value("spring","wrapped",false))
	heat=clampf(cfg.get_value("spring","heat",0.),0.,1.)
	night_stock=bool(cfg.get_value("spring","night_stock",false))
	night_sales=maxi(0,cfg.get_value("spring","night_sales",0))
	picked=step==4 and cfg.get_value("spring","picked",false)
	intact=clampi(cfg.get_value("spring","intact",6),0,6)
	for key in ["baskets","income","local_trade","port_trade"]:set(key,maxi(0,cfg.get_value("spring",key,0)))
	road_point=cfg.get_value("spring","road_point",Vector2.ZERO)
	road_yaw=cfg.get_value("spring","road_yaw",PI)

func stamp()->void:
	road_point=owner_game.pos;road_yaw=owner_game.heading
	checkpoint=road_point;owner_game.file_postmarks()

func leave()->void:
	chart.hide();stamp();transfer=0.;cart_part.position=Vector3(-1.,1.23,0);active=false;testing=false;charge=0.;ceremony=0.
	owner_game.pos=previous_pos;owner_game.heading=previous_yaw;owner_game.speed=previous_speed
	owner_game.camera_yaw=previous_yaw;owner_game.altitude=owner_game.land.ground(previous_pos)
	owner_game.update_pose(1.);refresh();owner_game.open_board()
	if owner_game.stage=="signed":owner_game.receipt.show()

func fruit_bin(parent:Node3D,at:Vector3)->Node3D:
	var bin:=a.group(parent,at)
	a.box(bin,Vector3.UP*.08,Vector3(1.48,.15,1.04),"#98704a")
	for x in [-.69,.69]:
		for z in [-.47,.47]:a.box(bin,Vector3(x,.32,z),Vector3(.09,.63,.09),"#9d7950")
	for z in [-.49,.49]:
		for j in 2:a.box(bin,Vector3(0,.24+j*.21,z),Vector3(1.42,.14,.07),"#c4a074")
	for j in 6:
		var piece:=a.group(bin,Vector3((j%3-1)*.43,.37,(j/3-.5)*.44))
		a.ball(piece,Vector3.ZERO,Vector3.ONE*.39,"#e89946",true)
		a.ball(piece,Vector3(.06,.19,0),Vector3(.16,.052,.083),"#69865c",true)
		if parent==owner_game.truck:fruit_meshes.append(piece)
	return bin


func setup(g)->void:
	owner_game=g
	chart.job=self;g.title.get_parent().add_child(chart);chart.z_index=80
	add_child(shower);shower.prepare(g)
	var span:=a.group(self,Vector3(153,0,3.5))
	for side in [-1.,1.]:
		var abutment:=a.group(span,Vector3(side*7.1,-.04,0))
		var leaf:=a.group(abutment);leaves.append(leaf)
		for plank in 16:
			a.box(leaf,Vector3(-side*(plank+.5)*.44,-.13,0),Vector3(.42,.23,4.8),"#b79668" if plank%3 else "#c4a674")
		for z in [-2.32,2.32]:
			a.beam(leaf,Vector3(0,-.30,z),Vector3(-side*7.,-.30,z),.14,"#657871")
			a.column(abutment,Vector3(side*.48,-1.0,z),3.0)
		leaf.rotation.z=-side*1.08
	bridge_open=1. if step>=4 else 0.
	for j in 11:
		var orchard:=a.group(self,g.land.surface(Vector2(31+j*1.3,15.9)))
		var trunk:=a.beam(orchard,Vector3.ZERO,Vector3(.15,1.85,0),.13,"#7b624c")
		for k in 3:
			var angle:=k*2.4+j
			var point:=Vector3(cos(angle)*.56,1.73+k*.16,sin(angle)*.55)
			a.beam(orchard,Vector3.UP*1.15,point,.08,"#806242")
			var crown:=a.ball(orchard,point,Vector3(1.66,1.36,1.55),"#719363" if k%2 else "#829c66",true);planted.append(crown)
			var citrus:=a.ball(orchard,point+Vector3(.21,-.15,-.60),Vector3.ONE*.26,"#e8a344",true);planted.append(citrus)
	var shed:=a.group(self,g.land.surface(g.WIND_DOCK+Vector2(-2.3,2.85)))
	a.box(shed,Vector3.UP*.44,Vector3(1.65,.88,.87),"#977759")
	loading_part=a.group(shed,Vector3(0,.91,0));make_pin(loading_part)
	potter=a.courier(shed);potter.position=Vector3(-1.28,0,-.04)
	preload("res://zephyr_people.gd").new().costume(potter,"miller")
	stop_labels.append(cove.label(shed,Vector3(-.1,2.14,0),"渠匠 · 等轮毂"))
	var spring:=a.group(self,g.land.surface(HEAD+Vector2(0,5.4)))
	for j in 7:
		var arch:=dock.arch(spring,Vector3((j-3)*4.1,-.28-j*.07,0),1.78,2.08,.95)
		a.box(arch,Vector3(0,4.38,0),Vector3(4.12,.28,1.18),"#b79c72")
		for side in [-1,1]:a.box(arch,Vector3(0,4.66,side*.52),Vector3(4.11,.36,.16),"#d1b88b")
		var stream:=a.box(arch,Vector3(0,4.52,0),Vector3(4.1,.10,.88),"#55baba");water.append(stream)
	wheel=a.group(spring,Vector3(.3,2.35,-1.18))
	a.ring(wheel,Vector3.ZERO,2.04,.14,"#806449").rotation.x=PI/2
	for j in 12:
		var spoke:=a.group(wheel);spoke.rotation.z=j*TAU/12
		a.box(spoke,Vector3.UP*.98,Vector3(.09,1.98,.15),"#b08b5b")
		a.box(spoke,Vector3.UP*1.94,Vector3(.66,.16,.66),"#907355")
	var hub:=a.cyl(wheel,Vector3.ZERO,.31,.31,.68,"#b9a068");hub.rotation.x=PI/2
	axle=a.group(spring,Vector3(.3,2.35,-1.67));make_pin(axle)
	for j in 8:
		var r:=a.ball(spring,Vector3(.24,3.95-j*.49,-1.08),Vector3(.22+j*.05,.65,.19),"#78cbbc",true);water.append(r)
	add_child(cove);cove.setup(g,spring)
	add_child(speaker);speaker.stream=preload("res://audio/spring_flow.wav");speaker.position=wheel.global_position;speaker.max_distance=24.;speaker.unit_size=7.;speaker.volume_db=-14.
	var cistern:=a.group(self,g.land.surface(GARDEN+Vector2(5.2,6.7)))
	a.box(cistern,Vector3(0,-.23,.50),Vector3(8.5,.52,5.2),"#cfad87")
	for side in [-1.,1.]:
		a.box(cistern,Vector3(side*4.05,.20,.3),Vector3(.4,.52,4.75),"#bea180")
		a.cyl(cistern,Vector3(side*4.04,.59,-1.38),.34,.39,.66,"#bf835d")
		a.prop(cistern,"garden/plant_bushDetailed",Vector3(side*4.04,.87,-1.38),.72,.3)
	stop_labels.append(cove.label(spring,Vector3(0,5.42,0),"渠首水轮"))
	stop_labels.append(cove.label(cistern,Vector3(.0,2.75,.10),"月桂园蓄水池"))
	for k in 10:
		var blossom:=a.prop(cistern,"garden/flower_yellowB" if k%3 else "garden/flower_purpleA",Vector3(-3.36+k*.74,.18,2.38),.50+.08*(k%3),k*.78)
		flowers.append(blossom)
	var pool:=a.cyl(cistern,Vector3.UP*.23,1.87,1.93,.47,"#cfaa80",32)
	a.ring(pool,Vector3.UP*.29,1.88,.12,"#efd6ab")
	water.append(a.cyl(cistern,Vector3.UP*.48,1.76,1.76,.045,"#64b8b2",32))
	for j in 4:
		var at:=Vector3((j-1.5)*2.12,0,2.3)
		a.box(cistern,at,Vector3(2.11,.4,1.06),"#ad865e")
		var foliage:=a.group(cistern,at+Vector3.UP*.2);craft.plant(foliage,Vector3.ZERO,4+j,true);flowers.append(foliage)
	visitor=a.courier(cistern);visitor.position=Vector3(2.4,0,-.66)
	preload("res://zephyr_people.gd").new().costume(visitor,"baker")
	garden_worker=a.courier(cistern);garden_worker.position=Vector3(-2.55,.1,-.48)
	preload("res://zephyr_people.gd").new().costume(garden_worker,"priest")
	a.jar(garden_worker,Vector3(.35,.85,.24),.37,"#b87750")
	a.jar(cistern,Vector3(2.68,0,-1.4),.65,"#bd7751")
	citrus=fruit_bin(g.truck,Vector3(-1.12,1.12,0))
	shroud=a.group(citrus,Vector3(0,.56,-.27))
	for j in 6:
		a.box(shroud,Vector3((j-2.5)*.23,0,0),Vector3(.24,.054,.53),"#61959a" if j%2 else "#d5c99f")
	juice_stall=a.group(self,g.land.surface(g.WIND_DOCK+Vector2(2.4,-1.42)))
	a.box(juice_stall,Vector3.UP*.68,Vector3(2.8,1.35,.93),"#7c9e8b")
	craft.cloth(juice_stall,Vector3(0,3.0,-.55),3.2,"#c47e46")
	for x in [-1.4,1.4]:a.beam(juice_stall,Vector3(x,0,-.45),Vector3(x,3,-.45),.065,"#825f47")
	fruit_bin(juice_stall,Vector3(0,1.38,0))
	var merchant:=a.courier(juice_stall);merchant.position=Vector3(-1.72,0,0)
	preload("res://zephyr_people.gd").new().costume(merchant,"baker")
	craft.barrel(juice_stall,Vector3(1.49,0,.18),.76)
	cove.tile(juice_stall,Vector3(.0,.68,.56),.79,0.)
	cart_part=a.group(g.truck,Vector3(-1.0,1.23,0));make_pin(cart_part)
	rotor=a.group(cistern,Vector3(0,.62,0))
	for j in 8:
		var angle:=j*TAU/8
		var last:=Vector3.UP*1.25
		for k in range(1,7):
			var u:=k/6.;var tip:=Vector3(cos(angle)*u*1.25,1.25+.95*u-2.32*u*u,sin(angle)*u*1.25)
			a.beam(rotor,last,tip,.034,"#afe8d9");last=tip
	a.column(cistern,Vector3.ZERO,1.6)
	refresh()

func make_pin(n:Node3D)->void:
	a.ring(n,Vector3.UP*.48,.51,.12,"#c49653").rotation.x=PI/2
	for i in 8:
		var bar:=a.group(n,Vector3.UP*.48);bar.rotation.z=i*PI/4
		a.box(bar,Vector3.UP*.27,Vector3(.10,.54,.13),"#c89b55")
	a.beam(n,Vector3(0,.48,-.38),Vector3(0,.48,.38),.12,"#71968b")

func refresh()->void:
	for canopy in planted:canopy.visible=step>=4
	owner_game.land.spring_bridge=step>=4 and bridge_open>.99
	shroud.visible=wrapped
	citrus.visible=active and picked
	for j in fruit_meshes.size():fruit_meshes[j].visible=j<intact
	juice_stall.visible=port_trade>0
	loading_part.visible=step==0;axle.visible=step>=2;cart_part.visible=step==1 and active
	for item in water:item.visible=step>=3
	for item in flowers:item.visible=step>=4
	rotor.visible=step>=4

func begin()->void:
	if owner_game.stage not in ["signed","pickup"] or is_instance_valid(owner_game.porter):return
	previous_pos=owner_game.pos;previous_yaw=owner_game.heading;previous_speed=owner_game.speed
	impact_count=owner_game.bumps
	active=true;owner_game.board.hide();owner_game.receipt.hide()
	var at:Vector2=owner_game.WIND_DOCK if step<2 else (HEAD if step==2 else GARDEN)
	owner_game.pos=at-Vector2(2,0) if road_point==Vector2.ZERO else road_point
	owner_game.heading=PI if road_point==Vector2.ZERO else road_yaw;owner_game.camera_yaw=owner_game.heading
	checkpoint=owner_game.pos;last_pos=checkpoint
	owner_game.speed=0;owner_game.altitude=owner_game.land.ground(owner_game.pos)
	refresh();owner_game.update_pose(1.)

func advance()->void:
	step+=1;stamp();refresh();owner_game.audio.play_cue("win" if step==4 else "load")

func use()->void:
	if transfer>0. or testing:return
	if owner_game.pos.distance_to(cove.WELL)<6. and absf(owner_game.speed)<1.6:
		discovered=true;admire=3.1
		if picked:
			wrapped=true;heat=0.;board_note="泉女把湿布盖上果筐 · 山脊热风也能保鲜"
		else:board_note="泉女：「看渠首浮子。进了绿色石纹，泉水才走得远。」"
		note_time=4.;stamp();refresh();owner_game.audio.play_cue("page");return
	if absf(owner_game.speed)>1.6:return
	match step:
		0:
			if owner_game.pos.distance_to(owner_game.WIND_DOCK)<7.:advance();board_note="渠匠：「送到连拱水轮，果园就有救了。」";note_time=3.2
		1:
			if owner_game.pos.distance_to(HEAD)<6.:
				cargo_start=cart_part.global_position;advance()
				inspection=2.6;transfer=1.6;axle.hide();cart_part.show();owner_game.speed=0.
		2:
			if owner_game.pos.distance_to(HEAD)<6.:inspection=0.;testing=true;owner_game.speed=0
		3:
			if owner_game.pos.distance_to(GARDEN)<6.:
				owner_game.wind_wallet+=24;ceremony=4.2;advance()
		4:
			if not picked and owner_game.pos.distance_to(GARDEN)<6.:
				picked=true;wrapped=false;heat=0.;intact=6;impact_count=owner_game.bumps;refresh();stamp();owner_game.audio.play_cue("grab")
			elif picked:
				var port:bool=owner_game.pos.distance_to(owner_game.WIND_DOCK)<6.
				var inn:bool=owner_game.pos.distance_to(owner_game.Map.LODGE)<6.
				if not (port or inn):return
				var pay:=(12+intact*2+(4 if owner_game.north_beacon else 0)) if port else 5+intact
				if port:port_trade+=1;night_stock=true
				else:local_trade+=1
				if wrapped and port:pay+=3
				income+=pay;baskets+=1;owner_game.wind_wallet+=pay;picked=false
				board_note=("海港果摊首次开张" if port and port_trade==1 else "鲜果已签收")+"　+%d 枚"%pay
				note_time=4.;owner_game.audio.play_cue("win");refresh();stamp()

func turn_cart()->void:
	if step!=4 or not active or turnaround>0. or absf(owner_game.speed)>1. or owner_game.pos.distance_to(GARDEN)>6.:return
	for i in 13:
		if not owner_game.clear_for(owner_game.pos,owner_game.heading+PI*i/12.):
			board_note="车尾离树太近 · 向泉台前的空地挪一点";note_time=2.8;return
	turn_from=owner_game.heading;turnaround=1.25;owner_game.speed=0.
	owner_game.audio.play_cue("load")

func tick(dt:float)->void:
	elapsed+=dt
	shower.tick(dt,owner_game,active)
	bridge_open=move_toward(bridge_open,1. if step>=4 else 0.,dt*.5)
	for j in leaves.size():leaves[j].rotation.z=(1. if j==0 else -1.)*(1.-smoothstep(0.,1.,bridge_open))*1.08
	owner_game.land.spring_bridge=step>=4 and bridge_open>.99
	if step>=3:wheel.rotation.z-=dt*.65
	if step>=4:rotor.rotation.y+=dt*.12
	cove.tick(elapsed,pressure,opening,step,testing)
	if (testing or step>=3) and not speaker.playing:speaker.play()
	speaker.pitch_scale=.80+.48*pressure if testing else 1.
	for j in stop_labels.size():stop_labels[j].visible=active and ((j==0 and step==0) or (j==1 and step in [1,2]) or (j==2 and step>=3))
	garden_worker.get_node("ArmR").rotation.x=-.54+.15*sin(elapsed*1.7)
	if not active:return
	var g=owner_game
	if chart.visible:chart.queue_redraw();return
	if turnaround>0.:
		turnaround=maxf(0.,turnaround-dt);g.heading=turn_from+PI*smoothstep(0.,1.25,1.25-turnaround)
		if turnaround<=0.:stamp()
	var distance:=last_pos.distance_to(g.pos);last_pos=g.pos
	if picked and not wrapped and g.pos.x>48. and g.pos.x<133. and distance<2.:
		var shaded:bool=g.pos.y>17.
		heat=clampf(heat+distance*(-.035 if shower.wetness>.28 else (-.028 if shaded else .019)),0.,1.)
		if heat>=1. and intact>0:
			heat=.33;intact-=1;board_note="热风晒软一筐 · 走海湾背阴的小路能给果子降温";note_time=3.;refresh();stamp()
	if transfer>0.:
		transfer=maxf(0.,transfer-dt)
		var u:=1.-transfer/1.6
		cart_part.global_position=cargo_start.lerp(axle.global_position,smoothstep(0.,1.,u))+Vector3.UP*sin(u*PI)*1.5
		if transfer<=0.:
			cart_part.position=Vector3(-1.,1.23,0);refresh()

	if g.pos.distance_to(checkpoint)>10.:stamp()
	if picked and g.bumps>impact_count:
		intact=maxi(0,intact-1);board_note="鲜果受碰 · 余下 %d 筐完好"%intact;note_time=2.2;refresh();stamp()
	impact_count=g.bumps
	note_time=maxf(0.,note_time-dt)
	g.day_button.hide();g.night_button.hide();g.book_button.hide();g.info.show()
	if testing:
		var hand:=float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))
		opening=clampf(opening+hand*dt*.58,0.,1.)
		pressure=opening+.11*sin(elapsed*1.75)
		charge=clampf(charge+dt*(1. if pressure>=.46 and pressure<=.72 else -.60),0.,2.4)
		wheel.rotation.z-=dt*opening*2.8
		if charge>=2.39:testing=false;advance()
	g.title.text="泉神的旱季　/　西湾引水"
	var target:Vector2=g.WIND_DOCK if step==0 else (HEAD if step<=2 else GARDEN)
	var dist:=roundi(g.pos.distance_to(target))
	g.info.text=["月桂园断水了。去蓝棚接渠匠的轮毂。","送到山道上的高架水轮","给主渠通水","赶去月桂园放水","月桂园重新开泉 · 公共运费 24 枚"][step]+"　%d 米"%dist
	g.controls.text="W/S 驾车　 A/D 转向　 E 停稳作业　 Tab 引水图　 Esc 暂离"
	g.port_caption.show()
	if testing:
		g.port_caption.text="A 收闸　D 开闸　　 水压 %d　·　绿色区间 46–72　　 稳流 %d%%"%[roundi(pressure*100),roundi(charge/2.4*100)]
		var focus:=wheel.global_position
		g.cam.position=focus+Vector3(2.5,3.5,-8.2);g.cam.look_at(focus)
	else:
		g.port_caption.text=["E 接走轮毂","E 安装青铜轮毂","E 接手闸轮","E 打开园闸","E 返回委托簿"][step] if dist<=6 else ["回蓝棚码头找渠匠","向西过河，循陶画找渠首连拱","回到连拱下的水轮","沿路向西，寻找月桂园石泉",""][step]
		if dist<=6 and absf(g.speed)>1.6:g.port_caption.text="先把车停稳，再下车作业。"

	if step==4:
		g.info.text="月桂园果运　·　已送 %d 篮　收入 %d 枚"%[baskets,income]
		if picked:
			var port_dist:=roundi(g.pos.distance_to(g.WIND_DOCK))
			var inn_dist:=roundi(g.pos.distance_to(g.Map.LODGE))
			g.port_caption.text="客舍 %d 米 · 近途　　海港 %d 米 · 高价，升桥已落下"%[inn_dist,port_dist]
			if minf(g.pos.distance_to(g.WIND_DOCK),g.pos.distance_to(g.Map.LODGE))<6.:g.port_caption.text="E 卸下鲜果　·　完好果筐 %d / 6"%intact if absf(g.speed)<=1.6 else "果摊到了，刹住车再卸货。"
		else:g.port_caption.text="E 装月桂园鲜果　·　可送客舍或海港" if g.pos.distance_to(GARDEN)<6. else "返回月桂园装下一篮　 Esc 回委托簿"
		if note_time>0.:g.port_caption.text=board_note
		if ceremony>0.:
			ceremony=maxf(0.,ceremony-dt)
			var focus:=rotor.global_position+Vector3.UP*.65
			var offset:=Vector3(5.8,4.9,-5.0)
			var pose:=Transform3D(Basis.looking_at(-offset,Vector3.UP),focus+offset)
			var blend:=smoothstep(0.,.8,ceremony)*(1.-smoothstep(3.1,4.2,ceremony))
			g.cam.transform=g.cam.transform.interpolate_with(pose,blend)
			g.port_caption.text="泉神还水 · 果园复苏，西湾水桥落下　+24 枚"

	if picked and active:
		g.info.text+="　·　"+("泉水湿布" if wrapped else ("暑气渐重" if heat>.65 else "鲜果完好 %d/6"%intact))
	if active and g.pos.distance_to(cove.WELL)<6.:
		g.port_caption.text="E 借泉水浸湿护果布" if picked else "E 拜访海湾泉眼"
	if note_time>0.:g.port_caption.text=board_note
	if transfer>0.:g.port_caption.text="渠匠正在把轮毂送上水轴"

	if picked and g.pos.distance_to(GARDEN)<6. and ceremony<=0. and note_time<=0.:g.port_caption.text="Q 请园工调头　·　客舍在西，果港在东"

	if active and not testing and inspection<=0. and g.pos.distance_to(HEAD)<10. and absf(g.speed)<1.8:
		var weight:float=1.-smoothstep(4.,10.,g.pos.distance_to(HEAD))
		var center:Vector3=wheel.global_position.lerp(g.truck.global_position+Vector3.UP*.8,.53)
		var eye:=Vector3(-4.8,8.4,-7.7)
		g.cam.transform=g.cam.transform.interpolate_with(Transform3D(Basis.looking_at(-eye,Vector3.UP),center+eye),weight)
	if inspection>0.:
		inspection=maxf(0.,inspection-dt)
		var center:Vector3=wheel.global_position.lerp(g.truck.global_position+Vector3.UP,.48)
		var eye:=Vector3(-4.8,8.4,-7.7)
		g.cam.transform=Transform3D(Basis.looking_at(-eye,Vector3.UP),center+eye)
	if admire>0.:
		admire=maxf(0.,admire-dt)
		var eye:=Vector3(-5.6,4.6,-7.8)
		var target3:=cove.grotto.global_position+Vector3.UP*1.6
		var blend:=smoothstep(0.,.7,admire)*(1.-smoothstep(2.4,3.1,admire))
		g.cam.transform=g.cam.transform.interpolate_with(Transform3D(Basis.looking_at(-eye,Vector3.UP),target3+eye),blend)

	if picked and shower.wetness>.3 and note_time<=0. and g.pos.distance_to(cove.WELL)>6. and g.pos.distance_to(GARDEN)>6. and g.pos.distance_to(g.Map.LODGE)>6. and g.pos.distance_to(g.WIND_DOCK)>6.:g.port_caption.text="海雨替果筐降温 · 湿石缓转，出口看红白风袋"

	if active and not picked and night_stock and g.pos.distance_to(g.WIND_DOCK)<6. and note_time<=0.:
		g.port_caption.text="Q 随夜船把窑工订的果箱送去双灯窑　·　捎货 +6 枚"

func night_depart()->bool:
	if not night_stock or picked or owner_game.pos.distance_to(owner_game.WIND_DOCK)>6. or absf(owner_game.speed)>1.6:return false
	leave();owner_game.open_tide_dock(true,true);return true

func kiln_signed()->void:
	if not night_stock:return
	night_stock=false;night_sales+=1;income+=6
	owner_game.wind_wallet+=6;owner_game.file_postmarks()
