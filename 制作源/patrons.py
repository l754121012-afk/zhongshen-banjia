from pathlib import Path
exec(Path(__file__).with_name('sculpt.py').read_text(encoding='utf8').split("clear()\nbox('chassis'")[0])
for who in ['wind','wine']:
    clear()
    iswind=who=='wind'
    robe='528E7B' if iswind else '865976'
    skin='BE8765' if iswind else 'AA765C'
    beard='F1DABB' if iswind else '885844'
    for side in [-1,1]:
        orb('sandal',(side*.245,.135,.06),(.36,.22,.48),wood)
        box('strap',(side*.245,.21,.16),(.33,.065,.10),gold,.025)
    cylinder('robe',(0,.23,0),(0,1.08,0),.515,robe,.385)
    orb('shoulders',(0,1.15,0),(.98,.65,.65),robe)
    for side in [-1,1]:
        orb('arm',(side*.42,.99,.10),(.285,.53,.32),skin)
        orb('hand',(side*.46,.83,.20),(.225,.24,.23),skin)
    pipe('drape',[(-.38,1.39,.08),(-.26,1.31,.30),(.10,1.04,.36),(.40,.78,.22)],.079,cream)
    pipe('drape braid',[(-.39,1.35,.12),(-.27,1.27,.34),(.09,1.0,.385),(.38,.75,.23)],.020,gold)
    for i in range(5):
        x=-.36+.18*i
        pipe('pleat',[(x*.80,.84,.28),(x,.48,.38*(1-abs(x))),(x*1.12,.24,.44*(1-abs(x)))],.024,'407967' if iswind else '734667')
    orb('head',(0,1.70,.015),(.86,.83,.72),skin)
    orb('hair cap',(0,1.81,-.08),(.89,.67,.72),beard)
    for side in [-1,1]:
        orb('ear',(side*.422,1.68,.02),(.17,.21,.17),skin)
        orb('white',(side*.167,1.76,.325),(.146,.125,.062),cream)
        orb('pupil',(side*.169,1.755,.366),(.071,.084,.04),dark)
        pipe('eyebrow',[(side*.26,1.87,.254),(side*.188,1.89,.321),(side*.093,1.845,.350)],.033,beard)
    orb('nose',(0,1.662,.395),(.234,.213,.225),'C98C66' if iswind else 'B37F63')
    for i in range(13):
        a=i*2*pi/13
        orb('curls',(.38*cos(a),1.882+.035*cos(a*3),-.045+.305*sin(a)),(.225,.26,.21),beard)
    for i in range(7):
        a=i*pi/6
        orb('beard curl',(.305*cos(a),1.485-.15*sin(a),.256+.06*sin(a)),(.229,.31,.185),beard)
    for side in [-1,1]:
        pipe('whisker',[(side*.025,1.581,.392),(side*.17,1.545,.392),(side*.32,1.59,.325),(side*.39,1.65,.26)],.061,beard)
    for k in range(11):
        a=k*2*pi/11
        base=(.40*cos(a),1.989,.30*sin(a))
        o=orb('wreath',base,(.18,.22,.086),gold if iswind else '65805B')
        o.rotation_euler.y=.42*cos(a);o.rotation_euler.z=-a
    if not iswind:
        for j in range(6):
            orb('grape',(.33+(j%2)*.08,1.93-(j//2)*.09,.18),(.14,.14,.14),'72516C')
        cylinder('cup stem',(.49,.97,.26),(.49,1.14,.26),.048,gold)
        cylinder('goblet',(.49,1.12,.26),(.49,1.34,.26),.07,gold,.155)
    else:
        pipe('scroll',[(.43,.95,.21),(.47,1.17,.24),(.45,1.31,.25)],.058,cream)
    export('patron_'+who)
