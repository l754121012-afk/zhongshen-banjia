extends Node3D

const TILE:=preload("res://art/spring_arethusa.jpg")
const WELL:=Vector2(85,35)
var a:=preload("res://workshop.gd").new()
var coastal:=preload("res://coastal_craft.gd").new()
var architecture:=preload("res://tide_art.gd").new()
var veil:Array[MeshInstance3D]=[]
var fins:Array[Node3D]=[]
var float_marker:Node3D
var float_rod:Node3D
var sluice:Node3D
var spill:Node3D
var stream:Node3D
var gauge:Node3D
var gate_label:Label3D
var ribbon:Node3D
var goddess:Node3D
var grotto:Node3D
var tiles:Array[Node3D]=[]

func tile(parent:Node3D,at:Vector3,wide:float,yaw:float)->void:
	var base:=a.group(parent,at);base.rotation.y=yaw
	a.box(base,Vector3.ZERO,Vector3(wide+.13,wide+.13,.15),"#c4a571")
	var picture:=Sprite3D.new();base.add_child(picture);picture.texture=TILE
	picture.pixel_size=wide/TILE.get_width();picture.position.z=.084
	tiles.append(base)

func label(parent:Node3D,at:Vector3,words:String)->Label3D:
	var l:=Label3D.new();parent.add_child(l);l.position=at;l.text=words
	l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.font=preload("res://harbour_fonts.gd").body()
	l.pixel_size=.009;l.font_size=29;l.outline_size=6;l.modulate=Color("#ffe3af");return l

func setup(g,head:Node3D)->void:
	var land=g.land
	grotto=a.group(self,land.surface(WELL+Vector2(0,5.1)))
	for i in 4:
		var shelf:=Vector3(-14.+i*8.8,.3,10.8+sin(i*1.5)*3.1)
		coastal.outcrop(grotto,shelf,Vector3(11.8,8.4+(i%2)*3.,8.2),33+i)
		a.cypress(grotto,shelf+Vector3(.3,3.45,0),1.38)
		if i==2:coastal.villa(grotto,shelf+Vector3(0,3.36,.4),4.4,2.6,-.68,0)
	for j in 8:
		var ang:=.25+j*.37
		var x:=cos(ang)*6.35
		var z:=sin(ang)*2.6
		coastal.crag(grotto,Vector3(x,-.8,z),Vector3(2.9,4.6+j%3*.6,2.7),j+2)
	for j in 5:
		var arch:=architecture.arch(grotto,Vector3((j-2)*2.1,0,1.45),.88,1.64,.88)
		a.box(arch,Vector3(0,2.8,0),Vector3(2.13,.21,1.06),"#d3b395")
	for side in [-1,1]:
		a.cypress(grotto,Vector3(side*5.1,.08,-.3),1.45)
		coastal.plant(grotto,Vector3(side*3.1,.10,-1.30),3+side,true)
	var pool:=a.cyl(grotto,Vector3(0,.12,-.62),2.9,2.95,.29,"#beaa8b",36)
	pool.scale.z=.59
	var w:=a.cyl(pool,Vector3.UP*.19,2.73,2.73,.08,"#64bbae",36)
	a.ring(pool,Vector3.UP*.19,2.81,.082,"#d9bea0")
	goddess=a.group(grotto,Vector3(0,.30,.66))
	a.cyl(goddess,Vector3.UP*.37,.64,.48,.74,"#d8c5a7",16)
	var figure:=a.courier(goddess);figure.position.y=.72;figure.rotation.y=PI
	preload("res://zephyr_people.gd").new().costume(figure,"priest")
	figure.get_node("ArmR").rotation.x=-.94
	a.jar(goddess,Vector3(-.49,1.68,-.33),.71,"#b78558").rotation.z=-.7
	for j in 7:
		var drop:=a.ball(grotto,Vector3(-.62+.08*sin(j*.6),1.86-j*.23,.09-j*.14),Vector3(.12,.35,.17),"#8ed9cd",true);veil.append(drop)
	tile(grotto,Vector3(0,3.70,1.49),1.5,PI)
	label(grotto,Vector3(.35,2.91,-.45),"阿瑞图萨泉眼")
	for j in 5:
		var fish:=a.group(pool);fins.append(fish)
		a.ball(fish,Vector3.ZERO,Vector3(.30,.085,.12),"#d7b06c",true)
		a.ball(fish,Vector3(-.18,.01,0),Vector3(.16,.12,.045),"#c59155",true)
	for k in 19:
		var x:=54.+k*3.84
		var off:float=land.cove_path(x)+(-4.45 if k%2 else 4.62)
		var at:Vector3=land.surface(Vector2(x,off))
		a.prop(self,"garden/grass_large",at,.49+(k%3)*.08,k*.93)
		if k%4==1:a.prop(self,"garden/tree_oak",at,2.7+(k%3)*.22,k*.6)
	for x in range(54,126,9):
		var z:float=land.cove_path(x)+3.47
		var p:Vector3=land.surface(Vector2(x,z))
		coastal.plant(self,p,3+x%4,x%2==0)
		a.cyl(self,p+Vector3.UP*.44,.14,.105,.88,"#cdaf85")
	for x in [55.,125.]:
		var p:Vector3=land.surface(Vector2(x,land.cove_path(x)+3.15))
		a.column(self,p,2.12);tile(self,p+Vector3.UP*2.35,.90,PI/2 if x>85 else -PI/2)
	tile(head,Vector3(3.40,2.69,-.62),1.63,PI)
	make_gauge(head)

func make_gauge(head:Node3D)->void:
	gauge=a.group(head,Vector3(-3.35,.14,-1.16))
	a.box(gauge,Vector3.UP*1.33,Vector3(1.55,2.60,.49),"#a58b68")
	a.box(gauge,Vector3(0,1.39,-.28),Vector3(.98,2.1,.085),"#354f52")
	a.box(gauge,Vector3(0,1.41,-.35),Vector3(.95,.54,.08),"#689d81")
	for i in 9:a.box(gauge,Vector3(.36,.43+i*.24,-.42),Vector3(.20,.026,.09),"#e6be81")
	float_rod=a.group(gauge,Vector3(0,0,-.48))
	a.cyl(float_rod,Vector3.UP*.9,.027,.027,1.85,"#b8a27a")
	float_marker=a.ball(float_rod,Vector3.UP*.72,Vector3(.46,.23,.28),"#e6b263",true)
	sluice=a.group(head,Vector3(.2,.13,-.76))
	for j in 5:a.box(sluice,Vector3(0,j*.24,0),Vector3(2.1,.21,.16),"#77694e")
	spill=a.group(head,Vector3(2.72,.14,-.86));stream=a.group(head,Vector3(.64,.12,-.92))
	for outlet in [spill,stream]:
		for j in 7:a.ball(outlet,Vector3(0,3.43-j*.46,-.08*j),Vector3(.23+j*.06,.70,.21),"#91d7cb",true)
	gate_label=label(gauge,Vector3(0,3.08,0),"")
	gate_label.hide()

func tick(t:float,pressure:float,opening:float,step:int,testing:bool)->void:
	for j in fins.size():
		var ang:=t*.32+j*1.3
		fins[j].position=Vector3(sin(ang)*1.8,.25,cos(ang)*1.52)
		fins[j].rotation.y=ang
	for j in veil.size():veil[j].scale.x=.11+.026*sin(t*5.+j*.8)
	float_rod.position.y=clampf(pressure,0.,1.)*2.02-.24
	sluice.position.y=.13+(opening*1.08 if testing else (1.18 if step>=3 else 0.))
	spill.visible=testing and pressure>.72
	stream.visible=testing or step>=3
	stream.scale.x=clampf(pressure,.16,1.)
	gate_label.visible=testing
	if testing:gate_label.text="水涌出溢流口" if pressure>.72 else ("浮子进了青铜绿带" if pressure>=.46 else "浮子太低 · 再开一些")
