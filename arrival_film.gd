extends CanvasLayer

const Fonts=preload("res://harbour_fonts.gd")
var host:Node3D
var camera:Camera3D
var original:Transform3D
var previous_mode:Node.ProcessMode
var layers:Array[CanvasLayer]=[]
var signs:Array[Label3D]=[]
var beats:Array
var index:=0
var age:=0.
var subtitle:=Label.new()
var prompt:=Label.new()
var curtain:=ColorRect.new()
var gesture:Node3D
var rest:=Vector3.ZERO
var prop:Node3D
var prop_rest:Transform3D
var leaving:=false
var exit_age:=0.
var setting:=""
var elapsed:=0.
var last_accept:=-2.
var foley:=AudioStreamPlayer.new()
var cue_fired:=false
var returned:=false

static func play(world:Node3D,key:String,view:Camera3D,shots:Array)->bool:
	var seen:Dictionary=world.get_meta("arrival_history",{})
	if seen.has(key) or world.has_node("ArrivalFilm"):return false
	seen[key]=true;world.set_meta("arrival_history",seen)
	var film=new()
	film.setting=key;film.name="ArrivalFilm";film.host=world;film.camera=view;film.beats=shots
	world.add_child(film)
	return true

func _ready()->void:
	layer=90;process_mode=Node.PROCESS_MODE_ALWAYS
	add_child(foley);foley.volume_db=-15.
	original=camera.global_transform
	previous_mode=host.process_mode
	for child in host.find_children("*","CanvasLayer",true,false):
		if child!=self and child.visible:layers.append(child);child.hide()
	for sign_node:Label3D in host.find_children("*","Label3D",true,false):
		if sign_node.is_visible_in_tree():signs.append(sign_node);sign_node.hide()
	host.process_mode=Node.PROCESS_MODE_DISABLED
	for edge in [0.,1.]:
		var bar:=ColorRect.new();add_child(bar);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		bar.color=Color("#11191b");bar.anchor_top=edge;bar.anchor_bottom=edge;bar.anchor_right=1.
		bar.offset_top=-105. if edge else 0.;bar.offset_bottom=0. if edge else 42.
	for item in [subtitle,prompt]:
		add_child(item);item.anchor_top=1.;item.anchor_bottom=1.;item.anchor_right=1.
		item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		item.add_theme_font_override("font",Fonts.body());item.mouse_filter=Control.MOUSE_FILTER_IGNORE
	subtitle.offset_top=-92.;subtitle.offset_bottom=-52.;subtitle.add_theme_font_size_override("font_size",24)
	prompt.offset_top=-47.;prompt.offset_bottom=-8.;prompt.add_theme_font_size_override("font_size",16);prompt.modulate=Color("#cfbea0")
	add_child(curtain);curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);curtain.mouse_filter=Control.MOUSE_FILTER_IGNORE
	curtain.color=Color("#101719")
	begin_shot()

func reset_cast()->void:
	if gesture:gesture.rotation=rest
	if prop:prop.transform=prop_rest

func begin_shot()->void:
	reset_cast()
	prop=null
	if beats[index].size()>5:
		prop=beats[index][5]
		prop_rest=prop.transform
	var actor:Node3D=beats[index][0]
	gesture=actor.get_node_or_null("ArmR");age=0.;cue_fired=false
	if gesture:rest=gesture.rotation
	subtitle.text=beats[index][3];prompt.text="Esc　略过这段" if index==0 else ""
	frame_shot()

func frame_shot()->void:
	var beat:Array=beats[index]
	var focus:Vector3=beat[0].global_position+Vector3.UP*float(beat[1])
	var approach:=smoothstep(0.,3.8,age)
	camera.global_position=focus+Vector3(beat[2])*(1.-.075*approach)
	camera.look_at(focus)
	if gesture:gesture.rotation.x=rest.x-.65*sin(PI*approach)
	if prop:
		var motion:String=beats[index][6]
		prop.transform=prop_rest
		match motion:
			"stall":prop.rotation.x+=.38*sin(age*4.)*exp(-age*1.5)
			"shunt":prop.position.x+=.5*smoothstep(.3,1.25,age)-.16*smoothstep(1.25,1.55,age)
			"rock":prop.rotation.z+=.035*sin(age*2.)
			"beacon":prop.rotation.y+=age*.51
			"breathe":prop.scale=prop_rest.basis.get_scale()*(1.+.075*sin(PI*approach))

func _process(dt:float)->void:
	if leaving:
		exit_age+=dt
		if not returned and exit_age>=.24:
			returned=true;reset_cast();camera.global_transform=original
			for item in get_children():
				if item is Control and item!=curtain:item.hide()
			for l in layers:l.show()
			for s in signs:s.show()
		curtain.modulate.a=1.-smoothstep(.24,.65,exit_age) if returned else smoothstep(0.,.24,exit_age)
		if exit_age>=.65:
			host.process_mode=previous_mode
			hide();set_process(false);set_process_input(false);queue_free()
		return
	elapsed+=dt;age+=dt;frame_shot()
	if not cue_fired and age>=1.2:
		cue_fired=true
		var cue:String={"lens1":"buckle","mill0":"wind","stove1":"zephyr_oven","letter0":"letter_fold","grain0":"blue_quay_rope","ferry0":"styx_chord","breakfast0":"quay_feast","deep0":"styx_depth","optics0":"clay_answer","lantern0":"blue_quay_clay"}.get(setting+str(index),"")
		if not cue.is_empty():
			foley.stream=load("res://audio/"+cue+".wav");foley.play()
	curtain.modulate.a=(1.-smoothstep(0.,.28,age)) if index==0 else 0.
	if index+1<beats.size() and age>=4.2:index+=1;begin_shot()
	elif index+1==beats.size() and age>=1.2:prompt.text="E　"+str(beats[index][4])

func _input(event:InputEvent)->void:
	if event is InputEventKey or event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		if leaving or not event is InputEventKey or not event.pressed or event.echo:return
		if event.keycode==KEY_ESCAPE:leaving=true
		if event.keycode==KEY_E:
			var deliberate:=elapsed-last_accept>.5
			last_accept=elapsed
			if deliberate and index+1==beats.size() and age>=1.2:leaving=true

static func mill(j)->void:
	var close:=Vector3(2.9,1.3,3.8)
	if j.has_method("build_berth"):
		play(j,"stove",j.cam,[
			[j.dock_basket,.1,Vector3(-4.5,2.,4.).rotated(Vector3.UP,TAU*5./6.),"蓝棚的晚班快开工了，灶台还冷着。"],
			[j.freight,.66,Vector3(-2.1,1.35,3.),"伊娅：这炉膛里还有火。现在走，赶得上他们开饭。"],
			[j.land.apprentice,1.18,close,"伊娅：搭把手？先把炉子从门里抬出去。","走到炉边"]])
	else:
		play(j,"mill",j.cam,[
			[j.land.blades,.0,Vector3(-10,2.4,13),"山顶的磨坊。风叶动了一下，又停住了。" if j.prior_level==0 else "磨坊主又在等西湾的风。","",j.land.blades,"stall"],
			[j.freight,.68,Vector3(-2.4,1.25,3.3),"米拉：山脚有风。我才把袋口撑开，它就鼓起来了。","",j.freight,"breathe"],
			[j.land.apprentice,1.12,close,"米拉：你经过风口时，再替我兜上一袋，好吗？","看看风囊"]])

static func dock(j)->void:
	if j.blue_focus:
		var point:Node3D=j.community.basket if j.community and j.meal_stock>0 else j.courier
		var loaf:bool=j.community!=null and j.meal_stock>0
		play(j,"breakfast" if loaf else "quay",j.cam,[
			[point,.7,Vector3(-4.5,3.4,6.).rotated(Vector3.UP,PI),"昨夜运来的粮，今天烤成了第一篮面包。" if loaf else "船快开了，木阶边还有人等着。"],
			[j.courier,.95,Vector3(2.8,2.2,4.9),"客舍和工班都等着吃早饭。先给哪桌送去？" if loaf else "到临水木台去，听听街坊怎么说。","走向木台"]])
	else:
		play(j,"lens",j.cam,[
			[j.design.tower_beacon,.0,Vector3(-14,5,17),"守塔人：入夜前，北岬得亮起来。"],
			[j.jewel,.45,Vector3(2.6,1.8,4.),"船夫：再推……不行，镜车被栏杆挡住了。","",j.lens_cart,"shunt"],
			[j.weight_cart,.48,Vector3(3.4,3.6,5.1),"船夫：看那只铁配重。你推，我在船边接。","进仓帮忙"]])

static func night(j)->void:
	if j.quay_welcome!="" and j.beacon_unlocked:
		play(j,"north_lit",j.cam,[
			[j.traffic.light_root,0.,Vector3(7.,1.9,10.5),j.quay_welcome,"",j.traffic.light_root,"beacon"],
			[j.boat,.8,Vector3(2.4,1.6,-5.8),"船夫：我认得这道光了。以后起雾也能从北岬进港。","回到舵边"]])
		return
	var subject:Node3D=j.guests[0]
	var line:="渡客：还有位子吗？我一直等到天黑。"
	var answer:="船夫：靠近岸边，问清他想去哪一站。"
	var key:="ferry"
	if j.grain_status==1 or (j.lighter and j.worker_signed and j.grain_status==0):
		subject=j.lighter.hull;line="这艘驳船吃水深，满船麦子等着进港。";answer="船夫：过窄口得替船尾也留个弯。";key="grain"
	elif j.worker_aboard or (j.works==3 and not j.worker_signed):
		subject=j.worker if j.worker_aboard else j.pots.buyer;line="窑工：炉子总算可以封了。末班船还在吗？";answer="蓝棚的木阶亮着灯。窑工今晚想从那儿上岸。";key="worker"
	elif j.harbor_song and j.letter_stage<2 and j.bell_boarding:
		subject=j.letter_writer if j.letter_stage==0 else j.family_letter;line="女孩：爷爷只听见了船号，还不知道爸爸回家了。";answer="这封信要上山。双灯窑有人明早顺路。";key="letter"
	elif j.works in [1,2] or (j.harbor_bell and j.works==0 and not j.bread_loaded and not j.fruit_reserved):
		subject=j.lantern_crate if j.works==2 else j.pots.potter
		line="窑工：昨晚下船，一脚就踩进水里了。";answer="把船上的陶灯带回木阶吧。" if j.works==2 else "东岸窑口还亮着火，去听听窑工的主意。";key="lantern"
	elif j.bread_loaded or j.fruit_reserved:
		subject=j.fruit_crate if j.fruit_reserved else j.boat;line="双灯窑的炉火还亮着，窑工正等这趟捎货。";answer="把船靠到东岸，让晚班的人接货。";key="night_freight"
	var eye:=Vector3(-3.25,1.6,4.25)
	if key=="letter":eye=eye.rotated(Vector3.UP,PI)*.65
	play(j,key,j.cam,[[subject,1.12 if key=="letter" and j.letter_stage==0 else .65,eye,line],[j.boat,1.,Vector3(3.,2.8,-6.2),answer,"接过船桨",j.boat,"rock"]])
	if is_instance_valid(j.handover_fade):j.handover_fade.hide()
	j.first_look=4.

static func spring_route(g)->void:
	var s=g.spring
	if s.step==4:
		play(g,"orchard",g.cam,[[s.garden_worker,1.15,Vector3(3.6,1.65,4.2),"园工：这批果子，是通水以后才结的。"],[g.truck,1.,Vector3(4.,2.7,6.),"客舍近，海港远。你想让哪一边先尝到？","回到车旁"]])
	elif s.step==0:
		play(g,"canal",g.cam,[[s.garden_worker,1.05,Vector3(3.4,1.6,4.2).rotated(Vector3.UP,PI/3),"园工：水渠都见底了。这些树可等不到下场雨。"],[s.wheel,1.,Vector3(5.,3.7,-7.),"渠首的水轮停了，中间空着一个轴位。"],[s.loading_part,.35,Vector3(2.7,1.5,3.8).rotated(Vector3.UP,-PI/3),"渠匠：新轮毂到了。送上山去，我们就能开闸。","去接轮毂"]])

	else:
		var part:Node3D=s.wheel if s.step<3 else s.garden_worker
		var words:=["","把轮毂送到连拱下的水轮。","轮毂就位了。渠匠在等你试闸。","水已到渠尾。园工正等你开最后一道闸。"]
		play(g,"canal_resume_"+str(s.step),g.cam,[[part,1.,Vector3(4.,2.4,6.),words[s.step]],[g.truck,1.,Vector3(4.,2.,5.),"沿着水渠过去，就能接着干了。","继续这一程"]])
