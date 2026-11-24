extends Node3D

const Gate:=Vector2(2.,4.5)
const Width:=3.8
var art:=preload("res://workshop.gd").new()
var night:=preload("res://night_art.gd").new()
var net:Node3D
var crank:Node3D
var gatekeeper:Node3D
var marker:Node3D
var signal_flag:Node3D
var lamps:Array[MeshInstance3D]=[]
var open_amount:=1.
var requested:=0.
var passed:=false
var face:=preload("res://harbour_fonts.gd").body()
var last_hit:=0.
var wave_time:=0.

func _ready()->void:
	position=Vector3(Gate.x,0,Gate.y)
	for side in [-1,1]:
		var pier:=art.group(self,Vector3(side*4.75,-.4,0))
		for i in 4:
			art.box(pier,Vector3(0,.24+i*.46,0),Vector3(1.51-i*.08,.43,1.92-i*.07),"#84908a" if i%2 else "#a8997c")
		art.box(pier,Vector3.UP*1.96,Vector3(1.67,.24,1.91),"#c6b292")
		art.column(pier,Vector3(0,2.,0),2.75)
		var slant:=art.box(pier,Vector3(-side*.40,4.63,0),Vector3(1.8,.39,.84),"#a69b7b")
		slant.rotation.z=side*.21
		var lamp:=night.glow(pier,Vector3(0,2.48,-.66),Vector3(.37,.52,.37),"#83b5ac",.65)
		lamps.append(lamp)
		for z in [-.66,.66]:
			art.beam(pier,Vector3(-side*.16,3.05,z),Vector3(side*.82,2.05,z),.085,"#8a674c")
	crank=art.group(self,Vector3(-4.27,2.14,-1.08))
	art.ring(crank,Vector3.ZERO,.61,.07,"#ac8957").rotation.x=PI/2
	for j in 4:art.box(crank,Vector3.ZERO,Vector3(.07,1.12,.074),"#d8b780").rotation.z=j*PI/4
	gatekeeper=art.courier(self);gatekeeper.position=Vector3(-5.04,1.71,.02);gatekeeper.scale=Vector3.ONE*.78
	preload("res://zephyr_people.gd").new().costume(gatekeeper,"miller")
	net=art.group(self)
	for i in 15:
		var x:=float(i-7)*.55
		art.beam(net,Vector3(x,.13,0),Vector3(x+.46,1.49,0),.022,"#acaa91")
		art.beam(net,Vector3(x+.46,.13,0),Vector3(x,1.49,0),.022,"#8b9b8e")
		if i%2==0:art.ball(net,Vector3(x+.16,1.50,0),Vector3(.21,.19,.19),"#d8ab6a",true)
	art.beam(net,Vector3(-4.32,1.49,0),Vector3(4.32,1.49,0),.045,"#b29b73")
	art.beam(net,Vector3(-4.32,.12,0),Vector3(4.32,.12,0),.045,"#a39171")
	signal_flag=art.group(self,Vector3(-4.73,4.56,0))
	art.beam(signal_flag,Vector3.ZERO,Vector3(0,1.13,0),.048,"#c1a675")
	art.box(signal_flag,Vector3(.35,.9,0),Vector3(.71,.40,.055),"#7ba19a")
	marker=night.label(self,Vector3(-4.5,5.73,0),"旧汊网门",face,"#ffe1a3")
	marker.pixel_size=.011
	for j in 3:
		var buoy:=art.group(self,Vector3(8.7+.8*sin(j),-.16,-3.6+j*3.65))
		art.cyl(buoy,Vector3.UP*.4,.26,.43,.76,"#677d78",10)
		art.cyl(buoy,Vector3.UP*.75,.26,.28,.22,"#e1d2aa",10)
		night.glow(buoy,Vector3.UP*1.08,Vector3(.17,.35,.17),"#d6d9a8",.9)

func call_keeper(boat:Vector2)->bool:
	if Gate.distance_to(boat)>20.:return false
	requested=9.
	return true

func tick(dt:float,boat:Vector2,barge:Vector2,towing:bool,beacon:bool)->void:
	wave_time+=dt;requested=maxf(0.,requested-dt);last_hit=maxf(0.,last_hit-dt)
	var between:=boat.y>Gate.y and barge.y<Gate.y or barge.y>Gate.y and boat.y<Gate.y
	var near:=minf(boat.distance_to(Gate),barge.distance_to(Gate))
	if towing and beacon and boat.distance_to(Gate)<12.:requested=maxf(requested,2.)
	var keep_open:=open_amount>.70 and (near<4.8 or between and absf(boat.x-Gate.x)<6.)
	var raising:=not towing or requested>0. or keep_open
	var last:=open_amount
	open_amount=move_toward(open_amount,1. if raising else 0.,dt*(.85 if raising else .45))
	net.position.y=open_amount*3.92
	crank.rotation.z+=12.*(open_amount-last)
	gatekeeper.get_node("ArmR").rotation.x=-.5+sin(open_amount*11.)*.58
	signal_flag.rotation.z=-.95*(1.-open_amount)
	marker.visible=towing and boat.distance_to(Gate)<18.
	for lamp in lamps:lamp.scale.y=.52+.48*open_amount

func blocks(previous:Vector2,current:Vector2)->bool:
	if open_amount>.73 or absf(current.x-Gate.x)>Width+.35:return false
	return (previous.y-Gate.y)*(current.y-Gate.y)<=0. and absf(current.y-previous.y)>.00001

func clear_piers(p:Vector2)->Vector2:
	for side in [-1.,1.]:
		var center:=Gate+Vector2(side*4.75,0)
		if p.distance_to(center)<1.65:p=center+center.direction_to(p)*1.65
	return p
