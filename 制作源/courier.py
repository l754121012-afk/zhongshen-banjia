"""Original articulated Hermes Express courier and a fragile amphora commission."""
from pathlib import Path
exec(Path(__file__).with_name('sculpt.py').read_text(encoding='utf8').split("clear()\nbox('chassis'")[0])
clear()
skin='E5AD80';hair='674636';coat='267A73';indigo='314653'
orb('tunic',(0,.88,0),(.83,.84,.57),coat)
box('belt',(0,.68,0),(.72,.13,.52),'81533A',.06)
box('buckle',(0,.68,.27),(.17,.14,.055),gold,.024)
for side in [-1,1]:
    pipe('lapel',[(side*.25,1.19,.09),(side*.20,1.08,.24),(side*.13,1.01,.279)],.060,cream)
for i in range(2):orb('button',(0,.88+i*.15,.27),(.05,.05,.04),gold)
pipe('strap',[(-.28,1.22,.14),(-.14,1.06,.29),(.28,.71,.235)],.042,wood)
box('satchel',(.31,.70,-.08),(.30,.35,.37),wood,.07)
box('satchel flap',(.32,.77,.10),(.30,.20,.055),'C29564',.04)
orb('buckle',(.32,.73,.14),(.064,.065,.03),gold)
orb('neck',(0,1.27,0),(.32,.30,.31),skin)
orb('face',(0,1.52,.02),(.76,.68,.67),skin)
orb('hair',(0,1.61,-.08),(.77,.51,.60),hair)
for side in [-1,1]:
    orb('ear',(side*.37,1.51,0),(.15,.20,.13),skin)
    orb('curl',(side*.31,1.57,-.01),(.13,.25,.24),hair)
    orb('eye white',(side*.144,1.57,.315),(.124,.14,.045),cream)
    orb('eye',(side*.145,1.57,.342),(.073,.099,.034),dark)
    orb('glint',(side*.145-.012,1.591,.361),(.023,.023,.018),cream)
    pipe('brow',[(side*.219,1.665,.295),(side*.155,1.68,.321),(side*.09,1.662,.334)],.022,hair)
    orb('cheek',(side*.22,1.485,.29),(.095,.055,.04),'D99473')
orb('nose',(0,1.48,.367),(.205,.161,.19),'DB9770')
pipe('grin',[(-.11,1.397,.299),(0,1.374,.313),(.10,1.412,.30)],.014,hair)
orb('cap',(0,1.806,-.02),(.88,.39,.78),'B95747')
box('visor',(0,1.735,.28),(.72,.084,.41),red,.04)
pipe('cap braid',[(-.31,1.756,.268),(0,1.765,.349),(.31,1.756,.268)],.024,gold)
for side in [-1,1]:
    orb('brooch',(side*.34,1.775,.16),(.105,.105,.08),gold)
    for i in range(3):
        o=orb('feather',(side*(.40+i*.075),1.81+i*.077,-.02-.035*i),(.29-i*.037,.095,.14),cream);o.rotation_euler.y=-side*.48
orb('button',(0,2.01,-.03),(.12,.065,.10),gold)
export('courier_body')
for side,n in [(-1,'l'),(1,'r')]:
    clear()
    orb('sleeve',(side*.012,-.112,0),(.30,.35,.29),coat)
    cylinder('sleeve band',(0,-.26,0),(0,-.20,0),.128,cream)
    orb('forearm',(0,-.30,0),(.20,.24,.20),skin)
    orb('glove',(0,-.435,.038),(.243,.25,.246),'9F6B46')
    orb('finger',(side*-.075,-.423,.135),(.11,.13,.12),'B68352')
    export('courier_arm_'+n)
clear()
orb('trouser',(0,-.13,0),(.27,.39,.29),indigo)
box('boot',(0,-.355,.058),(.31,.238,.415),'704D39',.089)
box('sole',(0,-.446,.073),(.325,.085,.43),dark,.032)
box('buckle',(0,-.276,.205),(.15,.070,.045),brass,.016)
export('courier_boot')
clear()
orb('clay body',(0,.77,0),(1.28,1.50,1.17),'B26848')
cylinder('foot',(0,.08,0),(0,.23,0),.36,'8C533D',.27)
cylinder('neck',(0,1.34,0),(0,1.71,0),.27,'C88453',.29)
cylinder('lip',(0,1.68,0),(0,1.78,0),.34,dark,.35)
cylinder('wax seal',(0,1.77,0),(0,1.79,0),.275,red)
for s in [-1,1]:
    pipe('big handle',[(s*.24,1.59,0),(s*.59,1.62,0),(s*.73,1.35,0),(s*.54,1.01,0)],.085,'84513E')
for y,r in [(.44,.57),(1.04,.60),(1.17,.548)]:
    pts=[(cos(i*2*pi/24)*r,y,sin(i*2*pi/24)*r*.92) for i in range(26)]
    pipe('paint band',pts,.035,dark)
for side in [-1,1]:
    for i in range(7):
        x=(i%3-1)*.11+(.055 if i//3==1 else 0)
        orb('grapes',(x,.89-(i//3)*.115,side*.565),(.125,.14,.065),'57465D')
    pipe('vine',[(-.18,1.0,side*.55),(-.085,1.05,side*.56),(.075,1.07,side*.53),(.17,1.03,side*.53)],.029,gold)
export('wine_urn')
