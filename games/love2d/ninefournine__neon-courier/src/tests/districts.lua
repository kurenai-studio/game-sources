-- Task 1 RED gate (before any map/simulation changes). Six named cases pin
-- the map API, Waterfront geometry, per-map ownership, validation errors, and
-- shared spawn/withdrawal rules. New APIs are lazy-loaded inside each case so
-- the missing interface is named by the failing case.
package.path='./?.lua;./?/init.lua;'..package.path
local Sim=require('game.sim')
local Map=require('game.map')
local Snapshot=require('tests.helpers.district_snapshot')
local FIXTURE=assert(loadfile('tests/fixtures/district07_baseline.lua'))()

local count=0
local FILTER=arg and arg[1] or nil
local NAMED={'legacy map and replay match frozen baseline','Waterfront geometry and jobs are authored',
             'separate maps own collision and routes','invalid definitions fail before exposure',
             'spawn and withdrawal rules hold on both maps','cargo and upgrade edges hold on both districts'}
if FILTER then
 local known=false
 for _,n in ipairs(NAMED) do if n==FILTER then known=true;break end end
 if not known then print('UNKNOWN CASE FILTER: '..FILTER);os.exit(1) end
end
local function test(name,fn)
 if FILTER and name~=FILTER then return end
 local ok,err=pcall(fn)
 if not ok then print('FAIL '..name..': '..tostring(err));os.exit(1) end
 count=count+1;print('PASS '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<.001,tostring(a)..' ~= '..tostring(b)) end
local function deepeq(a,b,path)
 if type(a)~=type(b) then return false,path..' type '..type(a)..'~='..type(b) end
 if type(a)~='table' then
  if a~=b then return false,path..' '..tostring(a)..' ~= '..tostring(b) end
  return true
 end
 local ka,kb={},{}
 for k in pairs(a) do ka[#ka+1]=k end
 for k in pairs(b) do kb[#kb+1]=k end
 if #ka~=#kb then return false,path..' key count '..#ka..' ~= '..#kb end
 for _,k in ipairs(ka) do
  if b[k]==nil then return false,path..' missing key '..tostring(k) end
  local ok,why=deepeq(a[k],b[k],path..'.'..tostring(k))
  if not ok then return false,why end
 end
 return true
end
local function moduleOp(name)
 local ok,m=pcall(require,name)
 if not ok then error(name..' must exist (planned module not implemented yet): '..tostring(m)) end
 return m
end
local function mapGet()
 assert(type(Map.get)=='function',
  'game.map must expose Map.get(id) while keeping the legacy District 07 facade')
 return Map.get
end

local SEEDS={72891,17,119,9001}

test('legacy map and replay match frozen baseline',function()
 local get=mapGet()
 -- the untouched singleton itself is still District 07
 local ok,why=deepeq(Snapshot.map(Map),FIXTURE.map,'snapshot.map')
 assert(ok,'frozen map geometry differs from the current singleton: '..tostring(why))
 -- implicit default Sim.new(seed) replays still identical to the frozen states
 for _,seed in ipairs(SEEDS) do
  local fresh=Snapshot.replay(seed)
  local okr,whyr=deepeq(fresh,FIXTURE.replays[tostring(seed)],'replay['..seed..']')
  assert(okr,'implicit default replay changed: '..tostring(whyr))
 end
 -- explicit District 07 map replays must match the same frozen states
 local a=get('district07')
 assert(a,'Map.get("district07") must return the built District 07 map')
 for _,seed in ipairs(SEEDS) do
  local fresh=Snapshot.replay(seed,a)
  local okr,whyr=deepeq(fresh,FIXTURE.replays[tostring(seed)],'explicit['..seed..']')
  assert(okr,'explicit District 07 replay changed: '..tostring(whyr))
 end
 -- legacy dot-call facade untouched
 eq(Map.w,960);eq(Map.h,720);eq(Map.halfwidth,28)
 eq(#Map.nodes,24);eq(#Map.buildings,14);eq(#Map.locations,8)
 eq(Map.locations[1].id,'noodle');eq(Map.locations[8].id,'dispatch')
 eq(Map.blocked(60,60,8),'edge')
 eq(Map.nearest(480,432),13)
 -- an unknown selected id is rejected with a reason, not silently defaulted
 local unknown,reason=get('unknown')
 eq(unknown,nil)
 assert(type(reason)=='string' and #reason>0,'unknown id must return a descriptive reason, got '..tostring(reason))
end)

test('Waterfront geometry and jobs are authored',function()
 local get=mapGet()
 local b=get('waterfront')
 assert(b,'Map.get("waterfront") must return the built Waterfront map')
 eq(b.id,'waterfront')
 assert(type(b.label)=='string' and #b.label>0,'Waterfront needs a label')
 assert(type(b.subtitle)=='string' and #b.subtitle>0,'Waterfront needs a subtitle')
 assert(b.w==960 and b.h==720 and b.halfwidth==28,'world/grid dimensions must match the shared baseline')
 eq(#b.nodes,24)
 eq(#b.buildings,14)
 local edges=0
 for _,n in ipairs(b.nodes) do edges=edges+#n.links end
 eq(edges,82) -- 41 undirected edges as two directed entries
 -- spec destination rows, in order, with exact names, signs and existing kinds
 local spec={
  {'noodle','ANCHOR LIGHT NOODLES','ANCHOR LIGHT',96,264,'noodle'},
  {'garage','TIDEWAY GARAGE','TIDEWAY',288,600,'garage'},
  {'mart','NIGHT TIDE MARKET','NIGHT TIDE',672,264,'mart'},
  {'dock','PIER 12 LOADING','PIER 12',864,600,'dock'},
  {'clinic','HARBOR FIRST AID','FIRST AID',480,96,'clinic'},
  {'club','BRINE ROOM CLUB','BRINE ROOM',96,600,'club'},
  {'substation','BREAKWATER POWER','BREAKWATER',864,96,'power'},
  {'dispatch','HARBOR DISPATCH','DISPATCH',480,432,'dispatch'},
 }
 for i,row in ipairs(spec) do
  local loc=b.locations[i]
  eq(loc.id,row[1],'destination '..i..' id')
  eq(loc.name,row[2],'destination '..i..' name')
  eq(loc.sign,row[3],'destination '..i..' sign')
  eq(loc.x,row[4],'destination '..i..' x')
  eq(loc.y,row[5],'destination '..i..' y')
  eq(loc.kind,row[6],'destination '..i..' kind')
 end
 assert(type(b.locationIndex)=='table','built map must expose an id-to-index lookup')
 eq(b.locationIndex['mart'],3)
 -- delivery candidates per origin: >260 pixels, counts in spec order
 local counts={7,5,4,7,6,6,6,5}
 for i,origin in ipairs(b.locations) do
  local n=0
  for _,loc in ipairs(b.locations) do
   if (loc.x-origin.x)^2+(loc.y-origin.y)^2>260^2 then n=n+1 end
  end
  eq(n,counts[i],'candidate count for origin '..origin.id)
 end
 -- exactly two shortcuts from the spec: warehouse cut 21/22, loading lane 23/24
 local sc=b.shortcuts
 assert(type(sc)=='table' and #sc==2,'Waterfront must expose exactly two shortcuts, got '..tostring(type(sc)=='table' and #sc or 'nil'))
 local n21,n22,n23,n24=b.nodes[21],b.nodes[22],b.nodes[23],b.nodes[24]
 eq(n21.x,576);eq(n21.y,96);eq(n22.x,576);eq(n22.y,264)
 eq(n23.x,768);eq(n23.y,264);eq(n24.x,768);eq(n24.y,432)
 local function has(node,id) for _,l in ipairs(node.links) do if l==id then return true end end return false end
 assert(has(n21,3) and has(n21,4) and has(n21,22),'warehouse cut top must link road nodes 3,4 and its pair')
 assert(has(n22,8) and has(n22,9) and has(n22,21),'warehouse cut bottom must link road nodes 8,9 and its pair')
 assert(has(n23,9) and has(n23,10) and has(n23,24),'loading lane top must link road nodes 9,10 and its pair')
 assert(has(n24,14) and has(n24,15) and has(n24,23),'loading lane bottom must link road nodes 14,15 and its pair')
 local function idlist(t,expected,label)
  assert(type(t)=='table' and #t==#expected,label..' length')
  for i,v in ipairs(expected) do eq(t[i],v,label..'['..i..']') end
 end
 -- published shortcut descriptors follow the approved interface
 eq(#sc,2)
 local function pin(sc,x,y,h,width,col,row,a,b,al,ar,bl,br,label1,label2)
  eq(sc.x,x);eq(sc.y,y);eq(sc.h,h);eq(sc.width,width);eq(sc.col,col);eq(sc.row,row)
  idlist(sc.nodeIds,{a,b},'shortcut nodeIds')
  idlist(sc.attachments[1],{al,ar},'shortcut top attachments')
  idlist(sc.attachments[2],{bl,br},'shortcut bottom attachments')
  idlist(sc.label,{label1,label2},'shortcut label')
 end
 pin(sc[1],576,96,168,24,3,1,21,22,3,4,8,9,'CUT','THRU')
 pin(sc[2],768,264,168,24,4,2,23,24,9,10,14,15,'CUT','THRU')
 assert(b.theme.waterX==916 and b.theme.quayX==902 and b.theme.roadEndX==902 and b.theme.warehouses==true,
  'Waterfront theme must publish waterX/quayX/roadEndX/warehouses')
 -- start pose and initial jobs keep the agreed order
 eq(b.start.x,480);eq(b.start.y,432)
 assert(b.start.angle<-1.56 and b.start.angle>-1.58,'start must face north (-math.pi/2), got '..tostring(b.start.angle))
 local jobs=b.initialJobs
 assert(type(jobs)=='table' and #jobs==3,'built map must expose ordered initialJobs')
 eq(jobs[1].locationId,'noodle');eq(jobs[1].kind,'medical')
 eq(jobs[2].locationId,'mart');eq(jobs[2].kind,'prototype')
 eq(jobs[3].locationId,'dock');eq(jobs[3].kind,'battery')
 -- Map.list is ordered District 07 then Waterfront and returns built maps
 assert(type(Map.list)=='function','game.map must expose Map.list()')
 local list=Map.list()
 eq(#list,2)
 assert(list[1]==get('district07'),'list[1] must be the cached District 07 map')
 assert(list[2]==get('waterfront'),'list[2] must be the cached Waterfront map')
 assert(list[1].nearest(480,432)==13 and list[2].blocked(576,180,8)==false,
  'listed maps must keep their usable helpers')
 eq(Map.list()[1].label,'DISTRICT 07')
 eq(Map.list()[2].label,'WATERFRONT')
end)

test('separate maps own collision and routes',function()
 local get=mapGet()
 local a,b=get('district07'),get('waterfront')
 assert(a and b,'both built-in maps must be available')
 -- the legacy alley (384,350) is clear only on District 07
 eq(a.blocked(384,350,8),false)
 assert(b.blocked(384,350,8)~=false,'Warehouse Cut geometry must cover the legacy alley on Waterfront')
 -- the Waterfront alley (576,180) is clear only on Waterfront
 eq(b.blocked(576,180,8),false)
 assert(a.blocked(576,180,8)~=false,'District 07 must block the Waterfront alley')
 -- routes belong to their own graph
 local ra,rb=a.route(576,96,576,264),b.route(576,96,576,264)
 -- a route is vertices/segments; the direct alley route may legitimately be
 -- just its endpoints, so prove the CONSECUTIVE SEGMENT traverses the alley
 -- instead of requiring an invented interior point
 local function alleySegment(route)
  for i=2,#route do
   local p,q=route[i-1],route[i]
   if p.x==576 and q.x==576 and math.min(p.y,q.y)>=96 and math.max(p.y,q.y)<=264 then return true end
  end
  return false
 end
 assert(alleySegment(rb),'a Waterfront route segment must traverse its warehouse alley at x=576')
 assert(not alleySegment(ra),'District 07 must not route through the Waterfront alley at x=576')
 -- each simulation owns its map; interleaved updates use each map's geometry
 local s1,s2=Sim.new(72891,a),Sim.new(72891,b)
 assert(type(s1.map)=='table' and s1.map==a,'Sim.new(seed,map) must record s.map')
 assert(type(s2.map)=='table' and s2.map==b,'Sim.new(seed,map) must record the passed map')
 eq(s1.districtId,'district07');eq(s2.districtId,'waterfront')
 -- interleaved pair vs two isolated controls, identical input per map, each
 -- starting in its OWN clear alley facing down with zero velocity and no
 -- random traffic, so movement proves per-map collision geometry
 local function pose(s,x,y)
  s.player.x,s.player.y=x,y
  s.player.angle=math.pi/2
  s.player.vx,s.player.vy=0,0
  s.cars={}
 end
 local function step(s)
  Sim.update(s,1/60,{x=0,y=1})
  s.events={}
 end
 local s3,s4=Sim.new(72891,a),Sim.new(72891,b)
 pose(s1,384,350);pose(s2,576,180);pose(s3,384,350);pose(s4,576,180)
 local y1a,y1b=s1.player.y,s2.player.y
 for i=1,60 do
  step(s1);step(s2)          -- interleaved pair
 end
 for i=1,60 do step(s3) end  -- isolated control for District 07
 for i=1,60 do step(s4) end  -- isolated control for Waterfront
 local ok1,why1=deepeq(Snapshot.sim(s1),Snapshot.sim(s3),'interleave-a')
 assert(ok1,'interleaved District 07 run diverged from its isolated control: '..tostring(why1))
 local ok2,why2=deepeq(Snapshot.sim(s2),Snapshot.sim(s4),'interleave-b')
 assert(ok2,'interleaved Waterfront run diverged from its isolated control: '..tostring(why2))
 assert(s1.player.y>y1a,'District 07 player must move down its alley from '..y1a..', stopped at '..s1.player.y)
 assert(s2.player.y>y1b,'Waterfront player must move down its alley from '..y1b..', stopped at '..s2.player.y)
 assert(math.abs(s1.player.x-384)<1,'District 07 player must stay in its alley column, x='..s1.player.x)
 assert(math.abs(s2.player.x-576)<1,'Waterfront player must stay in its alley column, x='..s2.player.x)
 assert(a.blocked(384,s1.player.y,8)==false,'District 07 alley must stay clear during movement')
 assert(b.blocked(576,s2.player.y,8)==false,'Waterfront alley must stay clear during movement')
 -- the legacy start of the sim (before posing) is unchanged by the pair run
 local w=Sim.new(72891,b)
 eq(w.jobs[1].location,1);eq(w.jobs[1].kind,'medical')
 eq(w.jobs[2].location,3);eq(w.jobs[2].kind,'prototype')
 eq(w.jobs[3].location,4);eq(w.jobs[3].kind,'battery')
end)

test('invalid definitions fail before exposure',function()
 local Build=moduleOp('game.maps.build')
 local Validate=moduleOp('game.maps.validate')
 local D07=moduleOp('game.maps.district07')
 local WF=moduleOp('game.maps.waterfront')
 local get=mapGet()
 local good={D07,WF}
 for _,def in ipairs(good) do
  assert(type(def)=='table' and type(def.id)=='string','definition modules must expose authored tables')
 end
 local function clone(v)
  if type(v)~='table' then return v end
  local out={}
  for k,val in pairs(v) do out[k]=clone(val) end
  return out
 end
 -- factory validation: malformed AUTHORED definitions must raise through Build.
 -- Definitions are plain authored tables (xs/ys/locations/shortcuts/start/jobs/
 -- spawn/theme) with no generated nodes/buildings, so every mutator must be
 -- valid until Build runs; the failure we assert is Build's, not the mutator's.
 local function expectBuildError(def,mutate,label)
  local m=clone(def)
  local mok,merr=pcall(mutate,m)
  assert(mok,'mutator itself failed for '..label..': '..tostring(merr))
  local ok,err=pcall(Build,m)
  assert(not ok,'Build must raise for a malformed definition: '..label)
  assert(type(err)=='string' and #err>0,label..' needs a descriptive error')
  assert(err:find(def.id,1,true),label..' error should name the district: '..tostring(err))
 end
 expectBuildError(WF,function(m) m.xs[1]=0/0 end,'NaN road coordinate')
 expectBuildError(WF,function(m) m.w=0 end,'non-positive world dimension')
 expectBuildError(WF,function(m) m.shortcuts[1].x=1e9 end,'out-of-bounds authored shortcut coordinate') expectBuildError(WF,function(m) m.start.x,m.start.y=m.xs[1]+39,m.ys[1]+39 end,'blocked start pose')
 expectBuildError(WF,function(m) m.locations[3].id=m.locations[4].id end,'duplicate location id')
 expectBuildError(WF,function(m) m.initialJobs[1].locationId='does-not-exist' end,'unknown job location id')
 expectBuildError(WF,function(m) m.initialJobs[1].kind='not-a-cargo' end,'invalid cargo kind')
 expectBuildError(WF,function(m) m.spawnNodeIds={1,2,21} end,'shortcut offered as a spawn id')
 expectBuildError(WF,function(m) m.spawnNodeIds={1,2,2.5} end,'fractional spawn id')
 expectBuildError(WF,function(m) m.spawnNodeIds={1,2,0/0} end,'NaN spawn id')
 expectBuildError(WF,function(m) m.shortcuts[1].attachments[1]={3,4.5} end,'fractional shortcut attachment')
 expectBuildError(WF,function(m) m.shortcuts[1].nodeIds={21,0/0} end,'NaN shortcut node id')
 expectBuildError(WF,function(m) m.shortcuts[1].width=-1 end,'non-positive shortcut width')
 -- duplicate shortcut descriptor: an independent deep copy of shortcut 1
 -- replacing shortcut 2 collides on every endpoint ID
 local dup=clone(D07)
 dup.shortcuts[2]=clone(D07.shortcuts[1])
 local dupok,duperr=pcall(Build,dup)
 assert(not dupok,'Build must reject duplicated shortcut node IDs, but it returned a map')
 assert(type(duperr)=='string' and duperr:find('district07',1,true),
  'the duplicate-shortcut error must name the district: '..tostring(duperr))
 -- repeated endpoint IDs inside one shortcut
 expectBuildError(WF,function(m) m.shortcuts[1].nodeIds={21,21} end,'repeated endpoint ids in one shortcut')
 expectBuildError(WF,function(m) m.shortcuts[1].nodeIds[2]=21 end,'repeated endpoint ids in one shortcut (second)')
 -- endpoints overlapping ordinary road ids
 expectBuildError(WF,function(m) m.shortcuts[1].nodeIds={3,4} end,'shortcut endpoints overlapping road ids')
 expectBuildError(WF,function(m) m.shortcuts[2].nodeIds={21,5} end,'shortcut endpoint overlapping a road id')
 -- graph-shape injections go through the production validator on a built map,
 -- per the ledger ruling: authored definitions generate their links, so a
 -- one-sided or disconnected link can only be injected after construction
 local a,b=get('district07'),get('waterfront')
 assert(a and b,'both built-in maps must exist before validation checks')
 local function expectValidateError(map,mutate,label,needle)
  local m=clone(map)
  mutate(m)
  local ok,reason=Validate.check(m)
  assert(not ok,'the validator must reject: '..label)
  assert(type(reason)=='string' and #reason>0,label..' needs a descriptive reason')
  if needle then assert(reason:find(needle,1,true),label..' reason should mention '..needle..': '..tostring(reason)) end
 end
 expectValidateError(b,function(m) table.insert(m.nodes[5].links,9) end,'one-sided link','link')
 -- connected component {19,20} keeps only their mutual link; all other
 -- incident links are removed reciprocally so every node keeps positive degree
 -- and the BFS connectivity check is what fails
 expectValidateError(b,function(m)
   local pair={19,20}
   for _,i in ipairs(pair) do
    local keep={}
    for _,l in ipairs(m.nodes[i].links) do
     if l==19 or l==20 then keep[#keep+1]=l end
     for _,j in ipairs(pair) do
      if j~=i then
       for k=#m.nodes[j].links,1,-1 do if m.nodes[j].links[k]==i then table.remove(m.nodes[j].links,k) end end
      end
     end
    end
    for _,l in ipairs(keep) do end
    local rebuilt={}
    for _,l in ipairs(m.nodes[i].links) do
     if (l==19 or l==20) and l~=i then rebuilt[#rebuilt+1]=l end
    end
    m.nodes[i].links=rebuilt
   end
   -- 19 keeps only 20 and 20 keeps only 19 (grid row-neighbours stay adjacent)
   m.nodes[19].links={20};m.nodes[20].links={19}
   for i=1,18 do
    for k=#m.nodes[i].links,1,-1 do
     local l=m.nodes[i].links[k]
     if l==19 or l==20 then table.remove(m.nodes[i].links,k) end
    end
   end
 end,'disconnected graph','connect')
 expectValidateError(b,function(m) m.buildings[#m.buildings+1]={x=196,y=103.9,w=.01,h=.01,style=1} end,
  'near-miss rectangle on a road segment','clear')
 -- built shortcut descriptors never share mutable tables with the definition
 local fresh=Build(WF)
 fresh.shortcuts[1].attachments[1][1]=99
 eq(WF.shortcuts[1].attachments[1][1],3,'built attachments must not alias the authored definition')
 fresh.shortcuts[1].nodeIds[1]=77
 eq(WF.shortcuts[1].nodeIds[1],21,'built nodeIds must not alias the authored definition')
 -- a rejected definition or map is never exposed; the cached maps survive
 eq(#Map.list(),2)
 local still=get('waterfront')
 assert(still and still.id=='waterfront' and #still.nodes==24 and #still.buildings==14,
  'a rejected definition must not replace the built Waterfront map')
 assert(still.locations[8].id=='dispatch','destination table must be unchanged')
 assert(get('district07').id=='district07','a rejected definition must not replace District 07')
end)

test('spawn and withdrawal rules hold on both maps',function()
 local get=mapGet()
 local corners={{66,66},{894,66},{66,628},{894,628}}
 local function distance(x,y) return x*x+y*y end
 for _,map in ipairs({get('district07'),get('waterfront')}) do
  local did=map.id
  -- spawn candidates are the complete ordered ordinary road node ids
  assert(type(map.spawnNodeIds)=='table','built map must expose ordered spawnNodeIds on '..did)
  eq(#map.spawnNodeIds,20)
  for i,id in ipairs(map.spawnNodeIds) do eq(id,i,'spawnNodeIds must be the ordered road ids 1..20 on '..did) end
  -- seeds 1..200: six fair initial cars with distance, node id, spacing,
  -- road-only and camera-exclusion rules
  for seed=1,200 do
   local s=Sim.new(seed,map)
   eq(#s.cars,6,'six initial cars on '..did..' seed '..seed)
   for i=1,#s.cars do
    local c=s.cars[i]
    assert(not map.blocked(c.x,c.y,8),'car on a building on '..did..' seed '..seed)
    assert(distance(c.x-s.player.x,c.y-s.player.y)>190*190,'car inside the 190px minimum on '..did..' seed '..seed)
    assert(c.node>=1 and c.node<=20,'spawn car nodes must be ordinary road ids on '..did..' seed '..seed)
    assert(not map.visible(s.player.x,s.player.y,c.x,c.y,24),'car spawned on screen on '..did..' seed '..seed)
    for j=i+1,#s.cars do
     local o=s.cars[j]
     assert(distance(c.x-o.x,c.y-o.y)>=48*48,'cars closer than 48 on '..did..' seed '..seed)
    end
   end
  end
  -- police keep the distance cap; shortcut targets stay legal for AI
  local s=Sim.new(4242,map);s.cars={}
  local police=0
  for attempt=1,120 do
   if not Sim.spawn(s,'police') then break end
   police=police+1
   local c=s.cars[#s.cars]
   local d=distance(c.x-s.player.x,c.y-s.player.y)
   assert(d>190*190,'police inside the minimum distance on '..did)
   assert(d<490*490,'police beyond the distance cap on '..did..': '..math.sqrt(d))
   assert(c.node>=1 and c.node<=20,'police must spawn on ordinary road nodes on '..did)
   assert(c.target>=1 and c.target<=#map.nodes,'AI targets may include shortcut nodes on '..did)
  end
  assert(police>0,'no police spawned on '..did)
  -- the 11-car cap refuses without touching RNG or ids
  local cap=Sim.new(77,map);cap.cars={}
  for i=1,11 do assert(Sim.spawn(cap,'traffic'),'cap fill on '..did) end
  local seedAt,idAt=cap.seed,cap.nextId
  eq(Sim.spawn(cap,'traffic'),false)
  eq(cap.seed,seedAt);eq(cap.nextId,idAt)
  -- no eligible candidate defers too, derived from the production rules and
  -- kept separate from the cap: six blockers occupy every legal police
  -- candidate at (66,66) and the car count stays well below the cap
  local none=Sim.new(78,map)
  none.cars={}
  local px,py=66,66
  none.player.x,none.player.y=px,py
  local candidates={}
  for _,id in ipairs(map.spawnNodeIds) do
   local n=map.nodes[id]
   local d=distance(n.x-px,n.y-py)
   if d>190*190 and d<490*490 and not map.visible(px,py,n.x,n.y,24) then candidates[#candidates+1]=id end
  end
  assert(#candidates==6,'expected six legal police candidates at (66,66) on '..did..', got '..#candidates)
  for i,id in ipairs(candidates) do
   local n=map.nodes[id]
   none.cars[i]={id=i,x=n.x,y=n.y,angle=0,kind='police',node=id,target=id,stun=0,speed=0}
  end
  eq(#none.cars,6)
  local seed2,id2=none.seed,none.nextId
  eq(Sim.spawn(none,'police'),false)
  eq(none.seed,seed2);eq(none.nextId,id2)
  -- four clamped-camera corners keep every candidate legal and offscreen
  for _,pos in ipairs(corners) do
   local c=Sim.new(99,map);c.cars={};c.player.x,c.player.y=pos[1],pos[2]
   for _=1,6 do assert(Sim.spawn(c,'traffic'),'corner spawn on '..did..' at '..pos[1]..','..pos[2]) end
   for _,car in ipairs(c.cars) do
    assert(not map.blocked(car.x,car.y,8),'corner car blocked on '..did)
    assert(distance(car.x-pos[1],car.y-pos[2])>190*190,'corner car inside the minimum distance on '..did)
    assert(car.node>=1 and car.node<=20,'corner spawn must use ordinary road nodes on '..did)
    assert(car.target>=1 and car.target<=#map.nodes,'corner AI targets may include shortcut nodes on '..did)
    assert(not map.visible(pos[1],pos[2],car.x,car.y,24),'corner car on screen on '..did)
   end
   for i=1,#c.cars do
    for j=i+1,#c.cars do
     local o=c.cars[j]
     assert(distance(c.cars[i].x-o.x,c.cars[i].y-o.y)>=48*48,'corner cars closer than 48 on '..did)
    end
   end
  end
  -- mirrored prototype withdrawal at this map's first shortcut entrance
  local sc=map.shortcuts
  assert(type(sc)=='table' and #sc==2,'map must expose exactly two shortcuts on '..did)
  assert(type(sc[1].nodeIds)=='table' and #sc[1].nodeIds==2,'a shortcut must name nodeIds={a,b} on '..did)
  assert(type(sc[1].attachments)=='table' and #sc[1].attachments==2,'a shortcut must name its road attachments on '..did)
  local top=map.nodes[sc[1].nodeIds[1]]
  local px2,py2=top.x,top.y+31
  local att=sc[1].attachments[1]
  assert(#att>=2,'the shortcut top needs two road attachments on '..did)
  local w=Sim.new(17,map);w.time=85;w.player.x,w.player.y=px2,py2;w.cars={}
  w.jobs={{location=1,kind='prototype'}};assert(Sim.pickup(w,1))
  for i,dx in ipairs({-80,-56,56,80}) do
   local x=px2+dx
   w.cars[i]={id=i,x=x,y=top.y,node=x<px2 and att[1] or att[2],target=sc[1].nodeIds[1],
    angle=x<px2 and 0 or math.pi,stun=0,speed=70,kind='police'}
  end
  Sim.update(w,1/60,{});assert(w.heat>3)
  local positions={};for i,c in ipairs(w.cars) do positions[i]={c.x,c.y} end
  Sim.deliver(w)
  local active,returning=0,0
  for _,c in ipairs(w.cars) do
   near(c.x,positions[c.id][1]);near(c.y,positions[c.id][2])
   if c.withdrawing then returning=returning+1;assert(c.exit,'withdrawing car needs an exit') else active=active+1 end
  end
  eq(active,2);eq(returning,2)
  -- remember the returning cars so deletion can be proven offscreen-only
  local refs={}
  for _,c in ipairs(w.cars) do
   if c.withdrawing then refs[c.id]={car=c,lastX=c.x,lastY=c.y,gone=false} end
  end
  for step=1,1800 do
   Sim.update(w,1/60,{});w.events={}
   for id,ref in pairs(refs) do
    if not ref.gone then ref.lastX,ref.lastY=ref.car.x,ref.car.y end
   end
   local present={}
   for _,c in ipairs(w.cars) do present[c.id]=c end
   for id,ref in pairs(refs) do
    if not ref.gone and not present[id] then
     ref.gone=true
     assert(not map.visible(w.player.x,w.player.y,ref.lastX,ref.lastY,24),
      'returning car '..id..' disappeared while still on screen on '..did)
    end
   end
   for _,c in ipairs(w.cars) do
    assert(not map.blocked(c.x,c.y,8),'patrol left the road on '..did)
    if c.exit then assert(c.exit>=1 and c.exit<=20,'exits must be ordinary road nodes on '..did) end
    if step<=60 and c.withdrawing then
     local before=positions[c.id]
     assert((c.x-w.player.x)^2+(c.y-w.player.y)^2>=(before[1]-px2)^2+(before[2]-py2)^2,
      'returning patrol initially closed on the courier on '..did)
    end
   end
  end
  active,returning=0,0
  for _,c in ipairs(w.cars) do if c.withdrawing then returning=returning+1 else active=active+1 end end
  eq(active,2);eq(returning,0);eq(w.player.hp,100)
 end
end)


test('cargo and upgrade edges hold on both districts',function()
 local get=mapGet()
 local function cargoOn(mapId,kind)
  local m=get(mapId);assert(m,'both districts must be available')
  local s=Sim.new(72891,m)
  local index=1
  for i,loc in ipairs(m.locations) do if loc.id=='noodle' then index=i end end
  s.jobs={{location=index,kind=kind}}
  assert(Sim.pickup(s,1),'pickup must succeed on '..mapId)
  return s
 end
 for _,district in ipairs({'district07','waterfront'}) do
  -- medical: separated impacts count once each, then lose cargo on the third
  local med=cargoOn(district,'medical')
  Sim.impact(med,'a',9);eq(med.cargo.integrity,2,district..' medical impact one')
  assert(not Sim.impact(med,'a',9),district..' impact cooldown must suppress repeats')
  eq(med.cargo.integrity,2,district..' no phantom impact')
  med.impactCooldown=0;Sim.impact(med,'b',9);eq(med.cargo.integrity,1,district..' medical impact two')
  med.impactCooldown=0;Sim.impact(med,'c',9)
  eq(med.cargo,nil,district..' medical cargo lost after three impacts')
  eq(med.failed,1,district..' medical failure counted')
  -- battery: expiry removes cargo, costs exactly 26 hull and can wreck
  local bat=cargoOn(district,'battery')
  bat.cargo.remaining=.01;Sim.update(bat,1/60,{})
  eq(bat.cargo,nil,district..' battery cargo expired')
  eq(bat.player.hp,74,district..' battery expiry costs exactly 26 hull')
  eq(bat.failed,1,district..' battery failure counted once')
  Sim.update(bat,1/60,{})
  eq(bat.player.hp,74,district..' a later ordinary tick must not damage again')
  eq(bat.failed,1,district..' a later tick must not repeat the failure')
  local doomed=cargoOn(district,'battery');doomed.player.hp=20;doomed.cargo.remaining=.01
  Sim.update(doomed,1/60,{})
  assert(doomed.over,district..' battery expiry can wreck')
  eq(doomed.endReason,'VEHICLE WRECKED',district..' battery expiry wrecks the vehicle')
  eq(doomed.failed,1,district..' the wreck counts one failure')
  -- prototype heat: carrying adds, delivering removes it again
  local pro=cargoOn(district,'prototype')
  pro.time=85;Sim.update(pro,1/60,{})
  assert(pro.heat>3,district..' prototype heat must raise')
  Sim.deliver(pro)
  near(pro.heat,pro.time/85,district..' prototype delivery must restore baseline heat')
  -- bounded upgrades: every real definition caps, and the pool empties when capped
  local up=cargoOn(district,'medical')
  local defs={}
  for _,u in ipairs(require('game.data').upgrades) do
   assert(u.id and u.max and u.max>=1 and u.name,'a real upgrade definition is required for '..district)
   defs[#defs+1]=u
  end
  for _=1,3 do
   up.upgradeProgress=up.upgradeTarget;Sim.offer(up)
   assert(#up.offers==3,district..' must offer three upgrades per batch')
   local batch={}
   for _,o in ipairs(up.offers) do
    assert(o.id and o.max and o.max>=1,'a real offer is required on '..district)
    assert(not batch[o.id],district..' offers must be unique within the batch')
    batch[o.id]=true
   end
   local pick=up.offers[1]
   local before=up.upgrades[pick.id] or 0
   assert(before<pick.max,district..' an offer must stay eligible to apply')
   assert(Sim.applyUpgrade(up,pick.id),district..' an offer must apply')
   eq(up.upgrades[pick.id],before+1,district..' applying must increment exactly once')
   assert(up.upgrades[pick.id]<=pick.max,district..' an applied upgrade must stay within its cap')
  end
  -- cap boundary: reach exactly max, refuse further application, then drain the pool
  for _,u in ipairs(defs) do
   local before=up.upgrades[u.id] or 0
   while before<u.max do
    up.awaitingUpgrade=true;up.offers={{id=u.id,name=u.name,description='',max=u.max}}
    assert(Sim.applyUpgrade(up,u.id),district..' must accept a below-cap application')
    local now=up.upgrades[u.id]
    eq(now,before+1,district..' below-cap application must increment exactly once')
    assert(now<=u.max,district..' application must stay within its cap')
    before=now
   end
   local capped=up.upgrades[u.id]
   up.awaitingUpgrade=true;up.offers={{id=u.id,name=u.name,description='',max=u.max}}
   assert(not Sim.applyUpgrade(up,u.id),district..' must refuse an application at the cap of '..u.id)
   eq(up.upgrades[u.id],capped,district..' a refused application must not increment '..u.id)
  end
  up.upgradeProgress=up.upgradeTarget;Sim.offer(up)
  eq(#up.offers,0,district..' a fully capped pool must offer nothing')
  assert(not up.awaitingUpgrade,district..' a capped pool must not pause for upgrades')
 end
end)
print('ALL '..count..' DISTRICT TESTS PASSED')