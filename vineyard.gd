extends Node3D

const Map=preload("res://vineyard_land.gd")
const Art=preload("res://workshop.gd")
var land:=Map.new()
var art:=Art.new()
var wear:=preload("res://cargo_wear.gd").new()
var audio=preload("res://sound.gd").new()
var truck:Node3D
var freight:Node3D
var receiver:Node3D
var cam:=Camera3D.new()
var pos:=Vector2(1.0,2.0)
var heading:=0.0
var speed:=0.0
var pitch:=0.0
var roll:=0.0
var altitude:=0.0
var vy:=0.0
var airborne:=false
var reserve:=1
var wind_used:=false
var lean:=0.0
var lean_v:=0.0
# Deck coordinates are longitudinal (x) and lateral (y); neither has a centering spring.
const RAIL:=Vector2(0.37,0.56)
var load_offset:=Vector2.ZERO
var load_velocity:=Vector2.ZERO
const Catch:=preload("res://cargo_catch.gd")
const BRACE_DISTANCE:=Catch.PULL
const BRACE_DURATION:=Catch.DURATION
const CATCH_WINDOW:=Catch.WINDOW
var brace_time:=0.0
var slip_caught:=false
var slip_side:=0
var catch_left:=0.0
var calm_time:=0.0
var pending_hit:=0.0
var catch_strap:Node3D
var buckle:Node3D
var brace_travel:=0.0
var impact_time:=0.0
var rail_loss:=0
var last_warning:=""
var rail_hits:=0
var health:=100.0
var departure:=Vector2.ZERO
var departure_heading:=0.0
var landing_note:=""
var stage:="pickup"
var handoff:=0.0
var duration:=1.0
var carry_from:=Vector3.ZERO
var carry_to:=Vector3.ZERO
var exit_name:=""
const REACH:=5.4
var stations:Array[Dictionary]=[]
var clock:=0.0
var was_ready:=false
var delivered_at:=Vector2.ZERO
var view_blend:=1.0
var walked:=0.0
var title:=Label.new()
var info:=Label.new()
var controls:=Label.new()
var traffic:=preload("res://cape_traffic.gd").new()
var crane:Node3D
var quay_tip:=0
var porter:Node3D
var wind_job:=false
var strap_paid:=false
var gate_passed:=false
var porter_time:=0.0
var dock_gate:Node3D
const WIND_SOURCE:=Vector2(3,9)
const WIND_DOCK:=Vector2(167,12)
var returning:=false
var rested:=false
var rest_time:=0.0
var ledger:Array[int]=[]
var tag=preload("res://freight_tag.gd").new()
var receipt:=Label.new()
var dock_order:Node3D
var dock_earnings:=0
var night_earnings:=0
var bell_record:Dictionary={}
var bell_done:=false
var bell_padding:=false
var bell_song:=false
var bell_selected:=false
var bell_blessed:=false
var bell_letter:=0
var zephyr_selected:=false
var wind_wallet:=0
var wind_level:=0
var wind_receipt:=""
var wind_last_charge:=0
var wind_runs:=0
var wind_bell:=false
var lamp_supper_bonus:=0
var quay_mirror:=false
var worker_runs:=0
var worker_ticket:=false
var lamp_worker_home:=false
var lamp_step:=0
var grain_status:=0
var spring:=preload("res://spring_line.gd").new()
var grain_pay:=0
var meal_stock:=0
var table_inn:=false
var table_crew:=false
var inn_regular_pay:=0
var grain_position:=Vector2.ZERO
var grain_helm:=Vector2.ZERO
var grain_heading:=0.
var barge_heading:=0.
var barge_velocity:=Vector2.ZERO
var grain_bumps:=0
var road_quay:Node3D
var hearth_moved:=false
var freight_route:=0
var bread_checkpoint:=Vector2.ZERO
var bread_heading:=PI
var market_open:=false
var market_bonus:=0
var laurel_carried:=false
var laurel_income:=0
var resume_signed_after_bread:=false
var delivery_message:=""
var delivery_time:=0.
var bread_sites:Array[Node3D]=[]
var inn_runs:=0
var move_pay:=0
var hot_pay:=0
var office:=preload("res://freight_office.gd").new()
var bread_case:Node3D
var inn_table:Node3D
var bread_waiting:=false
var bread_shipments:=0
var port_return:=preload("res://zephyr_port.gd").new()
var port_view:=0.
var port_talk:=0.
var port_caption:=Label.new()
var night_selected:=false
var day_best:=0
var night_best:=0
var north_beacon:=false
var diver_lamp:=false
var board:=preload("res://harbour_board.gd").new()
var book_button:=Button.new()
var day_button:=Button.new()
var night_button:=Button.new()
var receipt_base:=""
var camera_yaw:=0.0
var shot_mode:="road"
var shot_from:=Transform3D.IDENTITY
var shot_blend:=1.0
var hook_focus:=Vector3.ZERO
var bumps:=0
var elapsed:=0.0

var profile_path:=""

func postmark_file()->String:
	if profile_path.is_empty():
		profile_path=OS.get_environment("OLYMPUS_TRIAL_PROFILE")
		if profile_path.is_empty() and OS.has_feature("foundry_guidance"):
			var folder:=OS.get_executable_path().get_base_dir().path_join("存档")
			if DirAccess.make_dir_recursive_absolute(folder)==OK:
				profile_path=folder.path_join("铸钟山.cfg")
			else:profile_path="user://foundry-guidance.cfg"
		if profile_path.is_empty():profile_path="user://harbour_postmarks.cfg"
	return profile_path

func read_postmarks()->void:
	var profile:=ConfigFile.new()
	if profile.load(postmark_file())!=OK:return
	bell_blessed=profile.get_value("bell","blessed",false);bell_letter=clampi(profile.get_value("bell","letter",0),0,2)
	bell_record=profile.get_value("bell","run",{});bell_done=profile.get_value("bell","done",false);bell_padding=profile.get_value("bell","padding",false);bell_song=profile.get_value("bell","song",false)
	spring.load_state(profile)
	day_best=maxi(0,int(profile.get_value("port","day_best",0)));night_best=maxi(0,int(profile.get_value("port","night_best",0)))
	north_beacon=bool(profile.get_value("port","north_beacon",false));diver_lamp=bool(profile.get_value("port","diver_lamp",false))

	wind_wallet=maxi(0,int(profile.get_value("westwind","wallet",day_best+night_best)))
	wind_level=clampi(int(profile.get_value("westwind","level",0)),0,2)
	wind_receipt=str(profile.get_value("westwind","receipt",""))
	bread_waiting=bool(profile.get_value("westwind","bread_waiting",wind_level==2))
	bread_shipments=int(profile.get_value("westwind","bread_shipments",0))
	lamp_supper_bonus=int(profile.get_value("line","supper_income",0))
	lamp_worker_home=bool(profile.get_value("line","late_worker",false))
	grain_status=clampi(int(profile.get_value("line","grain_status",0)),0,2)
	meal_stock=clampi(int(profile.get_value("line","meal_stock",1 if grain_status==2 else 0)),0,2)
	table_inn=bool(profile.get_value("line","table_inn",false))
	table_crew=bool(profile.get_value("line","table_crew",false))
	inn_regular_pay=int(profile.get_value("line","inn_regular_pay",0))
	grain_pay=int(profile.get_value("line","grain_pay",0))
	grain_position=profile.get_value("line","grain_position",Vector2(7,-19))
	grain_helm=profile.get_value("line","grain_helm",Vector2(6,-15))
	grain_heading=float(profile.get_value("line","grain_heading",0))
	barge_heading=float(profile.get_value("line","barge_heading",grain_heading))
	barge_velocity=profile.get_value("line","barge_velocity",Vector2.ZERO)
	grain_bumps=clampi(int(profile.get_value("line","grain_bumps",0)),0,3)
	quay_mirror=bool(profile.get_value("line","quay_mirror",false)) and lamp_worker_home
	worker_runs=maxi(1 if lamp_worker_home else 0,int(profile.get_value("line","worker_runs",0)))
	worker_ticket=bool(profile.get_value("line","worker_ticket",false))
	lamp_step=clampi(int(profile.get_value("line","blue_quay",0)),0,3)
	hearth_moved=bool(profile.get_value("line","hearth_moved",false))
	freight_route=clampi(int(profile.get_value("line","freight_route",2 if bread_waiting else 0)),0,3)
	bread_checkpoint=profile.get_value("line","road_position",WIND_DOCK-Vector2(2.5,0))
	bread_heading=float(profile.get_value("line","road_heading",PI))
	laurel_carried=bool(profile.get_value("line","laurel_carried",false)) and freight_route==3
	laurel_income=int(profile.get_value("line","laurel_income",0))
	market_open=bool(profile.get_value("line","market_open",false))
	market_bonus=int(profile.get_value("line","market_bonus",0))
	inn_runs=int(profile.get_value("line","inn_runs",0))
	move_pay=int(profile.get_value("line","move_pay",0))
	hot_pay=int(profile.get_value("line","hot_pay",0))
	wind_bell=bool(profile.get_value("westwind","bell",false))
	wind_runs=int(profile.get_value("westwind","runs",0))
	wind_last_charge=int(profile.get_value("westwind","charge",0))

func file_postmarks()->void:
	var profile:=ConfigFile.new()
	if profile.load(postmark_file())==OK:
		day_best=maxi(day_best,int(profile.get_value("port","day_best",0)));night_best=maxi(night_best,int(profile.get_value("port","night_best",0)))
		north_beacon=north_beacon or bool(profile.get_value("port","north_beacon",false));diver_lamp=diver_lamp or bool(profile.get_value("port","diver_lamp",false))
	profile.set_value("bell","blessed",bell_blessed);profile.set_value("bell","letter",bell_letter)
	profile.set_value("bell","run",bell_record);profile.set_value("bell","done",bell_done);profile.set_value("bell","padding",bell_padding);profile.set_value("bell","song",bell_song)
	spring.save_state(profile)
	profile.set_value("port","day_best",day_best);profile.set_value("port","night_best",night_best)
	profile.set_value("port","north_beacon",north_beacon);profile.set_value("port","diver_lamp",diver_lamp)
	profile.set_value("westwind","wallet",wind_wallet)
	profile.set_value("westwind","level",wind_level)
	profile.set_value("westwind","receipt",wind_receipt)
	profile.set_value("westwind","charge",wind_last_charge)
	profile.set_value("westwind","runs",wind_runs)
	profile.set_value("westwind","bell",wind_bell)
	profile.set_value("westwind","bread_waiting",bread_waiting)
	profile.set_value("westwind","bread_shipments",bread_shipments)
	profile.set_value("line","supper_income",lamp_supper_bonus)
	profile.set_value("line","late_worker",lamp_worker_home)
	profile.set_value("line","grain_status",grain_status)
	profile.set_value("line","grain_pay",grain_pay)
	profile.set_value("line","meal_stock",meal_stock)
	profile.set_value("line","table_inn",table_inn)
	profile.set_value("line","table_crew",table_crew)
	profile.set_value("line","inn_regular_pay",inn_regular_pay)
	profile.set_value("line","grain_position",grain_position)
	profile.set_value("line","grain_helm",grain_helm)
	profile.set_value("line","grain_heading",grain_heading)
	profile.set_value("line","grain_bumps",grain_bumps)
	profile.set_value("line","barge_heading",barge_heading)
	profile.set_value("line","barge_velocity",barge_velocity)
	profile.set_value("line","worker_ticket",worker_ticket)
	profile.set_value("line","worker_runs",worker_runs)
	profile.set_value("line","quay_mirror",quay_mirror)
	profile.set_value("line","blue_quay",lamp_step)
	profile.set_value("line","hearth_moved",hearth_moved)
	profile.set_value("line","freight_route",freight_route)
	profile.set_value("line","laurel_carried",laurel_carried)
	profile.set_value("line","laurel_income",laurel_income)
	profile.set_value("line","market_open",market_open)
	profile.set_value("line","market_bonus",market_bonus)
	profile.set_value("line","inn_runs",inn_runs)
	if freight_route==3:
		bread_checkpoint=spring.previous_pos if spring.active else pos;bread_heading=spring.previous_yaw if spring.active else heading
		profile.set_value("line","road_position",bread_checkpoint)
		profile.set_value("line","road_heading",spring.previous_yaw if spring.active else heading)
	profile.set_value("line","move_pay",move_pay)
	profile.set_value("line","hot_pay",hot_pay)
	var err:=profile.save(postmark_file())
	if err!=OK:push_warning("港务纪录未写入磁盘，本班成绩仍然有效")

func open_board()->void:
	if not is_instance_valid(dock_order) and stage in ["pickup","signed"] and not is_instance_valid(porter):
		board.refresh(day_best,night_best,north_beacon,diver_lamp,wind_level,wind_wallet,bread_waiting,freight_route,kiln_fare(),lamp_step,lamp_worker_home,grain_status)
		board.continue_route("")
		if bell_done:
			var next:="去蓝棚木阶开夜班"
			if grain_status==2:next="去晨班看看新到的粮食"
			elif grain_status==1:next="接着领粮驳进港"
			elif worker_ticket:next="送船上的窑工回家"
			elif lamp_worker_home:next="回木阶接下一班"
			elif lamp_step==3:next="去双灯窑接晚班窑工"
			elif lamp_step==2:next="把船上的陶灯送回木阶"
			elif lamp_step==1:next="去双灯窑取陶灯"
			elif bell_song:next=["去木阶见渡工的女儿","接着送船上的家书","去看看窑工烧的灯"][bell_letter]
			board.continue_route(next)
			board.stamps[2].text=["回声已到蓝棚　·　有封信待捎","船上有家书　·　送往双灯窑","双灯窑已寄出家书"][bell_letter] if bell_song else "白帆港的铜钟已为夜船报平安"
		board.show()

func book_select(index:int)->void:
	board.hide()
	if index==8 and bell_done:
		if grain_status==2 and not worker_ticket:open_tide_dock(false,true)
		else:open_tide_dock(true,true,true)
	elif index==7:open_bell()
	elif index==6:spring.begin()
	elif index==5:office_action(6)
	elif index==4:office.refresh(self)
	elif index==3:open_westwind()
	elif index>0:open_tide_dock(index==2)

func open_bell()->void:
	if is_instance_valid(dock_order):return
	board.hide();bell_selected=true;zephyr_selected=false;night_selected=false
	dock_order=preload("res://bell_first.gd").new();dock_order.record=bell_record;dock_order.fitted=bell_padding;dock_order.previously_paid=bell_done;dock_order.letter_history=bell_letter
	dock_order.checkpoint.connect(save_bell);dock_order.completed.connect(record_bell)
	enter_harbour_job()

func save_bell(run:Dictionary)->void:
	bell_record=run.duplicate(true);file_postmarks()

func record_bell(song:bool,integrity:float,bought:bool)->void:
	if not bell_done:
		wind_wallet+=preload("res://bell_first.gd").fare(integrity,song,bell_record.get("repair",false))-(12 if bought else 0)
		bell_padding=bought
	bell_blessed=bell_blessed or bell_record.get("blessing",false);bell_done=true;bell_song=bell_song or song;bell_record={};file_postmarks()

func _ready()->void:
	read_postmarks()
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_SKY
	var atmosphere:=ProceduralSkyMaterial.new()
	atmosphere.sky_top_color=Color("#5b94bf")
	atmosphere.sky_horizon_color=Color("#c2dce2")
	atmosphere.ground_horizon_color=Color("#b4cfcf")
	atmosphere.ground_bottom_color=Color("#739799")
	env.environment.sky=Sky.new()
	env.environment.sky.sky_material=atmosphere
	env.environment.background_color=Color("#c5dfe0")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("#e3e7dc")
	env.environment.ambient_light_energy=0.62
	env.environment.fog_enabled=true
	env.environment.fog_light_color=Color("#c7d7ce")
	env.environment.fog_density=0.004
	add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-49,-36,0)
	sun.light_energy=0.99
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=104
	add_child(sun)
	add_child(land)
	add_child(traffic)
	traffic.build(land)
	var harbour:=preload("res://bay_harbour.gd").new()
	add_child(harbour)
	harbour.build()
	add_child(port_return);port_return.build();port_return.relocated=hearth_moved;port_return.apply(wind_level,wind_bell)
	land.solids.append(Rect2(9.1,13.2,5.8,3.3))
	add_child(audio)
	audio.set_scene("yard")
	road_quay=preload("res://lamp_quay.gd").new();add_child(road_quay);road_quay.position=land.surface(WIND_DOCK+Vector2(-1,5));road_quay.oven_installed=hearth_moved;road_quay.build(lamp_step==3);road_quay.visible=lamp_step==3
	if lamp_worker_home:road_quay.seat_regular()
	if grain_status==2:road_quay.grain_received()
	if table_inn and table_crew:road_quay.set_feast()
	truck=art.truck(self)
	bread_case=make_bread(truck,Vector3(-2.22,1.15,.66));bread_case.visible=bread_waiting and freight_route==3
	inn_table=make_bread(self,land.surface(Map.LODGE+Vector2(.8,2.4))+Vector3.UP*.87);inn_table.visible=inn_runs>0 or table_inn
	art.box(self,inn_table.position-Vector3.UP*.13,Vector3(1.5,.17,.98),Art.WOOD)
	catch_strap=art.group(truck)
	art.beam(catch_strap,Vector3(-0.62,-0.28,0),Vector3(0,0.26,0),0.052,Art.GOLD)
	art.beam(catch_strap,Vector3(0,0.26,0),Vector3(0.62,-0.28,0),0.052,Art.GOLD)
	buckle=art.ring(catch_strap,Vector3.UP*0.26,0.19,0.055,Art.CREAM)
	buckle.rotation.x=PI/2
	catch_strap.hide()
	freight=art.trolley(self)
	freight.rotation.y=PI/2
	freight.position=land.surface(Map.CELLAR+Vector2(-1.50,11.4))+Vector3.UP*0.12
	receiver=art.hero(self,"patron_wine")
	receiver.position=Vector3(185,0,-2.7)
	receiver.rotation.y=-PI/3
	receiver.scale=Vector3.ONE*0.91
	add_child(cam)
	cam.current=true
	cam.fov=54
	build_ui()
	add_station(Map.CELLAR,"酒庄取货")
	add_station(Map.STEPS,"正阶交酒")
	add_station(Map.SIDE,"侧院交酒")
	for stop:Vector2 in [WIND_DOCK,Map.GROVE,Map.LODGE]:
		var marker:=art.group(self,land.surface(stop))
		art.ring(marker,Vector3.UP*.13,3.2,.075,"#e8bc60")
		var sign:=Label3D.new();marker.add_child(sign);sign.position=Vector3.UP*3.4
		sign.font=title.get_theme_font("font");sign.font_size=32;sign.pixel_size=.018
		sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sign.outline_size=10;sign.outline_modulate=Color("#26433b")
		sign.text="东岸面包交接" if stop==WIND_DOCK else ("静风亭 · 月桂叶" if stop==Map.GROVE else "客舍早餐桌")
		bread_sites.append(marker);marker.hide()
	if bread_waiting and freight_route==3:
		pos=bread_checkpoint;heading=bread_heading;camera_yaw=heading;altitude=land.ground(pos)
	update_pose(1)
	update_ui()
	update_stations()
	if not FileAccess.file_exists(postmark_file()) or not bell_record.is_empty():call_deferred("open_bell")

func build_ui()->void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	var typeface:=preload("res://harbour_fonts.gd").body()
	for label in [title,info,controls,receipt]:
		layer.add_child(label)
		label.add_theme_font_override("font",typeface)
		label.add_theme_font_size_override("font_size",18)
		label.add_theme_color_override("font_color",Color("#fff3d8"))
		var panel:=StyleBoxFlat.new()
		panel.bg_color=Color("#193b40ed")
		panel.set_corner_radius_all(9)
		panel.content_margin_left=15
		panel.content_margin_right=15
		panel.content_margin_top=7
		panel.content_margin_bottom=7
		label.add_theme_stylebox_override("normal",panel)
	for btn:Button in [day_button,night_button,book_button]:
		layer.add_child(btn);btn.focus_mode=Control.FOCUS_NONE
		btn.add_theme_font_override("font",typeface);btn.add_theme_font_size_override("font_size",17)
		btn.add_theme_color_override("font_color",Color("#fff1cf"))
		var card:=StyleBoxFlat.new();card.bg_color=Color("#244954ef") if btn==day_button else Color("#30374eef");card.set_corner_radius_all(8)
		card.border_width_left=4;card.border_color=Color("#d7ad65") if btn==day_button else Color("#aabdda")
		btn.add_theme_stylebox_override("normal",card)
		var hov:=card.duplicate() as StyleBoxFlat;hov.bg_color=card.bg_color.lightened(0.13);btn.add_theme_stylebox_override("hover",hov)
		btn.size=Vector2(229,39);btn.position=Vector2(1027,21 if btn==day_button else 65)
	book_button.position.y=109;book_button.text="P　港务委托簿"
	book_button.pressed.connect(open_board)
	day_button.pressed.connect(open_tide_dock)
	night_button.pressed.connect(func():open_tide_dock(true))
	layer.add_child(tag)
	tag.build(typeface)
	receipt.position=Vector2(350,125)
	receipt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	receipt.custom_minimum_size.x=580
	layer.add_child(port_caption);port_caption.position=Vector2(260,543);port_caption.custom_minimum_size.x=760
	port_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;port_caption.add_theme_font_override("font",typeface);port_caption.add_theme_font_size_override("font_size",20)
	var back:=StyleBoxFlat.new();back.bg_color=Color("#193941ed");back.set_corner_radius_all(6);back.content_margin_top=9;back.content_margin_bottom=9
	port_caption.add_theme_stylebox_override("normal",back);port_caption.hide()
	receipt.hide()
	title.position=Vector2(24,20)
	info.position=Vector2(24,76)
	controls.position=Vector2(24,651)
	title.add_theme_font_size_override("font_size",23)
	controls.text="W 加速    S 刹车 / 倒车    A D 转向    空格 跳 / 空中借风    E 交接    R 重试"
	add_child(spring);spring.setup(self)
	layer.add_child(board);board.selected.connect(book_select);layer.add_child(office);office.chosen.connect(office_action);open_board()

func forward_dir()->Vector2:
	return Vector2(cos(heading),-sin(heading))

func rear()->Vector2:
	return pos-forward_dir()*2.92

func target()->Vector2:
	if wind_job: return WIND_SOURCE if stage=="pickup" else WIND_DOCK
	if returning: return Map.MARKET if stage=="pickup" else Map.LODGE
	if stage=="pickup": return Map.CELLAR
	return Map.SIDE if rear().distance_to(Map.SIDE)<rear().distance_to(Map.STEPS) else Map.STEPS

func add_station(at:Vector2,caption:String)->void:
	var site:=art.group(self,land.surface(at))
	var rim:=art.ring(site,Vector3.UP*0.08,REACH,0.060,Art.GOLD)
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	rim.material_override=material
	var beacon:=art.group(site,Vector3.UP*2.9)
	for direction in [-1,1]:
		art.beam(beacon,Vector3(0,0,direction*0.34),Vector3(0,-0.32,0),0.075,Art.GOLD)
	var tag:=Label3D.new()
	tag.font=title.get_theme_font("font")
	tag.font_size=32
	tag.pixel_size=0.015
	tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test=false
	tag.outline_size=9
	tag.outline_modulate=Color("#173940")
	tag.position=Vector3.UP*0.55
	beacon.add_child(tag)
	stations.append({"at":at,"name":caption,"site":site,"beacon":beacon,"tag":tag,"material":material})

func in_reach(at:Vector2)->bool:
	return rear().distance_to(at)<=REACH

func update_stations()->void:
	for j in bread_sites.size():
		bread_sites[j].visible=bread_waiting and stage=="pickup" and ((j==0 and freight_route==1) or (j>0 and freight_route==3 and (j!=1 or not laurel_carried)))
	var active:=stage in ["pickup","drive"]
	var ready:=active and in_reach(target()) and absf(speed)<=0.65 and not airborne
	if ready and not was_ready: audio.play_cue("snap")
	was_ready=ready
	for station in stations:
		var at:Vector2=station.at
		var pickup:=at==(Map.MARKET if returning else Map.CELLAR)
		var selected:=at==target() if active else at==delivered_at
		var show_it:=pickup if stage in ["pickup","loading"] else not pickup
		if stage in ["signed","unloading"]: show_it=selected
		if returning: show_it=show_it and at in [Map.MARKET,Map.LODGE,Map.GROVE]
		if at==Map.GROVE: show_it=stage in ["drive","rest"] and not rested and not wind_job
		if wind_job:
			show_it=at==WIND_SOURCE if stage in ["pickup","loading","porter_load"] else at==WIND_DOCK
		if stage in ["porter_load","porter_drop","crane"]: show_it=false
		if freight_route in [1,3] and stage=="pickup":show_it=false
		station.site.visible=show_it
		if not show_it: continue
		station.beacon.visible=pos.distance_to(at)<38
		var highlight:=ready and selected
		var tint:=Color("#51edc3") if highlight or stage=="signed" else Color("#ffcb61")
		station.material.albedo_color=tint
		station.tag.modulate=tint
		station.beacon.position.y=3.0+sin(clock*3.2)*0.13
		var words:String=station.name
		if highlight: words+="  [E]"
		elif stage=="loading": words="装车中"
		elif stage=="unloading": words="卸货中"
		elif stage=="signed": words=exit_name+"已签收 ✓"
		station.tag.text=words

func bearing_hint(at:Vector2)->String:
	var delta:=at-rear()
	var angle:=wrapf(delta.angle()-forward_dir().angle(),-PI,PI)
	var side:="前方" if absf(angle)<0.45 else ("后方" if absf(angle)>2.45 else ("右侧" if angle>0 else "左侧"))
	return "%s %.0f 米" % [side,delta.length()]

func road_hint()->String:
	var westbound:=returning and not wind_job
	var bends:=[Vector2(68,10),Vector2(95,-10),Vector2(119,10)]
	var names:=["海崖外弯","葡萄梯田下方","柏树岬口"]
	for step in bends.size():
		var i:int=bends.size()-1-step if westbound else step
		var distance:float=(bends[i].x-pos.x)*(-1 if westbound else 1)
		if distance>2 and distance<32:
			return names[i]+" · "+bearing_hint(bends[i])
	return ""

func begin_return()->void:
	returning=true
	stage="pickup"
	health=100
	rail_hits=0
	bumps=0
	reserve=1
	elapsed=0
	impact_time=0
	lean=0
	lean_v=0
	load_offset=Vector2.ZERO
	load_velocity=Vector2.ZERO
	receipt.hide()
	freight=art.bed(self)
	freight.rotation.y=PI/2
	freight.position=land.surface(Map.MARKET+Vector2(-1.50,-16.97))+Vector3.UP*0.1
	if strap_paid:
		art.beam(freight,Vector3(-0.66,0.26,0.37),Vector3(-0.48,1.12,0.37),0.064,Art.RED)
		art.beam(freight,Vector3(-0.48,1.12,0.37),Vector3(0.48,1.12,0.37),0.064,Art.RED)
		art.beam(freight,Vector3(0.48,1.12,0.37),Vector3(0.66,0.26,0.37),0.064,Art.RED)
	add_station(Map.MARKET,"集市接睡榻")
	add_station(Map.LODGE,"客舍送客")
	add_station(Map.GROVE,"静风亭 · 可停靠")
	update_ui()
	update_stations()

func begin_wind()->void:
	wind_job=true
	stage="pickup"
	health=100
	load_offset=Vector2.ZERO
	load_velocity=Vector2.ZERO
	lean=0
	lean_v=0
	impact_time=0
	reserve=2
	gate_passed=false
	receipt.hide()
	freight=art.sack(self)
	freight.position=land.surface(WIND_SOURCE+Vector2(-2.7,-4.3))+Vector3.UP*0.12
	add_station(WIND_DOCK,"灯塔交风")
	for station in stations:
		if station.at==WIND_SOURCE: station.name="客舍取风"
	dock_gate=art.group(self,Vector3(154,0,9))
	for z in [-3.3,3.3]:
		art.cyl(dock_gate,Vector3(0,2.0,z),0.14,0.11,5.3,Art.GOLD)
		art.box(dock_gate,Vector3(0.48,4.35,z),Vector3(1.18,0.77,0.09),Art.TEAL)
	art.beam(dock_gate,Vector3(0,4.65,-3.3),Vector3(0,4.65,3.3),0.065,Art.GOLD)
	land.sign_at(Vector2(144,13),"乘风赏门")
	update_ui()
	update_stations()

func condition_name()->String:
	return "余风" if wind_job else ("安眠" if returning else "酒况")

func grade()->int:
	if health>=90: return 3
	if health>=60: return 2
	if health>=30: return 1
	return 0

func condition_grade()->String:
	return ["损坏","严重损坏","轻微破损","完整"][grade()]

func reject_order()->void:
	stage="rejected"
	speed=0
	receipt.text="拒收  ·  "+condition_grade()+"  %d%%\n%s本单无报酬  ·  R 从本单装车后重运" % [floori(health),landing_note]
	receipt.show()

func retry_delivery()->void:
	if freight.get_parent()!=truck: freight.reparent(truck,true)
	pos=departure
	heading=departure_heading
	camera_yaw=heading
	altitude=land.ground(pos)
	airborne=false
	speed=0
	vy=0
	pitch=0
	roll=0
	lean=0
	lean_v=0
	health=100
	elapsed=0
	load_offset=Vector2.ZERO
	load_velocity=Vector2.ZERO
	freight.position=Vector3(-0.9,1.1,0)
	freight.rotation=Vector3(0,PI/2,0)
	impact_time=0
	quay_tip=0
	gate_passed=false
	rested=false
	wind_used=false
	reserve=2 if wind_job else 1
	landing_note=""
	receipt.hide()
	brace_time=0
	reset_slip()
	stage="drive"
	audio.set_scene("road")
	update_pose(1)

func sign_order()->void:
	if grade()==0:
		reject_order()
		return
	var base:=90 if wind_job else (75 if returning else 60)
	var stars:=grade()
	var percent:int=[0,40,75,100][stars]
	var fare:=roundi(base*percent/100.0)
	var tip:=roundi(health*0.4) if stars==3 else (roundi(health*0.2) if stars==2 else 0)
	var bonus:=22 if gate_passed else 0
	var cost:=8 if strap_paid else 0
	ledger.append(fare+tip+bonus+quay_tip-cost)
	wind_wallet+=maxi(0,ledger.back());produce();file_postmarks()
	stage="signed"
	receipt.text="%s签收  ·  %s  %s %d%%\n%s运费 %d × %d%% = %d   +   小费 %d" % [exit_name,"★".repeat(stars),condition_grade(),floori(health),landing_note,base,percent,fare,tip]
	if bonus: receipt.text+="  +  乘风赏金 %d" % bonus
	if quay_tip: receipt.text+="  +  正中软垫 %d" % quay_tip
	if cost: receipt.text+="  −  绑带 %d" % cost
	receipt.text+="  =  %d 枚" % ledger.back()
	if wind_job: pass
	elif returning: receipt.text+="\n末班委托：把客舍的风囊送到灯塔   [E 接单]"
	else: receipt.text+="\n集市接睡榻送往月桂客舍   [E 接单]   [B 花 8 枚租绑带并接单]"
	receipt_base=receipt.text
	update_shift_receipt()
	receipt.show()

func update_shift_receipt()->void:
	if stage!="signed":return
	receipt.text=receipt_base
	if dock_earnings+night_earnings>0:receipt.text+="\n船坞 %d　夜渡 %d"%[dock_earnings,night_earnings]
	if wind_job:
		var road_pay:=int(ledger.reduce(func(a,b):return a+b,0))
		receipt.text+="\n今日三单合计 %d 枚"%road_pay
		if dock_earnings+night_earnings>0:receipt.text+="　含港务委托共 %d 枚"%(road_pay+dock_earnings+night_earnings)
		receipt.text+="　·　R 重新出车"

func interact()->void:
	if bread_waiting and stage in ["drive","pickup","signed"] and absf(speed)<1.8 and not is_instance_valid(porter):
		if freight_route==1 and pos.distance_to(WIND_DOCK)<6.0:
			freight_route=3;bread_case.show();delivery_message="面包已上车　·　沿海岸返回月桂客舍";delivery_time=2.4
			file_postmarks();audio.play_cue("load");return
		if freight_route==3 and not laurel_carried and pos.distance_to(Map.GROVE)<4.8:
			laurel_carried=true;delivery_message="月桂叶已包好　·　客舍加付 2 枚";delivery_time=3.2
			file_postmarks();audio.play_cue("load");return
		if freight_route==3 and pos.distance_to(Map.LODGE)<6.0:
			delivery_message="客舍早餐已签收　+%d 枚　·　P 打开委托簿"%((8 if laurel_carried else 6)+(2 if market_open else 0)+(3 if table_inn else 0));delivery_time=5.
			if laurel_carried:laurel_income+=2;wind_wallet+=2;laurel_carried=false
			freight_route=0;bread_waiting=false;inn_runs+=1;wind_wallet+=6
			if table_inn:inn_regular_pay+=3;wind_wallet+=3
			if market_open:market_bonus+=2;wind_wallet+=2
			bread_case.hide();inn_table.show();file_postmarks();audio.play_cue("win")
			if resume_signed_after_bread:
				resume_signed_after_bread=false;stage="signed";update_shift_receipt();receipt.show()
			return
	if freight_route==3 and stage=="pickup":return
	if stage=="signed":
		if not returning: begin_return()
		elif not wind_job:
			strap_paid=false
			begin_wind()
		return
	if stage in ["porter_load","porter_drop"]:
		if porter.use():
			carry_from=freight.global_position
			stage="loading" if porter.loading else "unloading"
			duration=0.65
			handoff=0
			carry_to=truck.to_global(Vector3(-0.9,1.1,0)) if porter.loading else land.surface(porter.goal)+Vector3.UP*0.14
			porter.hide()
			porter.queue_free()
			porter=null
			audio.play_cue("load")
		return
	if stage not in ["pickup","drive"] or absf(speed)>0.65 or airborne: return
	var dest:=target()
	var dist:=rear().distance_to(dest)
	if not in_reach(dest):
		if returning and not wind_job and stage=="drive" and in_reach(Map.GROVE) and not rested:
			stage="rest"
			speed=0
			rest_time=0
			audio.play_cue("snap")
			return

		return
	delivered_at=dest
	walked=dist
	speed=0
	porter_time=0
	var taking:=stage=="pickup"
	exit_name="西风灯塔" if wind_job else ("月桂客舍" if returning else ("侧院" if dest==Map.SIDE else "正阶"))
	if taking:
		stage="porter_load"
		porter=preload("res://bay_porter.gd").new()
		add_child(porter)
		porter.begin(self,true,dest)
	else:
		stage="crane"
		quay_tip=0
		var point:=Vector2(180.65,-4.65) if dest==Map.STEPS else Vector2(186.85,5.6)
		if returning: point=Vector2(165.8,14.6) if wind_job else Vector2(3,10.7)
		crane=preload("res://quay_crane.gd").new()
		add_child(crane)
		crane.begin(self,point)
	audio.play_cue("page")

func jump()->void:
	if not spring.active and stage!="drive": return
	if not airborne:
		vy=5.8
		airborne=true
		wind_used=false
	elif reserve>0 and not wind_used:
		reserve-=1
		if wind_job: health=maxf(0,health-15)
		wind_used=true
		vy=maxf(vy,1.8)+4.6
	else: return
	audio.play_cue("wind")

func _input(event:InputEvent)->void:
	if stage!="drive" or catch_left<=0: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		slip_caught=true
		brace_time=BRACE_DURATION
		catch_left=0
		pending_hit=0
		load_velocity.y=0
		brace_travel=BRACE_DISTANCE
		audio.play_cue("grab")

func make_bread(n:Node3D,p:Vector3)->Node3D:
	var basket:=art.group(n,p)
	art.cyl(basket,Vector3.UP*.2,.35,.47,.41,"#a67948")
	for i in 4:art.ball(basket,Vector3((i%2-.5)*.32,.43,(i/2-.5)*.29),Vector3(.44,.25,.32),"#dba459",true)
	return basket

func chartered()->bool:
	return market_open and inn_runs>0 and bread_shipments>0

func produce()->void:
	if hearth_moved and not bread_waiting:bread_waiting=true;freight_route=0

func office_action(id:int)->void:
	if id==6:
		office.hide()
		if lamp_step==0 or grain_status==2:open_tide_dock(false,true)
		else:open_tide_dock(true,true)
		return
	if id==5:
		if not market_open and hearth_moved and inn_runs+bread_shipments>0 and wind_wallet>=12:
			wind_wallet-=12;market_open=true;file_postmarks();audio.play_cue("win")
		office.refresh(self);return
	if id==4:
		if bread_waiting and freight_route==2:
			office.hide();open_tide_dock(true);return
		if not bread_waiting or freight_route not in [1,3] or stage not in ["signed","pickup"] or is_instance_valid(porter):return
		if stage=="signed":resume_signed_after_bread=true;stage="pickup";receipt.hide()
		office.hide();board.hide()
		if freight_route==1:
			pos=WIND_DOCK-Vector2(2.5,0);heading=PI;camera_yaw=heading;speed=0;altitude=land.ground(pos);update_pose(1.)
		return
	if id in [1,2]:
		if bread_waiting and freight_route==0:freight_route=id;file_postmarks()
		office.refresh(self);return
	office.hide()
	if id==3:open_board();return
	if hearth_moved:open_tide_dock();return
	zephyr_selected=true;night_selected=false
	dock_order=preload("res://hearth_job.gd").new()
	dock_order.order_signed.connect(record_move);enter_harbour_job()

func record_move(level:int,pay:int,_heat:int,_route:String)->void:
	hearth_moved=true;port_return.relocated=true;port_return.apply(wind_level,wind_bell);wind_wallet+=pay;hot_pay+=18 if level==2 else 0;move_pay+=pay-(18 if level==2 else 0)
	if level==2:produce()
	file_postmarks()

func open_tide_dock(night:=false,commission:=false,from_bell:=false)->void:
	if is_instance_valid(dock_order) or stage not in ["pickup","signed"]: return
	board.hide()
	zephyr_selected=false
	night_selected=night
	dock_order=preload("res://lamp_night.gd").new() if night else preload("res://tide_dock.gd").new()
	dock_order.table_inn=table_inn;dock_order.table_crew=table_crew
	if night:
		dock_order.bell_boarding=from_bell;dock_order.letter_stage=bell_letter;dock_order.letter_progress.connect(record_bell_letter);dock_order.harbor_bell=bell_done;dock_order.harbor_song=bell_song
		dock_order.fruit_reserved=spring.night_stock;dock_order.fruit_sold_before=spring.night_sales>0;dock_order.fruit_signed.connect(spring.kiln_signed)
		dock_order.day_shift.connect(lamp_day_shift)
		dock_order.grain_status=grain_status;dock_order.grain_origin=grain_position;dock_order.helm_origin=grain_helm
		dock_order.saved_yaw=grain_heading;dock_order.barge_yaw=barge_heading;dock_order.barge_velocity=barge_velocity;dock_order.grain_bumps=grain_bumps;dock_order.mill_trade=wind_level>0
		dock_order.grain_progress.connect(record_grain_progress);dock_order.grain_signed.connect(record_grain_delivery)
		dock_order.mirror_built=quay_mirror;dock_order.available_funds=wind_wallet;dock_order.mirror_order.connect(order_quay_mirror);dock_order.paid_crossings=worker_runs;dock_order.board_at_quay=commission;dock_order.worker_aboard=worker_ticket;dock_order.worker_boarded.connect(record_worker_ticket);dock_order.oven_installed=hearth_moved;dock_order.has_market=market_open;dock_order.worker_signed=lamp_worker_home;dock_order.worker_home.connect(record_worker_home);dock_order.works=lamp_step;dock_order.works_changed.connect(save_lamp);dock_order.change_shift.connect(lamp_road_shift)
		dock_order.bread_fare=kiln_fare();dock_order.beacon_unlocked=north_beacon;dock_order.bread_loaded=bread_waiting and freight_route==2
		dock_order.basket_delivered.connect(record_basket)
	else:
		dock_order.meal_stock=meal_stock;dock_order.table_served.connect(record_table)
		dock_order.grain_arrived=grain_status==2;dock_order.tower_lit=north_beacon;dock_order.blue_focus=commission;dock_order.regular=lamp_worker_home;dock_order.blue_step=lamp_step;dock_order.take_watch.connect(start_lamp_watch)
		dock_order.lamp_unlocked=diver_lamp;dock_order.has_market=market_open;dock_order.has_bakery=hearth_moved;dock_order.has_loaf=bread_waiting
	enter_harbour_job()

func record_bell_letter(next:int)->void:
	if next!=bell_letter+1 or next>2:return
	bell_letter=next
	if next==2:wind_wallet+=5
	file_postmarks()

func save_lamp(value:int)->void:
	if value!=lamp_step+1:return
	lamp_step=value
	if value==3:
		road_quay.show();road_quay.animate(6.)
		if not bread_waiting:bread_waiting=true;freight_route=0
	file_postmarks()

func fade_quay_crossing()->void:
	if DisplayServer.get_name()=="headless":return
	var image:=get_viewport().get_texture().get_image()
	if image==null or image.is_empty():return
	var layer:=CanvasLayer.new();layer.layer=12;get_tree().root.add_child(layer)
	var still:=TextureRect.new();layer.add_child(still);still.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	still.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;still.mouse_filter=Control.MOUSE_FILTER_IGNORE;still.texture=ImageTexture.create_from_image(image)
	var tween:=layer.create_tween();tween.tween_property(still,"modulate:a",0.,.65);tween.tween_callback(layer.queue_free)

func start_lamp_watch()->void:
	fade_quay_crossing()
	return_from_tide_dock(0)
	if lamp_step==0:save_lamp(1)
	open_tide_dock(true)
	if lamp_step!=2 and not worker_ticket and grain_status!=1:dock_order.depart_blue_quay()

func lamp_day_shift()->void:
	fade_quay_crossing()
	return_from_tide_dock(dock_order.total if dock_order.stage=="signed" else 0)
	open_tide_dock(false,true)

func record_table(who:String)->void:
	if meal_stock<=0 or who not in ["inn","crew"]:return
	if (who=="inn" and table_inn) or (who=="crew" and table_crew):return
	if who=="inn":table_inn=true;inn_table.show()
	else:table_crew=true
	meal_stock-=1
	if table_inn and table_crew:road_quay.set_feast()
	file_postmarks()

func record_grain_progress(barge:Vector2,helm:Vector2,yaw:float,bumps:int,barge_yaw:float,velocity:Vector2)->void:
	if grain_status==2:return
	grain_status=1;grain_position=barge;grain_helm=helm;grain_heading=yaw;grain_bumps=bumps;barge_heading=barge_yaw;barge_velocity=velocity
	file_postmarks()

func record_grain_delivery(bumps:int)->void:
	if grain_status!=1:return
	grain_status=2;grain_bumps=bumps;grain_pay=12+maxi(0,6-2*bumps)+(6 if wind_level>0 else 0)
	wind_wallet+=grain_pay;meal_stock=1
	if not bread_waiting:bread_waiting=true;freight_route=0
	road_quay.grain_received();file_postmarks()

func can_board_at_road()->bool:
	return lamp_step==3 and stage in ["pickup","signed"] and not is_instance_valid(porter) and absf(speed)<1.5 and pos.distance_to(WIND_DOCK)<7.

func order_quay_mirror()->void:
	if quay_mirror or not lamp_worker_home or not bell_done or wind_wallet<6:return
	if not is_instance_valid(dock_order) or not dock_order.has_method("fit_mirror"):return
	quay_mirror=true;wind_wallet-=6;file_postmarks()
	dock_order.fit_mirror(wind_wallet)

func record_worker_ticket()->void:
	if worker_ticket:return
	worker_ticket=true;file_postmarks()
func record_worker_home()->void:
	if not worker_ticket:return
	worker_ticket=false;lamp_worker_home=true;worker_runs+=1;wind_wallet+=8;road_quay.seat_regular();file_postmarks()
	if is_instance_valid(dock_order):dock_order.available_funds=wind_wallet
func lamp_road_shift()->void:
	fade_quay_crossing()
	return_from_tide_dock(dock_order.total if dock_order.stage=="signed" else 0)
	if stage=="signed" and bread_waiting and freight_route in [0,1,3]:resume_signed_after_bread=true;receipt.hide();stage="pickup"
	pos=WIND_DOCK-Vector2(2.5,0);heading=PI;camera_yaw=PI;speed=0;altitude=land.ground(pos)
	if bread_waiting and freight_route==0:office_action(1);office.hide()
	delivery_message="船夫系好缆绳 · 东岸木阶到了";delivery_time=2.5
	update_pose(1.)

func open_westwind()->void:
	if is_instance_valid(dock_order) or stage not in ["pickup","signed"] or is_instance_valid(porter):return
	board.hide()
	zephyr_selected=true
	dock_order=preload("res://zephyr_job.gd").new()
	dock_order.wallet=wind_wallet
	dock_order.season=wind_runs
	dock_order.bakery_moved=hearth_moved
	dock_order.charter_branch=chartered()
	dock_order.prior_level=wind_level
	dock_order.bell_returned=wind_bell
	dock_order.previous_receipt=wind_receipt
	dock_order.rent_requested.connect(rent_hood)
	dock_order.order_signed.connect(record_westwind)
	enter_harbour_job()

func rent_hood()->void:
	if not zephyr_selected or dock_order.rented or dock_order.stage!="offer":return
	var cost:int=dock_order.HOOD_COST
	var paid:=wind_wallet>=cost
	if paid:wind_wallet-=cost;file_postmarks()
	dock_order.set_rented(paid,wind_wallet)

func kiln_fare()->int:
	return 8+(2 if market_open else 0)+(2 if lamp_worker_home and hearth_moved else 0)

func record_basket()->void:
	if not bread_waiting or freight_route!=2 or not night_selected or zephyr_selected:return
	bread_waiting=false;freight_route=0;bread_shipments+=1;wind_wallet+=8
	if lamp_worker_home and hearth_moved:lamp_supper_bonus+=2;wind_wallet+=2
	if market_open:market_bonus+=2;wind_wallet+=2
	file_postmarks()

func record_westwind(level:int,pay:int,charge:int,route:String)->void:
	if level==2 and not bread_waiting:bread_waiting=true;freight_route=0 if hearth_moved else 2
	produce()
	if grain_status==2:meal_stock=mini(int(not table_inn)+int(not table_crew),meal_stock+1)
	wind_bell=wind_bell or dock_order.chime_taken
	port_return.apply(level,wind_bell)
	wind_wallet+=pay;wind_level=level;wind_runs+=1;wind_last_charge=charge
	wind_receipt="%s　余风 %d　运费 %d 枚"%[route,charge,pay]
	file_postmarks()

func enter_harbour_job()->void:
	get_parent().add_child(dock_order)
	dock_order.left_dock.connect(return_from_tide_dock)
	title.get_parent().hide()
	hide()
	audio.bg.stream_paused=true
	process_mode=Node.PROCESS_MODE_DISABLED

func return_from_tide_dock(pay:int)->void:
	if pay>0 and not zephyr_selected:
		produce()
		wind_wallet+=maxi(0,pay-(night_best if night_selected else day_best))
		if night_selected:
			night_earnings=maxi(night_earnings,pay);night_best=maxi(night_best,pay)
			diver_lamp=diver_lamp or dock_order.states[1]==2
		else:
			dock_earnings=maxi(dock_earnings,pay);day_best=maxi(day_best,pay);north_beacon=true
		file_postmarks()
	var ferry_invited:bool=bell_selected and dock_order.take_ferry
	if bell_selected and dock_order.stage=="invite":
		bell_record={};file_postmarks()
	var show_port:bool=zephyr_selected and dock_order.assessed
	dock_order.hide()
	dock_order.set_process_unhandled_key_input(false)
	dock_order.queue_free()
	dock_order=null
	process_mode=Node.PROCESS_MODE_INHERIT
	show()
	title.get_parent().show()
	cam.current=true
	audio.bg.stream_paused=false
	update_ui()
	update_shift_receipt()
	if bell_selected:
		bell_selected=false
		if ferry_invited:call_deferred("open_tide_dock",true,false,true)
		else:call_deferred("open_board")
	if show_port and wind_level>0:port_view=4.6;port_talk=0.;port_return_tick(.016)

func port_return_tick(dt:float)->void:
	port_return.tick(dt)
	port_talk=maxf(0,port_talk-dt)
	if port_view>0:
		port_view=maxf(0,port_view-dt)
		var focus:=port_return.position+Vector3(0,2.48,-.7)
		var dir:=Vector3(-5.9,4.2,-8.6)
		var camera_goal:=Transform3D(Basis.looking_at(-dir,Vector3.UP),focus+dir)
		var blend:=smoothstep(0,.80,port_view)
		cam.transform=cam.transform.interpolate_with(camera_goal,blend)
	var nearby:=pos.distance_to(Vector2(12,11.7))<6.9 and absf(speed)<1.4
	port_caption.visible=not board.visible and (port_view>.23 or port_talk>0 or nearby and wind_level>0)
	if port_caption.visible:
		if hearth_moved:port_caption.text="粮站管事：「伊娅搬到潮汐船坞了，蓝棚里烤的是咱们磨坊的新粉。」" if port_talk>0 else "西湾粮站　·　磨坊供粉，送往船坞　 Q 听街坊说"
		elif port_talk>0:port_caption.text="伊娅：「第一炉给街坊。这一块带回路上。」" if wind_level==2 else "码头工：「起重机动了！下一船麦子赶得上潮水。」"
		elif port_view>.23:port_caption.text=("西湾回访　·　伊娅给冥河夜渡留了一篮面包" if wind_level==2 else "西湾回访　·　粮袋正从磨坊进港")+"　　 Q 听街坊说"
		else:port_caption.text="Q　和面包摊的街坊聊聊"

func _unhandled_key_input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if spring.active:
		if event.keycode==KEY_TAB or spring.chart.visible and event.keycode==KEY_ESCAPE:
			spring.chart.visible=not spring.chart.visible;spring.chart.queue_redraw()
			get_viewport().set_input_as_handled();return
		if spring.chart.visible:get_viewport().set_input_as_handled();return
		if event.keycode==KEY_E:spring.use()
		elif event.keycode==KEY_Q:
			if not spring.night_depart():spring.turn_cart()
		elif event.keycode==KEY_SPACE and not spring.testing and spring.transfer<=0.:jump()
		elif event.keycode==KEY_ESCAPE:
			spring.leave()
		get_viewport().set_input_as_handled();return
	if office.visible:
		match event.keycode:
			KEY_H:office_action(0)
			KEY_1:office_action(1)
			KEY_2:office_action(2)
			KEY_3:office_action(5)
			KEY_4:office_action(6)
			KEY_ENTER:office_action(4)
			KEY_ESCAPE,KEY_P:office_action(3)
		get_viewport().set_input_as_handled();return
	if board.visible:
		if event.keycode in [KEY_ENTER,KEY_KP_ENTER] and board.continuation.visible:
			book_select(8);get_viewport().set_input_as_handled();return
		match event.keycode:
			KEY_B:book_select(7)
			KEY_G:book_select(6)
			KEY_L:book_select(5)
			KEY_H:book_select(4)
			KEY_V:book_select(3)
			KEY_N:book_select(1)
			KEY_M:book_select(2)
			KEY_E:book_select(0);interact()
			KEY_ESCAPE,KEY_P,KEY_ENTER:book_select(0)
			KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT:board.hide()
			_:return
		get_viewport().set_input_as_handled();return
	match event.keycode:
		KEY_L:office_action(6)
		KEY_V:open_westwind()
		KEY_P:open_board()
		KEY_N: open_tide_dock()
		KEY_M: open_tide_dock(true)
		KEY_E: interact()
		KEY_B:
			if stage=="signed" and not returning:
				strap_paid=true
				begin_return()
		KEY_Q:
			if can_board_at_road():
				fade_quay_crossing();open_tide_dock(true,true);get_viewport().set_input_as_handled();return
			if wind_level>0 and not is_instance_valid(porter) and (port_view>0 or pos.distance_to(Vector2(12,11.7))<6.9):
				port_talk=3.5;audio.play_cue("page");return
			if is_instance_valid(porter) and porter.held: porter.rotate_load()
		KEY_TAB:
			if is_instance_valid(porter) and not porter.held:
				stage="pickup" if porter.loading else "drive"
				if not porter.loading:
					freight.reparent(truck,true)
					freight.position=Vector3(-0.9+load_offset.x,1.10,load_offset.y)
				porter.queue_free()
				porter=null
		KEY_SPACE:
			if stage=="crane": crane.release()
			else: jump()
		KEY_R:
			if stage=="rejected": retry_delivery()
			else: get_tree().reload_current_scene()

func clear_for(center:Vector2,yaw:float)->bool:
	var f:=Vector2(cos(yaw),-sin(yaw))
	var side:=f.orthogonal()*0.84
	for offset in [-2.35,0.0,2.35]:
		if not land.valid(center+f*float(offset)+side) or not land.valid(center+f*float(offset)-side): return false
	return true

func drive(dt:float,throttle:float,steer:float)->void:
	var f:=forward_dir()
	var side:=f.orthogonal()
	var incline:=land.ground(pos+f*0.5)-land.ground(pos-f*0.5)
	var bank:=land.ground(pos+side*0.5)-land.ground(pos-side*0.5)
	var old:=speed
	var prev_yaw:=heading
	var top:=9.8 if throttle>=0 else 3.8
	var accel:=10.0 if throttle*speed<0 else (5.0 if throttle!=0 else 3.8)
	speed=move_toward(speed,throttle*top*clampf(1-incline,0.52,1.15),dt*accel)
	var yaw:=heading-steer*clampf(speed/3.4,-1,1)*dt*(1.25 if not airborne else 0.46)
	var motion:=Vector2(cos(yaw),-sin(yaw))*speed*dt
	if spring.active and absf(speed)>5.:
		motion+=side*steer*spring.shower.wetness*clampf((absf(speed)-5.)*.21,0.,.95)*dt
	if clear_for(pos+motion,yaw):
		pos+=motion
		heading=yaw
	else:
		if absf(speed)>3.1:
			bumps+=1
			if stage=="drive": warn_damage("撞上障碍",absf(speed)*(0.95+0.065*absf(speed)))
			lean_v+=1.8
			audio.play_cue("bonk")
		speed=0
	var floor_y:=land.ground(pos)
	if airborne:
		vy-=13.0*dt
		altitude+=vy*dt
		if altitude<=floor_y:
			airborne=false
			altitude=floor_y
			if stage=="drive":
				warn_damage("重落地",maxf(0,-vy-6.0)*0.85)
				lean_v+=minf(2.8,absf(vy)*0.18)
			audio.play_cue("land")
	else: altitude=floor_y
	pitch=lerpf(pitch,clampf(atan(incline),-0.45,0.45),minf(1,dt*8))
	roll=lerpf(roll,clampf(-atan(bank)-steer*speed*0.012,-0.5,0.5),minf(1,dt*8))
	var force:=-bank*10.0-steer*speed*absf(speed)*0.12
	lean_v+=(force-32*lean-5.0*lean_v)*dt
	lean+=lean_v*dt
	lean=clampf(lean,-0.49,0.49)
	if stage=="drive":
		var roughness:=smoothstep(1.9,6.0,absf(pos.y-land.path_z(pos.x)))*smoothstep(8,14,pos.x)*(1.0-smoothstep(35,43,pos.x))
		if pos.x>146 and pos.x<160 and pos.y>5.5: roughness=0.92
		if pos.x>42 and pos.x<142:
			roughness=smoothstep(1.8,5.2,absf(pos.y-land.path_z(pos.x)))
		var exposure:=smoothstep(77,85,pos.x)*(1-smoothstep(108,117,pos.x))*smoothstep(-5,4,pos.y)
		var crosswind:=exposure*(3.8+2.8*sin(clock*2.1))*clampf(absf(speed)/5,0,1)
		var shake:=roughness*sin(pos.x*2.8+pos.y)*clampf(absf(speed)/8.2,0.0,1.3)
		var strain:=maxf(0,absf(speed)-5.2)*roughness*(absf(bank)+0.12)
		health=maxf(0,health-strain*dt*1.8)
		if returning and not wind_job:
			# Rough ground, sharp braking and cornering disturb the sleeper.
			var jolt:=absf(speed-old)/maxf(dt,0.001)+absf(speed*angle_difference(prev_yaw,heading))/maxf(dt,0.001)
			health=maxf(0,health-(maxf(0,jolt-5.5)*0.85+absf(shake)*0.55)*dt)
		for i in (0 if returning else 2):
			var jar: Node3D=freight.get_node("Amphora"+str(i))
			jar.rotation.x=lean*(0.40+i*0.09)+shake*(0.085+i*0.035)
			jar.rotation.z=shake*0.038+incline*0.12
		var yaw_rate:=angle_difference(prev_yaw,heading)/maxf(dt,0.001)
		var force_deck:=Vector2(-(speed-old)/maxf(dt,0.001)-9.8*incline,speed*yaw_rate-9.8*bank)
		force_deck.y+=crosswind*cos(heading)
		var assist_dt:=minf(dt,brace_time)
		if assist_dt>0 and brace_travel>0:
			force_deck.y*=0.20
			load_velocity=load_velocity.move_toward(Vector2.ZERO,6.0*assist_dt)
		slide_load(force_deck,dt)
		if assist_dt>0:
			var pull:=minf(brace_travel,minf(absf(load_offset.y),Catch.grip_step(assist_dt)))
			load_offset.y=move_toward(load_offset.y,0,pull)
			brace_travel-=pull
			brace_time=maxf(0,brace_time-dt)
		if wind_job and not gate_passed and absf(pos.x-154)<1.3 and absf(pos.y-9)<2.65 and wind_used and altitude-floor_y>0.5:
			gate_passed=true
			audio.play_cue("win")
		freight.position=Vector3(-0.9+load_offset.x,1.10,load_offset.y)
		freight.rotation.x=-lean*0.48
		freight.rotation.z=lerpf(freight.rotation.z,clampf((speed-old)*0.24,-0.12,0.12),minf(1,dt*10))
	for wheel in get_tree().get_nodes_in_group("wheels"): wheel.rotation.z-=speed*dt*1.3

func warn_damage(reason:String,loss:float)->void:
	if loss<=0: return
	if bell_padding:loss*=.80;reason+=" · 钟毡缓冲"
	health=maxf(0,health-loss)
	if loss>=0.5:
		rail_loss=roundi(loss)
		last_warning=reason
		impact_time=1.05

func reset_slip()->void:
	slip_caught=false
	slip_side=0
	catch_left=0
	calm_time=0
	pending_hit=0

func track_slip(force:float,grip:float,dt:float)->void:
	var v:=load_velocity.y
	var side:=int(signf(v))
	var remaining:=RAIL.y-load_offset.y*side
	var pushing:float=force*slip_side
	if slip_side!=0:
		if catch_left>0:
			catch_left=maxf(0,catch_left-dt)
			if catch_left<=0 and pending_hit>0:
				rail_impact(pending_hit)
				pending_hit=0
		var settled:=absf(v)<0.16 and pushing<grip
		calm_time=calm_time+dt if settled else 0.0
		if brace_time<=0 and (calm_time>0.25 or v*slip_side< -0.30):
			if pending_hit>0 and catch_left>0: return
			reset_slip()
	if slip_side!=0 or side==0 or absf(speed)<0.5: return
	var outward_accel:=maxf(0,force*side-grip*0.81)
	if Catch.reaches_rail(remaining,absf(v),outward_accel,.38):
		slip_side=side
		catch_left=CATCH_WINDOW
		audio.play_cue("buckle")

func rail_impact(impact:float)->void:
	if impact<=1.05: return
	rail_hits+=1
	warn_damage("撞栏",clampi(roundi((impact-0.75)*1.65),1,10))
	lean_v+=signf(load_offset.y)*minf(2,impact*0.38)
	audio.play_cue("bonk")

func slide_load(accel:Vector2,dt:float)->void:
	var impact:=0.0
	for axis in 2:
		var force:=clampf(accel[axis],-22,22)
		var v:=load_velocity[axis]
		var grip:=(6.3 if axis==0 else 4.2)*(2.15 if strap_paid else (0.8 if wind_job else 1.0))
		if axis==1:
			grip+=2.2*(1-smoothstep(3.5,5.8,absf(speed)))
			track_slip(force,grip,dt)
			if slip_caught and force*slip_side>0: grip*=2.0
		if absf(v)<0.025 and absf(force)<grip:
			load_velocity[axis]=0
			continue
		# Integrate applied force, then let dry friction stop the load where it lies.
		v=move_toward(v+force*dt,0.0,grip*0.81*dt)
		var place:=load_offset[axis]+v*dt
		if absf(place)>=RAIL[axis] and signf(v)==signf(place):
			place=signf(place)*RAIL[axis]
			if axis==1 and catch_left>0 and signf(v)==slip_side:
				pending_hit=maxf(pending_hit,absf(v))
			else:
				impact=maxf(impact,absf(v))
			v=0
		load_offset[axis]=place
		load_velocity[axis]=v
	rail_impact(impact)

func load_state()->String:
	if impact_time>0: return last_warning+" −%d" % rail_loss
	if catch_left>0 or brace_time>0: return Catch.instruction(catch_left,brace_time)
	if pos.x>81 and pos.x<113 and pos.y>1 and absf(speed)>4: return "横风 · 向背风侧收线"
	if absf(speed)>5.4 and pos.x>146 and pos.x<160 and pos.y>5.5:
		return "石堤颠簸 · 松油"
	if returning and not wind_job and absf(lean)>0.30: return "睡神翻身 · 放缓转向"
	return ""

func update_pose(dt:float)->void:
	var previous_pose:=cam.transform
	truck.position=Vector3(pos.x,altitude+0.08,pos.y)
	truck.rotation=Vector3(roll,heading,pitch)
	camera_yaw=lerp_angle(camera_yaw,heading,minf(1,dt*3.5))
	var ahead:=Vector3(cos(camera_yaw),0,-sin(camera_yaw))
	var focus:=Vector3(pos.x,land.ground(pos)+0.9,pos.y)
	var bakery_run:=bread_waiting and freight_route in [1,3] and stage=="pickup"
	var framed:=not bakery_run and (stage in ["loading","unloading","signed","porter_load","porter_drop"] or (stage=="pickup" and rear().distance_to(target())<10))
	view_blend=move_toward(view_blend,1.0 if framed else 0.0,dt*1.8)
	var flank:=Vector3(-ahead.z,0,ahead.x)
	cam.position=focus-ahead*lerpf(10.8,8.5,view_blend)+flank*6.6*view_blend+Vector3.UP*lerpf(7.1,8.7,view_blend)
	var look:=focus+ahead*3.5
	if framed:
		look=look.lerp((truck.global_position+freight.global_position)*0.5+Vector3.UP*0.8,view_blend)
	if bakery_run:
		var quay_weight:=1.-smoothstep(6.,20.,pos.distance_to(WIND_DOCK))
		var dock_look:=truck.position+Vector3(-.8,1.05,0)
		cam.position=cam.position.lerp(dock_look+Vector3(2.7,9.6,9.5),quay_weight)
		look=look.lerp(dock_look,quay_weight)
	var mode:="road"
	if is_instance_valid(porter) or stage in ["loading","unloading"]:
		mode="porter"
		# Look through the open face of each depot, independently of the parked truck.
		var offset:=Vector3(5.0,12.5,-8.0)
		if returning and not wind_job: offset=Vector3(-5.0,12.5,8.0)
		var subject:Vector3=porter.follow_anchor if is_instance_valid(porter) else freight.global_position
		look=truck.global_position.lerp(subject,0.78)+Vector3.UP*0.65
		cam.position=look+offset
	elif stage=="crane":
		mode="crane"
		var mid:Vector3=(crane.start+crane.pad)*0.5
		var side:Vector3=crane.axis.cross(Vector3.UP)
		var subject:Vector3=mid.lerp(freight.global_position,0.48).lerp(crane.pad,0.20)
		if shot_mode!=mode: hook_focus=subject
		hook_focus=hook_focus.lerp(subject,1-exp(-8.0*dt))
		look=hook_focus+Vector3.UP*0.8
		cam.position=look+(side*0.82+Vector3.UP*0.85)*(9.0+crane.length*0.45)
	cam.look_at(look)
	if mode!=shot_mode:
		shot_mode=mode
		shot_from=previous_pose
		shot_blend=0
	if shot_blend<1:
		shot_blend=minf(1,shot_blend+dt/0.46)
		cam.transform=shot_from.interpolate_with(cam.transform,smoothstep(0,1,shot_blend))

	if is_instance_valid(porter): porter.cutaway.update(cam,porter.courier)

func update_ui()->void:
	wear.update(freight,"sack" if wind_job else ("couch" if returning else "wine"),health)
	if board.visible and stage not in ["pickup","signed"]:board.hide()
	catch_strap.visible=stage=="drive" and (catch_left>0 or brace_time>0)
	if catch_strap.visible:
		catch_strap.position=Vector3(-0.9+load_offset.x,1.68,slip_side*1.14)
		catch_strap.scale.y=1.0+0.35*(1.0-catch_left/CATCH_WINDOW) if catch_left>0 else 0.92
		buckle.scale=Vector3.ONE*(1+0.38*sin(PI*catch_left/CATCH_WINDOW))
	var zone:="酒庄" if pos.x<7 else ("葡萄园" if pos.x<42 else ("岬角山道" if pos.x<145 else ("西湾石桥" if pos.x<161 else "神庙集市")))
	title.text="灯塔末班   /   "+zone if wind_job else ("月桂归客" if returning else "西湾酒单")+"   /   "+zone
	controls.text="WASD 搬运工移动    E 抬起 / 放下 / 交接    Q 转货    Tab 回车调整停车" if is_instance_valid(porter) else "W 加速    S 刹车 / 倒车    A D 转向    空格 跳 / 空中借风    E 下车交接    R 重试"
	day_button.visible=stage in ["pickup","signed"];night_button.visible=day_button.visible;book_button.visible=day_button.visible and not is_instance_valid(porter)
	day_button.text="N　潮汐船坞"+("　%d 枚"%dock_earnings if dock_earnings>0 else "　日班")
	night_button.text="M　冥河渡客"+("　%d 枚"%night_earnings if night_earnings>0 else "　夜班")
	if stage=="drive": controls.text="W / S 油门与刹车    A / D 转向    空格 跳    绑带绷紧时点左键    E 交接"
	if stage=="crane": controls.text="A D 移吊车    观察风带和货影    空格脱钩 · 瞄准绿垫中心"
	var state:=""
	info.visible=stage in ["pickup","drive"]
	tag.hide()
	if bread_waiting and freight_route in [1,3] and stage=="pickup":
		title.text="月桂客舍早餐　/　"+zone
		var stop:=WIND_DOCK if freight_route==1 else Map.LODGE
		info.text=("东岸码头取货" if freight_route==1 else "月桂客舍")+"　·　"+bearing_hint(stop)
		controls.text="W S 驾驶　 A D 转向　 E 停车交接　 P 委托簿"
		return
	match stage:
		"pickup","drive":
			var at:=target()
			var place:="酒庄取货" if stage=="pickup" else ("侧院交酒" if at==Map.SIDE else "正阶交酒")
			if returning: place="集市取榻" if stage=="pickup" else "月桂客舍"
			if wind_job: place="客舍取风" if stage=="pickup" else "西风灯塔"
			info.text=place+" · "+bearing_hint(at) if stage=="pickup" or rear().distance_to(at)<24 else ("回程到月桂客舍，途中可在静风亭歇脚" if returning else "送往红顶神庙 · 正阶或侧院签收")
			if wind_job and stage=="drive" and rear().distance_to(at)>=24: info.text="前往灯塔 · 石堤金门内借风可赚 22 枚，消耗 15 点余风"
			if stage=="drive":
				state=load_state()
				var bend:=road_hint()
				if not bend.is_empty(): info.text=bend
			if wind_job and gate_passed and state=="": state="乘风赏金 +22"
			if in_reach(at):
				var action:="E 下车搬货" if stage=="pickup" else "E 挂钩卸货"
				state=action if absf(speed)<=0.65 and not airborne else "停稳后交接"
			elif returning and not wind_job and stage=="drive" and not rested and in_reach(Map.GROVE):
				state="静风亭 · 停稳按 E 歇脚"
			elif airborne and reserve>0: state="空格 · 再借一次风"
		"porter_load","porter_drop": state=porter.prompt()
		"crane": state=crane.hint
		"loading": state="正在装车"
		"unloading": state="正在签收"
		"rest": state="歇脚中 · 安眠恢复"
		"signed","rejected": return
	if stage!="pickup" or rear().distance_to(target())<12:
		tag.set_balance(stage=="drive" and Catch.show_balance(load_offset.y/RAIL.y,catch_left,brace_time),load_offset.y/RAIL.y)
		tag.modulate.a=move_toward(tag.modulate.a,0.58 if stage=="drive" and state=="" else 1.0,0.12)
		var worker_rect:=Rect2()
		if is_instance_valid(porter):
			var soles:Vector2=cam.unproject_position(porter.courier.global_position)
			var crown:Vector2=cam.unproject_position(porter.courier.global_position+Vector3.UP*2.1)
			worker_rect=Rect2(soles,Vector2.ZERO).expand(crown).grow(22)
		tag.follow(cam,freight.global_position+Vector3.UP*1.5,condition_name()+" · "+condition_grade(),health,state,impact_time>0 or catch_left>0,worker_rect)

func _physics_process(dt:float)->void:
	if office.visible:return
	clock+=dt
	traffic.tick(self,dt)
	impact_time=maxf(0,impact_time-dt)
	if (spring.active and not spring.testing and spring.transfer<=0. and spring.turnaround<=0. and not spring.chart.visible) or (not spring.active and stage in ["pickup","drive"]):
		var gas:=float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))-float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
		var turn:=float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		drive(dt,gas,turn)
		if not spring.active and freight_route==3 and bread_waiting and pos.distance_to(bread_checkpoint)>9.:file_postmarks()
		if stage=="drive": elapsed+=dt
	elif stage in ["porter_load","porter_drop"]:
		porter_time+=dt
		var axis:=Vector2(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W)))
		porter.move(dt,axis)
	elif stage=="crane":
		var axis:=float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		if crane.tick(dt,axis):
			quay_tip=6 if crane.gentle else 0
			warn_damage("硬地冲击",crane.damage)
			landing_note=("正中软垫" if crane.gentle else "偏心 %.1f 米 · 冲击 −%.1f" % [crane.alignment,crane.damage])+"\n"
			freight.rotation.z=0
			crane.queue_free()
			crane=null
			audio.play_cue("load" if quay_tip else "drop")
			audio.set_scene("yard")
			sign_order()
	elif stage=="rest":
		rest_time+=dt
		health=minf(100,health+6.0*dt)
		if rest_time>=2:
			rested=true
			stage="drive"
			audio.play_cue("snap")
	elif stage in ["loading","unloading"]:
		handoff+=dt
		var u:=clampf(handoff/duration,0,1)
		freight.global_position=carry_from.lerp(carry_to,smoothstep(0,1,u))+Vector3.UP*sin(u*PI)*0.7
		if u>=1:
			if stage=="loading":
				freight.reparent(truck,true)
				freight.position=Vector3(-0.9,1.10,0)
				freight.rotation=Vector3(0,PI/2,0)
				brace_time=0
				reset_slip()
				departure=pos
				departure_heading=heading
				landing_note=""
				stage="drive"
				audio.set_scene("road")
			else:
				sign_order()
				audio.set_scene("yard")
			audio.play_cue("load" if stage=="drive" else "win")
	if stage=="drive" and grade()==0: reject_order()
	update_pose(dt)
	if port_view>0 and (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S)):port_view=0.
	port_return_tick(dt)
	if bread_waiting and freight_route in [1,3] and not office.visible and not board.visible:
		var stop:=WIND_DOCK if freight_route==1 else Map.LODGE
		port_caption.visible=pos.distance_to(stop)<6.
		port_caption.text="E 停车接走东岸面包" if freight_route==1 else "E 停车交付客舍早餐"
	if freight_route==3 and not laurel_carried and pos.distance_to(Map.GROVE)<18.:
		port_caption.visible=true;port_caption.text="静风亭有新鲜月桂叶　·　停稳 E 顺取，客舍多付 2 枚"
	if can_board_at_road() and not board.visible and not office.visible:
		port_caption.text=(port_caption.text+"　·　" if port_caption.visible else "")+"Q 登上夜船";port_caption.show()
	if delivery_time>0:
		delivery_time=maxf(0,delivery_time-dt);port_caption.visible=true;port_caption.text=delivery_message
	update_ui()
	update_stations()
	spring.tick(dt)
