extends Control

const INK:=Color("#112930f4")
const CREAM:=Color("#fff0d2")
const BRASS:=Color("#e8bd76")
const SEA:=Color("#a3d5ce")
var body:=preload("res://harbour_fonts.gd").body()
var head:=preload("res://harbour_fonts.gd").headings()
var job
var speaker:=""
var line:=""
var heading:=""
var tip:=""
var counter:=""
var cinematic:=false

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func update_view()->void:
	var n=job
	cinematic=n.stage in ["lighting","winch"] or n.lamp_offer
	visible=n.harbor_bell and not n.harbour_charter.visible and not n.chart.large and n.stage in ["sail","winch","lighting"]
	if not visible:return
	heading=n.task.text
	tip=""
	speaker=""
	line=""
	counter=""
	if n.stage=="lighting":
		heading="蓝棚木阶亮灯了"
		if n.ceremony<2.0:speaker="伊娅";line="我来引火。你扶住灯座。"
		elif n.ceremony<3.9:speaker="船夫";line="看，最下面那级台阶也照到了。"
		else:speaker="窑工";line="这下晚班散了，也有地方上岸了。"
	elif n.stage=="winch":
		heading="把陶灯放上石座";tip=n.rig.hint if is_instance_valid(n.rig) else ""
		counter="A D  移吊车     空格  脱钩"
	elif n.stage=="sail":
		var story:bool=n.works<=2 or n.worker_aboard or (n.works==3 and not n.worker_signed)
		if n.harbor_song and n.letter_stage<2 and n.bell_boarding:heading="接过木阶上的家书" if n.letter_stage==0 else "把家书捎给双灯窑"
		elif n.worker_aboard:heading="送晚班窑工回家";counter="船资  8 枚"
		elif n.works==2:heading="把陶灯送回蓝棚木阶";counter="船上  ·  陶灯"
		elif n.works==1:heading="去双灯窑取陶灯"
		elif n.works==0 and n.seats.is_empty() and not n.bread_loaded and not n.fruit_reserved:heading="去双灯窑见窑工"
		elif n.works==3 and not n.worker_signed:heading="去双灯窑接晚班窑工"
		if n.lamp_offer and n.works==0:
			speaker="窑工";line="昨晚我在木阶上踩空了。这盏灯刚烧好，能帮我带过去吗？"
			tip="E  带上陶灯       划走可暂时离开"
		elif n.message_left>0. and not n.note.is_empty():
			var split_at:int=n.note.find("：")
			if split_at>0 and split_at<=5:
				speaker=n.note.left(split_at);line=n.note.substr(split_at+1).trim_prefix("「").trim_suffix("」")
			else:line=n.note
		elif n.action.visible:tip=n.action.text
		if tip=="" and line=="" and n.works==2 and n.pos.distance_to(n.BERTH)>6. and not n.used_echo:tip="空格  吹海螺，看看港钟怎样回应"
		if tip=="" and line=="" and n.time<7. and story:tip="W  划船     A D  掌舵     S  减速"
		if not story and n.deck.visible and counter=="":counter=n.deck.text
		if n.works==3 and n.worker_signed and not n.worker_aboard and n.pos.distance_to(n.BERTH)<5.2 and n.grain_status==0 and n.mirror_age<0.:
			heading="蓝棚木阶"
			counter="已送 %d 班　·　钱袋 %d 枚"%[n.paid_crossings,n.available_funds]
			if line=="" and not n.mirror_built:tip="Q  看共建铭，给外弯装一面照礁镜"
		if n.mirror_age>=0.:heading="外弯的礁石亮了";counter="照礁镜已启用"
	for control in [n.title,n.task,n.deck,n.guide,n.action]:control.hide()
	queue_redraw()

func label(at:Vector2,caption:String,type:Font,px:int,tint:Color)->void:
	draw_string(type,at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,px,tint)

func _draw()->void:
	var left:=Vector2(30,30)
	var w:=maxf(258.,head.get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x+82.)
	draw_rect(Rect2(left,Vector2(w,76)),INK)
	draw_rect(Rect2(left,Vector2(4,76)),BRASS)
	var emblem:=left+Vector2(36,39)
	draw_arc(emblem,17,0,TAU,40,BRASS,1.2,true)
	for i in 3:
		var a:=Vector2(-10+i*7.,4)
		draw_line(emblem+a,emblem+a+Vector2(0,-6-i*2),SEA,2,true)
	draw_polyline(PackedVector2Array([emblem+Vector2(-11,6),emblem+Vector2(-4,9),emblem+Vector2(4,9),emblem+Vector2(11,6)]),BRASS,1.7,true)
	label(left+Vector2(66,25),"白帆港    /    夜渡",body,15,SEA)
	label(left+Vector2(65,58),heading,head,23,CREAM)
	if not counter.is_empty():
		var span:=body.get_string_size(counter,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+26.
		draw_rect(Rect2(left+Vector2(0,80),Vector2(span,31)),INK)
		label(left+Vector2(13,102),counter,body,16,CREAM)
	var bottom:=size.y-48.
	if not tip.is_empty():
		var tw:=body.get_string_size(tip,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x+38.
		var p:=Vector2((size.x-tw)*.5,bottom-35.)
		draw_rect(Rect2(p,Vector2(tw,37)),INK)
		label(p+Vector2(19,25),tip,body,19,CREAM)
		bottom-=49.
	if not line.is_empty():
		var sx:=body.get_string_size(speaker,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+22. if speaker!="" else 0.
		var width:=body.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x+sx+44.
		var p:=Vector2((size.x-width)*.5,bottom-48.)
		draw_rect(Rect2(p,Vector2(width,48)),INK)
		draw_rect(Rect2(p,Vector2(3,48)),BRASS)
		if speaker!="":label(p+Vector2(18,31),speaker,head,18,BRASS)
		label(p+Vector2(20+sx,32),line,body,21,CREAM)
	if not cinematic:
		var hint:="Tab  航图"
		var x:=size.x-133.
		draw_rect(Rect2(x,size.y-48.,106,29),INK)
		label(Vector2(x+11,size.y-28.),hint,body,15,SEA)

