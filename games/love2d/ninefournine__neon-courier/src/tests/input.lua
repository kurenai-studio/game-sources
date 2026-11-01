local held={};local pads={}
love={keyboard={isDown=function(...)for _,k in ipairs({...}) do if held[k] then return true end end;return false end},joystick={getJoysticks=function()return pads end}}
local I=require('game.input')
local n=0
local function check(name,fn) fn();n=n+1;print('PASS '..name) end
check('keyboard direct vector and boost',function()held.w=true;held.d=true;held.space=true;local v=I.play();assert(v.x==1 and v.y==-1 and v.boost);held={} end)
check('EMP press consumed once',function()I.keypressed('x');assert(I.play().emp);assert(not I.play().emp) end)
local pad={connected=true,x=0,y=0,held={}}
function pad:isConnected()return self.connected end
function pad:isGamepad()return true end
function pad:getGamepadAxis(k)return k=='leftx' and self.x or self.y end
function pad:isGamepadDown(...)for _,k in ipairs({...}) do if self.held[k] then return true end end;return false end
pads={pad}
check('controller deadzone eliminates drift',function()pad.x=.22;pad.y=0;local x,y=I.vector();assert(x==0 and y==0) end)
check('controller radial deadzone preserves usable diagonal',function()pad.x=.6;pad.y=.6;local x,y=I.vector();assert(x>.5 and y>.5 and x<1) end)
check('controller D-pad and boost',function()pad.x=0;pad.y=0;pad.held.dpleft=true;pad.held.a=true;local v=I.play();assert(v.x==-1 and v.boost);pad.held={} end)
check('controller B is EMP during driving without keyboard-back alias',function()I.gamepadpressed(pad,'b');assert(I.play().emp);assert(not I.take('back')) end)
check('keyboard Esc remains back with controller connected',function()I.keypressed('escape');assert(I.take('back'));assert(not I.play().emp) end)
check('controller start pauses and A confirms',function()I.gamepadpressed(pad,'start');assert(I.take('pause'));I.gamepadpressed(pad,'a');assert(I.take('confirm')) end)
check('analog menu repeat is bounded',function()pad.y=1;I.menu(1);assert(I.take('down'));I.menu(.01);assert(not I.take('down'));I.menu(.25);assert(I.take('down'));pad.y=0 end)
check('disconnect clears pending actions',function()I.gamepadpressed(pad,'a');pad.connected=false;pads={};assert(not I.connected());assert(not I.take('confirm'));assert(not I.pad) end)
print('ALL '..n..' INPUT TESTS PASSED')
