-- Normal-hull deterministic navigation audit. No invulnerability, teleporting,
-- cargo overrides, or human-enjoyment claims. Prints balance observations.
-- District07 keeps its existing five seeds x two styles and every target, route
-- and collision query goes through that shift's own map.
package.path='./?.lua;./?/init.lua;'..package.path
local Sim=require('game.sim')
local Map=require('game.map')
local function length(x,y) return math.sqrt(x*x+y*y) end
local preference={chassis=6,ram=5,grip=4,cargo=3,emp=2,turbo=1}
local outcomes={}
local districts={['district07']=Map.get('district07'),waterfront=Map.get('waterfront')}
for _,district in ipairs({'district07','waterfront'}) do
 for _,seed in ipairs({72891,17,119,9001,20260929}) do
  for _,style in ipairs({'cautious','straight_boost'}) do
   local s=Sim.new(seed,districts[district])
   local m=s.map
   assert(m.id==district,'the audit must run on the requested district')
   local route,routeIndex,routeCargo,routeTarget
   local steps,stalled,maxCars,minHull=0,0,0,100
   while not s.over and steps<18002 do
    if s.awaitingUpgrade then
     local best=s.offers[1]
     for _,o in ipairs(s.offers) do if preference[o.id]>preference[best.id] then best=o end end
     assert(Sim.applyUpgrade(s,best.id),'offered upgrade failed')
    end
    local target
    if s.cargo then target=m.locations[s.cargo.destination]
    else local i=Sim.nearestJob(s);target=i and m.locations[s.jobs[i].location] end
    local input={}
    if target then
     if not route or s.cargo~=routeCargo or target~=routeTarget then
      route=m.route(s.player.x,s.player.y,target.x,target.y)
      routeIndex=2;routeCargo=s.cargo;routeTarget=target
     end
     local n=route[routeIndex] or target
     while length(n.x-s.player.x,n.y-s.player.y)<18 and routeIndex<#route do
      routeIndex=routeIndex+1;n=route[routeIndex]
     end
     local dx,dy=n.x-s.player.x,n.y-s.player.y
     local distance=length(dx,dy)
     if distance>1 then input.x,input.y=dx/distance,dy/distance end
     local alignment=distance>1 and (dx*math.cos(s.player.angle)+dy*math.sin(s.player.angle))/distance or 0
     input.boost=style=='straight_boost' and distance>70 and alignment>.97
     for _,c in ipairs(s.cars) do
      if c.kind=='police' and length(c.x-s.player.x,c.y-s.player.y)<100 and c.stun<.2 then input.emp=true end
     end
    end
    local x,y=s.player.x,s.player.y
    Sim.update(s,1/60,input);s.events={};steps=steps+1
    if length(s.player.x-x,s.player.y-y)<.05 and target then stalled=stalled+1 end
    minHull=math.min(minHull,s.player.hp);maxCars=math.max(maxCars,#s.cars)
    assert(not m.blocked(s.player.x,s.player.y,7.99),'player trapped inside collision geometry on '..district)
    for _,c in ipairs(s.cars) do assert(not m.blocked(c.x,c.y,8),'AI left road graph on '..district) end
    assert(#s.cars<=11,'unbounded vehicle count')
   end
   assert(s.over,'normal-hull navigation exceeded shift boundary on '..district)
   local result=string.format('district=%s seed=%d style=%s end=%s time=%.2f delivered=%d failed=%d score=%d hull=%d max_cars=%d stalled_seconds=%.2f',
    district,seed,style,s.endReason,s.time,s.delivered,s.failed,s.score,s.player.hp,maxCars,stalled/60)
   outcomes[#outcomes+1]=result;print(result)
  end
 end
end
print('PASS '..#outcomes..' deterministic normal-hull navigation audits (2 districts x 5 seeds x 2 styles); outcomes are balance evidence, not human playtests')
