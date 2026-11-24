extends Node3D

const Art=preload("res://workshop.gd")
const District=preload("res://district.gd")
const Screen=preload("res://interface.gd")
const AudioKit=preload("res://sound.gd")
const ORIGINS=[Vector2(-3.68,-1.08),Vector2(-2.64,2.35)]
const ITEM_NAMES=["睡神的长榻","风神的风囊"]
const WALLS=[Rect2(-0.98,-4.48,0.36,3.21),Rect2(-0.98,1.27,0.36,2.51)]
const FREIGHT=[Vector2(0.68,1.41),Vector2(0.43,0.43)]
const COLORS=["#ffbd61","#78ceba"]
var mode: String="title"
var paused_from: String=""
var world: Node3D
var camera: Camera3D
var environment: WorldEnvironment
var sun: DirectionalLight3D
var art=Art.new()
var district=District.new()
var ui=Screen.new()
var audio=AudioKit.new()
var agent: Node3D
var items: Array[Node3D]=[]
var halo: Node3D
var ground_hints: Array[Node3D]=[]
var cargo_pos: Array[Vector2]=[]
var angles: Array[float]=[]
var loaded: Array[bool]=[]
var held: int=-1
var player:=Vector2(-4.52,1.04)
func cargo_name(i: int) -> String:
	return "酒神的双耳瓮" if expert and i==0 else ITEM_NAMES[i]

func condition_name() -> String:
	return "酒量" if expert else "安眠"

var facing:=Vector2(0,-1)
var grip:=Vector2.ZERO
var walked:=0.0
var t:=0.0
var note: String=""
var note_left:=0.0
var bonk_left:=0.0
var carry_lift:=0.0
var strap:=0
var route:=0
var expert:=false
var air:=100.0
var calm:=100.0
var stamina:=100.0
var road_t:=0.0
var road_end:=0.0
var events: Array[Dictionary]=[]
var current_event: int=-1
var weather_strength:=0.0
var wind_burst:=0.0
var bounce:=0.0
var cash_best:=0
var jobs:=0
var personal_records: Dictionary={}
var muted:=false
var testing:=false
var receipt_data: Dictionary={}
var action_cooldown:=0.0
var rig_rope: Node3D
var jumping:=0.0
var previous_order: Array[int]=[]
var report_lines: Array[String]=[]
var yard_air:=100.0
var yard_calm:=100.0
var yard_seconds:=0.0
var sealed:=true
var gate_fired:=false
var toss_charge:=0.0
var flying:=-1
var flight_time:=0.0
var flight_from:=Vector2.ZERO
var flight_to:=Vector2.ZERO
var flight_dir:=Vector2.RIGHT
var road_bonus:=0
var lane_z:=0.0
var lane_v:=0.0
var stops: Node3D
var drive_speed:=1.0
var chassis_y:=0.0
var lift_v:=0.0
var airborne:=false
var wind_spent:=false
var ground_pitch:=0.0
var ground_bank:=0.0
var meadow_heading:=0.0
var sprint_heat:=0.0
var sprint_locked:=false
var wheel_dmg:=0
var puff_pool: Array[Dictionary]=[]
var gusts: Array[Node3D]=[]
var closing:=false
var warned:=-1
var cargo_label: Label3D
var cargo_shift:=Vector2.ZERO
var cargo_velocity:=Vector2.ZERO
var corked:=false
var load_slosh:=0.0
var next_footfall:=0.0
var spill_buffer:=0.0
var rescue_time:=0.0
var rescue_item:=-1
var rescue_count:=0
var rescue_slide:=0.0
var rescued_lately:=0.0
var threatened_loss:=0
var passenger_head: Node3D
var quilt_pivot: Node3D
var sack_mouth: Node3D
var sleep_sign: Label3D
var peek_label: Label3D
var sky_light: DirectionalLight3D
var harbor=preload("res://harbor.gd").new()
var crane_x:=0.0
var crane_dx:=0.0
var pendulum:=0.0
var pendulum_dx:=0.0
var crane_stage: String=""
var crate_index:=0
var crane_timer:=0.0
var crane_auto:=false
var unload_tip:=0
var drop_from:=Vector3.ZERO
var drop_to:=Vector3.ZERO
var pickup_from:=Vector3.ZERO
var unload_line: String=""
var just_signed:=false
var yard_direction: Node3D
const DECOR_BLOCKS=[Rect2(-8.42,-3.92,1.5,1.05),Rect2(-6.68,-3.93,1.16,0.72),Rect2(-8.30,-2.36,1.13,1.08),Rect2(-8.22,-0.76,0.83,0.80),Rect2(-8.35,2.49,0.61,0.64)]


func _ready() -> void:
	testing=OS.get_cmdline_user_args().has("--qa") or OS.get_cmdline_user_args().has("--qa-run")
	get_tree().auto_accept_quit=false
	add_child(audio)
	var canvas:=CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(ui)
	ui.game=self
	if not testing:
		var cfg:=ConfigFile.new()
		if cfg.load("user://dispatch.cfg")==OK:
			cash_best=int(cfg.get_value("record","best",0))
			jobs=int(cfg.get_value("record","jobs",0))
			var saved_bests: Variant=cfg.get_value("record","commissions",{})
			if saved_bests is Dictionary: personal_records=saved_bests
			muted=bool(cfg.get_value("record","muted",false))
	audio.set_quiet(muted)
	environment=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("#afd0cb")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("#ffedce")
	environment.environment.ambient_light_energy=0.61
	environment.environment.ssao_enabled=true
	environment.environment.ssao_radius=1.8
	environment.environment.ssao_intensity=2.0
	environment.environment.ssao_detail=0.7
	environment.environment.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_ACES
	environment.environment.tonemap_exposure=0.85
	add_child(environment)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-32,0)
	sun.light_color=Color("#ffdcaa")
	sun.light_energy=1.9
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=65
	sun.shadow_bias=0.045
	sun.light_angular_distance=1.8
	sun.shadow_blur=1.35
	add_child(sun)
	sky_light=DirectionalLight3D.new()
	sky_light.rotation_degrees=Vector3(-24,142,0)
	sky_light.light_color=Color("#aecedf")
	sky_light.light_energy=0.24
	add_child(sky_light)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.near=0.1
	camera.far=150
	add_child(camera)
	camera.current=true
	to_title()
	if OS.get_cmdline_user_args().has("--road-preview"):
		testing=true
		previous_order.assign([0,1])
		begin_road()
	if OS.get_cmdline_user_args().has("--qa-run"):
		add_child(load("res://validation.gd").new())

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree() and not closing:
		shut_down()

func shut_down() -> void:
	closing=true
	mode="closing"
	audio.stop_all()
	await get_tree().create_timer(0.24).timeout
	get_tree().quit()

func toggle_sound() -> void:
	muted=not muted
	audio.set_quiet(muted)
	save_record()
	if mode=="pause": ui.pause_overlay()

func save_record() -> void:
	if testing: return
	var cfg:=ConfigFile.new()
	cfg.set_value("record","best",cash_best)
	cfg.set_value("record","jobs",jobs)
	cfg.set_value("record","commissions",personal_records)
	cfg.set_value("record","muted",muted)
	cfg.save("user://dispatch.cfg")

func clear_world() -> void:
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	world=Node3D.new()
	add_child(world)
	district=District.new()
	agent=null
	rig_rope=null
	items.clear()
	ground_hints.clear()
	puff_pool.clear()
	gusts.clear()
	cargo_label=null
	yard_direction=null
	halo=null
	passenger_head=null
	quilt_pivot=null
	sack_mouth=null
	sleep_sign=null
	peek_label=null

func set_camera(eye: Vector3,look: Vector3,size: float) -> void:
	camera.position=eye
	camera.look_at(look)
	camera.size=size
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL

func daylight() -> void:
	environment.environment.background_color=Color("#899cb1") if expert else Color("#b4d3cc")
	environment.environment.ambient_light_color=Color("#cfdbf4") if expert else Color("#ffedce")
	sun.light_color=Color("#ffcfa7") if expert else Color("#fff0de")
	sun.light_energy=0.91 if expert else 1.08
	if RenderingServer.get_current_rendering_method()=="gl_compatibility":
		sun.light_energy*=0.54
		environment.environment.ambient_light_energy=0.32
		environment.environment.tonemap_exposure=0.74
		sky_light.light_energy=0.11
	environment.environment.fog_enabled=true
	environment.environment.fog_mode=Environment.FOG_MODE_DEPTH
	environment.environment.fog_depth_begin=24
	environment.environment.fog_depth_end=73
	environment.environment.fog_light_color=Color("#b1c3c2") if not expert else Color("#8795ad")
	environment.environment.fog_density=0.56

func to_title() -> void:
	mode="title"
	clear_world()
	ui.title_page(cash_best,jobs)
	audio.set_scene("title")
	action_cooldown=0.18

func begin_dispatch() -> void:
	expert=false
	begin_order()

func begin_expert() -> void:
	expert=true
	begin_order()

func begin_order() -> void:
	clear_world()
	daylight()
	district.depot(world)
	set_camera(Vector3(6,15.5,19),Vector3(0,0,0),14.2)
	mode="brief"
	ui.briefing(expert)
	audio.set_scene("yard")
	audio.play_cue("page")
	action_cooldown=0.16

func restart_order() -> void:
	begin_order()

func begin_load() -> void:
	mode="load"
	clear_world()
	daylight()
	district.depot(world)
	set_camera(Vector3(5.2,17.2,20.5),Vector3(-0.15,0.3,-0.36),13.55)
	player=Vector2(-5.78,1.48) if expert else Vector2(-4.52,1.04)
	facing=Vector2(0,-1)
	held=-1
	loaded=[false,false]
	cargo_pos=[Vector2(-4.55,0.73) if expert else ORIGINS[0],Vector2(-2.43,-2.25) if expert else ORIGINS[1]]
	angles=[0.0,0.25]
	previous_order.clear()
	yard_air=100
	yard_calm=100
	corked=false
	load_slosh=0
	spill_buffer=0
	next_footfall=0
	if expert:
		district.winery(world)
	yard_seconds=0
	sealed=true
	gate_fired=false
	toss_charge=0
	flying=-1
	strap=0
	route=0
	agent=art.courier(world)
	items=[art.trolley(world) if expert else art.bed(world),art.sack(world)]
	halo=art.ring(world,Vector3.ZERO,0.40,0.034,"#ffe5a2")
	for i in 2:
		var h:=art.ring(world,Vector3.ZERO,0.68 if i==0 else 0.53,0.033,COLORS[i])
		ground_hints.append(h)
	setup_animated_props()
	cargo_label=district.sign_text(world,"",Vector3.ZERO,0.0064)
	cargo_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	cargo_label.outline_size=9
	cargo_label.outline_modulate=Color("#173940")
	cargo_label.no_depth_test=true
	yard_direction=art.group(world,Vector3.ZERO)
	for k in 3:
		var fin:=art.box(yard_direction,Vector3(0,0.025,k*0.23),Vector3(0.36-k*0.075,0.03,0.085),Art.GOLD)
		fin.rotation.y=0
	ui.loading()
	audio.play_cue("start")
	note_left=0
	bonk_left=0
	carry_lift=0
	action_cooldown=0.15
	sync_load(0.016)

func to_world(v: Vector2,h: float=0.0) -> Vector3:
	return Vector3(v.x,h,v.y)

func legal(center: Vector2, angle: float, half: Vector2) -> bool:
	var poly:=PackedVector2Array()
	for c: Vector2 in [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)]:
		var q:=center+c.rotated(-angle)
		if not Rect2(-8.43,-3.94,16.91,7.62).has_point(q):
			return false
		poly.append(q)
	var obstacles: Array=WALLS.duplicate()
	if gate_fired: obstacles.remove_at(1)
	obstacles.append_array(DECOR_BLOCKS)
	for wall: Rect2 in obstacles:
		var a:=wall.position
		var b:=wall.end
		if not Geometry2D.intersect_polygons(poly,PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])).is_empty():
			return false
	return true

func move_step(step2: Vector2) -> bool:
	if step2.length_squared()<0.000001: return true
	if not legal(player+step2,0,Vector2(0.21,0.21)): return false
	# The van is solid. Cargo is handed off at its tail ramp.
	if player.x+step2.x>1.91 and player.x+step2.x<7.91 and absf(player.y+step2.y)<1.36: return false
	if held>=0 and not legal(cargo_pos[held]+step2,angles[held],FREIGHT[held]):
		return false
	for i in 2:
		if held==i or flying==i or loaded[i]: continue
		var local: Vector2=(player+step2-cargo_pos[i]).rotated(angles[i])
		var half: Vector2=FREIGHT[i]
		if absf(local.x)<half.x+0.15 and absf(local.y)<half.y+0.15:
			# A loose parcel can be nudged, but walls still arrest its footprint.
			if not legal(cargo_pos[i]+step2,angles[i],half): return false
			cargo_pos[i]+=step2
	player+=step2
	if held>=0: cargo_pos[held]+=step2
	return true

func nearest_cargo() -> int:
	var near:=-1
	var distance:=0.80
	for i in 2:
		if loaded[i] or flying==i: continue
		var local: Vector2=(player-cargo_pos[i]).rotated(angles[i])
		var d:=Vector2(maxf(absf(local.x)-FREIGHT[i].x,0),maxf(absf(local.y)-FREIGHT[i].y,0)).length()
		if d<distance:
			near=i
			distance=d
	return near

func at_ramp(i: int) -> bool:
	return cargo_pos[i].x>0.57 and cargo_pos[i].x<5.0 and absf(cargo_pos[i].y)<1.24

func interact() -> void:
	if held<0:
		var near:=nearest_cargo()
		if near<0:
			message("走到睡榻或风囊旁边，再按空格。",1.5)
			return
		held=near
		# Move the courier to a reachable handle on the nearest long or short edge.
		var local: Vector2=(player-cargo_pos[held]).rotated(angles[held])
		var half: Vector2=FREIGHT[held]
		if absf(local.x)/half.x>absf(local.y)/half.y:
			local=Vector2((half.x+0.22)*(1 if local.x>=0 else -1),clampf(local.y,-half.y+0.15,half.y-0.15))
		else:
			local=Vector2(clampf(local.x,-half.x+0.14,half.x-0.14),(half.y+0.22)*(1 if local.y>=0 else -1))
		var handle: Vector2=cargo_pos[held]+local.rotated(-angles[held])
		if legal(handle,0,Vector2(0.18,0.18)): player=handle
		grip=cargo_pos[held]-player
		if grip.length()>0.12: facing=grip.normalized()
		audio.play_cue("grab")
		message("搬起"+cargo_name(held),0.75)
		return
	var i:=held
	toss_charge=0
	held=-1
	if at_ramp(i):
		stow(i)
	else:
		audio.play_cue("drop")
		message("已放下。可以换一侧重新搬起。",1.2)

func stow(i: int) -> void:
	if loaded[i]: return
	loaded[i]=true
	previous_order.append(i)
	audio.play_cue("load")
	sparks(to_world(cargo_pos[i],0.8),Art.GOLD,9)
	message(cargo_name(i)+"已装车",1.2)
	if loaded[0] and loaded[1]:
		sync_load(0)
		begin_rig()

func sparks(pos: Vector3,col: String,count: int) -> void:
	for k in count:
		var a:=k*TAU/count+t
		var n:=art.ball(world,pos,Vector3.ONE*(0.085+0.025*(k%3)),col,true)
		puff_pool.append({"n":n,"v":Vector3(cos(a)*(1+k%2),1.65+(k%3)*0.53,sin(a)*(1+k%2)),"life":0.64,"start":0.64})

func animate_puffs(dt: float) -> void:
	for j in range(puff_pool.size()-1,-1,-1):
		var fx: Dictionary=puff_pool[j]
		fx.life-=dt
		if fx.life<=0 or not is_instance_valid(fx.n):
			if is_instance_valid(fx.n): fx.n.queue_free()
			puff_pool.remove_at(j)
			continue
		fx.n.position+=fx.v*dt
		fx.v.y-=dt*4.3
		fx.n.scale*=pow(0.36,dt)

func gust_gate() -> void:
	if held!=1 or gate_fired: return
	if cargo_pos[1].distance_to(Vector2(-0.8,2.48))>3.6:
		message("靠近右侧百叶门，才吹得到门闩",1.4)
		return
	gate_fired=true
	sealed=false
	yard_air=maxf(0,yard_air-16)
	district.blow_gate()
	var origin: Vector3=items[1].global_position+Vector3.UP*0.96
	var towards: Vector3=Vector3(-0.8,0.95,2.48)-origin
	var gust=preload("res://gust.gd").new()
	gust.start(world,origin,towards,maxf(1.2,towards.length()+0.9),1.23)
	gusts.append(gust)
	audio.play_cue("wind")
	sparks(Vector3(-0.80,0.98,2.48),Art.CREAM,21)
	message("西风吹开了侧门  ·  余风 −16",2.3)

func begin_throw() -> void:
	if held<0 or toss_charge>0 or flying>=0: return
	toss_charge=0.01
	flight_dir=facing
	audio.play_cue("snap")

func release_throw() -> void:
	if toss_charge<=0 or held<0:
		toss_charge=0
		return
	flying=held
	held=-1
	flight_time=0
	flight_from=cargo_pos[flying]
	flight_to=flight_from
	var strength:=1.1+minf(1,toss_charge/0.85)*2.05
	for k in 32:
		var dest:=flight_from+flight_dir*(k+1)*strength/32.0
		if not legal(dest,angles[flying],FREIGHT[flying]): break
		if dest.x>4.95: break
		flight_to=dest
	toss_charge=0
	audio.play_cue("wind")
	message("货物已抛出",0.55)

func update_flight(dt: float) -> void:
	if flying<0: return
	flight_time+=dt
	var v:=clampf(flight_time/0.5,0,1)
	cargo_pos[flying]=flight_from.lerp(flight_to,v)
	if v>=1:
		var i:=flying
		flying=-1
		if at_ramp(i):
			stow(i)
		else:
			if i==0: yard_calm=maxf(0,yard_calm-7)
			else: yard_air=maxf(0,yard_air-5)
			audio.play_cue("land")
			sparks(to_world(cargo_pos[i],0.25),Art.SAND,7)
			message("落地一颠  ·  "+(condition_name()+" −7" if i==0 else "余风 −5"),1.5)

func message(s: String,sec: float) -> void:
	note=s
	note_left=sec

func sync_load(delta: float) -> void:
	var move:=Vector2.ZERO
	if mode=="load":
		move=Vector2(float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	move=move.normalized().rotated(-0.155)
	var speed:=4.15 if held<0 else (2.14 if held==0 else 3.0)
	if toss_charge>0: speed*=0.26
	if held>=0:
		var turn:=float(Input.is_key_pressed(KEY_E))-float(Input.is_key_pressed(KEY_Q))
		var angle:=angles[held]+turn*delta*2.1
		var rotated_grip:=grip.rotated(angles[held]-angle)
		var turned_player:=cargo_pos[held]-rotated_grip
		if legal(cargo_pos[held],angle,FREIGHT[held]) and legal(turned_player,0,Vector2(0.19,0.19)):
			angles[held]=angle
			grip=rotated_grip
			player=turned_player
		elif turn!=0: bump()
	var before:=player
	if move.length_squared()>0:
		var motion:=move*speed*delta
		if not move_step(motion):
			var x_ok:=move_step(Vector2(motion.x,0))
			var y_ok:=move_step(Vector2(0,motion.y))
			if not x_ok or not y_ok: bump()
		if held<0: facing=move
		elif grip.length_squared()>0.01: facing=grip.normalized()
	if mode=="load":
		yard_seconds+=delta
		if held==0 and expert and not corked:
			var twist:=absf(float(Input.is_key_pressed(KEY_E))-float(Input.is_key_pressed(KEY_Q)))
			load_slosh=move_toward(load_slosh,twist,delta*(0.82 if twist>0 else 1.4))
			if load_slosh>0.54:
				spill_buffer+=delta*4.2
				if spill_buffer>=1:
					yard_calm=maxf(0,yard_calm-1)
					spill_buffer-=1
					sparks(to_world(cargo_pos[0],1.0),"#9b4778",3)
		else:
			load_slosh=move_toward(load_slosh,0,delta)
		if dist_to_footstep(): audio.play_cue("foot")
		if toss_charge>0: toss_charge=minf(1.0,toss_charge+delta)
		if toss_charge>0 and move.length_squared()>0.1: flight_dir=move.normalized()
	var dist:=player.distance_to(before)
	walked+=dist*3.5
	agent.position=to_world(player,0.16+absf(sin(walked))*0.047*minf(1,dist*110))
	agent.rotation.y=lerp_angle(agent.rotation.y,atan2(facing.x,facing.y),minf(1,delta*14))
	agent.get_node("LegL").rotation.x=sin(walked)*minf(0.48,dist*15)
	agent.get_node("LegR").rotation.x=-agent.get_node("LegL").rotation.x
	agent.get_node("ArmL").rotation.x=-1.15 if held>=0 else -agent.get_node("LegL").rotation.x
	agent.get_node("ArmR").rotation.x=-1.15 if held>=0 else agent.get_node("LegL").rotation.x
	halo.position=to_world(player,0.218)
	carry_lift=move_toward(carry_lift,0.36 if held>=0 else 0.0,delta*2.5)
	var near:=nearest_cargo()
	for i in 2:
		if loaded[i]:
			items[i].position=Vector3(stow_x(i)+4.75,1.14,0)
			items[i].rotation=Vector3(0,PI/2 if i==0 else 0,0)
		else:
			var lift:=carry_lift if held==i else 0.0
			if flying==i: lift+=sin(clampf(flight_time/0.5,0,1)*PI)*1.48
			items[i].position=to_world(cargo_pos[i],0.20+lift)
			items[i].rotation=Vector3(0,angles[i],sin(walked)*0.028 if held==i else 0.0)
		district.pads[i].visible=not loaded[i]
		ground_hints[i].visible=not loaded[i] and held!=i
		ground_hints[i].position=to_world(cargo_pos[i],0.226)
		ground_hints[i].scale=Vector3.ONE*(1+0.04*sin(t*3+i))
	if is_instance_valid(cargo_label):
		cargo_label.visible=held<0 and near>=0
		if sleep_sign: sleep_sign.visible=not (cargo_label.visible and near==0)
		if near>=0:
			cargo_label.position=items[near].position+Vector3.UP*1.86
			cargo_label.text=cargo_name(near)
	if is_instance_valid(yard_direction):
		yard_direction.visible=held>=0
		if held>=0:
			yard_direction.position=to_world(cargo_pos[held],0.24)
			yard_direction.rotation.y=atan2(flight_dir.x,flight_dir.y) if toss_charge>0 else atan2(facing.x,facing.y)
			yard_direction.scale=Vector3(1,1,3.8+toss_charge*3)
	if ui.ctl.has("count"):
		ui.ctl.count.text="已装车     %d / 2" % (int(loaded[0])+int(loaded[1]))
		var prompt: String
		if toss_charge>0: prompt="蓄力 %d%%  ·  方向键瞄准，松开 Shift 抛出" % roundi(minf(1,toss_charge/0.85)*100)
		elif note_left>0: prompt=note
		elif held>=0 and at_ramp(held): prompt="空格  ·  将"+cargo_name(held)+"装上车"
		elif held==0 and expert: prompt="轻转防洒  ·  F 在紫色封蜡台封酒（9 枚）" if not corked else "已封蜡  ·  把酒车送到装载木坡"
		elif held==0: prompt="Q / E  转榻，让长边顺着门洞穿过去"
		elif held==1 and not gate_fired and cargo_pos[1].distance_to(Vector2(-0.8,2.48))<3.6: prompt="F  借风吹开百叶门（余风 −16）   /   也可绕正门"
		elif held==1: prompt="把风囊搬到货车尾部的木坡，按空格装车"
		elif near>=0: prompt="空格  ·  搬起"+cargo_name(near)
		else: prompt="走到金色睡榻或风囊旁，空格搬起"
		ui.ctl.prompt.text=prompt

func dist_to_footstep() -> bool:
	if walked<next_footfall: return false
	next_footfall=walked+2.55
	return true

func seal_urn() -> void:
	if not expert or held!=0: return
	if corked:
		message("两个酒瓮都已封蜡",1.3)
		return
	if cargo_pos[0].distance_to(Vector2(-6.8,2.15))>2.36:
		message("把酒车推近紫色封蜡台，再按 F",1.5)
		return
	corked=true
	audio.play_cue("snap")
	sparks(items[0].position+Vector3.UP,Art.RED,10)
	message("酒瓮已封蜡  ·  抵达时支付 9 枚",2.1)

func bump() -> void:
	if bonk_left>0: return
	bonk_left=0.68
	if held>=0:
		message("卡住了  ·  后退一点，按 Q / E 转货",0.78)
		audio.play_cue("bonk")

func stow_x(i: int) -> float:
	# The first item slides to the cab. The second sits closer to the open tail.
	var first:=0 if previous_order.is_empty() else previous_order[0]
	if first==0:
		return -0.05 if i==0 else -2.25
	return -1.36 if i==0 else 0.51

func begin_rig() -> void:
	mode="rig"
	if cargo_label: cargo_label.hide()
	if yard_direction: yard_direction.hide()
	# Camera re-frames the same truck. Cargo identity and load order persist.
	set_camera(Vector3(-0.4,11.2,12.2),Vector3(5.95,0.6,0),10.1)
	show_strap()
	ui.rig(strap,route,expert)
	audio.play_cue("page")
	action_cooldown=0.18

func return_to_load() -> void:
	var condition: Array=[yard_air,yard_calm,gate_fired,sealed,yard_seconds,corked]
	begin_load()
	yard_air=condition[0]
	yard_calm=condition[1]
	sealed=condition[3]
	yard_seconds=condition[4]
	corked=condition[5]
	if condition[2]:
		gate_fired=true
		district.blow_gate()
	message("货物已卸回庭院，可以重新安排先后。",1.5)

func swap_positions() -> void:
	if previous_order.size()!=2: return
	previous_order.reverse()
	for i in 2:
		items[i].position.x=stow_x(i)+4.75
	audio.play_cue("load")
	ui.rig(strap,route,expert)

func show_strap() -> void:
	if is_instance_valid(rig_rope):
		rig_rope.get_parent().remove_child(rig_rope)
		rig_rope.queue_free()
	rig_rope=art.group(items[strap])
	if strap==0:
		art.beam(rig_rope,Vector3(-0.69,0.28,0.34),Vector3(-0.50,1.15,0.34),0.058,Art.RED)
		art.beam(rig_rope,Vector3(-0.5,1.15,0.34),Vector3(0.5,1.15,0.34),0.062,Art.RED)
		art.beam(rig_rope,Vector3(0.5,1.15,0.34),Vector3(0.69,0.28,0.34),0.058,Art.RED)
	else:
		var r: Node3D=art.ring(rig_rope,Vector3(0,0.59,0),0.54,0.064,Art.RED)
		r.scale.z=0.89

func set_strap(i: int) -> void:
	strap=i
	show_strap()
	ui.rig(strap,route,expert)
	audio.play_cue("grab")

func set_route(i: int) -> void:
	route=i
	ui.rig(strap,route,expert)
	audio.play_cue("page")

func make_event(at: float,kind: String,title: String,damage: float) -> Dictionary:
	return {"at":at,"kind":kind,"title":title,"damage":damage,"guard":0.0,"used":false,"done":false}

func begin_road() -> void:
	mode="road"
	clear_world()
	district.highway(world,route==1,expert)
	stops=preload("res://road_stops.gd").new()
	world.add_child(stops)
	stops.build(district,route==1,expert)
	drive_speed=1.0
	chassis_y=0
	lift_v=0
	airborne=false
	wind_spent=false
	ground_pitch=0
	ground_bank=0
	sprint_heat=0
	sprint_locked=false
	daylight()
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	camera.fov=53
	cargo_shift=Vector2.ZERO
	cargo_velocity=Vector2.ZERO
	items=[art.trolley(district.truck) if expert else art.bed(district.truck),art.sack(district.truck)]
	items[0].position=Vector3(stow_x(0),1.11,0)
	items[0].rotation.y=PI/2
	items[1].position=Vector3(stow_x(1),1.11,0)
	show_strap()
	air=yard_air
	calm=yard_calm
	stamina=100
	road_t=0
	wind_burst=0
	bounce=0
	jumping=0
	wheel_dmg=0
	lane_z=0
	lane_v=0
	warned=-1
	note_left=0
	rescue_time=0
	rescue_item=-1
	rescue_count=0
	rescue_slide=0
	rescued_lately=0
	setup_animated_props()
	peek_label=district.sign_text(world,"",Vector3.ZERO,0.0067)
	peek_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	peek_label.no_depth_test=true
	peek_label.outline_size=11
	peek_label.outline_modulate=Color("#713d31")
	peek_label.modulate=Color("#ffe7a8")
	peek_label.hide()
	current_event=-1
	events=[]
	events.append(make_event(5.8,"curve","滚动酒桶",26))
	events.append(make_event(13.1,"stones","山坡落石",32))
	if route==0:
		events.append(make_event(21.0,"gap","断桥！",45))
	else:
		events.append(make_event(21.0,"ferry","渡口栈桥",12))
	if expert: events.append(make_event(28.0,"curve","横穿酒桶",35))
	road_end=events.back().at+4.2
	report_lines.clear()
	weather_strength=0
	ui.road()
	audio.set_scene("road")
	audio.play_cue("engine")
	action_cooldown=0.22
	update_road(0)

func setup_animated_props() -> void:
	passenger_head=items[0].find_child("HeadPivot",true,false)
	quilt_pivot=items[0].find_child("QuiltPivot",true,false)
	sack_mouth=items[1].find_child("MouthPivot",true,false)
	sleep_sign=district.sign_text(items[0],"z  Z",Vector3(0.1,1.67,-0.84),0.005)
	sleep_sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sleep_sign.outline_size=7
	sleep_sign.outline_modulate=Color("#365b6b")
	sleep_sign.modulate=Color("#ffecbf")
	if expert: sleep_sign.text="•••"

func animate_freight(dt: float) -> void:
	if items.size()!=2: return
	var shock:=bounce if mode=="road" else 0.0
	if passenger_head:
		passenger_head.rotation.x=sin(t*1.7)*0.056-shock*0.55
		passenger_head.position.y=0.96+0.019*sin(t*1.7)+shock*0.15
	if quilt_pivot: quilt_pivot.scale.y=1+0.073*sin(t*1.7)
	if sack_mouth:
		var tension: float=wind_burst if mode=="road" else (bonk_left*0.25)
		sack_mouth.rotation.z=sin(t*2.6)*0.06+tension*0.68
		sack_mouth.scale=Vector3.ONE*(1+tension*0.22)
	if sleep_sign:
		sleep_sign.position.y=1.68+0.095*sin(t*2.1)
		if expert:
			sleep_sign.text="酒洒了！" if load_slosh>0.54 and not corked else ("已封蜡" if corked else "陈酿")
		else:
			sleep_sign.text="！" if shock>0.35 else "z  Z"
		sleep_sign.modulate.a=0.56+0.31*sin(t*1.9)
	if expert:
		for idx in 2:
			var vase=items[0].get_node_or_null("Amphora"+str(idx))
			if vase: vase.rotation.z=sin(t*7+idx)*((shock*0.18 if mode=="road" else load_slosh*0.16))

func catch_cargo() -> void:
	if mode!="road" or rescue_item<0 or rescue_time<=0: return
	var refund:=mini(threatened_loss,maxi(2,roundi(threatened_loss*0.5)))
	if rescue_item==0: calm=minf(100,calm+refund)
	else: air=minf(100,air+refund)
	sparks(items[rescue_item].global_position+Vector3.UP*0.8,Art.GOLD,13)
	audio.play_cue("snap")
	report_lines.append("伸手拉回"+cargo_name(rescue_item))
	message("拉回来了！  ·  挽回 %d 点货况" % refund,1.55)
	rescue_count+=1
	rescue_time=0
	rescued_lately=0.85
	if peek_label: peek_label.hide()

func road_jump() -> void:
	if not airborne:
		lift_v=5.7
		airborne=true
		wind_spent=false
		audio.play_cue("wind")
		return
	if wind_spent or (not stops.feather and air<28): return
	wind_spent=true
	lift_v=maxf(2.0,lift_v)+4.6
	var bottled: bool=stops.feather
	if bottled: stops.feather=false
	else:
		sealed=false
		air-=28
	sparks(district.truck.position+Vector3(-1,1.8,0),Art.CREAM,20)
	wind_burst=1.2
	var gust=preload("res://gust.gd").new()
	gust.start(items[1],Vector3(-0.1,1.25,0),Vector3(-1.0,0.18,0.13),4.4,1.05)
	gusts.append(gust)
	audio.play_cue("wind")
	message("西风瓶已用 · 货物余风保全" if bottled else "借风起跳！  ·  风囊余量 −28",1.6)

func settle(e: Dictionary) -> void:
	var guard:=clampf(float(e.guard)/0.82,0.0,1.0)
	var damage:=float(e.damage)*(1.17 if expert else 1.0)*lerpf(1.0,drive_speed,0.45)
	if e.kind in ["gap","ferry"] and e.used:
		damage*=0.11
		jumping=1.0
	var dodged: bool=e.kind in ["curve","stones"] and bool(e.get("dodged",false))
	if dodged: damage*=0.07
	if e.kind=="gap" and not e.used:
		wheel_dmg=12 if guard>=0.75 else 27
	var sleep_factor:=1.13 if previous_order.size()==2 and previous_order[1]==0 else 0.91
	var wind_factor:=1.13 if previous_order.size()==2 and previous_order[1]==1 else 0.91
	var sleep_loss:=roundi(damage*sleep_factor*(0.31 if strap==0 else 1.0)*(1.0-0.80*guard)*(0.36 if expert and corked else 1.0))
	var air_loss:=roundi(damage*0.64*wind_factor*(0.16 if strap==1 else 1.0)*(1.0-0.74*guard))
	calm=maxf(0,calm-sleep_loss)
	air=maxf(0,air-air_loss)
	bounce=minf(1,0.2+damage/42.0*(1-guard*0.65))
	var side: float=-1.0 if e.kind=="stones" else 1.0
	cargo_velocity+=Vector2(side*4.0*(0.25 if strap==0 else 1.0),side*5.3*(0.25 if strap==1 else 1.0))*bounce
	var verb: String
	if e.kind=="gap" and e.used: verb="乘风过桥"
	elif dodged: verb="顺利绕过"
	elif guard>0.73: verb="稳住了"
	elif guard>0.17: verb="货物轻碰"
	else: verb="重重一颠"
	report_lines.append("%s · %s" % [e.title,verb])
	sparks(district.truck.position+Vector3(1.9,0.32,0.7),Art.CREAM if dodged or guard>0.73 else Art.SAND,8)
	if e.kind=="gap" and not e.used: verb+="，悬架受损"
	message("%s  ·  %s −%d   余风 −%d" % [verb,condition_name(),sleep_loss,air_loss],2.15)
	audio.play_cue("land" if guard<0.75 else "load")
	e.done=true
	if not dodged and guard<0.67 and not e.used and e.kind!="ferry":
		rescue_item=1-strap
		threatened_loss=sleep_loss if rescue_item==0 else air_loss
		rescue_time=1.65
		rescue_slide=0
		peek_label.show()
		peek_label.text="E  拉回"+cargo_name(rescue_item)

func update_road(delta: float) -> void:
	var real_delta:=delta
	if rescue_time>0:
		rescue_time=maxf(0,rescue_time-real_delta)
		rescue_slide=move_toward(rescue_slide,1.0,real_delta*1.72)
		delta*=0.64
		if rescue_time<=0:
			var extra:=3 if rescue_item==1 else 5
			if rescue_item==0: calm=maxf(0,calm-extra)
			else: air=maxf(0,air-extra)
			message("货物撞上尾栏  ·  货况 −%d" % extra,1.4)
			bounce=maxf(bounce,0.66)
			audio.play_cue("bonk")
			peek_label.hide()
	else:
		rescue_slide=move_toward(rescue_slide,0.0,real_delta*(4.2 if rescued_lately>0 else 2.4))
		rescued_lately=maxf(0,rescued_lately-real_delta)
	var braking:=Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var d:=road_t*5.0
	var mud: float=stops.mud(d,lane_z)
	var incline: float=(stops.ground(d+0.5,lane_z)-stops.ground(d-0.5,lane_z))
	var cross_slope: float=stops.ground(d,lane_z+0.5)-stops.ground(d,lane_z-0.5)
	var sprint:=(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) and not braking and not sprint_locked
	sprint_heat=clampf(sprint_heat+delta*(0.36 if sprint else -0.55),0,1)
	if sprint_heat>=1: sprint_locked=true
	if sprint_heat<=0.08: sprint_locked=false
	var target_speed:=0.0 if braking else (1.72 if sprint else 1.0)
	target_speed*=clampf(1.0-0.37*mud-0.85*incline,0.45,1.40)
	drive_speed=move_toward(drive_speed,target_speed,delta*(2.8 if braking else 2.1))
	road_t+=delta*drive_speed*cos(meadow_heading)
	d=road_t*5.0
	var input_axis:=float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var old_speed:=lane_v
	var steer_gain:=minf(1,drive_speed*2.0)*(1.0-0.28*mud)
	var drift:=cross_slope*minf(1,drive_speed) if not airborne else 0.0
	var loose_ground:=smoothstep(2.2,3.9,lane_z)
	if loose_ground>0.0 and input_axis!=0:
		meadow_heading=clampf(meadow_heading+input_axis*delta*1.55*steer_gain,-0.98,0.98)
	else:
		meadow_heading=move_toward(meadow_heading,0,delta*lerpf(3.0,0.25,loose_ground))
	var lateral:=lerpf(input_axis*3.65*steer_gain,sin(meadow_heading)*5.0*drive_speed,loose_ground)
	lane_v=move_toward(lane_v,lateral-drift,delta*(7.0 if airborne else 17.5))
	var edge: float=1.70+stops.meadow_width(d)
	lane_z=clampf(lane_z+lane_v*delta,-1.70,edge)
	if (lane_z>=edge and lane_v>0) or (lane_z<=-1.7 and lane_v<0): lane_v=0
	var floor_y: float=stops.ground(d,lane_z)
	var before_y:=chassis_y
	if not airborne and floor_y<chassis_y+lift_v*delta-0.005:
		airborne=true
	if airborne and delta>0:
		lift_v-=13.0*delta
		chassis_y+=lift_v*delta
		if chassis_y<=floor_y:
			var strike:=maxf(0,-lift_v+incline*drive_speed*5.0)
			chassis_y=floor_y
			airborne=false
			wind_spent=false
			bounce=maxf(bounce,clampf(strike*0.065,0,0.85))
			if strike>8.0:
				var loss:=roundi((strike-7.0)*(0.45 if braking else 0.9))
				calm=maxf(0,calm-loss)
				message("重落地 · %s −%d" % [condition_name(),loss],1.25)
			audio.play_cue("land")
	if not airborne and delta>0:
		chassis_y=floor_y
		lift_v=clampf((floor_y-before_y)/delta,-3.2,3.2)
	var hop_height:=maxf(0.0,chassis_y-floor_y)
	ground_pitch=lerpf(ground_pitch,clampf(atan(incline),-0.42,0.42),minf(1,delta*8))
	ground_bank=lerpf(ground_bank,-clampf(atan(cross_slope),-0.48,0.48),minf(1,delta*8))
	stops.advance(self,hop_height)
	var acceleration:=clampf((lane_v-old_speed)/maxf(delta,0.001),-24,24)
	current_event=-1
	var amplitude:=0.0
	var warning:=2.9 if not expert else 2.1
	for i in events.size():
		var e: Dictionary=events[i]
		var relative:=road_t-float(e.at)
		if relative>=-warning and relative<1.45 and not e.done:
			current_event=i
			if warned!=i:
				warned=i
				audio.play_cue("warn")
			if relative>=-0.12 and relative<0.49 and wind_spent and hop_height>0.48 and e.kind in ["gap","ferry"]:
				e.used=true
			if relative>=-0.15 and not e.has("dodged"):
				var obstacle: float=(-0.78 if e.kind=="stones" else (-0.95 if i>=3 else 0.98)+sin(road_t*0.82)*0.41)
				e.dodged=absf(lane_z-obstacle)>1.12 or hop_height>(0.80 if e.kind=="curve" else 0.62)
			amplitude=1.0-clampf(absf(relative)/warning,0,1)
			if relative>=-0.58 and relative<=0.49 and braking:
				e.guard+=delta*drive_speed
			if relative>=0.49:
				settle(e)
	var braced:=braking
	var driver=district.truck.get_node_or_null("Driver")
	if driver: driver.rotation.z=sin(t*7.1)*0.016-bounce*0.15
	stamina=100.0*(1.0-sprint_heat)
	wind_burst=move_toward(wind_burst,0,delta)
	jumping=move_toward(jumping,0,delta*0.84)
	bounce=move_toward(bounce,0,delta*0.76)
	weather_strength=lerpf(weather_strength,amplitude,minf(1,delta*4))
	var v:=5.0*drive_speed
	district.tick(t,v,delta)
	district.travel(road_t)
	for wheel in get_tree().get_nodes_in_group("wheels"):
		wheel.rotation.z-=v*delta*0.8
	var sway:=sin(road_t*5.1)*weather_strength*0.052+sin(road_t*16.0)*bounce*0.077
	var gap_wave:=0.0
	if route==0:
		var jump_event: Dictionary=events[2]
		var phase:=clampf((road_t-20.4)/1.68,0,1)
		gap_wave=0.0 if airborne or jump_event.used else -0.22*sin(phase*PI)
	gap_wave+=chassis_y
	var distance:=road_t*5.0
	district.truck.position=district.pos(distance,lane_z,0.06+absf(sin(road_t*8))*0.043+gap_wave)
	district.truck.rotation.y=district.heading(distance)-lerpf(lane_v*0.057,meadow_heading,loose_ground)
	var chase:=smoothstep(0.0,1.7,road_t)*smoothstep(0.0,2.0,road_end-road_t)
	var yaw: float=district.heading(distance)+lerpf(1.12,0.0,chase)
	camera.position=district.pos(distance,lane_z*lerpf(0.66,0.94,loose_ground))+Vector3(-cos(yaw)*10,lerpf(10.5,7.8,chase),sin(yaw)*10)
	camera.position.y+=floor_y*0.85
	camera.look_at(district.pos(distance+lerpf(0,4.2,chase),lane_z*lerpf(0.57,0.94,loose_ground),0.78+floor_y*0.85))
	district.truck.rotation.z=sway*0.32+ground_pitch+clampf(lift_v*0.025,-0.15,0.18)
	district.truck.rotation.x=sway-lane_v*0.035+ground_bank
	for i in 2:
		var restrained:=strap==i
		var freedom:=0.24 if restrained else (0.54 if braced else 1.0)
		var stiffness:=43.0 if i==0 else 32.0
		var damping:=8.5 if restrained else (5.8 if i==0 else 4.4)
		cargo_velocity[i]+=((-acceleration*0.78-cross_slope*9.0)*freedom-stiffness*cargo_shift[i]-damping*cargo_velocity[i])*delta
		cargo_shift[i]+=cargo_velocity[i]*delta
		var limit:=0.17 if restrained else 0.64
		if absf(cargo_shift[i])>limit:
			cargo_shift[i]=signf(cargo_shift[i])*limit
			cargo_velocity[i]*=-0.43
		var slide:=rescue_slide if rescue_item==i else 0.0
		var offset:=cargo_shift[i]
		items[i].position.z=clampf(offset+slide*0.76,-0.85,0.99)
		items[i].position.y=1.10+absf(sin(road_t*13.0))*bounce*0.48*freedom+slide*0.10
		items[i].rotation.x=-offset*0.55+slide*0.40
		items[i].rotation.z=sway*freedom*2.6
	if rescue_time>0:
		peek_label.global_position=items[rescue_item].global_position+Vector3.UP*1.9
	items[1].scale=Vector3(0.66+air/292.0,0.75+air/400.0,0.66+air/292.0)
	var ui_hazard: String="路况平稳"
	var ui_signal: String="W 加速，S 刹车稳货。"
	if current_event>=0 and not events[current_event].done:
		var e: Dictionary=events[current_event]
		var left: float=(float(e.at)-road_t)/maxf(0.05,drive_speed)
		ui_hazard="%s   ·   %.1f 秒" % [e.title,maxf(left,0)] if left>0.55 and drive_speed>0.12 else str(e.title)+"   ·   现在稳货！"
		if e.kind=="gap":
			ui_signal="桥边起跳，空中再按空格借风；也可缓行过板" if not e.used else "双跳成功，准备着陆"
			if stops.feather: ui_signal="桥边双跳优先用西风瓶，保住原封奖"
			if e.used: ui_hazard="乘风越桥！"
		elif e.kind=="curve" or e.kind=="stones":
			ui_signal="A / D  左右换道避开障碍   ·   S 刹车稳货"
		else:
			ui_signal="空中再按空格用西风瓶" if stops.feather else "渡船入口有高低差，按 S 缓行稳货"
	elif note_left>0:
		ui_hazard=note
		ui_signal="司机已把本次情况记入货单"
	var upcoming: String=stops.preview(road_t)
	if upcoming!="" and (current_event<0 or events[current_event].done):
		ui_hazard=upcoming
		ui_signal="路面箭头标出奖励线，两侧都能通车"
	if d>46 and d<88 and (current_event<0 or lane_z>3.5) and note_left<=0:
		ui_hazard="右侧山脊便道" if lane_z<3.5 else ("泥地 · 抓地变弱" if mud>0.4 else "草坡 · 留意车厢倾斜")
		ui_signal="沿石路保货，或从右侧草坡绕开落石"
	if rescue_time>0:
		ui_hazard=cargo_name(rescue_item)+"滑出来了！"
		ui_signal="按 E 或点击正在滑落的货物，把它拉回来"
	if ui.ctl.has("hazard"):
		ui.ctl.drive.text="%s   ·   %d 枚%s" % [("刹车" if braking else ("冲刺冷却" if sprint_locked else ("冲刺 %d%%" % roundi(100*(1.0-sprint_heat)) if sprint else "巡航"))),stops.earnings,("   ·   西风瓶 ×1" if stops.feather else "")]
		ui.ctl.hazard.text=ui_hazard
		ui.ctl.signal.text=ui_signal
		ui.ctl.cargo.text="%s  %d%%" % [condition_name(),roundi(calm)]
		ui.ctl.air.text="余风  %d%%" % roundi(air)
		ui.ctl.calm_bar.size.x=maxf(1,133*calm/100)
		ui.ctl.air_bar.size.x=maxf(1,130*air/100)
		ui.ctl.progress.size.x=maxf(2,207*minf(1,road_t/road_end))
		ui.ctl.distance.text="行程   %d%%    /   %s" % [mini(100,roundi(road_t/road_end*100)),("山口" if route==0 else "渡口")]
		ui.ctl.gauge.size.x=maxf(2,335*stamina/100)
	if road_t>=road_end:
		begin_harbor()

func begin_harbor() -> void:
	mode="harbor"
	road_bonus=stops.earnings
	clear_world()
	harbor=preload("res://harbor.gd").new()
	harbor.build(world,expert)
	set_camera(Vector3(-5.5,10.2,15.0),Vector3(-0.25,1.45,-0.28),12.40)
	items=[art.trolley(world) if expert else art.bed(world),art.sack(world)]
	for i in 2:
		items[i].position=harbor.truck.position+Vector3(stow_x(i),1.10,0.0)
	items[0].rotation.y=PI/2
	setup_animated_props()
	crate_index=0
	unload_tip=0
	just_signed=false
	crane_lift()
	ui.harbor_view()
	audio.set_scene("yard")
	audio.play_cue("start")
	action_cooldown=0.20

func crane_lift() -> void:
	crane_stage="lift"
	crane_timer=0
	crane_auto=false
	pendulum=0
	pendulum_dx=0
	crane_dx=0
	pickup_from=items[crate_index].position
	crane_x=pickup_from.x
	unload_line="吊钩已扣好"
	for i in 2:
		harbor.target_rings[i].visible=i==crate_index

func lower_cargo() -> void:
	if crane_stage=="signed":
		finish_order()
		return
	if crane_stage!="carry": return
	var target: float=harbor.slots[crate_index]
	var offset: float=absf(items[crate_index].position.x-target)
	if offset>1.05:
		unload_line="继续移动吊车，对准发光签收垫"
		audio.play_cue("bonk")
		return
	var gentle:=offset<0.44 and absf(crane_dx)<1.78
	crane_stage="lower"
	crane_timer=0
	crane_auto=false
	drop_from=items[crate_index].position
	drop_to=Vector3(target,0.24,0.55)
	if gentle:
		unload_tip+=3
		unload_line="正中软垫  ·  轻放赏钱 ＋3"
		audio.play_cue("load")
	else:
		if crate_index==0: calm=maxf(0,calm-3)
		else: air=maxf(0,air-3)
		unload_line="擦到垫边  ·  "+(condition_name() if crate_index==0 else "余风")+" −3"
		audio.play_cue("drop")

func update_harbor(dt: float) -> void:
	crane_timer+=dt
	var target: float=harbor.slots[crate_index]
	var cargo:=items[crate_index]
	if crane_stage=="lift":
		var ease_lift:=smoothstep(0,1,crane_timer/0.82)
		cargo.position=pickup_from.lerp(Vector3(pickup_from.x,2.23,0.55),ease_lift)
		if crane_timer>=0.82:
			crane_stage="carry"
			crane_timer=0
			unload_line="沿顶轨移动，让货物的影子对准"+("紫金酒垫" if expert and crate_index==0 else ("月纹软垫" if crate_index==0 else "风纹软垫"))
	elif crane_stage=="carry":
		var manual:=float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		if manual!=0: crane_auto=false
		var desired:=manual*4.85
		if crane_auto: desired=clampf((target-crane_x)*2.1,-4.1,4.1)
		var prev:=crane_dx
		crane_dx=move_toward(crane_dx,desired,dt*(7.2 if desired!=0 else 9.4))
		crane_x=clampf(crane_x+crane_dx*dt,-7.4,6.8)
		pendulum_dx+=-(crane_dx-prev)*0.43
		pendulum_dx+=(-pendulum*7.9-pendulum_dx*3.6)*dt
		pendulum=clampf(pendulum+pendulum_dx*dt,-0.84,0.84)
		cargo.position=Vector3(crane_x+pendulum,2.24+absf(pendulum)*0.16,0.55)
		cargo.rotation.z=pendulum*0.18
		var dist:=absf(target-cargo.position.x)
		if dist<0.44 and absf(crane_dx)<1.78: unload_line="已经对准  ·  空格轻放，争取赏钱"
		elif dist<=1.05: unload_line="已到垫边  ·  松开方向，等货物稳住"
		else: unload_line="A / D 移吊车，也可以点击发光签收垫"
	elif crane_stage=="lower":
		var u:=clampf(crane_timer/0.65,0,1)
		cargo.position=drop_from.lerp(drop_to,smoothstep(0,1,u))
		cargo.rotation.z*=maxf(0,1-dt*7)
		if crane_timer>=0.65:
			crane_stage="handoff"
			crane_timer=0
			sparks(drop_to+Vector3.UP*0.68,Art.GOLD,15)
			audio.play_cue("load")
	elif crane_stage=="handoff":
		harbor.customers[crate_index].rotation.x=-sin(minf(1,crane_timer/0.75)*PI)*0.16
		if crane_timer>=1.15:
			if crate_index==0:
				crate_index=1
				crane_lift()
				ui.harbor_view()
			else:
				crane_stage="signed"
				for ring in harbor.target_rings: ring.hide()
				unload_line="两份委托均已签收"
				ui.harbor_view()
				audio.play_cue("win")
	harbor.rope(crane_x,cargo.position+Vector3.UP*(1.40 if crate_index==0 else 1.38))
	if crane_stage=="signed": harbor.shadow.hide()
	if ui.ctl.has("crane"):
		ui.ctl.crane.text=unload_line
		var offset:=absf(items[crate_index].position.x-harbor.slots[crate_index])
		var x:=clampf((items[crate_index].position.x-harbor.slots[crate_index])/3.8,-1,1)
		ui.ctl.marker.position.x=640+x*153-4
		ui.ctl.marker.modulate=Color("#8fdbb5") if offset<0.44 else Color.WHITE

func finish_order() -> void:
	if mode!="harbor" or just_signed: return
	just_signed=true
	mode="receipt"
	var base:=130 if expert else 100
	var fare:=14 if route==1 else 0
	var st:=roundi((36.0 if expert else 25.0)*calm/100)
	var wt:=roundi(20*air/100)+(5 if sealed else 0)
	var goods_claim:=15 if calm<45 else 0
	var claim: int=goods_claim+wheel_dmg+(9 if expert and corked else 0)
	var net: int=base-fare+st+wt-claim+unload_tip+road_bonus
	receipt_data={"base":base,"fare":fare,"sleep_tip":st,"wind_tip":wt,"claim":claim,"net":net,"calm":roundi(calm),"air":roundi(air),"route_name":"山口飞桥" if route==0 else "渡船码头"}
	receipt_data.road_bonus=road_bonus
	receipt_data.axle=wheel_dmg
	receipt_data.damage_fee=goods_claim
	receipt_data.wax_fee=9 if expert and corked else 0
	receipt_data.sealed=sealed
	receipt_data.catches=rescue_count
	receipt_data.unload_tip=unload_tip
	receipt_data.yard_seconds=roundi(yard_seconds)
	var record_id: String="wine" if expert else "sleep"
	var old_record:=int(personal_records.get(record_id,0))
	receipt_data.previous_best=old_record
	personal_records[record_id]=maxi(net,old_record)
	jobs+=1
	cash_best=maxi(cash_best,net)
	save_record()
	var windline:="绳结没动。\n这趟送得漂亮！" if air>=93 else ("等等……这袋风\n怎么瘦了一圈？" if air<76 else "少了几缕西风。\n我可都记着呢。")
	var sleepline:="已经到了？\n我连梦都没做完。" if calm>=86 else ("你们是把床\n一路滚过来的吗？" if calm<58 else "有点颠……\n好在枕头还在。")
	if rescue_count>0 and calm>=75: sleepline="我梦见床在飞。\n又被一只手接住了。" 
	if expert:
		sleepline="封蜡漂亮，酒香全在。\n今晚请你喝头一杯！" if corked and calm>82 else ("颠归颠，宴席\n还开得成。" if calm>61 else "这一车酒……\n给车轮喝了多少？")
	ui.receipt(receipt_data,windline,sleepline)
	audio.play_cue("win")
	audio.set_scene("title")

func pause_game() -> void:
	if mode not in ["road","load","rig","brief","harbor"]: return
	toss_charge=0
	paused_from=mode
	mode="pause"
	ui.pause_overlay()
	audio.play_cue("page")

func resume_game() -> void:
	mode=paused_from
	match mode:
		"load": ui.loading(); sync_load(0)
		"road": ui.road(); update_road(0)
		"harbor": ui.harbor_view(); update_harbor(0)
		"rig": ui.rig(strap,route,expert)
		"brief": ui.briefing(expert)
	action_cooldown=0.15

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo: return
	if mode=="load" and event.keycode==KEY_SHIFT:
		if event.pressed: begin_throw()
		else: release_throw()
		return
	if not event.pressed: return
	var key: Key=event.keycode
	if key==KEY_M:
		toggle_sound()
		return
	if key==KEY_F11:
		var win:=get_window()
		win.mode=Window.MODE_WINDOWED if win.mode==Window.MODE_EXCLUSIVE_FULLSCREEN else Window.MODE_EXCLUSIVE_FULLSCREEN
		return
	if key==KEY_ESCAPE:
		if mode=="pause": resume_game()
		else: pause_game()
		return
	if action_cooldown>0: return
	if mode=="road" and key==KEY_SPACE:
		road_jump()
		return
	if key==KEY_SPACE or key==KEY_ENTER:
		match mode:
			"title": begin_dispatch()
			"brief": begin_load()
			"load": interact()
			"rig": begin_road()
			"harbor": lower_cargo()
	elif mode=="load" and key==KEY_R and held>=0:
		toss_charge=0
		cargo_pos[held]=(Vector2(-4.55,0.73) if held==0 else Vector2(-2.43,-2.25)) if expert else ORIGINS[held]
		angles[held]=0
		held=-1
		message("货物已放回取货位置",1.2)
	elif mode=="load" and key==KEY_F:
		if expert and held==0: seal_urn()
		else: gust_gate()
	elif mode=="road" and key==KEY_E: catch_cargo()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
	if mode=="road" and rescue_time>0:
		var pos:=camera.unproject_position(items[rescue_item].global_position+Vector3.UP*0.75)
		if pos.distance_to(event.position)<115:
			catch_cargo()
	elif mode=="harbor" and crane_stage=="carry":
		var target:=camera.unproject_position(Vector3(harbor.slots[crate_index],0.3,0.55))
		if target.distance_to(event.position)<112:
			if absf(items[crate_index].position.x-harbor.slots[crate_index])<0.7: lower_cargo()
			else: crane_auto=true
	elif mode=="rig" and event.position.x<751:
		for i in 2:
			var pos:=camera.unproject_position(items[i].global_position+Vector3.UP*0.7)
			if pos.distance_to(event.position)<58:
				set_strap(i)
				break

func _physics_process(delta: float) -> void:
	action_cooldown=maxf(0,action_cooldown-delta)
	if mode=="pause": return
	t+=delta
	note_left=maxf(0,note_left-delta)
	bonk_left=maxf(0,bonk_left-delta)
	animate_puffs(delta)
	for i in range(gusts.size()-1,-1,-1):
		if not is_instance_valid(gusts[i]) or not gusts[i].advance(delta): gusts.remove_at(i)
	if mode=="load":
		update_flight(delta)
		if mode=="load": sync_load(delta)
	if mode in ["load","rig","road","harbor"]: animate_freight(delta)
	if mode=="harbor": update_harbor(delta)
	if mode=="road": update_road(delta)
	elif mode in ["brief","rig","load"]: district.tick(t,0,delta)






