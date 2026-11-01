-- Replaces only the smoke driver in a temporary archive. Main/sim/input/render
-- and assets remain byte-identical to the packaged game. No physical pad claim.
local Sim=require('game.sim')
local F={}
function F.new(app,flags,start,mode,result)
 local self={app=app,start=start,mode=mode,result=result,time=0,phase=-1}
 self.pad={}
 function self.pad:isConnected()return true end
 function self.pad:isGamepad()return true end
 function self.pad:getGamepadAxis()return 0 end
 function self.pad:isGamepadDown()return false end
 start();Sim.offer(app.sim)
 return setmetatable(self,{__index=F})
end
function F:input()return require('game.input').play() end
function F:drawn()end
function F:update(dt)
 self.time=self.time+dt;local phase=math.floor(self.time/.2)
 if phase==self.phase then return end;self.phase=phase
 local app,s=self.app,self.app.sim
 if phase==1 then assert(app.mode=='upgrade');self.first=s.offers[2].id;love.gamepadpressed(self.pad,'dpright')
 elseif phase==2 then assert(app.selection==2);love.gamepadpressed(self.pad,'a')
 elseif phase==3 then assert(app.mode=='playing');assert(s.upgrades[self.first]==1);Sim.offer(s)
 elseif phase==4 then assert(app.mode=='upgrade');self.second=s.offers[3].id;self.level=s.upgrades[self.second] or 0;love.gamepadpressed(self.pad,'dpleft')
 elseif phase==5 then assert(app.selection==3);love.gamepadpressed(self.pad,'a')
 elseif phase==6 then assert(app.mode=='playing');assert(s.upgrades[self.second]==self.level+1);Sim.finish(s,'SHIFT COMPLETE');self.result()
 elseif phase==7 then assert(app.mode=='results');love.gamepadpressed(self.pad,'a')
 elseif phase==8 then assert(app.mode=='playing');assert(next(s.upgrades)==nil and s.score==0);self.mode('title')
 elseif phase==9 then love.gamepadpressed(self.pad,'dpdown')
 elseif phase==10 then assert(app.selection==2,'district row');love.gamepadpressed(self.pad,'dpdown')
 elseif phase==11 then assert(app.selection==3,'settings row');love.gamepadpressed(self.pad,'dpdown')
 elseif phase==12 then assert(app.selection==4,'quit row');print('PASS ACTUAL MAIN CONTROLLER: two upgrade choices, numerical effects, results, clean restart, title selection, quit');love.gamepadpressed(self.pad,'a') end
 if self.time>5 then error('Controller fixture timeout') end
end
return F
