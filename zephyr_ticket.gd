extends Control
const Ink:="#294545"
const Muted:="#716a55"
const PALE:="#eadcb8"
var body:=preload("res://harbour_fonts.gd").body()
var serif:=preload("res://harbour_fonts.gd").headings()
var data:Dictionary={}
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;position=Vector2(871,72);size=Vector2(375,549);hide()
func line(words:String,x:float,y:float,px:int,col:String=Ink,display:=false,width:float=-1,align:=HORIZONTAL_ALIGNMENT_LEFT)->void:
	draw_string(serif if display else body,Vector2(x,y),words,align,width,px,Color(col))
func ruled(y:float)->void:draw_line(Vector2(23,y),Vector2(350,y),Color("#b6a787"),1)
func set_receipt(job)->void:
	data={"moved":job.bakery_moved,"full":job.signed_level==2,"route":job.route_name(),"wind":job.wind_units(),"condition":floori(job.health),"bonus":job.bell_bonus,"pad":job.pad_tip,"tip":job.rate_tip,"loss":job.decline,"rent":job.HOOD_COST if job.rented else 0,"gross":job.gross,"time":roundi(job.drive_time)}
	show();queue_redraw()
func _draw()->void:
	if data.is_empty():return
	draw_rect(Rect2(4,6,371,538),Color("#132b3550"))
	draw_rect(Rect2(0,0,370,538),Color(PALE));draw_rect(Rect2(0,0,370,7),Color("#597b72"))
	for j in 31:draw_circle(Vector2(6+j*12,537),3.2,Color("#b4a889"))
	line("西湾港务所",23,43,23,Ink,true);line("运  输  签  收  联",224,41,14,Muted)
	ruled(58);line("西风过境",22,107,37,Ink,true)
	line("橄榄风坊   →   北坡磨坊",24,140,18,Muted)
	var col:="#477365" if data.full else "#a26141"
	draw_rect(Rect2(24,157,322,55),Color(col))
	line(("船坞供粉" if data.moved else "蓝窗开炉") if data.full else "绞盘复工",38,194,27,"#fff0c9",true)
	line("余风  %d / 100"%data.wind,199,192,16,"#f9e7c3")
	line(data.route+"　·　行车 %d 秒"%data.time,25,243,18)
	line("囊体 %d%%　%s"%[data.condition,("完整" if data.condition>=90 else ("轻微破损" if data.condition>=60 else "严重损坏"))],25,271,16,Muted)
	ruled(286)
	var rows:=[["基础运费","60"],["余风小费","＋%d"%data.tip],["软垫 / 破损","＋%d  /  −%d"%[data.pad,data.loss]],["寻铃赏金 / 租罩","＋%d  /  −%d"%[data.bonus,data.rent]]]
	for j in rows.size():
		line(rows[j][0],25,313+j*25,16,Muted);line(rows[j][1],196,313+j*25,17,Ink,false,149,HORIZONTAL_ALIGNMENT_RIGHT)
	ruled(401);line("本单净收",25,440,20);line("%d 枚"%(data.gross-data.rent),167,443,32,col,true,179,HORIZONTAL_ALIGNMENT_RIGHT)
	line(("「这袋新粉，给码头送去。」" if data.moved else "「把第一炉面包端出来吧。」") if data.full else "「粮袋起来了，麦子有救了。」",24,476,16,Muted)
	ruled(490);line("E　返港",24,519,18,Ink);line("Tab　留在磨坊",194,519,17,Ink)
