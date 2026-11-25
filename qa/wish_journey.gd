extends SceneTree
var town
var boat
var errors:=0
var frames:=0
var movie:=OS.get_cmdline_user_args().has("--film")
var album:=OS.get_environment("WISH_PHOTOS")
func _initialize()->void:call_deferred("run")
func check(ok:bool,msg:String)->void:
	print("PASS " if ok else "FAIL ",msg)
	if not ok:errors+=1
func tap(code:Key)->void:
	var e:=InputEventKey.new();e.pressed=true;e.keycode=code;e.physical_keycode=code
	Input.parse_input_event(e);Input.flush_buffered_events();e=e.duplicate();e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events()
func tick(n:int)->void:
	for i in n:
		if movie:await process_frame
		else:
			boat._physics_process(1./60.)
			if i%45==0:await process_frame
func shot(id:String)->void:
	if album!="" and DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(album+"/"+id+".png")
	print("VIEW ",id," frame ",Engine.get_process_frames())
func skip(host)->void:
	var film=host.get_node_or_null("ArrivalFilm")
	if film:
		tap(KEY_ESCAPE)
		if not movie:film._process(.75)
		while is_instance_valid(film):await process_frame
func boot()->void:
	town=load("res://vineyard.tscn").instantiate();root.add_child(town)
	await process_frame;await process_frame
func run()->void:
	var seed:=ConfigFile.new();seed.set_value("bell","done",true);seed.save(OS.get_environment("OLYMPUS_TRIAL_PROFILE"))
	await boot()
	check(town.board.visible and town.board.rows.filter(func(b):return b.visible).size()==2,"a bell delivery reveals only bell and night passage")
	tap(KEY_V);check(town.board.visible and town.dock_order==null,"hidden shortcut cannot enter wind route")
	await shot("01-log")
	tap(KEY_ENTER);await process_frame;boat=town.dock_order
	await skip(boat)
	if not movie:boat.set_physics_process(false)
	# Approach the posted sheet from the playable channel with the real helm.
	var start:Vector2=boat.pos
	boat.heading=(boat.wishes.LANDING-boat.pos).angle();boat.view_heading=boat.heading
	boat.pose(1.,0.)
	var forward:=InputEventKey.new();forward.keycode=KEY_W;forward.physical_keycode=KEY_W;forward.pressed=true
	Input.parse_input_event(forward);Input.flush_buffered_events()
	for i in 360:
		await tick(1)
		if boat.pos.distance_to(boat.wishes.LANDING)<2.3:break
	forward.pressed=false;Input.parse_input_event(forward);Input.flush_buffered_events()
	var brake:=forward.duplicate();brake.pressed=true;brake.keycode=KEY_S;brake.physical_keycode=KEY_S;Input.parse_input_event(brake);Input.flush_buffered_events()
	for i in 120:
		if boat.speed<.45:break
		await tick(1)
	brake.pressed=false;Input.parse_input_event(brake);Input.flush_buffered_events();await tick(10)
	check(boat.pos.distance_to(start)>2. and boat.wishes.near_boat(),"board reachable by sailing from the arrival steps")
	await shot("02-quay")
	tap(KEY_E);tap(KEY_E);check(boat.wishes.reading and not town.knows(1),"reading cannot accept on the same press")
	await tick(55);await shot("03-note");tap(KEY_ESCAPE);check(not boat.wishes.reading and not town.knows(1),"putting the note back keeps the offer")
	tap(KEY_E);await tick(55 if not movie else 85)
	tap(KEY_E);await process_frame;await process_frame;await process_frame
	var dock=town.dock_order
	check(town.knows(1) and dock!=null and dock.has_method("start_voyage"),"accepted letter takes you into the lens warehouse")
	if dock==null or not dock.has_method("start_voyage"):quit(1);return
	var opening=dock.get_node_or_null("ArrivalFilm")
	check(opening!=null and opening.setting=="lens","physical wish leads into the warehouse scene")
	if movie:
		for i in 125:await process_frame
	await shot("04-warehouse");await skip(dock)
	dock.left_dock.emit(0);await process_frame;await process_frame
	check(town.dock_order!=null and town.dock_order.has_method("depart_blue_quay"),"leaving a shore commission returns to the living quay")
	boat=town.dock_order;await skip(boat);boat.left_dock.emit(0);await process_frame;await process_frame
	check(town.board.visible and town.board.rows[1].visible and not town.board.rows[3].visible,"accepted lens is available but later jobs stay hidden")
	town.queue_free();await process_frame;await boot()
	check(town.knows(1) and not town.knows(3),"accepted promise survives disk restart")
	town.day_best=60
	check(town.next_wish()==3,"after the lighthouse the mill writes")
	town.wind_level=1;town.wind_runs=1;town.known_jobs|=1<<3
	check(town.next_wish()==0,"the winegrower hears about the working mill")
	town.known_jobs|=1;town.wine_delivered=true
	check(town.next_wish()==6,"road delivery introduces the dry orchard")
	town.known_jobs|=1<<6;check(town.next_wish()==4,"the baker can ask to bring the hearth")
	town.queue_free();await process_frame;await create_timer(.25).timeout;print("WISH ERRORS ",errors);quit(errors)
