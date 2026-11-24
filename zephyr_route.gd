extends Node3D
## The recovered bell is visible from the bridge and can be caught in flight.
const Art=preload("res://workshop.gd")
const Bay=preload("res://tide_art.gd")
const Wind=preload("res://zephyr_weather.gd")
const BELL_POINT:=Vector2(65.4,0)
var art:=Art.new()
var design:=Bay.new()
var land
var bell:Node3D
var hoop:Node3D
var bell_tag:Label3D
var feathers:Array[Node3D]=[]
var ribbon_pivots:Array[Node3D]=[]
var canopy:Node3D
var shade:Node3D
var low_wind_vane:Node3D
var blocked:=false
var fabric_height:=0.
var angle:=0.
static func bell_shape(p:Node3D)->Node3D:
	var bronze:=Art.new()
	var n:=bronze.group(p)
	bronze.cyl(n,Vector3(0,.21,0),.35,.17,.47,"#cc9244",16)
	bronze.cyl(n,Vector3(0,.015,0),.39,.36,.095,"#efbe69",16)
	bronze.ball(n,Vector3(0,-.12,0),Vector3(.16,.20,.16),"#714b38")
	bronze.ring(n,Vector3(0,.53,0),.093,.032,"#e0bb70").rotation.x=PI/2
	return n
func build(terrain)->void:
	land=terrain
	bell=art.group(self,Vector3(BELL_POINT.x,9.75,BELL_POINT.y))
	hoop=art.group(bell);hoop.rotation.z=PI/2
	var rim:=art.ring(hoop,Vector3.ZERO,1.30,.055,"#d6a749")
	rim.material_override=design.glow("#dfb65f")
	var charm:=bell_shape(bell);charm.scale=Vector3.ONE*1.48
	for s in [-1,1]:
		for j in 4:
			var quill:=art.ball(bell,Vector3(.03,.23+j*.1,s*(.52+j*.21)),Vector3(.16,.23,.59),"#eac980" if j%2 else "#d3ac68",true)
			quill.rotation.x=-s*.43
	bell_tag=land.label(bell,Vector3.UP*1.72,"走失的风铃",.0085)
	for j in 3:
		var feather:=art.group(self)
		for s in [-1,1]:
			var wing:=art.ball(feather,Vector3(0,0,s*.17),Vector3(.12,.06,.44),"#ede4c6",true)
			wing.rotation.x=s*.34
		feathers.append(feather)
	var arbor:=art.group(self,land.surface(Vector2(65,-24)))
	arbor.rotation.y=.06
	for s in [-1,1]:
		var y:float=land.ground(Vector2(65,-24+s*3.35))-arbor.position.y
		art.box(arbor,Vector3(0,y+.23,s*3.35),Vector3(.79,.46,.81),"#b4a183")
		art.beam(arbor,Vector3(0,y,s*3.35),Vector3(0,4.42,s*3.35),.14,"#67503a")
		art.beam(arbor,Vector3(1.7,y+.12,s*3.36),Vector3(0,2.9,s*3.35),.064,"#94704f")
	art.beam(arbor,Vector3(0,4.42,-3.6),Vector3(0,4.42,3.6),.12,"#9d7a4e")
	canopy=art.group(arbor,Vector3.UP*4.30)
	for j in 11:
		var strip:=art.group(canopy,Vector3(0,0,(j-5)*.55));ribbon_pivots.append(strip)
		var cloth:=art.box(strip,Vector3(0,-1.43,0),Vector3(.075,2.87,.57),"#9f6453" if j%3 else "#d9bf94")
		cloth.material_override=preload("res://harbour_materials.gd").sample(3,"#ac6550" if j%3 else "#d9be91",1.25,false,.71)
		art.box(strip,Vector3(0,-2.79,0),Vector3(.10,.09,.54),"#d1b17f")
	land.label(arbor,Vector3(0,5.18,0),"晒帆巷",.009)
	low_wind_vane=art.group(arbor,Vector3(-.25,3.40,-3.35))
	art.box(low_wind_vane,Vector3(-.49,0,0),Vector3(1.05,.27,.06),"#588a83")
func tick(t:float,collected:bool)->void:
	bell.visible=not collected
	bell.position.y=9.72+sin(t*2.4)*.16;bell.rotation.x=sin(t*3.1)*.11
	hoop.rotation.y=sin(t*1.5)*.09
	for i in feathers.size():
		var a:=t*(.74+i*.13)+i*TAU/3
		var p:=Vector3(65+cos(a)*3.1,11.5+sin(a*2)*.50,sin(a)*3.5)
		feathers[i].position=p;feathers[i].rotation=Vector3(sin(t*7.5+i)*.20,-a,0)
	var pressure:=Wind.pressure(Vector2(65,-24),t)
	angle=lerpf(.15,1.46,pressure)
	low_wind_vane.rotation.z=-.88+.85*Wind.pressure(Vector2(64,-28),t)
	for j in ribbon_pivots.size():ribbon_pivots[j].rotation.z=angle+.055*sin(t*3+j*.53)
	fabric_height=4.30-2.87*cos(angle)
	blocked=fabric_height<2.38
func can_hear(p:Vector2,y:float)->bool:
	return p.distance_to(BELL_POINT)<2.1 and absf(y+1.1-bell.global_position.y)<2.15
func touches_sail(before:Vector2,after:Vector2)->bool:
	if absf(after.y+24.)>2.86 or not blocked:return false
	return (before.x-65.)*(after.x-65.)<=0 and absf(before.x-after.x)>.001
