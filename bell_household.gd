extends RefCounted

var a:=preload("res://workshop.gd").new()
func dress(actor:Node3D,sailor:=false)->void:
	for n:MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		var key:=String(n.name).trim_prefix("body_").trim_prefix("head_")
		if key in ["B95747","BC5849","E7D8B9"]:n.hide()
		if key=="267A73":n.material_override=a.material("#355b67" if sailor else "#455e79")
		if key=="21454C":n.material_override=a.material("#48545b")
	var hair:=a.ball(actor,Vector3(0,1.71,-.055),Vector3(.79,.57,.67),"#56443c");hair.rotation.x=.16
	for side in [-1.,1.]:
		var lock:=a.ball(actor,Vector3(side*.32,1.57,.055),Vector3(.16,.30,.19),"#554139");lock.rotation.z=side*.13
	if sailor:
		var cap:=a.cyl(actor,Vector3(0,1.91,0),.46,.37,.19,"#315364",18);cap.rotation.z=.11
		a.cyl(actor,Vector3(0,1.805,.02),.395,.42,.082,"#ba9a68")
		a.box(actor,Vector3(0,1.78,.25),Vector3(.57,.052,.32),"#2c4249")
		a.ball(actor,Vector3(.0,1.38,.23),Vector3(.44,.065,.11),"#775949")
	else:
		var headscarf:=a.ball(actor,Vector3(0,1.82,-.03),Vector3(.83,.43,.65),"#ba684d");headscarf.rotation.z=-.06
		var band:=a.ring(actor,Vector3(0,1.79,-.03),.356,.037,"#e0bb80");band.scale.z=.83
		for i in 4:
			var bead:=a.ball(actor,Vector3(.26+.032*sin(i*2.),1.49-.11*i,-.22),Vector3(.19-i*.017,.2,.18),"#594139");bead.rotation.z=.25*sin(i)
		a.ring(actor,Vector3(.26,1.13,-.22),.064,.017,"#c79459")
	# The woven shawl and its bronze clasp stay legible in the dusk close-up.
	for side in [-1.,1.]:
		var panel:=a.box(actor,Vector3(side*.16,1.15,.238),Vector3(.36,.26,.065),"#b26a49" if sailor else "#6a9d9b");panel.rotation.z=side*.31
	a.cyl(actor,Vector3(.09,1.06,.31),.062,.062,.034,"#d9b875").rotation.x=PI/2

func make_letter(parent:Node3D)->Node3D:
	var note:=a.group(parent)
	a.box(note,Vector3.ZERO,Vector3(.48,.32,.026),"#ead8ad")
	for dx in [-1.,1.]:a.beam(note,Vector3(dx*.225,.139,.021),Vector3(0,-.015,.021),.009,"#b99a72")
	a.cyl(note,Vector3(0,-.016,.033),.053,.053,.026,"#ad5443").rotation.x=PI/2
	return note

