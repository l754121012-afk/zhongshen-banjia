extends Node3D

signal signed(id:int)
const F=preload("res://harbour_fonts.gd")
const NOTES={
	1:["灯匠的手印","借我一面能照进雾里的镜子","昨夜听见了港钟，船却还是看不见礁石。\n镜片在船坞。你能把它送上北岬吗？","北岬灯匠","点亮航标，夜船就能认出北岬。","#88c7bc"],
	3:["磨坊里夹来的麦穗","风神把磨坊的风也带走了","我等了一整夜，磨盘一寸都没转。\n山脚的风口还有风，装进风囊带来吧。","磨坊主米拉","磨盘转起来，港里才有第一炉面包。","#b6bf75"],
	0:["一枚染红的软木塞","神庙的酒杯还空着","他们说酒神搬走了，今夜的宴席要散。\n地窖里还有最后两坛。车尾靠过来，我帮你抬。","山脚酒农","把酒送上祭台，领这一趟的运费。","#cf9589"],
	6:["晒白的柑橘叶","泉眼还在，水却去了哪里？","我挖开树根，连泥都是干的。\n顺着旧水道过来吧。我带你看它断在哪儿。","月桂园的果农","引水入园，等青果长成一船柑橘。","#95ba86"],
	4:["一角烤焦的油纸","我想把炉火留在蓝窗下","山上磨出了面粉，孩子们还是要走很远才买得到面包。\n能帮我搬一次炉子吗？小心，里面还有火。","面包师伊娅","炉子安顿后，蓝窗可以给港口供货。","#deaa73"]
}
const LANDING:=Vector2(-14.5,23.5)
var id:=-1
var art:=preload("res://workshop.gd").new()
var sheet:Node3D
var badge:MeshInstance3D
var signpost:Label3D
var layer:=CanvasLayer.new()
var panel:=Control.new()
var title:=Label.new()
var line:=Label.new()
var maker:=Label.new()
var reward:=Label.new()
var accept:=Button.new()
var back:=Button.new()
var reading:=false
var age:=0.
var job
var camera_start:Transform3D
var camera_fov:=64.
var phase:=0.

func build(owner_job,offer:int,known:int)->void:
	job=owner_job;id=offer;position=Vector3(LANDING.x,.05,LANDING.y+2.65)
	for i in 10:art.box(self,Vector3((i-4.5)*.58,.11,0),Vector3(.55,.23,2.65),"#827158" if i%2==0 else "#766248")
	for x in [-2.52,2.52]:
		for z in [-.92,.92]:art.cyl(self,Vector3(x,-.6,z),.14,.18,1.8,"#5b493c")
	for x in [-1.12,1.12]:art.box(self,Vector3(x,1.65,.44),Vector3(.16,3.15,.2),"#614c37")
	art.box(self,Vector3(0,2.26,.43),Vector3(2.56,1.64,.17),"#4c554c")
	art.box(self,Vector3(0,3.14,.34),Vector3(2.95,.20,.6),"#786448")
	art.box(self,Vector3(0,1.45,.32),Vector3(2.76,.13,.34),"#a98b62")
	for i in 3:
		var scrap:=art.box(self,Vector3(-.88+i*.77,2.11,.31),Vector3(.49,.54,.022),"#a99979")
		scrap.rotation.z=(i-1)*.09
	sheet=art.group(self,Vector3(.04,2.33,.27))
	art.box(sheet,Vector3.ZERO,Vector3(.9,1.08,.035),"#f4deb2")
	badge=art.ball(sheet,Vector3(0,.4,-.044),Vector3(.14,.15,.06),NOTES[id][5] if NOTES.has(id) else "#927653")
	for i in 4:art.box(sheet,Vector3(-.04, .17-i*.12,-.028),Vector3(.51 if i<3 else .28,.018,.02),"#826a4f")
	signpost=job.design.label(self,Vector3(0,3.68,0),"居民心愿",job.face,"#f9e3ae");signpost.pixel_size=.008
	var glow:=OmniLight3D.new();add_child(glow);glow.position=Vector3(.0,2.85,-.72);glow.light_color=Color("#ffd295");glow.light_energy=1.5;glow.omni_range=5.
	# Clay seals remain tied to the rail after a resident has entrusted a job.
	var rack:=art.group(self,Vector3(-1.02,1.46,-.03))
	var rank:=0
	for n:int in [1,3,0,6,4]:
		if (known & (1<<n))==0:continue
		var seal:=art.group(rack,Vector3(rank*.47,0,0))
		art.beam(seal,Vector3.ZERO,Vector3(.02,-.29,-.04),.014,"#d2b486")
		var disk:=art.cyl(seal,Vector3(.02,-.34,-.05),.135,.135,.044,NOTES[n][5],16)
		disk.rotation.x=PI/2;rank+=1
	sheet.visible=NOTES.has(id);add_child(layer);layer.layer=18;layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var shade:=ColorRect.new();panel.add_child(shade);shade.color=Color("#101d2533");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper:=Panel.new();panel.add_child(paper);paper.position=Vector2(634,102);paper.size=Vector2(572,504)
	var style:=StyleBoxFlat.new();style.bg_color=Color("#eee0bf");style.shadow_size=10;style.shadow_color=Color("#07111869");style.border_width_top=6;style.border_color=Color("#9d7451");paper.add_theme_stylebox_override("panel",style)
	text_at(paper,maker,Vector2(33,37),17,"#68523d")
	text_at(paper,title,Vector2(30,91),32,"#333b36",true)
	text_at(paper,line,Vector2(34,165),21,"#43443a")
	line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.size=Vector2(504,122)
	text_at(paper,reward,Vector2(34,317),19,"#496254")
	for b in [accept,back]:
		paper.add_child(b);b.add_theme_font_override("font",F.body());b.add_theme_font_size_override("font_size",19)
		b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		for state in ["normal","focus","hover","pressed"]:
			var box:=StyleBoxFlat.new();box.bg_color=Color("#33564e" if state=="normal" else "#527666");box.set_corner_radius_all(3);b.add_theme_stylebox_override(state,box)
	accept.position=Vector2(32,402);accept.size=Vector2(275,60);accept.text="接下这份托付　E";accept.pressed.connect(confirm)
	back.position=Vector2(326,402);back.size=Vector2(209,60);back.text="先放回去　Esc";back.pressed.connect(dismiss)
	panel.hide()

func text_at(parent:Control,label:Label,at:Vector2,sz:int,color:String,serif:=false)->void:
	parent.add_child(label);label.position=at;label.add_theme_font_override("font",F.headings() if serif else F.body());label.add_theme_font_size_override("font_size",sz);label.add_theme_color_override("font_color",Color(color))

func near_boat()->bool:
	return NOTES.has(id) and job.stage=="sail" and job.pos.distance_to(LANDING)<3. and absf(job.speed)<2.1 and not job.chart.large and not job.harbour_charter.visible and not job.worker_aboard and job.grain_status!=1 and job.works!=2 and job.transfer_left<=0. and not job.bread_loaded and job.seats.is_empty()

func read_note()->void:
	if not near_boat():return
	var note:Array=NOTES[id]
	maker.text=note[3]+"　／　"+note[0];title.text=note[1];line.text=note[2];reward.text=note[4]
	reading=true;age=0.;job.speed=0.;camera_start=job.cam.global_transform;camera_fov=job.cam.fov
	job.hud.hide();panel.show();job.sound.play_cue("page")
	tick(0.)

func tick(dt:float)->void:
	phase+=dt
	if sheet.visible:sheet.rotation.z=.028*sin(phase*2.3)
	if not reading:return
	age+=dt;var t:=smoothstep(0.,.58,age)
	var focus:=global_position+Vector3(-.9,2.1,.15)
	var eye:=focus+Vector3(-1.75,.29,-5.15)
	job.cam.global_transform=camera_start.interpolate_with(Transform3D(Basis.looking_at(focus-eye),eye),t)
	job.cam.fov=lerpf(camera_fov,47.,t)
	panel.modulate.a=smoothstep(.16,.66,age);accept.disabled=age<.66

func dismiss()->void:
	if not reading:return
	reading=false;panel.hide();job.hud.show();job.cam.global_transform=camera_start;job.cam.fov=camera_fov
	job.ui_update()

func confirm()->void:
	if not reading or age<.66:return
	dismiss();signed.emit(id)
