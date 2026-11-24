extends Control

var state
var face:Font
var large:=false
const SIZES:=[Vector2(212,158),Vector2(464,339)]
func dot(p:Vector2)->Vector2:return (p+Vector2(51,39))/Vector2(102,78)*(size-Vector2(22,33))+Vector2(11,26)
func set_large(on:bool)->void:
	large=on;size=SIZES[1 if on else 0];position=Vector2(1254-size.x,21)
	queue_redraw()
func _draw()->void:
	if not is_instance_valid(state):return
	draw_rect(Rect2(Vector2.ZERO,size),Color("#102735ed"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("#8d907d"),false,1)
	draw_string(face,Vector2(10,17),"冥河航图",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#e8d9b4"))
	draw_string(face,Vector2(size.x-92,17),"海螺就绪" if state.pulse_charge>=0.99 else "随航充能",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e8c389") if state.pulse_charge>=0.99 else Color("#9aafa9"))
	if state.pulse_age<1.75:
		var c:=dot(state.pulse_origin);var edge:=dot(state.pulse_origin+Vector2(state.pulse_age*17.0,0))
		draw_arc(c,c.distance_to(edge),0,TAU,48,Color("#81c5b2"),1.0)
	if large and "grain_status" in state and state.grain_status==1:
		route_marks([Vector2(7,-19),Vector2(7,-6),Vector2(2,1),Vector2(2,9),Vector2(-8,24)],Color("#bd9e63"))
		route_marks([Vector2(7,-19),Vector2(18,-6),Vector2(12,6),Vector2(3,16),Vector2(-8,24)],Color("#95b5b0"))
		draw_string(face,dot(Vector2(2,4.5))+Vector2(-59,1),"旧汊网门",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#ead29c"))
		draw_string(face,dot(Vector2(13,6))+Vector2(7,6),"白标外道",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#c8e0d5"))
	var s:float=1.2 if large else 0.8
	for j in 4:
		var a:=dot(state.PORTS[j])
		if state.PORTS[j].distance_to(state.next_harbour())<1:draw_arc(a,9.2*s,0,TAU,18,Color("#eadfba"),1.3)
		draw_circle(a,6.5*s,Color(state.COLORS[j]))
		draw_circle(a,3.1*s,Color("#18313d"))
		if large:draw_string(face,a+Vector2(7,-6),state.NAMES[j],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#fff0cc"))
	for i in state.reefs.size():
		var obs:Vector3=state.reefs[i]
		if state.reveal[i]>0:draw_circle(dot(Vector2(obs.x,obs.z)),3*s,Color("#bd8787"))
	if large or state.pulse_age<1.8:
		for i in state.coins.size():
			if not state.found[i] and state.coin_reveal[i]>0:draw_circle(dot(state.coins[i]),2.4*s,Color("#f7ce68"))
	if "pilots" in state and is_instance_valid(state.pilots) and large and (state.works==2 or state.works==3):
		var trail:Array=[state.PORTS[3]]
		for point:Vector2 in state.pilots.POINTS:trail.append(point+Vector2(0,3.))
		trail.append(state.BERTH);route_marks(trail,Color("#c7a56d"))
	if "works" in state and (state.works>0 or state.harbor_bell):
		var berth:=dot(state.BERTH)
		draw_rect(Rect2(berth-Vector2.ONE*3,Vector2.ONE*6),Color("#ffbd64"))
		if state.next_harbour().distance_to(state.BERTH)<1.:draw_arc(berth,9.2*s,0,TAU,18,Color("#eadfba"),1.3)
		if large:draw_string(face,berth+Vector2(-20,17),"蓝棚木阶",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#ffe0a2"))
	if "lighter" in state and is_instance_valid(state.lighter):
		var lighter_at:=dot(state.lighter.location)
		draw_circle(lighter_at,3.5*s,Color("#de965f"))
		if large:draw_string(face,lighter_at+Vector2(5,12),"粮驳",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#ffd7a5"))
	var at:=dot(state.pos)
	var aim:=Vector2.from_angle(state.heading)
	draw_colored_polygon(PackedVector2Array([at+aim*7.5,at-aim*4+aim.orthogonal()*4,at-aim*4-aim.orthogonal()*4]),Color("#fff0c3"))

func route_marks(points:Array,color:Color)->void:
	for i in points.size()-1:
		draw_dashed_line(dot(points[i]),dot(points[i+1]),color,1.4,4.,true)
