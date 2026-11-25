extends Node3D

var art:=preload("res://workshop.gd").new()
var craft:=preload("res://coastal_craft.gd").new()
var potter:Node3D
var buyer:Node3D
var watch_lamp:Node3D
var watch_wick:MeshInstance3D
var watch_fire:=StandardMaterial3D.new()
var shore_answer:=AudioStreamPlayer3D.new()
var turning:Node3D
var tray:Node3D
var clay:Node3D
var hot_coals:Array[Node3D]=[]

func build(lamps,step:int,waiting:bool)->void:
	for z in [-2.45,2.45]:
		for j in 9:
			var a:=PI*j/8.
			var brick:=art.box(self,Vector3(7.65,2.28+.82*sin(a),z+.70*cos(a)),Vector3(.28,.24,.34),"#c2865d" if j%2 else "#ad7351")
			brick.rotation.x=-a
		for j in 4:
			hot_coals.append(art.ball(self,Vector3(7.57,1.99,z+(j-1.5)*.24),Vector3(.27,.14,.21),"#e7a167",true))
	tray=art.group(self,Vector3(4.40,1.70,-.94))
	art.box(tray,Vector3.UP*.59,Vector3(1.78,.15,.79),"#c49464")
	for x in [-.72,.72]:
		for z in [-.28,.28]:art.beam(tray,Vector3(x,0,z),Vector3(x,.57,z),.053,"#775842")
	clay=lamps.lantern(tray,Vector3(-.25,.66,0));clay.scale=Vector3.ONE*.77;clay.visible=step<=1
	for j in 2:
		art.cyl(tray,Vector3(.52,.78,.16-j*.30),.12,.14,.24,"#a96649",12)
	turning=art.group(self,Vector3(5.31,1.68,1.02))
	art.cyl(turning,Vector3.UP*.32,.30,.39,.64,"#84684e",10)
	art.cyl(turning,Vector3.UP*.72,.52,.53,.14,"#bc996e",18)
	art.jar(turning,Vector3.UP*.82,.60,"#bd825b")
	potter=art.courier(self);preload("res://zephyr_people.gd").new().costume(potter,"miller")
	potter.position=Vector3(5.97,1.68,1.34);potter.rotation.y=-PI/2;potter.scale=Vector3.ONE*.82
	buyer=art.courier(self);preload("res://zephyr_people.gd").new().costume(buyer,"miller")
	buyer.position=Vector3(1.66,.39,.48);buyer.rotation.y=-PI*.57;buyer.scale=Vector3.ONE*.82;buyer.visible=waiting
	var hand:=buyer.get_node("ArmR") as Node3D
	watch_lamp=art.group(hand,Vector3(.02,-.49,.08));watch_lamp.scale=Vector3.ONE*.86
	art.cyl(watch_lamp,Vector3.DOWN*.42,.18,.22,.085,"#8c6a49",10)
	art.cyl(watch_lamp,Vector3.DOWN*.09,.22,.14,.075,"#ae8853",10)
	for side in [-1.,1.]:
		art.beam(watch_lamp,Vector3(side*.18,-.41,0),Vector3(side*.17,-.10,0),.018,"#b29362")
		art.beam(watch_lamp,Vector3(side*.15,-.10,0),Vector3(side*.04,.10,0),.022,"#88724c")
	watch_wick=art.ball(watch_lamp,Vector3(0,-.265,0),Vector3(.28,.38,.28),"#ffcc7d")
	watch_wick.material_override=watch_fire;watch_fire.albedo_color=Color("#e1a563")
	watch_fire.emission_enabled=true;watch_fire.emission=Color("#ffc06e")
	watch_lamp.hide()
	buyer.add_child(shore_answer);shore_answer.stream=preload("res://audio/blue_quay_clay.wav")
	shore_answer.unit_size=18.;shore_answer.max_distance=85.;shore_answer.volume_db=-6.
	craft.cloth(self,Vector3(5.65,4.59,-2.20),3.1,"#aa6953")
	for x in [4.23,7.04]:art.beam(self,Vector3(x,.91,-2.06),Vector3(x,4.65,-2.06),.07,"#796349")

func tick(t:float,near:bool)->void:
	turning.rotation.y=fmod(t*.72,TAU)
	potter.get_node("ArmL").rotation.x=-.68-.16*sin(t*2.)
	potter.get_node("ArmR").rotation.x=-.82+.13*sin(t*2.)
	if buyer.visible:buyer.get_node("ArmR").rotation.x=-.36-(.55+.22*sin(t*3.4) if near else 0.)
	for i in hot_coals.size():hot_coals[i].scale.y=.15+.04*sin(t*5.+i)

func ferry_signal(t:float,reply_age:float,waiting:bool)->void:
	watch_lamp.visible=waiting
	if not waiting:return
	var wave:=.5+.5*sin(t*1.9)
	var acknowledged:=1.-smoothstep(.9,3.4,reply_age)
	var arm:=buyer.get_node("ArmR") as Node3D
	arm.rotation.x=-1.85-.34*wave-.53*acknowledged
	arm.rotation.z=.91+.19*sin(t*2.4)
	watch_lamp.global_basis=Basis.IDENTITY.scaled(Vector3.ONE*.76)
	watch_fire.emission_energy_multiplier=1.18+.5*wave+1.85*acknowledged
