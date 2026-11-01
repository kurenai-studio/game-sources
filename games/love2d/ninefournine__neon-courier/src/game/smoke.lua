-- Deterministic fixtures exercise the actual main/render/audio path.
-- Test saves use a separate identity; a bot run is never a human playtest.
local Sim=require('game.sim')
local Map=require('game.map')
local Smoke={}
function Smoke.new(app,flags,start,mode,result)
 local self={app=app,flags=flags,start=start,mode=mode,result=result,elapsed=0,phase=0,
  captured={},frames=0,timings={},scenario=0,soak=flags['--soak'],begin=love.timer.getTime(),restarts=0}
 start();app.settings.mute=false
 return setmetatable(self,{__index=Smoke})
end
function Smoke:input()
 if self.controlling then return require('game.input').play() end
 if self.withdrawalUntil and self.elapsed<self.withdrawalUntil then return {} end
 if not self.soak then return {x=math.sin(self.elapsed*.6),y=-.8,boost=self.phase==1,emp=self.phase==3} end
 local s=self.app.sim
 -- routes belong to the tested shift's own map, reset when the sim changes
 if self.routeSim~=s then self.route=nil;self.routeSim=s end
 local target
 if s.cargo then target=s.map.locations[s.cargo.destination]
 else local i=Sim.nearestJob(s);target=i and s.map.locations[s.jobs[i].location] end
 if not target then return {} end
 if not self.route or s.cargo~=self.routeCargo or self.routeTarget~=target then
  self.route=s.map.route(s.player.x,s.player.y,target.x,target.y);self.routeIndex=2;self.routeCargo=s.cargo;self.routeTarget=target
 end
 local n=self.route[self.routeIndex] or target
 if ((n.x-s.player.x)^2+(n.y-s.player.y)^2)<18^2 and self.routeIndex<#self.route then self.routeIndex=self.routeIndex+1;n=self.route[self.routeIndex] end
 local dx,dy=n.x-s.player.x,n.y-s.player.y;local len=math.sqrt(dx*dx+dy*dy)
 return {x=len>1 and dx/len or 0,y=len>1 and dy/len or 0,boost=false,emp=s.player.empCooldown==0}
end
function Smoke:update(dt)
 self.elapsed=self.elapsed+dt;self.frames=self.frames+1;self.timings[#self.timings+1]=dt
 local app,s=self.app,self.app.sim
 if self.soak then
  -- Long-run fixture raises hull only, preserving movement/AI/cargo/timers.
  s.player.hp=math.max(s.player.hp,1000);s.player.maxHp=1000
  if app.mode=='upgrade' then Sim.applyUpgrade(s,s.offers[1].id);self.mode('playing') end
  if s.over then self:report('soak');love.event.quit() end
  if self.elapsed>330 then error('Soak exceeded bounded timeout') end
  return
 end
 if self.withdrawalAt and self.elapsed>=self.withdrawalAt then
  self.withdrawalAt=nil
  assert(s.cargo and s.cargo.kind=='prototype','withdrawal fixture carries prototype')
  -- The tested shift's first shortcut entrance: legal road attachments and the
  -- shortcut's own node ids, never off-road positions.
  local m=s.map
  local sc=m.shortcuts[1]
  local top=m.nodes[sc.nodeIds[1]]
  local att=sc.attachments[1]
  s.time=85;s.player.x,s.player.y=top.x,top.y+31;s.player.vx,s.player.vy=0,0
  s.player.angle=-math.pi/2;s.heat=3;s.spawnClock=0;s.visualEvents={};s.cars={}
  for i,dx in ipairs({-80,-56,56,80}) do
   local x=top.x+dx
   s.cars[i]={id=i,x=x,y=top.y,angle=x<top.x and 0 or math.pi,kind='police',
    node=x<top.x and att[1] or att[2],target=sc.nodeIds[1],stun=0,speed=70}
  end
  s.nextId=5
  assert(Sim.deliver(s),'prototype fixture delivery')
  local active,returning=0,0
  for _,c in ipairs(s.cars) do if c.withdrawing then returning=returning+1 else active=active+1 end end
  assert(active==2 and returning==2,'prototype delivery visibly withdraws surplus cops')
  self.oldEffects=app.settings.effects;app.settings.effects=false
  self.deferredCapture='withdrawal';self.captureAt=self.elapsed+.25
  self.withdrawalUntil=self.elapsed+.65
 end
 if self.withdrawalUntil and self.elapsed>=self.withdrawalUntil then
  app.settings.effects=self.oldEffects;self.withdrawalUntil=nil
 end
 local phase=math.floor(self.elapsed/1.4)
 if phase==self.phase and self.initialized then return end
 self.phase=phase;self.initialized=true
 if phase==0 then self.mode('title');self.capture='title'
 elseif phase==1 then self.start();self.capture='onboarding'
 elseif phase>=2 and phase<=4 then
  local kinds={'medical','prototype','battery'}
  s.player.x,s.player.y=s.map.locations[1].x,s.map.locations[1].y;s.cargo=nil;s.pickupCooldown=0
  s.jobs={{location=1,kind=kinds[phase-1]}};Sim.pickup(s,1);self.capture=kinds[phase-1]
  if phase==3 then self.withdrawalAt=self.elapsed+.3 end
  if phase==4 then
   local destination=s.map.locations[s.cargo.destination]
   s.player.x,s.player.y=destination.x-65,destination.y;s.player.vx,s.player.vy=0,0;s.player.angle=0
  end
 elseif phase==5 then Sim.deliver(s);Sim.offer(s);self.mode('upgrade');self.capture='upgrade'
 elseif phase==6 then Sim.applyUpgrade(s,s.offers[1].id);self.mode('playing');self.mode('paused');self.capture='paused'
 elseif phase==7 then self.mode('settings');self.capture='settings'
 elseif phase==8 then
  self.mode('playing');s.cargo=nil;s.jobs={{location=1,kind='battery'}};s.pickupCooldown=0;Sim.pickup(s,1);s.cargo.remaining=.01;self.deferredCapture='explosion';self.captureAt=self.elapsed+.07
 elseif phase==9 then Sim.finish(s,'VEHICLE WRECKED');self.result();self.capture='results'
 elseif phase==10 then
  for _=1,100 do self.start();self.restarts=self.restarts+1;assert(app.sim.time==0 and app.sim.score==0 and not app.sim.cargo and #app.sim.cars==6) end
  self.capture='restart'
 elseif phase==11 then love.window.setMode(1280,720,{resizable=true});self.capture='wide'
 elseif phase==12 then love.window.setMode(960,720,{resizable=true});self.capture='large4x3'
 elseif phase==13 then love.window.setMode(1560,720,{resizable=true});self.capture='phonewide'
 elseif phase==14 then
  self.controlling=true;self.mode('title')
  self.pad={held={},axes={leftx=0,lefty=0}}
  function self.pad:isConnected() return true end
  function self.pad:isGamepad() return true end
  function self.pad:getGamepadAxis(k) return self.axes[k] or 0 end
  function self.pad:isGamepadDown(...) for _,k in ipairs({...}) do if self.held[k] then return true end end;return false end
  love.gamepadpressed(self.pad,'a')
 elseif phase==15 then assert(app.mode=='playing','controller start');love.gamepadpressed(self.pad,'b')
 elseif phase==16 then assert(s.player.empCooldown>0,'controller EMP');love.gamepadpressed(self.pad,'start')
 elseif phase==17 then assert(app.mode=='paused','controller pause');love.gamepadpressed(self.pad,'dpdown');love.gamepadpressed(self.pad,'a')
 elseif phase==18 then assert(app.mode=='settings','controller settings');self.oldMusic=app.settings.music;love.gamepadpressed(self.pad,'dpright')
 elseif phase==19 then assert(app.settings.music>self.oldMusic,'controller volume');love.gamepadpressed(self.pad,'b')
 elseif phase==20 then assert(app.mode=='paused','controller settings back');love.gamepadpressed(self.pad,'start')
 elseif phase==21 then assert(app.mode=='playing','controller resume');love.joystickremoved(self.pad)
 elseif phase==22 then assert(app.mode=='paused','controller disconnect pauses');love.gamepadpressed(self.pad,'start')
 elseif phase==23 then
  assert(app.mode=='playing','controller reconnect resume');self.controllerX=s.player.x;self.pad.axes.leftx=1;self.pad.held.a=true
 elseif phase==24 then
  assert(s.player.x>self.controllerX+30,'controller steering/boost');assert(s.player.boost<100,'controller boost depletion')
  self.pad.axes.leftx=0;self.pad.held.a=false;Sim.finish(s,'SHIFT COMPLETE');self.result();self.capture='controller-results'
 elseif phase==25 then assert(app.mode=='results','controller results');love.gamepadpressed(self.pad,'a')
 elseif phase==26 then assert(app.mode=='playing' and s.score==0 and s.time<2,'controller restart');self.mode('title')
 elseif phase==27 then love.gamepadpressed(self.pad,'dpdown')
 elseif phase==28 then assert(app.selection==2,'controller district row');love.gamepadpressed(self.pad,'dpdown')
 elseif phase==29 then assert(app.selection==3,'controller settings row');love.gamepadpressed(self.pad,'dpdown')
 elseif phase==30 then assert(app.selection==4,'controller quit selection');self.controllerPassed=true;self:report('smoke');love.gamepadpressed(self.pad,'a') end
end
function Smoke:drawn()
 if self.deferredCapture and self.elapsed>=self.captureAt then self.capture=self.deferredCapture;self.deferredCapture=nil end
 if not self.capture then return end
 local name=self.capture;self.capture=nil
 love.graphics.captureScreenshot(function(image)
  image:encode('png','capture-'..name..'.png');self.captured[#self.captured+1]=name
 end)
end
function Smoke:report(kind)
 local mem=collectgarbage('count');local t=love.timer.getTime()-self.begin
 local s=self.app.sim
 local sum,maxDt=0,0;for _,v in ipairs(self.timings) do sum=sum+v;maxDt=math.max(maxDt,v) end
  local district=(self.app.sim and self.app.sim.map.id) or self.app.selectedDistrictId or 'district07'
  local saveDir=tostring(love.filesystem.getSaveDirectory())
 local report=string.format('kind=%s\ndistrict=%s\nsave_dir=%s\nseed=72891\nwall_seconds=%.3f\nsimulation_seconds=%.3f\nframes=%d\nlua_kib=%.1f\nrestarts=%d\ndeliveries=%d\nfailures=%d\nscore=%d\nmean_update_ms=%.3f\nmax_update_ms=%.3f\ncontroller_mock=%s\n',kind,district,saveDir,t,s.time,self.frames,mem,self.restarts,s.delivered,s.failed,s.score,sum/self.frames*1000,maxDt*1000,tostring(self.controllerPassed or false))
 love.filesystem.write(kind..'-report.txt',report);print('NEON_TEST '..report:gsub('\n',' '))
end
return Smoke
