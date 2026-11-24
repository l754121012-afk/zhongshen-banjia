extends SceneTree
var base
var job
var failures:=0
var keys:Dictionary={}
var dt:=1./60.

func _initialize()->void:call_deferred("run")
func check(ok:bool,words:String)->void:
	print("PASS " if ok else "FAIL ",words)
	if not ok:failures+=1
func keycode(k:Key,down:bool)->void:
	if keys.get(k,false)==down:return
	keys[k]=down
	var key:=InputEventKey.new();key.pressed=down;key.keycode=k;key.physical_keycode=k
	Input.parse_input_event(key);Input.flush_buffered_events()
func tap(k:Key)->void:keycode(k,true);keycode(k,false)
func press_mouse(down:bool)->void:
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=down
	Input.parse_input_event(click);Input.flush_buffered_events()
func ticks(n:int)->void:
	for i in n:job._physics_process(dt)
func run()->void:
	base=load("res://vineyard.tscn").instantiate();root.add_child(base)
	for i in 4:await process_frame
	job=base.dock_order;job.set_physics_process(false)
	ticks(720)
	check(job.stage=="opening" and job.ledger.text.contains("岸灯"),"opening request waits even for a slow reader")
	tap(KEY_E);ticks(60);check(job.stage=="call" and job.guide.useful and job.guide.spotlight>.3,"point and focus on the actual bell")
	tap(KEY_SPACE);ticks(205);check(job.stage=="yard","first signal reaches the apprentice")
	for pair in [[KEY_W,0],[KEY_A,0],[KEY_S,0],[KEY_D,0],[KEY_W,KEY_A],[KEY_W,KEY_D],[KEY_S,KEY_A],[KEY_S,KEY_D]]:
		job.porter=Vector2(-5.2,-6.8);ticks(1)
		var origin:Vector3=job.worker.position
		keycode(pair[0],true)
		if pair[1]:keycode(pair[1],true)
		ticks(23);keycode(pair[0],false)
		if pair[1]:keycode(pair[1],false)
		var move:Vector3=job.worker.position-origin;move.y=0.
		check(move.length()>.7 and move.normalized().dot(job.worker.basis.z)>.99,"walking model faces actual travel "+str(pair))
	job.porter=Vector2(-3.6,-5.);ticks(1);tap(KEY_E);check(job.carried,"carry input")
	job.porter=Vector2(-.81,-5.);keycode(KEY_D,true);ticks(75)
	var stuck:Vector2=job.porter;var foot:float=job.worker.get_node("LegL").rotation.x;ticks(35)
	check(stuck==job.porter and absf(foot)<.01,"feet settle against a blocked gate")
	keycode(KEY_D,false);tap(KEY_Q);keycode(KEY_D,true);ticks(63);keycode(KEY_D,false)
	check(job.gate_passed,"one rotation frees the yoke")
	job.porter=Vector2(4.,0.);ticks(1);tap(KEY_E);ticks(145)
	check(job.stage=="silence","second basket signal waits for departure")
	tap(KEY_E);ticks(3)
	job.speed=6.;job.slip=.76;job.first_catch_seen=true;job.track_bell(dt,.21)
	check(job.catch_left>0. and job.catch_side==1,"predicted right rail event")
	var before:float=job.slip
	press_mouse(true);check(job.brace_left>0. and job.slip==before,"click starts pull without teleport")
	for i in 24:job.track_bell(dt,0.)
	check(absf(before-job.slip-.32)<.001 and job.brace_left<=0.,"one click pulls exactly 0.32")
	var stable:float=job.slip
	for i in 150:job.track_bell(dt,0.)
	press_mouse(false);press_mouse(true);press_mouse(false)
	check(is_equal_approx(job.slip,stable) and job.brace_left==0.,"holding or spamming cannot center a stable load")
	job.speed=0.;job.slip=-.78
	for i in 90:job.track_bell(dt,0.)
	check(job.catch_left<=0. and is_equal_approx(job.slip,-.78),"parked freight retains offset without earning a correction")
	job.speed=6.;job.track_bell(dt,-.20)
	check(job.catch_left>0. and job.catch_side==-1,"left rail warning uses same control")
	tap(KEY_TAB);var age:float=job.age;press_mouse(true);press_mouse(false);ticks(45)
	check(job.waybill.visible and job.age==age and job.catch_left>0.,"reading the route cannot consume a catch")
	tap(KEY_ESCAPE);ticks(1)
	job.save();check(is_equal_approx(base.bell_record.slip,job.slip),"checkpoint preserves offset")
	job.pos=job.land.road(job.land.WATCH,true,8.);job.speed=0.;tap(KEY_E);ticks(216)
	tap(KEY_SPACE);ticks(2);check(job.lesson_hits==1,"first short note learned")
	tap(KEY_R);ticks(2);check(job.lesson_hits==0 and job.age<.1,"repeat demonstration without leaving encounter")
	ticks(205);tap(KEY_E);ticks(180);check(job.learned,"guided rhythm alternative completes family call")
	job.left_dock.emit(0);await process_frame;await process_frame
	base.queue_free();await process_frame;await create_timer(.25).timeout
	print("CONTROL FAILURES ",failures);quit(failures)

