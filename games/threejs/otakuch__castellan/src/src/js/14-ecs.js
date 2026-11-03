/* ══════════════ 8 · a small entity/component/system world ══════════════
   Entities are ints. Components are plain records in per-type maps.
   Systems declare a query and are run in order once a frame.            */
class EntityManager{
  constructor(){ this.next=1; this.alive=new Set(); }
  create(){ const e=this.next++; this.alive.add(e); return e; }
  destroy(e){ this.alive.delete(e); }
}
class ComponentManager{
  constructor(){ this.stores=new Map(); }
  store(t){ let s=this.stores.get(t); if(!s){s=new Map(); this.stores.set(t,s);} return s; }
  add(e,t,data){ this.store(t).set(e,data||{}); return data; }
  get(e,t){ const s=this.stores.get(t); return s?s.get(e):undefined; }
  has(e,t){ const s=this.stores.get(t); return !!s&&s.has(e); }
  remove(e,t){ const s=this.stores.get(t); if(s) s.delete(e); }
  removeAll(e){ this.stores.forEach(s=>s.delete(e)); }
  count(t){ const s=this.stores.get(t); return s?s.size:0; }
}
class System{
  constructor(world,types){ this.world=world; this.types=types||[]; }
  entities(){ return this.world.query(this.types); }
  update(){}
}
class World{
  constructor(){ this.em=new EntityManager(); this.cm=new ComponentManager();
                 this.systems=[]; this.queries=new Map(); this.singletons={}; }
  spawn(spec){
    const e=this.em.create();
    for(const t in spec) this.cm.add(e,t,spec[t]);
    this.queries.clear();
    return e;
  }
  kill(e){ this.cm.removeAll(e); this.em.destroy(e); this.queries.clear(); }
  add(e,t,d){ this.cm.add(e,t,d); this.queries.clear(); }
  get(e,t){ return this.cm.get(e,t); }
  count(t){ return this.cm.count(t); }
  /* cached until the entity set changes */
  query(types){
    const key=types.join('|');
    let list=this.queries.get(key);
    if(list) return list;
    list=[];
    const first=this.cm.stores.get(types[0]);
    if(first) first.forEach((_,e)=>{
      for(let i=1;i<types.length;i++) if(!this.cm.has(e,types[i])) return;
      list.push(e);
    });
    this.queries.set(key,list);
    return list;
  }
  register(sys){ this.systems.push(sys); return sys; }
  update(dt,simDt){
    for(let i=0;i<this.systems.length;i++){
      const s=this.systems[i];
      s.update(s.always?dt:(simDt===undefined?dt:simDt));
    }
  }
  clear(){ this.em=new EntityManager(); this.cm=new ComponentManager(); this.queries.clear(); }
}

/* component names, in one place so a typo fails loudly */
const C={TRANSFORM:'Transform',RENDER:'Render',GAIT:'Gait',LOCO:'Loco',PATH:'Path',
         ROUTINE:'Routine',GRAZER:'Grazer',SENTRY:'Sentry',FLYER:'Flyer',CART:'Cart',
         HUMAN:'Human',BEAST:'Beast',BIRD:'Bird',WATCH:'Watch',HEARTH:'Hearth'};
const world=new World();
/* the clock is a singleton component — a live view of the interface's own state */
world.singletons.clock={
  get hour(){return hour;}, set hour(v){hour=v;},
  get running(){return running;}, get pace(){return pace;},
  bucket:-1, retask:false
};
world.singletons.wind={strength:1,phase:0};

