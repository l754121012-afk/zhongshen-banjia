extends SceneTree
var base
var job
var errors:=0
func _initialize()->void:call_deferred("test")
func check(ok:bool,n:String)->void:
	print("PASS " if ok else "FAIL ",n)
	if not ok:errors+=1
func start()->void:
	base=preload("res://vineyard.tscn").instantiate();root.add_child(base);base.set_physics_process(false);base.book_select(3);job=base.dock_order;job.set_physics_process(false)
func finish()->void:
	base.return_from_tide_dock(0);base.queue_free();await process_frame
func test()->void:
	var file:=ConfigFile.new();file.set_value("wishes","accepted",1<<3);file.set_value("port","day_best",55);file.set_value("port","night_best",21);file.save(OS.get_environment("OLYMPUS_TRIAL_PROFILE"))
	start();check(base.wind_wallet==76,"migrate previous day and night records into spendable balance")
	var start_balance:int=base.wind_wallet
	base.rent_hood();base.rent_hood();check(job.rented and base.wind_wallet==64,"single 12 coin rental per dispatch")
	await finish();start();check(base.wind_wallet==64 and not job.rented,"abandoned rental stays paid and does not attach to next dispatch")
	job.stage="drive";job.speed=6.;job.airborne=false;job.heading=-.72;job.charge=24;job.pos=Vector2(7,0);job.collector_x=[6.,54.]
	job.draw_charge(Vector2(6.,-.8),.17);check(job.charge==24.,"stock scoop misses a steep diagonal")
	job.rented=true;job.collector_x=[6.,54.];job.draw_charge(Vector2(6.,-.8),.17);check(job.charge>29.,"flared hood collects on same diagonal")
	var earned:float=job.charge
	for i in 180:job.draw_charge(job.pos,1./60.)
	check(is_equal_approx(job.charge,earned),"waiting for gust does not farm charge")
	for i in 120:
		job.pos.x=6.7+sin(i*.2)*.29;job.draw_charge(Vector2(6.,0),1./60.)
	check(is_equal_approx(job.charge,earned),"backtracking banks no repeat harvest")
	job.pos=Vector2(50,0);job.speed=0;job.cargo_shift=.61;job.catch_window=0.
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;job._input(click)
	check(job.correction==0.,"no click correction while parked")
	job.speed=.9;job.catch_window=.45;job._input(click);var before:float=job.cargo_shift
	job.drive(.10,0.,0.);check(job.cargo_shift<before and job.cargo_shift>.35 and job.catch_window==0.,"catch gives gradual limited correction")
	for i in 80:job._input(click);job.drive(.01,0.,0.)
	check(job.cargo_shift>.245 and job.correction<=0.,"click spam cannot center sack")
	var v:Vector3=job.winch_wind(Vector3.BACK,Vector3(94,6,0))
	check(is_equal_approx(v.x,job.Wind.pressure(Vector2(94,0),job.time)*job.Wind.FLOW.y*6.15),"crane samples the road weather field")
	job.charge=79.99;check(job.wind_units()==79,"display and goal agree below 80")
	job.charge=80.;check(job.wind_units()==80,"80 opens oven")
	job.health=29.99;job.settle_delivery();check(job.stage=="broken" and not job.assessed and base.wind_wallet==64,"broken sack rejected without paying")
	job.retry_from_bank();check(job.health==100 and job.pos==job.Terrain.BANK and job.charge==24 and job.stage=="drive","retry returns loaded to the wind depot")
	for pair:Array in [[30.,36],[59.99,36],[60.,15],[89.99,15],[90.,0],[100.,0]]:
		job.health=pair[0];job.charge=79.99;job.rented=false;job.assessed=false;job.chime_taken=false;job.bell_returned=false;job.pad_tip=6;job.settle_delivery()
		check(job.decline==pair[1] and job.signed_level==1,"condition band "+str(pair[0]))
		var val:int=base.wind_wallet;job.settle_delivery();check(base.wind_wallet==val,"same delivery cannot pay twice")
	job.charge=80.;job.health=100.;job.assessed=false;job.settle_delivery()
	var end_balance:int=base.wind_wallet
	await finish();start()
	check(base.wind_wallet==end_balance and job.prior_level==2 and base.port_return.tray.visible,"fresh boot restores window bread and wallet")
	var e:=InputEventKey.new();e.keycode=KEY_TAB;e.pressed=true;job._unhandled_key_input(e);check(job.stage=="visit" and job.visit_archive and job.signed_level==2,"return to previous working bakery free of charge")
	job._unhandled_key_input(e);check(job.stage=="offer" and base.wind_wallet==end_balance and not job.assessed,"leave archive without issuing new bill")
	await finish();await create_timer(.35).timeout;print("SYSTEM ERRORS ",errors);quit(1 if errors else 0)
