extends Node3D

signal checkpoint(record:Dictionary)
signal completed(song:bool,integrity:float,bought:bool)
signal left_dock(pay:int)
const END:=1584.
var land:=preload("res://bell_valley.gd").new()
var encounters:=preload("res://bell_encounters.gd").new()
var clay_piece:Node3D
var mountain_cup:Node3D
var shard_start:=Transform3D.IDENTITY
var fitting_start:=Vector3.ZERO
var camp_shard:Node3D
var felt_pad:Node3D
var rigging_repaired:=false
var lift:=preload("res://foundry_lift.gd").new()
var first_worked:=false
var yard_voices:Array[AudioStreamPlayer3D]=[]
var mallet:Node3D
var letter_prop:Node3D
var boarding_age:=-1.
var fade:=ColorRect.new()
var take_ferry:=false
var coast:=preload("res://bell_coast.gd").new()
var blessing:=false
var fog_reach:=-999.
var rotation_walk:=0.
var wheels:Array[Node3D]=[]
var art:=preload("res://workshop.gd").new()
var audio:=preload("res://sound.gd").new()
var freight:=preload("res://bell_cast.gd").new()
var wind_job:=false
var truck:Node3D
var worker:Node3D
var yoke:Node3D
var rig:Node3D
var cam:=Camera3D.new()
var atmosphere:=Environment.new()
var daylight:=DirectionalLight3D.new()
var sky_colors:=ProceduralSkyMaterial.new()
var sun_step:=-1
var compatibility:=RenderingServer.get_current_rendering_method()=="gl_compatibility"
var quay_lamps:Array[OmniLight3D]=[]
var tone:=AudioStreamPlayer.new()
var reply:=AudioStreamPlayer3D.new()
var tracks:Array[AudioStream]=[]
var rings:Array[Node3D]=[]
var stage:="opening"
var record:Dictionary={}
var fitted:=false
var previously_paid:=false
var letter_history:=0
var learned:=false
var packed:=false
var carried:=false
var gate_passed:=false
var depot_turned:=false
var visited:=0
var hp:=100.
var pos:=Vector2(7.35,0)
var porter:=Vector2(-5.,-4.)
var yaw:=0.
var speed:=0.
var velocity:=Vector2.ZERO
var steer_rate:=0.
var swing:=0.
var swing_v:=0.
var slip:=0.
var hit_lock:=0.
var echo_age:=9.
var echo_goal:=Vector3.ZERO
var echo_pitch:=1.
var echo_return:=false
var phrase:=""
var phrase_left:=0.
var phrase_priority:=0
var elapsed:=0.
var age:=0.
var checkpoint_at:=Vector2.ZERO
var manifest:=preload("res://bell_manifest.gd").new()
const SpeakerPose:=preload("res://speaker_pose.gd")
var foreman_face:=SpeakerPose.new()
var apprentice_face:=SpeakerPose.new()
var daughter_face:=SpeakerPose.new()
var ferryman_face:=SpeakerPose.new()
var sailmaker_face:=SpeakerPose.new()
var pilot_face:=SpeakerPose.new()
var waybill:=preload("res://bell_waybill.gd").new()
var driven_sections:=PackedByteArray()
var guide:=preload("res://bell_guidance.gd").new()
var ui:=CanvasLayer.new()
var title:Label
var caption:Label
var controls:Label
var ledger:Label
var cam_started:=false
var last_region:=-1
var old_road:=false
const Catch:=preload("res://cargo_catch.gd")
const BELL_RAIL:=.83
var catch_side:=0
var catch_left:=0.0
var brace_left:=0.0
var catch_calm:=0.0
var catch_hit:=false
var first_catch_seen:=false
var cue_strap:Node3D
var bell_tag:=preload("res://freight_tag.gd").new()
var lookout_age:=-1.
var lookout_seen:=false
var pilot_lamp:Node3D
var port_signal:Node3D
var cup_signal:Node3D
var last_knock:=-10.
var tag_text:=""
var tag_time:=0.0
var clear_fog:=0.
var finished_view:=false
var lesson_hits:=0
var lesson_hold:=-1.
var answer_time:=-1.
var lesson_assist:=false
var song_beat:=-1
var pause_panel:=false
var wind:=0.
var shake:=0.
var focus_smooth:=Vector3.ZERO
var tick_ui:=0.

func _ready()->void:
	driven_sections.resize(101)
	add_child(land);land.build();coast.build(land);lift.build(land.stations.yard);lift.echo_bluff(land);encounters.build(self)
	add_child(audio);audio.set_scene("yard");audio.bg.volume_db=-23.
	add_child(tone);land.add_child(reply);reply.max_distance=190.;reply.unit_size=30.;reply.volume_db=-3
	for key in ["bronze_reply","ferryman_cup","harbor_horn","pilot_horn","family_bronze"]:tracks.append(load("res://audio/"+key+".wav"))
	truck=art.truck(self);
	for w in truck.find_children("*","Node3D",true,false):
		if w.is_in_group("wheels"):wheels.append(w)
	truck.position=land.surface(pos)
	worker=art.courier(self);worker.position=land.surface(porter);add_child(freight)
	freight.position=land.frame.global_position+Vector3.UP*.64
	var relic:=preload("res://bell_relic.gd").new()
	clay_piece=relic.shard(worker);clay_piece.position=Vector3(-.15,.85,.35);clay_piece.scale=Vector3.ONE*.66;clay_piece.hide()
	camp_shard=relic.shard(land.helper.get_node("ArmR"));camp_shard.position=Vector3(-.20,-.49,.09);camp_shard.scale=Vector3.ONE*.60;camp_shard.hide()
	mountain_cup=relic.make_horn(land.frame);mountain_cup.position=Vector3(0,1.09,0);mountain_cup.scale=Vector3.ONE*.63;relic.shard(mountain_cup);mountain_cup.hide()
	felt_pad=art.group(truck,Vector3(-1.42,1.25,0));felt_pad.hide()
	art.box(felt_pad,Vector3.ZERO,Vector3(1.75,.089,1.71),"#984e3e")
	for hem in [-.72,.72]:art.box(felt_pad,Vector3(0,.049,hem),Vector3(1.73,.008,.088),"#dbc396")
	yoke=art.group(freight,Vector3.UP*1.48);art.beam(yoke,Vector3(0,0,-1.52),Vector3(0,0,1.52),.093,"#916c43")
	for side in [-1.,1.]:
		art.ring(yoke,Vector3(0,-.06,side*.47),.094,.026,"#e2b665").rotation.x=PI*.5
	for i in 3:
		var ring:=art.ring(self,Vector3.ZERO,1.,.029,"#f7dc8b");rings.append(ring);ring.hide()
	setup_light();add_child(cam);cam.current=true;cam.fov=54;cam.far=1100.
	add_child(ui);guide.state=self;ui.add_child(guide);manifest.state=self;ui.add_child(manifest)
	title=make_label(Vector2(97,26),27,true);caption=make_label(Vector2(98,62),17);controls=make_label(Vector2(0,637),18);ledger=make_label(Vector2(0,571),23)
	for label in [controls,ledger]:
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		label.size=Vector2(1216,47);label.position.x=32
	ledger.add_theme_color_override("font_color",Color("#fff1d6"))
	ui.add_child(fade);fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;fade.color=Color("#132e3a");fade.modulate.a=0.
	ui.add_child(bell_tag);bell_tag.build(preload("res://harbour_fonts.gd").body());bell_tag.hide()
	cue_strap=art.group(freight)
	var knot:=art.ring(cue_strap,Vector3(0,1.12,0),.21,.049,"#ffe0a2");knot.rotation.z=PI*.5
	for side in [-1.,1.]:art.beam(cue_strap,Vector3(0,1.1,side*.16),Vector3(0,.49,side*.62),.037,"#efd292")
	cue_strap.hide()
	ui.add_child(waybill);waybill.job=self
	setup_signal_props()
	foreman_face.bind(land.apprentice,.47);apprentice_face.bind(lift.hand,1.14)
	daughter_face.bind(coast.daughter,.79);ferryman_face.bind(land.elder,2.3)
	sailmaker_face.bind(land.helper,1.7);pilot_face.bind(land.captain,2.9)
	restore();pose(1.);update_hud()

func setup_signal_props()->void:
	preload("res://listening_herm.gd").new().build(land.stations.port,Vector3(-7.6,-.04,15.24),.12,1.35)
	pilot_lamp=preload("res://votive_lamp.gd").build(land.captain.get_node("ArmR"),Vector3(0,-.46,.15),art)
	pilot_lamp.scale=Vector3.ONE*.32
	var ember:=art.ball(pilot_lamp,Vector3.UP*.82,Vector3(.60,.45,.60),"#ffc782")
	var wick:=StandardMaterial3D.new();wick.albedo_color=Color("#ffcf83");wick.emission_enabled=true;wick.emission=Color("#ffba54");wick.emission_energy_multiplier=2.0;ember.material_override=wick
	for site:Vector3 in [Vector3(-4.1,2.25,14.9),Vector3(5.4,2.25,13.8)]:
		var dock:Node3D=land.stations.port
		art.beam(dock,site-Vector3.UP*2.26,site+Vector3.UP*.48,.069,"#795b44")
		art.beam(dock,site+Vector3.UP*.44,site+Vector3(.51,.44,0),.049,"#9c7651")
		var box_at:=site+Vector3(.44,.14,0)
		var glow:=art.ball(dock,box_at,Vector3(.27,.38,.27),"#fbd299")
		var glass:=StandardMaterial3D.new();glass.albedo_color=Color("#e2b476");glass.emission_enabled=true;glass.emission=Color("#ffc883");glass.emission_energy_multiplier=1.3;glow.material_override=glass
		for sign_y in [-1.,1.]:art.cyl(dock,box_at+Vector3.UP*.17*sign_y,.177,.16,.07,"#806a52",12)
		for dx in [-.105,.105]:art.beam(dock,box_at+Vector3(dx,-.16,.088),box_at+Vector3(dx,.16,.088),.011,"#785e4a")
		var light:=OmniLight3D.new();dock.add_child(light);light.position=box_at;light.light_color=Color("#ffcc8b");light.omni_range=6.5;quay_lamps.append(light)
	port_signal=signal_lamp(coast.skiff,Vector3(-1.64,1.34,.12))
	cup_signal=art.ring(land.cup,Vector3.UP*.14,.20,.024,"#ffe3a1");cup_signal.hide()
	for id in ["hollow_yoke","hemp_winch","copper_landing","clay_answer","letter_fold"]:
		var voice:=AudioStreamPlayer3D.new();add_child(voice);voice.stream=load("res://audio/"+id+".wav");voice.unit_size=9.5;voice.max_distance=68.;yard_voices.append(voice)
	mallet=art.group(worker.get_node("ArmR"),Vector3(.035,-.29,.16))
	art.beam(mallet,Vector3.ZERO,Vector3(.08,.05,.58),.037,"#8c6547");art.cyl(mallet,Vector3(.08,.07,.55),.109,.109,.26,"#a5835b").rotation.z=PI*.5;mallet.hide()
	letter_prop=preload("res://bell_household.gd").new().make_letter(coast.daughter.get_node("ArmR"))
	letter_prop.position=Vector3(0,-.32,.20);letter_prop.hide()

func signal_lamp(parent:Node3D,at:Vector3)->Node3D:
	var top:=art.group(parent,at)
	art.beam(top,Vector3.DOWN*1.02,Vector3.UP*.49,.041,"#735842")
	art.beam(top,Vector3.UP*.45,Vector3(.31,.45,0),.034,"#9d8255")
	var lens:=art.ball(top,Vector3(.27,.18,0),Vector3(.30,.36,.27),"#ffeea6")
	var glow:=StandardMaterial3D.new();glow.albedo_color=Color("#ffe7a4");glow.emission_enabled=true;glow.emission=Color("#ffd189");glow.emission_energy_multiplier=3.;lens.material_override=glow
	for sign_y in [-1.,1.]:art.cyl(top,Vector3(.27,.18+sign_y*.17,0),.17,.14,.07,"#75654e")
	return lens

func yard_sound(index:int,point:Vector3,gain:float)->void:
	var voice:=yard_voices[index];voice.global_position=point;voice.volume_db=gain;voice.play()

func make_label(at:Vector2,px:int,serif:=false)->Label:
	var l:=Label.new();ui.add_child(l);l.position=at;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.add_theme_font_override("font",preload("res://harbour_fonts.gd").headings() if serif else preload("res://harbour_fonts.gd").body())
	l.add_theme_font_size_override("font_size",px);l.add_theme_color_override("font_color",Color("#fff0d2"));l.add_theme_color_override("font_outline_color",Color("#182d32"));l.add_theme_constant_override("outline_size",5)
	return l

func setup_light()->void:
	atmosphere.background_mode=Environment.BG_SKY;var sky:=sky_colors;sky.sky_top_color=Color("#5b8aa6");sky.sky_horizon_color=Color("#c4dbe0");sky.ground_horizon_color=Color("#adc2b1");atmosphere.sky=Sky.new();atmosphere.sky.sky_material=sky
	atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;atmosphere.ambient_light_color=Color("#d9e4dd");atmosphere.ambient_light_energy=.76;atmosphere.tonemap_mode=Environment.TONE_MAPPER_FILMIC;atmosphere.tonemap_white=4.0;atmosphere.fog_enabled=true;atmosphere.fog_density=.0027;atmosphere.fog_light_color=Color("#d1cdc0");cam.environment=atmosphere
	daylight.rotation_degrees=Vector3(-42,-58,0);daylight.light_color=Color("#fff1d6");daylight.light_energy=.86;daylight.shadow_enabled=true;daylight.directional_shadow_max_distance=70.;add_child(daylight)

func evening(value:float)->void:
	var step:=roundi(value*32.)
	if step==sun_step:return
	sun_step=step;var u:=float(step)/32.
	sky_colors.sky_top_color=Color("#5b8aa6").lerp(Color("#525b84"),u)
	sky_colors.sky_horizon_color=Color("#c4dbe0").lerp(Color("#e3b2a5"),u)
	sky_colors.ground_horizon_color=Color("#adc2b1").lerp(Color("#ac9da5"),u)
	daylight.light_color=Color("#fff1d6").lerp(Color("#ffc18b"),u)
	daylight.light_energy=lerpf(.86,.51,u)*(.69 if compatibility else 1.)
	daylight.rotation_degrees.x=lerpf(-42.,-17.5,u)
	atmosphere.ambient_light_color=Color("#d9e4dd").lerp(Color("#b0b9d8"),u)
	atmosphere.ambient_light_energy=lerpf(.76,.60,u)*(.70 if compatibility else 1.)
	for lamp in quay_lamps:lamp.light_energy=1.18*u;lamp.visible=u>.03

func save()->void:
	var step:=stage
	if step in ["listen","altar","inlay","mountain"]:step="drive"
	if step=="first_drop":step="yard"
	if step=="camp_talk":step="drive"
	if step=="crane":step="dock"
	checkpoint.emit({"step":step,"first_worked":first_worked,"catch_seen":first_catch_seen,"slip":slip,"driven":driven_sections,"events":encounters.snapshot(),"repair":rigging_repaired,"pos":pos,"yaw":yaw,"porter":porter,"carry":carried,"turned":depot_turned,"passed":gate_passed,"song":learned,"blessing":blessing,"packed":packed,"visits":visited,"hp":hp,"time":elapsed})
	checkpoint_at=pos

func restore()->void:
	if record.is_empty():return
	if record.has("driven") and record.driven is PackedByteArray and record.driven.size()==driven_sections.size():driven_sections=record.driven.duplicate()
	first_catch_seen=record.get("catch_seen",false);slip=clampf(record.get("slip",0.),-.83,.83)
	encounters.restore(record.get("events",{}));rigging_repaired=record.get("repair",false)
	stage=record.get("step","opening");pos=record.get("pos",pos);yaw=record.get("yaw",yaw);porter=record.get("porter",porter);carried=record.get("carry",false);depot_turned=record.get("turned",false);gate_passed=record.get("passed",false)
	blessing=record.get("blessing",false);learned=record.get("song",false);packed=record.get("packed",false);visited=record.get("visits",0);hp=record.get("hp",100.);elapsed=record.get("time",0.)
	first_worked=record.get("first_worked",stage not in ["opening","call"]);mountain_cup.visible=blessing
	if stage not in ["opening","call","yard","silence","drive","dock","ring","arrival","ledger","invite"]:stage="yard"
	if stage not in ["opening","call","yard"]:attach_bed()
	if stage in ["ring","arrival","ledger","invite"]:mount_bell()
	truck.position=land.surface(pos);truck.rotation.y=-yaw;worker.position=land.surface(porter) if stage in ["yard","opening"] else worker.position
	checkpoint_at=pos

func switch(next:String)->void:
	stage=next;age=0.;song_beat=-1;phrase_left=0.;save();update_hud()
func tell(words:String,seconds:=4.,priority:=1)->void:
	if phrase_left>0. and phrase_priority>priority:return
	phrase=words;phrase_left=seconds;phrase_priority=priority;update_hud()
func one_shot(i:int,pitch:=1.,gain:=-2.)->void:
	tone.stream=tracks[i];tone.pitch_scale=pitch;tone.volume_db=gain;tone.play()
func attach_bed()->void:
	if freight.get_parent()!=truck:freight.reparent(truck,false)
	freight.position=Vector3(-1.42,1.27,0);freight.rotation=Vector3.ZERO;worker.hide();carried=false;yoke.show();audio.set_scene("road")
func mount_bell()->void:
	if freight.get_parent()!=land.harbor_frame:freight.reparent(land.harbor_frame,false)
	freight.position=Vector3.UP*2.83;freight.rotation=Vector3.ZERO;yoke.hide();worker.show();worker.position=land.harbor_frame.global_position+Vector3(-2,0,-1);audio.set_scene("yard")
func near(point:Vector2,r:float)->bool:return pos.distance_squared_to(point)<r*r
func action()->void:
	match stage:
		"opening":switch("call")
		"call":
			first_worked=true;switch("first_drop");one_shot(0,.94,-3.)
		"first_drop":
			if age>=1.:switch("yard")
		"silence":
			if age>=1.35:switch("drive")
		"camp_talk":
			packed=true;audio.play_cue("buckle");switch("drive");tell("车上的钟垫好了。到了山口，可以停车把陶片送回去。",5.)
		"invite":
			if boarding_age<0.:
				boarding_age=0.;audio.play_cue("page")
		"yard":
			if not carried and porter.distance_to(Vector2(-3,-5))<2.7:
				carried=true;audio.play_cue("grab");one_shot(0,.82,-13.);tell("师傅：门窄。把钟杠转个向，一头先进。",5.);save()
			elif carried and gate_passed and porter.x>=3.6 and absf(porter.y)<1.5:
				attach_bed();switch("silence");phrase_left=0.
		"drive":
			if absf(speed)>3.2:tell("慢下来再和路边的人说话。",1.6);return
			if near(land.road(END),15.):request_dock()
			elif near(land.road(coast.HORN,false,6.6),18.) and packed and not blessing:
				speed=0.;velocity=Vector2.ZERO;porter=pos+Vector2(-1.2,1.85);worker.show();clay_piece.show();switch("altar");tell("陶耳缺了一角。把手里的陶片装回去试试。" ,4.5)
			elif near(land.road(land.WATCH,true,8.6),18.) and not learned:
				speed=0.;velocity=Vector2.ZERO;lesson_hits=0;lesson_hold=-1.;answer_time=-1.;lesson_assist=false;switch("listen")
			elif near(land.road(land.CAMP,true,10.),16.) and not packed:
				speed=0.;velocity=Vector2.ZERO;switch("camp_talk")
		"altar":
			if close_to_ear():
				shard_start=clay_piece.global_transform;fitting_start=worker.global_position
				blessing=true;mountain_cup.show();audio.play_cue("snap");switch("inlay")
		"listen":
			if age>3.3 and answer_time<0.:
				lesson_assist=true;answer_time=0.;one_shot(1,.88);tell("老渡工：对，就这么敲。我儿子的船听见了，会给你回号。" ,3.)
		"dock":request_dock()
		"ring":
			switch("arrival");one_shot(4 if learned else 0);tell("你敲了两下短的，又敲了一声长的。" if learned else "钟声传到雾里。领港船转过来了。",2.8)
		"ledger":settle(false)

func request_dock()->void:
	if hp<30.:
		hp=43.;rigging_repaired=true;audio.play_cue("buckle");save();tell("港里的铜匠替你铆住裂口。扣除修缮费，钟还能挂起来。",5.);return
	begin_crane()
func begin_crane()->void:
	speed=0.;velocity=Vector2.ZERO;pos=land.road(END);yaw=0.;truck.position=land.surface(pos);truck.rotation=Vector3.ZERO;freight.position=Vector3(-1.42,1.27,0);freight.rotation=Vector3.ZERO
	rig=preload("res://quay_crane.gd").new();add_child(rig);rig.begin(self,Vector2(END+1.8,6.5));switch("crane")
func settle(buy:bool)->void:
	if finished_view or stage!="ledger":return
	finished_view=true
	completed.emit(learned,hp,buy and not fitted and not previously_paid);switch("invite");phrase_left=0.
func _input(ev:InputEvent)->void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT and stage=="drive" and catch_left>0. and not pause_panel and not waybill.visible:
		catch_left=0.;brace_left=Catch.DURATION;swing_v*=.35
		tag_text="扶住了";tag_time=1.05;audio.play_cue("grab")
		get_viewport().set_input_as_handled();return

func _unhandled_input(ev:InputEvent)->void:
	if ev is InputEventKey and ev.pressed and not ev.echo and boarding_age<0.:
		if ev.keycode==KEY_TAB and not pause_panel and stage!="ledger":
			lesson_hold=-1.
			waybill.visible=not waybill.visible;audio.play_cue("page");guide.visible=not waybill.visible
			update_hud();bell_tag.visible=false
			if waybill.visible:waybill.queue_redraw()
			get_viewport().set_input_as_handled();return
		if waybill.visible and ev.keycode in [KEY_ESCAPE,KEY_E]:
			waybill.hide();guide.show();update_hud();get_viewport().set_input_as_handled();return
	if waybill.visible:return
	if ev is InputEventKey and ev.keycode==KEY_SPACE and not ev.pressed and stage=="listen" and lesson_hold>=0. and not pause_panel:
		var held:=age-lesson_hold;lesson_hold=-1.;last_knock=age
		if answer_time<0.:
			if (lesson_hits<2 and held<=.48) or (lesson_hits==2 and held>=.42):
				lesson_hits+=1;one_shot(0,1.17 if lesson_hits<3 else .79,-6.)
				if lesson_hits==3:answer_time=0.;tell("老渡工：就是这个号！我孙女在码头等她爸爸呢。" ,4.)
			else:
				lesson_hits=0;one_shot(1,1.,-10.);tell("老人又示范了一遍：轻敲、轻敲，再让最后一声响久一些。",4.)
		get_viewport().set_input_as_handled();return
	if not ev is InputEventKey or not ev.pressed or ev.echo:return
	if boarding_age>=0.:get_viewport().set_input_as_handled();return
	match ev.keycode:
		KEY_ESCAPE:
			if pause_panel:pause_panel=false
			else:pause_panel=true;lesson_hold=-1.;save()
			update_hud()
		KEY_B:
			if pause_panel or stage=="invite":save();left_dock.emit(0)
		KEY_E:
			if pause_panel:pause_panel=false;update_hud()
			elif stage=="call":
				first_worked=true;switch("yard");tell("师傅：我来敲。你把铜钟抬上车，港口等着用。" ,3.)
			else:action()
		KEY_R:
			if stage=="listen" and not pause_panel and answer_time<0.:
				age=0.;lesson_hits=0;lesson_hold=-1.;last_knock=-10.;song_beat=-1;phrase_left=0.
		KEY_Q:
			if not pause_panel and stage=="yard" and carried:
				depot_turned=not depot_turned;audio.play_cue("foot");phrase_left=0.;save();update_hud()
			elif not pause_panel and stage=="ledger":settle(true)
		KEY_SPACE:
			if not pause_panel and stage=="opening" and (lookout_age<0. or lookout_age>3.9):
				lookout_seen=true;lookout_age=0.;one_shot(3,.92,-8.);update_hud()
			elif not pause_panel and stage=="call":action()
			elif not pause_panel and stage=="drive" and echo_age>2.6:call_echo()
			elif not pause_panel and stage=="listen" and age>=3.3 and answer_time<0.:lesson_hold=age
			elif not pause_panel and stage=="crane":rig.release()
	get_viewport().set_input_as_handled()

func call_echo()->void:
	echo_age=0.;echo_return=false
	var nearest:=INF;var index:=-1
	for i in land.beacon_points.size():
		var d:=pos.distance_to(land.beacon_points[i])
		if d<nearest:nearest=d;index=i
	echo_goal=land.beacons[index].global_position;echo_pitch=.86 if nearest<180. else .71
	one_shot(0,1.,-5.);encounters.on_echo()
	if pos.x>1224.:
		fog_reach=minf(1604.,pos.x+205.)
		tell("铜钟一响，雾里的人沿路点起了引航灯。",2.8)
	if nearest>190.:
		echo_goal=land.surface(land.road(clampf(pos.x+46.,0.,END),old_road))+Vector3.UP*3.;echo_pitch=.74
	if near(land.road(land.WATCH,true,8.6),90.) and not learned:
		echo_goal=land.cup.global_position;echo_pitch=1.24
func echo_tick(dt:float)->void:
	echo_age+=dt
	if echo_age<2.45:
		if echo_age>.65 and not echo_return:
			echo_return=true;reply.global_position=echo_goal;reply.stream=tracks[1 if echo_pitch>1. else 0];reply.pitch_scale=echo_pitch;reply.play()
		for i in rings.size():
			var u:float=echo_age-.17*i
			rings[i].visible=u>0 and u<1.6
			if rings[i].visible:
				var at:=truck.global_position+Vector3.UP*1.15 if u<.64 else echo_goal
				rings[i].global_position=at;rings[i].scale=Vector3.ONE*(.55+fmod(u,.66)*9.)
	else:
		for r in rings:r.hide()
func yard_tick(dt:float,input:Vector2)->void:
	# The fixed camera is on the south side, so screen-up runs toward negative Z.
	var next:=porter+Vector2(input.x,-input.y).limit_length(1.)*dt*(2.45 if carried else 3.7)
	next=next.clamp(Vector2(-9,-11),Vector2(9,5))
	var crossing:=minf(porter.x,next.x)<-.24 and maxf(porter.x,next.x)>-.77
	if crossing:
		var gap:=1.19 if not carried else (.95 if depot_turned else 0.)
		if absf(next.y+5.)>gap or (carried and not depot_turned):
			if absf(porter.x+.50)>.25:next.x=porter.x
			else:next.y=porter.y
			if carried and not gate_passed:tell("钟杠卡住了。按 Q，把长的一头转进门。" ,1.4)
		elif next.x>-.30 and carried and not gate_passed:gate_passed=true;phrase_left=0.;save()
	if next.x>4.52 and absf(next.y)<1.5:next.x=minf(porter.x,4.52)
	move_porter(next,dt,carried)
	if absf(porter.y)<1.23:worker.position.y+=clampf((porter.x-1.)/3.5,0.,1.)*1.09
	if carried:
		freight.global_position=worker.global_position+Vector3.UP*.69+worker.transform.basis.z*.56;freight.rotation.y=lerp_angle(freight.rotation.y,PI*.5 if depot_turned else 0.,1.-exp(-dt*10.))


func move_porter(next:Vector2,dt:float,holding:bool)->void:
	var travel:=next-porter
	var distance:=travel.length()
	rotation_walk+=distance*(3.2 if holding else 2.65)
	var strength:=clampf(distance/maxf(.001,dt*2.2),0.,1.)
	var stride:=sin(rotation_walk)*strength
	if distance>.0001:
		worker.rotation.y=rotate_toward(worker.rotation.y,atan2(travel.x,travel.y),dt*19.)
	var ease:=1.-exp(-dt*20.)
	worker.get_node("LegL").rotation.x=lerpf(worker.get_node("LegL").rotation.x,-stride*.49,ease)
	worker.get_node("LegR").rotation.x=lerpf(worker.get_node("LegR").rotation.x,stride*.49,ease)
	worker.get_node("ArmL").rotation.x=lerpf(worker.get_node("ArmL").rotation.x,-.94 if holding else stride*.35,ease)
	worker.get_node("ArmR").rotation.x=lerpf(worker.get_node("ArmR").rotation.x,-.94 if holding else -stride*.35,ease)
	porter=next
	worker.position=land.surface(porter)

func ear_foot()->Vector2:
	return Vector2(coast.jar.global_position.x-1.04,coast.jar.global_position.z+.89)

func close_to_ear()->bool:
	return porter.distance_to(ear_foot())<1.66

func drive_tick(dt:float,throttle:float,steer:float)->void:
	var forward:=Vector2.from_angle(yaw);var previous:=speed
	var track:=land.road_dist(pos)
	var slope:float=land.ground(pos+forward*.5)-land.ground(pos-forward*.5)
	var top:=7.55 if track<6. else 5.25
	var target:float=throttle*top if throttle>=0. else throttle*(3. if speed<.2 else 7.)
	speed=move_toward(speed,target,(8.8 if throttle<0 and speed>0. else (3.6 if throttle!=0 else 1.55))*dt)
	if absf(speed)>.2:speed=clampf(speed-slope*3.7*dt,-3.,top+1.4)
	var rate:=steer*clampf(absf(speed)*.27,0.,1.3)*(1. if speed>=0. else -1.)
	steer_rate=lerpf(steer_rate,rate,1.-exp(-dt*5.8));yaw+=steer_rate*dt
	forward=Vector2.from_angle(yaw)
	wind=smoothstep(land.FORK,land.FORK+190.,pos.x)*(1.-smoothstep(land.JOIN-230.,land.JOIN,pos.x))*(.28+.72*pow(maxf(0.,sin(elapsed*.72)),2.))
	old_road=absf(pos.y-land.branch(pos.x))+.5<absf(pos.y-land.center(pos.x))
	var band:=clampi(roundi(pos.x/END*100.),0,100)
	driven_sections[band]|=2 if old_road else 1
	if old_road:wind*=.16
	var desired:=forward*speed+Vector2(0,wind*1.2)*minf(absf(speed)*.25,1.)
	velocity=velocity.lerp(desired,1.-exp(-dt*(4.4 if track<6. else 2.5)))
	var next:=pos+velocity*dt
	if land.valid(next):pos=next
	else:
		if absf(speed)>3. and hit_lock<=0.:
			hp=maxf(0.,hp-(2.+absf(speed)*.66)*(.68 if packed or fitted else 1.));hit_lock=1.6;shake=.32;audio.play_cue("bonk");tell("撞上路边障碍　·　钟身遭到冲击",2.)
		speed=move_toward(speed,0.,dt*40.);velocity*=.25
	swing_v+=(-swing*6.6-swing_v*2.5-steer_rate*speed*.31+wind*1.9)*dt
	swing=clampf(swing+swing_v*dt,-.75,.75)
	var bank:float=land.crossfall(pos.x)*cos(yaw)
	var downhill_slide:float=-bank*1.25*smoothstep(2.8,6.8,absf(speed))
	track_bell(dt,(swing*.55+wind*.22)*minf(absf(speed)/4.,1.)+downhill_slide)
	for w in wheels:w.rotation.z-=speed*dt/.52
	truck.position=land.surface(pos);truck.rotation.y=-yaw
	truck.rotation.z=lerp_angle(truck.rotation.z,atan(slope)+clampf((speed-previous)*.16,-.035,.035),1.-exp(-dt*5.))
	truck.rotation.x=lerpf(truck.rotation.x,swing*.11-bank,1.-exp(-dt*4.))
	freight.position=Vector3(-1.42,1.27,slip*.78);freight.rotation.x=swing*.36
	encounters.tick(dt)
	if pos.distance_to(checkpoint_at)>85.:save()
	var region:=land.region(pos.x)
	if region!=last_region:
		last_region=region
		var lines:=["白帆港在山下。沿车辙走，过了山口就能看见海。","路边的石耳能传声。按空格，敲一下车上的钟。","白石桩那边风大、路近。红布旗那边绕远些，有人家。","两条路在这里会合了。翻过前面那座山就是海。","前面起雾了。按空格敲钟，让沿路的人替你点灯。"]
		tell(lines[region],4.,0)
	if pos.x>59. and pos.x<84. and not (visited&8):
		visited|=8;tell("前面是斜坡。松油门更稳，绑带绷紧时点左键扶住钟。",6.,1)
	if pos.x>land.FORK-95. and pos.x<land.FORK and not (visited&1):
		visited|=1;tell("前面两条路都到港。走左边翻山快，走右边能找帆匠垫钟。" ,6.)
	if near(land.road(land.WATCH,true,8.6),55.) and not (visited&2):
		visited|=2;one_shot(1,1.,-8.);tell("叮、叮……当。背后的杯声，竟比山谷多了一下。",5.);save()
	if near(land.road(END),13.) and absf(speed)<1.2:
		speed=0.;velocity=Vector2.ZERO;switch("dock")
func track_bell(dt:float,drift:float)->void:
	var side:=int(signf(drift))
	if catch_side!=0:
		catch_left=maxf(0.,catch_left-dt)
		if absf(drift)<.07:catch_calm+=dt
		else:catch_calm=0.
		if brace_left<=0. and catch_left<=0. and (catch_calm>.25 or drift*catch_side<-.075):
			catch_side=0;catch_calm=0.;catch_hit=false
	var remaining:=BELL_RAIL-slip*side
	var peril:=Catch.reaches_rail(remaining,absf(drift),0.,.055)
	var pushing_rail:=remaining<=.007 and absf(drift)>.095
	if catch_side==0 and absf(speed)>.5 and (peril or pushing_rail):
		catch_side=side;catch_left=Catch.WINDOW if first_catch_seen else 1.05
		first_catch_seen=true;audio.play_cue("buckle")
	if brace_left>0.:
		slip=move_toward(slip,0.,Catch.grip_step(minf(dt,brace_left)));brace_left=maxf(0.,brace_left-dt)
	else:
		slip=clampf(slip+drift*dt,BELL_RAIL*-1.,BELL_RAIL)
	if catch_left<=0. and not catch_hit and absf(slip)>=BELL_RAIL-.002 and drift*slip>.065:
		var loss:=.9 if packed or fitted else 1.55
		hp=maxf(0.,hp-loss);catch_hit=true;catch_side=side
		audio.play_cue("bonk");tag_text="撞到护栏";tag_time=1.4

func physics_input()->Vector2:
	return Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))-float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)))
func _physics_process(dt:float)->void:
	if pause_panel or waybill.visible:return
	if boarding_age>=0.:
		boarding_age+=dt
		fade.modulate.a=smoothstep(.05,.63,boarding_age)
		if boarding_age>=.72:
			boarding_age=-1.;take_ferry=true;left_dock.emit(0);return
	elapsed+=dt;age+=dt;phrase_left=maxf(0.,phrase_left-dt);hit_lock=maxf(0.,hit_lock-dt);tag_time=maxf(0.,tag_time-dt);shake=maxf(0.,shake-dt)
	var input:=physics_input()
	match stage:
		"opening":
			if lookout_age>=0.:lookout_age+=dt
			if age>1. and song_beat<0:one_shot(3,.86,-13.);song_beat=0
			if age>3.6 and song_beat==0:song_beat=1
		"call":pass
		"first_drop":
			if age>.73 and song_beat<0:one_shot(0,1.23,-11.);yard_sound(1,lift.drum.global_position,-4.);song_beat=0
			if age>2.86 and song_beat==0:yard_sound(2,lift.loads[0].global_position,-2.);song_beat=1
			if age>3.26:switch("yard");tell("师傅：你来抬吧。这口钟，今晚得送到白帆港。",6.)
		"silence":
			if age>.60 and song_beat<0:yard_sound(0,land.frame.global_position+Vector3.UP*1.9,2.);song_beat=0

		"yard":yard_tick(dt,input)
		"altar":
			var altar_pt:=land.road(coast.HORN,false,6.6)
			var target:=porter+Vector2(input.x,-input.y).limit_length(1.)*dt*3.4
			var pedestal:=Vector2(coast.jar.global_position.x,coast.jar.global_position.z)
			if target.distance_to(pedestal)<1.04:
				var normal:Vector2=(porter-pedestal).normalized()
				target=pedestal+normal*1.04
			move_porter(target if target.distance_to(altar_pt)<24. else porter,dt,true)
		"inlay":
			var u:=smoothstep(.15,.98,age)
			worker.position=fitting_start.lerp(land.surface(ear_foot()),smoothstep(0.,.67,age))
			var towards:=coast.jar.global_position-worker.global_position
			worker.rotation.y=rotate_toward(worker.rotation.y,atan2(towards.x,towards.z),dt*9.)
			clay_piece.global_transform=shard_start.interpolate_with(coast.jar.global_transform,u)
			clay_piece.global_position+=Vector3(0,.16,.18)*sin(PI*u)
			if age>.98 and song_beat<0:one_shot(0,1.28,-7.);song_beat=0
			if age>1.52:clay_piece.hide();switch("mountain")
		"mountain":
			if age>.58 and song_beat<0:yard_sound(0,land.frame.global_position,0.);song_beat=0
			if age>1.05 and song_beat==0:yard_sound(3,mountain_cup.global_position,-2.);yard_sound(1,lift.drum.global_position,-5.);song_beat=1
			if age>2.83 and song_beat==1:yard_sound(2,lift.loads[1].global_position,-3.);song_beat=2
			if age>3.93:worker.hide();switch("drive");tell("师傅敲木架，陶耳把声音送到了对坡。第二篮也到地了。" ,4.)
		"drive":drive_tick(dt,input.y,input.x)
		"listen":
			if song_beat<0:one_shot(1,1.,-4.);song_beat=0
			land.cup.rotation.x=sin(age*12.)*.34*exp(-fmod(age,.56)*3.) if age<2.6 or lesson_hold>=0. else 0.
			if answer_time>=0.:
				answer_time+=dt
				if answer_time>2.8:
					learned=true;switch("drive");tell("老渡工：多谢。到了港口敲这三下，我儿子的船会回号。",6.)
		"crane":
			if rig.tick(dt,input.x):
				hp=maxf(0.,hp-minf(12.,rig.damage*.32))
				var missed:bool=rig.alignment>1.85;rig.queue_free();rig=null
				if missed:attach_bed();switch("dock");tell("吊钩收回了钟。看地上的圆影，卸到金圈里。",4.)
				elif hp<30.:attach_bed();switch("dock");tell("钟口裂开了。请码头铜匠先铆好，再起吊。",4.)
				else:mount_bell();switch("ring");tell("钟挂好了。码头的人都停下来，等你敲第一声。",4.)
		"arrival":
			var beat:=0 if age<2.8 else (1 if age<5.5 else 2)
			if beat!=song_beat:
				song_beat=beat
				if beat==1:
					one_shot(2 if learned else 3,1.,-4.);tell("雾里也传来两短一长。有人在回号！" if learned else "领港人：听到了，往钟声那边靠！",3.)
				elif beat==2:
					tell("渡工女儿：是爸爸！我在这儿！" if learned else "领港员听见了。第一条渡船正在靠岸。",5.5)
			if age>11.5:switch("ledger")
	if stage in ["opening","call","first_drop","yard","silence","mountain"] or (stage=="drive" and pos.x<50.):
		lift.fire_tick(dt);lift.animate(stage,age,first_worked,blessing)
	coast.animate(elapsed,pos,fog_reach,blessing and stage!="inlay");echo_tick(dt);pose(dt);guide.tick(dt);tick_ui-=dt
	if tick_ui<=0.:tick_ui=.12;update_hud()

func signal_pulse(t:float,second:float,third:float)->float:
	if t<0.:return 0.
	if t<third:
		var start:=0. if t<second else second
		return 1.-smoothstep(.055,.24,t-start)
	return 1.-smoothstep(.22,.77,t-third)

func cast_tick(dt:float)->void:
	if stage!="listen":cup_signal.hide()
	port_signal.visible=learned and stage in ["arrival","ledger","invite"]
	if port_signal.visible:
		var pulse:=signal_pulse(age-2.8,.55,1.24) if stage=="arrival" else 0.
		port_signal.scale=Vector3(.30,.36,.27)*(.36+1.65*pulse)
	var now:=elapsed
	var smith:=land.apprentice
	if stage in ["opening","call","first_drop","silence","yard","mountain"]:
		var gesture:=smoothstep(.12,.58,age)
		var pointing:=1. if stage=="call" else (1.-smoothstep(.4,1.6,age) if stage=="first_drop" else 0.)
		var waiting:=1. if stage=="silence" else 0.
		var explaining:=stage in ["opening","call","silence"] and age<4.7
		smith.get_node("ArmL").rotation.z=lerpf(smith.get_node("ArmL").rotation.z,-.13-1.13*pointing,1.-exp(-dt*9.))
		smith.get_node("ArmL").rotation.x=lerpf(smith.get_node("ArmL").rotation.x,-.36-.62*pointing,1.-exp(-dt*9.))
		smith.get_node("ArmR").rotation.x=-.19-waiting*.44-.68*exp(-pow((age-.55)*4.,2.))*waiting
		foreman_face.perform(dt,now,Vector2(-.64*pointing-.48*waiting,.05+.18*waiting),-.65*waiting,explaining)
		var listening:=stage in ["call","silence"] or (stage=="first_drop" and age<.85)
		lift.hand.get_node("ArmL").rotation.x=-1.96*gesture if listening else -.92
		lift.hand.get_node("ArmL").rotation.z=-.32 if listening else -.18
		apprentice_face.perform(dt,now,Vector2(.55 if listening else -.30,.19 if listening else .43),-.6 if stage=="silence" else .47,stage=="first_drop" and age<2.4)
	if stage=="listen":
		var knocking:float=signal_pulse(age,.38,1.04)
		if age-last_knock<.33:knocking=maxf(knocking,1.-smoothstep(0.,.33,age-last_knock))
		cup_signal.visible=knocking>.06;cup_signal.scale=Vector3.ONE*(1.+.53*(1.-knocking))
		land.elder.get_node("ArmR").rotation.z=-.35-.23*knocking
		land.elder.get_node("ArmR").rotation.x=-.69-knocking*.78
		land.elder.get_node("ArmL").rotation.x=-1.09
		ferryman_face.perform(dt,now,Vector2(.48,.20 if age<2. else -.03),.58,age<2.8 or (answer_time>0. and answer_time<2.))
	if stage=="camp_talk":
		land.helper.rotation.y=-.47
		land.helper.get_node("ArmR").rotation.x=-.94-.24*smoothstep(.45,1.2,age)
		sailmaker_face.perform(dt,now,Vector2(-.08,.12+.10*sin(age*2.)),.39,age<4.8)
	if stage in ["opening","arrival","invite","ledger"]:
		var greeting:=stage=="arrival" and learned and age>5.
		var sea:=stage=="opening" or (stage=="arrival" and age<5.)
		daughter_face.perform(dt,now,Vector2(.53 if sea else -.10,-.12 if greeting else .05),.92 if greeting or stage=="invite" else -.76,stage=="invite" and age<5. or greeting and age<7.6)
		pilot_face.perform(dt,now,Vector2(.26,-.07),.58 if stage=="invite" else -.47,age<4.3 and stage in ["opening","invite"])

func pose(dt:float)->void:
	var at:Vector3;var offset:Vector3;var immediate:=not cam_started
	pilot_lamp.visible=stage=="opening" or stage=="invite"
	if stage not in ["opening","arrival","ledger","invite"]:coast.skiff.hide()
	var twilight:=.63*smoothstep(1040.,END,pos.x)
	if stage in ["ledger","invite"]:twilight=1.
	elif stage=="arrival":twilight+=.37*smoothstep(2.,9.,age)
	if stage=="mountain":twilight=.28
	evening(twilight)
	var haze:=smoothstep(1112.,1368.,pos.x)*(1.-.45*smoothstep(END-80.,END,pos.x))
	if stage in ["arrival","ledger","invite"]:haze*=1.-smoothstep(2.,9.,age) if stage=="arrival" else .12
	atmosphere.fog_density=lerpf(.0023,.026,haze);atmosphere.fog_light_color=Color("#a9c3c8").lerp(Color("#afc3d0"),haze);atmosphere.fog_light_color=atmosphere.fog_light_color.lerp(Color("#b2a4b1"),twilight*.49);atmosphere.fog_sun_scatter=.08
	if stage in ["arrival","ledger","invite"]:
		var landing:=smoothstep(4.9,11.,age) if stage=="arrival" else 1.
		coast.skiff.visible=learned and (stage!="arrival" or age>=2.45)
		coast.skiff.position=Vector3(22.,-.73,36.).lerp(Vector3(-3.,-.7,20.1),landing)+Vector3.UP*sin(elapsed*1.8)*.06
		coast.daughter.rotation.y=lerp_angle(-2.1,.98,landing)
		coast.daughter.position=Vector3(-4.,0,10.4).lerp(Vector3(-2.,0,15.1),landing)
		coast.daughter.get_node("ArmL").rotation.z=sin(elapsed*6.)*.35-1.9 if learned and landing>.01 else 0.
		coast.daughter.get_node("ArmR").rotation.z=1.8-sin(elapsed*5.)*.23 if learned and landing>.01 else 0.
	mallet.visible=stage in ["call","first_drop"]
	letter_prop.visible=stage=="invite" and learned
	if mallet.visible:
		worker.position=land.frame.global_position+Vector3(-1.04,.01,.60);worker.rotation.y=2.16
		worker.get_node("ArmR").rotation.x=-.83+.79*exp(-pow(age*4.,2.)) if stage=="first_drop" else -.9
	camp_shard.visible=stage=="camp_talk"
	felt_pad.visible=(packed or fitted) and freight.get_parent()==truck
	if stage=="inlay":
		at=coast.jar.global_position+Vector3(-.23,-.10,0);offset=Vector3(.78,.63,3.69)
	elif stage=="camp_talk":
		at=land.stations.camp.global_position+Vector3(.4,1.15,.2);offset=Vector3(-2.6,1.25,4.6)
	elif stage=="opening":
		land.ferry.position=Vector3(8.6+sin(age*.27)*.32,-.69,24.-sin(age*.22)*.38);land.ferry.rotation.z=sin(age*1.5)*.035
		coast.daughter.get_node("ArmL").rotation.z=-1.94+.22*sin(age*6.)
		coast.skiff.show()
		var loss:=smoothstep(.30,4.7,lookout_age) if lookout_age>=0. else .10*sin(age*.37)
		coast.skiff.position=Vector3(15.6+8.5*loss,-.76+.10*sin(age*1.55),34.2+12.2*loss)
		coast.skiff.rotation=Vector3(.021*cos(age),-.38,.033*sin(age*1.47))
		var view:=smoothstep(0.,.86,lookout_age)*(1.-smoothstep(3.1,4.6,lookout_age)) if lookout_age>=0. else 0.
		land.captain.rotation.y=lerp_angle(-2.70,.68,view);land.captain.get_node("ArmR").rotation.x=-.46-view*1.53
		var pilot:=land.captain.global_position+Vector3.UP*1.14
		at=pilot.lerp(coast.skiff.global_position+Vector3.UP*1.25,view*.79+.095)
		offset=Vector3(-4.25,1.90,-4.65).lerp(Vector3(-3.25,1.25,-7.25),view)
		atmosphere.fog_density=.031+view*.016
	elif stage in ["call","first_drop","silence","mountain"]:
		var near_bell:=land.frame.global_position+Vector3(-1.45,1.36,-.03)
		var near_winch:=lift.loads[1 if stage in ["silence","mountain"] else 0].global_position
		near_winch=near_winch.lerp(lift.hand.global_position+Vector3.UP*.97,.40)
		var follow:float=smoothstep(.13,1.48,age) if stage in ["first_drop","silence","mountain"] else 0.
		at=near_bell.lerp(near_winch,follow)
		offset=Vector3(-1.8,1.64,5.65).lerp(Vector3(3.5,1.83,7.05),follow)
	elif stage=="invite":
		land.ferry.position=Vector3(5.,-.6,21.)+Vector3.UP*sin(elapsed*1.2)*.09
		var host:=coast.daughter if learned else land.captain
		at=host.global_position+Vector3.UP*1.12;offset=Vector3(-2.8,1.46,-4.18)
		if not learned:land.captain.global_rotation.y=-2.54;land.captain.get_node("ArmL").rotation.x=-.81+.16*sin(age*2.)
		if learned and song_beat<0 and age>.29:yard_sound(4,coast.daughter.global_position,-1.);song_beat=0
		coast.daughter.rotation.y=-2.58;coast.daughter.get_node("ArmL").rotation.z=-.25;coast.daughter.get_node("ArmR").rotation.z=.19;coast.daughter.get_node("ArmR").rotation.x=-1.12+.17*sin(age*2.)
	elif stage=="yard":
		at=land.surface(porter).lerp(land.surface(Vector2(1,-3)),.29)+Vector3.UP*1.05;offset=Vector3(0,7.2,11.2)
	elif stage=="altar":
		at=worker.global_position.lerp(coast.jar.global_position,.32)+Vector3.UP*.95;offset=Vector3(0,4.4,7.1)
	elif stage=="listen":
		at=land.elder.global_position+Vector3.UP*1.1;offset=Vector3(-3.4,1.5,-4.1)
	elif stage in ["ring","arrival","ledger"]:
		var u:=smoothstep(1.4,9.,age) if stage=="arrival" else (1. if stage in ["ledger","invite"] else 0.)
		land.ferry.position=land.boat_from.lerp(Vector3(5.,-.6,21.),u)+Vector3.UP*sin(elapsed*1.2)*.09
		land.ferry.rotation.z=sin(elapsed*.83)*.022
		at=land.harbor_frame.global_position+Vector3.UP*2.+Vector3(1.8,0,5.4)*u;offset=Vector3(-7.7,4.5,-8.5)
		if stage=="arrival" and learned:
			var return_call:=smoothstep(1.7,2.75,age)*(1.-smoothstep(4.1,5.55,age))
			at=at.lerp(coast.skiff.global_position+Vector3.UP*.85,return_call)
			offset=offset.lerp(Vector3(-4.3,2.1,-6.5),return_call)
			var reaction:=smoothstep(4.1,5.55,age)*(1.-smoothstep(8.7,10.9,age))
			at=at.lerp(coast.daughter.global_position+Vector3.UP*1.17,reaction)
			offset=offset.lerp(Vector3(-3.4,1.6,5.6),reaction)
		freight.body.rotation.z=.14*sin(age*7.)*exp(-age*.49) if stage=="arrival" else 0.
	elif stage in ["dock","crane"]:
		at=land.surface(Vector2(END,3))+Vector3.UP*1.8;offset=Vector3(-8.2,7.4,8.5)
	else:
		var ahead:=Vector3(cos(yaw),0,sin(yaw));at=truck.global_position+Vector3.UP*1.65+ahead*1.9;offset=-ahead*11.7+Vector3.UP*(5.2+.035*absf(speed));at+=Vector3.UP*.52
	var smoothing:=1. if immediate else 1.-exp(-dt*(6. if stage=="drive" else 3.5))
	if not cam_started or cam.global_position.distance_to(at)>100.:smoothing=1.
	cam.global_position=cam.global_position.lerp(at+offset,smoothing);focus_smooth=focus_smooth.lerp(at,smoothing)
	cam.look_at(focus_smooth+Vector3.UP*(sin(elapsed*43.)*shake*.12));cam_started=true
	cast_tick(dt)
	var awaken:=0.
	if stage=="first_drop" or stage=="arrival":awaken=1.-smoothstep(1.3,3.2,age)
	elif stage=="drive" and echo_age<2.5:awaken=sin(PI*clampf(echo_age/2.5,0.,1.))
	elif stage in ["inlay","mountain"]:awaken=.82
	freight.answer(awaken,dt)
	if freight.tongue:freight.tongue.rotation.x=swing*.55+sin(echo_age*12.)*exp(-echo_age*2.2)*.35
	var warning:=catch_left>0.
	cue_strap.visible=stage=="drive" and (warning or brace_left>0.)
	if cue_strap.visible:cue_strap.scale=Vector3.ONE*(1.+.065*sin(PI*catch_left/Catch.WINDOW))
	if stage=="drive" and not pause_panel and (warning or brace_left>0. or tag_time>0. or hit_lock>0. or absf(slip)>.37):
		bell_tag.set_balance(true,slip/BELL_RAIL)
		var detail:="左键  扶住" if warning else (tag_text if tag_time>0. else ("货物受冲击" if hit_lock>0. else ""))
		bell_tag.follow(cam,freight.global_position+Vector3.UP*1.48,"回声钟",hp,detail,warning or hit_lock>0.)
	else:bell_tag.hide()
func next_task()->String:
	match stage:
		"opening":return "去铸钟山借一口钟，给雾里的渡船引路。"
		"call","first_drop":return "敲一次钟，看对坡的学徒怎么放篮。"
		"yard":
			if not carried:return "到木架旁，把回声钟抬起来。"
			return "沿木坡走上车尾，放好铜钟。" if gate_passed else "转动钟杠，从两根石柱之间穿过去。"
		"silence","drive":return "把铜钟送到白帆港。两条路都能到。"
		"camp_talk":return "听听帆匠的托付，再带上钟垫出发。"
		"listen":return "跟老渡工学敲家里的船号。"
		"altar","inlay","mountain":return "把陶片装回石台，给山上的人传个信。"
		"dock","crane":return "把铜钟吊到码头的圆垫上。"
		"ring":return "敲响港钟，让雾里的船听见。"
		"arrival","ledger":return "等渡船靠岸，再收下运费。"
		"invite":return "随船开夜班，或回委托簿接下一单。"
	return "把回声钟送到白帆港。"

func update_hud()->void:
	if not is_instance_valid(title):return
	var km:float=maxf(0.,END-pos.x)/1000.
	var names:=["铸钟山","石耳峡","双路岭","云背垭口","白帆港"]
	title.text="第一声港钟　/　"+str(names[land.region(pos.x)])
	caption.text="把回声钟送到白帆港"
	ledger.text=phrase if phrase_left>0. else ""
	match stage:
		"opening":
			title.text="第一声港钟";caption.text="白帆港　·　清晨海雾"
			controls.text="空格  举灯示意      E  上山借钟" if not lookout_seen else "E  上山借钟"
			ledger.text="领港人：看，红帆又绕回来了。我再举一次灯，试试船上能不能看见。"
			if lookout_seen:ledger.text="领港人：船上看不见我们。听说山上有口钟，声音能穿过大雾。劳驾你跑一趟。"

		"call":title.text="铸钟山　/　早班";caption.text="对坡的学徒等着放篮";ledger.text="师傅：敲一下。回声神会替你传到对坡，学徒听见了才敢放篮。";controls.text="E  请师傅代敲"
		"first_drop":title.text="铸钟山　/　早班";controls.text="";ledger.text="学徒：听到了！我这就放篮。" 
		"silence":title.text="铸钟山　/　第二篮";caption.text="铜钟已经上车";controls.text="E  发车去白帆港" if age>=1.35 else "";ledger.text="师傅：钟搬走了，敲木架可传不到对坡。那篮铜，只能先吊着了。"
		"invite":
			title.text="白帆港　/　入夜";caption.text="蓝棚木阶的夜渡正要启航"
			ledger.text="渡工女儿：爷爷还在山上等消息。能把信带给双灯窑的窑工吗？他明早上山。" if learned else "领港人：多亏你送来这口钟。走吧，我载你去上夜班。"
			if learned and letter_history==1:ledger.text="渡工女儿：信还在船上。去双灯窑那班船，你一起来吗？"
			if learned and letter_history==2:ledger.text="渡工女儿：爷爷收到了，谢谢你。今晚还跟我们跑一班吗？"
			controls.text="E  跟船去双灯窑　　 B  回委托簿" if learned and letter_history<2 else "E  随船开夜班　　 B  回委托簿"
		"yard":
			controls.text="WASD  走动" if not carried else ""
		"drive":
			caption.text="%s　　距白帆港 %.1f 公里　　%d km/h"%[("旧渡路" if old_road else "海岸公路"),km,roundi(absf(speed)*3.6)]
			controls.text="W 加速　S 刹车　A D 转向　空格 敲钟问路" if pos.x<48. else ""
			if controls.text=="" and ((pos.x>land.FORK-80. and pos.x<land.FORK+105.) or (km<.80 and fog_reach<pos.x+15.)):controls.text="空格  敲钟问路"
			if km<.04:controls.text="S  减速，停到钟架旁"
		"camp_talk":
			title.text="旧渡路　/　帆匠的红棚";caption.text="帆匠把一层厚布垫在钟下"
			ledger.text="帆匠：这片陶是从山口那只耳朵上掉的。你路过，帮它装回去成吗？"
			controls.text="E  收好钟垫和陶片，继续赶路"
		"altar":title.text="云背垭口　/　给山留声";controls.text="WASD  走动"
		"inlay":title.text="云背垭口";caption.text="把陶片还给山";ledger.text="陶片严丝合缝。远远地，又响起了师傅敲木架的声音。";controls.text=""
		"mountain":title.text="此刻　/　铸钟山";caption.text="学徒又敲了一下空钟架";controls.text="";ledger.text="学徒：师傅，我听见啦！这就放第二篮。"
		"listen":
			title.text="旧渡路　/　那只搪瓷杯";caption.text="旧渡工用过的家船号"
			controls.text="看杯口亮起的节奏";ledger.text="老渡工：那艘红帆船是我儿子的。敲两短一长，他就知道是家里人叫他。"
			if age>3.3 and answer_time<0.:
				controls.text="空格  敲杯　　R  再听一遍　　E  请爷爷带着敲"
				ledger.text=["老渡工：来，先轻按一下。我孙女也在码头等她爸爸呢。","老渡工：再轻按一下。","老渡工：最后一下按久点，再松手。"][clampi(lesson_hits,0,2)] if phrase_left<=0. else phrase
			elif answer_time>=0.:controls.text="铜钟记住了家船的信号。"
		"dock":controls.text="E　请港口铜匠铆住裂口（修缮费 4 枚）" if hp<30. else ""
		"crane":controls.text="A / D  移动吊车　　"+str(rig.hint if is_instance_valid(rig) else "")
		"ring":controls.text="敲出爷爷教你的船号" if learned else ""
		"arrival":controls.text=""
		"ledger":
			title.text="白帆港　/　第一笔入账";caption.text="港钟已挂好，下一班夜渡会听见它。"
			ledger.text="旧渡工的家船与领港船都已回港" if learned else "领港船已靠岸　·　旧渡路上，还有一种钟声"
			if blessing:ledger.text+="　·　铸钟山重获回声"
			controls.text="E 返回委托簿" if previously_paid else "运费 %d 枚　·　E 存进商号　　Q 花 12 枚缝永久钟毡，再回委托簿"%fare(hp,learned,rigging_repaired)
	if pause_panel:
		title.text="已暂停　/　行程已记下";caption.text="进度已保存";controls.text="E / Esc  继续　　B  回委托簿";ledger.text="路上用 W 加速、S 刹车，A D 转向。空格敲钟，货物快撞栏时点左键。"
	manifest.visible=not waybill.visible
	var show_text:=(stage!="ledger" or pause_panel) and not waybill.visible
	for text_node in [title,caption,controls,ledger]:text_node.visible=show_text
	manifest.refresh()
static func fare(integrity:float,song:bool,repaired:=false)->int:return 14+(12 if integrity>=90 else (7 if integrity>=60 else 2))+(6 if song else 0)-(4 if repaired else 0)

