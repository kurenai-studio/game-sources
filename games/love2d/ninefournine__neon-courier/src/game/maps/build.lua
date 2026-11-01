-- Deterministic district construction: one authored definition -> one built
-- map with bound helpers. Consumes no randomness and never shares mutable
-- tables with the authored source. Invalid input raises a descriptive
-- district/check error; authored fields are validated before construction and
-- the finished graph/geometry is validated before the map is returned.
local Validate=require('game/maps.validate')

local Build={}

local function deepcopy(v)
 if type(v)~='table' then return v end
 local out={}
 for k,val in pairs(v) do out[k]=deepcopy(val) end
 return out
end

local function fail(def,detail)
 error(string.format('district "%s" check: %s',tostring(def and def.id),detail),0)
end

local function finite(v) return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge end
local function isInt(v) return finite(v) and math.floor(v)==v end

-- Authored fields are validated before any arithmetic runs on them.
local function checkDefinition(def)
 if type(def)~='table' then fail(def,'definition is not a table') end
 if type(def.id)~='string' or #def.id==0 then fail(def,'missing id') end
 if type(def.label)~='string' or #def.label==0 then fail(def,'missing label') end
 if type(def.subtitle)~='string' then fail(def,'missing subtitle') end
 if not (finite(def.w) and finite(def.h) and def.w>0 and def.h>0) then fail(def,'world size is not a positive number') end
 if not (finite(def.halfwidth) and def.halfwidth>0) then fail(def,'half width is not a positive number') end
 for _,name in ipairs({'xs','ys'}) do
  local v=def[name]
  if type(v)~='table' or #v<2 then fail(def,name..' needs at least two road centers') end
  for i,n in ipairs(v) do
   if not finite(n) then fail(def,name..'['..i..'] is not a finite number') end
   if i>1 and n<=v[i-1] then fail(def,name..' are not strictly increasing') end
  end
 end
 if type(def.locations)~='table' or #def.locations~=8 then fail(def,'needs exactly eight destinations') end
 local seen={}
 for i,loc in ipairs(def.locations) do
  if type(loc)~='table' or type(loc.id)~='string' or #loc.id==0 then fail(def,'destination '..i..' needs an id') end
  if seen[loc.id] then fail(def,'duplicate destination id "'..loc.id..'"') end
  seen[loc.id]=true
  if not (finite(loc.x) and finite(loc.y)) then fail(def,'destination "'..loc.id..'" needs finite coordinates') end
  if not (type(loc.color)=='table' and finite(loc.color[1]) and finite(loc.color[2]) and finite(loc.color[3])) then
   fail(def,'destination "'..loc.id..'" needs an RGB color') end
  if loc.x-8<58 or loc.y-8<58 or loc.x+8>def.w-58 or loc.y+8>def.h-84 then
   fail(def,'destination "'..loc.id..'" sits outside the drivable area') end
 end
 local road=#def.xs*#def.ys
 local endpointIds={}
 if type(def.shortcuts)~='table' then fail(def,'shortcuts must be a table') end
 for i,sc in ipairs(def.shortcuts) do
  if type(sc)~='table' then fail(def,'shortcut '..i..' is not a table') end
  for _,k in ipairs({'x','y','h','width'}) do
   if not finite(sc[k]) then fail(def,'shortcut '..i..' needs a finite '..k) end
  end
  if not (sc.width>0 and sc.h>0) then fail(def,'shortcut '..i..' needs a positive width and height') end
  if not (isInt(sc.col) and isInt(sc.row)) then fail(def,'shortcut '..i..' needs integer col/row') end
  if sc.col<1 or sc.col>=#def.xs or sc.row<1 or sc.row>=#def.ys then fail(def,'shortcut '..i..' col/row is outside the block grid') end
  if sc.x-8<58 or sc.y-8<58 or sc.x+8>def.w-58 or sc.y+sc.h+8>def.h-84 then
   fail(def,'shortcut '..i..' sits outside the drivable area') end
  -- endpoint ids are integers, unique across every shortcut endpoint, and never
  -- reuse an ordinary road id: duplicates would silently overwrite nodes
  if type(sc.nodeIds)~='table' or #sc.nodeIds~=2 then fail(def,'shortcut '..i..' needs exactly two node ids') end
  for _,nid in ipairs(sc.nodeIds) do
   if not isInt(nid) then fail(def,'shortcut '..i..' node id '..tostring(nid)..' is not an integer') end
   if nid<=road then fail(def,'shortcut '..i..' endpoint id '..tostring(nid)..' collides with ordinary road ids') end
   if endpointIds[nid] then fail(def,'shortcut endpoint id '..tostring(nid)..' is used by more than one shortcut') end
   endpointIds[nid]=true
  end
  if sc.nodeIds[1]==sc.nodeIds[2] then
   fail(def,'shortcut '..i..' reuses endpoint id '..tostring(sc.nodeIds[1])) end
  if type(sc.attachments)~='table' or #sc.attachments~=2 then
   fail(def,'shortcut '..i..' needs attachments for both endpoints') end
  for _,ends in ipairs(sc.attachments) do
   if type(ends)~='table' or #ends<1 then fail(def,'shortcut '..i..' attachment has no road ids') end
   for _,rid in ipairs(ends) do
    if not isInt(rid) or rid<1 or rid>road then
     fail(def,'shortcut '..i..' attaches to non-road id '..tostring(rid)) end
   end
  end
  if type(sc.label)~='table' or type(sc.label[1])~='string' or type(sc.label[2])~='string' then
   fail(def,'shortcut '..i..' needs a two-line label') end
 end
 if type(def.spawnNodeIds)~='table' or #def.spawnNodeIds==0 then fail(def,'needs spawn node ids') end
 for i,sid in ipairs(def.spawnNodeIds) do
  if not isInt(sid) or sid<1 or sid>road then
   fail(def,'spawnNodeIds['..i..'] ('..tostring(sid)..') is not an ordinary road node') end
 end
 if type(def.start)~='table' or not (finite(def.start.x) and finite(def.start.y) and finite(def.start.angle)) then
  fail(def,'start needs finite coordinates and angle') end
 if type(def.initialJobs)~='table' or #def.initialJobs~=3 then fail(def,'needs three initial jobs') end
 for i,job in ipairs(def.initialJobs) do
  if type(job)~='table' or not seen[job.locationId] then fail(def,'initial job '..i..' uses an unknown location id') end
  if type(job.kind)~='string' then fail(def,'initial job '..i..' needs a cargo kind') end
  local Data=require('game.data')
  if not Data.cargo[job.kind] then fail(def,'initial job '..i..' uses unknown cargo kind "'..job.kind..'"') end
 end
end

-- Buildings use the shared block rule: each block starts 39px inside its road
-- centers, and a shortcut alley splits the block named by its col/row with a
-- 12px gap either side of the alley center.
local function buildBuildings(def)
 local xs,ys=def.xs,def.ys
 local splits={}
 for _,sc in ipairs(def.shortcuts) do splits[sc.col..':'..sc.row]=sc end
 local buildings={}
 for row=1,#ys-1 do for col=1,#xs-1 do
  local x,y=xs[col]+39,ys[row]+39
  local w,h=xs[col+1]-x-39,ys[row+1]-y-39
  local style=(col+row)%4+1
  local sc=splits[col..':'..row]
  if sc then
   buildings[#buildings+1]={x=x,y=y,w=sc.x-12-x,h=h,style=style}
   buildings[#buildings+1]={x=sc.x+12,y=y,w=x+w-sc.x-12,h=h,style=style}
  else
   buildings[#buildings+1]={x=x,y=y,w=w,h=h,style=style}
  end
 end end
 return buildings
end

-- Road grid plus shortcuts in the documented order: left/right/up/down grid
-- links first, then each shortcut's endpoint attachments and its internal
-- pair link, so both districts keep the original link append order. The built
-- shortcut descriptors are deep copies; nothing is shared with the definition.
local function buildNodes(def)
 local xs,ys=def.xs,def.ys
 local nodes={}
 for r=1,#ys do for c=1,#xs do
  local i=(r-1)*#xs+c
  nodes[i]={x=xs[c],y=ys[r],links={}}
  if c>1 then nodes[i].links[#nodes[i].links+1]=i-1 end
  if c<#xs then nodes[i].links[#nodes[i].links+1]=i+1 end
  if r>1 then nodes[i].links[#nodes[i].links+1]=i-#xs end
  if r<#ys then nodes[i].links[#nodes[i].links+1]=i+#xs end
 end end
 local shortcuts={}
 for _,sc in ipairs(def.shortcuts) do
  local a,b=sc.nodeIds[1],sc.nodeIds[2]
  nodes[a]={x=sc.x,y=sc.y,links={}}
  for _,road in ipairs(sc.attachments[1]) do
   nodes[road].links[#nodes[road].links+1]=a
   nodes[a].links[#nodes[a].links+1]=road
  end
  nodes[b]={x=sc.x,y=sc.y+sc.h,links={}}
  for _,road in ipairs(sc.attachments[2]) do
   nodes[road].links[#nodes[road].links+1]=b
   nodes[b].links[#nodes[b].links+1]=road
  end
  nodes[a].links[#nodes[a].links+1]=b
  nodes[b].links[#nodes[b].links+1]=a
  shortcuts[#shortcuts+1]={
   x=sc.x,y=sc.y,h=sc.h,width=sc.width,col=sc.col,row=sc.row,
   nodeIds={a,b},attachments={deepcopy(sc.attachments[1]),deepcopy(sc.attachments[2])},
   label={sc.label[1],sc.label[2]},
  }
 end
 return nodes,shortcuts
end

local function bind(m)
 function m.nearest(x,y)
  local best,d=1,math.huge
  for i,n in ipairs(m.nodes) do local dd=(n.x-x)^2+(n.y-y)^2;if dd<d then best,d=i,dd end end
  return best
 end
 function m.camera(x,y)
  return math.floor(math.max(0,math.min(m.w-320,x-160))),
         math.floor(math.max(0,math.min(m.h-190,y-95)))
 end
 function m.visible(px,py,x,y,padding)
  local cx,cy=m.camera(px,py);local margin=padding or 0
  return x>=cx-margin and x<=cx+320+margin and y>=cy-margin and y<=cy+190+margin
 end
 function m.path(a,b)
  local dist,prev,done={[a]=0},{},{}
  for _=1,#m.nodes do
   local u,best=nil,math.huge
   for i,d in pairs(dist) do if not done[i] and d<best then u,best=i,d end end
   if not u or u==b then break end
   done[u]=true
   for _,v in ipairs(m.nodes[u].links) do
    local A,B=m.nodes[u],m.nodes[v]
    local alt=best+math.sqrt((A.x-B.x)^2+(A.y-B.y)^2)
    if not dist[v] or alt<dist[v] then dist[v],prev[v]=alt,u end
   end
  end
  local out={b};local u=b
  while prev[u] do u=prev[u];table.insert(out,1,u) end
  return out
 end
 function m.route(x,y,tx,ty)
  local out={{x=x,y=y}}
  for _,i in ipairs(m.path(m.nearest(x,y),m.nearest(tx,ty))) do table.insert(out,m.nodes[i]) end
  table.insert(out,{x=tx,y=ty});return out
 end
 function m.blocked(x,y,r)
  if x-r<58 or y-r<58 or x+r>m.w-58 or y+r>m.h-84 then return 'edge' end
  for i,b in ipairs(m.buildings) do
   local cx=math.max(b.x,math.min(x,b.x+b.w));local cy=math.max(b.y,math.min(y,b.y+b.h))
   if (x-cx)^2+(y-cy)^2<r*r then return i end
  end
  return false
 end
end

-- Build one definition into a cached-free, self-contained map table.
local function build(def)
 checkDefinition(def)
 local nodes,shortcuts=buildNodes(def)
 -- no partial or silently overwritten node array may reach validation
 local expected=#def.xs*#def.ys+2*#def.shortcuts
 if #nodes~=expected then
  fail(def,'built '..#nodes..' nodes but '..expected..' were authored; refusing a partial map')
 end
 for i=1,#nodes do
  if type(nodes[i])~='table' then fail(def,'node '..i..' is missing from the built map') end
 end
 local map={
  id=def.id,label=def.label,subtitle=def.subtitle,
  w=def.w,h=def.h,halfwidth=def.halfwidth,
  xs=deepcopy(def.xs),ys=deepcopy(def.ys),
  locations=deepcopy(def.locations),
  buildings=buildBuildings(def),
  nodes=nodes,shortcuts=shortcuts,
  spawnNodeIds=deepcopy(def.spawnNodeIds),
  start=deepcopy(def.start),
  initialJobs=deepcopy(def.initialJobs),
  theme=deepcopy(def.theme or {}),
 }
 map.locationIndex={}
 for i,loc in ipairs(map.locations) do map.locationIndex[loc.id]=i end
 local ok,why=Validate.check(map)
 if not ok then error(why,0) end
 bind(map)
 return map
end

Build.build=build
return setmetatable(Build,{__call=function(_,def) return build(def) end})
