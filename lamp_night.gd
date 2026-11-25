extends "res://tide_night.gd"

signal wish_accepted(id:int)
var wish_id:=-1
var wish_mask:=0
var quay_welcome:=""
var wishes:Node3D
signal grain_progress(barge:Vector2,helm:Vector2,yaw:float,bumps:int,barge_yaw:float,velocity:Vector2)
signal grain_signed(bumps:int)
var mail_pin:=preload("res://world_pin.gd").new()
var letter_face:=preload("res://speaker_pose.gd").new()
var posted_age:=-1.
var pilots:Node3D
var lamp_offer:=false
var bell_boarding:=false
var handover_fade:ColorRect
var handover_time:=0.
var letter_writer:Node3D
var postal_sack:Node3D
var letter_motion:=-1.
var letter_from:=Vector3.ZERO
var letter_to:=Vector3.ZERO
var letter_intro:=0.
var harbor_bell:=false
var harbor_song:=false
var bell_answered:=false
var harbor_voice:AudioStreamPlayer3D
signal letter_progress(next:int)
var letter_stage:=0
var family_letter:Node3D
var grain_status:=0
var grain_origin:=Vector2.ZERO
var helm_origin:=Vector2.ZERO
var saved_yaw:=0.
var barge_yaw:=0.
var barge_velocity:=Vector2.ZERO
var unload_age:=-1.
var grain_bumps:=0
var mill_trade:=false
var net_gate:Node3D
var lighter:Node3D
var last_tow_save:=Vector2.ZERO
var tow_framing:=0.
signal works_changed(step:int)
signal day_shift
var table_inn:=false
var table_crew:=false
signal fruit_signed
var fruit_reserved:=false
var fruit_sold_before:=false
var fruit_crate:Node3D
var fruit_display:Node3D
signal change_shift
const BERTH:=Vector2(-8,24)
signal worker_boarded
signal worker_home
var board_at_quay:=false
var worker_signed:=false
signal mirror_order
var mirror_built:=false
var mirror_age:=-1.
var available_funds:=0
var paid_crossings:=0
var bronze:Node3D
var kiln_talk:=0.0
var tile_signs:Array[Sprite3D]=[]
var used_echo:=false
var hail_age:=12.
var hailed_worker:=false
var first_look:=0.0
var stair_look:=0.
var looking_at_steps:=false
var ferry_guide:Control
var worker_aboard:=false
var fare_scene:Node3D
var worker:Node3D
var oven_installed:=false
var harbour_charter:=preload("res://lamp_charter.gd").new()
var has_market:=false
var fire_chime:=AudioStreamPlayer.new()
var ropes:=AudioStreamPlayer.new()
var voices:=AudioStreamPlayer3D.new()
var lit_count:=0
var works:=0
var quay:=preload("res://lamp_quay.gd").new()
var rig:Node3D
var freight:Node3D
var land:
	get:return self
var audio:
	get:return sound
var wind_job:=false
var ceremony:=-1.
var pier_fade:ColorRect
var lantern_crate:Node3D
var pots:Node3D
var transfer_node:Node3D
var transfer_start:=Vector3.ZERO
var transfer_left:=0.
var boarding_worker:=false
var walking_home:=false
var marker:Label3D

func ground(_p:Vector2)->float:return .16
func surface(p:Vector2)->Vector3:return Vector3(p.x,.16,p.y)

func _ready()->void:
	super()
	if works>0 or harbor_bell:
		cam.environment.ambient_light_energy=.29
		cam.environment.fog_light_color=Color("#385464")
		cam.environment.fog_light_energy=.73;cam.environment.fog_sun_scatter=.12
		for light in get_children():
			if light is DirectionalLight3D:light.light_energy=.39;light.light_color=Color("#91b9dc")
	hud.add_child(mail_pin);mail_pin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mail_pin.mouse_filter=Control.MOUSE_FILTER_IGNORE;mail_pin.hide()
	hud.add_child(harbour_charter);harbour_charter.mirror_requested.connect(request_mirror)
	add_child(quay);quay.position=Vector3(BERTH.x,.10,BERTH.y+3.4);quay.oven_installed=oven_installed;quay.waterfront();quay.build(works==3)
	if harbor_bell:
		wishes=preload("res://quay_wishes.gd").new();add_child(wishes);wishes.build(self,wish_id,wish_mask);wishes.signed.connect(func(id:int):wish_accepted.emit(id))
		var moored:=preload("res://harbor_convoy.gd").new();add_child(moored);moored.position=Vector3(-23.,-.51,30.8);moored.scale=Vector3.ONE*.71;moored.show_return(12.)
		preload("res://listening_herm.gd").new().build(quay,Vector3(6.28,.53,2.85),PI*.91,1.52)
		pilots=preload("res://night_pilots.gd").new();add_child(pilots);pilots.build(quay,cam.environment)
		ferry_guide=preload("res://ferry_guide.gd").new();ferry_guide.job=self;hud.add_child(ferry_guide)
		if mirror_built:pilots.mount_mirror(quay)
		bronze=preload("res://bell_cast.gd").new();quay.add_child(bronze);bronze.position=Vector3(4.5,2.3,0);bronze.scale=Vector3.ONE*.8
		for s in [-1,1]:art.beam(quay,Vector3(4.5,0,s),Vector3(4.5,3.45,s),.11,"#96734f")
		art.beam(quay,Vector3(4.5,3.45,-1.2),Vector3(4.5,3.45,1.2),.14,"#b58e5c")
		harbor_voice=AudioStreamPlayer3D.new();bronze.add_child(harbor_voice);harbor_voice.stream=preload("res://audio/harbor_horn.wav") if harbor_song else preload("res://audio/bronze_reply.wav");harbor_voice.unit_size=12.;harbor_voice.max_distance=90.
	if harbor_song:
		letter_writer=art.courier(quay,true);preload("res://bell_household.gd").new().dress(letter_writer);letter_writer.position=Vector3(2.35,.13,-.62);letter_writer.rotation.y=PI
		family_letter=preload("res://bell_household.gd").new().make_letter(quay)
		postal_sack=art.group(docks[3],Vector3(1.18,.78,1.38))
		art.ball(postal_sack,Vector3.UP*.23,Vector3(.65,.59,.43),"#947357")
		art.ring(postal_sack,Vector3.UP*.47,.21,.035,"#cfaa75")
		letter_writer.position=Vector3(1.38,.17,-1.23)
		letter_face.bind(letter_writer,1.13)
		letter_writer.get_node("ArmR").rotation.x=-.95
		place_letter()
	if has_market:quay.breakfast_stall(true)
	if table_inn and table_crew:quay.set_feast()
	if worker_signed:quay.seat_regular();launch_lighter()
	add_child(fire_chime);fire_chime.stream=preload("res://audio/blue_quay_clay.wav");fire_chime.volume_db=-10
	add_child(ropes);ropes.stream=preload("res://audio/blue_quay_rope.wav");ropes.volume_db=-9
	quay.add_child(voices);voices.position=Vector3(0,1,1);voices.stream=preload("res://audio/blue_quay_evening.wav");voices.max_distance=24.;voices.unit_size=8.;voices.volume_db=-12
	worker=art.courier(boat,true);preload("res://zephyr_people.gd").new().costume(worker,"miller");worker.position=Vector3(.7,.53,-.6);worker.scale=Vector3.ONE*.78;worker.visible=worker_aboard
	lantern_crate=quay.lantern(boat,Vector3(-.82,.76,-.49));lantern_crate.visible=works==2
	marker=design.label(self,Vector3(BERTH.x,5.7,BERTH.y+3),"蓝棚木阶",face,"#ffe4af")
	install_tile(quay,Vector3(-3.67,2.15,-.7),preload("res://art/watch_blue.jpg"),1.0)
	install_tile(self,Vector3(PORTS[3].x+2.4,2.5,PORTS[3].y+2.3),preload("res://art/watch_kiln.jpg"),1.5)
	pots=preload("res://kiln_workshop.gd").new();docks[3].add_child(pots);pots.build(quay,works,works==3 and not worker_aboard)
	fruit_crate=make_fruit_case(boat,Vector3(-1.35,.65,.48));fruit_crate.visible=fruit_reserved
	fruit_display=make_fruit_case(docks[3],Vector3(.5,.63,1.5));fruit_display.visible=fruit_sold_before
	if harbor_bell:
		fare_scene=preload("res://quay_fare.gd").new();add_child(fare_scene);fare_scene.build(self)
	marker.pixel_size=.013
	if works==1:say("窑工在双灯窑等船 · 去东面的双灯火取陶灯",4)
	if bell_boarding:
		depart_blue_quay()
		handover_fade=ColorRect.new();hud.add_child(handover_fade);handover_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);handover_fade.color=Color("#132e3a");handover_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if board_at_quay and works in [1,3] and not worker_aboard:depart_blue_quay()
	if not bell_boarding and harbor_song and letter_stage<2 and works<2 and grain_status!=1:
		bell_boarding=true;depart_blue_quay()
	if worker_aboard or works==2:
		pos=PORTS[3]+Vector2(-2.5,0);heading=PI;view_heading=heading;port=3;cam_ready=false;pose(1.,0.)
		say("窑工还在船上 · 回蓝棚木阶赶末班" if worker_aboard else "陶灯仍在船上 · 回蓝棚木阶安装",4)
	if grain_status==1:
		pos=helm_origin;heading=saved_yaw;view_heading=heading;cam_ready=false;port=nearest_port()
		last_tow_save=pos;pose(1.,0.);say("粮驳仍系在船尾 · 给拖缆留出过弯空间",3.)
	ui_update()

func make_fruit_case(parent:Node3D,at:Vector3)->Node3D:
	var n:=art.group(parent,at)
	art.box(n,Vector3.UP*.13,Vector3(.85,.26,.6),"#a3794f")
	for j in 6:art.ball(n,Vector3((j%3-1)*.25,.27,(j/3-.5)*.24),Vector3.ONE*.25,"#ec9a45",true)
	return n

func launch_lighter()->void:
	if is_instance_valid(lighter):return
	net_gate=preload("res://quay_net.gd").new();add_child(net_gate)
	lighter=preload("res://grain_lighter.gd").new();add_child(lighter)
	if grain_status==2:
		lighter.location=BERTH+Vector2(5.,.45);lighter.yaw=PI*.82;quay.grain_received()
		for sack in lighter.sacks:sack.hide()
	elif grain_status==1:
		lighter.location=grain_origin;lighter.yaw=barge_yaw;lighter.velocity=barge_velocity;lighter.impacts=grain_bumps;lighter.set_tow(true)
	lighter.place()

func save_tow()->void:
	last_tow_save=pos
	grain_progress.emit(lighter.location,pos,heading,lighter.impacts,lighter.yaw,lighter.velocity)

func tow_use()->bool:
	if lighter==null or grain_status==2:return false
	if grain_status==0 and pos.distance_to(lighter.location)<6.2:
		if absf(speed)>2.:say("粮驳在等缆 · 慢航靠上去");return true
		if worker_aboard or not seats.is_empty() or bread_loaded:say("船夫：「先送完这一班，再替粮驳引航。」");return true
		grain_status=1;lighter.set_tow(true);ropes.play();save_tow();say("拖缆已系牢 · 转弯放宽，领粮驳回蓝棚",3.);return true
	if grain_status==1:
		if pos.distance_to(BERTH)>5.2:say("把粮驳领回蓝棚 · 弯道给船尾留足空间");return true
		if absf(speed)>2.:say("慢慢收桨，再把拖缆递给岸上");return true
		if lighter.location.distance_to(BERTH)>13.:say("驳船还在外侧 · 缓缓靠岸等船尾入港");return true
		grain_status=2;lighter.moor_to(BERTH+Vector2(5.,.45));unload_age=0.
		quay.grain_received();grain_signed.emit(lighter.impacts);chord.play()
		var pay:=12+(2 if harbor_bell else 0)+maxi(0,6-2*int(lighter.impacts))+(6 if mill_trade else 0)
		say("运费 %d 枚 · 伊娅升起谷神麦穗印，明早开炉！"%pay,5.);return true
	return false

func install_tile(parent:Node3D,where:Vector3,texture:Texture2D,side:float)->void:
	var tile:=Sprite3D.new()
	tile_signs.append(tile);parent.add_child(tile);tile.texture=texture;tile.position=where
	tile.pixel_size=side/float(texture.get_width());tile.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y
	art.beam(parent,where-Vector3.UP*(side*.45),where-Vector3.UP*2.5,.07,"#796447")
func depart_blue_quay()->void:
	pos=BERTH-Vector2(1.,1.9);heading=-.18;view_heading=heading;speed=0;port=-1;cam_ready=false
	pose(1.,0.);ui_update()
func next_harbour()->Vector2:
	if grain_status==1 or worker_aboard or works==2:return BERTH
	if harbor_song and bell_boarding and letter_stage<2:return BERTH if letter_stage==0 else PORTS[3]
	if works<=1 and seats.is_empty() and (works==1 or harbor_bell):return PORTS[3]
	return super()
func change_works(value:int)->void:
	works=value;works_changed.emit(value)

func pulse()->void:
	if first_passenger_waiting() and not hailed_worker and pos.distance_to(BERTH)<9.:
		hailed_worker=true;hail_age=0.;horn.play()
		say("船夫：我替你问问对岸。",1.40)
		return
	var ready:=pulse_charge>=.99
	super()
	if ready and is_instance_valid(pilots):
		pilots.call_from(pos);used_echo=true
		if works==2 and grain_status!=1:say("船夫：它听见了！沿着亮起来的浮灯回木阶。",3.4)
	if ready and grain_status==1 and net_gate.call_keeper(pos):
		ropes.play();say("闸工听见了 · 网门升起，领船从内孔过",2.8)

func first_passenger_waiting()->bool:
	return stage=="sail" and harbor_bell and works==3 and not worker_signed and not worker_aboard and seats.is_empty() and not bread_loaded and not fruit_reserved and grain_status==0 and not (harbor_song and bell_boarding and letter_stage<2)

func begin_transfer(node:Node3D,from:Vector3)->void:
	transfer_node=node;transfer_start=from;transfer_left=1.25
	node.global_position=from

func move_transfer(dt:float)->void:
	if transfer_left<=0.:return
	transfer_left=maxf(0.,transfer_left-dt)
	var u:=1.-transfer_left/1.25
	var target:=boat.to_global(Vector3(.7,.53,-.6) if boarding_worker else Vector3(-.82,.76,-.49))
	if walking_home:target=quay.local_worker.global_position
	transfer_node.global_position=transfer_start.lerp(target,smoothstep(0.,1.,u))+Vector3.UP*sin(PI*u)*(.22 if walking_home or boarding_worker else .89)
	if boarding_worker or walking_home:
		worker.get_node("LegL").rotation.x=.42*sin(u*TAU*2);worker.get_node("LegR").rotation.x=-.42*sin(u*TAU*2)
	if transfer_left<=0:
		if walking_home:worker.hide();quay.local_worker.show()
		boarding_worker=false;walking_home=false;transfer_node=null

func place_letter()->void:
	var location:Node3D=letter_writer.get_node("ArmR") if letter_stage==0 else (boat if letter_stage==1 else docks[3])
	if family_letter.get_parent()!=location:family_letter.reparent(location,false)
	family_letter.position=[Vector3(0,-.32,.20),Vector3(.54,.70,.28),Vector3(1.18,1.30,1.38)][letter_stage]
	family_letter.rotation=Vector3(-1.38,.06,0.) if letter_stage==1 else Vector3.ZERO

func move_letter(next:int)->void:
	var origin:=family_letter.global_position
	if next==2:posted_age=0.
	letter_stage=next;place_letter();letter_to=family_letter.global_position;letter_from=origin;letter_motion=0.
	family_letter.global_position=origin;letter_progress.emit(next)

func use()->void:
	if is_instance_valid(wishes) and wishes.near_boat():
		wishes.read_note();return
	if harbor_song and stage=="sail" and absf(speed)<2.6:
		if letter_stage==0 and pos.distance_to(BERTH)<5.2:
			move_letter(1);sound.play_cue("grab");say("渡工女儿：信里写着爸爸到家了。双灯窑的窑工会替我捎给爷爷。",4.2);return
		if letter_stage==1 and port==3:
			move_letter(2);sound.play_cue("load");say("窑工：放心，明早我上山，亲手交给老爷子。你收下这 5 枚运费。",4.5);return
	if transfer_left>0.:return
	if harbor_bell and stage=="sail" and works==0 and port==3 and absf(speed)<2.6 and grain_status!=1 and not worker_aboard and not bread_loaded and not fruit_reserved and not seats.any(func(id): return STOPS[id]==3):
		if not lamp_offer:
			lamp_offer=true;say("窑工：木阶上黑，昨晚我险些踩空。这盏灯烧好了，能替我带回去吗？",6.);return
		if kiln_talk<.95:return
		change_works(1)

	if stage=="sail" and fruit_reserved and port==3 and absf(speed)<2.7:
		fruit_reserved=false;fruit_sold_before=true;fruit_crate.hide();fruit_display.show()
		fruit_signed.emit();sound.play_cue("load");say("窑工分到月桂园的柑橘 · 果箱捎货 +6 枚",3.);return
	if stage=="sail" and tow_use():return
	if stage=="sail" and pos.distance_to(BERTH)<5.2 and works>=2:
		if absf(speed)>2.7:say("收桨后再系缆");return
		if works==3:
			if worker_aboard:
				var first_home:=not worker_signed
				worker_aboard=false;worker_signed=true;paid_crossings+=1;quay.seat_regular();quay.local_worker.hide();walking_home=true;begin_transfer(worker,worker.global_position);launch_lighter();worker_home.emit();chord.play()
				if fare_scene:fare_scene.begin(true,first_home)
				say("窑工：这回看得清台阶了。给，今晚的船钱，8 枚。",3.4);return
			if not seats.is_empty():say("先送船上乘客下船，再从木阶换班");return
			if bread_loaded:say("双灯窑还等着船上的面包");return
			if delivered()>=3:finish()
			change_shift.emit();return
		speed=0;stage="winch";freight=lantern_crate
		rig=preload("res://quay_crane.gd").new();add_child(rig)
		ropes.play();rig.begin(self,BERTH+Vector2(-.28,3.5),quay.lampholder.global_position.y);sound.play_cue("load");return
	if stage=="sail" and port==3 and works==1 and absf(speed)<=2.7:
		change_works(2);pots.clay.hide();lantern_crate.show();begin_transfer(lantern_crate,pots.tray.to_global(Vector3(0,.72,0)));fire_chime.play();say("窑工把陶灯装上了船。回蓝棚木阶，让伊娅点火。",4);return
	if stage=="sail" and works==3 and port==3 and absf(speed)<2.7 and not worker_aboard and seats.size()<2 and not bread_loaded:
		var dropping:=false
		for id in seats: dropping=dropping or STOPS[id]==3
		if not dropping and grain_status!=1:
			worker_aboard=true;worker.show();pots.buyer.hide();boarding_worker=true;begin_transfer(worker,pots.buyer.global_position);worker_boarded.emit();sound.play_cue("grab")
			if fare_scene:fare_scene.begin(false,not worker_signed)
			say("窑工：晚班收工了。劳驾，送我到亮灯的木阶。",3);return
	if worker_aboard and seats.size()==1 and port>=0 and STOPS[seats[0]]!=port and not (port==3 and bread_loaded):
		say("窑工占一席 · 先送船上乘客下船");return
	super()

func _unhandled_key_input(e:InputEvent)->void:
	if e is InputEventKey and e.pressed and not e.echo:
		if is_instance_valid(wishes) and wishes.reading:
			if e.keycode==KEY_ESCAPE:wishes.dismiss()
			elif e.keycode in [KEY_E,KEY_ENTER]:wishes.confirm()
			get_viewport().set_input_as_handled();return
		if harbour_charter.visible:
			if e.keycode in [KEY_ENTER,KEY_KP_ENTER]:request_mirror()
			elif e.keycode in [KEY_E,KEY_ESCAPE,KEY_Q]:harbour_charter.hide()
			get_viewport().set_input_as_handled();return
		if stage=="sail" and grain_status==2 and e.keycode==KEY_L and pos.distance_to(BERTH)<5.2 and absf(speed)<2. and seats.is_empty() and not bread_loaded:
			get_viewport().set_input_as_handled();day_shift.emit();return
		if e.keycode==KEY_ESCAPE and grain_status==1:save_tow()
		if stage=="sail" and works==3 and e.keycode==KEY_Q and pos.distance_to(BERTH)<5.2 and absf(speed)<2.7:
			harbour_charter.present(worker_signed,has_market,beacon_unlocked,grain_status==2,table_inn,table_crew);harbour_charter.fares(paid_crossings);harbour_charter.mirror_status(harbor_bell and worker_signed,mirror_built,available_funds);sound.play_cue("page")
			get_viewport().set_input_as_handled();return
	if stage in ["winch","lighting"]:
		if e is InputEventKey and e.pressed and not e.echo:
			if e.keycode==KEY_SPACE and stage=="winch":rig.release()
			elif e.keycode==KEY_ESCAPE:left_dock.emit(0)
			get_viewport().set_input_as_handled()
		return
	super(e)

func _physics_process(dt:float)->void:
	if is_instance_valid(wishes):
		wishes.tick(dt)
		if is_instance_valid(wishes) and wishes.reading:return
	if is_instance_valid(pilots) and not harbour_charter.visible:
		pilots.tick(dt,pos,works,cam.environment)
		pilots.swing_bell(bronze,dt)
		pilots.reflect_lights(design.water_mat)
	if port!=3 or absf(speed)>2.6:lamp_offer=false
	kiln_talk=move_toward(kiln_talk,1. if lamp_offer and works==0 else 0.,dt*1.8)
	if posted_age>=0.:posted_age+=dt
	if harbor_song and is_instance_valid(letter_writer) and pos.distance_to(BERTH)<10.:
		letter_face.perform(dt,waves,Vector2(-.18,-.03),.72,letter_motion>=0.)
	if letter_motion>=0.:
		letter_motion+=dt;var u:=clampf(letter_motion/.92,0.,1.)
		place_letter();letter_to=family_letter.global_position
		family_letter.global_position=letter_from.lerp(letter_to,smoothstep(0.,1.,u))+Vector3.UP*(sin(u*PI)*.72)
		if u>=1.:letter_motion=-1.
	if is_instance_valid(handover_fade):
		handover_time+=dt;handover_fade.modulate.a=1.-smoothstep(0.,.75,handover_time)
		if handover_time>.76:handover_fade.queue_free();handover_fade=null
	if harbor_bell and not bell_answered and pos.distance_to(BERTH)<22.:
		bell_answered=true;harbor_voice.play();say("白帆港的钟传过来了。两短一长，老渡工家船的号。" if harbor_song else "船夫：听，是你从山上送来的钟。它在替我们守夜。",4.)
	if harbour_charter.visible:
		mail_pin.hide()
		if is_instance_valid(ferry_guide):ferry_guide.hide()
		return
	if works==3 and not worker_aboard and pos.distance_to(PORTS[3])>13.:pots.buyer.show()
	pots.tick(waves,pos.distance_to(PORTS[3])<12.);move_transfer(dt)
	if first_passenger_waiting():
		if hailed_worker and (absf(speed)>=1. or chart.large):hail_age=maxf(hail_age,3.)
		if hail_age<.72 and hail_age+dt>=.72:
			pots.shore_answer.play()
			say("船夫：你看，窑工举灯了。他要搭末班船。",3.65)
		hail_age+=dt
	pots.ferry_signal(waves,hail_age,first_passenger_waiting())
	if stage not in ["winch","lighting"]:
		var previous:=pos
		super(dt)
		if mirror_built and is_instance_valid(pilots):
			var rock:Vector3=REEF_DATA[5]
			if pos.distance_to(Vector2(rock.x,rock.z))<22.:
				reveal[5]=maxf(reveal[5],.5);warning_rings[5].show()
			if mirror_age>=0.:mirror_age+=dt
			if mirror_age>=4.8:mirror_age=-1.
		if is_instance_valid(lighter):
			var forward:=Vector2.from_angle(heading)
			design.water_mat.set_shader_parameter("tug_trace",Vector4(pos.x,pos.y,heading,clampf(speed/5.,0.,1.)))
			design.water_mat.set_shader_parameter("cargo_trace",Vector4(lighter.location.x,lighter.location.y,lighter.yaw,clampf(lighter.velocity.length()/4.,0.,1.)))
			var old_grain:Vector2=lighter.location
			net_gate.tick(dt,pos,old_grain,grain_status==1,beacon_unlocked)
			pos=net_gate.clear_piers(pos)
			if grain_status==1 and net_gate.blocks(previous,pos):
				pos.y=previous.y;speed=move_toward(speed,0.,dt*38.)
				if net_gate.last_hit<=0.:say("渔网尚低 · 空格鸣螺，或走东侧白标",2.4);net_gate.last_hit=3.
			var struck:bool=lighter.tick(dt,pos-forward*2.65,forward,reefs,waves)
			if unload_age>=0.:
				unload_age+=dt;quay.unload_from(unload_age,lighter)
				if unload_age>5.75:unload_age=-1.
			if grain_status==1:
				if net_gate.blocks(old_grain,lighter.location):
					lighter.location.y=old_grain.y;lighter.velocity.y=0.
				lighter.location=net_gate.clear_piers(lighter.location)
				speed*=exp(-dt*(.14+.46*lighter.strain))
				if struck:sound.play_cue("bonk");say("驳船碰礁 · 先收桨，把船尾带离礁圈",2.5)
				if struck or pos.distance_to(last_tow_save)>7.:save_tow()
			tow_framing=move_toward(tow_framing,1. if grain_status==1 else 0.,dt*.75)
			if tow_framing>0.:
				var mid:Vector3=boat.position.lerp(lighter.hull.position,.42)+Vector3.UP*.75
				var back:=Vector3(-forward.x,0,-forward.y)
				var offset:=back*15.1+Vector3(back.z,0,-back.x)*5.8+Vector3.UP*10.3
				cam.position=cam.position.lerp(mid+offset,tow_framing);cam.look_at(cam_target.lerp(mid,tow_framing))
		if unload_age>=0. and absf(speed)<1.2 and pos.distance_to(BERTH)<5.4:
			var strength:=smoothstep(0.,1.2,unload_age)*(1.-smoothstep(4.25,5.65,unload_age))*.90
			var focus:=quay.global_position+Vector3(2.15,1.05,-1.15)
			var photograph:=Transform3D(Basis.looking_at(Vector3(-6.8,-5.2,4.7),Vector3.UP),focus+Vector3(6.8,5.2,-4.7))
			cam.transform=cam.transform.interpolate_with(photograph,strength)
		if bell_boarding and harbor_song and letter_stage==0 and pos.distance_to(BERTH)<5.2 and absf(speed)<.8 and grain_status!=1 and not worker_aboard and works!=2:
			letter_intro+=dt
			var mix_in:=smoothstep(0.,.55,letter_intro)*(1.-smoothstep(2.25,3.75,letter_intro))
			var speaker:=letter_writer.global_position+Vector3.UP*1.12
			var off:=Vector3(-1.65,1.65,-4.06)
			cam.global_transform=cam.global_transform.interpolate_with(Transform3D(Basis.looking_at(-off,Vector3.UP),speaker+off),mix_in)
		if bell_boarding and not harbor_song and works==0 and not used_echo:
			first_look+=dt
			if absf(speed)>.6:first_look=maxf(first_look,4.)
			var intro_weight:=smoothstep(0.,.5,first_look)*(1.-smoothstep(2.35,3.55,first_look))
			cam.global_transform=cam.global_transform.interpolate_with(quay_view(),intro_weight)
		for sign_tile:Sprite3D in tile_signs:sign_tile.visible=kiln_talk<.12 and intro_finished() and not watching_kiln()
		if kiln_talk>.01:port_names[3].hide()
		if kiln_talk>.005:
			var lamp_spot:Vector3=pots.tray.global_position.lerp(pots.potter.global_position,.74)+Vector3.UP*1.06
			var offset:Vector3=docks[3].global_basis*Vector3(-1.65,1.18,2.72)
			cam.global_transform=cam.global_transform.interpolate_with(Transform3D(Basis.looking_at(-offset,Vector3.UP),lamp_spot+offset),smoothstep(0.,1.,kiln_talk))
		if mirror_age>=0. and absf(speed)<1.:
			var focus:Vector3=pilots.reflector.global_position.lerp(Vector3(REEF_DATA[5].x,.3,REEF_DATA[5].z),smoothstep(1.25,2.68,mirror_age)*.67)
			var off:=Vector3(4.25,2.85,-4.82)
			var blend:=smoothstep(0.,.45,mirror_age)*(1.-smoothstep(3.45,4.78,mirror_age))
			cam.global_transform=cam.global_transform.interpolate_with(Transform3D(Basis.looking_at(-off,Vector3.UP),focus+off),blend)
		if watching_kiln():
			var boatman:Vector3=pots.buyer.global_position+Vector3.UP*.95
			var eye:Vector3=boatman+pots.global_basis*Vector3(-2.8,.80,1.65)
			var response:=Transform3D(Basis.looking_at(boatman-eye,Vector3.UP),eye)
			cam.global_transform=response
			chart.hide();port_names[3].hide()
		var waiting_for_letter:=bell_boarding and harbor_song and letter_stage==0
		looking_at_steps=harbor_bell and works in [0,1,2] and seats.is_empty() and not bread_loaded and not fruit_reserved and grain_status==0 and not waiting_for_letter and letter_motion<0. and pos.distance_to(BERTH)<8. and absf(speed)<1.8 and not chart.large and (works==2 or message_left<=0.)
		if looking_at_steps:
			stair_look+=dt
			var gesture:=sin(PI*clampf((stair_look-.3)/2.,0.,1.))
			quay.stair_pose(0.,gesture)
			var framing:=smoothstep(.0,.5,stair_look)*(1.-smoothstep(2.1,2.9,stair_look))
			cam.global_transform=cam.global_transform.interpolate_with(stair_view(),framing)
		if fare_scene:fare_scene.tick(dt)
		update_story_pin()
		if works==3 and pos.distance_to(BERTH)<21 and not voices.playing:voices.play()
		if stage=="sail" and pos.x>BERTH.x-4.8 and pos.x<BERTH.x+4.8 and pos.y>BERTH.y+.78 and pos.y<BERTH.y+6.1:
			pos.y=BERTH.y+.78;speed=move_toward(speed,0.,dt*15)
		return
	mail_pin.hide()
	var at:=quay.global_position+Vector3(0,1,0)
	var offset:=Vector3(-5.,6.0,-8.)
	marker.visible=false
	if stage=="winch":cam.transform=cam.transform.interpolate_with(Transform3D(Basis.looking_at(-offset,Vector3.UP),at+offset),1.-exp(-3.8*dt))
	if stage=="winch":
		if rig.tick(dt,float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))):
			if rig.alignment>1.22:
				rig.queue_free();marker.show();stage="sail";freight.reparent(boat,false);freight.position=Vector3(-.82,.76,-.49);say("灯座未对准 · E 重新挂索");return
			transfer_start=freight.global_position
			rig.queue_free();ceremony=0;stage="lighting";change_works(3);chord.play()
			pier_fade=ColorRect.new();hud.add_child(pier_fade)
			pier_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			pier_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE; pier_fade.color=Color("#182a32");pier_fade.modulate.a=0.
	else:
		ceremony+=dt;quay.animate(ceremony)
		if ceremony<.68:
			quay.lampholder.hide()
			freight.global_position=transfer_start.lerp(quay.lampholder.global_position,smoothstep(.0,.60,ceremony))
			freight.rotation=freight.rotation.lerp(Vector3.ZERO,1.-exp(-dt*10.))
		else:freight.hide()
		var wick:=quay.lights[0].global_position
		if ceremony<1.90:
			var eye:=Vector3(-2.25,.65,.47)
			cam.global_transform=Transform3D(Basis.looking_at(-eye,Vector3.UP),wick+eye)
		elif ceremony<4.82:
			var focus:=quay.to_global(Vector3(.48,1.50,.59))
			var eye:=Vector3(-4.30,3.40,-8.5)*(1.+.055*smoothstep(1.9,4.4,ceremony))
			cam.global_transform=Transform3D(Basis.looking_at(-eye,Vector3.UP),focus+eye)
		else:
			cam.global_transform=stair_view()
		pier_fade.modulate.a=smoothstep(quay.END_OF_SHIFT-.35,quay.END_OF_SHIFT,ceremony)
		if lit_count<3 and ceremony>=1.25+.64*lit_count:
			fire_chime.pitch_scale=[.82,1.0,1.23][lit_count];fire_chime.play();lit_count+=1
		if ceremony>3.4 and not voices.playing:voices.play()
		if ceremony>=quay.END_OF_SHIFT:
			quay.plaque.show();pots.buyer.show();marker.show();stage="sail"
			var opening:=create_tween()
			opening.tween_property(pier_fade,"modulate:a",0.,.38).set_trans(Tween.TRANS_SINE)
			opening.tween_callback(pier_fade.queue_free)
			say("船夫：「以后认这三盏灯靠岸。」",3.)
	ui_update()

func ui_update()->void:
	super()
	if harbor_song and stage=="sail":
		if letter_stage==1:deck.text+="　·　家书 → 双灯窑"
		if message_left<=0. and ((letter_stage==0 and pos.distance_to(BERTH)<5.2) or (letter_stage==1 and port==3)):
			action.text="E 捎上老渡工家的回信" if letter_stage==0 else "E 把回信交给双灯窑的窑工";action.show();action.reset_size();action.position.x=(1280-action.size.x)/2
	if not is_instance_valid(marker):return
	if stage in ["winch","lighting"]:
		title.text="蓝棚木阶　/　"+("安装陶灯" if stage=="winch" else "第一盏晚灯")
		guide.hide();deck.hide();chart.hide();task.show();action.show()
		task.text="A D 移吊车　·　空格脱钩" if stage=="winch" else "伊娅从炉膛取火，船夫沿木阶传灯"
		action.text=rig.hint if stage=="winch" else "";action.visible=stage=="winch"
		if stage=="lighting":task.hide();title.hide();quay.plaque.hide()
	elif stage=="sail":
		title.text="卡戎的夜班　/　冥河渡客"
		if worker_aboard:deck.text="船上　晚班窑工 → 蓝棚木阶"+("　·　"+GUESTS[seats[0]] if not seats.is_empty() else "　·　空座一席")
		if works==3 and port==3 and not worker_aboard and message_left<=0 and seats.size()<2:action.show();action.text="E　靠岸接送晚班窑工"
		if works==3 and not worker_signed and not worker_aboard:task.text="木阶已通航　·　窑工在双灯窑等末班船"
		if works==1:task.text+="　·　东岸双灯窑取灯"
		if works==2:task.text+="　·　蓝棚木阶 %d 米"%roundi(pos.distance_to(BERTH));deck.text+="　陶灯 → 蓝棚"
		if works>=2 and pos.distance_to(BERTH)<5.2 and message_left<=0:
			action.show();action.text="E　系缆安装陶灯" if works==2 else ("E　窑工下船赶夜市" if worker_aboard else "E　靠岸换公路班　 Q 读共建铭")

		if lighter!=null and grain_status==0 and worker_signed:
			task.text="外港红白麦旗　·　距粮驳 %d 米"%roundi(pos.distance_to(lighter.location))
			if pos.distance_to(lighter.location)<6.2 and message_left<=0:action.show();action.text="E　系缆，领粮驳进港"
		elif grain_status==1:
			task.text="首班粮驳　/　蓝棚木阶 %d 米"%roundi(pos.distance_to(BERTH))
			if pos.distance_to(net_gate.Gate)<15. and pos.y<net_gate.Gate.y+1.:task.text="旧汊网门　·　"+("灯塔已示意提网" if beacon_unlocked else "鸣螺请提网，或绕东侧白标")
			deck.text="船尾　"+(["粮袋完好","一袋擦损","两袋擦损","三袋擦损"][clampi(lighter.impacts,0,3)])+("　·　磨坊联运" if mill_trade else "")
			if pos.distance_to(BERTH)<5.2 and message_left<=0:action.show();action.text="E　递缆卸粮"
		if grain_status==2 and pos.distance_to(BERTH)<6. and seats.is_empty() and not bread_loaded:
			task.text="木阶已系缆 · L 去船坞分早饭" if not (table_inn and table_crew) else "蓝棚木阶 · 谷神长桌已开席"
		if grain_status==2 and pos.distance_to(BERTH)<5.2 and message_left<=0 and seats.is_empty() and not bread_loaded:
			action.show();action.text="E 走东岸公路　 L 上岸到晨班　 Q 读共建铭"
	if stage=="sail" and fruit_reserved:
		deck.text+="　·　鲜果 → 双灯窑"
		if port==3 and message_left<=0.:action.show();action.text="E 给窑工卸果箱　+6 枚"
	if bell_boarding and stage=="sail" and harbor_song and letter_stage<2 and grain_status!=1 and not worker_aboard and works!=2:
		task.text="替祖孙捎一封平安信" if letter_stage==0 else "把信交给东岸双灯窑的窑工"
		if not chart.large:
			guide.text="W S  划船 / 倒船　　A D  掌舵　　Tab  航图"
			deck.visible=letter_stage==1
		if letter_stage==1 and message_left<=0. and port!=3:action.hide()
		if message_left<=0. and letter_stage==0 and pos.distance_to(BERTH)<5.2 and absf(speed)<2.6:action.text="渡工女儿举起了信　·　E 接过回信";action.show()
		elif message_left<=0. and letter_stage==1 and port==3 and absf(speed)<2.6:action.text="窑工等着收信　·　E 递进上山邮袋";action.show()
	if posted_age>=0. and posted_age<5.5 and stage=="sail":
		task.text="家书已收进明早上山的邮袋";deck.text="捎信运费  +5 枚"
	elif posted_age>=5.5 and stage=="sail":
		guide.text="W S 划船 / 倒船　 A D 掌舵　 空格 鸣螺探浅　 E 停靠　 Q 选乘客　 Tab 航图　 Esc 返回"
	action.reset_size();action.position.x=(1280-action.size.x)/2

	if harbor_bell and stage=="sail" and not chart.large and not harbour_charter.visible and grain_status!=1:
		var has_letter:=harbor_song and letter_stage<2 and bell_boarding
		if posted_age>=0. and posted_age<5.5:task.text="信已进邮袋。明早，爷爷就知道红帆到家了。"
		elif works==0 and not has_letter and not worker_aboard and seats.is_empty() and not bread_loaded and not fruit_reserved:
			task.text="顺路去双灯窑，问问窑工缺什么。"
			if port==3 and absf(speed)<2.6 and (message_left<=0. or lamp_offer):
				action.text="E  答应带灯　·　也可以直接开船离开" if lamp_offer else "E  和窑工说话"
				if lamp_offer:
					task.text="窑工：木阶上黑，昨晚我险些踩空。能把这盏灯带回去吗？"
					if kiln_talk<.95:action.text=""
				action.show()
		if works==2:
			task.text="把陶灯运回蓝棚木阶"
			if message_left<=0. and pos.distance_to(BERTH)>5.2:
				action.text="空格  鸣螺，听港钟引路";action.visible=pulse_charge>=.99 and pilots.wave<0.
		if works==3 and not worker_aboard and port==3 and not bread_loaded and seats.is_empty() and grain_status!=1 and message_left<=0.:
			action.text="E  接窑工回蓝棚木阶　·　8 枚";action.show()
		if works==3 and worker_aboard:task.text="把晚班窑工送到亮灯的木阶　·　船资 8 枚"
		action.reset_size();action.position.x=(1280-action.size.x)/2

	if stage=="sail":title.show()
	if is_instance_valid(ferry_guide):
		ferry_guide.update_view()
		if stage=="lighting":ferry_guide.hide()
	if watching_steps():
		title.hide();guide.hide();deck.hide();chart.hide();task.hide();action.hide();mail_pin.hide()
		if is_instance_valid(ferry_guide):ferry_guide.hide()

	if is_instance_valid(wishes) and wishes.near_boat():
		action.text="E　读一读居民留下的纸条";action.show();action.reset_size();action.position.x=(1280-action.size.x)*.5
		if is_instance_valid(ferry_guide):ferry_guide.hide()

func watching_kiln()->bool:
	return hailed_worker and hail_age>=.72 and hail_age<2.75 and first_passenger_waiting() and absf(speed)<1. and not chart.large and pos.distance_to(BERTH)<9.

func watching_steps()->bool:
	return stage=="sail" and looking_at_steps and stair_look>.32 and stair_look<2.45

func intro_finished()->bool:
	return first_look<.05 or first_look>3.1

func update_story_pin()->void:
	mail_pin.hide()
	if watching_steps() or watching_kiln() or not harbor_bell or stage!="sail" or chart.large or harbour_charter.visible or grain_status==1:return
	if kiln_talk>.12 or not intro_finished():return
	if not seats.is_empty() or bread_loaded or fruit_reserved:return
	var slow:=absf(speed)<2.6
	var quay_range:=pos.distance_to(BERTH)<5.2
	var kiln_range:=port==3
	mail_pin.beside=false
	if first_passenger_waiting() and not kiln_range and not hailed_worker:return
	if worker_aboard or works==2:
		if works==2 and pilots.wave>=0. and not quay_range:return
		mail_pin.target=quay.to_global(Vector3(.35,1.1,-.65))
		mail_pin.words=("E  送窑工上岸" if worker_aboard else "E  系缆挂灯") if slow and quay_range else "蓝棚木阶"
	elif harbor_song and letter_stage<2 and bell_boarding:
		mail_pin.target=family_letter.global_position+Vector3.UP*.10 if letter_stage==0 else postal_sack.global_position+Vector3.UP*.42
		mail_pin.beside=letter_stage==0 and quay_range
		mail_pin.words=("E  接过家书" if slow and quay_range else "蓝棚木阶") if letter_stage==0 else ("E  投进邮袋" if slow and kiln_range else "双灯窑  ·  送信")
	elif works<3 or not worker_signed:
		var person:Node3D=pots.buyer if works==3 else pots.potter
		mail_pin.target=person.global_position+Vector3.UP*1.2
		mail_pin.beside=kiln_range
		mail_pin.words=("E  接窑工" if works==3 else ("E  接过陶灯" if works==1 else "E  和窑工说话")) if slow and kiln_range else "双灯窑"
	else:return
	mail_pin.follow_camera=cam;mail_pin.show();mail_pin.queue_redraw()


func request_mirror()->void:
	if mirror_built or not harbor_bell or not worker_signed or not harbour_charter.visible:return
	if available_funds>=6:mirror_order.emit()

func fit_mirror(balance:int)->void:
	mirror_built=true;available_funds=balance;mirror_age=0.
	pilots.mount_mirror(quay);harbour_charter.hide()
	fire_chime.play();say("船夫：镜子对准了。你看，外弯那块暗礁亮起来了。",4.8)


func stair_view()->Transform3D:
	var focus:=quay.to_global(Vector3(1.06,1.08,2.13))
	var eye:=Vector3(-1.9,1.46,3.05)
	return Transform3D(Basis.looking_at(-eye,Vector3.UP),focus+eye)

func quay_view()->Transform3D:
	var focus:=quay.to_global(Vector3(.48,1.50,.59))
	var off:=Vector3(-2.84,2.10,-9.45)
	return Transform3D(Basis.looking_at(-off,Vector3.UP),focus+off)


func current_exposure(point:Vector2)->float:
	return minf(super(point),smoothstep(3.8,7.4,point.distance_to(BERTH)))
