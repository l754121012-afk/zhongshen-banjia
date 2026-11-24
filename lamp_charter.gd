extends Control
var display:=preload("res://harbour_fonts.gd").headings()
var body:=preload("res://harbour_fonts.gd").body()
signal mirror_requested
var mirror_button:=Button.new()
var mirror_label:=Label.new()
var crossings:=0
func fares(count:int)->void:
	crossings=count;queue_redraw()
var regular:=false
var market:=false
var beacon:=false
var grain:=false
var inn:=false
var crew:=false
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index=60;mouse_filter=Control.MOUSE_FILTER_STOP;hide()
	add_child(mirror_label);mirror_label.position=Vector2(315,521);mirror_label.add_theme_font_override("font",body);mirror_label.add_theme_font_size_override("font_size",16);mirror_label.add_theme_color_override("font_color",Color("#cad9c8"));mirror_label.hide()
	add_child(mirror_button);mirror_button.position=Vector2(644,539);mirror_button.size=Vector2(315,41)
	mirror_button.add_theme_font_override("font",body);mirror_button.add_theme_font_size_override("font_size",18);mirror_button.focus_mode=Control.FOCUS_NONE;mirror_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for flavor in ["normal","hover","pressed","disabled"]:
		var panel:=StyleBoxFlat.new();panel.bg_color=Color("#37635e") if flavor!="hover" else Color("#497870")
		panel.border_color=Color("#bd9e68");panel.set_border_width_all(1);mirror_button.add_theme_stylebox_override(flavor,panel)
	mirror_button.pressed.connect(func():mirror_requested.emit());mirror_button.hide()
func present(served:bool,shop:bool,tower:bool,flour:=false,inn_table:=false,crew_table:=false)->void:
	grain=flour;inn=inn_table;crew=crew_table
	regular=served;market=shop;beacon=tower;show();queue_redraw()
func mirror_status(enabled:bool,installed:bool,wallet:int)->void:
	mirror_button.visible=enabled and not installed
	mirror_button.disabled=wallet<6
	mirror_button.text="回车  装照礁镜　·　6 枚" if wallet>=6 else "装照礁镜还差 %d 枚"%(6-wallet)
	mirror_label.visible=enabled and not grain
	mirror_label.text="照礁镜已装好。收班后，礁石上也能看见灯光。" if installed else "把木阶的灯光反到外弯，过礁的人就能看清水面。"
	queue_redraw()

func words(where:Vector2,t:String,font:Font,px:int,color:Color)->void:
	draw_string(font,where,t,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func _draw()->void:
	var ink:=Color("#fae5b6");var brass:=Color("#c6a36d");var teal:=Color("#a7bbaa")
	draw_rect(Rect2(0,0,1280,720),Color("#101e27b8"))
	draw_rect(Rect2(262,106,756,508),Color("#172d30"));draw_rect(Rect2(269,113,742,494),brass,false,2)
	for x in [285,994]:
		for y in [131,588]:draw_circle(Vector2(x,y),4,brass)
	words(Vector2(313,163),"西湾港务所　/　公共泊位",body,19,teal)
	words(Vector2(313,232),"蓝棚木阶共建铭",display,44,ink)
	draw_line(Vector2(313,254),Vector2(960,254),brass,1)
	words(Vector2(313,299),"双灯窑烧成陶灯，伊娅分出炉火，船夫沿阶传灯。",body,22,ink)
	words(Vector2(313,339),"西湾搬家公司承运、吊装。自今夜起，木阶等末班船。",body,21,ink)
	words(Vector2(313,409),"窑工　　伊娅　　船夫　　西湾搬家公司",display,25,brass)
	draw_line(Vector2(313,437),Vector2(960,437),brass,1)
	var history:PackedStringArray=["木阶通航"]
	if beacon:history.append("北岬灯塔已亮")
	if market:history.append("晨市已开张")
	if regular:history.append("末班窑工到岸")
	words(Vector2(313,483),"　·　".join(history),body,18,teal)
	if grain:
		var signatures:PackedStringArray=["谷神麦穗印 · 首驳通港"]
		if inn:signatures.append("月桂客舍常订晨饭")
		if crew:signatures.append("码头工班协装压舱铁")
		if inn and crew:signatures=["谷神长桌已落成","客舍常订晨饭","工班协装压舱铁"]
		words(Vector2(313,519),"　·　".join(signatures),body,18,ink)
	if crossings>0:words(Vector2(724,163),"末班船已接送 %d 人"%crossings,body,18,ink)
	words(Vector2(313,562),"E 或 Esc　收起铭牌",body,18,brass)
	for i in 3:
		var at:=Vector2(863+i*36,195)
		draw_line(at+Vector2(0,9),at+Vector2(0,25),brass,2)
		draw_circle(at,7,brass)
