extends Control

var job
var font:=preload("res://harbour_fonts.gd").body()
var display:=preload("res://harbour_fonts.gd").headings()
var tile:=preload("res://art/spring_arethusa.jpg")
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_IGNORE;hide()
func ink(p:Vector2,s:String,px:int,color:Color)->void:draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func at(p:Vector2)->Vector2:return Vector2(136.+p.x*5.42,301.+p.y*4.05)
func path(points:Array,color:Color,thick:float)->void:
	var q:=PackedVector2Array()
	for p:Vector2 in points:q.append(at(p))
	draw_polyline(q,color,thick,true)
func spot(p:Vector2,name_text:String,offset:Vector2,open:=true)->void:
	var q:=at(p);draw_circle(q,8.,Color("#e9c47d") if open else Color("#82958c"));draw_circle(q,3.,Color("#324641"))
	ink(q+offset,name_text,18,Color("#fff0ce"))
func _draw()->void:
	if not is_instance_valid(job):return
	var g=job.owner_game
	draw_rect(Rect2(0,0,1280,720),Color("#15292cae"));draw_rect(Rect2(60,65,1160,580),Color("#234341"))
	draw_rect(Rect2(68,73,1144,564),Color("#ab986c"),false,2.)
	draw_texture_rect(tile,Rect2(93,95,84,84),false)
	draw_string(display,Vector2(202,137),"西湾引水图",HORIZONTAL_ALIGNMENT_LEFT,-1,35,Color("#ffdea1"))
	ink(Vector2(204,174),"渠匠随车手记",19,Color("#c4ccae"))
	ink(Vector2(981,138),"Tab　收起地图",19,Color("#fae3b5"))
	var coast:Array=[];var ridge:Array=[]
	for x in range(4,170,2):
		ridge.append(Vector2(x,g.land.path_z(x) if x<143 and x>42 else (3.5 if x>142 and job.step==4 else 7.)))
		if x>=44 and x<=134:coast.append(Vector2(x,g.land.cove_path(x)))
	path(ridge,Color("#bd9970"),5.)
	path(coast,Color("#91b5a4"),4.)
	spot(g.Map.LODGE,"月桂客舍",Vector2(-29,-17));spot(job.GARDEN,"月桂园",Vector2(-21,32))
	spot(job.HEAD,"渠首水轮",Vector2(-32,-18));spot(g.WIND_DOCK,"蓝棚码头",Vector2(-30,35))
	spot(job.cove.WELL,"阿瑞图萨泉眼" if job.discovered else "海湾泉眼",Vector2(-39,32),job.discovered)
	spot(Vector2(153,3.5),"水桥已通" if job.step>=4 else "升起的水桥",Vector2(-32,-17),job.step>=4)
	ink(Vector2(543,239),"山脊石道",17,Color("#d7b88d"));ink(Vector2(607,510),"海湾阴道",17,Color("#b2d0ba"))
	var pos2:=at(g.pos);var dir:=Vector2(cos(g.heading),-sin(g.heading))
	draw_circle(pos2,12.,Color("#273d3ccc"))
	draw_colored_polygon(PackedVector2Array([pos2+dir*12.,pos2-dir*7.+dir.orthogonal()*7.,pos2-dir*7.-dir.orthogonal()*7.]),Color("#fff7cd"))
	ink(Vector2(108,575),["先到蓝棚领轮毂","沿山道将轮毂运到渠首","调节闸门，让浮子停在绿色石纹","到月桂园开园闸","客舍收近单，蓝棚收整车；泉眼可借湿布护果"][job.step],21,Color("#ffdf9d"))
