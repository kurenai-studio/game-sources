-- Test-only District 07 recorder. Captures the exact old ordered geometry,
-- helper samples and complete deterministic replay state of the still-
-- unmodified game/map.lua + game/sim.lua. No production module is edited here.
package.path='./?.lua;./?/init.lua;'..package.path
local Snapshot={}

function Snapshot.map(map)
 local out={}
 out.id='legacy-singleton'
 out.w,out.h,out.halfwidth=map.w,map.h,map.halfwidth
 out.xs={};for _,x in ipairs(map.xs) do out.xs[#out.xs+1]=x end
 out.ys={};for _,y in ipairs(map.ys) do out.ys[#out.ys+1]=y end
 out.locations={}
 for i,loc in ipairs(map.locations) do
  out.locations[i]={id=loc.id,name=loc.name,x=loc.x,y=loc.y,
   color={loc.color[1],loc.color[2],loc.color[3]},kind=loc.kind}
 end
 out.buildings={}
 for i,b in ipairs(map.buildings) do out.buildings[i]={x=b.x,y=b.y,w=b.w,h=b.h,style=b.style} end
 out.nodes={}
 for i,n in ipairs(map.nodes) do out.nodes[i]={x=n.x,y=n.y,links={}};for j,l in ipairs(n.links) do out.nodes[i].links[j]=l end end
 out.nearestSamples={}
 for _,p in ipairs({{96,96},{0,0},{959,719},{480,432},{384,264},{768,432},{850,600},{100,700}}) do
  out.nearestSamples[#out.nearestSamples+1]={p[1],p[2],map.nearest(p[1],p[2])}
 end
 out.cameraSamples={}
 for _,p in ipairs({{480,432},{0,0},{959,719},{50,50},{900,50},{50,650},{900,650},{300,300}}) do
  local cx,cy=map.camera(p[1],p[2]);out.cameraSamples[#out.cameraSamples+1]={p[1],p[2],cx,cy}
 end
 out.blockedSamples={}
 for _,p in ipairs({{60,60},{60,200},{900,200},{480,360},{480,362},{58,360},{902,360},{640,360},{640,362},{0,0},{959,719},{480,648}}) do
  out.blockedSamples[#out.blockedSamples+1]={p[1],p[2],map.blocked(p[1],p[2],8)}
 end
 out.pathSamples={}
 for _,pr in ipairs({{1,24},{13,12},{6,20},{3,16},{21,22},{5,1},{24,1},{9,15}}) do
  local path=map.path(pr[1],pr[2])
  local ids={};for _,i in ipairs(path) do ids[#ids+1]=i end
  out.pathSamples[#out.pathSamples+1]={from=pr[1],to=pr[2],path=ids}
 end
 out.routeSamples={}
 for _,pr in ipairs({{96,264,672,264},{480,432,864,600},{96,600,864,96}}) do
  local r=map.route(pr[1],pr[2],pr[3],pr[4])
  local pts={};for _,p in ipairs(r) do pts[#pts+1]={x=p.x,y=p.y} end
  out.routeSamples[#out.routeSamples+1]={x=pr[1],y=pr[2],tx=pr[3],ty=pr[4],route=pts}
 end
 out.visibleSamples={}
 for _,c in ipairs({{480,432,96,96},{480,432,864,600},{480,432,49,360},{480,432,850,600},{480,432,58,360},{0,0,700,700},{959,719,300,300}}) do
  for _,pad in ipairs({0,24}) do
   out.visibleSamples[#out.visibleSamples+1]={c[1],c[2],c[3],c[4],pad,map.visible(c[1],c[2],c[3],c[4],pad)}
  end
 end
 return out
end

-- Complete recursive copy of plain simulation data. Only the later map
-- metadata (s.map/s.districtId) is excluded; every existing deterministic
-- field, keyed table and nil-vs-false shape is preserved as it exists.
local function deepcopy(v,seen)
 if type(v)~='table' then return v end
 seen=seen or {}
 if seen[v] then return '<cycle>' end
 seen[v]=true
 local out={}
 for k,val in pairs(v) do
  if type(k)=='string' or type(k)=='number' then out[k]=deepcopy(val,seen) end
 end
 return out
end

function Snapshot.sim(s)
 local out=deepcopy(s)
 out.map=nil
 out.districtId=nil
 return out
end

function Snapshot.replay(seed,map)
 local Sim=require('game.sim')
 local s=Sim.new(seed,map)
 local marks={0,60,300,1800}
 local out={}
 local mi=1
 if mi<=#marks then out[#out+1]={frame=0,state=Snapshot.sim(s)};mi=mi+1 end
 for frame=1,1800 do
  local input={x=1,y=0,boost=frame<=120,emp=frame==300}
  Sim.update(s,1/60,input)
  if mi<=#marks and marks[mi]==frame then out[#out+1]={frame=frame,state=Snapshot.sim(s)};mi=mi+1 end
 end
 return out
end

return Snapshot
