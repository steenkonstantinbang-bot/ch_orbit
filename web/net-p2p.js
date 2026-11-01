// Serverless online duels: Trystero/Nostr signaling -> direct encrypted WebRTC.
// Room codes are ephemeral. No user accounts or database required.
const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export class DuelNetwork {
  constructor(){
    this.code=null;this.side=null;this.room=null;this.data=null;
    this.peer=null;this.uid=null;this.hello=null;this.events=null;this.onRoom=()=>{};this.onError=()=>{};this.lastSent=0;
  }
  makeCode(){let values=new Uint32Array(6);crypto.getRandomValues(values);return [...values].map(x=>letters[x%letters.length]).join('');}
  cleanName(x){return String(x||'Pilot').replace(/[^a-zA-Z0-9 æøåÆØÅ._\-]/g,'').trim().slice(0,16)||'Pilot';}
  async init(code,side,name){
    const {joinRoom}=await import('https://esm.run/trystero@0.26.0');
    this.code=code;this.side=side;this.uid=crypto.randomUUID();this.localName=this.cleanName(name);
    this.data={hostName:side==='host'?this.localName:'',guestName:side==='guest'?this.localName:'',guestUid:side==='guest'?this.uid:null,status:'waiting',players:{host:{online:side==='host',attacks:0,score:0,lost:false},guest:{online:side==='guest',attacks:0,score:0,lost:false}}};
    this.room=joinRoom({appId:'konhagen-games-orbit-zero-v18-browser'},'oz-'+this.code);
    this.hello=this.room.makeAction('hello');
    this.events=this.room.makeAction('duel');
    this.hello.onMessage=(message,meta)=>{
      if(!message||!meta?.peerId||typeof message!=='object')return;
      if(message.side===this.side)return;
      if(this.peer && this.peer!==meta.peerId)return;
      this.peer=meta.peerId;
      if(this.side==='host'){
        this.data.guestUid=meta.peerId;this.data.guestName=this.cleanName(message.name);
        this.data.players.guest.online=true;
      }else{
        this.data.hostName=this.cleanName(message.name);
        this.data.players.host.online=true;
      }
      if(message.kind==='hello')Promise.resolve(this.hello.send({kind:'ack',side:this.side,name:this.localName},{target:this.peer})).catch(()=>{});
      this.onRoom(this.data);
    };
    this.events.onMessage=(message,meta)=>{
      if(!message||!meta?.peerId||meta.peerId!==this.peer)return;
      if(message.kind==='start' && this.side==='guest'){
        this.data.status='playing';this.onRoom(this.data);
      }else if(message.kind==='state'){
        const opp=this.side==='host'?'guest':'host';
        const state=message.state||{};
        this.data.players[opp]={...this.data.players[opp],score:Math.max(0,Number(state.score)||0),pressure:Math.max(0,Number(state.pressure)||0),shields:Math.max(0,Number(state.shields)||0),attacks:Math.max(0,Number(state.attacks)||0),lost:!!state.lost,online:true,lastSeen:Date.now()};
        this.onRoom(this.data);
      }
    };
    this.room.onPeerJoin=peerId=>{
      if(this.peer&&peerId!==this.peer)return;
      Promise.resolve(this.hello.send({kind:'hello',side:this.side,name:this.localName},{target:peerId})).catch(e=>this.onError(e));
    };
    this.room.onPeerLeave=peerId=>{
      if(peerId!==this.peer)return;
      const other=this.side==='host'?'guest':'host';
      this.data.players[other].online=false;
      if(this.side==='host'&&this.data.status==='waiting'){this.data.guestUid=null;this.data.guestName='';this.peer=null;}
      this.onRoom(this.data);
    };
  }
  async create(name){const code=this.makeCode();await this.init(code,'host',name);this.onRoom(this.data);return code;}
  async join(code,name){
    const normalized=String(code||'').toUpperCase().replace(/[^A-Z2-9]/g,'');
    if(!/^[A-HJ-NP-Z2-9]{6}$/.test(normalized))throw new Error('Rumkoden skal have 6 tegn.');
    await this.init(normalized,'guest',name);
    this.onRoom(this.data);return normalized;
  }
  async start(){
    if(this.side!=='host')throw new Error('Kun værten kan starte.');
    if(!this.peer)throw new Error('Vent på din ven.');
    await this.events.send({kind:'start'},{target:this.peer});
    this.data.status='playing';this.onRoom(this.data);
  }
  send(stats,force=false){
    if(this.data?.status!=='playing'||!this.peer||!this.events)return;
    if(!force&&Date.now()-this.lastSent<500)return;
    this.lastSent=Date.now();
    const state={score:Math.floor(stats.score||0),pressure:Math.floor(stats.pressure||0),shields:Math.floor(stats.shields||0),attacks:Math.floor(stats.attacks||0),lost:!!stats.lost};
    Promise.resolve(this.events.send({kind:'state',state},{target:this.peer})).catch(e=>this.onError(e));
  }
  async leave(){
    try{this.room?.leave()}catch{}
    this.room=null;this.hello=null;this.events=null;this.data=null;this.peer=null;this.side=null;this.code=null;
  }
}
