-- Task 3 district-flow regressions. Loads the real main.lua with a stubbed
-- LÖVE environment (same technique as the fullscreen suite), fresh modules and
-- an in-memory filesystem per case, and drives the actual love.load/keypressed/
-- gamepadpressed/update handlers with real Input/Save. No real window, files or
-- audio are created; the app table is inspected through its closure upvalue.
package.path='./?.lua;./?/init.lua;'..package.path

local function stubGraphics()
 return {
  setDefaultFilter=function() end,
  newCanvas=function() return {setFilter=function() end,newImageData=function() return {encode=function() return 'png' end} end} end,
  newImage=function() return {setFilter=function() end,getWidth=function() return 32 end,getHeight=function() return 32 end} end,
  setCanvas=function() end,getCanvas=function() return nil end,clear=function() end,
  push=function() end,pop=function() end,origin=function() end,setScissor=function() end,
  setColor=function() end,setLineWidth=function() end,setLineStyle=function() end,setBlendMode=function() end,
  rectangle=function() end,circle=function() end,line=function() end,polygon=function() end,
  draw=function() end,translate=function() end,scale=function() end,rotate=function() end,
  print=function() end,printf=function() end,setFont=function() end,
  newFont=function() return {setFilter=function() end,getWidth=function(t) return #tostring(t)*7 end,getHeight=function() return 10 end} end,
  captureScreenshot=function() end,getDimensions=function() return 640,480 end,
  getDPIScale=function() return 1 end,getRendererInfo=function() return 'stub','stub','stub','stub' end,
 }
end

local MODULES={'game.sim','game.input','game.save','game.render','game.audio','game.window','game.map',
 'game.maps.build','game.maps.validate','game.maps.district07','game.maps.waterfront','game.art'}
local function resetModules()
 for _,m in ipairs(MODULES) do package.loaded[m]=nil end
end

local function makeLove(opts)
 local files=opts and opts.files or {}
 local calls={identity='neon-courier-v1',reads=0,writes=0,quits=0,ui=0,emp=0,saveDir='/tmp/neon-test-save'} opts=opts or {}
 local love={
  graphics=stubGraphics(),
  window={
   updateMode=function(w,h) calls[#calls+1]='updateMode:'..w..'x'..h;return (opts.updateMode~=false) end,
   setFullscreen=function(enable) calls[#calls+1]='setFullscreen:'..tostring(enable);return (opts.setFullscreen or function() return true end)(enable==true) end,
   getFullscreen=function() return (opts.getFullscreen or function() return false end)() end,
   getDesktopDimensions=function() return 1512,982 end,
   getDisplayName=function() return 'stub' end,
  },
  filesystem={
   setIdentity=function(id) calls.identity=tostring(id) end,
   getIdentity=function() return calls.identity end,
   getSaveDirectory=function() return calls.saveDir end,
   getInfo=function(name)
    calls.reads=calls.reads+1
    calls.firstReadIdentity=calls.firstReadIdentity or calls.identity
    return files[name] and {size=#files[name]} or nil
   end,
   read=function(name) calls.reads=calls.reads+1;calls.firstReadIdentity=calls.firstReadIdentity or calls.identity;return files[name] end,
   write=function(name,data) calls.writes=calls.writes+1;files[name]=data;return true end,
  },
  timer={getTime=function() return 7 end},
  keyboard={isDown=function() return false end},
  joystick={getJoysticks=function() return opts.pad and {opts.pad} or {} end},
  event={quit=function() calls.quits=calls.quits+1 end},
 }
 setmetatable(love,{__index=_G})
 resetModules()
 _G.love=love -- required modules capture love.graphics at require time
 local ok,err=pcall(function() assert(loadfile('main.lua'))() end)
 if not ok then error('main.lua failed to load: '..tostring(err)) end
 -- a narrow spy on the real Audio.play counts menu/EMP dispatches
 local audio=package.loaded['game.audio']
 local realPlay=audio.play
 audio.play=function(name,...)
  if name=='ui' then calls.ui=calls.ui+1 elseif name=='emp' then calls.emp=calls.emp+1 end
  return realPlay(name,...)
 end
 love.load(opts.args or {})
 calls.saveDir=love.filesystem.getSaveDirectory()
 return love,files,calls
end

local function findApp()
 for i=1,30 do
  local n,v=debug.getupvalue(_G.love.keypressed,i)
  if not n then break end
  if type(v)=='table' and rawget(v,'mode') and rawget(v,'selection') and rawget(v,'clock') then return v end
 end
 return nil
end

local function settle(love,frames)
 for _=1,(frames or 120) do love.update(1/60) end
end

local function padStub()
 local p={held={},axes={leftx=0,lefty=0}}
 function p:isConnected() return true end
 function p:isGamepad() return true end
 function p:getGamepadAxis(k) return self.axes[k] or 0 end
 function p:isGamepadDown(...) for _,k in ipairs({...}) do if self.held[k] then return true end end;return false end
 return p
end

local Save=require('game.save')

local count=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then print('FAIL '..name..': '..tostring(err));os.exit(1) end
 count=count+1;print('PASS '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end

test('fresh title defaults District07',function()
 local valid='NEON1\nmusic=0.6\nsfx=0.7\nmute=false\nshake=true\neffects=true\npixelSize=1\nfullscreen=false\n'
 local love,files,calls=makeLove{files={['dispatch.sav']=valid}}
 local app=assert(findApp(),'main.lua must expose its app closure')
 eq(app.selectedDistrictId,'district07')
 eq(app.selection,1)
 eq(app.mode,'title')
 -- a normal launch keeps the production identity and reads the save after
 eq(calls.identity,'neon-courier-v1')
 eq(calls.firstReadIdentity,'neon-courier-v1','the identity is set before the save read')
 -- ordinary --waterfront alone selects nothing
 local l2,f2,c2=makeLove{args={'--waterfront'},files={['dispatch.sav']=valid}}
 local a2=assert(findApp())
 eq(a2.selectedDistrictId,'district07')
 eq(a2.test,nil,'--waterfront alone must not enable test mode')
 eq(c2.identity,'neon-courier-v1')
 eq(c2.firstReadIdentity,'neon-courier-v1')
 -- --waterfront beside an automated-test flag selects Waterfront, identity first
 for _,flag in ipairs({'--smoke','--soak','--web-test'}) do
  local l,f,c=makeLove{args={flag,'--waterfront'},files={['dispatch.sav']=valid}}
  local a=assert(findApp())
  eq(a.selectedDistrictId,'waterfront',flag..' must select Waterfront')
  eq(c.identity,'neon-courier-test-waterfront-v1',flag..' must set the Waterfront test identity')
  eq(c.firstReadIdentity,'neon-courier-test-waterfront-v1',flag..' must set the identity before reading saves')
 end
 -- the default test identity is unchanged
 local l4,f4,c4=makeLove{args={'--smoke'},files={['dispatch.sav']=valid}}
 eq(c4.identity,'neon-courier-test-v1')
 eq(c4.firstReadIdentity,'neon-courier-test-v1')
 assert(type(c4.saveDir)=='string' and #c4.saveDir>0,'the launcher must be able to report the save directory')
end)

test('keyboard and pad cycle two districts',function()
 local love,files,calls=makeLove()
 local app=assert(findApp())
 local Input=require('game.input')
 -- focus the district row
 love.keypressed('down');love.update(1/60)
 eq(app.selection,2)
 eq(app.selectedDistrictId,'district07')
 eq(calls.ui,1) -- one ui action for the row move
 -- selection only changes on the district row
 love.keypressed('up');love.update(1/60)
 love.keypressed('right');love.update(1/60)
 eq(app.selectedDistrictId,'district07')
 eq(calls.ui,2)
 love.keypressed('down');love.update(1/60)
 eq(app.selection,2)
 eq(calls.ui,3)
 -- one keyboard cycle counts exactly one ui action
 love.keypressed('right');love.update(1/60)
 eq(app.selectedDistrictId,'waterfront')
 eq(calls.ui,4)
 love.keypressed('left');love.update(1/60)
 eq(app.selectedDistrictId,'district07')
 eq(calls.ui,5)
 love.keypressed('left');love.update(1/60)
 eq(app.selectedDistrictId,'waterfront')
 eq(calls.ui,6)
 -- the gamepad dpad cycles the same way
 local pad=padStub()
 local love2,_,calls2=makeLove{pad=pad}
 local app2=assert(findApp())
 love2.keypressed('down');love2.update(1/60)
 local ui2=calls2.ui
 love2.gamepadpressed(pad,'dpright');love2.update(1/60)
 eq(app2.selectedDistrictId,'waterfront')
 eq(calls2.ui,ui2+1)
 love2.gamepadpressed(pad,'dpleft');love2.update(1/60)
 eq(app2.selectedDistrictId,'district07')
 eq(calls2.ui,ui2+2)
 -- a held pad presses immediately, then repeats on the .23s menu clock only
 ui2=calls2.ui
 pad.axes.leftx=1
 love2.update(1/60)
 eq(calls2.ui,ui2+1,'the held pad must press once immediately')
 love2.update(1/60) -- one frame later: below the repeat deadline
 eq(calls2.ui,ui2+1,'no extra action may fire before the repeat deadline')
 for _=1,25 do love2.update(1/60) end
 eq(calls2.ui,ui2+2,'the repeat fires only after the .23s menu clock')
 for _=1,90 do love2.update(1/60) end
 assert(calls2.ui>=ui2+7,'held repeat must keep cycling after the deadline')
 assert(calls2.ui<=ui2+10,'held repeat must stay tight to the .23s menu clock')
 pad.axes.leftx=0
 local heldEnd=calls2.ui
 for _=1,60 do love2.update(1/60) end
 eq(calls2.ui,heldEnd,'releasing the pad stops all cycling')
end)

test('simultaneous district edges change once',function()
 local love,files,calls=makeLove()
 local app=assert(findApp())
 local Input=require('game.input')
 love.keypressed('down');love.update(1/60)
 eq(app.selection,2)
 local uiBefore=calls.ui
 -- left, right and confirm arrive together before a single update
 love.keypressed('left');love.keypressed('right');love.keypressed('return')
 assert(Input.pressed.left and Input.pressed.right and Input.pressed.confirm,'all three edges are queued')
 love.update(1/60)
 eq(app.selectedDistrictId,'waterfront','the left edge wins a single wrap-around cycle')
 eq(app.mode,'title','a district action must not Start the shift')
 eq(app.sim,nil,'no shift may be created by a district action')
 eq(calls.ui,uiBefore+1,'exactly one action may apply')
 -- all three keys were consumed by the district action
 eq(Input.pressed.left,nil)
 eq(Input.pressed.right,nil)
 eq(Input.pressed.confirm,nil)
 -- the next update starts nothing
 love.update(1/60)
 eq(app.mode,'title')
 eq(app.sim,nil)
end)

test('Start binds selected map',function()
 local love,files=makeLove()
 local app=assert(findApp())
 love.keypressed('down');love.update(1/60)
 love.keypressed('right');love.update(1/60)
 eq(app.selectedDistrictId,'waterfront')
 love.keypressed('up');love.update(1/60)
 eq(app.selection,1)
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'playing')
 assert(app.sim~=nil,'Start must create a shift')
 eq(app.sim.map.id,'waterfront')
 eq(app.sim.districtId,'waterfront')
 eq(#app.sim.jobs,3)
 eq(app.sim.player.x,480);eq(app.sim.player.y,432)
end)

test('Run Again retains completed map',function()
 local love,files,calls=makeLove()
 local app=assert(findApp())
 love.keypressed('down');love.update(1/60)
 love.keypressed('right');love.update(1/60)
 love.keypressed('up');love.update(1/60)
 love.keypressed('return');love.update(1/60)
 local s=app.sim
 eq(s.map.id,'waterfront')
 eq(app.mode,'playing')
 require('game.sim').finish(s,'SHIFT COMPLETE')
 love.update(1/60)
 eq(app.mode,'results')
 eq(app.selection,1)
 local finishedMap=s.map
 -- the title selection moves away from the completed district before Run Again
 app.selectedDistrictId='district07'
 love.keypressed('return');love.update(1/60)
 assert(app.sim~=nil,'Run Again must create a fresh shift')
 eq(app.sim.map,finishedMap,'Run Again must reuse the completed district even if the selection changed')
 eq(app.sim.map.id,'waterfront')
 assert(app.sim~=s,'Run Again must create a new simulation')
 eq(app.sim.time,0)
 eq(app.sim.score,0)
 eq(app.mode,'playing')
end)

test('title preserves selection and previews independently',function()
 local love,files,calls=makeLove()
 local app=assert(findApp())
 local render=package.loaded['game.render']
 local realSetMap=render.setMap
 local previewMaps={}
 render.setMap=function(m) previewMaps[#previewMaps+1]=m.id;return realSetMap(m) end
 love.keypressed('down');love.update(1/60)
 love.keypressed('right');love.update(1/60)
 eq(app.selectedDistrictId,'waterfront')
 love.keypressed('up');love.update(1/60)
 love.keypressed('return');love.update(1/60)
 local finished=app.sim
 require('game.sim').finish(finished,'SHIFT COMPLETE')
 love.update(1/60)
 eq(app.mode,'results')
 -- returning to title moves the row back to Start
 love.keypressed('down');love.update(1/60)
 eq(app.selection,2)
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'title','returning to title keeps the selection')
 eq(app.selection,1,'title always opens on the Start row')
 eq(app.selectedDistrictId,'waterfront','the title selection survives a completed shift')
 -- the retained shift keeps its own map while the selection changes
 love.keypressed('down');love.update(1/60)
 eq(app.selection,2)
 love.keypressed('right');love.update(1/60)
 eq(app.selectedDistrictId,'district07')
 eq(app.sim.map.id,'waterfront','the retained simulation must keep its district')
 -- the preview resolves from the selection, not the retained map
 previewMaps={}
 love.draw()
 assert(#previewMaps>0,'the title preview must select a district map')
 assert(previewMaps[#previewMaps]=='district07','the title preview must follow the selection')
 -- title settings (row3) opens and returns without disturbing ownership
 love.keypressed('down');love.update(1/60)
 eq(app.selection,3)
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'settings')
 eq(app.settingsReturn,'title')
 love.keypressed('escape');love.update(1/60)
 eq(app.mode,'title')
 love.keypressed('down');love.update(1/60)
 love.keypressed('down');love.update(1/60)
 eq(app.selection,3)
 love.keypressed('up');love.update(1/60)
 love.keypressed('up');love.update(1/60)
 eq(app.selection,1)
 -- a new Start uses the current selection, not the retained map
 love.keypressed('return');love.update(1/60)
 eq(app.sim.map.id,'district07')
 render.setMap=realSetMap
end)

test('pause settings upgrades and disconnect retain map',function()
 local love,files,Sim=makeLove()
 local app=assert(findApp())
 love.keypressed('down');love.update(1/60)
 love.keypressed('right');love.update(1/60)
 love.keypressed('up');love.update(1/60)
 love.keypressed('return');love.update(1/60)
 local s=app.sim
 eq(s.map.id,'waterfront')
 -- focus loss pauses but keeps the map
 love.focus(false)
 eq(app.mode,'paused')
 eq(app.sim.map.id,'waterfront')
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'playing')
 -- pause settings and back
 love.keypressed('escape');love.update(1/60)
 eq(app.mode,'paused')
 love.keypressed('down');love.update(1/60)
 eq(app.selection,2)
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'settings')
 eq(app.settingsReturn,'paused')
 love.keypressed('escape');love.update(1/60)
 eq(app.mode,'paused','settings back must return to the paused shift')
 eq(app.selection,1)
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'playing','resume keeps the shift map')
 eq(app.sim.map.id,'waterfront')
 -- upgrade choice keeps the map
 require('game.sim').offer(s)
 assert(s.awaitingUpgrade,'the fixture must open an upgrade choice')
 love.update(1/60)
 eq(app.mode,'upgrade')
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'playing')
 eq(app.sim.map.id,'waterfront')
 -- active pad disconnect pauses the shift and keeps the map
 local pad=padStub()
 local love2,files2=makeLove{pad=pad}
 local app2=assert(findApp())
 love2.keypressed('down');love2.update(1/60)
 love2.keypressed('right');love2.update(1/60)
 love2.keypressed('up');love2.update(1/60)
 love2.keypressed('return');love2.update(1/60)
 local s2=app2.sim
 eq(s2.map.id,'waterfront')
 love2.update(1/60) -- connect the pad through the real Input path
 love2.joystickremoved(pad)
 eq(app2.mode,'paused')
 eq(app2.sim.map.id,'waterfront')
 -- EMP press is buffered and fires exactly once
 local love3,files3,calls3=makeLove()
 local app3=assert(findApp())
 love3.keypressed('return');love3.update(1/60)
 eq(app3.mode,'playing')
 local s3=app3.sim
 eq(calls3.emp,0)
 love3.keypressed('x')
 -- a sub-tick update cannot consume the fixed step: the EMP stays buffered
 love3.update(1/240)
 eq(calls3.emp,0,'the EMP must stay buffered across a sub-tick update')
 assert(app3.pendingEmp==true,'the press must arm the EMP buffer')
 love3.update(1/60)
 eq(calls3.emp,1,'exactly one EMP may fire from one press')
 assert(s3.player.empCooldown>0,'the EMP sets its cooldown')
 eq(app3.pendingEmp,false)
 for _=1,3 do love3.update(1/60) end
 eq(calls3.emp,1,'a single press must not fire twice')
end)

test('relaunch resets selection without changing saves',function()
 -- a shared memory save carrying a non-default preference
 local files={['dispatch.sav']='NEON1\nmusic=0.3\nsfx=0.7\nmute=false\nshake=true\neffects=true\npixelSize=1\nfullscreen=false\n'}
 local love,files,calls=makeLove{files=files}
 local app=assert(findApp())
 local Sim=require('game.sim')
 -- a District07 shift and a Waterfront shift share one highscore table
 local function runShift(district,score)
  local l,f,c=makeLove{files=files}
  local a=assert(findApp())
  eq(a.settings.music,.3,district..' must load the shared preference')
  if district=='waterfront' then
   l.keypressed('down');l.update(1/60)
   l.keypressed('right');l.update(1/60)
   eq(a.selectedDistrictId,'waterfront')
   l.keypressed('up');l.update(1/60)
  else
   eq(a.selectedDistrictId,'district07')
  end
  l.keypressed('return');l.update(1/60)
  eq(a.mode,'playing')
  local s=a.sim
  eq(s.map.id,district)
  s.cash=score;s.score=score;s.delivered=1
  Sim.finish(s,'SHIFT COMPLETE')
  -- the standard completion bonus (Math.floor(hp*2)=200 at full hull) applies
  local final=s.score
  eq(final,score+200,district..' must append the standard completion bonus')
  l.update(1/60)
  eq(a.mode,'results')
  l.quit()
  assert(c.writes>0,district..' must persist its result')
  assert(f['dispatch.sav']:match('music=0.3'),district..' must keep the non-default preference')
  assert(f['dispatch.sav']:match('score='..final..',1'),district..' must persist its final total')
  return f,final
 end
 local f1,score1=runShift('district07',111)
 local f2,score2=runShift('waterfront',222)
 eq(score1,311)
 eq(score2,422)
 local text=files['dispatch.sav']
 assert(text:match('score=311,1') and text:match('score=422,1'),
  'both districts must share one persisted highscore table')
 -- a fresh launch keeps the preference and both scores and selects District07
 local l3,f3,c3=makeLove{files=files}
 local a3=assert(findApp())
 eq(a3.selectedDistrictId,'district07','a fresh launch must default District07')
 eq(a3.settings.music,.3,'the non-default preference must survive both shifts')
 eq(#a3.highscores,2)
 eq(a3.highscores[1].score,422)
 eq(a3.highscores[2].score,311)
 -- selection-only actions never write and never change the NEON1 bytes
 local before=files['dispatch.sav']
 local wBefore=c3.writes
 l3.keypressed('down');l3.update(1/60)
 eq(a3.selection,2)
 l3.keypressed('right');l3.update(1/60)
 eq(a3.selectedDistrictId,'waterfront')
 l3.keypressed('left');l3.update(1/60)
 eq(a3.selectedDistrictId,'district07')
 eq(c3.writes,wBefore,'selection-only actions must not write')
 eq(files['dispatch.sav'],before,'selection-only actions must not change the stored bytes')
 eq(Save.encode(a3),before,'selection must not add a save field')
 assert(not Save.encode(a3):match('district'),'no district field may enter the save')
 -- seeded default/legacy/corrupt saves recover and keep the invariants
 local seeds={
  {'default','NEON1\nmusic=0.6\nsfx=0.7\nmute=false\nshake=true\neffects=true\npixelSize=1\nfullscreen=false\n'},
  {'legacy','NEON1\nmusic=0.3\nsfx=0.2\nmute=false\nshake=true\neffects=true\n'},
  {'corrupt','not-a-save-at-all'},
 }
 for _,seed in ipairs(seeds) do
  local f={['dispatch.sav']=seed[2]}
  local l,_,c=makeLove{files=f}
  local a=assert(findApp())
  eq(a.selectedDistrictId,'district07',seed[1]..' must default District07')
  eq(a.settings.music,seed[1]=='legacy' and .3 or .6,seed[1]..' settings must recover')
  if seed[1]=='corrupt' then eq(f['dispatch.sav'],seed[2],'a corrupt save is never rewritten by load') end
  local pre=f['dispatch.sav']
  local canonical=Save.encode(a)
  local w=c.writes
  l.keypressed('down');l.update(1/60)
  l.keypressed('right');l.update(1/60)
  eq(a.selectedDistrictId,'waterfront',seed[1]..' must allow a selection toggle')
  eq(Save.encode(a),canonical,seed[1]..' selection must not change the canonical encoding')
  eq(f['dispatch.sav'],pre,seed[1]..' selection must not change stored bytes')
  eq(c.writes,w,seed[1]..' selection must not write')
  assert(not Save.encode(a):match('district'),seed[1]..' must not gain a district field')
  if seed[1]=='default' then eq(Save.encode(a),pre,seed[1]..' must stay byte-identical') end
  l.quit()
  assert(f['dispatch.sav']:match('music='),seed[1]..' must still persist a valid save')
  assert(not f['dispatch.sav']:match('district'),seed[1]..' must not persist a district field')
 end
 -- default/legacy/corrupt decode paths with no filesystem at all
 local s1=Save.decode('NEON1\nmusic=0.3\nsfx=0.2\nmute=false\nshake=true\neffects=true\n')
 eq(s1.settings.music,.3);eq(s1.settings.pixelSize,1);eq(s1.settings.fullscreen,false)
 local s2=Save.decode('garbage-not-a-save')
 eq(s2.settings.music,.6);eq(#s2.highscores,0)
 local s3=Save.decode(nil)
 eq(s3.settings.music,.6)
end)

test('unknown selection is rejected',function()
 -- a direct unknown selection cannot Start from the title
 local love,files,calls=makeLove()
 local app=assert(findApp())
 app.selectedDistrictId='nowhere-district'
 eq(app.selection,1)
 local before=Save.encode(app)
 local wBefore=calls.writes
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'title','an unknown selection must not start a shift')
 eq(app.sim,nil)
 eq(Save.encode(app),before)
 eq(calls.writes,wBefore,'a rejected Start must not write saves')
 -- a retained shift is not replaced or corrupted either
 local love2,files2,calls2=makeLove()
 local app2=assert(findApp())
 love2.keypressed('return');love2.update(1/60)
 local s2=app2.sim
 eq(s2.map.id,'district07')
 love2.keypressed('escape');love2.update(1/60)
 eq(app2.mode,'paused')
 app2.selectedDistrictId='nowhere-district'
 -- resume through the real handler first: a paused shift cannot be finished
 love2.keypressed('return');love2.update(1/60)
 eq(app2.mode,'playing','resume must use the real handler')
 require('game.sim').finish(s2,'SHIFT ENDED')
 love2.update(1/60)
 eq(app2.mode,'results')
 love2.keypressed('down');love2.update(1/60)
 love2.keypressed('return');love2.update(1/60)
 eq(app2.mode,'title')
 local bytes2=Save.encode(app2)
 local w2=calls2.writes
 love2.keypressed('return');love2.update(1/60)
 eq(app2.mode,'title','the unknown selection must still be rejected on title')
 eq(app2.sim,s2,'the retained simulation must be untouched')
 eq(Save.encode(app2),bytes2)
 eq(calls2.writes,w2,'the rejected title Start must not write saves')
end)

print('ALL '..count..' DISTRICT FLOW TESTS PASSED')
