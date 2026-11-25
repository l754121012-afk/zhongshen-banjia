extends SceneTree
var g
func _initialize()->void:call_deferred("run")
func frames(n:int)->void:
	for i in n:await process_frame
func key(k:Key,on:bool)->void:
	var e:=InputEventKey.new();e.physical_keycode=k;e.keycode=k;e.pressed=on;Input.parse_input_event(e);Input.flush_buffered_events()
func run()->void:
	var seed:=ConfigFile.new();seed.set_value("bell","done",true);seed.set_value("line","blue_quay",3);seed.save(OS.get_environment("OLYMPUS_TRIAL_PROFILE"))
	g=load("res://vineyard.tscn").instantiate();root.add_child(g)
	if "--fare" in OS.get_cmdline_user_args():
		g.arrival_history["worker"]=true;g.open_tide_dock(true,true,true)
		var n=g.dock_order;n.pos=n.PORTS[3]+Vector2(-2.4,0);n.port=3;n.speed=0.;n.heading=PI;n.view_heading=PI;n.cam_ready=false;n.pose(1.,0.)
		await frames(30);n.use();await frames(155)
		n.depart_blue_quay();await frames(32);n.use();await frames(155)
		print("FARE ",g.worker_runs," wallet ",g.wind_wallet)
	else:
		g.open_bell();var b=g.dock_order;b.attach_bed();b.pos=b.land.road(115.);b.yaw=(b.land.road(127.)-b.pos).angle();b.stage="drive";b.speed=0.;b.slip=.48;b.age=4.;b.pose(1.)
		key(KEY_W,true);await frames(70);key(KEY_D,true);await frames(15);key(KEY_D,false)
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;Input.parse_input_event(click);Input.flush_buffered_events()
		await frames(21);key(KEY_W,false);await frames(32);key(KEY_S,true);await frames(25);key(KEY_S,false);await frames(15)
		print("ROAD ",b.pos," speed ",b.speed)
	quit()
