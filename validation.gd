extends Node
var report: FileAccess
var app
var passed:=0
var failed:=0
var keys: Dictionary={}
func _ready() -> void:
	call_deferred("test")
func check(ok: bool,desc: String) -> void:
	if ok: passed+=1
	else: failed+=1
	print("PASS " if ok else "FAIL ",desc)
	if report:
		report.store_line(("PASS " if ok else "FAIL ")+desc)
		report.flush()
func key(code: Key,down: bool) -> void:
	if keys.get(code,false)==down:return
	keys[code]=down
	var ev:=InputEventKey.new()
	ev.keycode=code
	ev.physical_keycode=code
	ev.pressed=down
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
func tick(n: int=1) -> void:
	for i in n:
		app._physics_process(1.0/60.0)
func tap(code: Key) -> void:
	key(code,true)
	tick(2)
	key(code,false)
	tick(14)
func go(target: Vector2,center:=false) -> bool:
	var start: Vector2=app.cargo_pos[app.held] if center and app.held>=0 else app.player
	var last:=Vector2.INF
	var stuck:=0
	for i in 260:
		var pos: Vector2=app.cargo_pos[app.held] if center and app.held>=0 else app.player
		var d:=target-pos
		if d.length()<0.09: break
		if pos.distance_to(last)<0.0004:stuck+=1
		else:stuck=0
		if stuck>8:
			print("stalled at ",pos," toward ",target," held ",app.held)
			break
		last=pos
		var path: Vector2=target-start
		var along:=clampf((pos-start).dot(path.normalized())+0.13,0,path.length())
		var input: Vector2=(start+path.normalized()*along-pos).rotated(0.155)
		key(KEY_A,input.x < -0.028)
		key(KEY_D,input.x > 0.028)
		key(KEY_W,input.y < -0.028)
		key(KEY_S,input.y > 0.028)
		tick()
	for k in [KEY_A,KEY_D,KEY_W,KEY_S]:key(k,false)
	var end: Vector2=app.cargo_pos[app.held] if center and app.held>=0 else app.player
	if end.distance_to(target)>=0.13: print("miss target ", target," got ",end," grip ",app.grip," player ",app.player," angle ",app.angles[0])
	return end.distance_to(target)<0.13
func click_at(pos: Vector2) -> void:
	var ev:=InputEventMouseButton.new()
	ev.button_index=MOUSE_BUTTON_LEFT
	ev.position=pos
	ev.pressed=true
	get_tree().root.push_input(ev,true)
	ev=ev.duplicate()
	ev.pressed=false
	get_tree().root.push_input(ev,true)

func sign_off() -> void:
	check(app.mode=="harbor","road reaches physical harbor")
	for i in 2:
		tick(80)
		var target: float=app.harbor.slots[i]
		click_at(app.camera.unproject_position(Vector3(target,0.3,0.55)))
		tick(290)
		check(absf(app.items[i].position.x-target)<0.45,"crane moves to pad "+str(i))
		tap(KEY_SPACE)
		tick(138)
	check(app.crane_stage=="signed","both cargoes signed")
	tap(KEY_SPACE)
	check(app.mode=="receipt","delivery receipt opens")
func capture_if_requested(id: String) -> void:
	if not OS.get_cmdline_user_args().has("--render-qa"): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path:=OS.get_environment("OLYMPUS_QA_DIR").path_join(id+".png")
	get_viewport().get_texture().get_image().save_png(path)
func test() -> void:
	app=get_parent()
	var folder:=OS.get_environment("OLYMPUS_QA_DIR")
	report=FileAccess.open(folder.path_join("release-check.txt"),FileAccess.WRITE)
	if report: report.store_line("Godot "+str(Engine.get_version_info().string)+" / release="+str(OS.has_feature("release")))
	app.set_physics_process(false)
	await get_tree().process_frame
	tick(20)
	tap(KEY_SPACE)
	check(app.mode=="brief","title opens dispatch via input")
	tap(KEY_SPACE)
	check(app.mode=="load","dispatch opens yard via input")
	await capture_if_requested("retail-yard")
	if app.mode!="load":
		get_tree().quit(1);return
	check(go(Vector2(-5.13,1.11)) and go(Vector2(-5.11,-1.08)),"walk to couch handle")
	tap(KEY_SPACE)
	check(app.held==0,"grip couch")
	check(not app.legal(Vector2(-0.8,0),0,app.FREIGHT[0]),"crosswise couch stopped by doorway")
	key(KEY_E,true);tick(45);key(KEY_E,false)
	check(absf(app.angles[0]-PI/2)<0.06,"rotate couch through actual key")
	check(go(Vector2(-3.48,0),true) and go(Vector2(0.94,0),true),"carry rotated couch along door and ramp")
	tap(KEY_SPACE)
	check(app.loaded[0],"couch loaded from ramp")
	check(go(Vector2(-2.60,0.16)) and go(Vector2(-2.64,1.75)),"walk to windsack")
	tap(KEY_SPACE)
	check(app.held==1,"grip sack")
	tap(KEY_F)
	check(app.gate_fired and app.yard_air==84 and not app.sealed,"wind opens actual shutter and consumes 16 air")
	check(go(Vector2(-1.95,2.22),true) and go(Vector2(0.42,2.22),true) and go(Vector2(0.93,0.90),true),"opened shortcut is traversable")
	tap(KEY_SPACE)
	check(app.mode=="rig","second cargo advances to loading plan")
	if app.mode!="rig":
		print("unfinished position ",app.player," cargo ",app.cargo_pos)
		get_tree().quit(1);return
	var before: float=app.stow_x(0)
	app.swap_positions()
	check(app.stow_x(0)!=before,"swap changes physical cargo position")
	app.set_strap(1)
	app.set_route(0)
	tap(KEY_SPACE)
	check(app.mode=="road" and app.air==84,"road inherits yard condition")
	await capture_if_requested("retail-road")
	key(KEY_A,true);tick(55);key(KEY_A,false)
	tick(310)
	check(app.events[0].get("dodged",false),"steering avoids barrel")
	tap(KEY_ESCAPE)
	var frozen: float=app.road_t
	tick(60)
	check(app.mode=="pause" and app.road_t==frozen,"pause freezes delivery")
	tap(KEY_ESCAPE)
	while app.mode=="road" and app.road_t<20.45:tick()
	tap(KEY_SPACE);tap(KEY_SPACE)
	while app.road_t<21.0: tick()
	check(app.events[2].used,"wind boost in bridge window")
	while app.mode=="road":tick()
	sign_off()
	check(app.receipt_data.fare==0 and app.receipt_data.claim==0 and app.receipt_data.air<84,"mountain pays actual wind, avoids axle claim")
	var net: int=app.receipt_data.road_bonus+app.receipt_data.unload_tip+app.receipt_data.base+app.receipt_data.sleep_tip+app.receipt_data.wind_tip-app.receipt_data.fare-app.receipt_data.claim
	check(net==app.receipt_data.net,"receipt balances")
	# Same tracked loadout under an alternate route and no timed rescue.
	app.route=1;app.begin_road()
	while app.mode=="road":tick()
	sign_off()
	check(app.receipt_data.fare==14 and app.receipt_data.axle==0,"ferry charge and intact suspension")
	app.route=0;app.begin_road()
	while app.mode=="road":tick()
	sign_off()
	check(app.receipt_data.claim>=27,"unassisted hard landing has real cost")
	app.begin_expert();app.begin_load();tick(20)
	check(app.expert and app.items[0].has_node("Amphora0"),"second commission uses real wine trolley")
	tap(KEY_SPACE)
	check(app.held==0,"new depot spawn reaches trolley")
	check(go(Vector2(-5.55,1.43),true),"trolley can reach sealing bench")
	tap(KEY_F)
	check(app.corked,"seal both urns at bench")
	key(KEY_E,true);tick(45);key(KEY_E,false)
	check(go(Vector2(-4.57,0.0),true) and go(Vector2(0.95,0.0),true),"wine trolley fits long-axis route")
	tap(KEY_SPACE)
	check(app.loaded[0],"wine trolley stowed")
	check(go(Vector2(-2.55,0.03)) and go(Vector2(-2.43,-1.55)),"walk to second-order sack")
	tap(KEY_SPACE)
	check(app.held==1,"pick up second-order sack")
	check(go(Vector2(-1.62,0.0),true),"position for throw")
	key(KEY_SHIFT,true);key(KEY_D,true);tick(50);key(KEY_D,false);key(KEY_SHIFT,false)
	tick(46)
	check(app.mode=="rig" and app.loaded[1],"charged throw lands on truck")
	if app.mode!="rig":
		print("throw stopped at ",app.cargo_pos," held ",app.held);get_tree().quit(1);return
	app.set_strap(1);app.set_route(1);app.begin_road()
	while app.mode=="road" and app.rescue_time<=0 and app.road_t<19:tick()
	check(app.rescue_time>0,"unguarded impact starts actual cargo slip")
	var old: float=app.calm
	tap(KEY_E)
	check(app.rescue_count==1 and app.calm>=old,"timely catch restores actual cargo condition")
	while app.mode=="road":tick()
	sign_off()
	check(app.receipt_data.base==130 and app.receipt_data.wax_fee==9 and app.receipt_data.fare==14,"second order bills wax and ferry once")
	await capture_if_requested("retail-wine-receipt")
	check(app.receipt_data.unload_tip==6,"two gentle deliveries award six")
	check(app.receipt_data.net==app.receipt_data.road_bonus+app.receipt_data.base+app.receipt_data.sleep_tip+app.receipt_data.wind_tip+app.receipt_data.unload_tip-app.receipt_data.fare-app.receipt_data.claim,"second-order receipt balances")
	var peaks:=Vector2.ZERO
	for tied in 2:
		app.strap=tied
		app.begin_road()
		key(KEY_D,true)
		tick(9)
		check(app.lane_z>0.12 and app.cargo_shift.y<0,"right steer moves truck right and load leans left")
		key(KEY_D,false)
		app.begin_road()
		while not app.events[0].done: tick()
		for frame in 38:
			tick()
			peaks[tied]=maxf(peaks[tied],absf(app.cargo_shift.y))
	check(peaks.x>peaks.y*2.5,"same barrel hit gives loose sack more travel than strapped sack")
	var line:="Sack lateral spring peak, loose %.3f / strapped %.3f world units" % [peaks.x,peaks.y]
	print(line)
	if report: report.store_line(line)
	app.route=0
	app.begin_road()
	key(KEY_S,true);tick(30)
	check(app.drive_speed<0.6 and app.road_t<0.4,"brake buys approach time")
	key(KEY_S,false)
	key(KEY_A,true);tick(40);key(KEY_A,false)
	while app.road_t<3.1: tick()
	check(app.stops.earnings==3,"coin on left line credits wallet once")
	while app.road_t<7.1: tick()
	key(KEY_D,true);tick(75);key(KEY_D,false)
	while app.road_t<9.06: tick()
	tap(KEY_SPACE)
	while app.road_t<9.47: tick()
	check(app.stops.earnings==8,"airborne hurdle earns five")
	while app.road_t<14.2: tick()
	key(KEY_A,true);tick(75);key(KEY_A,false)
	while app.road_t<17.0: tick()
	check(app.stops.feather,"left approach collects wind bottle")
	while app.road_t<20.40: tick()
	var reserve: float=app.air
	var original_seal: bool=app.sealed
	tap(KEY_SPACE);tap(KEY_SPACE)
	while app.road_t<21.0: tick()
	check(app.events[2].used and not app.stops.feather and app.air==reserve and app.sealed==original_seal,"bottle powers crossing and preserves cargo wind")
	while app.road_t<22.55: tick()
	key(KEY_W,true)
	while app.road_t<23.8: tick()
	check(app.drive_speed>1.39 and app.stops.earnings==15,"sprint gate awards seven")
	key(KEY_W,false)
	while app.mode=="road": tick()
	sign_off()
	check(app.receipt_data.road_bonus==15 and app.receipt_data.net==app.receipt_data.base+app.receipt_data.wind_tip+app.receipt_data.sleep_tip+app.receipt_data.unload_tip+15-app.receipt_data.claim,"all road prizes appear on signed receipt")
	app.route=1
	app.begin_road()
	key(KEY_D,true);tick(40);key(KEY_D,false)
	while app.road_t<9.35: tick()
	var before_hurdle: float=app.calm
	tick(12)
	check(app.calm==maxf(0,before_hurdle-5) and app.stops.earnings==0,"grounded hurdle takes condition and awards no coin")
	while app.road_t<17.1: tick()
	check(not app.stops.feather,"wrong lane misses the bottle")
	while app.road_t<20: tick()
	tap(KEY_SPACE)
	check(not app.events[2].used,"ferry without bottle still uses boarding planks")
	while app.road_t<23.9: tick()
	check(app.stops.earnings==0,"cruising through express gate earns no prize")
	app.route=0
	app.begin_road()
	tick(28)
	tap(KEY_SPACE)
	check(app.airborne and not app.wind_spent and app.air==app.yard_air,"first space jumps without spending wind")
	tap(KEY_SPACE)
	var after_wind: float=app.air
	var lifted: float=app.chassis_y
	tap(KEY_SPACE)
	check(app.wind_spent and after_wind==app.yard_air-28 and app.air==after_wind and app.chassis_y>lifted,"second press lifts anywhere and third press costs nothing")
	tick(150)
	check(not app.airborne and not app.wind_spent,"landing resets jump")
	app.air=12
	tap(KEY_SPACE);tap(KEY_SPACE)
	check(not app.wind_spent and app.air==12,"low wind leaves normal jump intact")
	key(KEY_S,true);tick(70)
	var stopped: float=app.road_t
	tick(70)
	check(app.road_t==stopped and app.drive_speed==0,"brake can hold full stop")
	key(KEY_S,false)
	while app.road_t<9.8: tick()
	key(KEY_D,true)
	var max_y:=0.0
	var max_mud:=0.0
	var max_bank:=0.0
	while app.road_t<14.2:
		tick()
		max_y=maxf(max_y,app.chassis_y)
		max_bank=maxf(max_bank,absf(app.ground_bank))
		max_mud=maxf(max_mud,app.stops.mud(app.road_t*5,app.lane_z))
	key(KEY_D,false)
	check(max_mud>0.5 and max_y>2.5 and max_bank>0.2,"driver leaves pavement, crosses mud and climbs banked ridge")
	check(app.events[1].get("dodged",false),"meadow line bypasses rockfall")
	while app.mode=="road" and app.road_t<20: tick()
	check(app.lane_z<=1.71 and app.chassis_y<0.1,"ridge rejoins bridge approach at road level")
	print("TOTAL ",passed," passed, ",failed," failed")
	app.audio.stop_all()
	OS.delay_msec(180)
	for i in 10: await get_tree().process_frame
	if report:
		report.store_line("TOTAL %d passed, %d failed" % [passed,failed])
		report.flush()
	for i in 8: await get_tree().process_frame
	get_tree().quit(1 if failed else 0)









