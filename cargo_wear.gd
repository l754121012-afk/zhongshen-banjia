extends RefCounted

const Art=preload("res://workshop.gd")
var art:=Art.new()
var last_id:=0
var last_grade:=-1
var marks:Node3D
func fissure(p:Node3D,points:Array[Vector3],thick:float,color:String)->void:
	for i in points.size()-1:art.beam(p,points[i],points[i+1],thick,color)

func update(item:Node3D,style:String,hp:float)->void:
	if not is_instance_valid(item):return
	var grade:=3 if hp>=90 else (2 if hp>=60 else (1 if hp>=30 else 0))
	if last_id==item.get_instance_id() and last_grade==grade:return
	last_id=item.get_instance_id();last_grade=grade
	if is_instance_valid(marks):marks.hide();marks.queue_free()
	marks=null
	if grade==3:return
	marks=art.group(item);marks.name="SurfaceWear"
	var severity:=3-grade
	match style:
		"wine":
			for i in 2:
				if i==1 and severity<2:continue
				var urn:=art.group(marks,Vector3(0,0.43,-0.63+i*1.20));urn.scale=Vector3.ONE*(.83 if i==0 else .76)
				for side in [-1,1]:
					var line:Array[Vector3]=[]
					for j in range(3+severity):
						var y:=1.21-j*.139
						var x:float=.17+(.11 if j%2 else -.05)-.041*j
						var surface:=.585*sqrt(maxf(.05,1-pow(x/.64,2)-pow((y-.77)/.75,2)))
						line.append(Vector3(x,y,side*(surface+.014)))
					fissure(urn,line,.018+severity*.006,"#513c38")
				if severity==3:art.ball(urn,Vector3(.33,1.31,.19),Vector3(.20,.16,.13),"#e1a986",true)
		"couch":
			for i in severity:
				var p:=Vector3(-.32+i*.26,1.13,.30+i*.13)
				art.ball(marks,p,Vector3(.24,.065,.20),"#354e69",true)
				art.ball(marks,p+Vector3(.05,.04,.06),Vector3(.17,.12,.14),Art.CREAM,true)
				fissure(marks,[p+Vector3(-.14,.015,.04),p+Vector3(-.05,.04,.12),p+Vector3(.12,.01,.14)],.019,"#367087")
		"sack":
			for i in severity:
				var y:=.81-.13*i;var x:float=-.17+i*.12
				var z:=.50*sqrt(maxf(.05,1-pow(x/.56,2)-pow((y-.58)/.585,2)))+.012
				fissure(marks,[Vector3(x-.1,y+.063,z-.026),Vector3(x,y,z+.012),Vector3(x+.11,y+.011,z-.016)],.020,"#684f43")
				art.beam(marks,Vector3(x,y+.02,z+.012),Vector3(x+.04,y-.13,z+.064),.017,Art.CREAM)
		"lens":
			for side in [-1,1]:
				var line:Array[Vector3]=[Vector3(.20,1.25,.28*side),Vector3(.10,1.12,.46*side),Vector3(.18,.98,.49*side),Vector3(.09,.85,.52*side)]
				if severity>=2:line.append(Vector3(.20,.64,.42*side))
				if severity==3:line.append(Vector3(.03,.47,.35*side))
				fissure(marks,line,.019+severity*.004,"#416c76")
