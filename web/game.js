// ORBIT ZERO v1.8 — KONHAGEN GAMES — browser edition for GitHub Pages.
import { firebaseConfig } from './firebase-config.js';

const $ = id => document.getElementById(id);
const TWO_PI = 2 * Math.PI;
const clamp = (n,min,max) => Math.max(min,Math.min(max,n));
const angDiff = (a,b) => Math.abs(Math.atan2(Math.sin(a-b),Math.cos(a-b)));
const randomAngle = () => Math.random()*TWO_PI;
const collections = [
  {title:'Aurora',subtitle:'The Beginning',boss:'The Sentinel',accent:'#b7d6db'},
  {title:'Monolith',subtitle:'Gravity Control',boss:'The Vortex',accent:'#c4c9d1'},
  {title:'Equinox',subtitle:'Master the Illusion',boss:'Mirror Warden',accent:'#d4c6b4'},
  {title:'Obsidian',subtitle:'Enter the Darkness',boss:'The Prism',accent:'#c6abb0'},
  {title:'Zenith',subtitle:'The Final Ascension',boss:'Eclipse Titan',accent:'#d7bf99'}
];
const names=['First Light','Silent Orbit','Blue Passage','The Pulse','Signal Drift','Clear Skies','Convergence','The Sentinel',
'Gravity Line','Vortex Rise','Shift Point','Angular Motion','Double Passage','Pressure Field','The Descent','The Vortex',
'Reflection','Split Signal','False Entry','Afterimage','Blind Corner','Fracture','Mirrorfall','Mirror Warden',
'Cold Start','Black Signal','Obsidian Gate','Red Horizon','Overdrive','The Divide','No Escape','The Prism',
'Final Ascent','The Pattern','Zenith Pulse','Shattered Orbit','Critical Mass','Silent Dawn','Terminal Velocity','Eclipse Titan'];
const missions=names.map((title,index)=>{
  const id=index+1,collection=Math.floor(index/8),boss=id%8===0;
  return {id,title,collection,boss,gateGoal:boss?12+collection*4:7+Math.floor(index*.7),
    defenseGoal:boss?5+collection*3:3+Math.floor(index*.3),
    orbitGoal:boss?5+collection*2:3+Math.floor(index*.14),
    capacity:clamp(12-collection,7,12),bossHP:boss?6+collection*3:0};
});
const skinTypes=[
  {id:'standard',name:'Polar',accent:'#b7d6db',symbol:'◈',hint:'Standard · Included'},
  {id:'aurora',name:'Aurora Glass',accent:'#9dbec6',symbol:'◇',hint:'24★ i Aurora'},
  {id:'copper',name:'Monolith Copper',accent:'#d2af8c',symbol:'✧',hint:'24★ i Monolith'},
  {id:'prism',name:'Equinox Prism',accent:'#b9b8db',symbol:'⬡',hint:'24★ i Equinox'},
  {id:'carbon',name:'Void Carbon',accent:'#b6b6b8',symbol:'◆',hint:'24★ i Obsidian'},
  {id:'zenith',name:'Zenith Gold',accent:'#d7bf99',symbol:'✦',hint:'24★ i Zenith'}
];
const storageKey='konhagen-orbit-zero-web-v18';
function loadSaved(){try{let d=JSON.parse(localStorage.getItem(storageKey));return {stars:Array.isArray(d?.stars)&&d.stars.length===40?d.stars.map(x=>clamp(Math.floor(Number(x)||0),0,3)):Array(40).fill(0),best:Number(d?.best)||0,skin:String(d?.skin||'standard'),xp:Number(d?.xp)||0};}catch{return {stars:Array(40).fill(0),best:0,skin:'standard',xp:0};}}
const saved=loadSaved();
const writeSave=()=>{try{localStorage.setItem(storageKey,JSON.stringify(saved));}catch{}};
function unlockedIndex(){let i=0;while(i<40&&saved.stars[i]>0)i++;return Math.min(i,39);}
function collectionMastery(c){return saved.stars.slice(c*8,c*8+8).reduce((sum,n)=>sum+n,0)===24;}
function rankName(xp){return xp>=6000?'Elite Commander':xp>=3500?'Commander':xp>=2100?'Pathfinder':xp>=1100?'Navigator':xp>=500?'Vanguard':xp>=180?'Pilot':'Cadet';}
let screen='home',selected=0,collection=0,session=null,network=null,onlineRole=null,roomStatus='',lastRivalAttacks=0,opponentOfflineAt=0;
let toastTimer=null,animatedResult=0,viewState='none',lastFrame=0;
let notifications=0;
const audio={music:null,current:'',sfx:{},muted:false};
const audioBase='./audio/';
function sound(name){
  try{
    let a=audio.sfx[name];if(!a){a=new Audio(audioBase+name+'.mp3');a.volume=.26;audio.sfx[name]=a;}
    a.currentTime=0;a.play().catch(()=>{});
    if(navigator.vibrate&&['fail','perfect','victory'].includes(name))navigator.vibrate(name==='fail'?50:22);
  }catch{}
}
function soundtrack(type){
  if(audio.current===type)return;
  audio.current=type;
  if(audio.music){audio.music.pause();audio.music=null;}
  if(type==='none')return;
  try{audio.music=new Audio(audioBase+(type==='battle'?'boss_protocol':'orbit_ambient')+'.mp3');audio.music.loop=true;audio.music.volume=type==='battle'?.21:.13;audio.music.play().catch(()=>{});}catch{}
}
function notice(text){const box=$('snackbar');box.textContent=text;box.hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>box.hidden=true,3100)}
function battleToast(text){const el=$('game-toast');el.textContent=text;el.classList.remove('visible');void el.offsetWidth;el.classList.add('visible')}
function show(id){screen=id;for(const el of document.querySelectorAll('.screen'))el.classList.toggle('active',el.id===`screen-${id}`);if(id!=='game')soundtrack('none');if(id==='home')renderHome();if(id==='missions')renderMissions();if(id==='shop')renderHangar();}
function renderHome(){$('home-progress').textContent=`MISSION ${String(unlockedIndex()+1).padStart(2,'0')} / 40 · ${rankName(saved.xp).toUpperCase()}`;$('home-best').textContent='BEST · '+saved.best.toLocaleString('da-DK');}
function renderMissions(){
  $('stars-counter').textContent=`${saved.stars.reduce((a,b)=>a+b,0)} / 120 ★`;
  $('collection-tabs').innerHTML=collections.map((c,i)=>`<button class="collection-tab ${collection===i?'active':''} ${i*8>unlockedIndex()?'locked':''}" data-c="${i}" aria-label="${c.title}">${String(i+1).padStart(2,'0')}${i*8>unlockedIndex()?' ·⌑':''}</button>`).join('');
  let c=collections[collection],locked=collection*8>unlockedIndex();
  $('collection-intro').innerHTML=`<strong>${c.title} <span style="color:var(--muted)">/ ${c.subtitle}</span></strong><p>${locked?'Låst – besejr den forrige Collection-boss.':'8 missioner · '+(collectionMastery(collection)?'Collection mastered':'Find alle 24 stjerner for at mestre den.')}</p>`;
  $('mission-list').innerHTML=missions.slice(collection*8,collection*8+8).map(m=>{
    let open=m.id<=unlockedIndex()+1,stars=saved.stars[m.id-1];return `<button class="mission-card ${m.boss?'boss':''}" data-m="${m.id}" ${open?'':'disabled'}><span class="id">${open?String(m.id).padStart(2,'0'):'⌑'}</span><span class="mission-info"><b>${m.title}${m.boss?' · BOSS':''}</b><small>${open?(m.boss?'Final encounter':'Precision · Defense · Survival'):'Complete previous mission to unlock'}</small></span><span class="stars">${stars?'★'.repeat(stars)+'☆'.repeat(3-stars):open?'→':'—'}</span></button>`;
  }).join('');
  $('collection-tabs').querySelectorAll('[data-c]').forEach(b=>b.addEventListener('click',()=>{collection=Number(b.dataset.c);renderMissions()}));
  $('mission-list').querySelectorAll('[data-m]').forEach(b=>b.addEventListener('click',()=>{selected=Number(b.dataset.m)-1;renderBrief();show('brief')}));
}
function renderBrief(){const m=missions[selected],c=collections[m.collection];$('brief-collection').textContent=`COLLECTION ${String(m.collection+1).padStart(2,'0')} · ${c.title.toUpperCase()}`;$('brief-title').textContent=`${m.boss?'Boss':'Mission'} ${String(m.id).padStart(2,'0')}`;$('brief-mark').textContent=m.boss?'◎':String(m.id).padStart(2,'0');$('brief-text').textContent=m.boss?`${m.title}: overlev tre faser, bryd bossens skjolde og forsvar din orbit.`:`${m.title}: hold computerens farepunkter nede, mens du opfylder alle tre missionskrav.`;$('brief-gates').textContent=m.gateGoal;$('brief-defend').textContent=m.defenseGoal;$('brief-orbits').textContent=m.orbitGoal;}
function unlockedSkin(s){return s.id==='standard'||(s.id==='aurora'&&collectionMastery(0))||(s.id==='copper'&&collectionMastery(1))||(s.id==='prism'&&collectionMastery(2))||(s.id==='carbon'&&collectionMastery(3))||(s.id==='zenith'&&collectionMastery(4));}
function renderHangar(){$('skin-grid').innerHTML=skinTypes.map(s=>`<button class="skin-btn ${saved.skin===s.id?'active':''}" data-skin="${s.id}" ${unlockedSkin(s)?'':'disabled'}><span style="color:${s.accent}">${s.symbol}</span>${s.name}<small>${saved.skin===s.id?'Equipped':unlockedSkin(s)?'Unlocked':s.hint+' · Locked'}</small></button>`).join('');$('skin-grid').querySelectorAll('[data-skin]').forEach(btn=>btn.addEventListener('click',()=>{const s=skinTypes.find(x=>x.id===btn.dataset.skin);if(!s||!unlockedSkin(s))return;saved.skin=s.id;writeSave();renderHangar();notice('Rumskib opdateret: '+s.name)}));}
function prepareSession(type='campaign'){
  const m=type==='campaign'?missions[selected]:type==='duel'?{id:0,title:'Orbit Duel',collection:2,gateGoal:0,defenseGoal:0,orbitGoal:0,capacity:12,bossHP:0,boss:false}:{id:0,title:'Endless Orbit',collection:2,gateGoal:0,defenseGoal:0,orbitGoal:0,capacity:12,bossHP:0,boss:false};
  const started=Date.now();
  return {type,m,started,active:true,angle:-Math.PI/2,previousAngle:-Math.PI/2,laps:0,gate:Math.PI*.3,gateDrift:.22,points:[],particle:[],score:0,shields:3,hit:0,perfect:0,defense:0,combo:0,attacks:0,received:0,bossHp:m.bossHP,failures:0,elapsed:0,flipTime:0,shieldFlash:0,ending:false,rankStart:saved.xp,phase:1,prevPressed:0,focus:0,showGate2:false,gate2:2.5,finishStatus:'',resultReason:''};
}
function startSolo(type){
  if(type==='campaign'&&selected>unlockedIndex()){notice('Gennemfør den forrige mission først.');return;}
  session=prepareSession(type);lastFrame=performance.now();show('game');refreshHUD();sound('start');soundtrack(musicType());
}
function duelStart(){session=prepareSession('duel');lastRivalAttacks=0;lastFrame=performance.now();show('game');refreshHUD();sound('start');soundtrack('battle');}
function musicType(){return session&&(session.type==='duel'||session.m.boss||session.points.length>=7)?'battle':'ambient';}
function spawnTargets(count,kind='computer'){
  if(!session)return;
  for(let i=0;i<count;i++){
    if(session.points.length>=session.m.capacity){endSession('lose','Computer Wins');return;}
    let a=randomAngle();for(let r=0;r<20;r++){
      if(session.points.every(p=>angDiff(p.angle,a)>.30)&&angDiff(a,session.gate)>.3)break;
      a=randomAngle();
    }
    session.points.push({angle:a,kind,t:0});
  }
  session.shieldFlash=.15;
  sound('deploy');
  if(session.points.length>=session.m.capacity)endSession('lose',session.type==='duel'?'Pressure Full':'Computer Wins');
}
function releaseParticles(angle,color,count=22){
  if(!session)return;
  for(let i=0;i<count;i++){
    const d=Math.random()*TWO_PI,v=45+Math.random()*160;
    session.particle.push({angle,x:Math.cos(angle)*170,y:Math.sin(angle)*170,vx:Math.cos(d)*v,vy:Math.sin(d)*v,life:.7+Math.random()*.35,clr:color});
  }
  if(session.particle.length>220)session.particle.splice(0,100);
}
function shiftGate(){
  if(!session)return;
  session.gate=session.angle+1.1+Math.random()*4.0;
  session.gateDrift=(Math.random()>.5?1:-1)*(.17+session.m.collection*.045);
  session.gate2=session.gate+1.65;
}
function jump(){
  if(!session?.active||session.ending)return;
  if(performance.now()-session.prevPressed<115)return;
  session.prevPressed=performance.now();
  const s=session,difficulty=s.type==='campaign'?s.m.collection:2;
  const width=gateWidth(s);
  const found=s.points.findIndex(p=>angDiff(s.angle,p.angle)<.18);
  if(found>=0){const p=s.points.splice(found,1)[0];s.defense++;s.score+=140+Math.min(s.combo,8)*35;s.combo++;releaseParticles(p.angle,'#e1adb1',34);battleToast('INTERCEPT +140');sound('intercept');}
  else if(angDiff(s.angle,s.gate)<width || (s.showGate2 && angDiff(s.angle,s.gate2)<width*.85)){
    const best=Math.min(angDiff(s.angle,s.gate),s.showGate2?angDiff(s.angle,s.gate2):9);
    const perfect=best<width*.35;
    s.hit++;if(perfect)s.perfect++;
    s.combo++;s.score+=(perfect?240:115)*Math.min(6,s.combo);
    s.bossHp=s.m.boss?Math.max(0,s.bossHp-1):0;
    releaseParticles(s.angle,perfect?'#d8c99f':'#b7d6db',perfect?47:26);
    battleToast(perfect?'PERFECT':'CLEAN GATE');sound(perfect?'perfect':'success');
    if(s.type==='duel'&&s.hit%2===0){s.attacks++;battleToast('ATTACK SENT');}
    shiftGate();
  }else{failure('MISSED TARGET');}
  refreshHUD();
  if(session?.type==='campaign')checkMission();
  if(session?.type==='duel')sendDuelState(true);
}
function failure(reason){const s=session;if(!s?.active)return;s.shields--;s.combo=0;s.failures++;s.shieldFlash=.8;releaseParticles(s.angle,'#c87b86',16);sound('failure');battleToast(reason);if(s.shields<=0)endSession('lose',s.type==='duel'?'Shields Depleted':'Signal Lost');}
function gateWidth(s){let width=.27-s.m.collection*.019;
 if(s.m.boss){const phase=s.phase;width-=phase*.018;}
 if(s.laps>=5)width-=.024;
 return clamp(width + Math.sin(s.elapsed*2.2)*.03,.14,.32);
}
function checkMission(){const s=session;if(!s||s.ending||s.type!=='campaign')return;
 if(s.hit>=s.m.gateGoal && s.defense>=s.m.defenseGoal && s.laps>=s.m.orbitGoal && (!s.m.boss||s.bossHp===0))endSession('win','Mission Complete');
}
function endSession(outcome,reason){
 const s=session;if(!s||s.ending)return;
 s.ending=true;s.active=false;s.resultReason=reason;s.finishStatus=outcome;
 if(s.type==='duel'){sendDuelState(true);if(outcome==='lose')sound('failure');else sound('victory');}
 else {if(outcome==='win')sound('victory');else sound('failure');}
 if(outcome==='win'&&s.type==='campaign'){
   const stars=1+(s.failures===0?1:0)+(s.hit>0&&s.perfect/s.hit>=.5?1:0);
   saved.stars[s.m.id-1]=Math.max(saved.stars[s.m.id-1],stars);
   saved.xp+=60+(stars-1)*40+(s.m.boss?130:0);
   saved.best=Math.max(saved.best,s.score);writeSave();
 }else if(s.type!=='duel'){saved.best=Math.max(saved.best,s.score);writeSave();}
 animatedResult=Date.now()+900;
 setTimeout(()=>{if(session!==s||s.finishStatus!==outcome)return;showResult(outcome,reason)},950);
}
function showResult(outcome,reason){if(!session)return;const s=session;
 $('result-icon').textContent=outcome==='win'?'✦':outcome==='draw'?'◎':'⨯';
 $('result-sub').textContent=s.type==='duel'?'ORBIT ARENA':s.type==='campaign'?'CAMPAIGN':'ENDLESS';
 $('result-title').textContent=outcome==='win'?(s.type==='duel'?'Victory':'Mission Clear'):outcome==='draw'?'Draw':s.type==='duel'?'Defeat':'Computer Wins';
 $('result-description').textContent=reason+(s.type==='campaign'&&outcome==='win'?` · ${rankName(saved.xp)}`:'');
 $('result-score').textContent=s.score.toLocaleString('da-DK');
 $('result-reward').textContent=s.type==='campaign'&&outcome==='win'?'★'.repeat(saved.stars[s.m.id-1]):s.type==='duel'?outcome==='win'?'WIN':'—':'—';
 const primary=$('result-primary');primary.textContent='';primary.append(document.createTextNode(s.type==='campaign'&&outcome==='win'&&s.m.id<40?'Næste mission →':s.type==='duel'?'Ny duel →':'Til kampagnen →'));
 $('result-retry').hidden=s.type==='duel';
 soundtrack('none');show('result');
}
function refreshHUD(){const s=session;if(!s)return;
 $('hud-mission').textContent=s.type==='duel'?'DUEL':s.type==='endless'?'∞':String(s.m.id).padStart(2,'0');
 $('hud-score').textContent=s.score.toLocaleString('da-DK');$('hud-shields').textContent='● '.repeat(Math.max(0,s.shields));
 $('objective-name').textContent=s.type==='campaign'?s.m.boss?`BOSS · ${s.m.title.toUpperCase()}`:'HIT GATES':s.type==='duel'?'VS '+(network?.data?(network.side==='host'?network.data.guestName:network.data.hostName)||'PILOT':'PILOT'):'ENDLESS';
 $('objective-progress').textContent=s.type==='campaign'?s.m.boss?`${s.hit}/${s.m.gateGoal} · BOSS HP ${s.bossHp}`:`${s.hit}/${s.m.gateGoal}`:s.type==='duel'?`${s.score} pts`:`${s.hit} gates`;
 $('pressure-num').textContent=`${s.points.length}/${s.m.capacity}`;
 $('pressure-segments').innerHTML=Array.from({length:s.m.capacity},(_,i)=>`<i class="${i<s.points.length?'on':''}"></i>`).join('');
 $('stat-defense').textContent=s.type==='campaign'?`${s.defense}/${s.m.defenseGoal}`:String(s.defense);
 $('stat-orbits').textContent=s.type==='campaign'?`${s.laps}/${s.m.orbitGoal}`:String(s.laps);
 $('stat-combo').textContent=String(s.combo);
}
const canvas=$('orbit-canvas'),ctx=canvas.getContext('2d');
function arc(x,y,r,a,b,color,width,glow=0){ctx.beginPath();ctx.arc(x,y,r,a,b);ctx.lineWidth=width;ctx.strokeStyle=color;ctx.lineCap='round';if(glow){ctx.shadowBlur=glow;ctx.shadowColor=color;}ctx.stroke();ctx.shadowBlur=0;}
function text(label,x,y,size,color='#a5b8bc',weight=500){ctx.textAlign='center';ctx.fillStyle=color;ctx.font=`${weight} ${size}px -apple-system,system-ui,sans-serif`;ctx.fillText(label,x,y);}
function drawFrame(){
 if(!ctx)return;
 const w=canvas.width,h=canvas.height,C=w/2,R=223;
 ctx.clearRect(0,0,w,h);const grad=ctx.createRadialGradient(C,C,80,C,C,445);grad.addColorStop(0,'#1c2a2d');grad.addColorStop(1,'#11191d');ctx.fillStyle=grad;ctx.fillRect(0,0,w,h);
 for(let i=0;i<60;i++){let x=(i*193+17)%720,y=(i*281+81)%720;ctx.fillStyle=`rgba(161,181,185,${.10+(i%5)*.02})`;ctx.fillRect(x,y,1+(i%3===0?1:0),1+(i%3===0?1:0));}
 ctx.save();ctx.translate(C,C);
 arc(0,0,R,0,TWO_PI,'#31454c',3);arc(0,0,R-20,0,TWO_PI,'#23363b',1);arc(0,0,R+19,0,TWO_PI,'#23363b',1);
 const s=session;
 if(s){
   const width=gateWidth(s);arc(0,0,R,s.gate-width,s.gate+width,'#b7d6db',13,12);arc(0,0,R,s.gate-width+.035,s.gate+width-.035,'#e2f0f1',3);
   if(s.showGate2)arc(0,0,R,s.gate2-width*.9,s.gate2+width*.9,'#c7b991',12,8);
   for(const p of s.points){p.t+=.015;const x=Math.cos(p.angle)*R,y=Math.sin(p.angle)*R;ctx.fillStyle='#c67f87';ctx.shadowBlur=11;ctx.shadowColor='#cc7f87';ctx.beginPath();ctx.arc(x,y,9+Math.sin(p.t*4)*1.2,0,TWO_PI);ctx.fill();ctx.shadowBlur=0;ctx.fillStyle='#152126';ctx.beginPath();ctx.arc(x,y,3,0,TWO_PI);ctx.fill();}
   const skin=skinTypes.find(x=>x.id===saved.skin)||skinTypes[0];
   for(let k=6;k>0;k--){const a=s.angle-k*.072;ctx.fillStyle=`rgba(173,215,219,${(7-k)*.04})`;ctx.beginPath();ctx.arc(Math.cos(a)*R,Math.sin(a)*R,3,0,TWO_PI);ctx.fill();}
   const sx=Math.cos(s.angle)*R,sy=Math.sin(s.angle)*R;
   ctx.save();ctx.translate(sx,sy);ctx.rotate(s.angle+Math.PI/2);ctx.fillStyle=skin.accent;ctx.shadowBlur=12;ctx.shadowColor=skin.accent;ctx.beginPath();ctx.moveTo(0,-18);ctx.lineTo(11,12);ctx.lineTo(0,6);ctx.lineTo(-11,12);ctx.closePath();ctx.fill();ctx.restore();ctx.shadowBlur=0;
   const boss=s.m.boss&&s.type==='campaign';const coreCol=boss?'#c69197':'#b7d6db';
   ctx.save();ctx.rotate(s.elapsed*(boss?-.37:.16));ctx.beginPath();for(let k=0;k<(boss?8:6);k++){let a=k*TWO_PI/(boss?8:6)-Math.PI/2,r=boss?68:55;let x=Math.cos(a)*r,y=Math.sin(a)*r;k?ctx.lineTo(x,y):ctx.moveTo(x,y)}ctx.closePath();ctx.fillStyle=boss?'#3f2d32':'#253b40';ctx.strokeStyle=coreCol;ctx.lineWidth=4;ctx.fill();ctx.stroke();ctx.restore();arc(0,0,33,0,TWO_PI,coreCol,4);ctx.fillStyle=coreCol;ctx.beginPath();ctx.arc(0,0,13,0,TWO_PI);ctx.fill();
   text(boss?'BOSS CORE':s.type==='duel'?'ORBIT ARENA':'ORBIT CORE',0,108,15,'#b6c5c8',600);
   if(boss){text('PHASE '+s.phase+' / 3',0,138,12,'#d2a2a8');}
   text(s.ending?s.finishStatus==='win'?'MISSION CLEAR':'SIGNAL LOST':s.type==='duel'?'DUEL · 90 SEC':`MISSION ${String(s.m.id||0).padStart(2,'0')}`,0,-R-62,15,'#abc7cb',550);
   for(const p of s.particle){ctx.globalAlpha=clamp(p.life,0,1);ctx.fillStyle=p.clr;ctx.beginPath();ctx.arc(p.x,p.y,3,0,TWO_PI);ctx.fill();}ctx.globalAlpha=1;
   if(s.shieldFlash>0){ctx.fillStyle=`rgba(200,105,120,${s.shieldFlash*.14})`;ctx.fillRect(-C,-C,w,h);}
 }else{arc(0,0,60,0,TWO_PI,'#b7d6db',3);}
 ctx.restore();
}
function updateFrame(now){
 const dt=clamp((now-lastFrame)/1000,0,.06);lastFrame=now;
 if(session&&session.active){
   const s=session;const speed=1.60+Math.min(.8,s.m.collection*.17)+(s.type==='duel'?.11:0)+Math.min(.24,s.laps*.007);
   s.elapsed+=dt;s.previousAngle=s.angle;s.angle+=speed*dt;
   s.gate+=s.gateDrift*dt;
   if(s.m.collection>=1 && Math.floor(s.elapsed/5)!==Math.floor((s.elapsed-dt)/5)){
     s.gateDrift*=-1;if(s.m.collection>=2)battleToast('DIRECTION SHIFT');
   }
   s.phase=s.m.boss?clamp(1+Math.floor((1-(s.bossHp/s.m.bossHP))*3),1,3):1;
   s.showGate2=s.m.collection>=2 && s.laps>=3 && Math.floor(s.elapsed/7)%2===0;
   if(Math.floor((s.angle+Math.PI/2)/TWO_PI)>Math.floor((s.previousAngle+Math.PI/2)/TWO_PI)){
      s.laps++;spawnTargets(2);
      if(s.active) {refreshHUD();checkMission();}
   }
   if(s.particle.length){for(let p of s.particle){p.x+=p.vx*dt;p.y+=p.vy*dt;p.life-=dt*1.8;}s.particle=s.particle.filter(p=>p.life>0)}
   s.shieldFlash=Math.max(0,s.shieldFlash-dt);
   if(s.type==='duel'){
     if(s.elapsed>=90){
       const rival=network?.data?.players?.[network.side==='host'?'guest':'host'];
       const otherScore=Number(rival?.score||0);
       const outcome=s.score>otherScore?'win':s.score<otherScore?'lose':'draw';
       endSession(outcome,'Time Limit');
     }
     if(opponentOfflineAt&&Date.now()-opponentOfflineAt>11000)endSession('win','Opponent Disconnected');
     sendDuelState();
   }
   if(s.type==='endless'&&s.elapsed>300)endSession('win','Endless Milestone');
   if(s.type==='campaign'&&s.elapsed>Math.max(110,150-s.m.collection*5))endSession('lose','Time Expired');
   if(audio.current!==musicType())soundtrack(musicType());
 }
 if(screen==='game')drawFrame();
 requestAnimationFrame(updateFrame);
}
function pause(){if(!session)return;if(session.type==='duel'){notice('Online Duel kan ikke pauses.');return;}session.active=false;show('pause');}
function quit(){if(session?.type==='duel'&&network){endSession('lose','Forfeit');network.leave().catch(()=>{});}session=null;show('home');}
function resultPrimary(){const s=session;if(!s)return show('home');if(s.type==='duel'){session=null;network?.leave().catch(()=>{});show('arena');return;}if(s.type==='campaign'&&s.finishStatus==='win'&&s.m.id<40){selected=Math.min(39,s.m.id);renderBrief();show('brief');return;}collection=s.m.collection;show('missions');}
async function enterArena(){show('arena');const input=new URLSearchParams(location.search).get('room');if(input)$('room-input').value=input.toUpperCase().slice(0,6);try{$('player-name').value=localStorage.getItem('oz-web-name')||'';}catch{$('player-name').value='';}const configured=Object.values(firebaseConfig).every(Boolean);$('online-status').textContent=configured?'Online klar · Firebase Realtime':'Online klar · Direct P2P (WebRTC)';$('online-status').classList.remove('error');$('online-help').textContent=configured?'Duel via Firebase. Begge spillere skal bruge samme webadresse.':'Ingen konto nødvendig. I forbindes direkte via WebRTC og offentlige signaleringsrelæer; nogle mobilnet kan blokere forbindelsen.';$('create-room').disabled=false;$('join-room').disabled=false;}
async function getNet(){if(!network){const configured=Object.values(firebaseConfig).every(Boolean);const {DuelNetwork}=await import(configured?'./net.js':'./net-p2p.js');network=new DuelNetwork();network.onRoom=onRoomChanged;network.onError=e=>{notice('Forbindelsesfejl: '+(e?.message||'Kontrollér netværket'))}}return network;}
async function createOrJoin(join){
 let name=$('player-name').value.trim()||'Pilot';try{localStorage.setItem('oz-web-name',name)}catch{};
 const create=$('create-room'),joinbtn=$('join-room');create.disabled=true;joinbtn.disabled=true;
 $('online-status').textContent='Forbinder til online arena…';
 try{let net=await getNet();let code=join?await net.join($('room-input').value,name):await net.create(name);onlineRole=net.side;
 $('lobby-code').textContent=code;$('lobby-self').textContent=name;roomStatus='waiting';show('lobby');renderLobby(net.data);
 }catch(e){notice(e?.message||'Kunne ikke forbinde');$('online-status').textContent='Kunne ikke oprette forbindelse. Se opsætningen.';$('online-status').classList.add('error');create.disabled=false;joinbtn.disabled=false;}
}
function renderLobby(data){if(!data)return;let host=network?.side==='host';$('lobby-self').textContent=host?data.hostName||'Pilot':data.guestName||'Pilot';$('lobby-opponent').textContent=host?(data.guestName||'Venter på din ven…'):(data.hostName||'Vært');$('opponent-state').textContent=(host?data.players?.guest?.online:data.players?.host?.online)?'KLAR':'VENTER';$('start-duel').hidden=!host;$('start-duel').disabled=!(data.guestUid&&data.players?.guest?.online);$('lobby-message').textContent=data.guestUid?'Begge spillere er tilsluttet. Værten kan starte kampen.':'Send invitationslinket til din ven.';}
function onRoomChanged(data){if(!network||!data)return;
 if(screen==='lobby')renderLobby(data);
 if(data.status==='playing'&&screen==='lobby'){opponentOfflineAt=0;duelStart();}
 if(session?.type!=='duel'||screen!=='game'||!session.active)return;
 const rival=network.side==='host'?data.players?.guest:data.players?.host;
 if(!rival)return;
 if(rival.attacks>lastRivalAttacks){const count=Math.min(6,rival.attacks-lastRivalAttacks);lastRivalAttacks=rival.attacks;spawnTargets(count,'rival');battleToast('INCOMING ATTACK');sound('surge');refreshHUD();}
 if(rival.lost){endSession('win','Opponent Defeated');return;}
 if(rival.online===false){if(!opponentOfflineAt)opponentOfflineAt=Date.now();}else opponentOfflineAt=0;
 if(data.status==='finished'){
   let score=session.score,other=Number(rival.score||0);endSession(score>other?'win':score<other?'lose':'draw','Time Limit');
 }
}
function sendDuelState(force=false){if(session?.type!=='duel'||!network)return;network.send({score:session.score,pressure:session.points.length,shields:session.shields,attacks:session.attacks,lost:session.finishStatus==='lose'},force);}

// Navigation — the home screen never scrolls; section-specific lists can scroll.
$('continue-btn').addEventListener('click',()=>{selected=unlockedIndex();renderBrief();show('brief');});
$('missions-btn').addEventListener('click',()=>{collection=Math.floor(unlockedIndex()/8);show('missions');});
$('arena-btn').addEventListener('click',enterArena);
$('endless-btn').addEventListener('click',()=>startSolo('endless'));
$('shop-btn').addEventListener('click',()=>show('shop'));
for(const b of document.querySelectorAll('[data-back]'))b.addEventListener('click',()=>show('home'));
$('launch-btn').addEventListener('click',()=>startSolo('campaign'));
$('jump-btn').addEventListener('click',jump);
$('orbit-canvas').addEventListener('pointerdown',e=>{e.preventDefault();jump();});
$('pause-btn').addEventListener('click',pause);
$('resume-btn').addEventListener('click',()=>{if(session){session.active=true;lastFrame=performance.now();show('game');soundtrack(musicType());}});
$('restart-btn').addEventListener('click',()=>startSolo(session?.type==='endless'?'endless':'campaign'));
$('quit-btn').addEventListener('click',quit);
$('result-primary').addEventListener('click',resultPrimary);
$('result-retry').addEventListener('click',()=>startSolo(session?.type==='endless'?'endless':'campaign'));
$('result-home').addEventListener('click',()=>{if(network?.code)network.leave().catch(()=>{});session=null;show('home')});
$('create-room').addEventListener('click',()=>createOrJoin(false));
$('join-room').addEventListener('click',()=>createOrJoin(true));
$('room-input').addEventListener('input',e=>{e.target.value=e.target.value.toUpperCase().replace(/[^A-HJ-NP-Z2-9]/g,'').slice(0,6)});
$('start-duel').addEventListener('click',async()=>{try{await network.start()}catch(e){notice(e.message)}});
$('copy-link').addEventListener('click',async()=>{const code=network?.code;if(!code)return;const url=new URL(location.href);url.searchParams.set('room',code);try{await navigator.clipboard.writeText(url.toString());notice('Invitationslink kopieret')}catch{notice('Del denne kode: '+code);}});
$('leave-lobby').addEventListener('click',async()=>{try{await network?.leave()}catch{};show('arena')});
window.addEventListener('keydown',e=>{if(e.code==='Space'&&screen==='game'&&!e.repeat){e.preventDefault();jump()}else if(e.code==='Escape'&&screen==='game'){pause()}});
window.addEventListener('pagehide',()=>{if(network?.code)network.leave().catch(()=>{});});
renderHome();requestAnimationFrame(updateFrame);
if(new URLSearchParams(location.search).has('room'))enterArena();
