-- Deterministic built-map validation. No randomness, no LÖVE. A built map is
-- accepted only when every authored field and the constructed graph/geometry
-- hold; Validate.check is the contract the district tests inject into.
local Validate={}

local function reason(map,detail)
 return string.format('district "%s" check: %s',tostring(map and map.id),detail)
end

local function finite(v) return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge end
local function isInt(v) return finite(v) and math.floor(v)==v end

function Validate.check(map)
 if type(map)~='table' then return false,'built map is not a table' end
 local id=map.id
 if type(id)~='string' or #id==0 then return false,reason(map,'missing id') end
 if not (finite(map.w) and finite(map.h) and map.w>0 and map.h>0) then return false,reason(map,'world size is not positive') end
 if not (finite(map.halfwidth) and map.halfwidth>0) then return false,reason(map,'half width is not positive') end
 for _,name in ipairs({'xs','ys'}) do
  if type(map[name])~='table' or #map[name]<2 then return false,reason(map,name..' needs at least two road centers') end
  for i,v in ipairs(map[name]) do
   if not finite(v) then return false,reason(map,name..'['..i..'] is not finite') end
   if i>1 and v<=map[name][i-1] then return false,reason(map,name..' are not strictly increasing') end
  end
 end
 if type(map.locations)~='table' or #map.locations~=8 then return false,reason(map,'needs exactly eight destinations') end
 local seen={}
 for i,loc in ipairs(map.locations) do
  if type(loc)~='table' then return false,reason(map,'destination '..i..' is not a table') end
  if type(loc.id)~='string' or #loc.id==0 then return false,reason(map,'destination '..i..' needs an id') end
  if seen[loc.id] then return false,reason(map,'duplicate destination id "'..loc.id..'"') end
  seen[loc.id]=true
  if not (finite(loc.x) and finite(loc.y)) then return false,reason(map,'destination "'..loc.id..'" coordinates are not finite') end
  if not (type(loc.color)=='table' and finite(loc.color[1]) and finite(loc.color[2]) and finite(loc.color[3])) then
   return false,reason(map,'destination "'..loc.id..'" needs an RGB color') end
 end
 if type(map.buildings)~='table' or #map.buildings==0 then return false,reason(map,'needs buildings') end
 for i,b in ipairs(map.buildings) do
  if not (finite(b.x) and finite(b.y) and finite(b.w) and finite(b.h) and b.w>0 and b.h>0) then
   return false,reason(map,'building '..i..' is not a positive finite rectangle') end
 end
 if type(map.nodes)~='table' or #map.nodes<#map.xs*#map.ys then return false,reason(map,'graph is missing nodes') end
 local count=#map.nodes
 for i,n in ipairs(map.nodes) do
  if not (finite(n.x) and finite(n.y)) then return false,reason(map,'node '..i..' is not finite') end
  if type(n.links)~='table' or #n.links==0 then return false,reason(map,'node '..i..' has no links') end
  for _,l in ipairs(n.links) do
   if not isInt(l) or l<1 or l>count or l==i then
    return false,reason(map,'node '..i..' links to invalid id '..tostring(l)) end
   local back=false
   for _,o in ipairs(map.nodes[l].links) do if o==i then back=true;break end end
   if not back then return false,reason(map,'link '..i..' -> '..l..' is not reciprocal') end
  end
 end
 -- shortcut descriptors keep the approved authored shape as built data
 local road=#map.xs*#map.ys
 if type(map.shortcuts)~='table' then return false,reason(map,'needs shortcut descriptors') end
 for i,sc in ipairs(map.shortcuts) do
  if type(sc)~='table' then return false,reason(map,'shortcut '..i..' is not a table') end
  for _,k in ipairs({'x','y','h','width'}) do
   if not finite(sc[k]) then return false,reason(map,'shortcut '..i..' needs a finite '..k) end
  end
  if not (finite(sc.col) and finite(sc.row)) then return false,reason(map,'shortcut '..i..' needs integer col/row') end
  if not (isInt(sc.nodeIds and sc.nodeIds[1]) and isInt(sc.nodeIds and sc.nodeIds[2])) then
   return false,reason(map,'shortcut '..i..' nodeIds must be two integers') end
  for _,nid in ipairs(sc.nodeIds or {}) do
   if nid<1 or nid>count then return false,reason(map,'shortcut '..i..' nodeId '..tostring(nid)..' is out of range') end
  end
  if type(sc.attachments)~='table' or #sc.attachments~=2 then
   return false,reason(map,'shortcut '..i..' needs attachments for both endpoints') end
  for _,ends in ipairs(sc.attachments) do
   for _,rid in ipairs(ends) do
    if not isInt(rid) or rid<1 or rid>road then return false,reason(map,'shortcut '..i..' attachment '..tostring(rid)..' is not a road id') end
   end
  end
  if type(sc.label)~='table' or type(sc.label[1])~='string' then return false,reason(map,'shortcut '..i..' needs a label') end
 end
 -- connectivity from node 1 over the undirected graph
 local seenIds,stack={[1]=true},{1}
 while #stack>0 do
  local u=table.remove(stack)
  for _,v in ipairs(map.nodes[u].links) do
   if not seenIds[v] then seenIds[v]=true;stack[#stack+1]=v end
  end
 end
 for i=1,count do if not seenIds[i] then return false,reason(map,'graph is disconnected at node '..i) end end
 -- spawn ids are ordinary road nodes
 if type(map.spawnNodeIds)~='table' or #map.spawnNodeIds==0 then return false,reason(map,'needs spawn node ids') end
 for _,sid in ipairs(map.spawnNodeIds) do
  if not isInt(sid) or sid<1 or sid>road then return false,reason(map,'spawn id '..tostring(sid)..' is not an ordinary road node') end
 end
 -- exact continuous geometry: segment/point distances against rectangles
 local function pointRectDist(px,py,b)
  local dx=math.max(b.x-px,0,px-(b.x+b.w))
  local dy=math.max(b.y-py,0,py-(b.y+b.h))
  return math.sqrt(dx*dx+dy*dy)
 end
 local function pointSegDist(px,py,ax,ay,bx,by)
  local vx,vy=bx-ax,by-ay
  local wx,wy=px-ax,py-ay
  local len=vx*vx+vy*vy
  if len<=0 then return math.sqrt(wx*wx+wy*wy) end
  local t=math.max(0,math.min(1,(wx*vx+wy*vy)/len))
  local cx,cy=ax+vx*t,ay+vy*t
  return math.sqrt((px-cx)^2+(py-cy)^2)
 end
 local function segIntersects(ax,ay,bx,by,cx,cy,dx,dy)
  local function orient(ux,uy,vx,vy,wx,wy)
   local v=(vx-ux)*(wy-uy)-(vy-uy)*(wx-ux)
   if v>0 then return 1 elseif v<0 then return -1 end
   return 0
  end
  local d1,d2,d3,d4=orient(cx,cy,dx,dy,ax,ay),orient(cx,cy,dx,dy,bx,by),
                   orient(ax,ay,bx,by,cx,cy),orient(ax,ay,bx,by,dx,dy)
  if d1~=d2 and d3~=d4 then return true end
  local function onSeg(sx,sy,ex,ey,px,py)
   return math.min(sx,ex)-1e-12<=px and px<=math.max(sx,ex)+1e-12
    and math.min(sy,ey)-1e-12<=py and py<=math.max(sy,ey)+1e-12
  end
  if d1==0 and onSeg(cx,cy,dx,dy,ax,ay) then return true end
  if d2==0 and onSeg(cx,cy,dx,dy,bx,by) then return true end
  if d3==0 and onSeg(ax,ay,bx,by,cx,cy) then return true end
  if d4==0 and onSeg(ax,ay,bx,by,dx,dy) then return true end
  return false
 end
 -- minimum distance between a segment and an axis-aligned rectangle
 local function segmentRectDist(ax,ay,bx,by,b)
  if ax>=b.x and ax<=b.x+b.w and ay>=b.y and ay<=b.y+b.h then return 0 end
  if bx>=b.x and bx<=b.x+b.w and by>=b.y and by<=b.y+b.h then return 0 end
  local edges={
   {b.x,b.y,b.x+b.w,b.y},{b.x+b.w,b.y,b.x+b.w,b.y+b.h},
   {b.x+b.w,b.y+b.h,b.x,b.y+b.h},{b.x,b.y+b.h,b.x,b.y},
  }
  local d=math.huge
  for _,e in ipairs(edges) do
   if segIntersects(ax,ay,bx,by,e[1],e[2],e[3],e[4]) then return 0 end
   local dd=math.min(
    pointSegDist(ax,ay,e[1],e[2],e[3],e[4]),pointSegDist(bx,by,e[1],e[2],e[3],e[4]),
    pointSegDist(e[1],e[2],ax,ay,bx,by),pointSegDist(e[3],e[4],ax,ay,bx,by))
   if dd<d then d=dd end
  end
  d=math.min(d,pointRectDist(ax,ay,b),pointRectDist(bx,by,b))
  return d
 end
 local function inDrivable(x,y)
  return x-8>=58 and y-8>=58 and x+8<=map.w-58 and y+8<=map.h-84
 end
 for i,n in ipairs(map.nodes) do
  for _,l in ipairs(n.links) do
   if l>i then
    local m=map.nodes[l]
    if not (inDrivable(n.x,n.y) and inDrivable(m.x,m.y)) then
     return false,reason(map,'segment '..i..'-'..l..' leaves the drivable bounds') end
    for _,b in ipairs(map.buildings) do
     if segmentRectDist(n.x,n.y,m.x,m.y,b)<8 then
      return false,reason(map,'segment '..i..'-'..l..' is not clear at 8px of building '..b.x..','..b.y) end
    end
   end
  end
 end
 if not inDrivable(map.start.x,map.start.y) then return false,reason(map,'start position is out of bounds') end
 for _,b in ipairs(map.buildings) do
  if pointRectDist(map.start.x,map.start.y,b)<8 then return false,reason(map,'start position is blocked') end
 end
 for _,loc in ipairs(map.locations) do
  if not inDrivable(loc.x,loc.y) then return false,reason(map,'destination "'..loc.id..'" is out of bounds') end
  for _,b in ipairs(map.buildings) do
   if pointRectDist(loc.x,loc.y,b)<8 then return false,reason(map,'destination "'..loc.id..'" is blocked') end
  end
 end
 -- every origin can deliver somewhere beyond 260px
 for _,origin in ipairs(map.locations) do
  local candidates=0
  for _,loc in ipairs(map.locations) do
   if (loc.x-origin.x)^2+(loc.y-origin.y)^2>260^2 then candidates=candidates+1 end
  end
  if candidates==0 then return false,reason(map,'origin "'..origin.id..'" has no delivery candidate beyond 260px') end
 end
 return true
end

return Validate
