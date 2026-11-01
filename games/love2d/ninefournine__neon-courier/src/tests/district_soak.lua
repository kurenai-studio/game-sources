-- Raised-hull 300-second stability fixture for each district. This is NOT a
-- balance or survival test: hull is raised only so the timer reaches its full
-- clamped boundary, and every offered upgrade is applied. The audit proves the
-- fixed five-minute clock, the 11-car cap and legal road geometry per district.
package.path='./?.lua;./?/init.lua;'..package.path
local Sim=require('game.sim')
local Map=require('game.map')

local function runSoak(district,map)
 local s=Sim.new(72891,map)
 -- raise hull only; movement, AI, cargo, timers and RNG stay untouched
 s.player.hp=1000;s.player.maxHp=1000
 local steps,applied,maxCars=0,0,0
 while not s.over and steps<18002 do
  if s.awaitingUpgrade then
   assert(s.offers and #s.offers>0,'an upgrade screen must offer choices')
   local up=s.offers[1]
   local before=s.upgrades[up.id] or 0
   assert(before<up.max,'an offered upgrade must still be eligible on '..district)
   assert(Sim.applyUpgrade(s,up.id),'offered upgrade failed on '..district)
   applied=applied+1
   assert(s.upgrades[up.id]==before+1,'applying an upgrade must increment exactly once on '..district)
   assert(s.upgrades[up.id]<=up.max,'an applied upgrade must stay within its cap on '..district)
  end
  local m=s.map
  local target
  if s.cargo then target=m.locations[s.cargo.destination]
  else local i=Sim.nearestJob(s);target=i and m.locations[s.jobs[i].location] end
  local input={}
  if target then
   local route=s.route
   if not route or s.cargo~=s.routeCargo or target~=s.routeTarget then
    route=m.route(s.player.x,s.player.y,target.x,target.y);s.routeIndex=2;s.routeCargo=s.cargo;s.routeTarget=target
   end
   s.route=route
   local n=s.route[s.routeIndex] or target
   while (n.x-s.player.x)^2+(n.y-s.player.y)^2<18^2 and s.routeIndex<#s.route do
    s.routeIndex=s.routeIndex+1;n=s.route[s.routeIndex]
   end
   local dx,dy=n.x-s.player.x,n.y-s.player.y
   local d=math.sqrt(dx*dx+dy*dy)
   if d>1 then input.x,input.y=dx/d,dy/d end
   input.emp=s.player.empCooldown<=0
  end
  Sim.update(s,1/60,input);s.events={};steps=steps+1
  maxCars=math.max(maxCars,#s.cars)
  assert(#s.cars<=11,'unbounded vehicle count on '..district)
  for _,c in ipairs(s.cars) do
   assert(not m.blocked(c.x,c.y,8),'AI left road graph on '..district)
   assert(c.x>=58 and c.y>=58 and c.x<=m.w-58 and c.y<=m.h-84,'AI left drivable bounds on '..district)
  end
  assert(not m.blocked(s.player.x,s.player.y,7.99),'player trapped inside collision geometry on '..district)
 end
 assert(steps<=18002,'stability loop exceeded its bounded tick count on '..district)
 assert(s.over,'the raised-hull fixture must still reach the shift boundary on '..district)
 assert(s.time==300,'the clamp must land exactly on 300 seconds on '..district..' (got '..tostring(s.time)..')')
 assert(s.endReason=='SHIFT COMPLETE','the raised-hull fixture completes the shift on '..district..' (got '..tostring(s.endReason)..')')
 print(string.format('SOAK district=%s steps=%d time=%.3f over=%s end=%s delivered=%d upgrades_applied=%d max_cars=%d hull=%d',
  district,steps,s.time,tostring(s.over),tostring(s.endReason),s.delivered,applied,maxCars,s.player.hp))
 return s
end

local soaks={}
for _,district in ipairs({'district07','waterfront'}) do
 soaks[#soaks+1]=runSoak(district,Map.get(district))
end
print('PASS 2 raised-hull 300-second stability audits; hull raised only, so this is stability evidence and never a balance or human-survival claim')
