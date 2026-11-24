extends Node3D

signal left_dock(earnings:int)
const Porter=preload("res://bay_porter.gd")
const CELL_SPACING:=2.0
const Workshop=preload("res://workshop.gd")
const DockArt=preload("res://tide_art.gd")
const PLATE:=Vector2i(3,2)
const GATE:=Vector2i(5,4)
const DOCK:=Vector2i(7,4)
const SPARE:=Vector2i(7,2)
const HELM:=Vector2i(7,5)
const LOCK:=Vector2(144,-3)
const BERTH:=Vector2(186,-3)
const MIRRORS:=[Vector2(2,0),Vector2(2,-4.5)]
const ROUGH_START:=78.0
const ROUGH_END:=117.0
const BLOCKED:Array[Vector2i]=[Vector2i(5,0),Vector2i(5,1),Vector2i(5,2),Vector2i(5,3),Vector2i(5,5),Vector2i(5,6),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(2,5),Vector2i(2,6)]
const REEFS:Array[Vector3]=[Vector3(48,2.6,8.7),Vector3(84,3.1,-11.3),Vector3(99,4.7,0.9),Vector3(116,2.1,8.4),Vector3(122,2.4,-11.2)]
var art:=Workshop.new()
var design:=DockArt.new()
var craft:=preload("res://coastal_craft.gd").new()
var nearby=preload("res://freight_tag.gd").new()
var wear:=preload("res://cargo_wear.gd").new()
var sound=preload("res://sound.gd").new()
var cam:=Camera3D.new()
var depot:=Node3D.new()
var coast:=Node3D.new()
var hill:=preload("res://tide_hill.gd").new()
var sun:=DirectionalLight3D.new()
var hill_entry_hp:=100.0
var chamber:=Node3D.new()
var courier:Node3D
var lens_cart:Node3D
var weight_cart:Node3D
var jewel:Node3D
var ballast:Node3D
var ferry:Node3D
var truck:Node3D
var shipman:Node3D
var goal_marker:Node3D
var weight_marker:Node3D
var dive:Node3D
var rescue_fee:=0
var lamp_unlocked:=false
var recovered_seal:Node3D
var parcels:Array[Node3D]=[]
var parcel_points:Array[Vector2]=[Vector2(71,-16),Vector2(106,9)]
var retrieved:Array[bool]=[false,false]
var mirrors:Array[Node3D]=[]
var beams:Array[Node3D]=[]
var receiver:Node3D
var bell:Node3D
var podium:Node3D
var stage:="depot"
var player_cell:=Vector2i(1,3)
var lens_cell:=Vector2i(3,4)
var weight_cell:=Vector2i(2,2)
var lens_loaded:=false
var spare_loaded:=false
var gate_latched:=false
var gate_open:=0.0
var step_left:=0.0
var depot_speed:=Porter.WALK_SPEED
var history:Array[Dictionary]=[]
var steps:=0
var sail_pos:=Vector2(23,8)
var yaw:=0.0
var speed:=0.0
var sail_up:=true
var sail_fraction:=1.0
var heel:=0.0
var side_drift:=0.0
var condition:=100.0
var impact_wait:=0.0
var passed_arch:=false
var short_channel:=false
var time:=0.0
var crossing_time:=0.0
var phase_time:=0.0
var level:=0.0
var flow:=0.0
var valve:=0.0
var lock_open:=false
var checkpoint_taken:=false
var checkpoint:Dictionary={}
var mirror_index:Array[int]=[1,1]
var keeper:=Vector2(-2,1.6)
var sea_bell:=false
var light_on:=false
var beam_key:=""
var total:=0
var notice:=""
var notice_left:=0.0
var title:=Label.new()
var subtitle:=Label.new()
var action:=Label.new()
var controls:=Label.new()
var cargo_label:=Label.new()
var receipt:=Label.new()
var world_font:=preload("res://harbour_fonts.gd").body()
var transition_start:=Transform3D.IDENTITY
var camera_blend:=1.0
var camera_focus:=Vector3.ZERO
var camera_initialized:=false
var ledger_parent:=0
var seen_helm:=false

signal take_watch
var harbour_charter:=preload("res://lamp_charter.gd").new()
var quay_talk:=0.
var tower_lit:=false
var grain_arrived:=false
var blue_focus:=false
var regular:=false
signal table_served(who:String)
var meal_camera:=0.
var feast_view:=0.
var public_quay:Node3D
var meal_stock:=0
var table_inn:=false
var table_crew:=false
var community:Node3D
var blue_step:=0
var has_market:=false
var has_bakery:=false
var has_loaf:=false
func _ready()->void:
	add_child(depot);add_child(coast);add_child(chamber)
	add_child(sound)
	add_child(cam)
	cam.current=true
	cam.fov=52
	var env:=Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky:=ProceduralSkyMaterial.new()
	sky.sky_top_color=Color("#4f91c1")
	sky.sky_horizon_color=Color("#bbd6dc")
	sky.ground_horizon_color=Color("#bed2c6")
	env.sky=Sky.new()
	env.sky.sky_material=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("#e2dfcc")
	env.ambient_light_energy=0.53
	env.ssao_enabled=true;env.ssao_radius=1.35;env.ssao_intensity=1.55
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.fog_enabled=true
	env.fog_density=0.003
	env.fog_light_color=Color("#afc9cc")
	cam.environment=env
	sun.rotation_degrees=Vector3(-52,-36,0)
	sun.light_color=Color("#ffead0");sun.light_energy=1.12
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=94
	add_child(sun)
	design.build_depot(depot,BLOCKED)
	design.build_coast(coast,REEFS)
	# The landing sits beyond the puzzle grid and is visible from the walking camera.
	var landing:=Vector3(3.1,.04,14.45)
	art.box(depot,landing-Vector3.UP*.34,Vector3(6.85,.63,3.05),"#af9b77")
	for j in 15:
		art.box(depot,landing+Vector3((j-7)*.45,0,0),Vector3(.434,.15,3.02),"#b39870" if j%3 else "#c2a780")
	for dx in [-3.12,3.12]:
		art.cyl(depot,landing+Vector3(dx,-.48,1.35),.18,.23,2.02,"#6b5a48")
	if has_bakery and blue_step!=3:
		var stall:=art.group(depot,landing+Vector3(.63,.08,-.06))
		var oven:=preload("res://hearth_art.gd").new();oven.build(stall);oven.glow(88,0)
		craft.cloth(stall,Vector3(0,3.24,-.90),3.4,"#316a83")
		for dx in [-1.52,1.52]:
			art.beam(stall,Vector3(dx,0,-.68),Vector3(dx,3.28,-.68),.073,"#876547")
		var baker:=art.courier(stall);baker.position=Vector3(1.1,0,.6);preload("res://zephyr_people.gd").new().costume(baker,"baker")
		text_world(stall,Vector3(0,3.85,0),"伊娅的蓝棚灶台","#fff0cc")
		if has_market:
			var counter:=art.group(stall,Vector3(-1.65,0,.46))
			art.box(counter,Vector3.UP*.49,Vector3(1.45,.98,.68),"#816149")
			art.box(counter,Vector3.UP*1.01,Vector3(1.60,.10,.77),"#dcb47e")
			for i in 6:art.ball(counter,Vector3((i%3-1)*.4,1.15,(i/3-.5)*.32),Vector3(.45,.23,.29),"#d59953",true)
			text_world(counter,Vector3(0,1.76,0),"西湾晨市","#ffe3a4")
			var customer:=art.courier(stall)
			customer.position=Vector3(-2.1,0,1.12)
			customer.rotation.y=PI*.84
			preload("res://zephyr_people.gd").new().costume(customer,"priest")
			customer.scale=Vector3.ONE*.92
		if has_loaf:for j in 3:art.ball(stall,Vector3(j*.30,1.23,.35),Vector3(.4,.24,.29),"#ca9451",true)
	if blue_step==3:
		var lamps:=preload("res://lamp_quay.gd").new();depot.add_child(lamps);lamps.position=landing;lamps.oven_installed=has_bakery;lamps.build(true)
		public_quay=lamps
		if table_inn and table_crew:lamps.set_feast()
		if regular:lamps.seat_regular()
		if grain_arrived:lamps.grain_received()
		if has_market:lamps.breakfast_stall(has_loaf)
	else:
		var sign_at:=landing+Vector3(1.85,0,.22)
		art.column(depot,sign_at,1.65)
		text_world(depot,sign_at+Vector3.UP*2.0,"收市 · 夜船缺引灯","#ffe4a7")
		var shift_worker:=art.courier(depot);shift_worker.position=landing+Vector3(2.2,.1,.72)
		if not has_bakery:
			var visitor:=art.courier(depot);visitor.position=landing+Vector3(-.6,.12,.28)
			preload("res://zephyr_people.gd").new().costume(visitor,"baker")
			art.crate(depot,landing+Vector3(-1.6,.12,.65),.76)
	craft.boathouse(depot);craft.coast(coast)
	build_cargo()
	if grain_arrived:
		community=preload("res://quay_breakfast.gd").new();depot.add_child(community)
		community.build(self);community.refresh(meal_stock,table_inn,table_crew)
	coast.add_child(hill)
	hill.hit.connect(hill_impact);hill.cargo_cue.connect(sound.play_cue)
	hill.arrived.connect(hill_arrive)
	hill.post_marked.connect(func():sound.play_cue("win"))
	build_chamber()
	build_interface()
	reset_depot()
	update_camera(1)
	update_ui()

func build_cargo()->void:
	courier=art.courier(depot)
	courier.scale=Vector3.ONE*0.92
	lens_cart=design.cart(depot)
	weight_cart=design.cart(depot)
	jewel=design.lens(lens_cart)
	ballast=design.ballast(weight_cart)
	jewel.position.y=0.31
	ballast.position.y=0.27
	design.socket(depot,cell_world(PLATE),DockArt.BRASS)
	goal_marker=design.socket(depot,cell_world(DOCK),DockArt.SIGNAL)
	weight_marker=design.socket(depot,cell_world(SPARE),DockArt.BRASS)
	var bollard:=art.cyl(depot,cell_world(HELM)+Vector3.UP*0.35,0.38,0.28,0.7,DockArt.BLUE)
	art.ring(bollard.get_parent(),cell_world(HELM)+Vector3.UP*0.75,0.31,0.06,DockArt.BRASS)
	ferry=design.make_ferry(coast)
	truck=art.truck(ferry)
	truck.position=Vector3(-1.45,0.07,0)
	truck.scale=Vector3.ONE*0.74
	truck.get_node("Driver").hide()
	shipman=art.courier(ferry)
	shipman.position=Vector3(3.45,0.09,0.36)
	shipman.scale=Vector3.ONE*0.83
	shipman.rotation.y=PI/2
	shipman.hide()
	for pos in parcel_points:
		var n:=art.group(coast,Vector3(pos.x,-0.4,pos.y))
		art.box(n,Vector3.ZERO,Vector3(1.65,0.25,1.39),Workshop.WOOD)
		var box:=art.crate(n,Vector3.UP*0.12,0.94)
		art.ring(box,Vector3.UP*0.91,0.3,0.055,DockArt.BRASS)
		design.flag(n,Vector3(-0.6,0,-0.37),DockArt.SIGNAL)
		parcels.append(n)

	recovered_seal=design.lens(truck)
	recovered_seal.scale=Vector3.ONE*0.53
	recovered_seal.position=Vector3(-1.82,1.07,0.42)
	recovered_seal.hide()
	text_world(parcels[0],Vector3.UP*3.1,"沉库潜水钟",Color("#c5f0dc"),0.014)
	var bell_shell:=art.cyl(parcels[0],Vector3(0,0.77,0),0.86,0.58,1.25,DockArt.BRASS)
	art.ball(parcels[0],Vector3(0,1.43,0),Vector3(1.20,0.66,1.20),DockArt.BRASS)
	var eye:=art.ring(parcels[0],Vector3(0,0.89,0.73),0.22,0.045,DockArt.INK)
	eye.rotation.x=PI/2

func cell_world(c:Vector2i)->Vector3: return Vector3(c.x*CELL_SPACING,0,c.y*CELL_SPACING)

func text_world(p:Node3D,pos:Vector3,words:String,color:Color,scale_px:=0.009)->Label3D:
	var label:=Label3D.new()
	label.text=words
	label.font=world_font
	label.font_size=26
	label.pixel_size=scale_px
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size=5
	label.outline_modulate=Color("#173b40")
	label.modulate=color
	label.position=pos
	p.add_child(label)
	return label

func build_chamber()->void:
	chamber.position=Vector3(208.0,15.05,46)
	art.cyl(chamber,Vector3.DOWN*0.48,8.6,8.5,0.96,DockArt.STONE,36)
	var terrazzo:=art.cyl(chamber,Vector3.DOWN*0.045,8.35,8.35,0.16,DockArt.SALT,36)
	terrazzo.material_override=preload("res://harbour_materials.gd").sample(2,"#dfc9a1",4.9,true,.55)
	art.ring(chamber,Vector3.UP*0.018,6.8,0.055,DockArt.BRASS)
	for i in 9:
		var ang:=lerpf(PI,TAU,i/8.0)
		var foot:=Vector3(7.9*cos(ang),0,7.9*sin(ang))
		art.column(chamber,foot,3.4)
		if i%2==0: design.light_stone(chamber,foot+Vector3.UP*3.66,Vector3.ONE*0.5,DockArt.SIGNAL)
	podium=art.group(chamber,Vector3(-4.4,0,0))
	art.cyl(podium,Vector3.UP*0.53,0.79,0.60,1.06,DockArt.BLUE)
	for point:Vector2 in MIRRORS:
		var base:=Vector3(point.x,0,point.y)
		art.cyl(chamber,base+Vector3.UP*0.31,0.74,0.64,0.62,DockArt.BLUE)
		art.ring(chamber,base+Vector3.UP*0.65,0.65,0.058,DockArt.BRASS)
		var hinge:=art.group(chamber,base+Vector3.UP*1.39)
		art.cyl(hinge,Vector3.DOWN*0.30,0.13,0.13,1.3,DockArt.BRASS)
		art.box(hinge,Vector3.ZERO,Vector3(1.38,1.26,0.15),DockArt.BRASS)
		art.box(hinge,Vector3(0,0,0.096),Vector3(1.19,1.08,0.06),"#b4dbdd")
		mirrors.append(hinge)
	receiver=art.group(chamber,Vector3(6.1,0,-4.5))
	art.cyl(receiver,Vector3.UP*0.65,0.68,0.52,1.3,DockArt.SALT)
	design.light_stone(receiver,Vector3.UP*1.52,Vector3.ONE*0.74,DockArt.BRASS)
	bell=art.group(chamber,Vector3(2,0,4.6))
	art.cyl(bell,Vector3.UP*0.72,0.48,0.39,1.44,DockArt.BLUE)
	art.cyl(bell,Vector3.UP*1.55,0.61,0.28,0.69,DockArt.BRASS)
	for i in 3:
		var b:=art.cyl(chamber,Vector3.ZERO,0.052,0.052,1,DockArt.SIGNAL)
		b.material_override=design.glow(DockArt.SIGNAL)
		beams.append(b)
	text_world(chamber,receiver.position+Vector3.UP*2.4,"主灯",Color("#ffe3ac"))
	text_world(chamber,bell.position+Vector3.UP*2.4,"雾钟",Color("#ffe3ac"))
	for i in 2: text_world(chamber,mirrors[i].position+Vector3.UP*0.92,"Ⅰ" if i==0 else "Ⅱ",Color("#ffdf96"))
	chamber.hide()

func panel(label:Label,size:int,color:String,bg:String)->void:
	label.add_theme_font_override("font",world_font)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color(color))
	var b:=StyleBoxFlat.new()
	b.bg_color=Color(bg)
	b.set_corner_radius_all(7)
	b.content_margin_left=14;b.content_margin_right=14
	b.content_margin_top=6;b.content_margin_bottom=6
	label.add_theme_stylebox_override("normal",b)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE

func build_interface()->void:
	var layer:=CanvasLayer.new();layer.add_child(harbour_charter)
	add_child(layer);layer.add_child(nearby);nearby.build(world_font);nearby.hide()
	for label in [title,subtitle,action,controls,cargo_label,receipt]: layer.add_child(label)
	panel(title,23,"#ffebc3","#193b44f4")
	panel(subtitle,16,"#f6efdd","#214650f0")
	panel(action,19,"#fff2c9","#203b43ed")
	panel(controls,16,"#f4e3bc","#19383fe8")
	panel(cargo_label,17,"#b4e8d3","#1a3c41ee")
	panel(receipt,23,"#fff1ce","#173b45fb")
	title.position=Vector2(26,22);subtitle.position=Vector2(26,72)
	controls.position=Vector2(26,652)
	cargo_label.position=Vector2(1040,22)
	action.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	receipt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	receipt.position=Vector2(345,157)
	receipt.custom_minimum_size.x=590
	receipt.hide()
	text_world(depot,cell_world(PLATE)+Vector3.UP*0.75,"配重压盘",Color("#ffd487"))
	text_world(depot,cell_world(DOCK)+Vector3.UP*1.5,"镜芯装船",Color("#99eed4"))
	text_world(depot,cell_world(SPARE)+Vector3.UP*0.82,"压舱位",Color("#ffd487"))
	text_world(depot,cell_world(HELM)+Vector3.UP*1.35,"系缆柱",Color("#fff0c2"))
	text_world(coast,Vector3(65,6.6,0),"旧引水渠",Color("#ffebbc"),0.015)
	text_world(coast,Vector3(143,6.0,-3),"潮汐升船闸",Color("#ffebbc"),0.015)
	text_world(coast,Vector3(185,6.0,-3),"北岬泊位",Color("#ffebbc"),0.014)

func reset_depot()->void:
	stage="depot";phase_time=0
	hill.active=false
	if truck.get_parent()!=ferry: truck.reparent(ferry,false)
	truck.position=Vector3(-1.45,0.07,0);truck.rotation=Vector3.ZERO;truck.scale=Vector3.ONE*0.74
	truck.get_node("Driver").hide()
	jewel.rotation=Vector3.ZERO
	player_cell=Vector2i(1,3);lens_cell=Vector2i(3,4);weight_cell=Vector2i(2,2)
	rescue_fee=0;recovered_seal.hide()
	if community!=null:community.stop_lift();community.return_basket(meal_stock,table_inn,table_crew)
	steps=0;history.clear();lens_loaded=false;spare_loaded=false
	gate_latched=false;gate_open=0;step_left=0
	condition=100;speed=0;yaw=0;heel=0;side_drift=0
	sail_pos=Vector2(23,8);sail_up=true;sail_fraction=1;crossing_time=0
	level=0;flow=0;valve=0;lock_open=false;checkpoint_taken=false
	passed_arch=false;short_channel=false;sea_bell=false;light_on=false
	impact_wait=0;seen_helm=false
	mirror_index=[1,1];beam_key="";notice_left=0;total=0
	depot.show();chamber.hide();coast.show()
	if courier.get_parent()!=depot: courier.reparent(depot,false)
	courier.show();shipman.hide();receipt.hide()
	for i in 2:
		retrieved[i]=false;parcels[i].show()
	design.tower_beacon.hide();design.lighthouse_rays.hide();design.sail.scale=Vector3.ONE;design.sail.position.y=0
	sync_carts(true)
	ferry.position=Vector3(sail_pos.x,0,sail_pos.y)
	ferry.rotation=Vector3.ZERO
	design.mast.rotation.z=0
	design.lock_front.position.y=0;design.lock_back.position.y=-6.3
	design.tide_water.position.y=-0.70
	sound.set_scene("yard")
	message("把铁配重推上金色压盘，抬起隔栏",2.6)

func attach_item(item:Node3D,p:Node3D,pos:Vector3)->void:
	if item.get_parent()!=p: item.reparent(p,false)
	item.position=pos

func sync_carts(snap:bool)->void:
	if snap:
		courier.position=cell_world(player_cell)
		lens_cart.position=cell_world(lens_cell)
		weight_cart.position=cell_world(weight_cell)
	lens_cart.visible=not lens_loaded
	weight_cart.visible=not spare_loaded
	attach_item(jewel,truck if lens_loaded else lens_cart,Vector3(-1,1.11,0.16) if lens_loaded else Vector3.UP*0.3)
	attach_item(ballast,truck if spare_loaded else weight_cart,Vector3(-2.23,1.10,-0.13) if spare_loaded else Vector3.UP*0.30)
	goal_marker.visible=not lens_loaded
	weight_marker.visible=not spare_loaded

func message(words:String,seconds:=1.7)->void:
	notice=words
	notice_left=seconds

func change_stage(next:String)->void:
	stage=next;phase_time=0;notice_left=0
	transition_start=cam.transform;camera_blend=0

func can_enter(cell:Vector2i)->bool:
	if cell.x<0 or cell.x>8 or cell.y<0 or cell.y>6 or cell in BLOCKED: return false
	return cell!=GATE or weight_cell==PLATE or gate_latched

func try_walk(dir:Vector2i)->void:
	if community!=null and community.lifting:return
	if step_left>0 or dir==Vector2i.ZERO: return
	var dest:=player_cell+dir
	courier.rotation.y=atan2(float(dir.x),float(dir.y))
	if not can_enter(dest): return
	var lens_here:=not lens_loaded and dest==lens_cell
	var weight_here:=not spare_loaded and dest==weight_cell
	var next:=dest+dir
	if lens_here or weight_here:
		if not can_enter(next) or (not lens_loaded and next==lens_cell) or (not spare_loaded and next==weight_cell):
			message("前方顶住了 · 换一侧推，或按 Z 撤一步",0.9)
			return
	history.append({"player":player_cell,"lens":lens_cell,"weight":weight_cell,"loaded":lens_loaded,"spare":spare_loaded,"latch":gate_latched})
	player_cell=dest;steps+=1
	depot_speed=Porter.LOADED_SPEED if lens_here or weight_here else Porter.WALK_SPEED
	step_left=CELL_SPACING/depot_speed
	if lens_here:
		lens_cell=next
		if next==DOCK:
			lens_loaded=true;gate_latched=true
			sound.play_cue("load");message("镜芯已装船 · 可再装铁配重，或到系缆柱启航",2.7)
		else: sound.play_cue("foot")
	elif weight_here:
		weight_cell=next
		if next==PLATE: sound.play_cue("snap");message("隔栏升起 · 去镜车背后，把它推过通道",2.0)
		elif next==SPARE and lens_loaded:
			spare_loaded=true;sound.play_cue("load");message("已加压舱铁 · 渡船更抗侧流，航速稍慢",2.4)
		else: sound.play_cue("foot")

func undo()->void:
	if history.is_empty(): return
	var s:Dictionary=history.pop_back()
	player_cell=s.player;lens_cell=s.lens;weight_cell=s.weight
	lens_loaded=s.loaded;spare_loaded=s.spare;gate_latched=s.latch
	steps-=1;step_left=0.10;sync_carts(true)
	sound.play_cue("snap");message("已撤回一步",0.5)

func start_voyage()->void:
	if community!=null and community.lifting:return
	if step_left>0:return
	if not lens_loaded: message("先把镜车推到青色吊运盘");return
	if player_cell.distance_to(HELM)>1.45: message("去码头边的系缆柱解缆");return
	courier.hide();shipman.show()
	change_stage("castoff")
	sound.play_cue("start");sound.set_scene("road")
	save_checkpoint()

func save_checkpoint()->void:
	checkpoint={"pos":sail_pos,"yaw":yaw,"hp":condition,"parcels":retrieved.duplicate(),"arch":passed_arch,"short":short_channel,"time":crossing_time,"upper":lock_open,"fees":rescue_fee}
	checkpoint_taken=true

func restart_voyage()->void:
	if checkpoint.is_empty(): return
	sail_pos=checkpoint.pos;yaw=checkpoint.yaw;condition=checkpoint.hp
	retrieved.assign(checkpoint.parcels)
	rescue_fee=checkpoint.fees
	recovered_seal.visible=retrieved[0]
	for i in 2: parcels[i].visible=not retrieved[i]
	passed_arch=checkpoint.arch;short_channel=checkpoint.short;crossing_time=checkpoint.time
	lock_open=checkpoint.upper;level=3.55 if lock_open else 0
	design.lock_front.position.y=-6.3 if lock_open else 0
	design.lock_back.position.y=0 if lock_open else -6.3
	design.tide_water.position.y=level-0.70
	speed=0;side_drift=0;heel=0;impact_wait=0;sail_up=true
	receipt.hide();change_stage("upper" if lock_open else "sea");sound.set_scene("road")

func _unhandled_key_input(event:InputEvent)->void:
	if stage=="dive" or not event is InputEventKey or not event.pressed or event.echo: return
	if harbour_charter.visible:
		if event.keycode in [KEY_E,KEY_ESCAPE]:harbour_charter.hide()
		get_viewport().set_input_as_handled();return
	match event.keycode:
		KEY_ESCAPE:
			left_dock.emit(total if stage=="signed" else 0)
			get_viewport().set_input_as_handled()
		KEY_Q:
			if stage=="chamber": turn_mirror(-1)
			elif stage=="depot" and table_crew and lens_loaded and not spare_loaded and player_cell.distance_to(HELM)<1.45:
				if community!=null and not community.lifting:
					community.lift(self);sound.play_cue("load");message("工班起吊压舱铁 · 等绳索松开即可解缆",2.2)
			elif stage=="depot" and player_cell.y==6 and player_cell.x in [1,3]:
				get_viewport().set_input_as_handled();take_watch.emit()
		KEY_Z:
			if stage=="depot" and (community==null or not community.lifting): undo()
		KEY_R:
			if stage in ["signed","depot"]: reset_depot()
			elif stage in ["hill","hill_wreck"]: reset_hill()
			elif stage in ["wreck","sea","lock","upper"]: restart_voyage()
		KEY_SPACE:
			if stage in ["sea","upper"]:
				sail_up=not sail_up;sound.play_cue("snap")
				message("升帆 · 借风提速" if sail_up else "收桅 · 低桥可通",1.1)
		KEY_E:
			match stage:
				"depot":
					if community!=null and community.interact(self):return
					if player_cell.y==6 and player_cell.x in [1,3]:
						if blue_step==3:
							if table_inn and table_crew and feast_view<=0.:
								feast_view=4.15;message("谷神长桌 · 全港合席　 E 读共建铭",3.5);return
							harbour_charter.present(regular,has_market,tower_lit,grain_arrived,table_inn,table_crew);sound.play_cue("page");return
						if blue_step==0 and (blue_focus or not has_market):
							quay_talk=3.6
							message("窑工：「船靠岸，面包已经收摊了。」 伊娅：「从双灯窑带一盏灯回来，我就等你们。」",5);return
						message("伊娅：「赫斯提亚的火种在这里安了家。今后每送一篮，多出的两枚都是你的。」" if has_market else "伊娅：「赫斯提亚教我把火分给邻居。客舍要晨饭，窑工等夜宵。」",4.5)
						sound.play_cue("page")
					else:start_voyage()
				"sea","upper": sea_use()
				"lock": open_lock()
				"hill":
					var note:=hill.use()
					if not note.is_empty():message(note)
				"hill_wreck":reset_hill()
				"chamber": turn_mirror()
				"signed": left_dock.emit(total);get_viewport().set_input_as_handled()
				"wreck": restart_voyage()

func _unhandled_input(event:InputEvent)->void:
	if stage=="hill" and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		hill.brace()

func hill_impact(loss:float,reason:String)->void:
	sail_damage(loss,reason)
	if stage=="wreck":
		change_stage("hill_wreck")
		receipt.text="镜芯损坏 · 灯室无法签收\n\nE 从上层码头重新出车　 Esc 返回公路"

func reset_hill()->void:
	condition=hill_entry_hp;impact_wait=0;hill.active=true;hill.reset_drive(true)
	receipt.hide();change_stage("hill");message("已回到山脚码头")

func hill_arrive()->void:
	change_stage("hoist");sound.play_cue("load")

func start_hill()->void:
	ferry.position=Vector3(BERTH.x,3.55,BERTH.y);ferry.rotation=Vector3.ZERO
	shipman.hide();chamber.show();hill_entry_hp=condition
	hill.begin(truck,jewel,spare_loaded)
	change_stage("hill");sound.play_cue("start")
	message("货车上岸 · 木衡桥抄近路，蓝门村道可取邮戳",3.0)

func sail_damage(loss:float,reason:String)->void:
	if impact_wait>0: return
	impact_wait=1.5
	condition=maxf(0,condition-loss)
	message(reason+" · 镜芯 −%d"%roundi(loss),1.5)
	sound.play_cue("bonk")
	if condition<30:
		change_stage("wreck")
		receipt.text="镜芯破损 · 委托中断\n\nE 从最近泊位重新启航\nEsc 返回公路";receipt.show()

func voyage(dt:float,gas:float,steer:float)->void:
	var upper:=stage=="upper"
	crossing_time+=dt
	impact_wait=maxf(0,impact_wait-dt)
	sail_fraction=move_toward(sail_fraction,1.0 if sail_up else 0.0,dt*1.8)
	var max_speed:=lerpf(4.8,8.4,sail_fraction)*(0.86 if spare_loaded else 1.0)
	var target:=gas*(max_speed if gas>0 else 2.8)
	speed=move_toward(speed,target,dt*(5.3 if gas*speed<0 else (2.6 if gas!=0 else 1.3)))
	var control:=clampf(absf(speed)/2,0.16,1.0)*(-1 if speed< -0.25 else 1)
	yaw=wrapf(yaw+steer*dt*control*(0.85 if sail_up else 1.04),-PI,PI)
	var dir:=Vector2(cos(yaw),sin(yaw))
	var rough:=smoothstep(ROUGH_START,ROUGH_START+9,sail_pos.x)*(1-smoothstep(ROUGH_END-7,ROUGH_END,sail_pos.x))
	var stream:=rough*(1.1+0.85*sin(sail_pos.x*0.23+time*0.8))*(0.47 if spare_loaded else 1.0)
	side_drift=lerpf(side_drift,stream,1-exp(-dt*2.4))
	var next:=sail_pos+(dir*speed+Vector2(0,side_drift))*dt
	var normal:=Vector2.ZERO
	if not upper:
		for rock in REEFS:
			var delta:=next-Vector2(rock.x,rock.z)
			if delta.length()<rock.y+1.85:
				normal=delta.normalized()
				break
		if absf(next.x-65)<3.05:
			for pier in [-11.7,-3.9,3.9,11.7]:
				if absf(next.y-float(pier))<1.48: normal=Vector2(signf(sail_pos.x-65),0)
			if absf(next.y)<11.7 and sail_fraction>0.36:
				normal=Vector2(signf(sail_pos.x-65),0)
				if impact_wait<=0: message("桅杆太高 · 空格收桅，或绕外侧航道",2.0)
		if next.x>129.8 and (next.y< -7.0 or next.y>1.0):
			normal=Vector2.LEFT
		if next.x>=151:
			normal=Vector2.LEFT
			if impact_wait<=0: message("已进闸室 · 减速后 E 系缆",1.1)
		if absf(next.y)>23:
			next.y=clampf(next.y,-23,23)
			message("外海浅滩 · 转回浮标之间",0.6)
		next.x=maxf(20,next.x)
	else:
		if next.y< -7.1 or next.y>1.1:
			normal=Vector2(0,1 if next.y< -7.1 else -1)
		next.x=clampf(next.x,144,188)
	if normal!=Vector2.ZERO:
		var into:float=(next-sail_pos).dot(normal)
		if into<0: next-=normal*into
		if absf(speed)>2.0:
			var label:="触礁"
			if absf(next.x-65)<4: label="擦碰低桥 · 空格收桅或绕行"
			elif next.x>129: label="擦碰闸岸"
			sail_damage(2.5+absf(speed)*1.1,label)
		speed=move_toward(speed,0,dt*24)
	if stage=="wreck": return
	sail_pos=next
	if not passed_arch and sail_pos.x>68.5:
		passed_arch=true;short_channel=absf(sail_pos.y)<11.7
		message("低桥通过 · 可升帆" if short_channel else "外海航道 · 注意漂流货箱",2.1)
		sound.play_cue("snap")
	heel=lerpf(heel,clampf(-steer*speed*0.023+side_drift*0.07,-0.25,0.25)*(0.65 if spare_loaded else 1.0),1-exp(-dt*3.2))
	var bob:float=(0.075+rough*0.15)*sin(time*(1.7+rough*0.65))
	ferry.position=Vector3(sail_pos.x,(3.55 if upper else 0.0)+bob,sail_pos.y)
	ferry.rotation=Vector3(heel+rough*0.055*sin(time*3),-yaw,0.023*sin(time*2.2))
	design.wheel.rotation.x=steer*0.80
	design.mast.rotation.z=lerpf(-1.08,0.0,sail_fraction)
	design.sail.scale.y=lerpf(0.10,1.0,sail_fraction);design.sail.position.y=4.4*(1-design.sail.scale.y)
	for foam:Node3D in design.wake: foam.visible=absf(speed)>1.35
	for i in parcels.size():
		if not retrieved[i]:
			parcels[i].position.y=-0.30+0.14*sin(time*2.1+i)
			parcels[i].rotation.z=sin(time*1.75+i)*0.10

func enter_dive()->void:
	if dive!=null:return
	dive=preload("res://tide_dive.gd").new()
	dive.position=Vector3(420,0,-80)
	dive.source_sound=sound;dive.lamp_unlocked=lamp_unlocked
	add_child(dive)
	dive.surfaced.connect(leave_dive)
	change_stage("dive");speed=0
	depot.hide();coast.hide();sun.hide();title.get_parent().hide()
	sound.bg.stream_paused=true

func leave_dive(recovered:bool,fee:int)->void:
	if stage!="dive":return
	dive.set_physics_process(false)
	dive.set_process_unhandled_key_input(false)
	dive.queue_free();dive=null
	title.get_parent().show();depot.show();coast.show();sun.show()
	cam.current=true
	sound.bg.stream_paused=false
	change_stage("sea")
	if recovered:
		retrieved[0]=true;parcels[0].hide();recovered_seal.show()
		message("潮印已打捞 · 北岬灯塔加赏 28 枚",2.2);sound.play_cue("win")
	else:
		rescue_fee+=fee;message("绞盘收回 · 救援费 6 枚" if fee else "已安全上浮")

func sea_use()->void:
	if stage=="sea":
		for i in parcel_points.size():
			if not retrieved[i] and sail_pos.distance_to(parcel_points[i])<5.2:
				if absf(speed)>3.0: message("减速到慢航，再 E 捞取");return
				if i==0: enter_dive();return
				retrieved[i]=true;parcels[i].hide()
				message("已捞回失物 · 救助赏金 +12");sound.play_cue("win");return
		if sail_pos.distance_to(LOCK)<7.1 and absf(sail_pos.y+3)<3.9:
			if absf(speed)>2.0: message("松油或反向刹船，低速才能系缆");return
			speed=0;change_stage("lock");sound.play_cue("load");return
		message("靠近漂流货箱或升船闸后再系缆",1.2)
	elif stage=="upper":
		if sail_pos.distance_to(BERTH)>5.3: message("前往灯塔脚下的金色泊位");return
		if absf(speed)>2.0: message("即将到岸 · 减速系缆");return
		speed=0;change_stage("disembark");sound.play_cue("load")

func tide_lock(dt:float,gas:float)->void:
	# The valve has inertia. Closing it early lets the water settle in the marked band.
	sail_pos=sail_pos.lerp(LOCK,1-exp(-dt*3))
	yaw=lerp_angle(yaw,0,1-exp(-dt*3))
	design.lock_back.position.y=move_toward(design.lock_back.position.y,0,dt*4.8)
	valve=move_toward(valve,gas,dt*2.7)
	flow=move_toward(flow,valve*1.60,dt*(1.9 if gas==0 else 1.35))
	level=clampf(level+flow*dt,0,4.55)
	if (level<=0 and flow<0) or (level>=4.55 and flow>0): flow=0
	ferry.position=Vector3(sail_pos.x,level+0.035*sin(time*2.1),sail_pos.y)
	ferry.rotation=Vector3(0,-yaw,0)
	design.tide_water.position.y=level-0.70
	design.lock_float.position.y=level

func open_lock()->void:
	if absf(level-3.55)>0.24 or absf(flow)>0.42:
		message("浮针对准青带，松开水阀待水面稳定",1.5)
		sound.play_cue("warn");return
	level=3.55;flow=0;lock_open=true
	change_stage("sluice");sound.play_cue("snap")

func enter_chamber()->void:
	chamber.show()
	attach_item(jewel,podium,Vector3.UP*1.1)
	keeper=Vector2(-2.0,1.3)
	courier.reparent(chamber,false)
	courier.position=Vector3(keeper.x,0,keeper.y)
	courier.show()
	change_stage("chamber");sound.set_scene("yard")
	update_beams()

func beam_segment(node:MeshInstance3D,a:Vector3,b:Vector3)->void:
	var delta:=b-a
	node.position=(a+b)/2
	node.scale=Vector3(1,delta.length(),1)
	node.quaternion=Quaternion(Vector3.UP,delta.normalized())
	node.show()

func update_beams()->void:
	var key:="%d,%d"%[mirror_index[0],mirror_index[1]]
	if key==beam_key: return
	beam_key=key
	for b in beams: b.hide()
	for i in 2:
		mirrors[i].rotation.y=PI/4-mirror_index[i]*PI/4
	var a:=Vector3(-4.4,1.44,0)
	var b:=Vector3(2,1.44,0)
	var c:=Vector3(2,1.44,-4.5)
	beam_segment(beams[0],a,b)
	# Four detents correspond to the optical flat turning through 45-degree increments.
	var first_dirs:=[Vector3.FORWARD,Vector3.RIGHT,Vector3.BACK,Vector3.LEFT]
	var d:Vector3=first_dirs[mirror_index[0]]
	beam_segment(beams[1],b,b+d*(4.5 if mirror_index[0] in [0,2] else 3.6))
	if mirror_index[0]==2 and not sea_bell:
		sea_bell=true;sound.play_cue("snap");message("雾钟收光 · 海上船只获得引航",1.8)
	if mirror_index[0]!=0: return
	var next_dirs:=[Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD]
	var second:Vector3=next_dirs[mirror_index[1]]
	beam_segment(beams[2],c,c+second*(4.1 if mirror_index[1]==0 else 3.4))
	if mirror_index[1]==0 and not light_on:
		light_on=true;design.tower_beacon.show();design.lighthouse_rays.show()
		change_stage("lighting");sound.play_cue("win")

func turn_mirror(direction:=1)->void:
	var near:=0 if keeper.distance_to(MIRRORS[0])<keeper.distance_to(MIRRORS[1]) else 1
	if keeper.distance_to(MIRRORS[near])>2.25:
		message("走到镜座旁再 E 转镜",1)
		return
	mirror_index[near]=posmod(mirror_index[near]+direction,4)
	sound.play_cue("snap");update_beams()

func animate_worker(moving:bool,rate:float)->void:
	for leg in ["LegL","LegR"]:
		var limb:=courier.get_node(leg) as Node3D
		limb.rotation.x=sin(time*rate)*(0.38 if moving else 0.0)*(1 if leg=="LegL" else -1)
	for arm in ["ArmL","ArmR"]:
		var limb:=courier.get_node(arm) as Node3D
		limb.rotation.x=-0.74 if moving and stage=="depot" and step_left>0.13 else -0.2 if moving else 0.0

func finish_order()->void:
	var salvage_pay:=(28 if retrieved[0] else 0)+(12 if retrieved[1] else 0)
	var base:=68 if condition<60 else (96 if condition<90 else 120)
	var hill_pay:=(11 if hill.mark else 0)+(6 if hill.crossed else 0)
	var intact:=roundi(condition*0.24)
	total=base+intact+salvage_pay+hill_pay-rescue_fee+(8 if sea_bell else 0)+(8 if short_channel else 0)
	var grade:="严重损坏" if condition<60 else ("轻微破损" if condition<90 else "完整")
	receipt.text="北岬灯塔亮灯　·　已签收\n\n潮汐镜芯　%s %d%%\n运费 %d　品相小费 %d　救助 %d\n引航钟 %d　穿桥 %d　山路 %d　救援 −%d\n\n本单 %d 枚　·　航行 %d 秒\n领取后，北岬灯塔将为冥河夜渡引航\nE 领取并返回公路　　R 重玩"%[grade,floori(condition),base,intact,salvage_pay,8 if sea_bell else 0,8 if short_channel else 0,hill_pay,rescue_fee,total,roundi(crossing_time)]
	receipt.show();change_stage("signed")

func _physics_process(dt:float)->void:
	if harbour_charter.visible:return
	quay_talk=maxf(0,quay_talk-dt);feast_view=maxf(0.,feast_view-dt)
	if stage=="dive":return
	time+=dt;phase_time+=dt
	notice_left=maxf(0,notice_left-dt)
	var dx:=float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var dz:=float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	match stage:
		"depot":
			if step_left<=0 and (dx!=0 or dz!=0):
				try_walk(Vector2i(int(dx),0) if dx!=0 else Vector2i(0,int(dz)))
			var p:=cell_world(player_cell)
			if step_left>0:
				step_left=maxf(0,step_left-dt)
				var travel:=dt*depot_speed
				courier.position=courier.position.move_toward(p,travel)
				lens_cart.position=lens_cart.position.move_toward(cell_world(lens_cell),travel)
				weight_cart.position=weight_cart.position.move_toward(cell_world(weight_cell),travel)
				if step_left<=0:sync_carts(true)
			gate_open=move_toward(gate_open,1 if gate_latched or weight_cell==PLATE else 0,dt*2.5)
			design.board_gate.position.y=-1.60*gate_open
			animate_worker(courier.position.distance_to(p)>0.02 or step_left>0,8.5 if depot_speed==Porter.LOADED_SPEED else 11.0)
		"castoff":
			sail_pos.x+=dt*1.75
			ferry.position.x=sail_pos.x
			if phase_time>=1.0: change_stage("sea");message("W 加帆航行 · 前方旧桥需收桅或外绕",2.8)
		"sea","upper": voyage(dt,-dz,dx)
		"lock": tide_lock(dt,-dz)
		"sluice":
			design.lock_front.position.y=move_toward(design.lock_front.position.y,-6.3,dt*3.7)
			if phase_time>1.77:
				ferry.position.y=3.55;sail_up=true;change_stage("upper");save_checkpoint();message("上渠已通 · 驶向北岬泊位")
		"disembark":
			ferry.position=ferry.position.lerp(Vector3(BERTH.x,3.55,BERTH.y),1-exp(-dt*5))
			ferry.rotation=ferry.rotation.lerp(Vector3.ZERO,1-exp(-dt*6))
			if phase_time>0.75:start_hill()
		"hill":
			impact_wait=maxf(0,impact_wait-dt)
			hill.tick(dt,-dz,dx)
		"hoist":
			var u:=smoothstep(0,2.0,phase_time)
			if jewel.get_parent()!=coast: jewel.reparent(coast,true)
			var from:=truck.to_global(Vector3(-1,1.11,0.16))
			jewel.global_position=from.lerp(chamber.to_global(Vector3(-4.4,1.1,0)),u)+Vector3.UP*sin(PI*u)*7.8
			chamber.show()
			if phase_time>=2.0: enter_chamber()
		"chamber":
			var motion:=Vector2(dx,dz).limit_length(1)
			keeper=(keeper+motion*dt*4.5).limit_length(7.1)
			courier.position=Vector3(keeper.x,0,keeper.y)
			if motion.length()>0: courier.rotation.y=atan2(motion.x,motion.y)
			animate_worker(motion.length()>0,10)
		"lighting":
			design.tower_beacon.scale=Vector3.ONE*(1.4+0.2*sin(time*5))
			if phase_time>=2.1: finish_order()
	if light_on:design.lighthouse_rays.rotation.y=time*0.70
	for j in design.pennants.size():
		design.pennants[j].rotation.y=0.12*sin(time*4.0+j)
	update_camera(dt);update_ui()

func update_camera(dt:float)->void:
	var look:=Vector3.ZERO
	var offset:=Vector3.ZERO
	if stage=="depot":
		look=Vector3(8.3,0.25,6.1).lerp(courier.position,0.14)
		offset=Vector3(0.3,17.0,12.4)
		if has_bakery or player_cell.y>=4 or blue_step==3:
			look=Vector3(7.65,.42,8.24).lerp(courier.position,.14)
			offset=Vector3(.34,19.45,14.42)
		if community!=null:
			var morning:bool=blue_focus or community.carried or community.salute_left>0.
			var want:=1. if morning and not lens_loaded else 0.
			meal_camera=move_toward(meal_camera,want,dt*1.15)
			var focus:Vector3=courier.position+Vector3(0,.95,.33)
			if community.salute_left>0.:focus=focus.lerp(community.guest_focus,.35)
			look=look.lerp(focus,meal_camera)
			offset=offset.lerp(Vector3(.85,11.05,4.2),meal_camera)
		if feast_view>0. and public_quay!=null and public_quay.feast!=null:
			var watch:=smoothstep(0.,.85,feast_view)*(1.-smoothstep(3.35,4.15,feast_view))
			look=look.lerp(public_quay.feast.global_position+Vector3.UP*1.2,watch)
			offset=offset.lerp(Vector3(1.85,3.55,6.45),watch)
		if blue_focus and quay_talk>0.:
			var weight:=smoothstep(0.,.65,quay_talk)*(1.-smoothstep(2.90,3.60,quay_talk))
			look=look.lerp(Vector3(3.3,1.32,13.8),weight)
			offset=offset.lerp(Vector3(-5.1,3.6,6.2),weight)
	elif stage in ["chamber","lighting","signed"]:
		look=chamber.position+Vector3(0.3,0.42,-0.6)
		offset=Vector3(0,12.0,12.5)
		if stage in ["lighting","signed"]:
			look=chamber.position+Vector3(-2.2,4.5,0)
			offset=Vector3(14,7,21)
	elif stage in ["lock","sluice"]:
		look=Vector3(144.5,level*0.48+1.4,-3)
		offset=Vector3(-12,9.6,15)
	elif stage in ["hill","hill_wreck"]:
		var aim:=Vector3(cos(hill.view_heading),0,sin(hill.view_heading))
		look=truck.position+aim*2.65+Vector3.UP*1.45
		offset=-aim*10.9+Vector3.UP*6.1
	elif stage=="hoist":
		look=jewel.global_position
		offset=Vector3(-13,10,17)
	else:
		var aim:=Vector3(cos(yaw),0,sin(yaw))
		look=ferry.position+aim*3.55+Vector3.UP*1.67
		offset=-aim*16.1+Vector3(-aim.z,0,aim.x)*3.0+Vector3.UP*7.95
	if not camera_initialized: camera_focus=look;camera_initialized=true
	camera_focus=camera_focus.lerp(look,1-exp(-dt*(5.0 if stage=="sea" or stage=="upper" else 8.0)))
	var pose:=Transform3D(Basis.looking_at(-offset,Vector3.UP),camera_focus+offset)
	camera_blend=minf(1,camera_blend+dt/0.75)
	cam.transform=transition_start.interpolate_with(pose,smoothstep(0,1,camera_blend)) if camera_blend<1 else pose

func update_ui()->void:
	wear.update(jewel,"lens",condition)
	var objective:=""
	var prompt:=""
	var where:="镜芯出库"
	var guide:="WASD 推货走位　 Z 撤回一步　 E 解缆　 Esc 返回公路"
	if stage=="depot":
		if not lens_loaded:
			objective="铁配重 → 金色压盘" if weight_cell!=PLATE else "隔栏已升 · 把镜车推到青色吊运盘"
		else:
			objective="镜芯已装船 · 加装压舱铁，或前往系缆柱出发"
			if player_cell.distance_to(HELM)<1.45: prompt="E 解缆启航"
		if player_cell.y==6 and player_cell.x in [1,3]:prompt="E 听街坊说　 Q 随船去双灯窑取灯" if blue_step<2 else ("E 查看共建铭　 Q 随夜船出港" if blue_step==3 else "Q 续运陶灯")
		elif blue_step==0:objective+="　·　朝海面走到木台边找船夫"
		if blue_focus and blue_step<3:
			where="第一盏晚灯";objective="沿左侧通道向画面下方走，在临水木台找伊娅和船夫"
			guide="WASD 走到摊前　 E 交谈　 Q 随船运灯　 Esc 离开"
		if community!=null:
			if blue_focus:guide="WASD 走动　 E 领篮 / 分餐　 Q 在木台乘夜船　 Esc 回公路"
			var hint:String=community.prompt(self)
			if blue_focus:
				where="蓝棚晨班"
				if community.carried:objective="客舍在左拱廊 · 工班在右隔栏，任选一桌先送"
				elif meal_stock>0:objective="昨夜进港的粮已烤成面包 · 到临水木台领早饭"
				else:objective="客舍与工班均已开席" if table_inn and table_crew else "下一趟西风运输会给留下的街坊带来新麦"
			if hint!="":prompt=hint
			if table_inn and table_crew and player_cell.y==6 and player_cell.x in [1,3]:prompt="E 看谷神长桌　 Q 随船出港"
		if table_crew and lens_loaded and not spare_loaded and player_cell.distance_to(HELM)<1.45:prompt="E 轻载出发　 Q 请工班装压舱铁"
	elif stage in ["castoff","sea","upper","disembark"]:
		where="北岬海峡 · 摆渡"
		guide="W 加速　 S 刹船 / 倒航　 A D 掌舵　 空格 升帆 / 收桅　 E 系缆或打捞　 R 重航　 Esc 返回"
		if stage in ["upper","disembark"]:
			objective="上层引水渠 → 灯塔泊位　%d 米"%roundi(sail_pos.distance_to(BERTH))
			if sail_pos.distance_to(BERTH)<5.3: prompt="E 靠泊上岸" if absf(speed)<2 else "慢航靠泊"
		elif not passed_arch:
			objective="旧引水渠 · 收桅走中孔，或从两端外海绕行"
			if sail_pos.x>49 and absf(sail_pos.y)<12 and sail_up: prompt="低桥在前 · 空格收桅"
		else:
			objective="沿青色航标驶入升船闸　%d 米"%roundi(sail_pos.distance_to(LOCK))
		for i in 2:
			if not retrieved[i] and sail_pos.distance_to(parcel_points[i])<5.2: prompt=("E 乘钟下潜　潮印 +28" if i==0 else "E 捞回失物　+12") if absf(speed)<3 else "减速可打捞"
		if stage=="sea" and sail_pos.distance_to(LOCK)<7.1: prompt="E 系缆入闸" if absf(speed)<2 else "减速入闸"
	elif stage in ["lock","sluice"]:
		where="升船闸 · 调平水位"
		objective="进水抬船，让金针停在青带后开闸"
		guide="按住 W 进水　 S 排水　 松手闭阀　 E 解锁上闸　 Esc 返回"
		prompt="水位 %.2f 米　目标 3.55 米"%level
		if absf(level-3.55)<=0.24 and absf(flow)<=0.42: prompt="水位已平 · E 开启上闸"
	elif stage in ["hill","hill_wreck","hoist"]:
		where="北岬盘山道"
		objective="驾车送镜上山 · 木衡桥近，蓝门村道平缓"
		guide="W S 油门 / 倒车　 A D 转向　 空格 刹车　 左键 扶镜　 E 停靠　 R 从码头重来"
		if hill.inside_bridge:prompt="桥面正在倾斜 · 控制车速越过支点"
		elif hill.on_summit:prompt="E 交镜入灯室" if absf(hill.speed)<2 else "刹车交镜"
		elif hill.pos.distance_to(hill.xz(hill.POST))<5.4 and not hill.mark:prompt="E 请邮差盖戳　+11"
	elif stage in ["chamber","lighting","signed"]:
		where="北岬灯室 · 引光签收"
		objective="光从镜芯出发，经 Ⅰ、Ⅱ 镜座照亮主灯"
		guide="WASD 走到镜座旁　 E / Q 顺转或逆转　 Esc 返回"
		if keeper.distance_to(MIRRORS[0])<2.25 or keeper.distance_to(MIRRORS[1])<2.25: prompt="E 顺转　Q 逆转"
		if light_on: prompt="灯塔已点亮"
	title.text="潮汐船坞　/　"+where
	subtitle.text=objective;controls.text=guide
	cargo_label.text="镜芯　%d%%"%floori(condition)
	if stage=="hill": cargo_label.text+="\n%d 千米/时"%roundi(absf(hill.speed)*3.6)
	if stage in ["sea","upper"]: cargo_label.text+="\n%s　%.1f 米/秒"%["张帆" if sail_up else "收桅",absf(speed)]
	elif stage=="depot" and lens_loaded: cargo_label.text+="\n"+("重载 · 抗侧流" if spare_loaded else "轻载 · 航速优")
	var at_cargo:=stage in ["sea","upper","hill","lock"]
	nearby.visible=at_cargo
	if at_cargo:
		var panic:bool=stage=="hill" and hill.catch_left>0
		nearby.set_balance(stage=="hill" and hill.Catch.show_balance(hill.lateral/.84,hill.catch_left,hill.brace_left),hill.lateral/.84)
		var status:String=hill.Catch.instruction(hill.catch_left,hill.brace_left) if stage=="hill" else ""
		nearby.follow(cam,jewel.global_position+Vector3.UP*1.00,"镜芯",condition,status,panic)
		if stage in ["sea","upper"]:cargo_label.text="%s　%.1f 米/秒"%["张帆" if sail_up else "收桅",absf(speed)]
		if stage=="hill":cargo_label.text="%d 千米/时"%roundi(absf(hill.speed)*3.6)
	cargo_label.visible=not (stage=="depot" and blue_focus and not lens_loaded) and stage not in ["lock","chamber","lighting","signed","hoist"]
	action.text=notice if notice_left>0 else prompt
	action.visible=not action.text.is_empty() and not receipt.visible
	action.reset_size()
	action.position=Vector2((1280-action.size.x)/2,575)
