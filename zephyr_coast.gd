extends RefCounted
## Coastal switchback leading out of the wind depot.
const Art=preload("res://workshop.gd")
const Craft=preload("res://coastal_craft.gd")
const B=preload("res://tide_art.gd")
const W=preload("res://zephyr_weather.gd")
const START:=Vector2(-46.0,12.0)
const ROAD:=[START,Vector2(-35,11),Vector2(-26,6),Vector2(-19,-2),Vector2(-12,-5.2),Vector2(-5,-4.9),Vector2(3,0)]
const SHRINE:=Vector2(-20.5,10.6)
var a:=Art.new()
var craft:=Craft.new()
var root:Node3D
var shrine:Node3D
var wreath:Node3D
var ribbon:Array[Node3D]=[]
var gulls:Array[Node3D]=[]
var gusts:Array[MeshInstance3D]=[]
var clouds:Array[Node3D]=[]
var priest:Node3D
var carved:Label3D
var land
func boulder(p:Vector2,sz:Vector3,i:int,solid:=false)->void:
	var n:=a.group(root,land.surface(p))
	craft.outcrop(n,Vector3.UP*sz.y*.27,sz,i)
	if solid:land.obstacle(p,Vector2(sz.x*.48,sz.z*.53))
func build(terrain)->void:
	land=terrain;root=a.group(terrain)
	var harbor:=a.group(root,land.surface(START+Vector2(-11,1.5)))
	for i in 13:
		a.box(harbor,Vector3(-3.2+i*.37,0,.1),Vector3(.35,.13,3.2),"#92775b" if i%3 else "#74624e")
	for s in [-1,1]:
		a.cyl(harbor,Vector3(-2.8,.25,s*1.5),.15,.13,1.04,"#705944")
		a.ring(harbor,Vector3(-2.8,.51,s*1.5),.17,.035,"#c0ab83")
	for p:Vector2 in [Vector2(-42,22),Vector2(-50,-3),Vector2(-31,-6)]:
		var n:=a.group(root,land.surface(p));craft.villa(n,Vector3.ZERO,4.8,3.7,-.24,2);a.cypress(n,Vector3(-3.2,0,1.3),1.3)
	boulder(Vector2(-36,-4),Vector3(10,6,8),241,true)
	boulder(Vector2(-27,-5.7),Vector3(10,9.3,7),242,true)
	boulder(Vector2(-22,-9),Vector3(7.8,8.7,6),243,true)
	boulder(Vector2(-12,4.0),Vector3(7.8,6.9,5.7),245,true)
	boulder(Vector2(-5,5.9),Vector3(8.1,6.4,4.9),246,true)
	for i in 3:
		var n:=a.group(root,land.surface(Vector2(-27+i*3.2,-7.7)))
		a.cypress(n,Vector3.UP*.6,1.93-i*.14)
	# The two columns genuinely frame the road as the summit appears through the pass.
	var arch:=a.group(root,land.surface(Vector2(-14.8,-4.1)));arch.rotation.y=.35
	for s in [-1,1]:
		var post:=Vector3(0,0,s*4.05)
		a.column(arch,post,4.85);a.box(arch,post+Vector3.UP*4.77,Vector3(1.15,.25,1.29),"#c3aa86")
	a.box(arch,Vector3.UP*5.05,Vector3(.84,.31,8.97),"#bc9970")
	for z in [-3.7,-2.1,-.5,1.1,2.7]:
		var link:=a.box(arch,Vector3(0,4.75,z),Vector3(.55,.26,.43),"#dbbf91")
	land.label(terrain,land.surface(Vector2(-13.5,-8.2))+Vector3.UP*2.68,"橄榄门",.008)
	for i in 4:
		var p:=Vector2(-39+i*5.5,3.5-i*1.9)
		var n:=a.group(root,land.surface(p));craft.plant(n,Vector3.UP*.23,i)
	for i in 11:
		var p:=Vector2(-45+i*3.,17.6-i*.31+sin(i*.53))
		var n:=a.group(root,land.surface(p));a.cypress(n,Vector3.ZERO,.85+(i%3)*.29)
	for i in 4:
		var n:=a.group(root,Vector3(-76+i*3.9,-8.35,5+i*3.2))
		n.rotation.y=i*1.22
		a.ball(n,Vector3.ZERO,Vector3(5.8,1.34,1.91),"#805942",true)
		a.beam(n,Vector3.ZERO,Vector3.UP*5.86,.075,"#815f4c")
		var sail:=a.group(n,Vector3.UP*3.2)
		for j in 7:a.box(sail,Vector3(.18+j*.19,-j*.22,0),Vector3(.22,3.97-j*.49,.06),"#e2c192" if j%2 else "#ba7b5e")
	shrine=a.group(terrain,land.surface(SHRINE));shrine.rotation.y=.54
	for i in 2:a.cyl(shrine,Vector3.UP*(.07+i*.13),1.54-i*.23,1.54-i*.23,.16,"#c4ae89",16)
	for s in [-1,1]:
		a.column(shrine,Vector3(s*.90,.18,.39),2.62)
	a.box(shrine,Vector3(0,2.91,.39),Vector3(2.93,.26,1.04),"#c6b391")
	for j in 7:
		var pipe:=a.cyl(shrine,Vector3((j-3)*.19,2.39+j*.035,.27),.075,.075,.82-j*.08,"#c69a58",9)
	wreath=a.group(shrine,Vector3(0,1.28,-.79))
	var crown:=a.ring(wreath,Vector3.ZERO,.43,.065,"#b9a462");crown.rotation.x=PI/2
	for j in 11:
		var ph:=j*TAU/12;var leaf:=a.ball(wreath,Vector3(.44*cos(ph),.44*sin(ph),0),Vector3(.25,.088,.095),"#88a777",true);leaf.rotation.z=ph+.55
	land.label(shrine,Vector3(0,3.6,0),"西风小祠",.009)
	land.label(shrine,Vector3(0,2.0,-.92),"丰收枝",.0068)
	priest=a.courier(terrain);priest.position=land.surface(SHRINE+Vector2(-1.7,-.75));priest.rotation.y=-1.7
	a.ball(priest,Vector3(0,1.67,.03),Vector3(.74,.38,.70),"#bcc7a8",true)
	# Thin copper ribbons announce pulses of wind at the chapel.
	for j in 5:
		var p:=a.group(shrine,Vector3((j-2)*.25,2.79,.3))
		a.box(p,Vector3(0,-.48,0),Vector3(.13,.97,.063),"#66887d" if j%2 else "#cca65f");ribbon.append(p)
	craft.batch(root)
	for i in 9:
		var bird:=a.group(terrain)
		for s in [-1,1]:
			var wing:=a.ball(bird,Vector3(0,.04,s*.24),Vector3(.16,.056,.58),"#ede8cf",true);wing.rotation.x=s*.23
		gulls.append(bird)
	for i in 9:
		var g:=a.group(terrain,Vector3(139+(i%3)*16,20.+(i%3)*5.5,-76+i*17))
		clouds.append(g)
		for j in 5:
			a.ball(g,Vector3((j-2)*2.6,j%2*.91,cos(j)*1.2),Vector3(7.6,(1.85+.77*sin(j*1.9)),3.6),"#e2e3d8",true)
func tick(t:float,collected:bool)->void:
	wreath.visible=not collected;wreath.position.y=1.28+sin(t*2)*.085;wreath.rotation.y=t*.65
	for i in ribbon.size():ribbon[i].rotation.x=.28+.85*W.pressure(SHRINE,t)+.09*sin(t*3+i)
	priest.get_node("ArmL").rotation.x=-.54+.27*sin(t*1.4)
	for i in gulls.size():
		var v:=t*(.25+i*.007)+i*1.44
		var base:=Vector3(-36,7.2+i%3*.56,9)
		gulls[i].position=base+Vector3(cos(v)*(13+i*.33),sin(v*2)*1.2,sin(v)*(8.+i*.36))
		gulls[i].rotation=Vector3(sin(v*4.1)*.23,-v,0)
	for i in clouds.size():clouds[i].position.z=-76+i*17+sin(t*.019+i)*2.35
