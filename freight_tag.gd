extends PanelContainer

var value:=Label.new()
var detail:=Label.new()
var meter:=ProgressBar.new()
var fill:=StyleBoxFlat.new()
var balance_row:=HBoxContainer.new()
var balance_track:=Control.new()
var lateral:=0.0


func set_balance(active:bool,offset:float)->void:
	balance_row.visible=active
	lateral=clampf(offset,-1,1)
	if active: balance_track.queue_redraw()

func draw_balance()->void:
	var width:=balance_track.size.x
	var middle:=balance_track.size.y*0.5
	var left:=3.0
	var span:=width-left*2
	for zone in [[0.0,0.125,"#cc715a"],[0.125,0.30,"#cfac68"],[0.30,0.70,"#58897b"],[0.70,0.875,"#cfac68"],[0.875,1.0,"#cc715a"]]:
		var start:float=zone[0]
		var end:float=zone[1]
		balance_track.draw_rect(Rect2(left+span*start,middle-3,span*(end-start),6),Color(zone[2]))
	balance_track.draw_line(Vector2(width*0.5,middle-5),Vector2(width*0.5,middle+5),Color("#bad2c4"),1)
	var x:=left+span*(lateral+1)*0.5
	balance_track.draw_rect(Rect2(x-3,middle-7,6,14),Color("#173940"))
	balance_track.draw_rect(Rect2(x-1.5,middle-6,3,12),Color("#fff3d8"))


func build(font:Font)->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var panel:=StyleBoxFlat.new()
	panel.bg_color=Color("#11323aeb")
	panel.set_corner_radius_all(8)
	panel.content_margin_left=10
	panel.content_margin_right=10
	panel.content_margin_top=5
	panel.content_margin_bottom=5
	add_theme_stylebox_override("panel",panel)
	var rows:=VBoxContainer.new()
	rows.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation",2)
	add_child(rows)
	for label in [value,detail]:
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",16 if label==value else 14)
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rows.add_child(value)
	rows.add_child(meter)
	rows.add_child(balance_row)
	var caption:=Label.new()
	caption.text="偏移"
	caption.add_theme_font_override("font",font)
	caption.add_theme_font_size_override("font_size",13)
	balance_row.add_child(caption)
	balance_row.add_child(balance_track)
	balance_track.custom_minimum_size=Vector2(96,16)
	balance_track.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	balance_track.draw.connect(draw_balance)
	balance_row.hide()
	rows.add_child(detail)
	meter.show_percentage=false
	meter.custom_minimum_size=Vector2(108,5)
	meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var track:=StyleBoxFlat.new()
	track.bg_color=Color("#466168")
	track.set_corner_radius_all(2)
	fill.set_corner_radius_all(2)
	meter.add_theme_stylebox_override("background",track)
	meter.add_theme_stylebox_override("fill",fill)

func follow(cam:Camera3D,where:Vector3,caption:String,condition:float,signal_text:String,danger:bool,avoid:=Rect2())->void:
	var area:=get_viewport_rect().size
	var p:=cam.unproject_position(where)
	visible=not cam.is_position_behind(where) and Rect2(Vector2.ZERO,area).has_point(p)
	if not visible: return
	value.text="%s  %d%%" % [caption,floori(condition)]
	detail.text=signal_text
	detail.visible=not signal_text.is_empty()
	detail.modulate=Color("#ffae89") if danger else Color("#ffe2a3")
	meter.value=condition
	fill.bg_color=Color("#bd5556") if condition<30 else (Color("#ff8667") if danger or condition<60 else (Color("#e8bf6d") if condition<90 else Color("#75ddbe")))
	reset_size()
	var margin:=Vector2(8,8)
	var limit:=area-size-margin
	position=(p+Vector2(22,-size.y*0.54)).clamp(margin,limit)
	if avoid.has_area() and Rect2(position,size).intersects(avoid):
		var options:=[Vector2(avoid.end.x+5,position.y),Vector2(avoid.position.x-size.x-5,position.y),Vector2(position.x,avoid.position.y-size.y-5),Vector2(position.x,avoid.end.y+5)]
		var shortest:=INF
		for option:Vector2 in options:
			var candidate:=option.clamp(margin,limit)
			var dist:=candidate.distance_squared_to(p)
			if not Rect2(candidate,size).intersects(avoid) and dist<shortest:
				position=candidate
				shortest=dist
