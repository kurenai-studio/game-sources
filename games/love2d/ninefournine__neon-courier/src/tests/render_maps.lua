-- Task 2: map-owned rendering and cache correctness. Exercises the REAL
-- game.render/game.art with an instrumented graphics stub (no files, windows
-- or audio); render/art modules are reset between isolated stubs. City-canvas
-- contents are recorded per canvas and cleared when that canvas is rebuilt;
-- a frame observes cached contents only through the g.draw that renders them.
package.path='./?.lua;./?/init.lua;'..package.path
local Map=require('game.map')
local Sim=require('game.sim')

local count=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then print('FAIL '..name..': '..tostring(err));os.exit(1) end
 count=count+1;print('PASS '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<=.001,tostring(a)..' ~= '..tostring(b)) end

local function makeStub()
 local frame={labels={},rects={},draws={}}
 local counts={images=0,fonts=0,canvases=0,rebuilds=0}
 local active=nil
 local cityCanvas=nil
 local function resetF()
  frame.labels={};frame.rects={};frame.draws={}
 end
 local function note(text,x,y)
  local e={text=text,x=x,y=y}
  if active then active.labels[#active.labels+1]=e else frame.labels[#frame.labels+1]=e end
 end
 local function rect(mode,x,y,w,h)
  local r={op='rect',mode=mode,x=x,y=y,w=w,h=h}
  if active then active.rects[#active.rects+1]=r else frame.rects[#frame.rects+1]=r end
 end
 local g={
  setColor=function() end,setFont=function() end,setLineWidth=function() end,setBlendMode=function() end,
  setScissor=function() end,setLineStyle=function() end,push=function() end,pop=function() end,
  origin=function() end,translate=function() end,scale=function() end,rotate=function() end,
  clear=function() end,
  draw=function(c,x,y,r,sx,sy) frame.draws[#frame.draws+1]={canvas=c,x=x,y=y,r=r,sx=sx,sy=sy} end,
  rectangle=rect,
  circle=function(mode,x,y,r) local t={op='circle',mode=mode,x=x,y=y,r=r};if active then active.rects[#active.rects+1]=t else frame.rects[#frame.rects+1]=t end end,
  line=function(a,b,c,d) local t={op='line',mode='line',x=a,y=b,w=c-a,h=d-b};if active then active.rects[#active.rects+1]=t else frame.rects[#frame.rects+1]=t end end,
  polygon=function(mode,...) local t={op='polygon',mode=mode};if active then active.rects[#active.rects+1]=t else frame.rects[#frame.rects+1]=t end end,
  print=function(text,x,y) note(tostring(text),x,y) end,
  printf=function(text,x,y,w,align) note(tostring(text),x,y) end,
  newCanvas=function(w,h)
   counts.canvases=counts.canvases+1
   local c={w=w,h=h,setFilter=function() end,labels={},rects={}}
   if w==960 and h==720 and not cityCanvas then cityCanvas=c end
   return c
  end,
  setCanvas=function(c)
   if c==nil then active=nil;return end
   if type(c)=='table' and c.labels then
    active=c
    if c==cityCanvas then counts.rebuilds=counts.rebuilds+1;c.labels={};c.rects={} end
   end
  end,
  getCanvas=function() return active end,
  newFont=function(size)
   counts.fonts=counts.fonts+1
   return {setFilter=function() end,getWidth=function(t) return #tostring(t)*7 end,getHeight=function() return 10 end}
  end,
  newImage=function(path)
   counts.images=counts.images+1
   return {setFilter=function() end,getWidth=function() return 32 end,getHeight=function() return 32 end}
  end,
  setDefaultFilter=function() end,
  getDimensions=function() return 640,480 end,
  getDPIScale=function() return 1 end,
  getRendererInfo=function() return 'stub','stub','stub','stub' end,
 }
 return {graphics=g,timer={getTime=function() return 0 end}},frame,counts,note,resetF,function() return cityCanvas end
end

local function setup(loveMap)
 package.loaded['game.render']=nil
 package.loaded['game.art']=nil
 local love,frame,counts,note,resetF,getCity=makeStub()
 _G.love=love
 local render=require('game.render')
 local art=package.loaded['game.art']
 local realText=art.text
 art.text=function(t,x,y,s,c)
  note('[art] '..tostring(t),x,y)
  return realText(t,x,y,s,c)
 end
 render.load(loveMap)
 -- resolve the ACTUAL city canvas created by the load before returning
 local city=getCity()
 assert(city,'the real renderer must create exactly one 960x720 city canvas')
 return render,frame,counts,resetF,city
end

local function strip(t) return (t:gsub('^%[art%] ','')) end
local function labelText(entries,text,minCount)
 local n=0
 for _,e in ipairs(entries) do if e.text==text or strip(e.text)==text then n=n+1 end end
 return n>=(minCount or 1)
end
-- labels observable in the current frame: live labels plus the drawn cache
local function cacheLabels(frame,city)
 local out={}
 for _,d in ipairs(frame.draws) do
  if d.canvas==city then for _,e in ipairs(city.labels) do out[#out+1]=e end end
 end
 return out
end
local function seen(frame,city,text,minCount)
 if labelText(frame.labels,text,minCount) then return true end
 return labelText(cacheLabels(frame,city),text,minCount)
end
local function drawKinds(frame,city)
 local k={city=0,illustration=0,vehicle=0}
 for _,d in ipairs(frame.draws) do
  if d.canvas==city then k.city=k.city+1
  elseif d.sx==4 and d.x==522 and d.y==130 then k.illustration=k.illustration+1
  else k.vehicle=k.vehicle+1 end
 end
 return k
end

local function simFor(mapId,phase)
 local s=Sim.new(72891,Map.get(mapId))
 if phase=='cargo' then
  s.jobs={{location=1,kind='medical'}};assert(Sim.pickup(s,1))
 elseif phase=='upgrade' then
  s.upgradeProgress=3;Sim.offer(s)
 elseif phase=='results' then
  Sim.finish(s,'SHIFT COMPLETE')
 end
 return s
end

local function appFor(mode,extra)
 local a={mode=mode,selection=1,settings={effects=true,shake=true},settingsReturn='title',
  highscores={},sim=nil}
 a.selectedDistrictId='district07'
 for k,v in pairs(extra or {}) do a[k]=v end
 return a
end

local WF_SIGNS={'ANCHOR LIGHT','TIDEWAY','NIGHT TIDE','PIER 12','FIRST AID','BRINE ROOM','BREAKWATER','DISPATCH'}
local D07_SIGNS={'LUCKY CAT','AFTERHOURS','NIGHT MART','PIER 09','CLINIC','VELVET','POWER 03','DISPATCH'}
local function groundY(signList,map)
 for i,s in ipairs(signList) do if s=='DISPATCH' then return map.locations[8].y-40 end end
end

test('preview ignores retained shift',function()
 local render,frame,counts,resetF,city=setup()
 eq(counts.images,5);eq(counts.fonts,11);eq(counts.canvases,1)
 local retained=simFor('district07','cargo')
 resetF()
 render.draw(appFor('title',{sim=retained,selectedDistrictId='waterfront'}))
 for _,s in ipairs(WF_SIGNS) do assert(seen(frame,city,s),'title preview must draw Waterfront sign '..s) end
 for _,s in ipairs(D07_SIGNS) do
  if s~='DISPATCH' then assert(not seen(frame,city,s),'title preview must not draw District07 sign '..s) end
 end
 assert(seen(frame,city,'ANCHOR LIGHT',2),'Waterfront must show roof and ground Anchor Light')
 local kinds=drawKinds(frame,city)
 eq(kinds.city,1);eq(kinds.illustration,1)
 eq(kinds.vehicle,0,'a title preview must not paint retained vehicles')
 -- title-settings from title also previews the selection without the shift
 resetF()
 render.draw(appFor('settings',{sim=retained,selectedDistrictId='waterfront',settingsReturn='title'}))
 for _,s in ipairs(WF_SIGNS) do assert(seen(frame,city,s),'title-settings must draw Waterfront sign '..s) end
 local sk=drawKinds(frame,city)
 eq(sk.city,1);eq(sk.illustration,0);eq(sk.vehicle,0)
 -- omitted selection falls back to District07 despite a Waterfront shift
 local wf=simFor('waterfront','cargo')
 local app=appFor('title',{sim=wf})
 app.selectedDistrictId=nil
 assert(app.selectedDistrictId==nil,'the omitted selection must be nil, not the default')
 resetF()
 render.draw(app)
 assert(seen(frame,city,'LUCKY CAT'),'an omitted selection must preview District07')
 assert(not seen(frame,city,'ANCHOR LIGHT'),'an omitted selection must not preview the retained Waterfront shift')
 -- an unknown selection is rejected without replacing the valid cache
 resetF()
 local before=counts.rebuilds
 render.draw(appFor('title',{sim=wf,selectedDistrictId='nowhere-district'}))
 eq(counts.rebuilds,before)
 assert(seen(frame,city,'LUCKY CAT'),'an unknown selection must keep the District07 cache')
 assert(not seen(frame,city,'ANCHOR LIGHT'),'an unknown selection must not draw Waterfront')
 eq(drawKinds(frame,city).city,1)
end)

test('active screens retain shift map',function()
 local render,frame,counts,resetF,city=setup()
 for _,mode in ipairs({'playing','paused','upgrade','results'}) do
  local s=simFor('waterfront',mode=='upgrade' and 'upgrade' or mode=='results' and 'results' or 'cargo')
  resetF()
  render.draw(appFor(mode,{sim=s,selectedDistrictId='district07'}))
  assert(seen(frame,city,'ANCHOR LIGHT'),mode..' must keep the active Waterfront district')
  assert(not seen(frame,city,'LUCKY CAT'),mode..' must not use the title selection')
 end
 local s=simFor('waterfront','cargo')
 resetF()
 render.draw(appFor('settings',{sim=s,selectedDistrictId='district07',settingsReturn='paused'}))
 assert(seen(frame,city,'ANCHOR LIGHT'),'pause-settings must keep the active district')
 assert(not seen(frame,city,'LUCKY CAT'),'pause-settings must not use the title selection')
 -- a real playing frame routes the active map and names the cargo target
 local routes={}
 local realRoute=s.map.route
 s.map.route=function(a,b,c,d) routes[#routes+1]={a,b,c,d};return realRoute(a,b,c,d) end
 resetF()
 render.draw(appFor('playing',{sim=s,selectedDistrictId='district07'}))
 s.map.route=realRoute
 local target=s.map.locations[s.cargo.destination]
 assert(seen(frame,city,target.name),'HUD must name the active Waterfront destination '..target.name)
 assert(#routes>0,'the playing frame must route through the active map')
 local r=routes[1]
 eq(r[1],s.player.x);eq(r[2],s.player.y);eq(r[3],target.x);eq(r[4],target.y)
 local kinds=drawKinds(frame,city)
 eq(kinds.city,1)
 assert(kinds.vehicle>0,'the playing frame must draw the active shift vehicles')
 eq(counts.canvases,1)
end)

test('switch clears old associations and signs',function()
 local render,frame,counts,resetF,city=setup()
 local d07=Map.get('district07')
 assert(labelText(city.labels,'LUCKY CAT',2),'District07 must show Lucky Cat roof and ground signs')
 assert(labelText(city.labels,'NIGHT MART',2),'District07 must show Night Mart roof and ground signs')
 local noodle=d07.locations[1]
 local ground,roof=false,nil
 for _,e in ipairs(city.labels) do
  if strip(e.text)=='LUCKY CAT' then
   if e.y==noodle.y-40 then ground=true end
   if e.y and e.y>=noodle.y then roof=e end
  end
 end
 assert(ground,'the ground sign must sit at location.y-40 (distance '..(noodle.y-40)..')')
 assert(roof,'a Lucky Cat roof sign must exist')
 local onBuilding=false
 for _,b in ipairs(d07.buildings) do
  if roof.x and roof.x>=b.x and roof.x<=b.x+b.w and roof.y>=b.y and roof.y<=b.y+b.h then onBuilding=true end
 end
 assert(onBuilding,'the Lucky Cat roof sign must land on an associated building')
 local wf=Map.get('waterfront')
 resetF()
 render.setMap(wf)
 render.draw(appFor('title',{selectedDistrictId='waterfront'}))
 for _,s in ipairs(WF_SIGNS) do assert(seen(frame,city,s),'switching to Waterfront must draw sign '..s) end
 assert(seen(frame,city,'ANCHOR LIGHT',2),'Waterfront must show Anchor Light roof and ground signs')
 local wfNoodle=wf.locations[1]
 local wfRoof,wfGround=false,false
 for _,e in ipairs(city.labels) do
  if strip(e.text)=='ANCHOR LIGHT' then
   if e.y==wfNoodle.y-40 then wfGround=true end
   if e.y and e.y>=wfNoodle.y then wfRoof=e end
  end
 end
 assert(wfGround,'the Waterfront ground sign must sit at location.y-40')
 assert(wfRoof,'a Waterfront roof sign must exist')
 local wfOnBuilding=false
 for _,b in ipairs(wf.buildings) do
  if wfRoof.x and wfRoof.x>=b.x and wfRoof.x<=b.x+b.w and wfRoof.y>=b.y and wfRoof.y<=b.y+b.h then wfOnBuilding=true end
 end
 assert(wfOnBuilding,'the Anchor Light roof sign must land on a Waterfront building')
 resetF()
 render.setMap(Map.get('district07'))
 render.setMap(wf)
 render.draw(appFor('title',{selectedDistrictId='waterfront'}))
 for _,s in ipairs(D07_SIGNS) do
  if s~='DISPATCH' then assert(not seen(frame,city,s),'no District07 sign may survive the switches: '..s) end
 end
 assert(seen(frame,city,'ANCHOR LIGHT'),'the final cache must be Waterfront')
 -- authored shortcut descriptors and alley geometry
 for i,sc in ipairs(wf.shortcuts) do
  assert(seen(frame,city,sc.label[1]) and seen(frame,city,sc.label[2]),'shortcut labels must come from map data')
  local alley
  for _,r in ipairs(city.rects) do
   if r.op=='rect' and r.x==sc.x-12 and r.w==24 and r.y==sc.y and r.h==sc.h then alley=r end
  end
  assert(alley,'alley '..i..' must use the authored x/width/y/height')
 end
 local water,quay
 for _,r in ipairs(city.rects) do
  if r.op=='rect' and r.x==wf.theme.waterX then water=r end
  if r.op=='rect' and r.x==wf.theme.quayX then quay=r end
 end
 assert(water,'water must start at x=916')
 assert(quay,'the quay must appear at x=902')
 -- horizontal pavement/edges/markings clip to the quay
 local wfPavement
 for _,r in ipairs(city.rects) do
  if r.op=='rect' and r.x==0 and r.y==96-28 and r.h==56 and r.w==902 then wfPavement=r end
 end
 assert(wfPavement,'Waterfront pavement must clip to x=902 at the first road center')
end)

test('same map does not rebuild',function()
 local render,frame,counts,resetF,city=setup()
 eq(counts.images,5);eq(counts.fonts,11);eq(counts.canvases,1)
 resetF()
 render.setMap(Map.get('waterfront'))
 eq(counts.rebuilds,2)
 render.draw(appFor('title',{selectedDistrictId='waterfront'}))
 local afterSwitch=counts.rebuilds
 assert(seen(frame,city,'NIGHT TIDE'),'the reuse case must draw Waterfront signs')
 render.setMap(Map.get('waterfront'))
 eq(counts.rebuilds,afterSwitch)
 resetF()
 render.draw(appFor('title',{selectedDistrictId='waterfront'}))
 eq(counts.rebuilds,afterSwitch)
 assert(seen(frame,city,'NIGHT TIDE'),'the reused cache must still draw Waterfront signs')
 eq(counts.images,5);eq(counts.fonts,11);eq(counts.canvases,1)
end)

test('resize rebuilds current map',function()
 local render,frame,counts,resetF,city=setup()
 local function playingFrame(map)
  local s=simFor(map.id,'cargo')
  resetF()
  render.draw(appFor('playing',{sim=s,selectedDistrictId=map.id=='waterfront' and 'district07' or 'waterfront'}))
  return s
 end
 for _,map in ipairs({Map.get('waterfront'),Map.get('district07')}) do
  render.setMap(map)
  local before=counts.rebuilds
  resetF()
  render.rebuild()
  eq(counts.rebuilds,before+1)
  local s=playingFrame(map)
  eq(counts.rebuilds,before+1,'a draw must not spuriously rebuild')
  local roadEnd=(map.theme and map.theme.roadEndX) or map.w
  -- pavement in the cache
  local pavement
  for _,r in ipairs(city.rects) do
   if r.op=='rect' and r.x==0 and r.y==96-28 and r.h==56 then pavement=r end
  end
  assert(pavement,'pavement must exist for '..map.id)
  eq(pavement.w,roadEnd)
  -- minimap roads in the live frame
  local horiz,vert={},{}
  for _,r in ipairs(frame.rects) do
   if r.op=='rect' and r.mode=='fill' and r.h==2 and r.x==30 and r.w>60 then horiz[#horiz+1]=r end
   if r.op=='rect' and r.mode=='fill' and r.w==2 and r.h>60 then vert[#vert+1]=r end
  end
  eq(#horiz,#map.ys)
  eq(#vert,#map.xs)
  for _,r in ipairs(horiz) do near(r.w,roadEnd*0.087) end
  assert(seen(frame,city,string.upper(map.label)),'the minimap must label '..map.label)
  -- pavement, edges and markings all clip to roadEnd (the background fill is
  -- drawn at full world width and is not road artwork)
  local pavement,edge,markOK
  for _,r in ipairs(city.rects) do
   if r.op=='rect' and r.x==0 and r.y==96-28 and r.h==56 then pavement=r end
   if r.op=='rect' and r.x==0 and r.y==96-28 and r.h==2 then edge=r end
   if r.op=='rect' and r.w==10 and r.h==1 and r.y==96 then
    if r.x+10>roadEnd then markOK=false end
   end
  end
  assert(pavement,'pavement must exist for '..map.id)
  eq(pavement.w,roadEnd)
  assert(edge,'a horizontal edge must exist for '..map.id)
  eq(edge.w,roadEnd)
  assert(markOK==nil or markOK,'markings must clip to roadEnd for '..map.id)
  eq(counts.images,5);eq(counts.fonts,11);eq(counts.canvases,1)
 end
end)

print('ALL '..count..' RENDER MAP TESTS PASSED')
