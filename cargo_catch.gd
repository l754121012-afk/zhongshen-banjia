extends RefCounted
# Both loads use the same warning horizon, hand travel and grab speed.
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

