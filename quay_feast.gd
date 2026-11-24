extends Node3D

var art:=preload("res://workshop.gd").new()
var people:=preload("res://zephyr_people.gd").new()
var musicians:Array[Node3D]=[]
var cups:Array[Node3D]=[]
var ribbons:Array[Node3D]=[]
var melody:AudioStreamPlayer3D
var cloth:Node3D
var age:=6.
var celebration:=false

func _ready()->void:
	for j in 12:
		art.box(self,Vector3((j-5.5)*.34,.015,0),Vector3(.33,.24,3.04),"#b49569" if j%3 else "#c1a378")
	for x in [-1.77,1.77]:
		for z in [-1.25,1.25]:art.cyl(self,Vector3(x,-.53,z),.15,.17,1.42,"#746048")
		art.beam(self,Vector3(x,.06,-.95),Vector3(x,3.16,-.95),.065,"#80664b")
	cloth=art.group(self,Vector3(0,3.05,-.95))
	preload("res://coastal_craft.gd").new().cloth(cloth,Vector3.ZERO,3.85,"#ad644c")
	for i in 7:
		var x:float=(i-3)*.52
		var ribbon:=art.box(cloth,Vector3(x,-.7,1.69),Vector3(.15,.38,.035),"#c18a50" if i%2 else "#688a81")
		ribbons.append(ribbon)
	for j in 4:art.box(self,Vector3(0,.86,(j-1.5)*.24),Vector3(3.07,.12,.225),"#b7956d" if j%2 else "#c5a57a")
	for x in [-1.21,1.21]:
		art.box(self,Vector3(x,.46,0),Vector3(.15,.75,.79),"#896c50")
	for i in 4:
		var p:=Vector3((i-1.5)*.70,.95,-.08 if i%2 else .10)
		art.cyl(self,p,.22,.24,.045,"#b4c1ae",16)
		people.loaf(self,p+Vector3.UP*.06).scale=Vector3.ONE*.59
		cups.append(art.cyl(self,p+Vector3(.18,.16,.26 if i%2 else -.27),.095,.12,.25,"#b77854",12))
	for i in 3:
		var person:=art.courier(self)
		person.position=Vector3(-1.0+i*.98,.12,-.91 if i%2 else .95)
		person.rotation.y=0. if i%2 else PI;person.scale=Vector3.ONE*.84
		people.costume(person,["priest","baker","miller"][i]);musicians.append(person)
	var candle:=preload("res://night_art.gd").new()
	candle.glow(self,Vector3(0,1.30,.12),Vector3(.1,.24,.1),"#e8ab62",1.3)
	candle.lamp(self,Vector3(0,1.54,.12),"#ffd596",1.0,4.5)
	melody=AudioStreamPlayer3D.new();melody.stream=preload("res://audio/quay_feast.wav");melody.position=Vector3.UP*1.5;melody.volume_db=-8.;melody.unit_size=10;melody.max_distance=30;add_child(melody)

func unveil()->void:
	age=0.;celebration=true;melody.play()

func _process(dt:float)->void:
	if not is_visible_in_tree():return
	age+=dt
	var t:=Time.get_ticks_msec()*.001
	for i in 3:
		var person:=musicians[i]
		var wave:=maxf(0.,sin(t*(1.05+i*.08)+i*2.13))
		person.get_node("ArmR").rotation.x=-.38-wave*(.68 if age<4. else .34)
		person.get_node("ArmL").rotation.x=-.28+.09*sin(t*1.3+i)
		person.rotation.z=.026*sin(t*.88+i)
	for j in ribbons.size():ribbons[j].rotation.x=.10+.14*sin(t*2.+j*.36)
	if celebration:
		cloth.scale.y=lerpf(.19,1.,smoothstep(0.,1.55,age))
		if age>1.6:celebration=false
