extends Node3D

const WALK_SPEED:=4.1
const LOADED_SPEED:=2.7

const Art=preload("res://workshop.gd")
var art:=Art.new()
var courier:Node3D
var ramp:Node3D
var mark:Node3D
var bay
var feet:=Vector2.ZERO
var facing:=Vector2.RIGHT
var cutaway:=preload("res://porter_cutaway.gd").new()
var held:=false
var carry_path:Array[Vector2]=[]
var path_length:=0.0
var loading:=true
var goal:=Vector2.ZERO
var port_yaw:=0.0
const RUN:=2.7
const WIDTH:=0.90
var upper:=Vector3.ZERO
var toe_y:=0.0
var follow_anchor:=Vector3.ZERO
var gait:=0.0
var jam:=0.0
var turning:=0.0
var turn_target:=0.0

func begin(owner_game,load_in:bool,station:Vector2)->void:
	bay=owner_game
	loading=load_in
	upper=bay.truck.to_global(Vector3(-3.06,1.075,0))
	ramp=art.group(self,upper)
	ramp.rotation.y=bay.heading
	var toe:=ramp.to_global(Vector3(-RUN,0,0))
	var ramp_end:=Vector2(toe.x,toe.z)
	toe_y=bay.land.ground(ramp_end)+0.035
	var rise:=upper.y-toe_y
	var pitch:=atan2(rise,RUN)
	var normal:=Vector3(-sin(pitch),cos(pitch),0)
	var plank:=art.box(ramp,Vector3(-RUN/2,-rise/2,0)-normal*0.07,Vector3(Vector2(RUN,rise).length(),0.14,WIDTH*2),Art.WOOD)
	plank.rotation.z=pitch
	for i in 7:
		var u:float=(i+0.5)/7
		var cleat:=art.box(ramp,Vector3(-RUN*(1-u),-rise*(1-u),0)+normal*0.012,Vector3(0.085,0.025,1.72),Art.SAND)
		cleat.rotation.z=pitch
	var lock:=ramp.to_global(Vector3(0.65,0,0))
	goal=Vector2(lock.x,lock.z) if loading else station
	courier=art.courier(self)
	courier.scale=Vector3.ONE*1.16
	
	art.ring(courier,Vector3.UP*0.07,0.40,0.04,Art.MINT)
	bay.truck.get_node("Driver").hide()
	if not loading:
		bay.freight.reparent(bay,true)
		# The load stays on the bed until the mover takes its handles at the tail.
	feet=ramp_end
	follow_anchor=standing_surface(feet)
	facing=bay.forward_dir()
	port_yaw=bay.heading
	cutaway.collect(bay,courier,bay.truck)
	mark=art.ring(self,standing_surface(goal)+Vector3.UP*0.035,0.48,0.07,Art.GOLD)
	update_actor(0,false)

func source()->Vector2:
	if not loading and bay.freight.global_position.y>0.8 and not held:
		var tail:Vector3=ramp.global_position
		return Vector2(tail.x,tail.z)
	var p:Vector3=bay.freight.global_position
	return Vector2(p.x,p.z)

func ramp_coords(p:Vector2)->Vector2:
	var d:=p-Vector2(upper.x,upper.z)
	var f:Vector2=bay.forward_dir()
	return Vector2(d.dot(f),d.dot(Vector2(-f.y,f.x)))

func on_board(p:Vector2)->bool:
	var q:=ramp_coords(p)
	return q.x>=-RUN and q.x<=1.85 and absf(q.y)<=WIDTH

func standing_surface(p:Vector2)->Vector3:
	if not on_board(p): return bay.land.surface(p)
	var q:=ramp_coords(p)
	return Vector3(p.x,lerpf(toe_y,upper.y,clampf(1+q.x/RUN,0,1)),p.y)

func walkable(p:Vector2)->bool:
	if not bay.land.valid(p,true): return false
	if on_board(p): return true
	var local:Vector3=bay.truck.to_local(bay.land.surface(p))
	return absf(local.z)>1.35 or local.x< -3.1 or local.x>3.45

func can_step(a:Vector2,b:Vector2)->bool:
	if not walkable(b): return false
	return absf(standing_surface(a).y-standing_surface(b).y)<0.21

func at_lock()->bool:
	var q:=ramp_coords(feet)
	return on_board(feet) and q.x>=0.28 and absf(q.y)<0.72

func fits(center:Vector2,angle:float)->bool:
	var long:=1.30 if bay.returning and not bay.wind_job else (0.50 if bay.wind_job else 1.16)
	var side:=Vector2(cos(angle),-sin(angle))*0.52
	var axis:=Vector2(sin(angle),cos(angle))*long
	var u:=side.normalized()
	var v:=axis.normalized()
	for rect:Rect2 in bay.land.solids:
		var half:=rect.size*0.5
		var delta:=rect.get_center()-center
		if absf(delta.x)>half.x+absf(side.x)+absf(axis.x): continue
		if absf(delta.y)>half.y+absf(side.y)+absf(axis.y): continue
		if absf(delta.dot(u))>0.52+half.dot(u.abs()): continue
		if absf(delta.dot(v))>long+half.dot(v.abs()): continue
		return false
	for end in [-1,1]:
		for edge in [-1,1]:
			if not bay.land.valid(center+axis*end+side*edge,true): return false
	return true

func rotate_load()->void:
	if not held or turning>0: return
	var destination:=port_yaw+PI/2
	for i in range(1,13):
		if not fits(feet,lerpf(port_yaw,destination,i/12.0)):
			jam=1.0
			bay.audio.play_cue("bonk")
			return
	turn_target=destination
	turning=0.27
	bay.audio.play_cue("snap")

func move(dt:float,axis:Vector2)->void:
	jam=maxf(0,jam-dt)
	if turning>0:
		turning=maxf(0,turning-dt)
		port_yaw=turn_target-(PI/2)*smoothstep(0,0.27,turning)
		update_actor(dt,false)
		return
	var right:=Vector2(bay.cam.global_basis.x.x,bay.cam.global_basis.x.z).normalized()
	var back:=Vector2(bay.cam.global_basis.z.x,bay.cam.global_basis.z.z).normalized()
	var dir:=right*axis.x+back*axis.y
	var step:=dir.limit_length(1)*dt*(LOADED_SPEED if held else WALK_SPEED)
	var origin:=feet
	if step.length_squared()>0.000001:
		if not try_step(step):
			# Slide along the parked truck even when its heading is diagonal to the world.
			var along:=Vector2.RIGHT
			var local:=ramp_coords(feet)
			if local.x>=-RUN-0.4 and local.x<7.0 and absf(local.y)<2.1:
				along=bay.forward_dir()
			var tangent:=along*step.dot(along)
			try_step(tangent)
			try_step(step-tangent)
	if step.length_squared()>0.00001 and (not held or fits(feet,port_yaw)): facing=dir.normalized()
	update_actor(dt,feet.distance_squared_to(origin)>0.000001)

func try_step(delta:Vector2)->bool:
	if delta.length_squared()<0.00000001: return false
	var dest:=feet+delta
	if not can_step(feet,dest): return false
	if held:
		if not fits(dest,port_yaw):
			jam=0.65
			return false
		path_length+=feet.distance_to(dest)
		carry_path.append(dest)
	feet=dest
	return true

func follow_cargo(dt:float)->Vector2:
	# Walk the same clear corners as the load, leaving enough distance for its handles.
	var body:=Vector2(courier.position.x,courier.position.z)
	var travel:=minf(4.8*dt,maxf(0,path_length-0.78))
	while travel>0 and not carry_path.is_empty():
		var next:=carry_path[0]
		var distance:=body.distance_to(next)
		if distance>travel:
			body=body.move_toward(next,travel)
			path_length-=travel
			break
		body=next
		carry_path.pop_front()
		path_length-=distance
		travel-=distance
	return body

func update_actor(dt:float,walking:bool)->void:
	var body_at:=feet
	var heading:=atan2(facing.x,facing.y)
	if held:
		body_at=follow_cargo(dt)
		courier.rotation.y=rotate_toward(courier.rotation.y,heading,9.0*dt)
	else:
		courier.rotation.y=heading
	courier.position=standing_surface(body_at)
	follow_anchor=follow_anchor.lerp(standing_surface(feet),1.0-exp(-9.0*dt))
	if walking: gait+=dt*(8.5 if held else 11.0)
	for limb in ["LegL","LegR","ArmL","ArmR"]:
		var joint:=courier.get_node_or_null(limb)
		if joint:
			var swing:=sin(gait)*(1 if limb.ends_with("L") else -1)*0.40 if walking else 0.0
			joint.rotation.x=-1.0 if held and limb.begins_with("Arm") else swing
	if held:
		var center:=feet
		bay.freight.global_position=standing_surface(center)+Vector3.UP*(0.45+absf(sin(gait))*0.035)
		bay.freight.rotation.y=port_yaw

func ramp_aligned()->bool:
	return not loading or bay.wind_job or absf(sin(port_yaw-bay.heading))>0.72

func prompt()->String:
	if held and at_lock():
		return "E 固定在货厢" if ramp_aligned() else "Q 转货 · 长边顺车身后可固定"
	if held and on_board(feet): return "沿木坡走到金环 · 可原路退下"
	var q:=ramp_coords(feet)
	if held and q.x>=-RUN and q.x<6.6 and absf(q.y)<2.8:
		return "沿车身绕到车尾，从坡脚上车"
	if jam>0: return "货物卡住了 · 退回宽处再转向"
	if held: return "将货物搬出门，送到木坡"
	return "E 抬起" if feet.distance_to(source())<=2.1 else ("走到货物旁" if loading else "走到车尾取货")

func _clear_grip()->bool:
	for i in range(1,9):
		if not can_step(feet.lerp(source(),(i-1)/8.0),feet.lerp(source(),i/8.0)): return false
	return true

func use()->bool:
	if turning>0: return false
	if not held:
		if feet.distance_to(source())<=2.1 and _clear_grip():
			feet=source()
			carry_path.assign([feet])
			path_length=Vector2(courier.position.x,courier.position.z).distance_to(feet)
			held=true
			port_yaw=bay.freight.rotation.y
			bay.audio.play_cue("grab")
			update_actor(0,false)
		return false
	if at_lock(): return ramp_aligned()
	if on_board(feet): return false
	held=false
	var point:=feet
	bay.freight.global_position=standing_surface(point)+Vector3.UP*0.10
	bay.audio.play_cue("drop")
	return false

func _exit_tree()->void:
	cutaway.clear()
	if is_instance_valid(bay) and is_instance_valid(bay.truck): bay.truck.get_node("Driver").show()
