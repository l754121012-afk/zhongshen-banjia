extends Control

signal selected(index:int)
const POSTERS=preload("res://art/harbour_posters.png")
var font:=preload("res://harbour_fonts.gd").body()
var serif:=preload("res://harbour_fonts.gd").headings()
var stamps:Array[Label]=[]
var buttons:Array[Button]=[]
var continuation:=Button.new()
var original_heading:Label
var original_brand:Label
var public_order:Button
var hover_card:=-1
func make_label(parent:Control,point:Vector2,words:String,size_px:int,tint:String,book:=false)->Label:
	var item:=Label.new();item.mouse_filter=Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_override("font",serif if book else font);item.add_theme_font_size_override("font_size",size_px)
	item.add_theme_color_override("font_color",Color(tint));item.position=point;item.text=words;parent.add_child(item);return item
func block(parent:Control,point:Vector2,dims:Vector2,tint:String)->ColorRect:
	var rect:=ColorRect.new();rect.color=Color(tint);rect.position=point;rect.size=dims
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(rect);return rect
func poster(index:int)->Texture2D:
	if index==3:return preload("res://art/zephyr_poster.png")
	if index==0:return preload("res://art/wine.png")
	var atlas:=AtlasTexture.new();atlas.atlas=POSTERS
	var w:=POSTERS.get_width()/2
	atlas.region=Rect2(w*(index-1),0,w,POSTERS.get_height());return atlas
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	block(self,Vector2.ZERO,Vector2(1280,720),"#122f38")
	block(self,Vector2(44,91),Vector2(1192,1),"#8a917a")
	original_brand=make_label(self,Vector2(48,20),"众神搬家",40,"#f4dfaf",true)
	original_heading=make_label(self,Vector2(260,43),"西湾港务所　/　委托簿",20,"#c8c9aa")
	add_child(continuation);continuation.position=Vector2(42,20);continuation.size=Vector2(407,57);continuation.focus_mode=Control.FOCUS_NONE
	continuation.add_theme_font_override("font",font);continuation.add_theme_font_size_override("font_size",19);continuation.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("#37635e" if state=="normal" else "#497870");style.border_color=Color("#c6a26c");style.set_border_width_all(1);style.border_width_left=4
		continuation.add_theme_stylebox_override(state,style)
	continuation.pressed.connect(func():selected.emit(8));continuation.hide()
	var bell:=Button.new();bell.text="B　第一声港钟";bell.position=Vector2(476,29);bell.size=Vector2(171,48);bell.focus_mode=Control.FOCUS_NONE;bell.add_theme_font_override("font",font);add_child(bell);bell.pressed.connect(func():selected.emit(7))
	var order:=Button.new();order.text="G　泉神的旱季 · 引水";order.position=Vector2(665,29);order.size=Vector2(295,48)
	order.icon=preload("res://art/spring_arethusa.jpg");order.add_theme_constant_override("icon_max_width",44)
	order.focus_mode=Control.FOCUS_NONE;order.add_theme_font_override("font",font);add_child(order);order.pressed.connect(func():selected.emit(6))
	make_label(self,Vector2(1032,46),"P 或 Esc　合上",16,"#c5c8b2")
	var shop:=Button.new();shop.text="H　西湾经营簿 · 搬炉与派货";shop.position=Vector2(40,657);shop.size=Vector2(348,44);shop.focus_mode=Control.FOCUS_NONE;shop.add_theme_font_override("font",font);add_child(shop);shop.pressed.connect(func():selected.emit(4))
	public_order=Button.new();public_order.position=Vector2(403,655);public_order.size=Vector2(840,50)
	public_order.focus_mode=Control.FOCUS_NONE
	order.focus_mode=Control.FOCUS_NONE;public_order.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	public_order.add_theme_font_override("font",font);public_order.add_theme_font_size_override("font_size",19)
	for kind in ["normal","hover","pressed"]:
		var surf:=StyleBoxFlat.new();surf.bg_color=Color("#36544f" if kind=="normal" else "#52685a");surf.border_color=Color("#b8a378");surf.set_border_width_all(1)
		public_order.add_theme_stylebox_override(kind,surf)
	add_child(public_order);public_order.pressed.connect(func():selected.emit(5))
	for side in 2:
		var tile:=TextureRect.new();tile.mouse_filter=Control.MOUSE_FILTER_IGNORE;tile.size=Vector2(46,46);tile.position=Vector2(3+side*788,2)
		tile.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;tile.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tile.texture=preload("res://art/watch_kiln.jpg") if side==0 else preload("res://art/watch_blue.jpg");public_order.add_child(tile)
	var captions:=["西湾公路","潮汐船坞","冥河渡客","西风过境"]
	var tags:=["公路班　·　酒神商队","日班　·　北岬灯塔","夜班　·　卡戎渡船","风坊　·　泽费罗斯"]
	var descriptions:=["搬货穿过山道，吊卸签收。","装镜启航，自选海峡与山路。","安排两席渡客，各自抵岸。","把一袋西风送进山顶磨坊。"]
	var keys:=["E　出车","N　接日班","M　接夜班","V　接西风"]
	for i in 4:
		var card:=Control.new();card.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.position=Vector2(38+((i+1)%4)*305,113);card.size=Vector2(289,535);add_child(card)
		block(card,Vector2.ZERO,card.size,"#c3ae83")
		block(card,Vector2.ONE,card.size-Vector2.ONE*2,"#1d3940" if i!=2 else "#283544")
		var frame:=TextureRect.new();frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.position=Vector2(7,7);frame.size=Vector2(275,318)
		frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;frame.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;frame.texture=poster(i);card.add_child(frame)
		block(card,Vector2(7,325),Vector2(275,2),"#a69577")
		make_label(card,Vector2(18,339),tags[i],16,"#cfb98b")
		make_label(card,Vector2(17,367),captions[i],33,"#fff0cc",true)
		make_label(card,Vector2(19,420),descriptions[i],17,"#dbdbca")
		var seal:=make_label(card,Vector2(19,454),"",15,"#a7d0bd")
		stamps.append(seal)
		block(card,Vector2(15,482),Vector2(259,1),"#77857b")
		make_label(card,Vector2(18,491),keys[i],20,"#ffe0a5")
		var b:=Button.new();b.position=Vector2.ZERO;b.size=card.size;b.focus_mode=Control.FOCUS_NONE;b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		for theme in ["normal","pressed","focus"]:b.add_theme_stylebox_override(theme,StyleBoxEmpty.new())
		var over:=StyleBoxFlat.new();over.draw_center=false;over.set_border_width_all(3);over.border_color=Color("#f1cc85");b.add_theme_stylebox_override("hover",over)
		card.add_child(b);buttons.append(b)
		b.pressed.connect(func():selected.emit(i))
func refresh(day:int,night:int,dawn:bool,lamp:bool,wind_level:=0,wallet:=0,bread_waiting:=false,freight_route:=0,fare:=8,lamp_step:=0,regular:=false,grain:=0)->void:
	stamps[0].text="酒庄　→　神庙　→　月桂客舍"
	stamps[1].text=("灯匠潜水灯已领　" if lamp else "")+("纪录 %d 枚"%day if day>0 else "可选　沉库打捞")
	stamps[2].text=("北岬航标已亮　" if dawn else "")+("纪录 %d 枚"%night if night>0 else "可选　海螺寻遗钱")
	stamps[3].text=["磨坊等风","绞盘已复工","蓝窗已开炉"][clampi(wind_level,0,2)]+"　·　钱包 %d 枚"%wallet
	if bread_waiting and freight_route==2:stamps[2].text="面包已派双灯窑　·　捎货 +%d 枚"%fare
	var text:String=["共建委托　·　第一盏晚灯","窑口取灯　·　蓝棚在等你","陶灯已上船　·　续运回港","木阶通航　·　接窑工赶末班"][lamp_step]
	if regular:text=["首班粮驳　·　外港系拖缆","继续领航　·　粮驳还在船尾","蓝棚晨班　·　上岸分粮"][grain]
	public_order.text="L　"+text

func continue_route(caption:String)->void:
	continuation.visible=caption!=""
	original_heading.visible=caption==""
	original_brand.visible=caption==""
	if caption!="":continuation.text="回车  "+caption
