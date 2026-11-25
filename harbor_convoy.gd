extends Node3D
var berth:Node3D
var sign:Node3D
var boats:Array[Node3D]=[]
var crews:Array[Node3D]=[]
var art:=preload("res://workshop.gd").new()

func _ready()->void:
	berth=art.group(self,Vector3(2.,.20,-6.8))
	for j in 14:art.box(berth,Vector3((j-6.5)*.39,.04,0),Vector3(.38,.26,3.8),"#ad8965")
	for x in [-2.45,2.45]:
		for z in [-1.61,1.61]:art.beam(berth,Vector3(x,-1.4,z),Vector3(x,.34,z),.15,"#776747")
		art.beam(berth,Vector3(x,.18,1.27),Vector3(x,3.38,1.27),.10,"#926e49")
	sign=art.group(berth,Vector3(0,3.04,1.21))
	art.box(sign,Vector3.ZERO,Vector3(4.86,.73,.15),"#255a56")
	var nameplate:=preload("res://night_art.gd").new().label(sign,Vector3(0,.02,-.13),"西湾搬家　·　共营货栈",preload("res://harbour_fonts.gd").body(),"#ffe6ae")
	nameplate.pixel_size=.012;nameplate.billboard=BaseMaterial3D.BILLBOARD_DISABLED;nameplate.rotation.y=PI
	var reverse:=nameplate.duplicate() as Label3D;sign.add_child(reverse);reverse.position.z=.13;reverse.rotation.y=0.
	for j in 5:
		var crate:=art.group(berth,Vector3(-1.8+j%3*.62,.47,.48+(j/3)*.78))
		art.box(crate,Vector3.ZERO,Vector3(.55,.54,.55),"#bd925e")
		art.box(crate,Vector3.ZERO,Vector3(.11,.56,.56),"#607e73")
	for i in 3:
		var vessel:=art.group(self)
		preload("res://family_skiff.gd").new().build(vessel,[Color("#e8bf7b"),Color("#438f8a"),Color("#c18a55")][i])
		var hand:=art.courier(vessel)
		hand.position=Vector3(-.64,.33,0);hand.scale=Vector3.ONE*.78
		for j in 3:
			var bag:=art.ball(vessel,Vector3(.6+j*.41,.52,.18),Vector3(.55,.47,.52),"#cba56a",true)
			art.ring(bag,Vector3.UP*.32,.22,.034,"#966f41")
		boats.append(vessel);crews.append(hand)
	hide()

func show_return(t:float)->void:
	visible=t>=0.
	if not visible:return
	sign.position.y=lerpf(1.1,3.04,smoothstep(3.3,7.0,t))
	for i in boats.size():
		var u:=smoothstep(i*.88,6.6+i*1.15,t)
		var berth:=Vector3(-8.+i*7.5,0.,i%2*3.1)
		boats[i].position=berth+Vector3(13.+5.*i,0.,27.+8.*i)*(1.-u)
		boats[i].rotation.y=-.9+.85*u
		crews[i].get_node("ArmL").rotation.z=-1.8*u+.29*sin(t*4.+i)*u
