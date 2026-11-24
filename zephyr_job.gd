extends Node3D

signal left_dock(pay:int)
signal rent_requested
signal order_signed(result:int,pay:int,remaining:int,route:String)
const Catch:=preload("res://cargo_catch.gd")
const Art=preload("res://workshop.gd")
const Bay=preload("res://tide_art.gd")
const Terrain=preload("res://zephyr_land.gd")
const Wind=preload("res://zephyr_weather.gd")
const Porter=preload("res://bay_porter.gd")
const Crane=preload("res://quay_crane.gd")
const FontBook=preload("res://harbour_fonts.gd")
const START_BAG:=Terrain.BANK+Vector2(-10.30,-.72)
const HOOD_COST:=12
const BURST_COST:=40.0
const FULL_ENOUGH:=80
var art:=Art.new()
var design:=Bay.new()
var land:=Terrain.new()
var audio=preload("res://sound.gd").new()
var wear:=preload("res://cargo_wear.gd").new()
var cam:=Camera3D.new()
var truck:Node3D
var freight:Node3D
var skin:Node3D
var cord:Node3D
var hood:Node3D
var vanes:Array[Node3D]=[]
var notes:Array[Node3D]=[]
var wisps:Array[Node3D]=[]
var wheels:Array[Node3D]=[]
var porter:Node3D
var crane:Node3D
var wind_job:=true
var returning:=false
var wallet:=0
var prior_level:=0
var season:=0
var bakery_moved:=false
var previous_receipt:=""
var bell_returned:=false
var chime_taken:=false
var bell_bonus:=0
var visit_archive:=false
var tracks:=preload("res://zephyr_wheels.gd").new()
var surface_id:=0
var route_meters:=0.
var sail_crossed:=false
var charter_branch:=false
var blessing:=false
var branch_spent:=false
var branch_mesh:Node3D
var shelter_read:=false
var route_events:=preload("res://zephyr_route.gd").new()
var bell_audio:=AudioStreamPlayer.new()
var cab_bell:Node3D
var mixer_clock:=0.
var frame_of_mind:=0.
var rented:=false
var stage:="offer"
var pos:=Terrain.BANK
var heading:=0.0
var speed:=0.0
var altitude:=0.0
var vy:=0.0
var airborne:=false
var burst_used:=false
var air_start:=0.0
var pitch:=0.0
var roll:=0.0
var cargo_shift:=0.0
var correction:=0.0
var brace_distance:=0.0
var rail_contact:=false
var charge:=24.0
var health:=100.0
var time:=0.0
var drive_time:=0.0
var phase_time:=0.0
var cooldown:=0.0
var current_gain:=0.0
var collector_x:=[3.0,54.0]
var released:=0
var lost_valley:=false
var stone_lane:=false
var bridge_cleared:=false
var crossing:=false
var cart_hits:=0
var safely_passed:=false
var voluntary_low:=false
var talk_step:=0
var notify_text:=""
var notify_time:=0.0
var signed_level:=0
var gross:=0
var rate_tip:=0
var pad_tip:=0
var decline:=0
var assessed:=false
var approach:=Vector2.ZERO
var loaded_from:=Vector3.ZERO
var posed:=false
var view_heading:=0.0
var camera_focus:=Vector3.ZERO
var bay_font:=FontBook.body()
var bag_tag:=Label.new()
var title:=Label.new()
var objective:=Label.new()
var action:=Label.new()
var guide:=Label.new()
var statement:=Label.new()
var seal:=Label.new()
var punch:=0.0
var source_spout:Node3D
var hear_wind:=AudioStreamPlayer.new()
var breath:=AudioStreamPlayer.new()
var mill_song:=AudioStreamPlayer.new()
var sun:=DirectionalLight3D.new()
var eye_env:=Environment.new()
var sky:=ProceduralSkyMaterial.new()
var visit_pos:=Vector2.ZERO
var chart:=preload("res://zephyr_chart.gd").new()
var compass:Node3D
var needle:Node3D
var compass_dest:=Terrain.MILL_PORT
var compass_title:=""
var ticket:=preload("res://zephyr_ticket.gd").new()
var visitor:Node3D
var passenger:Node3D
var catch_window:=0.
var slide_side:=0.
var shoe_buckle:Node3D
var cargo_visual:=0.
var balance:=Control.new()
var walked_bakery:=false

func _ready()->void:
	time=fposmod(season*2.37,Wind.PERIOD)
	add_child(land);add_child(audio);add_child(cam);cam.current=true;cam.fov=54
	eye_env.background_mode=Environment.BG_SKY
	sky.sky_top_color=Color("#5493bb");sky.sky_horizon_color=Color("#c7d5cf");sky.ground_horizon_color=Color("#a9c4bd")
	eye_env.sky=Sky.new();eye_env.sky.sky_material=sky
	eye_env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;eye_env.ambient_light_color=Color("#d1d8cd");eye_env.ambient_light_energy=.50
	eye_env.fog_enabled=true;eye_env.fog_density=.0037;eye_env.fog_light_color=Color("#8da9ae")
	eye_env.ssao_enabled=true;eye_env.ssao_radius=1.25;eye_env.ssao_intensity=1.5
	eye_env.tonemap_mode=Environment.TONE_MAPPER_ACES;eye_env.tonemap_exposure=.91;cam.environment=eye_env
	sun.rotation_degrees=Vector3(-37,-47,0);sun.light_color=Color("#ffe5c3");sun.light_energy=.95;sun.shadow_enabled=true;sun.directional_shadow_max_distance=88;add_child(sun)
	truck=art.truck(self);freight=art.group(self,land.surface(START_BAG)+Vector3.UP*.10)
	skin=art.sack(freight)
	build_rig();tracks.build(self)
	compass=art.group(truck,Vector3(.64,2.89,0))
	var tray:=art.cyl(compass,Vector3.ZERO,.25,.30,.09,"#947446",16)
	art.cyl(compass,Vector3.UP*.058,.249,.249,.025,"#456563",16)
	art.ring(compass,Vector3.UP*.081,.261,.029,"#d2b37e")
	needle=art.group(compass,Vector3.UP*.107)
	var pointer:=art.ball(needle,Vector3(.16,0,0),Vector3(.38,.044,.10),"#efcb85",true)
	art.ball(needle,Vector3(-.10,0,0),Vector3(.22,.042,.07),"#c7775b",true)
	passenger=art.courier(truck);land.people.costume(passenger,"miller")
	passenger.position=Vector3(1.84,1.27,-.52);passenger.scale=Vector3.ONE*.61;passenger.rotation.y=1.25
	passenger.get_node("ArmL").rotation.x=-.82;passenger.get_node("ArmR").rotation.x=-.65;passenger.hide()
	land.miller.visible=prior_level>0
	shoe_buckle=art.group(truck)
	art.ring(shoe_buckle,Vector3.ZERO,.18,.042,Bay.BRASS).rotation.x=PI/2;shoe_buckle.hide()
	branch_mesh=art.group(freight,Vector3(.0,.85,-.50))
	for j in 7:
		var leaf:=art.ball(branch_mesh,Vector3((j-3)*.085,.05*sin(j*.6),0),Vector3(.18,.07,.06),"#a9c48c",true)
		leaf.rotation.z=(.48 if j%2 else -.42)
	branch_mesh.visible=charter_branch;blessing=charter_branch
	add_child(route_events);route_events.build(land)
	cab_bell=preload("res://zephyr_route.gd").bell_shape(truck);cab_bell.position=Vector3(-2.45,1.86,.79);cab_bell.scale=Vector3.ONE*.58;cab_bell.visible=bell_returned
	for voice:AudioStreamPlayer in [hear_wind,breath,mill_song,bell_audio]:add_child(voice)
	var wind_bed:=preload("res://audio/zephyr_grove.wav").duplicate() as AudioStreamWAV
	wind_bed.loop_mode=AudioStreamWAV.LOOP_FORWARD;wind_bed.loop_end=roundi(wind_bed.get_length()*wind_bed.mix_rate)
	hear_wind.stream=wind_bed;hear_wind.volume_db=-24;hear_wind.play()
	breath.stream=preload("res://audio/zephyr_release.wav");breath.volume_db=-8
	bell_audio.stream=preload("res://audio/zephyr_chime.wav");bell_audio.volume_db=-8
	mill_song.volume_db=-5
	for n:Node3D in get_tree().get_nodes_in_group("wheels"):
		if truck.is_ancestor_of(n):wheels.append(n)
	land.label(land.apprentice,Vector3.UP*2.15,"磨坊主　米拉",.009)
	land.label(land.miller,Vector3.UP*2.3,"磨坊主　米拉",.008)
	land.label(land.people.baker,Vector3.UP*2.36,"面包师　伊娅",.008)
	land.label(land,land.surface(Vector2(29,-6.4))+Vector3.UP*2.4,"风过时 · 当心溜车",.010)
	land.label(land,land.surface(Vector2(47,-5.15))+Vector3.UP*3.0,"石巷 ←　　 断桥 →",.012)
	land.label(land,land.surface(Vector2(64,18.1))+Vector3.UP*3.2,"旧磨沟　·　回流采风",.012)
	land.label(land,land.surface(Vector2(15,5.2))+Vector3.UP*2.04,"西风廊　·　行驶纳风",.012)
	if bakery_moved:
		land.people.baker.hide();land.people.oven.hide();land.people.bread_tray.hide()
		land.label(land.bake_root,Vector3(-2.28,2.15,.3),"伊娅已经搬到潮汐船坞",.009)
	land.apply_result(prior_level,true)
	build_interface();audio.set_scene("yard")
	altitude=land.ground(pos);update_truck(0,0);draw_camera(1);update_cargo(0);update_ui()
func build_rig()->void:
	cord=art.group(freight)
	for side in [-1,1]:
		var pivot:=art.group(cord,Vector3(.08,1.18,side*.18))
		var tail:=art.box(pivot,Vector3(-.32,-.07,0),Vector3(.72,.105,.09),Bay.BLUE)
		tail.rotation.z=.12
		vanes.append(pivot)
	hood=art.group(freight,Vector3(.02,.97,-.37))
	var tube:=art.cyl(hood,Vector3.ZERO,.22,.41,.55,Bay.BRASS,12);tube.rotation.x=PI/2
	var rim:=art.ring(hood,Vector3(0,0,-.28),.40,.045,Bay.INK);rim.rotation.x=PI/2
	hood.hide()
	for i in 12:
		var n:=art.ball(self,Vector3.ZERO,Vector3(.66,.055,.12),"#e9d7a4",true);n.hide();wisps.append(n)
	for i in 4:
		var n:=art.ring(self,Vector3.ZERO,.45,.032,Bay.SIGNAL);n.rotation.x=PI/2;n.hide();notes.append(n)
func label_style(l:Label,size:int,tint:String,bg:String)->void:
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font",bay_font);l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color(tint))
	var style:=StyleBoxFlat.new();style.bg_color=Color(bg);style.set_corner_radius_all(7)
	style.content_margin_left=13;style.content_margin_right=13;style.content_margin_top=6;style.content_margin_bottom=6
	l.add_theme_stylebox_override("normal",style)
func build_interface()->void:
	var layer:=CanvasLayer.new();add_child(layer)
	for l in [title,objective,guide,action,statement,bag_tag,seal]:layer.add_child(l);label_style(l,17,"#f8edcf","#1e3942ed")
	layer.add_child(ticket);layer.add_child(chart);chart.pinned.connect(mark_map);layer.add_child(balance);balance.size=Vector2(103,9);balance.mouse_filter=Control.MOUSE_FILTER_IGNORE;balance.draw.connect(draw_balance);balance.hide()
	title.add_theme_font_size_override("font_size",23);title.position=Vector2(24,20);objective.position=Vector2(24,69)
	guide.position=Vector2(24,653)
	action.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	statement.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;statement.position=Vector2(345,124);statement.custom_minimum_size.x=590;statement.hide()
	seal.position=Vector2(1024,20);seal.add_theme_font_size_override("font_size",16)
	bag_tag.add_theme_font_size_override("font_size",15)
func wind_units()->int:return floori(clampf(charge+.00001,0.,100.))
func mark_map(p:Vector2,caption:String)->void:
	compass_dest=p;compass_title=caption;audio.play_cue("page")
func draw_balance()->void:
	var span:=balance.size.x
	balance.draw_rect(Rect2(0,1,span,7),Color("#233e40"))
	for band:Array in [[0.,.20,"#b7775a"],[.20,.60,"#72978a"],[.80,.20,"#b7775a"]]:
		balance.draw_rect(Rect2(span*float(band[0])+1,3,span*float(band[1])-2,3),Color(band[2]))
	var x:=span*(.5+.49*cargo_shift/.68)
	balance.draw_rect(Rect2(x-1.9,0,3.8,9),Color("#ffdf98"))

func tell(words:String,seconds:=2.2)->void:notify_text=words;notify_time=seconds
func enter(next:String)->void:stage=next;phase_time=0
func forward_dir()->Vector2:return Vector2(cos(heading),-sin(heading))
func set_rented(accepted:bool,available:int)->void:
	wallet=available
	if not accepted:tell("导风罩租金 12 枚 · 普通风囊也可接单");audio.play_cue("warn");return
	rented=true;hood.show();tell("已装导风罩 · 斜着驶过风口也能采风");audio.play_cue("buckle")
func begin_load()->void:
	visit_archive=false
	land.apply_result(0,true)
	porter=Porter.new();add_child(porter);porter.begin(self,true,Vector2.ZERO);enter("load")
	tell("米拉：「我摇了一早，才吊起一袋麦。伊娅还留着炉火。」",3.6)
func do_use()->void:
	match stage:
		"offer":begin_load()
		"load":
			if porter.use():
				loaded_from=freight.global_position;porter.queue_free();porter=null;enter("strap");audio.play_cue("load")
		"drive":
			if pos.distance_to(Terrain.MILL_PORT)<6.8:
				if absf(speed)>1.9 or airborne:tell("减速停在金圈旁，再交接风囊");return
				speed=0;land.miller.show();passenger.hide();enter("crane");crane=Crane.new();crane.local_weather=winch_wind;add_child(crane);crane.begin(self,Terrain.PAD);audio.set_scene("yard");audio.play_cue("page")
			elif pos.distance_to(Terrain.BANK+Vector2(25.5,-1.4))<5.4 and absf(speed)<2.3:
				tell("祭司：「泽费罗斯带回春天。摘一枝吧，愿它替风囊挡一次磕碰。」",3.6);audio.play_cue("page")
			elif pos.distance_to(Vector2(65,16.1))<5.4 and absf(speed)<2.3:
				tell("旧磨坊刻字：「向海留一道口，低处也有顺风。」",3.0);audio.play_cue("page")
			else:tell("把风囊送到坡顶大风车的金色进风座",1.35)
		"visit":
			if visit_pos.distance_to(Vector2(land.miller.global_position.x,land.miller.global_position.z))<3.3:
				tell("米拉：「麦子开始走了，你听。」" if signed_level==1 else "米拉：「把窗推开！这一阵够整条街。」",3.4);audio.play_cue("page")
			elif visit_pos.distance_to(Vector2(land.people.baker.global_position.x,land.people.baker.global_position.z))<4.3:
				if bakery_moved:tell("门上的字条：「面粉请送蓝棚。——伊娅」",3.2);return
				walked_bakery=true;tell("面包师伊娅：「第一炉，给送风的人留着。」" if signed_level==2 else "伊娅：「粮吊起来了，下一阵风再开炉。」",3.2);audio.play_cue("page")
			else:tell("靠近磨坊主或蓝窗面包房可以交谈")
		"signed":left_dock.emit(gross)
		"broken":retry_from_bank()
func jump()->void:
	if stage!="drive":return
	if not airborne:
		airborne=true;vy=4.85;air_start=altitude;burst_used=false;audio.play_cue("land");return
	if burst_used:return
	if charge<BURST_COST:tell("风囊太瘪 · 谷底还有一道采风廊");return
	charge-=BURST_COST;released+=1;burst_used=true;punch=1.0
	vy=maxf(vy,1.55)+5.35;speed=minf(16.5,maxf(8.3,speed)+2.25)
	land.pulse(pos);audio.play_cue("wind")
	if breath.stream!=null:breath.play()
	tell("借西风　−40　·　树叶翻银",1.2)
func _input(e:InputEvent)->void:
	if chart.visible or stage!="drive" or not e is InputEventMouseButton:return
	if e.button_index==MOUSE_BUTTON_LEFT and e.pressed and catch_window>0:
		correction=Catch.DURATION;catch_window=0.;audio.play_cue("grab")
func _unhandled_key_input(e:InputEvent)->void:
	if not e is InputEventKey or not e.pressed or e.echo:return
	if chart.visible:
		if e.keycode in [KEY_M,KEY_ESCAPE]:chart.hide()
		get_viewport().set_input_as_handled();return
	match e.keycode:
		KEY_M:
			if stage in ["offer","load","drive"]:chart.open(self);audio.play_cue("page")
		KEY_E:do_use()
		KEY_B:
			if stage=="offer" and not rented:rent_requested.emit()
		KEY_Q:
			if stage=="load" and is_instance_valid(porter):porter.rotate_load()
			elif stage=="offer":
				talk_step=(talk_step+1)%3;tell(["米拉：「前一车麦还在等。走石巷，就能把风多留给炉子。」","伊娅的纸条：满八成就能开炉，余风每两成多付五枚。","泽费罗斯封记：半空再拍一下袋口，可把风借给车轮。"][talk_step],3.6)
		KEY_SPACE:
			if stage=="crane":crane.release()
			else:jump()
		KEY_TAB:
			if stage=="signed":ticket.hide();visit_archive=false;begin_visit()
			elif stage=="offer" and prior_level>0:
				visit_archive=true;signed_level=prior_level;begin_visit()
			elif stage=="visit":
				visitor.hide()
				if visit_archive:enter("offer");visit_archive=false;signed_level=0
				else:ticket.set_receipt(self);enter("signed")
		KEY_R:
			if stage=="broken":retry_from_bank()
		KEY_ESCAPE:
			left_dock.emit(gross if assessed else 0)
	get_viewport().set_input_as_handled()

func winch_wind(axis:Vector3,pad:Vector3)->Vector3:
	var place:=Vector2(pad.x,pad.z)
	var phase:=fposmod(time-place.dot(Wind.FLOW)/10.,Wind.PERIOD)
	var force:=Vector2(axis.x,axis.z).dot(Wind.FLOW)*6.15
	var pressure:=Wind.pressure(place,time)
	var wait_time:=0. if pressure>.10 else (Wind.PERIOD-phase+.22 if phase>4.8 else .22-phase)
	return Vector3(force*pressure,wait_time,force)

func clear(p:Vector2)->bool:
	var side:=forward_dir().orthogonal()
	for x in [-2.34,0.,2.23]:
		for z in [-1.02,0.,1.02]:
			if not land.valid(p+forward_dir()*float(x)+side*float(z)):return false
	return true
func hurt(amount:float,reason:String)->void:
	if cooldown>0 or amount<=0:return
	if blessing and amount>4.:
		blessing=false;branch_spent=true;branch_mesh.hide();amount=maxf(0.,amount-9.);bell_audio.play()
		reason="丰收枝护住风囊 · "+reason
	cooldown=1.25;health=maxf(0,health-amount);audio.play_cue("bonk");tell(reason+" · 囊体 −%d"%roundi(amount),1.8)
	if health<30:enter("broken");speed=0;statement.show();statement.text="风囊破裂，米拉收不到风\n\nR 从风坊带货重运　　Esc 返回港口"
func retry_from_bank()->void:
	health=100;charge=24;speed=0;vy=0;airborne=false;pos=Terrain.BANK;heading=0;altitude=land.ground(pos);view_heading=0
	blessing=charter_branch;branch_spent=false;branch_mesh.visible=charter_branch;chime_taken=false;cab_bell.visible=bell_returned;sail_crossed=false;collector_x=[3.,54.];released=0;lost_valley=false;bridge_cleared=false;crossing=false;stone_lane=false;cart_hits=0;safely_passed=false;cargo_shift=0;brace_distance=0;rail_contact=false;drive_time=0;cooldown=0
	catch_window=0.;slide_side=0.;land.miller.hide();passenger.show()
	if freight.get_parent()!=truck:freight.reparent(truck,false)
	freight.position=Vector3(-.94,1.10,0);freight.rotation=Vector3.ZERO;statement.hide();enter("drive");audio.set_scene("road");tell("风坊已换上备用风囊");posed=false
func draw_charge(before:Vector2,dt:float)->void:
	current_gain=0
	var lane:=-1
	if pos.x>=3 and pos.x<=23.5 and absf(pos.y-1)<4.7:lane=0
	elif pos.x>=54 and pos.x<=81 and pos.y>=8.1 and pos.y<=18.6 and altitude<5.3:lane=1
	if lane<0 or airborne:return
	var previous:float=collector_x[lane]
	var meters:=maxf(0.0,pos.x-maxf(before.x,previous))
	collector_x[lane]=maxf(previous,pos.x)
	if meters<=0 or absf(speed)<.8:return
	# The brass scoop faces across the truck. A rental flares its acceptance cone.
	var catch:=(-forward_dir().orthogonal()).dot(Wind.FLOW)
	if catch<(cos(deg_to_rad(76.)) if rented else cos(deg_to_rad(37.))):return
	var flow:=Wind.breeze(pos,time)
	var gain:=meters*(6.2 if lane==0 else 4.45)*(.69+.38*flow)*(1.08 if rented else 1.0)
	var last:=charge;charge=minf(100.,charge+gain);current_gain=(charge-last)/dt
	if last<80 and charge>=80:audio.play_cue("snap");tell("袋绳绷紧 · 这阵风已经够开面包炉",1.6)

func drive(dt:float,gas:float,turn:float)->void:
	drive_time+=dt;var before:=pos
	surface_id=land.surface_kind(pos,altitude)
	var top:float=[12.1,10.75,9.9,12.1][surface_id]
	var gradient:=land.ground_for_wheels(pos+forward_dir()*.9,altitude)-land.ground_for_wheels(pos-forward_dir()*.9,altitude)
	if not airborne and surface_id!=3:top-=clampf(gradient*.56,-.8,.95)
	var target:=gas*(top if gas>0 else 4.2)
	speed=move_toward(speed,target,dt*(9.4 if speed*gas<0 else (4.7 if gas!=0 else 2.2))*(.43 if airborne else 1.0))
	var steering:=clampf(absf(speed)*.41,0,1)*signf(speed)
	heading=wrapf(heading-turn*dt*(1.20 if not airborne else .65)*steering,-PI,PI)
	var gust:=Wind.pressure(pos,time)
	var exposed:=1.-smoothstep(10,20,-pos.y)
	var move:=forward_dir()*speed*dt+Wind.FLOW*(gust*exposed*minf(absf(speed)*.022,.22)*dt)
	var next:=pos+move
	if clear(next):pos=next
	else:
		if clear(Vector2(next.x,pos.y)):pos.x=next.x
		elif clear(Vector2(pos.x,next.y)):pos.y=next.y
		if absf(speed)>4.5:hurt(3.+absf(speed)*.73,"撞到石垣")
		speed=move_toward(speed,0,dt*28)
	var travelled:=before.distance_to(pos);route_meters+=travelled
	if pos.distance_to(land.front_cart_pos)<2.32 and (absf(speed)>2.8 or absf(land.front_cart_speed)>2.8) and not airborne and cooldown<=0:
		cart_hits+=1;hurt(8.0+absf(speed)*.75,"迎面被空货车撞到");speed*=.47
	if pos.x>33 and cart_hits==0 and not safely_passed:safely_passed=true
	var ground_y:=land.ground_for_wheels(pos,altitude)
	if not airborne and altitude-ground_y>.52:airborne=true;vy=0;burst_used=false;air_start=altitude
	if airborne:
		var old:=altitude;vy-=13.*dt;altitude+=vy*dt
		if vy<=0 and altitude<=ground_y and old>=ground_y-.50:
			if vy< -10.9:hurt(minf(18.,(-vy-8.)*1.27),"落进磨沟")
			airborne=false;altitude=ground_y;vy=0
		elif altitude<land.ground(pos):altitude=land.ground(pos);airborne=false;vy=0
	else:altitude=ground_y
	if pos.x>57 and pos.x<60.7 and absf(pos.y)<3.1 and altitude>5.8:crossing=true
	if crossing and pos.x>72.6 and absf(pos.y)<3.15 and altitude>=6.0 and not lost_valley:bridge_cleared=true
	if pos.x>54 and pos.x<79 and altitude<2.6:
		if not lost_valley:tell("旧磨沟 · 顺青铜风口驶出，可把风补回",2.3)
		lost_valley=true
	if pos.x>56 and pos.x<77 and pos.y< -14.5:stone_lane=true
	if not blessing and not branch_spent and pos.distance_to(preload("res://zephyr_coast.gd").SHRINE)<3.45:
		blessing=true;branch_mesh.show();bell_audio.play();tell("西风小祠 · 丰收枝替你抵消一次撞击，至多 9 点",3.0)
	if airborne and not bell_returned and not chime_taken and route_events.can_hear(pos,altitude):
		chime_taken=true;cab_bell.show();bell_audio.play();tell("接住失落的风铃 · 送还港口赏 12 枚",2.75)
	if route_events.touches_sail(before,pos) and not sail_crossed:
		sail_crossed=true
		if absf(speed)>5.4:
			hurt(5.+absf(speed)*.30,"风未掀帆，帆布擦过车顶");speed*=.64
		else:tell("慢行穿过晒帆 · 风囊无损",1.65)
	draw_charge(before,dt)
	var slide:=turn*speed*absf(speed)*-.0030+gust*exposed*absf(speed)*.0028
	catch_window=maxf(0.,catch_window-dt)
	if absf(slide)<.15 or signf(slide)!=slide_side:
		slide_side=0.
	if slide_side==0 and absf(speed)>.5 and Catch.reaches_rail(.68-cargo_shift*signf(slide),absf(slide),0.,.11):
		slide_side=signf(slide);catch_window=Catch.WINDOW;audio.play_cue("buckle")
	cargo_shift=clampf(cargo_shift-turn*speed*absf(speed)*dt*.0030+gust*exposed*absf(speed)*.0028*dt,-.68,.68)
	if correction>0:
		cargo_shift=move_toward(cargo_shift,0,Catch.grip_step(minf(correction,dt)))
		correction=maxf(0.,correction-dt)
	if absf(cargo_shift)>.666 and absf(speed)>7 and not rail_contact:
		rail_contact=true;hurt(2.4,"风囊碰上车帮")
	if absf(cargo_shift)<.48:rail_contact=false
	update_truck(dt,turn);tracks.update(dt,travelled,surface_id)
func update_truck(dt:float,turn:float)->void:
	var dir:=forward_dir()
	var fore:=land.ground_for_wheels(pos+dir*.66,altitude)
	var aft:=land.ground_for_wheels(pos-dir*.66,altitude)
	var side:=dir.orthogonal()
	var slope:=clampf(atan2(fore-aft,1.32),-.35,.35)
	var bank:=clampf(atan2(land.ground_for_wheels(pos+side*.6,altitude)-land.ground_for_wheels(pos-side*.6,altitude),1.2),-.21,.21)
	pitch=lerpf(pitch,clampf(vy*.043,-.22,.25) if airborne else slope,1.-exp(-dt*5.7))
	roll=lerpf(roll,-bank-turn*speed*.006,1.-exp(-dt*6))
	var vibration:float=(.020*sin(route_meters*7.76) if surface_id==3 else (.024*sin(route_meters*3.25) if surface_id==2 else .0))
	if airborne:vibration=0.
	truck.position=Vector3(pos.x,altitude+.075+vibration,pos.y);truck.rotation=Vector3(roll,heading,pitch)
	for w in wheels:w.rotate_z(-speed*dt*1.8)
	if freight.get_parent()==truck:freight.position=Vector3(-.94,1.10,cargo_shift);freight.rotation.x=-cargo_shift*.22
	shoe_buckle.visible=stage=="drive" and (catch_window>0 or correction>0);shoe_buckle.position=Vector3(-.96,1.83,cargo_shift+signf(cargo_shift)*.55)
func begin_visit()->void:
	statement.hide();ticket.hide();land.miller.show()
	if visitor==null:visitor=art.courier(self)
	for candidate:Vector2 in [Vector2(93.8,-4.6),Vector2(93.0,-5.8),Vector2(92.0,-7.12),Vector2(94.0,-9.2)]:
		if can_visit(candidate):visit_pos=candidate;break
	visitor.show();visitor.position=land.surface(visit_pos);enter("visit");tell("码头已记账 · 走近米拉或蓝窗面包房再按 E")
func can_visit(p:Vector2)->bool:
	if not land.valid(p,true) or p.distance_to(Terrain.TOWER)>16.:return false
	var local:=truck.to_local(land.surface(p))
	return local.x< -3.26 or local.x>3.25 or absf(local.z)>1.46

func settle_delivery()->void:
	if assessed:return
	if health<30:enter("broken");statement.text="风囊已损坏 · R 从风坊重来";statement.show();return
	signed_level=2 if wind_units()>=FULL_ENOUGH else 1;land.apply_result(signed_level)
	rate_tip=floori(wind_units()/20.)*5
	decline=0 if health>=90 else (15 if health>=60 else 36)
	bell_bonus=12 if chime_taken and not bell_returned else 0
	gross=60+rate_tip+pad_tip+bell_bonus-decline
	assessed=true;order_signed.emit(signed_level,gross,wind_units(),route_name())
	audio.play_cue("win");audio.set_scene("yard")
	mill_song.stream=preload("res://audio/zephyr_oven.wav") if signed_level==2 else preload("res://audio/zephyr_winch.wav");mill_song.play()
	enter("awaken");tell("余风沿布管送进主轴",2.3)
func route_name()->String:
	if lost_valley:return "旧磨沟"
	if bridge_cleared:return "借风越桥"
	if stone_lane:return "背风石巷"
	return "橄榄园自由道"
func bill()->void:
	enter("signed");statement.hide();ticket.set_receipt(self)
	var text_result:="磨盘运粮 · 蓝窗开炉" if signed_level==2 else "起重绞盘复工 · 等待下一阵风"
	statement.text="西风签收　·　%s\n\n%s　余风 %d / 100　囊体 %d%%\n运费 60　余风小费 %d　软垫 %d　破损 −%d%s\n导风罩租金 −%d　　本单净收 %d 枚\n\n米拉：「%s」\nE 返港　　Tab 留在磨坊走走"%[text_result,route_name(),wind_units(),floori(health),rate_tip,pad_tip,decline,"　寻铃 +12" if bell_bonus else "",HOOD_COST if rented else 0,gross-(HOOD_COST if rented else 0),"让伊娅把窗推开吧。" if signed_level==2 else "粮袋终于吊起来了。"]
func _physics_process(dt:float)->void:
	if chart.visible:return
	time+=dt;phase_time+=dt;notify_time=maxf(0,notify_time-dt);cooldown=maxf(0,cooldown-dt);punch=maxf(0,punch-dt*1.25)
	land.tick(dt,time)
	land.people.tick(land,time,land.result_blend,phase_time,stage=="awaken")
	if bakery_moved:
		land.people.dough.hide();land.people.lamp.hide();land.people.bread_tray.hide();land.people.bakery_awn.scale.x=.1
		for plume in land.bakery_smoke:plume.hide()
		for shutter in land.shutters:shutter.rotation.y=0
	route_events.tick(time,chime_taken or bell_returned)
	var aim:=compass_dest-pos
	needle.rotation.y=lerp_angle(needle.rotation.y,-aim.angle()-heading,1.-exp(-dt*5.2))
	if not compass_title.is_empty() and aim.length()<3.7:
		tell("到达标记 · "+compass_title);compass_title="";compass_dest=Terrain.MILL_PORT;chart.active=-1
	land.coastal.tick(time,blessing or branch_spent)
	cab_bell.rotation.z=sin(time*4.1)*(.10+absf(speed)*.012)
	mixer_clock+=dt
	if mixer_clock>.09:
		mixer_clock=0.;var wave:=Wind.pressure(pos,time);var hollow:=.65 if pos.y< -15 else 1.
		hear_wind.volume_db=-29+(wave*10+minf(absf(speed),12)*.45)*hollow
		hear_wind.pitch_scale=.91+.15*wave
		audio.bg.volume_db=-19 if stage in ["crane","awaken","signed","visit"] else -15
	var right:=float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var forward:=float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))-float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	match stage:
		"load":porter.move(dt,Vector2(right,-forward))
		"strap":
			var t:=smoothstep(0,.70,phase_time);freight.global_position=loaded_from.lerp(truck.to_global(Vector3(-.94,1.10,0)),t)+Vector3.UP*sin(t*PI)*.61
			if phase_time>=.70:
				freight.reparent(truck,false);freight.position=Vector3(-.94,1.10,0);freight.rotation=Vector3.ZERO;enter("drive");land.apprentice.hide();passenger.show();land.target_ring.show();audio.set_scene("road");tell("沿风廊开出村 · 布袋会随采风鼓起")
		"drive":drive(dt,forward,right)
		"crane":
			if crane.tick(dt,right):
				health=maxf(0,health-crane.damage);pad_tip=6 if crane.gentle else 0
				crane.queue_free();crane=null;freight.rotation=Vector3.ZERO;settle_delivery()
		"awaken":
			if phase_time>4.6:bill()
		"visit":
			var v:=Vector2(right,-forward).limit_length(1)
			var next:=visit_pos+v*dt*Porter.WALK_SPEED
			if can_visit(next):visit_pos=next
			visitor.position=land.surface(visit_pos)
			if v.length()>.1:visitor.rotation.y=atan2(v.x,v.y)
			for s in [-1,1]:
				var limb:=visitor.get_node("LegL" if s==-1 else "LegR") as Node3D;limb.rotation.x=sin(time*10)*.39*s*v.length()
	update_cargo(dt);draw_camera(dt);update_ui()
func update_cargo(_dt:float)->void:
	var size:=charge/100.
	if stage=="awaken":size*=1.-.86*smoothstep(.12,2.7,phase_time)
	if stage in ["signed","visit"] and not visit_archive:size*=.14

	skin.scale=Vector3(.81+.49*size,.62+.55*size,.81+.50*size)
	cord.position.y=-.40+.54*size;hood.position.y=.72+.43*size
	for j in vanes.size():vanes[j].rotation.z=-.72+size*.69+.10*sin(time*(4.+size*4)+j)
	wear.update(freight,"sack",health)
	for i in wisps.size():
		var n:=wisps[i];n.visible=punch>.02
		if n.visible:
			var u:=1.-punch;var a:=i*TAU/wisps.size()
			n.position=Vector3(pos.x,altitude+.46,pos.y)+Vector3(cos(a)*(1.55+u*4.1),sin(PI*u)*.52,sin(a)*(1.55+u*4.1))
			n.rotation.y=-a;n.scale=Vector3(.72+punch*1.08,.045,.11)
	for i in notes.size():
		var n:=notes[i];n.visible=stage=="drive" and current_gain>2.0
		if n.visible:
			var u:=fposmod(time*1.95+i*.25,1)
			n.global_position=freight.global_position+Vector3(-Wind.FLOW.x,0,-Wind.FLOW.y)*(1-u)*2.75+Vector3.UP*(.9+.34*sin(u*PI))
			n.scale=Vector3.ONE*(.10+(1-u)*.34)
func draw_camera(dt:float)->void:
	var look:Vector3
	var offset:Vector3
	match stage:
		"offer","load","strap":
			var at:Vector3=freight.global_position if porter==null else porter.follow_anchor
			look=truck.position.lerp(at,.72)+Vector3.UP*.82
			offset=Vector3(5.5,8.5,9.9)
		"crane":
			var mid:Vector3=crane.start.lerp(crane.pad,.57)
			look=mid.lerp(freight.global_position,.30)+Vector3.UP*.75
			offset=Vector3(-7.4,8.5,6.2)
		"awaken","signed":
			look=land.surface(Terrain.TOWER)+Vector3(0,3.6,-3.9)
			offset=Vector3(-18.4,7.4,6.2)
			if stage=="signed":look+=Vector3(0,0,4.5)
			elif stage=="awaken":
				var dolly:=smoothstep(.38,2.9,phase_time)
				var inlet:=land.surface(Terrain.PAD)+Vector3(1.25,1.23,-1.1)
				look=inlet.lerp(look,dolly);offset=Vector3(-7.3,3.64,4.5).lerp(offset,dolly)
		"visit":
			look=land.surface(visit_pos)+Vector3.UP*1.15;offset=Vector3(0,7.8,8.5)
		_:
			view_heading=lerp_angle(view_heading,heading,1.-exp(-dt*4.1))
			var f:=Vector3(cos(view_heading),0,-sin(view_heading))
			look=truck.position+f*3.20+Vector3.UP*1.24
			offset=-f*11.55+Vector3.UP*(6.55+.33*punch)
	var factor:=1.-exp(-dt*(5.7 if stage=="drive" else 4.8))
	camera_focus=camera_focus.lerp(look,factor) if posed else look
	var pose:=Transform3D(Basis.looking_at(-offset,Vector3.UP),camera_focus+offset)
	cam.transform=cam.transform.interpolate_with(pose,factor) if posed else pose;posed=true
	cam.fov=lerpf(cam.fov,53.+3.0*smoothstep(5.,12.,absf(speed)) if stage=="drive" else 54.,1.-exp(-dt*2.1))
	if is_instance_valid(porter):porter.cutaway.update(cam,porter.courier)
func update_ui()->void:
	var local:=""
	var head:="西风过境　/　橄榄风坊"
	var intent:="将一袋西风送到山顶磨坊"
	var keys:="E 接下委托　 B 租导风罩 12 枚　 Q 听米拉说　 Esc 返港"
	match stage:
		"offer":
			intent="米拉的麦子还在吊钩下 · 留足 80 点风，蓝窗面包房就能开炉"
			if prior_level>0:keys+="　 Tab 回访磨坊";intent="上回 "+previous_receipt
			local="E 接单搬起风囊"+("　·　导风罩已租" if rented else "")
		"load","strap":
			keys="WASD 走位　 E 抬起 / 放下 / 装车　 Q 转货　 Esc 返港";local=porter.prompt() if porter!=null else "系紧风囊"
		"drive":
			head="西风过境　/　"+("旧磨沟" if lost_valley and pos.x<82 else ("北坡风车" if pos.x>82 else ("背风石巷" if pos.y< -13 else ("橄榄山脊" if pos.x>0 else "海崖驿道"))))
			keys="W S 油门 / 刹车　 A D 转向　 空格 跳 · 空中再按借风　 E 交货"
			if pos.x< -31:intent="沿白石路穿橄榄门 · 路旁小祠可取丰收枝"
			elif pos.x<0:intent="穿门后找青铜风口 · 往山顶大风车走"
			elif pos.x<23:intent="顺风廊采风 · 留足 80 可开炉"
			elif pos.x<37:intent="风会先吹动布旗，再推空货车过路"
			elif pos.x<82:intent="石巷保风　/　断桥借风　/　谷底补风"
			else:intent="在磨坊金圈旁停稳，E 接吊索"
			if pos.distance_to(preload("res://zephyr_coast.gd").SHRINE)<5 and absf(speed)<2.3:local="E 听守祠人说"
			if pos.x>48 and pos.x<59 and absf(pos.y)<4:local="断桥　空格起跳 · 空中再按放风"
			if pos.y< -16 and pos.x>45 and pos.x<66:local="看旗等风掀帆 · 也可减速从帆下穿过"
			if lost_valley and pos.x<78:local="谷底青铜风廊在右侧"
			if pos.distance_to(Terrain.MILL_PORT)<6.8:local="E 系索交风" if absf(speed)<1.9 else "松油或 S 刹车"
			if pos.distance_to(Vector2(65,16.1))<4.7 and absf(speed)<2.3:local="E 读旧磨坊刻字"
		"crane":
			head="西风过境　/　磨坊进风座";intent="瞄准进风座的软垫中心";keys="A D 移吊车　 空格 放开吊钩";local=crane.hint
		"awaken","signed":head="西风过境　/　磨坊复工";intent="让余风顺布管流进磨坊";keys="E 领取回港　 Tab 走进磨坊"
		"visit":head="西风过境　/　磨坊回访";intent="米拉在转轮旁，伊娅在面包房蓝窗前";keys="WASD 散步　 E 交谈　 Tab 回到风坊　 Esc 返港" if visit_archive else "WASD 散步　 E 交谈　 Tab 查看收据　 Esc 返港"
		"broken":intent="风囊已失去密封";keys="R 重新配送　 Esc 返港"
	title.text=head;objective.text=intent;guide.text=keys+("　 M 运单地图" if stage in ["drive","offer"] else "")
	objective.visible=stage!="signed";guide.visible=stage!="signed"
	seal.text="可用运费　%d 枚"%wallet if stage=="offer" else ("导风罩已租" if rented else "")
	if stage=="offer" and charter_branch:seal.text+="　·　商号赠丰收枝"
	seal.visible=not seal.text.is_empty()
	bag_tag.visible=stage in ["load","drive","crane"]
	if bag_tag.visible:
		bag_tag.text="余风 %d"%wind_units()+("　采风 ↑" if stage=="drive" and current_gain>2 else ("　可开炉" if charge>=80 and stage=="drive" else ""))
		if blessing:bag_tag.text+="　✦"
		if health<90:bag_tag.text+="　囊体 %d%%"%floori(health)
		if stage=="drive" and (catch_window>0 or correction>0):bag_tag.text+="　"+Catch.instruction(catch_window,correction)
		var pt:=freight.global_position+Vector3.UP*1.65
		bag_tag.reset_size();bag_tag.position=(cam.unproject_position(pt)+Vector2(16,-18)).clamp(Vector2(14,112),Vector2(1255-bag_tag.size.x,560))
	balance.visible=stage=="drive" and Catch.show_balance(cargo_shift/.68,catch_window,correction)
	if balance.visible:balance.position=bag_tag.position+Vector2(5,bag_tag.size.y-1);balance.queue_redraw()
	action.text=notify_text if notify_time>0 else local;action.visible=not statement.visible and not ticket.visible and not action.text.is_empty()
	action.reset_size();action.position=Vector2((1280-action.size.x)*.5,574)
