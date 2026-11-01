// Firebase Realtime Database transport for private casual duels.
// This module is dynamically imported only when Online Duel is opened.
import { firebaseConfig } from './firebase-config.js';

const fireVersion = '11.6.1';
const allowed = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export class DuelNetwork {
  constructor() {
    this.db = null;
    this.auth = null;
    this.api = null;
    this.uid = null;
    this.code = null;
    this.side = null;
    this.role = null;
    this.data = null;
    this.listener = null;
    this.connectionRef = null;
    this.onRoom = () => {};
    this.onError = () => {};
    this.lastSent = 0;
  }

  get configured() {
    return Boolean(firebaseConfig.apiKey && firebaseConfig.projectId && firebaseConfig.databaseURL && firebaseConfig.authDomain);
  }

  async connect() {
    if (!this.configured) throw new Error('Online kræver Firebase-opsætning. Se README.md.');
    if (this.uid && this.db) return;
    const [{initializeApp, getApps}, {getAuth, signInAnonymously}, dbMod] = await Promise.all([
      import(`https://www.gstatic.com/firebasejs/${fireVersion}/firebase-app.js`),
      import(`https://www.gstatic.com/firebasejs/${fireVersion}/firebase-auth.js`),
      import(`https://www.gstatic.com/firebasejs/${fireVersion}/firebase-database.js`)
    ]);
    const app = getApps().length ? getApps()[0] : initializeApp(firebaseConfig);
    this.auth = getAuth(app);
    this.db = dbMod.getDatabase(app);
    this.api = dbMod;
    if (!this.auth.currentUser) await signInAnonymously(this.auth);
    this.uid = this.auth.currentUser.uid;
  }

  path(path='') { return this.api.ref(this.db, `rooms/${this.code}${path ? '/' + path : ''}`); }
  makeCode(){const values=new Uint32Array(6);crypto.getRandomValues(values);return Array.from(values,n=>allowed[n%allowed.length]).join('');}
  cleanName(name){return String(name||'Pilot').replace(/[^a-zA-Z0-9 æøåÆØÅ._\-]/g,'').trim().slice(0,16)||'Pilot';}

  async create(name) {
    await this.connect();
    this.code = this.makeCode();
    this.side = 'host'; this.role = 'host';
    const initial = {
      hostUid: this.uid,
      hostName: this.cleanName(name),
      status: 'waiting',
      createdAt: Date.now(),
      players: {host: {score:0,pressure:0,shields:3,attacks:0,lost:false,online:true,lastSeen:Date.now()} }
    };
    // Extremely unlikely code collisions are retried rather than overwriting a room.
    for(let i=0;i<6;i++) {
      const r=this.api.runTransaction(await Promise.resolve(this.path()),current=>current===null?initial:undefined,{applyLocally:false});
      const res=await r;
      if(res.committed){this.listen();await this.connectPresence();return this.code;}
      this.code=this.makeCode();
    }
    throw new Error('Kunne ikke oprette en unik rumkode. Prøv igen.');
  }

  async join(code,name){
    await this.connect();
    this.code=String(code||'').toUpperCase().replace(/[^A-Z2-9]/g,'');
    if(!/^[A-HJ-NP-Z2-9]{6}$/.test(this.code))throw new Error('Rumkoden skal have 6 tegn.');
    const snapshot=await this.api.get(this.path());
    if(!snapshot.exists())throw new Error('Rummet findes ikke. Kontrollér koden.');
    const room=snapshot.val();
    if(room.status!=='waiting')throw new Error('Denne kamp er allerede begyndt.');
    if(room.hostUid===this.uid)throw new Error('Du er allerede vært i dette rum.');
    const joined=await this.api.runTransaction(this.path('guestUid'),val=>val===null?this.uid:undefined,{applyLocally:false});
    if(!joined.committed)throw new Error('Rummet har allerede to spillere.');
    this.side='guest';this.role='guest';
    await this.api.set(this.path('guestName'),this.cleanName(name));
    await this.api.set(this.path('players/guest'),{score:0,pressure:0,shields:3,attacks:0,lost:false,online:true,lastSeen:Date.now()});
    this.listen();await this.connectPresence();
    return this.code;
  }

  listen(){
    if(this.listener){this.listener();this.listener=null;}
    this.listener=this.api.onValue(this.path(),s=>{this.data=s.val();this.onRoom(this.data);},err=>this.onError(err));
  }

  async connectPresence(){
    const presence=this.path(`players/${this.side}/online`);
    this.connectionRef=presence;
    await this.api.onDisconnect(presence).set(false);
    await this.api.set(presence,true);
  }

  async start(){
    if(this.side!=='host')throw new Error('Kun værten kan starte kampen.');
    if(!this.data?.guestUid)throw new Error('Vent på din ven.');
    if(this.data.status!=='waiting')return;
    await this.api.set(this.path('status'),'playing');
  }

  send(stats,force=false){
    if(!this.uid||!this.code||!this.side||this.data?.status!=='playing')return;
    if(!force&&Date.now()-this.lastSent<450)return;
    this.lastSent=Date.now();
    const player={score:Math.max(0,Math.floor(stats.score||0)),pressure:Math.max(0,Math.floor(stats.pressure||0)),shields:Math.max(0,Math.floor(stats.shields||0)),attacks:Math.max(0,Math.floor(stats.attacks||0)),lost:!!stats.lost,online:true,lastSeen:Date.now()};
    this.api.update(this.path(`players/${this.side}`),player).catch(err=>this.onError(err));
  }

  async finish(){
    if(this.side==='host' && this.code && this.data?.status==='playing'){
      try{await this.api.set(this.path('status'),'finished');}catch{}
    }
  }

  async leave(){
    if(!this.db||!this.code)return;
    try{await this.api.set(this.path(`players/${this.side}/online`),false);}catch{}
    try{await this.api.onDisconnect(this.connectionRef).cancel();}catch{}
    if(this.listener){this.listener();this.listener=null;}
    this.code=null;this.side=null;this.data=null;this.lastSent=0;
  }
}
