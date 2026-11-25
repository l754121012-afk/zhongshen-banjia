extends SceneTree
var base
var n
var keys:Dictionary={}
var errs:=0
var counter:=0
var film:=false
var snap_dir:=OS.get_environment("TIDE_QA")
func _initialize()->void:call_deferred("run")
func check(ok:bool,s:String)->void:
	print("PASS " if ok else "FAIL ",s)
	if not ok:errs+=1
func key(k:Key,on:bool)->void:
	if keys.get(k,false)==on and Input.is_physical_key_pressed(k)==on:return
	keys[k]=on
	var e:=InputEventKey.new();e.keycode=k;e.physical_keycode=k;e.pressed=on;Input.parse_input_event(e);Input.flush_buffered_events()
func tap(k:Key)->void:key(k,true);key(k,false)
func frames(count:int)->void:
	for j in count:
		for i in 3:n._physics_process(1.0/72)
		counter+=1
		if film or counter%25==0:await process_frame
func shot(name:String)->void:
	print("MARK ",name," ",Engine.get_frames_drawn())
	if snap_dir=="" or DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(snap_dir+"/"+name+".png")
func steer(p:Vector2,vmax:float=5.4,r:=1.7)->void:
	for j in 720:
		var v:Vector2=p-n.pos
		if v.length()<r:break
		var a:=angle_difference(n.heading,v.angle())
		key(KEY_D,a>0.04);key(KEY_A,a< -0.04)
		var cruise:=0.0 if absf(a)>1.08 else minf(vmax,1.6 if absf(a)>0.50 else vmax)
		key(KEY_W,cruise>0.0 and n.speed<cruise);key(KEY_S,n.speed>cruise+0.5)
		await frames(1)
	for k in [KEY_W,KEY_S,KEY_A,KEY_D]:key(k,false)
	check(p.distance_to(n.pos)<r,"night route "+str(p)+" actual "+str(n.pos))
func moor()->void:
	while n.speed>0.25:key(KEY_S,true);await frames(1)
	key(KEY_S,false);await frames(10);tap(KEY_E);await frames(10)
func run()->void:
	var disk:=OS.get_environment("OLYMPUS_TRIAL_PROFILE")
	if not FileAccess.file_exists(disk):
		var seed:=ConfigFile.new();seed.set_value("bell","done",true);seed.save(disk)
	film=OS.get_cmdline_user_args().has("--film")
	AudioServer.set_bus_mute(0,not film)
	base=load("res://vineyard.tscn").instantiate();root.add_child(base);base.set_physics_process(false)
	check(base.board.continuation.visible,"board offers contextual continuation");tap(KEY_ENTER);await process_frame;n=base.dock_order;n.set_physics_process(false);await skip_intro()
	await frames(48)
	check(n.pos.distance_to(n.BERTH)<4. and n.harbor_bell,"shore bell from first delivery")
	await shot("01-quay")
	for p:Vector2 in [Vector2(0,22),Vector2(10,20),Vector2(23.5,19)]:await steer(p)
	await moor();await frames(32);check(n.lamp_offer and base.lamp_step==0,"can leave offer without accepting")
	await shot("02-potter")
	tap(KEY_E);await frames(38);check(base.lamp_step==2 and n.lantern_crate.visible,"offered lamp attached to deck")
	if base.lamp_step!=2:quit(1);return
	copy_save("clay")
	tap(KEY_ESCAPE);await process_frame;base.open_tide_dock(true,false,true);await process_frame;n=base.dock_order;n.set_physics_process(false);await skip_intro()
	check(n.lantern_crate.visible and n.works==2 and n.pos.distance_to(n.PORTS[3])<4.,"resume loaded near kiln")
	for p:Vector2 in [Vector2(17,20),Vector2(11,19)]:await steer(p)
	tap(KEY_SPACE);await frames(57)
	check(n.pilots.answered and n.pilots.lenses[-1].emission_energy_multiplier>1.,"muted conch lights navigable water")
	await shot("03-echo")
	for p:Vector2 in [Vector2(3,22),Vector2(-8,23)]:await steer(p)
	await moor();check(n.stage=="winch","start quay winch")
	if n.stage!="winch":quit(1);return
	await frames(37);tap(KEY_SPACE);await frames(82)
	check(n.stage=="sail" and n.works==2 and n.lantern_crate.visible and n.lantern_crate.get_parent()==n.boat,"off-target drop recovers the same lamp on deck")
	if n.stage!="sail":quit(1);return
	tap(KEY_E);await frames(28)
	check(n.stage=="winch","re-hook the recovered lamp")
	var rig=n.rig
	for i in 340:
		var err:float=rig.length-rig.trolley
		key(KEY_D,err>maxf(.08,rig.velocity*absf(rig.velocity)/16+.09));key(KEY_A,err<minf(-.08,rig.velocity*absf(rig.velocity)/16-.09));await frames(1)
		if absf(err)<.20 and absf(rig.velocity)<.24:break
	key(KEY_D,false);key(KEY_A,false);await frames(6);await shot("04-winch");tap(KEY_SPACE);await frames(90);await shot("05-handover");await frames(155)
	check(base.lamp_step==3 and n.quay.plaque.visible,"lit quay")
	if base.lamp_step!=3:quit(1);return
	n.pulse_charge=.12;tap(KEY_SPACE);await frames(28)
	check(n.hailed_worker and n.watching_kiln() and n.pots.watch_lamp.visible,"a moored boat can hail the waiting passenger on an empty sonar charge")
	await frames(95)
	check(not n.watching_kiln() and n.stage=="sail","optional kiln reply returns the helm")
	for r in 2:
		for p:Vector2 in [Vector2(0,22),Vector2(10,20),Vector2(23.5,19)]:await steer(p)
		await moor();await frames(32);check(n.worker_aboard and base.worker_ticket,"passenger boards")
		if r==1:
			copy_save("passenger")
			tap(KEY_ESCAPE);await process_frame;base.open_tide_dock(true);await process_frame;n=base.dock_order;n.set_physics_process(false);await skip_intro()
			check(n.worker_aboard and n.worker.visible and n.worker_signed,"repeat ticket resumes")
		var before:int=base.wind_wallet
		for p:Vector2 in [Vector2(14,21),Vector2(4,22),Vector2(-8,23)]:await steer(p)
		await moor();tap(KEY_E);await frames(32);check(base.wind_wallet==before+8 and base.worker_runs==r+1 and not base.worker_ticket,"fare paid once on landing")
		await shot("06-arrival")
	tap(KEY_Q);await frames(2);await shot("07-charter");check(n.harbour_charter.crossings==2,"charter counts arrivals")
	var funds_before:int=base.wind_wallet
	check(n.harbour_charter.mirror_button.visible,"mirror contribution offered")
	tap(KEY_ENTER);await frames(35)
	check(base.quay_mirror and n.mirror_built and base.wind_wallet==funds_before-6,"one time investment from fares")
	check(n.warning_rings[5].visible and n.pilots.reflector.visible,"marked rock above water")
	await shot("08-mirror");await frames(90);tap(KEY_Q);tap(KEY_ENTER);await frames(2)
	check(base.wind_wallet==funds_before-6,"no duplicate construction charge")
	copy_save("mirror");tap(KEY_ESCAPE);tap(KEY_ESCAPE);await process_frame
	base.open_tide_dock(true);await process_frame;n=base.dock_order;n.set_physics_process(false);await skip_intro()
	check(n.mirror_built and n.pilots.reflector!=null,"mirror present on next shift")
	check(n.quay.lunch_pail.global_position.distance_to(n.quay.apprentice_grip.global_position)<.25,"lit quay remembers the handed-over meal")
	check(n.quay.stair_worker.position.y>.60 and n.quay.stair_worker.position.z>2.7,"night worker stays on the lit landing")
	n.queue_free();base.queue_free();await process_frame;await create_timer(.5).timeout;print("ERRORS ",errs);quit(1 if errs else 0)


func copy_save(phase:String)->void:
	var prefix:=OS.get_environment("NIGHT_CHECKPOINTS")
	if prefix!="":
		check(DirAccess.copy_absolute(base.postmark_file(),prefix+"-"+phase+".cfg")==OK,"checkpoint "+phase)

func skip_intro()->void:
	var scene=n.get_node_or_null("ArrivalFilm")
	if scene:
		tap(KEY_ESCAPE);scene._process(.7);await process_frame
