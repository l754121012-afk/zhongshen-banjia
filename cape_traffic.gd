extends Node3D
const Art=preload("res://workshop.gd")
var art:=Art.new()
var casks:Array[Node3D]=[]
var cleared:Array[bool]=[]
var time:=0.0
var land

func build(map)->void:
	land=map
	for x:float in [77.0,128.0]:
		var n:=art.group(self,Vector3(x,0,0))
		var drum:=art.cyl(n,Vector3.ZERO,0.76,0.76,1.48,Art.WOOD)
		drum.rotation.z=PI/2
		for off in [-0.60,0.60]:
			var hoop:=art.ring(n,Vector3(off,0,0),0.76,0.055,Art.GOLD)
			hoop.rotation.z=PI/2
		casks.append(n)
		cleared.append(false)
		land.sign_at(Vector2(x-10,3.7),"酒桶横穿")
		land.sign_at(Vector2(x+10,3.7),"酒桶横穿")

func tick(bay,dt:float)->void:
	time+=dt
	for i in casks.size():
		var node:=casks[i]
		var frequency:=0.66+i*0.13
		var phase:=time*frequency+i*2.4
		var travel:=Vector2(0,5) if i==0 else Vector2(-5.8,4)
		var center:=Vector2(77 if i==0 else 128,0)+travel*sin(phase)
		var cask_velocity:=travel*frequency*cos(phase)
		var z:=center.y
		node.position=land.surface(center)+Vector3.UP*0.76
		node.rotation=Vector3(0,-travel.angle()+PI/2,0)
		node.rotate_object_local(Vector3.RIGHT,sin(phase)*travel.length()/0.76)
		var dx:=absf(bay.pos.x-center.x)
		if dx>7.5: cleared[i]=false
		if bay.stage!="drive" or cleared[i] or dx>2.65 or absf(bay.pos.y-z)>1.52: continue
		if bay.altitude-land.ground(bay.pos)>0.90: continue
		cleared[i]=true
		var relative:Vector2=bay.forward_dir()*bay.speed-cask_velocity
		bay.warn_damage("酒桶撞击",clampf(1.0+relative.length()*1.25,1.0,21.0))
		bay.load_velocity.y+=2.4 if bay.pos.y>=z else -2.4
		bay.speed*=0.47
		bay.audio.play_cue("bonk")
