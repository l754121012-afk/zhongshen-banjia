extends Control

const INK := Color("#172f36")
const PAPER := Color("#fff0d4")
const SOFT := Color("#d3e6d8")
const AMBER := Color("#ffc16b")
const JADE := Color("#176c65")
const RED := Color("#b74a38")
var regular := SystemFont.new()
var bold := SystemFont.new()
var serif := SystemFont.new()
var layer: Control
var tips := {}
var ctl := {}
var game
var buttons: Array[Button] = []

func _ready() -> void:
	regular.font_names=PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","Noto Sans CJK SC"])
	bold.font_names=regular.font_names
	bold.font_weight=720
	serif.font_names=PackedStringArray(["STZhongsong","SimSun","Microsoft YaHei"])
	serif.font_weight=700
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func rebuild() -> void:
	if is_instance_valid(layer):
		remove_child(layer)
		layer.queue_free()
	layer=Control.new()
	layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	layer.size=Vector2(1280,720)
	buttons.clear()
	ctl.clear()
	tips.clear()

func card(x: float,y: float,w: float,h: float,color: Color, radius:=14, border:=Color.TRANSPARENT) -> Panel:
	var n:=Panel.new()
	n.position=Vector2(x,y)
	n.size=Vector2(w,h)
	var style:=StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(radius)
	if border.a>0:
		style.border_color=border
		style.set_border_width_all(1)
	n.add_theme_stylebox_override("panel",style)
	n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(n)
	return n

func label(x: float,y: float,w: float,h: float,s: String,px: int,col:=PAPER,weight:=false,display:=false, align:=HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var n:=Label.new()
	n.text=s
	n.position=Vector2(x,y)
	n.size=Vector2(w,h)
	n.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	n.horizontal_alignment=align
	n.add_theme_font_override("font",serif if display else (bold if weight else regular))
	n.add_theme_font_size_override("font_size",px)
	n.add_theme_color_override("font_color",col)
	n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(n)
	return n

func pic(path: String,x: float,y: float,w: float,h: float,keep:=true) -> TextureRect:
	var n:=TextureRect.new()
	n.texture=load(path)
	n.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	n.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	n.position=Vector2(x,y)
	n.size=Vector2(w,h)
	layer.add_child(n)
	return n

func action(x: float,y: float,w: float,h: float,title: String,fn: Callable,primary:=true) -> Button:
	var n:=Button.new()
	n.text=title
	n.position=Vector2(x,y)
	n.size=Vector2(w,h)
	n.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	n.add_theme_font_override("font",bold)
	n.add_theme_font_size_override("font_size",19)
	for state in ["normal","hover","pressed","focus"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=(AMBER if primary else Color("#31565a")) if state=="normal" else (Color("#ffdb95") if primary else Color("#497371"))
		style.set_corner_radius_all(8)
		if state=="focus":
			style.draw_center=false
			style.set_border_width_all(2)
			style.border_color=Color("#fff6df")
		n.add_theme_stylebox_override(state,style)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		n.add_theme_color_override(key,INK if primary else PAPER)
	layer.add_child(n)
	n.pressed.connect(fn)
	buttons.append(n)
	return n

func top(tag: String,title: String,sub: String) -> void:
	card(26,20,423,91,Color("#173940ef"))
	card(26,34,4,61,AMBER,2)
	label(45,26,385,19,tag,12,AMBER,true)
	label(44,47,382,35,title,25,PAPER,true)
	label(45,82,390,21,sub,14,SOFT)
	action(1188,24,67,39,"暂停",game.pause_game,false)
	buttons.back().add_theme_font_size_override("font_size",15)

func manual(text: String) -> void:
	card(27,641,1226,57,Color("#173940ee"),10)
	label(48,648,1180,42,text,17,PAPER)

func title_page(best: int, clears: int) -> void:
	rebuild()
	pic("res://art/cover.png",0,0,1280,720,false)
	# Soft continuous vignette keeps the key art intact behind the type.
	var veil:=ColorRect.new()
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	veil.size=Vector2(1280,720)
	var sh:=Shader.new()
	sh.code="shader_type canvas_item; void fragment(){ COLOR=vec4(0.025,0.105,0.115,0.89*(1.0-smoothstep(0.05,0.66,UV.x))); }"
	var sm:=ShaderMaterial.new()
	sm.shader=sh
	veil.material=sm
	layer.add_child(veil)
	label(70,107,530,38,"O L Y M P U S   R E M O V A L S",20,AMBER,true)
	label(62,161,640,120,"众神搬家",88,PAPER,true,true)
	label(70,298,550,40,"第一程  ·  风神的急件",29,PAPER,true)
	label(72,354,560,32,"在奥林匹斯送货，每件行李都有自己的脾气。",18,SOFT)
	action(72,448,207,57,"接下委托    ›",game.begin_dispatch)
	if clears>0:
		action(72,519,207,44,"夜班加急单    ›",game.begin_expert,false)
		label(73,585,485,29,"已签收 %d 单    ·    最高单笔净赚 %d 枚" % [clears,best],16,SOFT)
	label(72,650,610,33,"空格 接单      /      M 声音开关      /      F11 全屏",14,SOFT)

func briefing(expert: bool) -> void:
	rebuild()
	card(0,0,1280,720,Color("#132c396c"),0)
	card(64,72,600,552,Color("#fbebcb"),18)
	label(99,96,525,31,"O L Y M P U S     /     派 车 单",15,JADE,true)
	label(95,145,525,74,"西风岬急运" if not expert else "夜班 · 逆风急运",45,INK,true,true)
	label(99,232,520,34,"委托人   酒神狄俄尼索斯  ×  风神埃俄罗斯" if expert else "委托人   风神埃俄罗斯  ×  睡神修普诺斯",18,JADE,true)
	label(99,288,519,92,"宴席开场前，把两瓮酒和风囊送到码头。\n酒车急转会洒酒。紫色工台能封蜡，每单 9 枚。" if expert else "把睡榻和风囊一起送过西风岬。\n睡神叮嘱「别叫醒我」。风神另付原封奖。",19,INK)
	label(99,407,495,64,"运费 100 枚   /   两位货主各有 25 枚小费" if not expert else "夜班运费 130 枚   /   路面更险，时间窗更短",17,INK,true)
	action(99,522,245,58,"到货场提货    ›",game.begin_load)
	pic("res://art/wind.png",717,144,266,339)
	pic("res://art/wine.png" if expert else "res://art/sleep.png",928,173,247,312)
	card(755,484,394,48,Color("#173940df"),10)
	label(766,487,370,40,"「我的顺风，一口都别少。」",18,PAPER,true,false,HORIZONTAL_ALIGNMENT_CENTER)

func loading() -> void:
	rebuild()
	top("01   /   提 货","酒神的庭院" if game.expert else "睡神的庭院","将两件货送到木坡。先装的靠车头，更平稳。")
	card(883,24,285,70,Color("#173940ec"),10)
	pic("res://art/icon_trolley.png" if game.expert else "res://art/icon_bed.png",890,24,67,60)
	pic("res://art/icon_sack.png",949,27,57,55)
	ctl.count=label(1016,34,144,42,"已装车  0 / 2",16,PAPER,true)
	card(358,570,564,51,Color("#173940e9"))
	ctl.prompt=label(368,572,544,46,"",18,AMBER,true,false,HORIZONTAL_ALIGNMENT_CENTER)
	manual("WASD   移动       空格   搬起 / 放下       Q / E   转货       Shift   蓄力抛货       F   借风开门       R   货物归位")

func rig(strap: int, route: int, expert: bool) -> void:
	rebuild()
	card(761,25,489,672,Color("#173940f9"),16)
	label(791,47,426,22,"02     /     装 车 调 度",14,AMBER,true)
	label(788,84,429,65,"出发前的选择",38,PAPER,true,true)
	label(792,157,425,30,"一道绑带，先护哪件货？",21,PAPER,true)
	label(792,193,430,42,"绑酒车可以减洒，绑风囊可以防漏。封蜡另计。" if expert else "睡榻绑稳能少颠醒；风囊绑稳能防止漏风。",15,SOFT)
	action(790,247,209,48,("已选 · " if strap==0 else "")+("绑酒车" if expert else "绑睡榻"),game.set_strap.bind(0),strap==0)
	action(1014,247,208,48,("已选 · " if strap==1 else "")+"绑风囊",game.set_strap.bind(1),strap==1)
	label(792,321,423,31,"选条路过西风岬",21,PAPER,true)
	action(790,372,209,50,("已选 · " if route==0 else "")+"山口飞桥",game.set_route.bind(0),route==0)
	action(1014,372,208,50,("已选 · " if route==1 else "")+"渡船码头",game.set_route.bind(1),route==1)
	label(792,440,430,79,"免渡费。断桥前放风借力，能保住悬架。\n可走应急板，着陆时悬架可能受损。" if route==0 else "渡费 14 枚。沿岸仍有颠簸，过河更稳。\n保住两件货的小费，可以抵回渡费。",16,SOFT)
	action(790,558,432,60,"签好货单，出发    ›",game.begin_road)
	label(792,637,420,29,"夜班急件 · 加收 30 枚" if expert else "本单运费 100 枚  ＋  货主小费",15,AMBER)
	card(28,37,350,55,Color("#173940df"))
	label(47,41,313,47,"货车装载图   /   西风号",20,PAPER,true)
	action(29,637,164,48,"重新提货",game.return_to_load,false)
	action(208,637,175,48,"交换前后位",game.swap_positions,false)
	var tail: String="风囊" if game.stow_x(1)<game.stow_x(0) else ("酒车" if expert else "睡榻")
	card(29,553,509,54,Color("#173940e8"),9)
	label(44,557,478,44,"车尾  "+tail+"   ·   尾部颠簸更重，先装的货靠车头。",16,PAPER)

func road() -> void:
	rebuild()
	top("03   /   在 途","西风岬公路","看路牌预判颠簸，留意车上的两位客户。")
	card(706,22,463,79,Color("#173940eb"))
	pic("res://art/icon_trolley.png" if game.expert else "res://art/icon_bed.png",711,25,78,68)
	pic("res://art/icon_sack.png",948,25,66,67)
	ctl.cargo=label(792,30,136,34,"",17,PAPER,true)
	ctl.air=label(1020,30,136,34,"",17,PAPER,true)
	card(793,72,133,7,Color("#42616a"),4)
	card(1021,72,130,7,Color("#42616a"),4)
	ctl.calm_bar=card(793,72,133,7,Color("#83c7bc"),4)
	ctl.air_bar=card(1021,72,130,7,AMBER,4)
	card(28,126,240,47,Color("#173940d9"),9)
	ctl.distance=label(41,127,214,35,"",16,AMBER,true)
	card(43,163,207,4,Color("#537273"),2)
	ctl.progress=card(43,163,2,4,AMBER,2)
	card(28,180,240,34,Color("#173940d9"),8)
	ctl.drive=label(41,181,221,32,"",15,PAPER,true)
	card(382,520,516,89,Color("#173940ec"),12)
	ctl.hazard=label(390,527,500,32,"",21,AMBER,true,false,HORIZONTAL_ALIGNMENT_CENTER)
	ctl.signal=label(391,564,498,31,"",15,PAPER,false,false,HORIZONTAL_ALIGNMENT_CENTER)
	card(447,609,386,17,Color("#122d33"),6)
	ctl.gauge=card(490,614,335,7,AMBER,4)
	label(453,607,39,19,"冲刺",11,SOFT,true)
	manual("W 加速  /  S 刹车稳货      A D 转向      空格 跳跃 · 空中再按借风      E 拉回")

func harbor_view() -> void:
	rebuild()
	top("04   /   交 货","西风港签收台","两位货主已经到了。轻放在对应软垫上有赏钱。")
	var i: int=game.crate_index
	var portrait: String="wind" if i==1 else ("wine" if game.expert else "sleep")
	card(916,22,255,87,Color("#173940ed"))
	pic("res://art/"+portrait+".png",920,22,81,86)
	label(1009,31,151,29,"风神签收" if i==1 else ("酒神签收" if game.expert else "睡神签收"),18,AMBER,true)
	label(1009,65,155,25,"第 %d 件  /  2" % (i+1),16,SOFT)
	card(338,559,604,67,Color("#173940ee"),11)
	ctl.crane=label(351,561,578,34,game.unload_line,18,PAPER,true,false,HORIZONTAL_ALIGNMENT_CENTER)
	card(480,607,320,4,Color("#607879"),2)
	card(621,601,38,16,JADE,4)
	ctl.marker=card(636,598,8,21,AMBER,3)
	if game.crane_stage=="signed":
		action(478,636,324,59,"查看货运回执   ›",game.finish_order)
	else:
		manual("A / D  或左右箭头   移吊车          点击软垫   自动对位          空格   松钩轻放          Esc   暂停")

func receipt(data: Dictionary, windline: String, sleepline: String) -> void:
	rebuild()
	pic("res://art/cover.png",0,0,1280,720,false)
	card(0,0,1280,720,Color("#142f38ba"),0)
	card(55,42,646,641,PAPER,17)
	label(89,65,578,27,"O L Y M P U S     /     货 运 回 执",15,JADE,true)
	label(86,107,586,67,"货物已签收",44,INK,true,true)
	label(90,189,576,33,"西风岬  ·  "+str(data.route_name),19,JADE,true)
	var sleep_label:=("酒神小费  ·  酒量" if game.expert else "睡神小费  ·  安眠")+" %d%%" % data.calm
	var wind_label: String="风神小费  ·  余风 %d%%" % data.air
	if data.sealed: wind_label+="（含原封奖 5）"
	var entries=[["基础运费", "+%d" % data.base],[sleep_label, "+%d" % data.sleep_tip],[wind_label, "+%d" % data.wind_tip]]
	if data.road_bonus>0: entries.append(["沿途急送赏金", "+%d" % data.road_bonus])
	if data.unload_tip>0: entries.append(["码头轻放赏钱", "+%d" % data.unload_tip])
	if data.fare>0: entries.append(["渡船票", "−%d" % data.fare])
	if data.axle>0: entries.append(["断桥硬着陆  ·  悬架维修", "−%d" % data.axle])
	if data.damage_fee>0: entries.append(["货况过低  ·  客户赔付", "−%d" % data.damage_fee])
	if data.wax_fee>0: entries.append(["酒庄封蜡", "−%d" % data.wax_fee])
	for i in entries.size():
		var y:=233+i*mini(43,220/entries.size())
		label(91,y,440,35,entries[i][0],18,INK)
		label(505,y,157,35,entries[i][1],20,INK,true,false,HORIZONTAL_ALIGNMENT_RIGHT)
	card(91,466,568,2,Color("#b8ab86"),0)
	label(90,485,315,64,"本单净赚",24,INK,true)
	label(402,480,259,75,"%d 枚" % data.net,41,JADE,true,false,HORIZONTAL_ALIGNMENT_RIGHT)
	action(90,584,200,58,"再试这单",game.restart_order)
	action(302,584,209,58,"接酒神急单  ›" if not game.expert else "接睡神委托  ›",game.begin_expert if not game.expert else game.begin_dispatch,false)
	action(526,584,131,58,"回标题",game.to_title,false)
	card(743,110,486,222,Color("#173940f0"))
	pic("res://art/wind.png",748,114,155,210)
	label(917,132,285,42,"风神  /  埃俄罗斯",20,AMBER,true)
	label(917,185,286,118,windline,17,PAPER)
	card(743,363,486,222,Color("#173940f0"))
	pic("res://art/wine.png" if game.expert else "res://art/sleep.png",747,369,156,208)
	label(917,385,285,42,"酒神  /  狄俄尼索斯" if game.expert else "睡神  /  修普诺斯",20,AMBER,true)
	label(917,438,286,118,sleepline,17,PAPER)
	var verdict: String="双神推荐" if data.air>=81 and data.calm>=82 else ("平安抵达" if data.net>=105 else "险中交差")
	var stamp=label(449,115,185,54,verdict,27,RED,true,true,HORIZONTAL_ALIGNMENT_CENTER)
	stamp.pivot_offset=Vector2(90,28)
	stamp.rotation=-0.11
	stamp.scale=Vector2.ONE*1.45
	stamp.modulate.a=0
	var tw=stamp.create_tween().set_parallel(true)
	tw.tween_property(stamp,"scale",Vector2.ONE,0.27).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(stamp,"modulate:a",1.0,0.18)
	var record_note: String="首单登记" if data.previous_best==0 else ("刷新纪录 +%d 枚" % (data.net-data.previous_best) if data.net>data.previous_best else "此单最佳 %d 枚" % data.previous_best)
	label(754,601,465,33,"%s   ·   提货 %d 秒   ·   拉回 %d 次" % [record_note,data.yard_seconds,data.catches],16,AMBER,true)
	if not game.report_lines.is_empty():
		label(754,639,465,28,str(game.report_lines.back()),15,SOFT)

func pause_overlay() -> void:
	rebuild()
	card(0,0,1280,720,Color("#153738bf"),0)
	card(415,121,450,483,INK)
	label(446,182,389,68,"休息片刻",39,PAPER,true,true,HORIZONTAL_ALIGNMENT_CENTER)
	action(468,279,344,53,"继续搬运",game.resume_game)
	action(468,351,344,53,"重开本单",game.restart_order,false)
	action(468,423,344,53,"回到标题",game.to_title,false)
	action(468,500,344,45,"声音   ·   "+("关闭" if game.muted else "开启"),game.toggle_sound,false)



