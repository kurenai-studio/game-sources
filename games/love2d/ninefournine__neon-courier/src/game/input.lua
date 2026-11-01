local I={pressed={},pad=nil,deadzone=.23,menuClock=0}
local keys={up='up',w='up',down='down',s='down',left='left',a='left',right='right',d='right',
 ['return']='confirm',space='boost',x='emp',lshift='boost',escape='back',p='pause',m='mute',f11='fullscreen'}
local buttons={a='confirm',b='padBack',x='emp',leftshoulder='emp',rightshoulder='boost',start='pause',back='back',
 dpup='up',dpdown='down',dpleft='left',dpright='right'}
function I.keypressed(k) if keys[k] then I.pressed[keys[k]]=true end end
function I.gamepadpressed(j,b) I.pad=j;if buttons[b] then I.pressed[buttons[b]]=true end end
function I.take(a) local v=I.pressed[a];I.pressed[a]=nil;return v end
function I.clear() I.pressed={} end
function I.connected()
 if I.pad and not I.pad:isConnected() then I.pad=nil;I.clear();return false end
 if not I.pad then for _,j in ipairs(love.joystick.getJoysticks()) do if j:isGamepad() then I.pad=j;break end end end
 return I.pad~=nil
end
function I.vector()
 local x,y=0,0
 if love.keyboard.isDown('a','left') then x=x-1 end;if love.keyboard.isDown('d','right') then x=x+1 end
 if love.keyboard.isDown('w','up') then y=y-1 end;if love.keyboard.isDown('s','down') then y=y+1 end
 if I.connected() then
  local px,py=I.pad:getGamepadAxis('leftx'),I.pad:getGamepadAxis('lefty')
  local mag=math.sqrt(px*px+py*py)
  if mag>I.deadzone then local m=math.min(1,(mag-I.deadzone)/(1-I.deadzone));x,y=px/mag*m,py/mag*m end
  if I.pad:isGamepadDown('dpleft') then x=-1 end;if I.pad:isGamepadDown('dpright') then x=1 end
  if I.pad:isGamepadDown('dpup') then y=-1 end;if I.pad:isGamepadDown('dpdown') then y=1 end
 end
 return x,y
end
function I.play()
 local x,y=I.vector()
 return {x=x,y=y,boost=love.keyboard.isDown('space','lshift') or (I.pad and I.pad:isGamepadDown('a','rightshoulder')),
 emp=I.take('emp') or I.take('padBack')}
end
function I.menu(dt)
 local x,y=I.vector();I.menuClock=math.max(0,I.menuClock-dt)
 if I.pad and I.menuClock==0 then
  if math.abs(y)>.55 then I.pressed[y<0 and 'up' or 'down']=true;I.menuClock=.23
  elseif math.abs(x)>.55 then I.pressed[x<0 and 'left' or 'right']=true;I.menuClock=.23 end
 end
end
return I
