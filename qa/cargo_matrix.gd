extends SceneTree
var errors:=0
var cues:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,words:String)->void:
	print("PASS " if ok else "FAIL ",words)
	if not ok:errors+=1
func click()->void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events()
	e=e.duplicate();e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events()
func run()->void:
	var seed:=ConfigFile.new()
	seed.set_value("port","day_best",1);seed.save(OS.get_environment("OLYMPUS_TRIAL_PROFILE"))
	var bay=load("res://vineyard.tscn").instantiate();root.add_child(bay)
	await process_frame;await process_frame
	bay.set_physics_process(false);bay.board.hide();bay.stage="drive"
	bay.load_offset=Vector2(0,bay.RAIL.y-.17);bay.load_velocity=Vector2(0,1.15);bay.speed=5.
	bay.track_slip(6.,4.2,1./60.)
	check(bay.catch_left>0. and bay.load_state().contains("左键"),"wine predicts a real rail strike")
	click();check(bay.catch_left==0. and bay.brace_time>0. and bay.brace_travel==.32,"wine click starts finite pull")
	bay.stage="pickup";bay.queue_free();await process_frame
	var world:=Node3D.new();root.add_child(world)
	var art=load("res://workshop.gd").new()
	var hill=load("res://tide_hill.gd").new();world.add_child(hill)
	var van=art.truck(world);var lens=art.jar(van,Vector3.ZERO,.60,"#bd9871")
	hill.cargo_cue.connect(func(id:String):cues.append(id))
	hill.begin(van,lens,false);hill.speed=8.;hill.lateral=.77
	hill.tick(1./60.,1.,-1.)
	check(hill.catch_left>0. and cues==["buckle"],"lens warns once on projected outward slide")
	var start:float=hill.lateral;hill.brace();hill.brace()
	check(hill.brace_left>0. and is_equal_approx(hill.lateral,start) and cues==["buckle","grab"],"lens rejects repeat click")
	for i in 30:hill.tick(1./60.,0.,0.)
	check(absf(start-hill.lateral-.32)<.015,"lens pulls same distance as bronze and wine")
	hill.speed=0.;hill.lateral=.65
	for i in 90:hill.tick(1./60.,0.,0.)
	hill.brace();check(hill.catch_left<=0. and hill.brace_left<=0. and is_equal_approx(hill.lateral,.65),"parking gives no extra lens pull")
	world.queue_free();await process_frame;await create_timer(.3).timeout
	print("CARGO MATRIX ERRORS ",errors);quit(errors)

