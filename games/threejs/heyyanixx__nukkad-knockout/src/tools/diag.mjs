import { Game } from '../src/game.js'; import { CPU } from '../src/ai.js'; import { ROSTER } from '../src/roster.js'; import {rng} from '../src/game.js';
const st={}; ROSTER.forEach(c=>st[c.id]={w:0,n:0,dmg:0,sup:0,supDmg:0,hits:0});
for (const a of ROSTER) for (const b of ROSTER) { if (a===b) continue; for (let s=1;s<=4;s++){
 const g=new Game({p1:a,p2:b,seed:s*31+a.id.length,stage:['tapri','terrace','platform'][s%3]});
 const ai=[new CPU('normal',rng(s*7+1)),new CPU('normal',rng(s*13+5))]; let n=0;
 const orig=g.spawnSuper.bind(g); g.spawnSuper=(f)=>{st[f.char.id].sup++; orig(f);};
 const od=g.applyDamage.bind(g); g.applyDamage=(att,def,d,o={})=>{const h=def.hp; od(att,def,d,o); if(o.superHit) st[att.char.id].supDmg+=h-def.hp;};
 while(g.phase!=='over'&&n<60*60*8){g.step([ai[0].think(g.f[0],g.f[1],g),ai[1].think(g.f[1],g.f[0],g)]);n++;}
 const w=g.winner; if(w===0)st[a.id].w++; else if(w===1)st[b.id].w++; st[a.id].n++;st[b.id].n++;
 st[a.id].dmg+=g.f[0].stats.dmgDealt; st[b.id].dmg+=g.f[1].stats.dmgDealt; st[a.id].hits+=g.f[0].stats.hits; st[b.id].hits+=g.f[1].stats.hits;
}}
for(const [k,v] of Object.entries(st)) console.log(k.padEnd(9),(100*v.w/v.n).toFixed(0)+'%','dmg/m',(v.dmg/v.n).toFixed(0),'hits/m',(v.hits/v.n).toFixed(1),'sup/m',(v.sup/v.n).toFixed(2),'supDmg/sup',(v.supDmg/Math.max(1,v.sup)).toFixed(1));
