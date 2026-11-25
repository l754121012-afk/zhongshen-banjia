extends "res://world_pin.gd"
# Scene cues stay beside the thing the player needs to see.
var state
var shade:=ColorRect.new()
var veil:=ShaderMaterial.new()
var useful:=false
var fork_window:=false
var fork_wait:=0.
var spotlight:=0.0
var intensity:=0.0
var focus_uv:=Vector2(.5,.5)

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(shade);shade.show_behind_parent=true
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	veil.shader=preload("res://bell_focus.gdshader");shade.material=veil

func mark(point:Vector3,label:String,power:=0.0,side_job:=false)->void:
	target=point;words=label;useful=true;optional=side_job;spotlight=power

func tick(dt:float)->void:
	var g=state
	beside=g.stage in ["call","arrival","listen","silence","first_drop","mountain","ring"]
	useful=false;optional=false;spotlight=0.
	var near_fork:bool=g.stage=="drive" and not g.pause_panel and g.pos.x>g.land.FORK-32. and g.pos.x<g.land.FORK+51. and cos(g.yaw)>.24
	if not near_fork:fork_wait=0.
	elif absf(g.speed)<3.1:fork_wait+=dt
	else:fork_wait=maxf(0.,fork_wait-dt*1.6)
	fork_window=near_fork and g.catch_left<=0. and fork_wait>1.5
	if not g.pause_panel:
		match g.stage:
			"opening":
				spotlight=0.
			"call":mark(g.freight.global_position+Vector3.UP*1.4,"空格  敲钟",.44)
			"first_drop":mark(g.lift.loads[0].global_position+Vector3.UP*.55,"学徒放篮了",.38)
			"silence":mark(g.lift.loads[1].global_position+Vector3.UP*.5,"这一篮还吊着",.39)
			"mountain":mark(g.lift.loads[1].global_position+Vector3.UP*.52,"学徒听见了",.37)
			"yard":
				if not g.carried:mark(g.freight.global_position+Vector3.UP*1.2,"E  抬起铜钟" if g.porter.distance_to(Vector2(-3,-5))<2.7 else "走到钟旁")
				elif not g.gate_passed:mark(g.land.surface(Vector2(-.5,-5.))+Vector3.UP*1.8,"穿过窄门" if g.depot_turned else "Q  转动钟杠")
				elif absf(g.porter.y)>1.45 or g.porter.x<1.:mark(g.land.surface(Vector2(1.1,0))+.28*Vector3.UP,"从这里上木坡")
				else:mark(g.truck.global_position+Vector3(-2.8,1.45,0),"E  放上车" if g.porter.x>=3.6 else "走到车尾")
			"drive":
				var rock_at:int=g.encounters.active_rock()
				if rock_at>=0:
					mark(g.encounters.rocks[rock_at].global_position+Vector3.UP*.9,"落石",0.)
				elif g.near(g.land.road(g.END),50.):mark(g.land.harbor_frame.global_position+Vector3.UP*3.,"慢慢停在钟架旁")
				elif g.packed and not g.blessing and g.near(g.land.road(g.coast.HORN,false,6.6),52.):
					mark(g.coast.jar.global_position+Vector3.UP,"E  下车还陶片" if g.near(g.land.road(g.coast.HORN,false,6.6),18.) and absf(g.speed)<=3.2 else "山口的陶耳",0.,true)
				elif not g.learned and g.near(g.land.road(g.land.WATCH,true,8.6),48.):
					mark(g.land.elder.global_position+Vector3.UP*2.,"E  听渡工敲杯" if g.near(g.land.road(g.land.WATCH,true,8.6),18.) and absf(g.speed)<=3.2 else "路边有位渡工",0.,true)
				elif not g.packed and g.near(g.land.road(g.land.CAMP,true,10.),43.):
					mark(g.land.stations.camp.global_position+Vector3.UP*3.,"E  问问帆匠" if g.near(g.land.road(g.land.CAMP,true,10.),16.) and absf(g.speed)<=3.2 else "帆匠的红棚",0.,true)
				elif g.land.road_dist(g.pos)>11. or (g.speed>1. and cos(g.yaw)<-.35 and not g.old_road):
					var path:Vector2=g.land.road(clampf(g.pos.x+12.,0.,g.END),g.old_road)
					mark(g.land.surface(path)+Vector3.UP*.65,"回到港口方向")
			"crane":
				if is_instance_valid(g.rig) and g.rig.phase=="carry":
					mark(g.rig.pad+Vector3.UP*.20,"落在软垫中央")
			"altar":mark(g.coast.jar.global_position+Vector3.UP,"E  装回陶片" if g.close_to_ear() else "把陶片带到这里",.16)
			"dock":mark(g.land.harbor_frame.global_position+Vector3.UP*2.5,"E  请铜匠修钟" if g.hp<30. else "E  挂上吊索")
			"ring":mark(g.freight.global_position+Vector3.UP*.85,"E  敲响港钟",.26)
			"arrival":
				if g.age>5. and g.age<9.8 and g.learned:mark(g.coast.daughter.global_position+Vector3.UP*1.75,"渡工的女儿",.22)
	intensity=lerpf(intensity,spotlight,1.-exp(-dt*7.))
	if (useful or spotlight>.01) and not g.cam.is_position_behind(target):
		var projected:Vector2=g.cam.unproject_position(target)
		focus_uv=focus_uv.lerp(projected/size.max(Vector2.ONE),1.-exp(-dt*12.))
	veil.set_shader_parameter("focus",focus_uv);veil.set_shader_parameter("shade",intensity)
	shade.visible=intensity>.01
	queue_redraw()

func fork_card(end:Vector2,x:float,label:String,color:Color)->void:
	var rect:=Rect2(x-94,165,188,34)
	draw_line(rect.get_center()+Vector2(0,16),end,color,1.4,true)
	draw_circle(end,3.,color,true);draw_rect(rect,ink)
	draw_rect(Rect2(rect.position,Vector2(4,rect.size.y)),color)
	draw_string(font,rect.position+Vector2(7,23),label,HORIZONTAL_ALIGNMENT_CENTER,174,17,ivory)

func draw_fork()->void:
	var g=state
	var x:float=maxf(g.land.FORK+62.,g.pos.x+24.)
	var l:Vector3=g.land.surface(g.land.road(x,false))+Vector3.UP*.3
	var r:Vector3=g.land.surface(g.land.road(x,true))+Vector3.UP*.3
	if g.cam.is_position_behind(l) or g.cam.is_position_behind(r):return
	var left:Vector2=g.cam.unproject_position(l).clamp(Vector2(48,210),size-Vector2(48,200))
	var right:Vector2=g.cam.unproject_position(r).clamp(Vector2(48,210),size-Vector2(48,200))
	if absf(left.x-right.x)<6.:return
	var mid:=clampf((left.x+right.x)*.5,231.,size.x-231.)
	var spacing:=minf(212.,maxf(108.,absf(left.x-right.x)*.48))
	var direction:=signf(right.x-left.x)
	fork_card(left,mid-spacing*direction,"风脊  ·  抄近路",Color("#d7cba6"))
	fork_card(right,mid+spacing*direction,"旧渡路  ·  找帆匠",Color("#e9a17c"))

func _draw()->void:
	if fork_window:draw_fork()
	if useful and is_instance_valid(state.cam):draw_pin(state.cam)
