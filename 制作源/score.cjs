const fs=require('fs'),path=require('path');
const dest=path.resolve(process.argv[2] || path.join(__dirname,'../game/audio'));
fs.mkdirSync(dest,{recursive:true});
const rate=22050, pi=Math.PI;
function wave(name,length,notes,volume=.9){
  const mix=new Float64Array(Math.ceil(length*rate));
  let seed=919;
  for(const [start,hz,dur,gain,voice='pluck',pan=0] of notes){
    const startAt=Math.round(start*rate);
    for(let i=0;i<Math.round(dur*rate)&&startAt+i<mix.length;i++){
      let t=i/rate,ph=2*pi*hz*t,en=Math.min(1,t/.009)*Math.min(1,(dur-t)/.065),s=0;
      if(voice==='pluck')s=(Math.sin(ph)+.32*Math.sin(2*ph)+.12*Math.sin(3*ph))*Math.exp(-t*5);
      if(voice==='reed')s=(Math.sin(ph+.15*Math.sin(t*30))+.13*Math.sin(3*ph))*Math.min(1,t/.09)*Math.exp(-t*.9);
      if(voice==='bass')s=(Math.sin(ph)+.24*Math.sin(ph*2))*Math.exp(-t*4.2);
      if(voice==='bell')s=(Math.sin(ph)+.28*Math.sin(ph*2.73)+.12*Math.sin(ph*4.1))*Math.exp(-t*4.7);
      if(voice==='thud')s=Math.sin(ph*(1+.42*Math.exp(-t*22)))*Math.exp(-t*12);
      if(voice==='air'){seed=(Math.imul(seed,1664525)+1013904223)>>>0;s=((seed/4294967296-.5)*.74+Math.sin(ph+t*t*510)*.38)*Math.sin(pi*t/dur);}
      mix[startAt+i]+=s*en*gain;
    }
  }
  const buf=Buffer.alloc(44+mix.length*2);buf.write('RIFF');buf.writeUInt32LE(buf.length-8,4);buf.write('WAVEfmt ',8);buf.writeUInt32LE(16,16);buf.writeUInt16LE(1,20);buf.writeUInt16LE(1,22);buf.writeUInt32LE(rate,24);buf.writeUInt32LE(rate*2,28);buf.writeUInt16LE(2,32);buf.writeUInt16LE(16,34);buf.write('data',36);buf.writeUInt32LE(mix.length*2,40);
  for(let i=0;i<mix.length;i++)buf.writeInt16LE(Math.round(Math.tanh(mix[i]*volume)*28000),44+i*2);
  fs.writeFileSync(path.join(dest,name+'.wav'),buf);
}
const hz=n=>440*Math.pow(2,(n-69)/12);
function music(name,beat,road){
 const notes=[],chords=[[50,57,62,65],[48,55,60,64],[46,53,58,62],[45,52,57,61],[50,57,62,65],[53,60,65,69],[48,55,60,64],[45,52,57,61]];
 const melodies=[[74,77,76,74],[72,69,67,69],[70,74,77,74],[73,69,64,69],[74,77,81,79],[77,76,72,69],[72,76,79,76],[73,76,69,73]];
 for(let bar=0;bar<8;bar++){
  const ch=chords[bar],at=bar*beat*4;
  for(let b=0;b<4;b++){
    notes.push([at+b*beat,hz(ch[b%2?2:0]-12),beat*.92,.22,'bass']);
    for(let k=0;k<3;k++)notes.push([at+(b+.45)*beat+.017*k,hz(ch[k+1]),beat*.65,.095,'pluck']);
    if(road)notes.push([at+(b+.78)*beat,118,.075,.11,'thud']);
  }
  for(let k=0;k<4;k++){const t=at+(k+(k===1?.25:0))*beat;notes.push([t,hz(melodies[bar][k]),beat*(k===3?.78:.9),.16,bar%3===1?'reed':'bell']);}
 }
 wave(name,8*beat*4,notes,.82);
}
music('yard',.49,false);music('road',.405,true);
const cues={foot:[[0,135,.08,.13,"thud"]],grab:[[0,330,.18,.55],[.06,494,.25,.4]],drop:[[0,160,.19,.67,'thud']],load:[[0,392,.25,.37],[.07,494,.28,.38],[.16,587,.38,.42,'bell']],bonk:[[0,99,.20,.62,'thud'],[.05,142,.1,.4,'thud']],start:[[0,294,.3,.35],[.09,370,.28,.4],[.20,440,.44,.45]],page:[[0,760,.08,.16,'air']],engine:[[0,68,.47,.4,'thud'],[.12,98,.3,.4,'thud']],wind:[[0,290,.83,.48,'air'],[.15,588,.46,.20,'bell']],land:[[0,74,.4,.7,'thud'],[.12,119,.19,.42,'thud']],win:[[0,392,.42,.4,'bell'],[.12,494,.42,.4,'bell'],[.26,587,.44,.4,'bell'],[.42,784,.65,.45,'bell']],warn:[[0,525,.12,.35,'bell'],[.19,660,.18,.35,'bell']],snap:[[0,220,.15,.4,'pluck'],[.06,880,.12,.25,'bell']]};
for(const [n,seq] of Object.entries(cues))wave(n,Math.max(...seq.map(a=>a[0]+a[2]))+.07,seq);


