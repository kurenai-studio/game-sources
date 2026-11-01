local Sim=require('game.sim')
local Input=require('game.input')
local Save=require('game.save')
local Render=require('game.render')
local Audio=require('game.audio')
local Window=require('game.window')
local Map=require('game.map')
local app={mode='title',selection=1,clock=0,accumulator=0,selectedDistrictId='district07'}
local test
local function trace()
 if app.test then
  local s=app.sim
  print(string.format('NEON_STATE mode=%s x=%.2f y=%.2f time=%.2f cargo=%s music=%.2f score=%d best=%d emp=%.2f boost=%.2f',
   app.mode,s and s.player.x or 0,s and s.player.y or 0,s and s.time or 0,
   s and s.cargo and s.cargo.kind or 'none',app.settings.music,s and s.score or 0,
   app.highscores[1] and app.highscores[1].score or 0,s and s.player.empCooldown or 0,s and s.player.boost or 100))
 end
end
local function mode(m)
 app.mode=m;app.selection=1;Input.clear();app.accumulator=0;app.pendingEmp=false;trace()
end
local function start(mapOverride)
 local selected=mapOverride
 if not selected then
  selected=Map.get(app.selectedDistrictId or 'district07')
  if not selected then return false end
 end
 app.sim=Sim.new(app.fixedSeed or math.floor(love.timer.getTime()*1000)%2147483646+1,selected)
 app.recorded=false;mode('playing');Audio.unlock();Audio.play('ui')
 return true
end
local function store()
 if not app.test or app.webTest then Save.store(app) end
end
local function result()
 if not app.recorded then
  Save.record(app,app.sim);app.recorded=true;store()
 end
 mode('results')
end
local settingsRows={'music','sfx','mute','shake','effects','pixelSize','fullscreen','back'}
local function nativeFullscreen()
 local ok,engaged=pcall(love.window.getFullscreen)
 if ok and type(engaged)=='boolean' then return engaged end
 return app.settings.fullscreen
end
local function wantFullscreen(enable)
 local previous=nativeFullscreen()
 app.settings.fullscreen=enable
 local ok,result=pcall(love.window.setFullscreen,enable,'desktop')
 if not ok or result~=true then
  app.settings.fullscreen=previous
  return false
 end
 app.fsCheck={deadline=app.clock+2,enable=enable,previous=previous}
 return true
end
local function checkFullscreen()
 local c=app.fsCheck
 if not c or app.clock<c.deadline then return end
 app.fsCheck=nil
 if nativeFullscreen()==c.enable then
  if not c.enable and app.sizeRecheck then
   app.sizeRecheck=nil
   if not Window.apply(app.settings) then
    app.settings.pixelSize=1
    Window.apply(app.settings)
    store()
   end
  end
  return
 end
 app.settings.fullscreen=c.previous
 pcall(love.window.setFullscreen,c.previous,'desktop')
 store()
end
local function setting(direction)
 local k=settingsRows[app.selection]
 if k=='back' then store();mode(app.settingsReturn or 'title');return end
 if k=='music' or k=='sfx' then app.settings[k]=math.max(0,math.min(1,app.settings[k]+direction*.1))
 elseif k=='pixelSize' then
  local previous=app.settings.pixelSize
  app.settings.pixelSize=Window.step(previous,direction)
  if not Window.apply(app.settings) then
   app.settings.pixelSize=previous
   Window.apply(app.settings)
  elseif nativeFullscreen() then app.sizeRecheck=true end
 elseif k=='fullscreen' then wantFullscreen(not app.settings.fullscreen)
 else app.settings[k]=not app.settings[k] end
 store();Audio.play('ui');trace()
end
local function menus(dt)
 Input.menu(dt)
 local counts={title=4,paused=3,settings=8,upgrade=#(app.sim and app.sim.offers or {}),results=2}
 local count=counts[app.mode] or 1
 if Input.take('up') or (app.mode=='upgrade' and Input.take('left')) then app.selection=(app.selection-2)%count+1;Audio.play('ui') end
 if Input.take('down') or (app.mode=='upgrade' and Input.take('right')) then app.selection=app.selection%count+1;Audio.play('ui') end
 -- on the title, left/right are consumed every update and applied only on the
 -- district row, so a stale edge pressed on another row cannot fire later
 if app.mode=='title' then
  local left,right=Input.take('left'),Input.take('right')
  if app.selection==2 then
   local confirm=Input.take('confirm')
   if left or right or confirm then
    local list=Map.list()
    local idx=1
    for i,m in ipairs(list) do if m.id==app.selectedDistrictId then idx=i end end
    local dir=0
    if left then dir=-1 elseif right or confirm then dir=1 end
    app.selectedDistrictId=list[(idx+dir-1)%#list+1].id
    Audio.play('ui');trace()
   end
  end
 end
 if app.mode=='settings' then
  if Input.take('left') then setting(-1) end;if Input.take('right') then setting(1) end
 end
 if Input.take('back') or Input.take('padBack') or Input.take('pause') then
  if app.mode=='paused' then mode('playing')
  elseif app.mode=='settings' then store();mode(app.settingsReturn or 'title')
  elseif app.mode=='results' then mode('title') end
 end
 if not Input.take('confirm') then return end
 Audio.unlock()
 if app.mode=='title' then
  if app.selection==1 then start()
  elseif app.selection==3 then app.settingsReturn='title';mode('settings')
  else love.event.quit() end
 elseif app.mode=='paused' then
  if app.selection==1 then mode('playing')
  elseif app.selection==2 then app.settingsReturn='paused';mode('settings')
  else Sim.finish(app.sim,'SHIFT ENDED');result() end
 elseif app.mode=='settings' then setting(1)
 elseif app.mode=='upgrade' then
  local o=app.sim.offers[app.selection];if o and Sim.applyUpgrade(app.sim,o.id) then mode('playing') end
 elseif app.mode=='results' then if app.selection==1 then start(app.sim.map) else mode('title') end end
end
function love.load(args)
 local flags={};for _,a in ipairs(args or {}) do flags[a]=true end
 app.webTest=flags['--web-test'];app.test=app.webTest or flags['--smoke'] or flags['--soak']
 -- test-only district selection: only beside an automated-test flag, so an
 -- ordinary --waterfront alone selects nothing and saves nothing
 app.waterfrontTest=flags['--waterfront'] and app.test or false
 if app.test then love.filesystem.setIdentity('neon-courier-test-v1');app.fixedSeed=72891 end
 if app.waterfrontTest then love.filesystem.setIdentity('neon-courier-test-waterfront-v1') end
 local saved=Save.load();app.settings=saved.settings;app.highscores=saved.highscores
 if app.test and not app.webTest then local d=Save.defaults();app.settings=d.settings;app.highscores={} end
 if app.waterfrontTest then app.selectedDistrictId='waterfront' end
 if not app.test then
  if not Window.apply(app.settings) then app.settings.pixelSize=1;Window.apply(app.settings) end
  if app.settings.fullscreen then wantFullscreen(true) end
 end
 love.graphics.setDefaultFilter('nearest','nearest')
 app.canvas=love.graphics.newCanvas(640,480);app.canvas:setFilter('nearest','nearest')
 Render.load();Audio.load(app.settings)
 if flags['--smoke'] or flags['--soak'] then test=require('game.smoke').new(app,flags,start,mode,result) end
 local name,version,vendor,device=love.graphics.getRendererInfo()
 print('NEON_RENDER '..name..' '..version..' '..vendor..' '..device)
 if app.test then
  print(string.format('NEON_TEST district=%s identity=%s save_dir=%s',
   app.selectedDistrictId,tostring(love.filesystem.getIdentity()),tostring(love.filesystem.getSaveDirectory())))
 end
 trace()
end
function love.keypressed(k)
 Audio.unlock();Input.keypressed(k)
 if app.webTest and k=='f9' then
  if not app.sim then start() end
  app.scenario=(app.scenario or 0)%4+1
  local s=app.sim;s.cars={};s.player.x,s.player.y=480,432;s.pickupCooldown=0;s.cargo=nil
  if app.scenario<=3 then
   local kinds={'medical','prototype','battery'}
   s.jobs={{location=8,kind=kinds[app.scenario]}};Sim.pickup(s,1);mode('playing')
  else Sim.offer(s);mode('upgrade') end
  trace()
 elseif app.webTest and k=='f10' then Sim.finish(app.sim,'SHIFT COMPLETE');result() end
 if app.webTest and k=='f8' then trace() end
end
function love.gamepadpressed(j,b) Audio.unlock();Input.gamepadpressed(j,b) end
function love.resize() if Render.rebuild then Render.rebuild() end end
function love.joystickremoved(j)
 if Input.pad==j then Input.pad=nil;Input.clear();if app.mode=='playing' then mode('paused');app.sim.notice='CONTROLLER DISCONNECTED';app.sim.noticeTime=5 end end
end
function love.focus(focused) if not focused and app.mode=='playing' and not app.test then mode('paused') end end
function love.update(dt)
 dt=math.min(dt,.25);app.clock=app.clock+dt
 checkFullscreen()
 if test then test:update(dt) end
 if Input.take('mute') then app.settings.mute=not app.settings.mute;store() end
 if Input.take('fullscreen') then if wantFullscreen(not app.settings.fullscreen) then store() end end
 if app.mode=='playing' then
  if Input.take('pause') or Input.take('back') then mode('paused')
  else
   local input=test and test:input() or Input.play()
   app.pendingEmp=app.pendingEmp or input.emp
   input.emp=app.pendingEmp
   app.accumulator=math.min(app.accumulator+dt,1/12)
   while app.accumulator>=1/60 and app.mode=='playing' do
    Sim.update(app.sim,1/60,input);input.emp=false;app.pendingEmp=false;app.accumulator=app.accumulator-1/60
    if app.sim.over then result() elseif app.sim.awaitingUpgrade then mode('upgrade') end
   end
  end
 else menus(dt) end
 if app.sim then
  app.sim.visualEvents=app.sim.visualEvents or {}
  for _,e in ipairs(app.sim.events) do
   Audio.play(e.name)
   if e.name=='explosion' or e.name=='emp' or e.name=='impact' or e.name=='delivery' then
    local fx=app.sim.visualEvents
    if #fx<32 then fx[#fx+1]={kind=e.name,x=e.x,y=e.y,life=e.name=='emp' and .6 or .7,radius=e.name=='emp' and 105+25*(app.sim.upgrades.emp or 0) or 45} end
   end
  end
  app.sim.events={}
  for i=#app.sim.visualEvents,1,-1 do
   local fx=app.sim.visualEvents[i];fx.life=fx.life-dt;if fx.life<=0 then table.remove(app.sim.visualEvents,i) end
  end
 end
 Audio.update(dt,app.sim,app.settings,app.mode)
end
function love.draw()
 love.graphics.setCanvas(app.canvas);love.graphics.clear(.025,.032,.065,1)
 Render.draw(app);love.graphics.setCanvas();love.graphics.setColor(1,1,1,1)
 local w,h=love.graphics.getDimensions();local scale=math.min(w/640,h/480)
 if scale>=1 then scale=math.floor(scale) end
 local x,y=math.floor((w-640*scale)/2),math.floor((h-480*scale)/2)
 love.graphics.clear(.009,.014,.026,1);love.graphics.draw(app.canvas,x,y,0,scale,scale)
 if test then test:drawn() end
end
function love.quit() store();Audio.stop() end
local defaultErrorHandler=love.errorhandler
function love.errorhandler(message)
 if not app.test then return defaultErrorHandler(message) end
 print('NEON_TEST_ERROR '..tostring(message))
 return function() return 1 end
end
