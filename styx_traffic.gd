extends Node3D

const Art=preload("res://workshop.gd")
const Night=preload("res://night_art.gd")
var art:=Art.new()
var design:=Night.new()
var traders:Array[Node3D]=[]
var track:Array[float]=[0.72,3.81]
var hold:Array[float]=[0.0,0.0]
var lamps:Array[Node3D]=[]
var wake:Array[Node3D]=[]
var north:Node3D
var light_root:Node3D
var guide_marks:Array[Node3D]=[]
var active_beacon:=false
var posted:Array[Node3D]=[]
var clock:=0.0
func _ready()->void:
	for i in 2:
		var hull:=art.group(self)
		hull.scale=Vector3.ONE*(0.92+i*0.1)
		art.ball(hull,Vector3(0,-0.1,0),Vector3(5.8,0.92,2.2),"#514454",true)
		art.box(hull,Vector3.UP*0.24,Vector3(4.3,0.16,1.9),"#916e52")
		for side in [-1,1]:art.beam(hull,Vector3(-2.12,0.43,side*0.95),Vector3(2.15,0.43,side*0.95),0.070,Night.GILT)
		for j in 4:
			var jar:=art.group(hull,Vector3(-0.65+(j%2)*0.76,0.34,(j/2-0.5)*0.70))
			art.jar(jar,Vector3.ZERO,0.91+(j%2)*0.19,"#935f53" if i==0 else "#679897")
		var runner:=design.ghost(hull,3,"#97aaa6");runner.position=Vector3(-1.69,0.3,0);runner.scale=Vector3.ONE*0.78
		art.beam(hull,Vector3(1.71,0.38,0),Vector3(1.71,2.45,0),0.085,Night.COPPER)
		var signal_lamp:=design.glow(hull,Vector3(1.71,2.38,0),Vector3.ONE*0.49,"#eab16c",1.35);lamps.append(signal_lamp)
		var pennant:=art.box(hull,Vector3(1.11,1.81,0),Vector3(1.16,0.44,0.06),"#bb7159");pennant.rotation.z=-0.16
		traders.append(hull)
		var ripple:=art.group(hull)
		for side in [-1,1]:
			art.beam(ripple,Vector3(-1.25,-0.37,side*1.08),Vector3(-4.2,-0.38,side*1.86),0.047,"#86a6aa")
		wake.append(ripple)
	for j in 5:
		var ring:=art.ring(self,Vector3.ZERO,0.29,0.046,"#b0dbcb");ring.material_override=design.emission("#a8d8c6",0.85);ring.hide();guide_marks.append(ring)
	north=art.group(self,Vector3(-27,0,-46))
	art.ball(north,Vector3(0,-0.75,0),Vector3(16,8,11),"#4a5669",true)
	art.cyl(north,Vector3.UP*5.6,1.70,1.25,6.4,"#a1a3a0",12)
	art.cyl(north,Vector3.UP*9.3,1.24,1.06,1.2,"#986d68",12)
	art.cyl(north,Vector3.UP*10.7,1.08,0.93,1.6,"#b8b5aa",12)
	art.cyl(north,Vector3.UP*11.74,1.25,1.23,0.32,Night.COPPER,12)
	for j in 6:
		var a:=j*TAU/6
		art.beam(north,Vector3(cos(a),11.83,sin(a)),Vector3(cos(a),13.87,sin(a)),0.068,Night.OBSIDIAN)
	art.cyl(north,Vector3.UP*14.09,1.45,0.05,0.99,"#8e6965",12)
	light_root=art.group(north,Vector3.UP*12.65)
	design.glow(light_root,Vector3.ZERO,Vector3(1.11,1.42,1.11),"#ffdf97",1.97)
	var mat:=StandardMaterial3D.new();mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color(1,.87,.56,.067);mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	for side in [-1,1]:
		var ray:=art.cyl(light_root,Vector3(side*6,0,0),1.67,0.11,12,Night.GILT,16)
		ray.rotation.z=side*PI/2;ray.material_override=mat;ray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	light_root.visible=active_beacon
func set_beacon(on:bool)->void:
	active_beacon=on
	if is_instance_valid(light_root):light_root.visible=on
func whistle(origin:Vector2)->bool:
	var responded:=false
	for i in 2:
		var ship:=traders[i];var p:=Vector2(ship.position.x,ship.position.z)
		if origin.distance_to(p)<17.5:
			hold[i]=3.4;responded=true
	return responded
func route(i:int,t:float)->Vector2:
	if i==0:return Vector2(1.8+cos(t)*12,7.1+sin(t)*4.7)
	return Vector2(-2.8+cos(t)*6.3,-5.0+sin(t)*9.1)
func tick(dt:float,position2:Vector2,destination:Vector2,lockout:bool)->bool:
	clock+=dt;light_root.rotation.y=clock*0.38
	var collision:=false
	for i in 2:
		hold[i]=maxf(0,hold[i]-dt)
		track[i]+=dt*(0.29 if i==0 else 0.25)*(0.05 if hold[i]>0 else 1.0)
		var at:=route(i,track[i]);var dir:=at.direction_to(route(i,track[i]+0.02));var n:=traders[i]
		n.position=Vector3(at.x,0.035*sin(clock*2+i),at.y);n.rotation.y=-dir.angle()
		wake[i].visible=hold[i]<=0;lamps[i].scale=Vector3.ONE*(0.52+0.09*sin(clock*5.8)) if at.distance_to(position2)<12 else Vector3.ONE*0.45
		if not lockout and hold[i]<=0 and at.distance_to(position2)<2.65:collision=true;hold[i]=2.6
	var dest:=destination-position2;var aim:=dest.normalized()
	for j in guide_marks.size():
		var u:float=4.6+j*2.3+fposmod(clock*0.62,1.0)
		var m:=guide_marks[j];m.visible=active_beacon and dest.length()>u+1.2
		if m.visible:
			var at:=position2+aim*u
			m.position=Vector3(at.x,-0.47,at.y);m.scale=Vector3.ONE*(0.67+0.09*sin(clock*3-j))
	return collision
