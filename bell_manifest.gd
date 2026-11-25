extends Control
# All geometry here is in the same 1280 × 720 design space as the freight board.
var state:Node
var ink:=Color("#233c3e")
var paper:=Color("#eee0bf")
var gold:=Color("#c09858")
var teal:=Color("#45786e")
var vermilion:=Color("#a45e45")
var font:=preload("res://harbour_fonts.gd").body()
var book:=preload("res://harbour_fonts.gd").headings()
var buttons:Array[Button]=[]
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 2:
		var b:=Button.new();add_child(b);buttons.append(b);b.position=Vector2(72,492+i*46);b.size=Vector2(370,37);b.focus_mode=Control.FOCUS_NONE;b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		for flavor in ["normal","hover","pressed"]:
			var box:=StyleBoxFlat.new();box.bg_color=teal if flavor=="normal" else teal.lightened(.18);box.border_color=Color("#315a54");box.set_border_width_all(1);b.add_theme_stylebox_override(flavor,box)
		b.add_theme_font_override("font",font);b.add_theme_font_size_override("font_size",17);b.add_theme_color_override("font_color",paper);b.pressed.connect(func():state.settle(i==1));b.hide()
func line(at:Vector2,words:String,px:int,c:Color,serif:=false)->void:draw_string(book if serif else font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,px,c)
func seal(center:Vector2,r:float,tint:Color)->void:
	draw_arc(center,r,0,TAU,50,tint,1.6,true);draw_arc(center,r*.87,-1.2,4.2,43,tint,1.,true)
	var profile:=PackedVector2Array()
	for q:Vector2 in [Vector2(-.59,.29),Vector2(-.49,.20),Vector2(-.39,-.23),Vector2(-.27,-.41),Vector2(0,-.48),Vector2(.27,-.41),Vector2(.39,-.23),Vector2(.49,.20),Vector2(.59,.29),Vector2(-.59,.29)]:profile.append(center+q*r)
	draw_polyline(profile,tint,1.7,true);draw_circle(center+Vector2(0,r*.43),r*.075,tint,true);draw_arc(center+Vector2(0,-r*.5),r*.12,PI,TAU,12,tint,1.5,true)
func screen_strip(rect:Rect2)->void:
	draw_rect(rect,Color(.055,.112,.13,.80));draw_rect(Rect2(rect.position,Vector2(3,rect.size.y)),gold)
func refresh()->void:
	var issue:bool=state.stage=="ledger" and not state.pause_panel
	buttons[0].visible=issue;buttons[1].visible=issue and not state.previously_paid
	buttons[0].text="E　收下运费，去码头" if not state.previously_paid else "E　去码头"
	buttons[1].text="Q　留 12 枚给帆匠，缝永久货毡"
	queue_redraw()
func _draw()->void:
	if not is_instance_valid(state):return
	if state.stage=="ledger" and not state.pause_panel:
		var rect:=Rect2(42,100,441,498)
		draw_rect(Rect2(rect.position+Vector2(5,7),rect.size),Color(.08,.13,.11,.28));draw_rect(rect,paper);draw_rect(Rect2(52,110,421,478),gold,false,1.)
		draw_rect(Rect2(52,110,421,9),teal);seal(Vector2(418,166),30.,vermilion)
		line(Vector2(73,151),"西湾港务所   /   迁居签收",15,teal);line(Vector2(72,201),"第一声港钟",38,ink,true)
		draw_line(Vector2(72,221),Vector2(447,221),gold,1.1)
		line(Vector2(74,253),"铸钟山   →   双路岭   →   白帆港",19,ink)
		var grade:String="完整" if state.hp>=90 else ("轻微破损" if state.hp>=60 else "严重损坏")
		line(Vector2(74,289),"铜钟交验    %d / 100    %s"%[roundi(state.hp),grade],17,ink)
		line(Vector2(74,323),"听钟靠岸    "+("领港船与渡工家船" if state.learned else "领港船"),17,ink)
		line(Vector2(74,356),"铸钟山       "+("学徒听见信号，第二篮已落地" if state.blessing else "学徒还在等第二篮的信号"),17,ink)
		draw_line(Vector2(72,377),Vector2(447,377),gold,1.)
		line(Vector2(74,419),"本单运费",20,ink,true);line(Vector2(290,422),("已入账" if state.previously_paid else "%d 枚"%state.fare(state.hp,state.learned,state.rigging_repaired)),27,teal,true)
		line(Vector2(74,457),"港口赠你一处货栈。运粮或送面包到窑口，每单分红 2 枚。",13,ink)
		return
	var header_w:=436. if state.stage=="drive" else 395.
	screen_strip(Rect2(28,22,header_w,81));seal(Vector2(64,62),24.,Color("#e6cd8b"))
	if state.stage=="drive" and not state.pause_panel:
		line(Vector2(362,51),"Tab 路单",14,Color("#dcceaa"))
	for label:Label in [state.ledger,state.controls]:
		if label.text.is_empty():continue
		var px:=label.get_theme_font_size("font_size")
		var width:=minf(1224.,label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x+44.)
		var body:=Rect2((size.x-width)*.5,label.position.y+2.,width,label.size.y-4.)
		draw_rect(body,Color("#162e32ed") if label==state.ledger else Color("#183638d9"))
		if label==state.ledger:
			draw_rect(Rect2(body.position,Vector2(3,body.size.y)),gold)
	if state.stage=="drive":
		var x:=97.;var y:=94.;var width:=header_w-87.
		draw_line(Vector2(x,y),Vector2(x+width,y),Color("#798a7c"),2.)
		draw_line(Vector2(x,y),Vector2(x+width*clampf(state.pos.x/state.END,0.,1.),y),gold,2.)
	if state.stage=="listen" and not state.pause_panel:
		var points:=[Vector2(581,517),Vector2(622,517),Vector2(668,517)]
		for j in 3:
			var tint:=gold if j<state.lesson_hits or state.answer_time>=0. else paper
			var active:bool=state.age<2.2 and absf(state.age-[.16,.53,1.22][j])<(.28 if j!=2 else .61)
			if active:tint=Color("#fff3bd")
			if j==2:draw_line(points[j],points[j]+Vector2(28,0),ink,9.,true);draw_line(points[j],points[j]+Vector2(28,0),tint,5.,true)
			else:draw_circle(points[j],6.,ink,true);draw_circle(points[j],3.8,tint,true)

