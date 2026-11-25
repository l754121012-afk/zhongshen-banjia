extends RefCounted

# Longitudinal force stays responsive. Only lateral grip relaxes in a fast corner.
var velocity:=Vector2.ZERO
var steer_axis:=0.
var slip:=0.
var pitch:=0.

func reset()->void:
	velocity=Vector2.ZERO;steer_axis=0.;slip=0.;pitch=0.

func accelerate(dt:float,speed:float,gas:float,top:float,reverse:float,grade:float,loose:float)->float:
	var target:=top*gas if gas>=0. else reverse*gas
	var braking:=speed*gas<0.
	var force:=9.1 if braking else lerpf(2.55,4.35,smoothstep(0.,2.5,absf(speed)))
	if gas==0.:force=.88+loose*.60+absf(speed)*.047
	var next:=move_toward(speed,target,force*dt)
	if absf(speed)>.22 or gas!=0.:
		next=clampf(next-grade*3.3*dt,-reverse,top+1.25)
	pitch=lerpf(pitch,clampf((next-speed)/maxf(dt,.001)*.012,-.079,.046),1.-exp(-dt*5.))
	return next

func steer(dt:float,input:float,speed:float)->float:
	var response:=7.3 if absf(input)>absf(steer_axis) else 10.
	steer_axis=lerpf(steer_axis,input,1.-exp(-dt*response))
	return steer_axis*clampf(absf(speed)*.39,0.,1.)*signf(speed)

func roll(dt:float,forward:Vector2,speed:float,loose:float,air:bool)->Vector2:
	var side:=forward.orthogonal()
	var lateral:=velocity.dot(side)
	var leaning:=smoothstep(3.8,8.6,absf(speed))*absf(steer_axis)
	var grip:=lerpf(10.8,3.7,leaning)*(1.-.33*loose)
	if air:grip=2.25
	lateral*=exp(-dt*grip)
	# A stopped axle has no residual sideways motion, especially after a handoff.
	lateral=clampf(lateral,-absf(speed)*.42,absf(speed)*.42)
	velocity=forward*speed+side*lateral
	slip=absf(lateral)
	return velocity
