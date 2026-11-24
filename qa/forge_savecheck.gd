extends SceneTree
var base
var job
var errors:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,text:String)->void:
	print("PASS " if ok else "FAIL ",text);if not ok:errors+=1
func boot()->void:
	base=load("res://vineyard.tscn").instantiate();root.add_child(base)
	await process_frame;await process_frame;await process_frame;job=base.dock_order
	if is_instance_valid(job):job.set_physics_process(false)
func relaunch()->void:
	if is_instance_valid(job):job.queue_free()
	base.queue_free();await process_frame;await process_frame;await boot()
func press(key:Key)->void:
	var e:=InputEventKey.new();e.keycode=key;e.physical_keycode=key;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events()
	var release:=e.duplicate() as InputEventKey;release.pressed=false;Input.parse_input_event(release);Input.flush_buffered_events()
func advance(t:float)->void:
	for i in ceili(t*60.):job._physics_process(1./60.)
func run()->void:
	await boot();check(is_instance_valid(job) and job.stage=="opening","new player automatically enters story")
	press(KEY_E);check(job.stage=="call","first bell request held for player input")
	press(KEY_ESCAPE);var t:float=job.age;advance(.48);check(job.pause_panel and job.age==t,"pause freezes opening action")
	await relaunch();check(job.stage=="call" and not job.pause_panel,"cold restart before ringing returns to prompt")
	press(KEY_SPACE);advance(1.3);check(job.stage=="first_drop","first load in motion")
	await relaunch();advance(.10);check(job.stage=="yard" and job.first_worked and job.lift.loads[0].position.y<.5,"checkpoint in lowering resolves to landed load")
	job.pos=job.land.road(1120.);job.attach_bed();job.stage="altar";job.blessing=true;job.switch("mountain");advance(1.50)
	await relaunch();check(job.stage=="drive" and job.blessing and job.mountain_cup.visible,"repaired ceramic ear restored after crosscut")
	job.stage="arrival";job.learned=true;job.mount_bell();advance(11.6);check(job.stage=="ledger","arrival unlocks signed receipt")
	press(KEY_Q);check(job.stage=="invite" and base.bell_done and base.bell_padding,"invoice raises invitation and buys equipment")
	var coins:int=base.wind_wallet
	await relaunch();check(job.stage=="invite" and job.learned and job.previously_paid and base.wind_wallet==coins,"quit during invitation resumes it with no double payment")
	press(KEY_ESCAPE);press(KEY_B);await process_frame;await process_frame;job=base.dock_order
	check(not is_instance_valid(job) and base.bell_record.is_empty() and base.board.visible,"declined invitation returns to board and clears checkpoint")
	await relaunch();check(not is_instance_valid(job) and base.board.visible,"completed account reopens on board")
	base.book_select(7);job=base.dock_order;job.set_physics_process(false);press(KEY_E);press(KEY_E);check(job.stage=="yard","voluntary skip does not block carrying")
	job.stage="ledger";job.learned=true;press(KEY_E);press(KEY_E);press(KEY_E);advance(.75);await process_frame;await process_frame;job=base.dock_order
	check(job!=null and job.has_method("depart_blue_quay") and base.wind_wallet==coins and base.bell_record.is_empty(),"repeat embark input changes scenes once and preserves wallet")
	job.left_dock.emit(0);await process_frame;base.queue_free();await process_frame
	print("FINISH save cases ",errors);quit(errors)

