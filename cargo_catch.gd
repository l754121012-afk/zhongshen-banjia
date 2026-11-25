extends RefCounted
# The rope can be grabbed when the load leaves its safe band.
const EDGE:=.46
var travel_left:=0.
var warned:=false

func available(offset:float,speed:float,horizon:float,pull:float)->bool:
	return travel_left<=0. and pull<=0. and absf(speed)>.5 and (horizon>0. or absf(offset)>=EDGE)

func tick(offset:float,speed:float,horizon:float,pull:float,meters:float)->bool:
	travel_left=maxf(0.,travel_left-meters)
	if absf(offset)<.30 and horizon<=0.:warned=false
	if not warned and available(offset,speed,horizon,pull):
		warned=true
		return true
	return false

func take()->void:
	travel_left=8.
	warned=false

func hint(offset:float,speed:float,horizon:float,pull:float)->String:
	if pull>0.:return "拉住了"
	if available(offset,speed,horizon,pull):return "左键  拉一把"
	if absf(offset)>=EDGE and travel_left>0.:return "绑带收紧"
	return ""

const WINDOW:=0.52
const PULL:=0.32
const DURATION:=0.36

static func reaches_rail(room:float,outward:float,accel:float,min_rate:float)->bool:
	return outward>min_rate and room>.005 and room<=outward*WINDOW+.5*maxf(0.,accel)*WINDOW*WINDOW

static func show_balance(offset_fraction:float,window:float,pull:float)->bool:
	return absf(offset_fraction)>.44 or window>0. or pull>0.

static func instruction(window:float,pull:float)->String:
	return "左键  扶住" if window>0. else ("扶住了" if pull>0. else "")

static func grip_step(dt:float)->float:
	return PULL*minf(DURATION,dt)/DURATION

