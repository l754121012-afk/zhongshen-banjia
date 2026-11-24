extends Control
signal pinned(world:Vector2,caption:String)
const Body=preload("res://harbour_fonts.gd")
const Terrain=preload("res://zephyr_land.gd")
const Coast=preload("res://zephyr_coast.gd")
const Wind=preload("res://zephyr_weather.gd")
const PAPER:=Color("#dfd0ac")
const INK:=Color("#34514e")
const FAINT:=Color("#78755e")
const OCEAN:=Color("#6d9592")
const STONE:=Color("#568078")
const LOW:=Color("#597a93")
const FLIGHT:=Color("#ab6445")
const NAMES:=["背风石巷","断桥","旧磨沟","山顶磨坊","西风小祠"]
const POINTS:=[Vector2(65,-24),Vector2(56,0),Vector2(66,13),Terrain.MILL_PORT,Coast.SHRINE]
var body:=Body.body()
var head:=Body.headings()
var map_rect:=Rect2(53,100,878,335)
var points:PackedVector2Array
var active:=-1
var game
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hide()
	for p:Vector2 in POINTS:points.append(project(p))
func open(owner_job)->void:game=owner_job;show();queue_redraw()
func project(p:Vector2)->Vector2:
	return map_rect.position+Vector2((p.x+64.)/177.*map_rect.size.x,(p.y+38.)/68.*map_rect.size.y)
func trace(line_points:Array,col:Color,width:float,dash:=false)->void:
	for j in line_points.size()-1:
		var a:=project(line_points[j]);var b:=project(line_points[j+1])
		if dash:draw_dashed_line(a,b,col,width,8,true,true)
		else:draw_line(a,b,col,width,true)
func word(s:String,pt:Vector2,px:int,colour:=INK,serif:=false)->void:
	draw_string(head if serif else body,pt,s,HORIZONTAL_ALIGNMENT_LEFT,-1,px,colour)
func polygon(line_points:Array,colour:Color)->void:
	var arr:=PackedVector2Array()
	for v:Vector2 in line_points:arr.append(project(v))
	draw_colored_polygon(arr,colour)
func _draw()->void:
	if game==null:return
	draw_rect(Rect2(Vector2.ZERO,Vector2(1280,720)),Color("#132c35a8"))
	draw_rect(Rect2(151,59,986,614),Color("#192e3777"))
	draw_set_transform(Vector2(143,51))
	draw_rect(Rect2(0,0,989,614),PAPER)
	draw_rect(Rect2(8,8,973,596),Color("#9d9173"),false,1.)
	word("西风运单",Vector2(40,55),32,INK,true);word("橄榄风坊   —   北坡磨坊",Vector2(217,52),20)
	word("M / Esc　收起",Vector2(814,51),17,FAINT)
	draw_line(Vector2(40,70),Vector2(947,70),Color("#ae9f80"),1)
	draw_rect(map_rect,OCEAN)
	var coast:=[Vector2(-61,-21),Vector2(-53,-28),Vector2(-33,-32),Vector2(-13,-33),Vector2(6,-31),Vector2(24,-32),Vector2(54,-30),Vector2(80,-33),Vector2(102,-29),Vector2(110,-22),Vector2(111,-12),Vector2(108,0),Vector2(112,12),Vector2(103,22),Vector2(77,22),Vector2(65,26),Vector2(45,23),Vector2(29,25),Vector2(3,24),Vector2(-17,26),Vector2(-38,24),Vector2(-53,22),Vector2(-62,18)]
	polygon(coast,Color("#c2bc92"));trace(coast+[coast[0]],Color("#e4d4ac"),2.)
	for i in 5:
		var ridge:=[]
		for j in 13:ridge.append(Vector2(24+j*6.5,-26+i*2.9+2.4*sin(j*.68+i*.29)))
		trace(ridge,Color("#a8a47f"),1.)
	polygon([Vector2(47,0),Vector2(51,-7),Vector2(60,-13),Vector2(69,-13.5),Vector2(76,-8),Vector2(85,9),Vector2(77,18),Vector2(65,20),Vector2(52,14)],Color("#b79b78"))
	for i in 4:
		trace([Vector2(51+i*1.4,4),Vector2(59+i*.6,-9+i*1.3),Vector2(68,-10+i*1.35),Vector2(76-i*.4,-3+i*1.2),Vector2(80-i*.65,9+i*.5)],Color("#9e8768"),1)
	trace(Coast.ROAD,Color("#947653"),3.5)
	trace([Vector2(3,0),Vector2(16,1),Vector2(30,0)],Color("#947653"),3.5)
	trace(Terrain.STONE_ROAD,STONE,4.1);trace(Terrain.HOLLOW,LOW,3.4)
	trace([Vector2(30,0),Vector2(47,0),Vector2(59,0)],FLIGHT,3.5)
	trace([Vector2(59,0),Vector2(72.5,0)],FLIGHT,3.5,true);trace([Vector2(72.5,0),Vector2(85,0),Terrain.MILL_PORT],FLIGHT,3.4)
	for j in 6:
		var h:=project(Vector2(5+j*3.05,1.4));draw_line(h+Vector2(-5,9),h+Vector2(1,-7),Color("#517a72"),2,true)
	for i in points.size():
		var p:=points[i];var col:Color=[STONE,FLIGHT,LOW,INK,INK][i]
		draw_circle(p,7.,PAPER);draw_circle(p,4.4,col)
		if i==active:draw_arc(p,10.,0,TAU,26,Color("#a25f43"),2,true)
		var off:Vector2=[Vector2(-34,-11),Vector2(-25,-11),Vector2(-20,26),Vector2(-28,-15),Vector2(-39,28)][i]
		word(NAMES[i],p+off,15,col)
	var port:=project(Coast.START);draw_circle(port,6.1,INK);word("风坊",port+Vector2(-11,26),15)
	var you:=project(game.pos);var facing:=Vector2(cos(game.heading),-sin(game.heading));var side:=Vector2(-facing.y,facing.x)
	draw_circle(you,11,Color("#ead5a2"));draw_colored_polygon(PackedVector2Array([you+facing*10,you-facing*6+side*6,you-facing*6-side*6]),Color("#9c5038"))
	draw_rect(map_rect,Color("#968e72"),false,1.2)
	word("余风 %d / 100"%game.wind_units(),Vector2(55,476),22,INK,true)
	word("撑起绞盘只需送达；留下 80 点，伊娅就能开炉。",Vector2(265,475),17)
	var after:=maxi(0,game.wind_units()-int(game.BURST_COST))
	var cost:="当前余风不足二段跳" if game.wind_units()<int(game.BURST_COST) else ("再借一次风，预计剩 %d 点"%after)
	word(cost+"　·　旧磨沟有第二道风廊",Vector2(55,513),17)
	word("导风罩　12 枚 / 单　可斜穿风廊采风",Vector2(55,544),16,FAINT)
	word("点地名，给车上罗盘标路。",Vector2(55,581),16,FAINT)
	if active>=0:word("当前指向　"+NAMES[active],Vector2(703,579),17)
func _gui_input(event:InputEvent)->void:
	if not visible or not event is InputEventMouseButton or event.button_index!=MOUSE_BUTTON_LEFT or not event.pressed:return
	var p:Vector2=event.position-Vector2(143,51)
	var nearest:=-1;var best:=43.
	for i in points.size():
		var d:=p.distance_to(points[i])
		if d<best:best=d;nearest=i
	if nearest>=0:
		active=nearest;pinned.emit(POINTS[active],NAMES[active]);queue_redraw()
	accept_event()
