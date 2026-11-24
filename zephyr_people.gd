extends RefCounted
const Art=preload("res://workshop.gd")
const Bay=preload("res://tide_art.gd")
var a:=Art.new()
var b:=Bay.new()
var oven:Node3D
var embers:Array[MeshInstance3D]=[]
var bread_tray:Node3D
var baker:Node3D
var dough:Node3D
var blower:Node3D
var lamp:OmniLight3D
var intake:Node3D
var couriers:Array[Node3D]=[]
var flock:Array[Node3D]=[]
var apron_sign:Label3D
var bakery_awn:Node3D
var fog:MeshInstance3D
var mill_stones:Array[Node3D]=[]
var seal:Node3D
var rope:MeshInstance3D
var grain:Node3D
func costume(actor:Node3D,role:String)->void:
	var colors:Dictionary
	if role=="miller":colors={"267A73":"#6f7688","21454C":"#573f40","B95747":"#916442","BC5849":"#987355","E7D8B9":"#dfcbae"}
	elif role=="baker":colors={"267A73":"#8c5b44","B95747":"#ddd2ae","BC5849":"#d3c7a5","21454C":"#69513e"}
	else:colors={"267A73":"#71856e","B95747":"#9eaa87","BC5849":"#8a9b7b","21454C":"#655c4c"}
	for part:MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		var key:=String(part.name).trim_prefix("body_").trim_prefix("head_")
		if colors.has(key):part.material_override=a.material(colors[key])
	if role=="miller":
		var hat:=a.cyl(actor,Vector3(0,1.76,.02),.44,.46,.082,"#c7ab73",16);hat.rotation.z=-.08
		a.cyl(actor,Vector3(0,1.88,.02),.34,.26,.20,"#d5b87a",16)
		a.cyl(actor,Vector3(0,1.822,.02),.345,.329,.065,"#795b64",16)
		for j in 3:
			var stalk:=a.ball(actor,Vector3(-.26-j*.07,1.92+j*.052,.11),Vector3(.18,.073,.085),"#a0a785",true);stalk.rotation.z=-.45
		a.box(actor,Vector3(.11,.99,.236),Vector3(.38,.63,.062),"#d5b789")
		a.box(actor,Vector3(.13,.80,.277),Vector3(.25,.11,.032),"#ab805e")
	elif role=="baker":
		a.cyl(actor,Vector3(0,1.84,.00),.34,.32,.25,"#e1d7b8",12)
		for j in 6:
			var ang:=TAU*j/6;a.ball(actor,Vector3(.19*cos(ang),1.99,.16*sin(ang)),Vector3(.39,.28,.34),"#ece4cf",true)
		a.box(actor,Vector3(0,.93,.269),Vector3(.49,.75,.071),"#dfd3b4")
		a.box(actor,Vector3(0,1.05,.32),Vector3(.45,.08,.039),"#b89b7b")
	else:
		a.ball(actor,Vector3(0,1.72,-.02),Vector3(.68,.37,.69),"#9bb395",true)
func loaf(p:Node3D,v:Vector3)->Node3D:
	var n:=a.group(p,v)
	a.ball(n,Vector3(0,.13,0),Vector3(.74,.33,.43),"#bc8549",true)
	for j in 3:
		var slash:=a.box(n,Vector3((j-1)*.17,.28,.014),Vector3(.16,.041,.051),"#edc98e");slash.rotation.y=.63
	return n
func build(land,mill:Node3D,breadhouse:Node3D)->void:
	costume(land.miller,"miller");costume(land.apprentice,"miller");costume(land.coastal.priest,"priest")
	oven=a.group(breadhouse,Vector3(-2.69,0,-1.63))
	a.box(oven,Vector3.UP*.37,Vector3(2.0,.73,2.65),"#aa9377")
	a.ball(oven,Vector3.UP*1.28,Vector3(2.16,2.15,2.67),"#bd8962",true)
	var mouth:=a.cyl(oven,Vector3(-.92,1.26,.05),.64,.64,.13,"#483d38",18);mouth.rotation.z=PI/2
	for j in 9:
		var ph:=PI*j/8
		var block:=a.box(oven,Vector3(-1.02,1.24+.68*sin(ph),.05+.68*cos(ph)),Vector3(.24,.24,.29),"#d4ab7a")
		block.rotation.x=ph
	for j in 5:
		var coal:=a.ball(oven,Vector3(-1.04,1.06+.13*sin(j),-.31+j*.16),Vector3(.10,.28,.18),"#df8542",true)
		coal.material_override=b.glow("#ee9850");embers.append(coal)
	lamp=OmniLight3D.new();oven.add_child(lamp);lamp.position=Vector3(-1.33,1.25,0);lamp.light_color=Color("#ffaf5a");lamp.omni_range=3.;lamp.light_energy=1.
	bakery_awn=a.group(breadhouse,Vector3(-2.30,3.16,.56))
	for j in 9:
		var pane:=a.box(bakery_awn,Vector3(-.77,-.12,(j-4)*.405),Vector3(1.65,.07,.415),"#396f86" if j%3 else "#ddc89a")
		pane.rotation.z=.14
		a.box(bakery_awn,Vector3(-1.56,-.34,(j-4)*.405),Vector3(.078,.28,.40),"#396f86" if j%3 else "#ddc89a")
	bread_tray=a.group(breadhouse,Vector3(-2.76,.99,.65))
	a.box(breadhouse,Vector3(-2.70,.89,.62),Vector3(1.27,.16,2.2),"#9c7653")
	for s in [-1,1]:a.box(breadhouse,Vector3(-2.97,.41,.62+s*.78),Vector3(.14,.84,.14),"#765940")
	for j in 6:
		var piece:=loaf(bread_tray,Vector3((j%2)*.42-.19,0,(j/2-1)*.54))
		piece.rotation.y=.2+j*.33;piece.scale=Vector3.ONE*.77
	baker=a.courier(breadhouse);costume(baker,"baker")
	dough=a.group(baker,Vector3(0,.98,.43));a.box(dough,Vector3.ZERO,Vector3(.75,.055,.51),"#8e6442");loaf(dough,Vector3.ZERO).scale=Vector3.ONE*.75
	intake=a.group(mill,Vector3(-4.69,.0,1.57))
	var brass:=a.cyl(intake,Vector3.UP*.63,.51,.38,1.25,"#9d7d54",14);brass.material_override=preload("res://harbour_materials.gd").sample(2,"#b48f55",1.1,false,.6)
	for j in 8:
		var stud:=a.ball(intake,Vector3(.42*cos(j*TAU/8),.97,.42*sin(j*TAU/8)),Vector3.ONE*.11,"#dbb981",true)
	for j in 2:
		var wheel:=a.group(mill,Vector3(-3.88,1.26+j*1.16,2.04))
		var disk:=a.cyl(wheel,Vector3.ZERO,.63-j*.10,.63-j*.10,.23,"#968768",14);disk.rotation.z=PI/2
		for k in 9:
			var ph:=k*TAU/9
			a.box(wheel,Vector3(-.128,.41*cos(ph),.41*sin(ph)),Vector3(.09,.095,.15),"#c0a97a").rotation.x=-ph
		mill_stones.append(wheel)
	var frame:=a.group(mill,Vector3(-4.67,0,-.5))
	a.beam(frame,Vector3(-.61,.15,-.74),Vector3(-.61,3.6,-.74),.11,"#795e42")
	a.beam(frame,Vector3(-.61,3.54,-.81),Vector3(-.61,3.54,1.1),.11,"#896f4b")
	grain=land.flour(frame,Vector3(-.61,.14,.94));rope=a.cyl(frame,Vector3.ZERO,.035,.035,1.0,"#a38964",8)
	for i in 14:
		var n:=a.ball(land,Vector3.ZERO,Vector3(.23,.07,.11),"#ecd497",true);couriers.append(n)
	for i in 8:
		var dust:=a.ball(mill,Vector3.ZERO,Vector3.ONE*.14,"#eadfc3",true);flock.append(dust)
func tick(land,t:float,level:float,elapsed:float,transferring:bool)->void:
	var open:=smoothstep(1.13,1.96,level)
	baker.position=Vector3(-2.49-open*1.58,.035,-1.8+open*2.08)
	baker.rotation.y=-PI*.56+open*.23
	baker.get_node("ArmL").rotation.x=-.25-.75*open;baker.get_node("ArmR").rotation.x=-.32-.78*open
	dough.visible=open>.65;bread_tray.visible=open>.52
	bakery_awn.scale.x=.10+open*.90
	for j in embers.size():
		embers[j].visible=open>.2
		embers[j].scale.y=.13+.21*open*(.8+.2*sin(t*7+j))
	lamp.visible=open>.24;lamp.light_energy=open*(1.25+.11*sin(t*8))
	for i in mill_stones.size():mill_stones[i].rotation.x=t*open*(1.26 if i==0 else -1.7)
	grain.position.y=.15+minf(level,1.)*(.72+.59*sin(t*1.25))
	var end:=grain.position+Vector3.UP*1.01;var start:=Vector3(-.61,3.54,.94)
	rope.position=(start+end)*.5;rope.scale.y=start.y-end.y
	for i in flock.size():
		var u:=fposmod(t*.64+i*.147,1.)
		flock[i].visible=open>.5;flock[i].position=Vector3(-4.05-.72*u,1.5+u*.6,2.1+sin(i*.84+u*4)*.25);flock[i].scale=Vector3.ONE*(.035+.13*sin(u*PI))
	var from:Vector3=land.surface(land.PAD)+Vector3.UP*.97
	for i in couriers.size():
		var n:=couriers[i];var u:=fposmod(elapsed*.73+i/14.,1.)
		n.visible=transferring and elapsed<2.75
		if n.visible:
			n.position=from.lerp(intake.global_position+Vector3.UP*1.12,u)+Vector3(0,sin(u*PI)*.65,cos(i*2+u*8)*.14)
			n.scale=Vector3(.14+.17*sin(u*PI),.048,.06)
