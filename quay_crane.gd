extends Node3D
const Art=preload("res://workshop.gd")
var art:=Art.new()
var bay
var start:Vector3
var pad:Vector3
var axis:Vector3
var length:=0.0
var trolley:=0.0
var velocity:=0.0
var swing:=0.0
var swing_v:=0.0
var height:=2.7
var fall_velocity:=Vector3.ZERO
var rng:=RandomNumberGenerator.new()
var local_weather:=Callable()
var gust_wait:=1.6
var gust_left:=0.0
var gust_duration:=1.0
var gust_force:=0.0
var streamer:Node3D
var damage:=0.0
var contact_time:=0.0
var cushion:Node3D
var cushion_dust:Array[Node3D]=[]
var contact_ring:MeshInstance3D
var time:=0.0
var phase:="lift"
var rope:MeshInstance3D
var slider:Node3D
var shadow:MeshInstance3D
var gentle:=false
const CORE:=0.42
var impact:=0.0
var alignment:=0.0
var hint:="吊索起货"

func begin(game,destination:Vector2)->void:
	bay=game
	bay.freight.reparent(bay,true)
	start=bay.freight.global_position
	pad=bay.land.surface(destination)+Vector3.UP*0.16
	var span:=Vector3(pad.x-start.x,0,pad.z-start.z)
	length=span.length()
	axis=span.normalized() if length>0.01 else Vector3.RIGHT
	var overhead:=Vector3.UP*5.7
	for site:Vector3 in [start-axis*2.4,pad+axis*2.4]:
		var base:=Vector3(site.x,pad.y,site.z)
		var lateral:=axis.cross(Vector3.UP)*2.05
		for side in [-1,1]:
			var foot:Vector3=base+lateral*side
			art.beam(self,foot,foot+overhead,0.10,Art.TEAL)
		art.beam(self,base-lateral+overhead,base+lateral+overhead,0.11,Art.GOLD)
	art.beam(self,Vector3(start.x,pad.y,start.z)-axis*2.4+overhead,pad+axis*2.4+overhead,0.14,Art.WOOD)
	slider=art.group(self)
	art.box(slider,Vector3.ZERO,Vector3(0.82,0.45,0.64),Art.GOLD)
	rope=art.cyl(self,Vector3.ZERO,0.045,0.045,1.0,Art.DARK)
	art.cyl(self,pad-Vector3.UP*0.055,1.22,1.22,0.11,Art.SAND,32)
	cushion=art.group(self,pad+Vector3.UP*0.022)
	art.cyl(cushion,Vector3.UP*0.038,CORE,CORE,0.096,Art.MINT,32)
	for side in [-1,1]:
		for j in 4:art.box(cushion,Vector3(side*(CORE-0.08),0.082,(j-1.5)*0.107),Vector3(0.044,0.018,0.067),Art.CREAM)
	art.ring(self,pad+Vector3.UP*0.02,1.14,0.04,Art.GOLD)
	streamer=art.group(slider,Vector3.UP*0.45)
	art.box(streamer,Vector3(0.51,0,0),Vector3(1.02,0.16,0.06),Art.RED)
	schedule_gust()
	shadow=art.cyl(self,pad,0.36,0.36,0.035,Art.TEAL)
	update_geometry(start)

func update_geometry(p:Vector3)->void:
	bay.freight.global_position=p
	slider.position=Vector3(start.x,pad.y+5.7,start.z)+axis*trolley
	var hook:=p+Vector3.UP*(1.45 if not bay.wind_job else 1.13)
	rope.position=(hook+slider.position)*0.5
	rope.scale.y=hook.distance_to(slider.position)
	rope.quaternion=Quaternion(Vector3.UP,(slider.position-hook).normalized())
	shadow.position=Vector3(p.x,pad.y+0.05,p.z)

func schedule_gust()->void:
	gust_wait=rng.randf_range(1.4,3.1)
	gust_duration=rng.randf_range(0.85,1.45)
	gust_force=rng.randf_range(4.8,7.0)*(-1 if rng.randi()%2 else 1)

func release()->void:
	if phase!="carry": return
	phase="fall"
	fall_velocity=axis*(velocity+swing_v)
	rope.hide()
	bay.audio.play_cue("snap")
	hint="已脱钩"

func tick(dt:float,steer:float)->bool:
	time+=dt
	if phase=="lift":
		update_geometry(start.lerp(Vector3(start.x,pad.y+height,start.z),smoothstep(0,0.72,time)))
		if time>=0.72: phase="carry"
		return false
	if phase=="fall":
		fall_velocity.y-=9.8*dt
		var p:Vector3=bay.freight.global_position+fall_velocity*dt
		var floor_y:float=bay.land.ground(Vector2(p.x,p.z))+0.16
		if p.y<=floor_y:
			p.y=floor_y
			update_geometry(p)
			alignment=Vector2(p.x-pad.x,p.z-pad.z).length()
			gentle=alignment<=CORE
			impact=absf(fall_velocity.y)
			damage=0.0 if gentle else minf(55,2.5+(alignment-CORE)*12)
			phase="landed"
			contact_ring=art.ring(self,p+Vector3.UP*0.12,0.46,0.048,Art.MINT if gentle else Art.RED)
			for i in 7:
				var dust:=art.ball(self,p+Vector3.UP*0.07,Vector3.ONE*0.10,Art.SAND if not gentle else Art.MINT,true)
				cushion_dust.append(dust)
			hint="正中软垫 · 无损" if gentle else "硬地冲击 −%.1f" % damage
			bay.audio.play_cue("load" if gentle else "bonk")
			return false
		update_geometry(p)
		return false
	if phase=="landed":
		contact_time+=dt
		var u:=clampf(contact_time/0.58,0,1)
		if gentle:cushion.scale=Vector3(1+0.16*sin(PI*u),1-0.54*sin(PI*u),1+0.16*sin(PI*u))
		for j in cushion_dust.size():
			var a:=j*TAU/7;var d:=(0.20+u*(0.54 if gentle else 1.22))
			var origin:Vector3=contact_ring.position
			cushion_dust[j].position=origin+Vector3(cos(a)*d,sin(PI*u)*(.18 if gentle else .55),sin(a)*d)
			cushion_dust[j].scale=Vector3.ONE*maxf(.004,.12*(1-u))
		contact_ring.scale=Vector3.ONE*(1+0.65*smoothstep(0,0.5,contact_time))
		return contact_time>=0.60
	if phase!="carry": return false
	var wind:=0.0
	if local_weather.is_valid():
		var outlook:Vector3=local_weather.call(axis,pad)
		wind=outlook.x;gust_wait=outlook.y;gust_force=outlook.z
	else:
		gust_wait-=dt
		if gust_wait<=0:
			gust_left+=dt
			wind=gust_force*sin(PI*clampf(gust_left/gust_duration,0,1))
			if gust_left>=gust_duration:
				gust_left=0
				schedule_gust()
	var direction:=axis*signf(gust_force)
	streamer.rotation.y=atan2(-direction.z,direction.x)
	streamer.rotation.z=-0.85 if gust_wait>0.65 else 0.09*sin(time*13)
	var previous:=velocity
	velocity=move_toward(velocity,steer*3.7,dt*(6.8 if steer!=0 else 8.0))
	var next:=clampf(trolley+velocity*dt,-1.9,length+1.85)
	if is_equal_approx(next,trolley): velocity=0.0
	trolley=next
	swing_v+=-(velocity-previous)*0.65
	swing_v+=(-swing*7.9-swing_v*1.85+wind)*dt
	swing+=swing_v*dt
	var p:=Vector3(start.x,pad.y+height,start.z)+axis*(trolley+swing)
	bay.freight.rotation.z=swing*0.19
	update_geometry(p)
	var cue:="风歇"
	if gust_wait<=0.65: cue=("阵风将至" if gust_wait>0 else "阵风")+" "+("→" if gust_force>0 else "←")
	hint=cue+"  ·  看影子，空格脱钩"
	return false