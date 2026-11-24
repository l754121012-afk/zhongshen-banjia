extends Node3D
const Art=preload("res://workshop.gd")
const Craft=preload("res://coastal_craft.gd")
const B=preload("res://tide_art.gd")
const PLACE:=Vector3(12.0,0,14.9)
var a:=Art.new()
var c:=Craft.new()
var sails:Node3D
var curtain:Node3D
var tray:Node3D
var pulley:Node3D
var bread:Node3D
var cook:Node3D
var little_bell:Node3D
var notice:=Label3D.new()
var relocated:=false
var level:=0
var clock:=0.
var bell_found:=false
func build()->void:
	position=PLACE
	a.cyl(self,Vector3.DOWN*.23,3.7,3.3,.48,"#b9a88b",18)
	a.box(self,Vector3(0,1.75,0),Vector3(5.9,3.5,3.2),"#e0c9a0")
	a.tile_roof(self,Vector3(0,3.72,0),6.38,3.87)
	a.box(self,Vector3(.31,1.77,-1.64),Vector3(2.81,1.64,.14),"#364644")
	a.box(self,Vector3(.31,.95,-1.95),Vector3(3.06,.16,.91),"#b38c5f")
	curtain=a.group(self,Vector3(.30,3.18,-1.72))
	for j in 8:
		var piece:=a.box(curtain,Vector3((j-3.5)*.40,-.46,-.2),Vector3(.405,.99,.45),"#42858a" if j%2 else "#e2c995")
		piece.rotation.x=-.42
	tray=a.group(self,Vector3(.3,1.12,-1.9))
	for j in 6:
		var bun:=a.ball(tray,Vector3((j%3-1)*.58,j/3*.21,.15*(j/3)),Vector3(.53,.36,.41),"#b3753d" if j%2 else "#cf9953",true)
		a.box(bun,Vector3.UP*.45,Vector3(.48,.11,.09),"#edd29a")
	sails=a.group(self,Vector3(-2.19,3.49,-1.82))
	for j in 6:
		var arm:=a.group(sails);arm.rotation.z=j*TAU/6
		a.beam(arm,Vector3.ZERO,Vector3.UP*1.47,.055,"#806247")
		a.box(arm,Vector3(.18,.95,0),Vector3(.36,.78,.048),"#ddbe89")
	pulley=a.group(self,Vector3(2.37,2.46,-1.86))
	a.ring(pulley,Vector3.ZERO,.52,.07,"#9a734b").rotation.x=PI/2
	for j in 4:
		a.box(pulley,Vector3.ZERO,Vector3(.06,1.06,.075),"#b8985d").rotation.z=j*PI/4
	a.beam(self,Vector3(2.37,2.94,-1.86),Vector3(2.37,.62,-1.86),.033,"#795a43")
	bread=a.group(self,Vector3(2.37,.36,-1.86))
	a.ball(bread,Vector3.UP*.42,Vector3(.64,.90,.59),"#c7aa7e",true)
	cook=a.courier(self);cook.position=Vector3(-.52,.04,-2.82);cook.rotation.y=PI
	a.ball(cook,Vector3(0,1.78,0),Vector3(.76,.39,.70),"#e4dcc2",true)
	little_bell=preload("res://zephyr_route.gd").bell_shape(self)
	little_bell.position=Vector3(1.83,3.06,-1.93)
	notice.font=preload("res://harbour_fonts.gd").body();notice.font_size=29;notice.pixel_size=.012
	notice.billboard=BaseMaterial3D.BILLBOARD_ENABLED;notice.outline_size=8;notice.modulate=Color("#f7e0a5")
	add_child(notice);notice.position=Vector3(.28,4.89,-.26)
func apply(next:int,chime:bool)->void:
	level=next;bell_found=chime;tray.visible=level==2
	curtain.scale.y=1.0 if level==2 else .20
	little_bell.visible=bell_found;cook.visible=level>0
	notice.text=["西湾粮站","西湾粮站 · 磨坊粮袋已到","蓝窗面包摊 · 今日有新面包"][level]
	if relocated:
		tray.hide();cook.hide();curtain.scale.y=.20
		notice.text="西湾粮站 · 船坞供粉" if level>0 else "西湾粮站 · 伊娅迁往蓝棚"
func tick(dt:float)->void:
	clock+=dt
	if level>0:
		pulley.rotation.z+=dt*.91;bread.position.y=.37+.40*(1+sin(clock*1.2))
		cook.get_node("ArmR").rotation.x=-.70+.48*sin(clock*1.9)
	if level==2:sails.rotation.z+=dt*.77
	if bell_found:little_bell.rotation.z=sin(clock*3.5)*.12
