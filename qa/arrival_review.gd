extends SceneTree
var game
var fails:=0
var photos:=OS.get_environment("ARRIVAL_PHOTOS")
func _initialize()->void:call_deferred("run")
func ck(ok:bool,label:String)->void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:fails+=1
func tap(k:Key)->void:
	var e:=InputEventKey.new();e.keycode=k;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events()
	e=e.duplicate();e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events()
func film(host,label:String,skip:=false)->void:
	var scene=host.get_node_or_null("ArrivalFilm")
	ck(is_instance_valid(scene),label+" has opening")
	if scene==null:return
	ck(not host.can_process() and scene.can_process(),label+" gates simulation")
	tap(KEY_E);ck(not scene.leaving,label+" ignores premature action")
	for i in scene.beats.size():
		scene._process(.4)
		if photos!="":
			await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(photos+"/"+label+str(i)+".png")
		if i+1<scene.beats.size():scene._process(4.3)
	scene._process(1.5);tap(KEY_ESCAPE if skip else KEY_E);scene._process(.7)
	await process_frame
	ck(host.can_process() and not is_instance_valid(scene),label+" handoff")
func close_job()->void:
	game.dock_order.left_dock.emit(0);await process_frame;await process_frame
func run()->void:
	var f:=ConfigFile.new();f.set_value("wishes","accepted",255);f.set_value("bell","done",true);f.save(OS.get_environment("OLYMPUS_TRIAL_PROFILE"))
	game=load("res://vineyard.tscn").instantiate();root.add_child(game);await process_frame
	game.book_select(0);await film(game,"wine")
	game.open_board();game.book_select(0);ck(not game.has_node("ArrivalFilm"),"repeat road visit")
	game.book_select(3);await film(game.dock_order,"mill");await close_job()
	game.book_select(4);game.office_action(0);await film(game.dock_order,"stove");await close_job()
	game.book_select(1);var day=game.dock_order;await film(day,"lens")
	day.enter_dive();await film(day.dive,"dive");day.leave_dive(false,0);await process_frame
	day.start_hill();await film(day,"hill",true)
	day.enter_chamber();await film(day,"optics");await close_job()
	game.book_select(6);await film(game,"spring");game.spring.leave() if game.spring.has_method("leave") else game.spring.set("active",false)
	game.bell_song=true;game.open_tide_dock(true,true,true);var night=game.dock_order
	await film(night,"letter");await close_job()
	game.bell_song=false;game.bell_done=false;game.open_tide_dock(true);await film(game.dock_order,"ferry");await close_job()
	game.bell_done=true;game.lamp_step=2;game.open_tide_dock(true);await film(game.dock_order,"lamp");await close_job()
	game.lamp_step=3;game.worker_ticket=true;game.open_tide_dock(true);await film(game.dock_order,"worker");await close_job()
	game.worker_ticket=false;game.lamp_worker_home=true;game.open_tide_dock(true);await film(game.dock_order,"grain");await close_job()
	game.grain_status=2;game.meal_stock=1;game.open_tide_dock(false,true);await film(game.dock_order,"meal")
	await close_job();game.queue_free();await process_frame;await create_timer(.4).timeout
	print("REVIEW ",fails);quit(fails)
