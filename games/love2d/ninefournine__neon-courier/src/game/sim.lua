local Map=require('game.map')
local Data=require('game.data')
local S={}
local function clamp(v,a,b) return math.max(a,math.min(v,b)) end
local function length(x,y) return math.sqrt(x*x+y*y) end
local function angle(x,y) return math.atan2(y,x) end
local function turn(a,b,amount) local d=(b-a+math.pi)%(2*math.pi)-math.pi;return a+clamp(d,-amount,amount) end
function S.random(s,n)
 s.seed=(s.seed*16807)%2147483647
 local v=s.seed/2147483647
 if n then return math.floor(v*n)+1 end;return v
end
local function event(s,name,x,y) s.events[#s.events+1]={name=name,x=x or s.player.x,y=y or s.player.y} end
function S.notice(s,text) s.notice=text;s.noticeTime=3 end
function S.new(seed,map)
 local built=map or Map
 local start=built.start
 local s={seed=seed or 72891,initialSeed=seed or 72891,time=0,duration=300,
 player={x=start.x,y=start.y,vx=0,vy=0,angle=start.angle,hp=100,maxHp=100,boost=100,empCooldown=0},
 score=0,cash=0,delivered=0,failed=0,heat=0,cars={},jobs={},upgrades={},
 upgradeProgress=0,upgradeTarget=3,offers={},events={},contacts={},impactCooldown=0,
 pickupCooldown=0,onboarding='FOLLOW THE BEACON. DRIVE INTO A JOB CIRCLE.',notice='',noticeTime=0,
 stats={bonus=0,damage=0,empHits=0,boostSeconds=0},shake=0,spawnClock=0,trafficClock=0,nextId=1,
 map=built,districtId=built.id}
 for _,job in ipairs(built.initialJobs) do
  s.jobs[#s.jobs+1]={location=built.locationIndex[job.locationId],kind=job.kind}
 end
 for i=1,6 do S.spawn(s,'traffic',true) end
 return s
end
function S.spawn(s,kind,initial)
 if #s.cars>=11 then return false end
 local p=s.player;local valid={}
 local map=s.map
 for _,i in ipairs(map.spawnNodeIds) do
  local n=map.nodes[i]
  local d=length(n.x-p.x,n.y-p.y)
  local clear=true
  for _,c in ipairs(s.cars) do if length(n.x-c.x,n.y-c.y)<48 then clear=false;break end end
  if d>190 and (kind~='police' or d<490) and clear
     and not map.visible(p.x,p.y,n.x,n.y,24) then valid[#valid+1]=i end
 end
 if #valid==0 then return false end
 local idx=valid[S.random(s,#valid)];local node=map.nodes[idx]
 local nextNode=node.links[S.random(s,#node.links)];local target=map.nodes[nextNode]
 local car={id=s.nextId,x=node.x,y=node.y,angle=angle(target.x-node.x,target.y-node.y),
 kind=kind,node=idx,target=nextNode,stun=0,speed=kind=='police' and 70 or 38+S.random(s)*16}
 s.nextId=s.nextId+1;s.cars[#s.cars+1]=car
 return true
end
function S.nearestJob(s)
 local best,d=nil,math.huge
 for i,j in ipairs(s.jobs) do local loc=s.map.locations[j.location];local dd=length(loc.x-s.player.x,loc.y-s.player.y)
 if dd<d then best,d=i,dd end end
 return best,d
end
local function policeDemand(s)
 return s.time>24 and math.min(5,math.floor(s.heat)+1) or 0
end
local function withdrawSurplus(s)
 local patrols={}
 for _,c in ipairs(s.cars) do
  if c.kind=='police' and not c.withdrawing then patrols[#patrols+1]=c end
 end
 -- Keep the closest baseline pursuers; surplus cargo patrols visibly break off.
 table.sort(patrols,function(a,b)
  local ad=(a.x-s.player.x)^2+(a.y-s.player.y)^2
  local bd=(b.x-s.player.x)^2+(b.y-s.player.y)^2
  if ad==bd then return a.id<b.id end
  return ad<bd
 end)
 for i=policeDemand(s)+1,#patrols do
  local c=patrols[i];c.withdrawing=true
  local exit,best=1,-1
  for _,j in ipairs(s.map.spawnNodeIds) do
   local n=s.map.nodes[j]
   local d=(n.x-s.player.x)^2+(n.y-s.player.y)^2
   local away=(n.x-s.player.x)*(c.x-s.player.x)+(n.y-s.player.y)*(c.y-s.player.y)
   if away>=0 and d>best then exit,best=j,d end
  end
  c.exit=exit
  -- Turn around along the current road rather than finishing a leg towards
  -- the courier. Both endpoints are legal; never teleport a visible patrol.
  local a,b=s.map.nodes[c.node],s.map.nodes[c.target]
  local da=(a.x-s.player.x)^2+(a.y-s.player.y)^2
  local db=(b.x-s.player.x)^2+(b.y-s.player.y)^2
  if da>db then c.node,c.target=c.target,c.node end
 end
 return math.min(#patrols,policeDemand(s))
end
function S.pickup(s,index)
 if s.cargo or s.pickupCooldown>0 or s.over then return false end
 local j=s.jobs[index];if not j then return false end
 local destinations={}
 local origin=s.map.locations[j.location]
 for i,loc in ipairs(s.map.locations) do if length(loc.x-origin.x,loc.y-origin.y)>260 then destinations[#destinations+1]=i end end
 local protection=s.upgrades.cargo or 0
 s.cargo={kind=j.kind,destination=destinations[S.random(s,#destinations)],origin=j.location,
 integrity=3+protection,maxIntegrity=3+protection,remaining=38+8*protection,payout=Data.cargo[j.kind].payout,
 pickedAt=s.time,damageFree=true}
 table.remove(s.jobs,index)
 s.onboarding='DELIVER TO THE DIAMOND. SPACE BOOST / X EMP.'
 S.notice(s,Data.cargo[j.kind].name..' ON BOARD');event(s,'pickup')
 return true
end
local function replacementJob(s)
 s.onboarding='FOLLOW THE BEACON FOR YOUR NEXT JOB.'
 local used={};for _,j in ipairs(s.jobs) do used[j.location]=true end
 local options={};for i,loc in ipairs(s.map.locations) do if not used[i] and length(loc.x-s.player.x,loc.y-s.player.y)>150 then options[#options+1]=i end end
 if #options>0 then
  local kinds={'prototype','medical','battery'}
  s.jobs[#s.jobs+1]={location=options[S.random(s,#options)],kind=kinds[S.random(s,3)]}
 end
end
function S.offer(s)
 local pool={}
 for _,u in ipairs(Data.upgrades) do if (s.upgrades[u.id] or 0)<u.max then pool[#pool+1]=u end end
 s.offers={}
 while #s.offers<3 and #pool>0 do
  local i=S.random(s,#pool);local u=table.remove(pool,i);local o={}
  for k,v in pairs(u) do o[k]=v end;o.level=s.upgrades[u.id] or 0;s.offers[#s.offers+1]=o
 end
 s.awaitingUpgrade=#s.offers>0
end
function S.deliver(s)
 if not s.cargo or s.over then return false end
 local c=s.cargo
 local bonus=(c.kind=='medical' and c.integrity*25 or 0)+(c.damageFree and 40 or 0)
 local payout=c.payout+bonus
 s.cash=s.cash+payout;s.score=s.score+payout;s.stats.bonus=s.stats.bonus+bonus
 s.delivered=s.delivered+1;s.upgradeProgress=s.upgradeProgress+1
 s.cargo=nil;s.pickupCooldown=1.2
 s.heat=math.min(5,s.time/85)
 withdrawSurplus(s)
 S.notice(s,'DELIVERED +$'..payout..(bonus>0 and ' / BONUS +$'..bonus or ''))
 event(s,'delivery');replacementJob(s)
 if s.upgradeProgress>=s.upgradeTarget then s.upgradeProgress=0;S.offer(s) end
 return true
end
function S.applyUpgrade(s,id)
 local def
 for _,o in ipairs(s.offers) do if o.id==id then def=o end end
 if not s.awaitingUpgrade or not def or (s.upgrades[id] or 0)>=def.max then return false end
 s.upgrades[id]=(s.upgrades[id] or 0)+1
 if id=='chassis' then s.player.maxHp=s.player.maxHp+25;s.player.hp=math.min(s.player.maxHp,s.player.hp+35) end
 s.awaitingUpgrade=false;s.offers={};S.notice(s,def.name..' INSTALLED');event(s,'ui')
 return true
end
function S.finish(s,reason)
 if s.over then return end
 s.over=true;s.endReason=reason or 'SHIFT COMPLETE';s.cargo=nil
 s.stats.survivalBonus=s.endReason=='SHIFT COMPLETE' and math.floor(s.player.hp*2) or 0
 s.score=s.score+s.stats.survivalBonus;event(s,'ui')
end
function S.impact(s,source,severity)
 if s.over or s.impactCooldown>0 then return false end
 s.impactCooldown=.65;s.shake=.8
 local damage=math.max(2,math.floor((severity or 10)*(1-.2*(s.upgrades.ram or 0))))
 s.player.hp=math.max(0,s.player.hp-damage);s.stats.damage=s.stats.damage+damage
 if s.cargo then
  s.cargo.damageFree=false
  if s.cargo.kind=='medical' then
   s.cargo.integrity=s.cargo.integrity-1
   if s.cargo.integrity<=0 then s.cargo=nil;s.failed=s.failed+1;s.pickupCooldown=1.2;replacementJob(s);S.notice(s,'MEDICAL CARGO LOST / INTEGRITY ZERO')
   else S.notice(s,'MEDICAL INTEGRITY '..s.cargo.integrity..' / '..s.cargo.maxIntegrity) end
  end
 end
 event(s,'impact')
 if s.player.hp<=0 then S.finish(s,'VEHICLE WRECKED') end
 return true
end
function S.emp(s)
 if s.player.empCooldown>0 or s.over then return false end
 local level=s.upgrades.emp or 0
 local radius=105+25*level
 s.player.empCooldown=12-2*level;s.empPulse=.6
 for _,car in ipairs(s.cars) do if length(car.x-s.player.x,car.y-s.player.y)<radius then car.stun=3+level;s.stats.empHits=s.stats.empHits+1 end end
 event(s,'emp');return true
end
local function cars(s,dt,contacts)
 local p=s.player
 for _,c in ipairs(s.cars) do
  c.stun=math.max(0,c.stun-dt)
  if c.stun==0 then
   local n=s.map.nodes[c.target];local dx,dy=n.x-c.x,n.y-c.y;local d=length(dx,dy)
   if d<3 then
    c.x,c.y=n.x,n.y;c.node=c.target
    if c.kind=='police' then
     local path=s.map.path(c.node,c.withdrawing and c.exit or s.map.nearest(p.x,p.y))
     c.target=path[2] or (c.withdrawing and c.node or n.links[1])
    else
     local opts={};for _,i in ipairs(n.links) do if i~=c.previous then opts[#opts+1]=i end end
     c.target=opts[S.random(s,#opts)] or n.links[1]
    end
    c.previous=c.node
   else
    local speed=c.speed+(c.kind=='police' and not c.withdrawing and math.min(38,s.heat*6) or 0)
    local step=math.min(d,speed*dt)
    c.x,c.y=c.x+dx/d*step,c.y+dy/d*step;c.angle=angle(dx,dy)
   end
  end
  local dx,dy=p.x-c.x,p.y-c.y;local d=length(dx,dy)
  local key='car'..c.id
  -- Contact releases only after a real gap. Push-out at20 must not rearm a
  --19-radius collision each frame, or one tailgate drains medical integrity.
  if s.contacts[key] and d<28 then contacts[key]=true end
  if d<19 then
   contacts[key]=true
   if d<.01 then dx,dy,d=1,0,1 end
   local nx,ny=dx/d,dy/d
   local px,py=c.x+nx*20,c.y+ny*20
   if not s.map.blocked(px,py,8) then p.x,p.y=px,py end
   local speed=length(p.vx,p.vy)
   if not s.contacts[key] then
    if speed>30 or c.stun==0 then S.impact(s,key,c.kind=='police' and 11 or 7) end
    c.stun=math.max(c.stun,.5+(s.upgrades.ram or 0)*(c.kind=='police' and 1 or .3))
   end
   p.vx,p.vy=p.vx*.35+nx*25,p.vy*.35+ny*25
  end
 end
end
function S.update(s,dt,input)
 if s.over or s.paused or s.awaitingUpgrade then return end
 dt=math.min(dt,1/30);input=input or {}
 s.time=math.min(s.duration,s.time+dt);s.noticeTime=math.max(0,s.noticeTime-dt)
 s.impactCooldown=math.max(0,s.impactCooldown-dt);s.pickupCooldown=math.max(0,s.pickupCooldown-dt)
 s.shake=math.max(0,s.shake-dt*2);s.empPulse=math.max(0,(s.empPulse or 0)-dt)
 local p=s.player;p.empCooldown=math.max(0,p.empCooldown-dt)
 if input.emp then S.emp(s) end
 local ix,iy=input.x or 0,input.y or 0;local strength=math.min(1,length(ix,iy))
 local moving=strength>.05
 local grip=s.upgrades.grip or 0
 if moving then p.angle=turn(p.angle,angle(ix,iy),(6.8+grip*1.7)*dt) end
 if not input.boost then p.boostLocked=false end
 if input.boost and p.boost<=4 then p.boostLocked=true end
 p.boostActive=input.boost and moving and p.boost>4 and not p.boostLocked
 local maxspeed=(p.boostActive and 165*(1+.18*(s.upgrades.turbo or 0)) or 102)*strength
 if p.boostActive then p.boost=math.max(0,p.boost-dt*31);s.stats.boostSeconds=s.stats.boostSeconds+dt
 else p.boost=math.min(100,p.boost+dt*20) end
 local blend=1-math.exp(-(moving and 5.8+grip*1.16 or 7)*dt)
 p.vx=p.vx+(math.cos(p.angle)*maxspeed-p.vx)*blend;p.vy=p.vy+(math.sin(p.angle)*maxspeed-p.vy)*blend
 local speed=length(p.vx,p.vy);local contacts={}
 local nx=p.x+p.vx*dt;local ny=p.y+p.vy*dt
 local bx=s.map.blocked(nx,p.y,8)
 if bx then contacts['wall'..tostring(bx)]=true;p.vx=-p.vx*.22
 else p.x=nx end
 local by=s.map.blocked(p.x,ny,8)
 if by then contacts['wall'..tostring(by)]=true;p.vy=-p.vy*.22
 else p.y=ny end
 for key in pairs(contacts) do if not s.contacts[key] and speed>48 then S.impact(s,key,5+speed*.035) end end
 s.heat=math.min(5,s.time/85)+(s.cargo and s.cargo.kind=='prototype' and 2 or 0)
 cars(s,dt,contacts);s.contacts=contacts
 if s.cargo and s.cargo.kind=='battery' then
  s.cargo.remaining=s.cargo.remaining-dt
  if s.cargo.remaining<=0 then
   s.cargo=nil;s.failed=s.failed+1;p.hp=math.max(0,p.hp-26);s.stats.damage=s.stats.damage+26
   s.pickupCooldown=1.5;s.shake=1;replacementJob(s);S.notice(s,'BATTERY EXPLODED / -26 HULL');event(s,'explosion')
   if p.hp<=0 then S.finish(s,'VEHICLE WRECKED') end
  end
 end
 if not s.over then
  if s.cargo then local loc=s.map.locations[s.cargo.destination];if length(p.x-loc.x,p.y-loc.y)<23 then S.deliver(s) end
  elseif s.pickupCooldown==0 then
   local i,d=S.nearestJob(s);if i and d<22 then S.pickup(s,i) end
  end
 end
 local count=withdrawSurplus(s)
 -- Remove returning cars only after they leave the actual view. Camera edge
 -- clamping means distance from the player alone is insufficient.
 for i=#s.cars,1,-1 do
  local c=s.cars[i]
  if c.withdrawing and not s.map.visible(p.x,p.y,c.x,c.y,24) then table.remove(s.cars,i) end
 end
 local desired=policeDemand(s)
 s.spawnClock=s.spawnClock+dt
 if count<desired and s.spawnClock>6 and S.spawn(s,'police') then s.spawnClock=0 end
 if s.time>=s.duration and not s.over then S.finish(s,'SHIFT COMPLETE') end
 if s.time>18 then s.onboarding=nil end
end
return S
