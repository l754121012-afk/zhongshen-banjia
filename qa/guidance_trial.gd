extends SceneTree
var base
var job
var old:=OS.get_cmdline_user_args().has("--old")
var live:=OS.get_cmdline_user_args().has("--live")
var photos:=OS.get_environment("BELL_PHOTOS")
var mode:="old" if old else "direct"
var keys:Dictionary={}
var errors:=0
var screenshots:Dictionary={}
var count:=0
var run_seconds:=0.
var real_start:=Time.get_ticks_msec()
var filming:=OS.get_cmdline_user_args().has("--film")
var ferry_run:=OS.get_cmdline_user_args().has("--night")
var skip_call:=OS.get_cmdline_user_args().has("--skip-call")
var muted:=OS.get_cmdline_user_args().has("--mute")
var returning:=false
var turned_back:=false
var previous_tick:=0
var max_slip:=0.0
var warnings:=0
var in_window:=false
var watch_road:=OS.get_cmdline_user_args().has("--catch")
func _initialize()->void:call_deferred("run")
func tap(k:Key)->void:key(k,true);key(k,false)
func key(k:Key,on:bool)->void:
	if keys.get(k,false)==on:
		if k not in [KEY_W,KEY_S,KEY_A,KEY_D] or Input.is_physical_key_pressed(k)==on:return
	keys[k]=on
	var e:=InputEventKey.new();e.keycode=k;e.physical_keycode=k;e.pressed=on;Input.parse_input_event(e);Input.flush_buffered_events()
func coast()->void:
	for k in [KEY_W,KEY_A,KEY_S,KEY_D]:key(k,false)
func step(n:int=1)->void:
	for i in n:
		count+=1;run_seconds+=1./60.
		if live:await physics_frame
		else:
			job._physics_process(1./60.)
			if filming:
				var scene:bool=(job.stage in ["opening","call","first_drop","silence","invite","yard","listen","ring","crane","arrival","ledger","altar","mountain"]) or (job.stage=="drive" and ((job.pos.x>180 and job.pos.x<193) or (job.pos.x>375 and job.pos.x<386) or (job.pos.x>521 and job.pos.x<528) or (job.pos.x>780 and job.pos.x<788) or (job.pos.x>1105 and job.pos.x<1116) or (job.pos.x>1408 and job.pos.x<1421)))
				if (scene and count%3==0) or count%900==0:await process_frame
			elif count%240==0:await process_frame
func check(ok:bool,info:String)->void:
	print(("PASS " if ok else "FAIL ")+info);if not ok:errors+=1
func shot(id:String)->void:
	if screenshots.has(id):return
	screenshots[id]=true;print("MILE ",id," t=",snappedf(run_seconds,.1)," health=",job.hp," x=",snappedf(job.pos.x,.1))
	if photos!="":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(photos+"/"+mode+"-"+id+".jpg.png")
func walk(p:Vector2)->void:
	for i in 900:
		var diff:Vector2=p-job.porter
		if diff.length()<.09:break
		key(KEY_D,diff.x>.06);key(KEY_A,diff.x<-.06);key(KEY_W,diff.y<-.06);key(KEY_S,diff.y>.06)
		await step()
	coast()
func run()->void:
	if muted:AudioServer.set_bus_mute(0,true)
	base=load("res://vineyard.tscn").instantiate();root.add_child(base)
	for i in 5:await process_frame
	if not is_instance_valid(base.dock_order):base.book_select(7)
	job=base.dock_order
	if not is_instance_valid(job):check(false,"opening entry");quit(1);return
	if not live:job.set_physics_process(false)
	print("START ",mode," ",job.stage," ",job.pos)
	if job.stage=="opening":
		await step(75);await shot("00-opening")
		if OS.get_cmdline_user_args().has("--signal"):
			tap(KEY_SPACE);await step(103);await shot("00a-red-sail")
			check(job.lookout_seen and job.coast.skiff.visible,"raise the lantern to signal red sail")
		tap(KEY_E);await step(90)
	if job.stage=="call":
		await step(80);await shot("00b-before")
		if skip_call:tap(KEY_E);await step(2);check(job.stage=="yard","skip bell handoff")
		else:
			tap(KEY_SPACE);await step(100);await shot("00c-first");await step(110)
			check(job.lift.loads[0].position.y<.5 and job.lift.loads[1].position.y>3.,"first load landed while second waits")
	if job.stage=="yard":
		await shot("01-forge");await walk(Vector2(-3.8,-5.));tap(KEY_E);await step(2)
		check(job.carried,"pick up bronze");await walk(Vector2(-.84,-5.));key(KEY_D,true);await step(25);key(KEY_D,false);check(not job.gate_passed,"crossbar caught until turned")
		tap(KEY_Q);await walk(Vector2(.55,-5.));await shot("01a-gate");await walk(Vector2(1.35,-.21));await walk(Vector2(3.34,-.21));await shot("01a-ramp");await walk(Vector2(4.1,-.21));tap(KEY_E);await step(96);check(job.lift.loads[1].position.y>3.,"second load still suspended with empty frame");await shot("01b-silent");await step(151);check(job.stage=="silence","important departure waits for player");tap(KEY_E);await step(2);check(job.stage=="drive","gate, turn and load")
		if job.stage!="drive":print(job.porter," ",job.gate_passed);quit(1);return
	var max_steps:=70000
	for i in max_steps:
		if job.stage!="drive":break
		max_slip=maxf(max_slip,absf(job.slip))
		if job.catch_left>0 and not in_window:
			warnings+=1
			print("CATCH ",job.pos.x," ",job.slip)
			await shot("04b-catch")
			if watch_road:
				var click:=InputEventMouseButton.new();click.pressed=true;click.button_index=MOUSE_BUTTON_LEFT
				Input.parse_input_event(click);Input.flush_buffered_events()
				click=click.duplicate() as InputEventMouseButton;click.pressed=false;Input.parse_input_event(click);Input.flush_buffered_events()
		in_window=job.catch_left>0
		var x:float=job.pos.x;var turn_stop:bool=old and not job.learned and not turned_back and x>job.land.WATCH+36.
		if turn_stop:returning=true;turned_back=true;print("TURN BACK ",job.pos)
		var pause_for:=0
		var goal_x:=0.
		if old and not job.packed and absf(x-job.land.CAMP)<33.:pause_for=1;goal_x=job.land.CAMP
		elif old and returning and not job.learned:pause_for=2;goal_x=job.land.WATCH
		elif old and job.packed and not job.blessing and absf(x-job.coast.HORN)<34.:pause_for=4;goal_x=job.coast.HORN
		elif x>job.END-32.:pause_for=3;goal_x=job.END
		var dx:=10.5 if not returning else -10.5
		var target:Vector2=job.land.road(clampf(x+dx,0.,job.END),old)
		if pause_for>0:target=job.land.road(goal_x,pause_for<3,6. if pause_for!=3 else 0.)
		var delta:Vector2=target-job.pos;var heading:float=wrapf(delta.angle()-job.yaw,-PI,PI)
		var dist:=delta.length()
		if pause_for!=0 and dist<9.5:
			coast()
			if job.speed>1.55:key(KEY_S,true)
			else:
				coast();tap(KEY_E);await step(1)
				if job.stage=="listen":
					await step(215);await shot("06-listen");tap(KEY_SPACE);await step(14);tap(KEY_SPACE);await step(18);key(KEY_SPACE,true);await step(42);key(KEY_SPACE,false);await step(181);check(job.learned,"learned ferry call after returning");returning=false
				elif job.stage=="camp_talk":
					await step(80);await shot("04-camp");tap(KEY_E);await step(2);check(job.packed,"accepted padding and clay after conversation")
				elif job.stage=="altar":
					var foot_goal:Vector2=job.ear_foot()
					await walk(foot_goal);tap(KEY_E);await step(65);await shot("06b-ear");await step(215);await shot("06c-basket");check(job.lift.loads[1].position.y<.5,"restored echo releases second load");await step(65);check(job.blessing and job.stage=="drive","returned echo to mountain on foot")
				elif job.stage=="dock":break
			await step(2);continue
		key(KEY_D,heading>.035);key(KEY_A,heading<-.035)
		var cap:=3.8 if absf(heading)>.77 else (4.5 if pause_for and dist<18. else 8.4)
		key(KEY_S,job.speed>cap+.8);key(KEY_W,job.speed<cap)
		if i%420==0 and job.echo_age>2.7:tap(KEY_SPACE)
		if x>196 and x<204:await shot("02-descent")
		if x>514 and x<518:await shot("03-fork")
		if x>638 and x<640 and not screenshots.has("05-map"):
			var where:Vector2=job.pos;tap(KEY_TAB);await step(12)
			check(job.waybill.visible and job.pos==where,"route card pauses driving")
			await shot("05-map");tap(KEY_ESCAPE);await step()
		if x>640 and x<652:await shot("05-branch")
		if x>1200 and x<1208:await shot("07-pass")
		if x>1404 and x<1412:await shot("08-fog")
		await step(3)
	coast()
	print("RANGE ",max_slip," warnings ",warnings)
	check(job.stage in ["crane","dock"],"arrival after drive "+str(job.pos))
	if job.stage not in ["crane","dock"]:quit(1);return
	if job.stage=="dock":tap(KEY_E)
	await step(80);await shot("09-crane")
	for i in 2000:
		if job.stage!="crane":break
		var rig=job.rig
		if rig.phase=="carry":
			var error:float=rig.length-rig.trolley
			key(KEY_D,error>.10 and rig.velocity<maxf(.35,error*1.12));key(KEY_A,error<-.12 and rig.velocity>minf(-.35,error*1.12))
			if absf(error-rig.swing)<.40 and absf(rig.velocity+rig.swing_v)<.62:coast();tap(KEY_SPACE)
		await step()
	coast();check(job.stage=="ring","landed within bell frame")
	if job.stage!="ring":quit(1);return
	tap(KEY_E);await step(450);await shot("10-answer");await step(300);await shot("11-ledger")
	var before:int=base.wind_wallet;var should_pay:int=job.fare(job.hp,job.learned)-(12 if old else 0) if not job.previously_paid else 0
	tap(KEY_Q if old else KEY_E);await step(90);await shot("12-invite");if ferry_run:
		tap(KEY_E);await step(44);await process_frame;await process_frame
	else:tap(KEY_B);await process_frame;await process_frame
	check(base.wind_wallet==before+should_pay,"income / investment posted once");check(base.bell_done,"saved port bell")
	if not ferry_run:check(base.board.visible,"opening hands off to board")
	else:await sail()
	print("FINISH ",mode," simulated=",snappedf(run_seconds,.1)," wall=",snappedf((Time.get_ticks_msec()-real_start)/1000.,.1)," hp last receipt ",base.wind_wallet," errors ",errors)
	base.queue_free();await process_frame;await create_timer(.50).timeout;quit(errors)



func sea_frames(n:int)->void:
	for i in n:
		if live:await physics_frame
		else:
			job._physics_process(1./60.)
			if filming and i%3==0:await process_frame
		run_seconds+=1./60.
func sea_steer(dest:Vector2)->bool:
	for j in 1900:
		var diff:Vector2=dest-job.pos
		if diff.length()<2.35:coast();return true
		var a:float=angle_difference(job.heading,diff.angle())
		key(KEY_D,a>.045);key(KEY_A,a<-.045)
		var vmax:=1.7 if absf(a)>.55 else 4.8
		key(KEY_W,job.speed<vmax);key(KEY_S,job.speed>vmax+.5)
		await sea_frames(2)
	coast();return false
func sea_photo(id:String)->void:
	print("NIGHT ",id," t=",run_seconds," pos=",job.pos)
	if photos!="":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(photos+"/"+mode+"-"+id+".png")
func sail()->void:
	job=base.dock_order
	check(is_instance_valid(job) and job.has_method("depart_blue_quay"),"board night vessel from invitation")
	if not is_instance_valid(job) or not job.has_method("depart_blue_quay"):return
	if not live:job.set_physics_process(false)
	await sea_frames(85)
	check(job.pos.distance_to(job.BERTH)<5.6,"controlled night starts at letter or waiting passenger")
	await sea_photo("13-berth")
	if not old:tap(KEY_ESCAPE);await process_frame;return
	tap(KEY_E);await sea_frames(35);check(base.bell_letter==1,"family hands over letter")
	for waypoint:Vector2 in [Vector2(0,17),Vector2(10,14),Vector2(18,13),Vector2(25,18.5)]:
		var arrived:=await sea_steer(waypoint)
		check(arrived,"night boat navigation "+str(waypoint))
		if not arrived:tap(KEY_ESCAPE);await process_frame;return
	coast();key(KEY_S,true);await sea_frames(35);key(KEY_S,false);await sea_frames(12)
	var cash:int=base.wind_wallet;tap(KEY_E);await sea_frames(52)
	check(base.bell_letter==2 and base.wind_wallet==cash+5,"night delivery payout and physical letter")
	await sea_photo("14-kiln");tap(KEY_ESCAPE);await process_frame
