extends Control

signal selected(index:int)
signal closed
const Fonts=preload("res://harbour_fonts.gd")
const NAMES=["酒庄的车","北岬的镜片","卡戎的夜班","磨坊的一袋风","蓝窗的炉火","木阶上的灯","泉神的水道","第一声港钟"]
const KEYS=["E","N","M","V","H","L","G","B"]
var continuation:=Button.new()
var rows:Array[Button]=[]
var entry_box:=GridContainer.new()
var latest:=Label.new()
var heading:=Label.new()
var detail:=Label.new()
var cover:=TextureRect.new()
var allowed:int=0
var current:=7
var close:=Button.new()

func style(b:Button,primary:=false)->void:
	b.add_theme_font_override("font",Fonts.body())
	b.add_theme_font_size_override("font_size",22 if primary else 18)
	b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","focus","pressed"]:
		var paper:=StyleBoxFlat.new()
		paper.bg_color=Color("#385c59" if state=="normal" else "#547a6e") if primary else Color("#273e44" if state=="normal" else "#415b59")
		paper.border_color=Color("#cbae79" if primary else "#66746b");paper.set_border_width_all(1)
		paper.content_margin_left=16;paper.content_margin_right=16
		b.add_theme_stylebox_override(state,paper)

func label_at(l:Label,p:Vector2,words:String,sz:int,ink:String,serif:=false)->void:
	add_child(l);l.position=p;l.text=words;l.add_theme_font_override("font",Fonts.headings() if serif else Fonts.body())
	l.add_theme_font_size_override("font_size",sz);l.add_theme_color_override("font_color",Color(ink))

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	var shade:=ColorRect.new();shade.color=Color("#14292ff7");shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label_at(Label.new(),Vector2(82,45),"西湾港务所",19,"#d9bb82")
	label_at(heading,Vector2(78,77),"我的航程",44,"#fff0cd",true)
	add_child(cover);cover.position=Vector2(82,165);cover.size=Vector2(340,395);cover.texture=preload("res://art/watch_blue.jpg");cover.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;cover.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	label_at(latest,Vector2(475,165),"下一站",21,"#d9bb82")
	add_child(continuation);continuation.position=Vector2(475,214);continuation.size=Vector2(690,66);style(continuation,true)
	continuation.pressed.connect(func():selected.emit(current))
	label_at(detail,Vector2(476,300),"",18,"#dedac8")
	label_at(Label.new(),Vector2(475,372),"我答应过的事",24,"#f0dfb8",true)
	add_child(entry_box);entry_box.columns=3;entry_box.position=Vector2(475,430);entry_box.add_theme_constant_override("h_separation",10);entry_box.add_theme_constant_override("v_separation",12)
	for i in NAMES.size():
		var b:=Button.new();style(b);b.text=KEYS[i]+"   "+NAMES[i];b.custom_minimum_size=Vector2(218,48)
		entry_box.add_child(b);rows.append(b);b.pressed.connect(func():selected.emit(i))
	add_child(close);close.position=Vector2(1008,65);close.size=Vector2(157,46);style(close);close.text="合上  Esc";close.pressed.connect(func():closed.emit())

func present(mask:int,done:bool,caption:String)->void:
	allowed=mask;current=8 if done else 7
	continuation.text=("继续航程　" if done else "上山借钟　")+"·　"+caption
	detail.text="蓝棚木阶西侧挂着居民的托付。靠过去，就能读到纸条。" if done else "白帆港起雾了，山上的钟，也许能让船找到回家的路。"
	for i in rows.size():rows[i].visible=(mask & (1<<i))!=0 and i!=current
	show()
