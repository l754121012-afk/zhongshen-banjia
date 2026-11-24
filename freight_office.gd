extends Control

signal chosen(action:int)

var body:=preload("res://harbour_fonts.gd").body()
var serif:=preload("res://harbour_fonts.gd").headings()
var state
var move_button:Button
var depart:Button
var market:Button
var status:Label
var orders:Label
var history:Label
var watch:Button
var charter:Label
var balance:Label
var route_buttons:Array[Button]=[]

func label_at(p:Vector2,words:String,px:int,display:=false)->Label:
	var label:=Label.new()
	label.position=p
	label.text=words
	label.add_theme_font_override("font",serif if display else body)
	label.add_theme_font_size_override("font_size",px)
	label.add_theme_color_override("font_color",Color("#f4e4c4"))
	add_child(label)
	return label

func button_at(p:Vector2,w:int,words:String,id:int)->Button:
	var button:=Button.new()
	button.position=p
	button.size=Vector2(w,45)
	button.text=words
	button.add_theme_font_override("font",body)
	button.add_theme_font_size_override("font_size",18)
	button.focus_mode=Control.FOCUS_NONE
	for theme:String in ["normal","hover","pressed","disabled"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color({"normal":"#345c5a","hover":"#49746b","pressed":"#836e49","disabled":"#263f42"}[theme])
		style.border_color=Color("#8b967a") if theme!="disabled" else Color("#415759")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(theme,style)
	button.pressed.connect(func():chosen.emit(id))
	add_child(button)
	return button

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index=20
	mouse_filter=Control.MOUSE_FILTER_STOP
	draw.connect(draw_routes)
	label_at(Vector2(58,28),"西湾搬家公司",38,true)
	label_at(Vector2(335,51),"常营货线",20)
	balance=label_at(Vector2(993,41),"",24,true)
	var picture:=TextureRect.new()
	picture.position=Vector2(58,122)
	picture.size=Vector2(475,310)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.texture=preload("res://art/hearth_dispatch.jpg")
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	label_at(Vector2(59,454),"伊娅的蓝棚面包房",29,true)
	status=label_at(Vector2(60,507),"",18)
	move_button=button_at(Vector2(60,579),348,"H　接搬炉委托",0)
	label_at(Vector2(591,120),"今日派货",28,true)
	orders=label_at(Vector2(592,176),"",19)
	route_buttons.append(button_at(Vector2(591,233),297,"",1))
	route_buttons.append(button_at(Vector2(907,233),297,"",2))
	depart=button_at(Vector2(591,294),613,"",4)
	label_at(Vector2(592,365),"商号账本",28,true)
	history=label_at(Vector2(592,418),"",19)
	market=button_at(Vector2(591,559),613,"",5)
	watch=button_at(Vector2(569,647),366,"",6)
	charter=label_at(Vector2(58,658),"",18)
	button_at(Vector2(966,647),240,"Esc　回委托簿",3)
	hide()

func draw_routes()->void:
	draw_rect(Rect2(0,0,1280,720),Color("#18373c"))
	draw_rect(Rect2(45,109,501,525),Color("#244349"))
	draw_rect(Rect2(56,120,479,314),Color("#c4a16c"),false,2)
	draw_line(Vector2(58,96),Vector2(1222,96),Color("#899077"),1)
	draw_line(Vector2(592,350),Vector2(1204,350),Color("#627a70"),1)
	draw_line(Vector2(58,641),Vector2(1222,641),Color("#63786e"),1)

func refresh(g)->void:
	state=g
	queue_redraw()
	watch.text=["4　共建 · 第一盏晚灯","4　双灯窑取陶灯","4　续运陶灯","4　乘末班船看灯"][g.lamp_step]
	if g.lamp_worker_home:watch.text=["4　首班粮驳","4　继续领航","4　去蓝棚分早饭"][g.grain_status]
	charter.text="商号已挂牌 · 西风班赠丰收枝" if g.chartered() else "商号 · 开晨市，集齐客舍与窑口签收"
	balance.text="钱包　%d 枚"%g.wind_wallet
	move_button.text="H　去船坞看伊娅" if g.hearth_moved else "H　接伊娅的搬炉委托"
	status.text="灶台已迁入潮汐船坞。\n伊娅会给下一班出车备好面包。" if g.hearth_moved else "把老灶送进潮汐船坞。\n到岸时还留有 55 点炉火，即可开炉。"
	var labels:=["刚出炉一篮面包，选一个地方送去。","东岸码头装车　·　沿途拾月桂叶，客舍另付 2 枚。","一篮已订　·　双灯窑，接夜渡时随船装载。","面包已上车　·　沿公路送往月桂客舍。"]
	orders.text=labels[g.freight_route] if g.bread_waiting else ("正在发面　·　完成一张运输委托即可出炉。" if g.hearth_moved else "等待面包房搬迁。")
	var extra:=2 if g.market_open else 0
	route_buttons[0].text="1　月桂客舍　公路 +%d"%(6+extra+(3 if g.table_inn else 0))
	route_buttons[1].text="2　双灯窑　夜渡 +%d"%g.kiln_fare()
	for b in route_buttons:b.disabled=not g.bread_waiting or g.freight_route!=0
	depart.visible=g.bread_waiting and g.freight_route in [1,2,3] and g.stage in ["pickup","signed"]
	depart.text={1:"Enter　去东岸码头接货",2:"Enter　接冥河夜渡",3:"Enter　继续公路送货"}.get(g.freight_route,"")
	history.text="客舍签收　%d 篮　　　双灯窑签收　%d 篮\n搬炉运费　%d 枚　　　护火赏金　　%d 枚\n基础捎货　%d 枚　　　晨市加价　　%d 枚\n月桂叶另收　%d 枚　　夜市预订　　%d 枚"%[g.inn_runs,g.bread_shipments,g.move_pay,g.hot_pay,g.inn_runs*6+g.bread_shipments*8,g.market_bonus,g.laurel_income,g.lamp_supper_bonus]
	if g.grain_status==2:history.text+="\n首航运费　%d 枚　　　客舍常订　　%d 枚"%[g.grain_pay,g.inn_regular_pay]
	var eligible:bool=g.hearth_moved and g.inn_runs+g.bread_shipments>0
	market.disabled=g.market_open or not eligible or g.wind_wallet<12
	market.text="晨市已开张　·　每篮多收 2 枚" if g.market_open else ("3　合办码头晨市　·　投入 12，每篮加收 2" if eligible else "完成首次捎货，可与伊娅合办晨市")
	show()
