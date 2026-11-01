package.path='./?.lua;./?/init.lua;'..package.path
local Sim=require('game.sim');local Map=require('game.map');local Save=require('game.save');local Window=require('game.window')
local count=0
local function test(name,fn)
 local ok,err=pcall(fn);if not ok then error('FAIL '..name..': '..tostring(err)) end
 count=count+1;print('PASS '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<.001,tostring(a)..' ~= '..tostring(b)) end
local function cargo(kind)
 local s=Sim.new(72891);s.jobs={{location=1,kind=kind}};assert(Sim.pickup(s,1));return s
end
test('deterministic seed and fair initial spawns',function()
 local a,b=Sim.new(72891),Sim.new(72891);eq(#a.cars,6)
 for i,c in ipairs(a.cars) do eq(c.x,b.cars[i].x);eq(c.y,b.cars[i].y);assert((c.x-a.player.x)^2+(c.y-a.player.y)^2>190^2) end
end)
test('spawns never stack or appear in the clamped gameplay view',function()
 for seed=1,200 do
  local s=Sim.new(seed);eq(#s.cars,6)
  for i,c in ipairs(s.cars) do
   assert(not Map.visible(s.player.x,s.player.y,c.x,c.y,24))
   for j=i+1,#s.cars do local b=s.cars[j];assert((c.x-b.x)^2+(c.y-b.y)^2>=48^2) end
  end
 end
 for _,pos in ipairs({{66,66},{894,66},{66,628},{894,628}}) do
  local s=Sim.new();s.cars={};s.player.x,s.player.y=pos[1],pos[2]
  for _=1,6 do assert(Sim.spawn(s,'traffic')) end
  for _,c in ipairs(s.cars) do assert(not Map.visible(pos[1],pos[2],c.x,c.y,24)) end
 end
end)
test('blocked and capped spawn attempts defer without consuming an id',function()
 local s=Sim.new();s.cars={};s.player.x,s.player.y=66,66
 for i,n in ipairs(Map.nodes) do
  local d=(n.x-s.player.x)^2+(n.y-s.player.y)^2
  if i<=20 and d>190^2 and d<490^2 and not Map.visible(s.player.x,s.player.y,n.x,n.y,24) then
   s.cars[#s.cars+1]={x=n.x,y=n.y}
  end
 end
 assert(#s.cars<11);local id,seed=s.nextId,s.seed
 assert(not Sim.spawn(s,'police'));eq(s.nextId,id);eq(s.seed,seed)
 s.cars={};for _=1,11 do s.cars[#s.cars+1]={x=-999,y=-999} end
 assert(not Sim.spawn(s,'traffic'));eq(#s.cars,11);eq(s.nextId,id)
end)
test('prototype delivery turns surplus nearby police away without teleporting',function()
 local s=Sim.new(17);s.time=85;s.player.x,s.player.y=384,295;s.cars={}
 s.jobs={{location=1,kind='prototype'}};assert(Sim.pickup(s,1))
 for i,x in ipairs({304,328,440,464}) do
  s.cars[i]={id=i,x=x,y=264,node=x<384 and 7 or 8,target=21,
   angle=x<384 and 0 or math.pi,stun=0,speed=70,kind='police'}
 end
 Sim.update(s,1/60,{});assert(s.heat>3)
 local positions={};for i,c in ipairs(s.cars) do positions[i]={c.x,c.y} end
 Sim.deliver(s)
 local active,returning=0,0
 for i,c in ipairs(s.cars) do
  near(c.x,positions[i][1]);near(c.y,positions[i][2])
  if c.withdrawing then returning=returning+1;assert(c.exit) else active=active+1 end
 end
 eq(active,2);eq(returning,2)
 for step=1,1800 do
  Sim.update(s,1/60,{});s.events={}
  for _,c in ipairs(s.cars) do
   assert(not Map.blocked(c.x,c.y,8))
   if step<=60 and c.withdrawing then
    local before=positions[c.id]
    assert((c.x-s.player.x)^2+(c.y-s.player.y)^2 >= (before[1]-384)^2+(before[2]-295)^2,
     'returning patrol initially closed on the courier')
   end
  end
 end
 active,returning=0,0
 for _,c in ipairs(s.cars) do if c.withdrawing then returning=returning+1 else active=active+1 end end
 eq(active,2);eq(returning,0);eq(s.player.hp,100)
end)
test('carry one package and disallow duplicate pickup',function() local s=cargo('medical');assert(not Sim.pickup(s,1));eq(s.cargo.kind,'medical');eq(#s.jobs,0) end)
test('automatic pickup without interact',function() local s=Sim.new();s.cars={};s.player.x,s.player.y=96,264;Sim.update(s,1/60,{});eq(s.cargo.kind,'medical') end)
test('automatic delivery earns score and clean bonus',function() local s=cargo('medical');s.cars={};local dest=Map.locations[s.cargo.destination];s.player.x,s.player.y=dest.x,dest.y;Sim.update(s,1/60,{});eq(s.cargo,nil);eq(s.delivered,1);eq(s.cash,275);eq(s.score,275) end)
test('prototype temporary heat removed at delivery',function() local s=cargo('prototype');s.time=85;Sim.update(s,1/60,{});assert(s.heat>3);Sim.deliver(s);near(s.heat,s.time/85);assert(s.heat<1.01) end)
test('medical counts separated impacts and cooldown',function() local s=cargo('medical');Sim.impact(s,'a',9);eq(s.cargo.integrity,2);assert(not Sim.impact(s,'a',9));eq(s.cargo.integrity,2);s.impactCooldown=0;Sim.impact(s,'b',9);eq(s.cargo.integrity,1);s.impactCooldown=0;Sim.impact(s,'c',9);eq(s.cargo,nil);eq(s.failed,1) end)
test('battery expiry exact penalty and one failure',function() local s=cargo('battery');s.cargo.remaining=.01;s.cars={};Sim.update(s,1/60,{});eq(s.cargo,nil);eq(s.player.hp,74);eq(s.failed,1);Sim.update(s,1/60,{});eq(s.failed,1);eq(s.player.hp,74) end)
test('sustained traffic contact damages medical once and does not pin traffic',function()
 local s=cargo('medical');s.player.x,s.player.y=460,432;s.player.angle=0;s.player.vx=102
 s.cars={{id=1,x=480,y=432,angle=0,node=13,target=14,stun=0,speed=38,kind='traffic'}}
 for _=1,240 do Sim.update(s,1/60,{x=1}) end
 eq(s.cargo.integrity,2);eq(s.player.hp,93);eq(s.failed,0);assert(s.cars[1].x>560)
 local c=s.cars[1];s.player.x,s.player.y=c.x-70,c.y;s.player.vx,s.player.vy=0,0
 Sim.update(s,1/60,{});assert(not s.contacts.car1)
 s.player.x,s.player.y=c.x-16,c.y;s.player.vx=60;s.player.angle=0
 Sim.update(s,1/60,{x=1});eq(s.cargo.integrity,1)
end)
test('survival bonus requires completion, ending early yields no score',function()
 local s=Sim.new();Sim.finish(s,'SHIFT ENDED');eq(s.score,0);eq(s.stats.survivalBonus,0)
 local t=Sim.new();t.time=299.995;Sim.update(t,1/60,{});eq(t.score,200)
end)
test('battery damage can wreck',function() local s=cargo('battery');s.player.hp=20;s.cargo.remaining=.01;Sim.update(s,1/60,{});assert(s.over);eq(s.endReason,'VEHICLE WRECKED') end)
test('pause freezes cargo, heat, movement and shift',function() local s=cargo('battery');s.paused=true;local x,t=s.player.x,s.cargo.remaining;Sim.update(s,1/60,{x=1,boost=true});eq(s.time,0);eq(s.player.x,x);eq(s.cargo.remaining,t) end)
test('upgrade pauses and offers only valid unique choices',function() local s=Sim.new();s.upgrades.turbo=3;Sim.offer(s);eq(#s.offers,3);local seen={};for _,o in ipairs(s.offers) do assert(o.id~='turbo' and not seen[o.id]);seen[o.id]=true end;Sim.update(s,1/60,{x=1});eq(s.time,0) end)
for _,id in ipairs({'turbo','grip','chassis','ram','emp','cargo'}) do
 test('upgrade '..id..' changes effective mechanics and respects cap',function()
  local a=Sim.new(123);Sim.offer(a);a.offers={{id=id,name=id,max=3}};a.awaitingUpgrade=true;assert(Sim.applyUpgrade(a,id));eq(a.upgrades[id],1)
  if id=='chassis' then eq(a.player.maxHp,125)
  elseif id=='cargo' then a.jobs={{location=1,kind='battery'}};Sim.pickup(a,1);eq(a.cargo.remaining,46)
  elseif id=='emp' then Sim.emp(a);eq(a.player.empCooldown,10)
  elseif id=='ram' then Sim.impact(a,'test',10);eq(a.player.hp,92)
  elseif id=='turbo' then local b=Sim.new(123);a.cars={};b.cars={};for _=1,50 do Sim.update(a,1/60,{x=1,boost=true});Sim.update(b,1/60,{x=1,boost=true}) end;assert(a.player.x>b.player.x)
  elseif id=='grip' then local b=Sim.new(123);a.cars={};b.cars={};Sim.update(a,1/60,{x=1});Sim.update(b,1/60,{x=1});assert(a.player.angle>b.player.angle) end
  a.upgrades[id]=3;a.awaitingUpgrade=true;assert(not Sim.applyUpgrade(a,id))
 end)
end
test('three deliveries open upgrade',function() local s=Sim.new();for _=1,3 do s.pickupCooldown=0;s.cargo=nil;s.jobs={{location=1,kind='prototype'}};Sim.pickup(s,1);Sim.deliver(s) end;eq(s.delivered,3);assert(s.awaitingUpgrade);eq(s.upgradeProgress,0) end)
test('all-capped upgrades cannot create invalid offers',function() local s=Sim.new();for _,id in ipairs({'turbo','grip','chassis','ram','emp','cargo'}) do s.upgrades[id]=3 end;Sim.offer(s);eq(#s.offers,0);assert(not s.awaitingUpgrade) end)
test('EMP radius and cooldown',function() local s=Sim.new();s.cars={{x=490,y=432,stun=0},{x=800,y=432,stun=0}};assert(Sim.emp(s));eq(s.cars[1].stun,3);eq(s.cars[2].stun,0);assert(not Sim.emp(s));eq(s.stats.empHits,1) end)
test('exhausted boost does not chatter until release; recharge and fresh press work',function()
 local s=Sim.new();s.cars={};s.player.hp=99999;local edges,last=0,false
 for _=1,600 do Sim.update(s,1/60,{x=1,boost=true});if s.player.boostActive and not last then edges=edges+1 end;last=s.player.boostActive end
 eq(edges,1);assert(s.player.boostLocked);assert(s.player.boost>90)
 Sim.update(s,1/60,{x=1,boost=false});assert(not s.player.boostLocked)
 Sim.update(s,1/60,{x=1,boost=true});assert(s.player.boostActive)
end)
test('shift completes at 300 seconds once',function() local s=Sim.new();s.time=299.995;Sim.update(s,1/60,{});eq(s.time,300);assert(s.over);local score=s.score;Sim.finish(s);eq(s.score,score) end)
test('restart resets every run modifier',function() local s=cargo('prototype');s.upgrades.turbo=2;s.time=200;s.score=123;s=Sim.new();eq(s.time,0);eq(s.score,0);eq(s.player.hp,100);eq(s.cargo,nil);eq(next(s.upgrades),nil);eq(s.player.empCooldown,0) end)
test('no score for circles, boost, EMP or time',function() local s=Sim.new();s.cars={};for _=1,120 do Sim.update(s,1/60,{x=1,boost=true,emp=true}) end;eq(s.score,0) end)
test('catch-up timestep is bounded',function() local s=Sim.new();Sim.update(s,99,{});near(s.time,1/30) end)
test('road paths avoid buildings including shortcuts',function() for a=1,#Map.nodes do for b=1,#Map.nodes do local path=Map.path(a,b);eq(path[1],a);eq(path[#path],b);for i=2,#path do local A,B=Map.nodes[path[i-1]],Map.nodes[path[i]];for j=0,20 do local t=j/20;assert(not Map.blocked(A.x+(B.x-A.x)*t,A.y+(B.y-A.y)*t,8)) end end end end end)
test('AI remains on roads through 5-minute simulation',function() local s=Sim.new(200);s.player.hp=99999;s.player.maxHp=99999;for _=1,18000 do Sim.update(s,1/60,{});s.events={};for _,c in ipairs(s.cars) do assert(not Map.blocked(c.x,c.y,8));assert(#s.cars<=11) end end;assert(s.over);eq(s.time,300) end)
test('save roundtrip with settings and sorted scores',function() local d=Save.defaults();d.settings.music=.3;Save.record(d,{score=20,delivered=1});Save.record(d,{score=100,delivered=2});local v,ok=Save.decode(Save.encode(d));assert(ok);eq(v.settings.music,.3);eq(v.highscores[1].score,100) end)
test('corrupt and missing saves recover without executing data',function() for _,text in ipairs({'', 'return os.execute("bad")','NEON1\nmusic=nan\nsfx=4\nmute=evil\nscore=-20,4\nscore=100000000,2\n'}) do local s=Save.decode(text);eq(s.settings.music,.6);eq(s.settings.sfx,.7);eq(#s.highscores,0) end;local s=Save.decode(nil);eq(s.settings.music,.6) end)
test('high scores stay bounded to 10',function() local d=Save.defaults();for i=1,100 do Save.record(d,{score=i,delivered=i}) end;eq(#d.highscores,10);eq(d.highscores[1].score,100) end)
test('pixel size maps to exact integer window multiples with clamping',function()
 local w,h=Window.size(1);eq(w,640);eq(h,480)
 w,h=Window.size(3);eq(w,1920);eq(h,1440)
 w,h=Window.size(99);eq(w,2560);eq(h,1920)
 w,h=Window.size('bad');eq(w,640)
 eq(Window.step(1,-1),1);eq(Window.step(1,1),2);eq(Window.step(4,1),4);eq(Window.step(2,1),3)
 assert(type(Window.apply)=='function')
end)
test('window apply reports the real LÖVE result and survives failures',function()
 local saved=love
 love={window={updateMode=function() return false end}};eq(Window.apply({pixelSize=2}),false)
 love={window={updateMode=function() return true end}};eq(Window.apply({pixelSize=2}),true)
 love={window={updateMode=function() error('mock display failure') end}};eq(Window.apply({pixelSize=2}),false)
 love={};eq(Window.apply({pixelSize=2}),false)
 love=nil;eq(Window.apply({pixelSize=2}),false)
 love=saved
end)
test('window apply verifies the two-return settled size against clamping',function()
 local saved=love
 -- exact success with the real API return shape
 love={window={updateMode=function() return true end,getFullscreen=function() return false end},
       graphics={getDimensions=function() return 1280,960 end}}
 eq(Window.apply({pixelSize=2}),true)
 -- clamped success: updateMode succeeds but the window manager shrinks the window
 love={window={updateMode=function() return true end,getFullscreen=function() return false end},
       graphics={getDimensions=function() return 1280,921 end}}
 eq(Window.apply({pixelSize=2}),false)
 -- clamped and width-limited as observed on the current display
 love={window={updateMode=function() return true end,getFullscreen=function() return false end},
       graphics={getDimensions=function() return 1512,921 end}}
 eq(Window.apply({pixelSize=3}),false)
 -- desktop fullscreen reports the desktop size; API success is trusted
 love={window={updateMode=function() return true end,getFullscreen=function() return true end},
       graphics={getDimensions=function() return 1512,921 end}}
 eq(Window.apply({pixelSize=2}),true)
 love=saved
end)
test('pixel size setting persists and rejects corrupt values',function()
 local d=Save.defaults();d.settings.pixelSize=3
 local v,ok=Save.decode(Save.encode(d));assert(ok);eq(v.settings.pixelSize,3)
 eq(Save.decode('NEON1\npixelSize=9\n').settings.pixelSize,1)
 eq(Save.decode('NEON1\npixelSize=abc\n').settings.pixelSize,1)
 eq(Save.decode('NEON1\n').settings.pixelSize,1)
end)
print('ALL '..count..' LOGIC TESTS PASSED')
