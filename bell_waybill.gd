extends Control

var job
var body:=preload("res://harbour_fonts.gd").body()
var heading:=preload("res://harbour_fonts.gd").headings()
var ink:=Color("#2d4646")
var pale:=Color("#e9dabe")
var green:=Color("#426e64")
var red:=Color("#a7573b")
var faded:=Color("#817b68")
var rule:=Color("#b7a787")
const LEFT:=252.0
const RIGHT:=1044.0

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	hide()

func write(at:Vector2,words:String,px:int,tint:Color,serif:=false)->void:
	draw_string(heading if serif else body,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,px,tint)

func map_point(x:float,old:bool)->Vector2:
	var u:=clampf(x/job.END,0.,1.)
	var level:=sin(u*TAU*1.2)*7.+sin(u*TAU*3.7)*3.
	if u>.314 and u<.650:
		var fork:=sin(PI*(u-.314)/(.650-.314))
		level+=fork*(45. if old else -20.)
	return Vector2(LEFT+(RIGHT-LEFT)*u,332.+level)

func _draw()->void:
	if not is_instance_valid(job):return
	draw_rect(Rect2(Vector2.ZERO,size),Color("#112728ae"))
	var page:=Rect2(185,81,910,546)
	draw_rect(Rect2(page.position+Vector2(5,8),page.size),Color("#0c24275b"))
	draw_rect(page,pale);draw_rect(page.grow(-9.),rule,false,1.)
	draw_rect(Rect2(205,105,8,65),green)
	write(Vector2(232,124),"白帆港务所   /   随车路单",17,green)
	write(Vector2(230,166),"第一声港钟",39,ink,true)
	write(Vector2(850,128),"铸钟山   →   白帆港",18,green)
	draw_line(Vector2(224,185),Vector2(1056,185),rule,1.)
	write(Vector2(232,218),"眼下要做的事",16,green)
	write(Vector2(232,254),job.next_task(),25,ink)
	write(Vector2(232,291),"海岸货道",16,green)
	for old in [false,true]:
		var pts:=PackedVector2Array()
		var progress:=PackedVector2Array()
		for j in 121:
			var x:float=j*job.END/120.
			if old and (x<job.land.FORK-8. or x>job.land.JOIN+10.):continue
			var p:=map_point(x,old);pts.append(p)
			var band:=clampi(roundi(x/job.END*100.),0,100)
			if job.driven_sections[band] & (2 if old else 1):progress.append(p)
			elif not progress.is_empty():
				if progress.size()>=2:draw_polyline(progress,green if not old else red,3.,true)
				progress=PackedVector2Array()
		draw_polyline(pts,Color(rule,.55),2.,true)
		if progress.size()>=2:draw_polyline(progress,green if not old else red,3.,true)
	for item in [[0.,false,"铸钟山"],[float(job.land.CAMP),true,"红棚"],[float(job.land.WATCH),true,"旧渡口"],[float(job.coast.HORN),false,"山口"],[float(job.END),false,"白帆港"]]:
		var p:=map_point(item[0],item[1]);draw_circle(p,5.8,pale,true);draw_arc(p,5.8,0,TAU,24,green,2.,true)
		write(p+Vector2(-18,25),item[2],16,ink)
	var here:=map_point(job.pos.x,job.old_road)
	draw_circle(here,9.,red,true);draw_circle(here,3.6,pale,true)
	write(Vector2(658,300),"风脊近路",14,faded)
	draw_line(Vector2(224,406),Vector2(1056,406),rule,1.)
	write(Vector2(232,440),"谁在等你",18,green)
	var home:="学徒等师傅敲钟，好把铜篮放下来。"
	if job.first_worked:home="铜钟上了车，山上的学徒听不见第二声了。" if job.stage not in ["yard","first_drop","call"] else "学徒听见了第一声，放下了第一篮。"
	if job.packed:home="帆匠给了你一枚陶片。山口的陶耳正好缺一块。"
	if job.blessing:home="陶耳把木架的声音传到了对坡。山上的人又能开工了。"
	write(Vector2(232,475),home,19,ink)
	var coast:="白帆港起了雾。船上的人需要听着钟声靠岸。"
	if job.learned:coast="老渡工教了你家里的船号。他儿子在海上，孙女在码头等爸爸。"
	if job.stage in ["ledger","invite"]:coast="渡工和领港船都进港了。女儿想捎一封平安信。" if job.learned else "领港船听见了港钟，已经平安靠岸。"
	write(Vector2(232,511),coast,19,ink)
	draw_line(Vector2(224,547),Vector2(1056,547),rule,1.)
	write(Vector2(232,587),"红点是你的位置。两条路都能到港，沿途可随时掉头。",16,faded)
	write(Vector2(880,588),"Tab / Esc   收起",17,green)

