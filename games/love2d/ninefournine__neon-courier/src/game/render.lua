-- The complete presentation uses a 640x480 canvas and a 2x pixel-art world.
local art = require('game.art')
local map = require('game.map')
local render = {}
local g, p = love.graphics, art.palette
local fonts, city, current
local windowWidth,windowHeight
local cargoNames={prototype='STOLEN PROTOTYPE',medical='MEDICAL SUPPLIES',battery='UNSTABLE BATTERY'}
local cargoHints={prototype='HIGH PAY / POLICE HEAT',medical='BONUS PAY / 3 IMPACTS',battery='HIGH PAY / TIMED RUN'}
local cargoColors={prototype=p.magenta,medical=p.green,battery=p.amber}
local camera={x=0,y=0}
local landmarkBuildings={}
local landmarkSigns={noodle='LUCKY CAT',garage='AFTERHOURS',mart='NIGHT MART',dock='PIER 09',clinic='CLINIC',club='VELVET',substation='POWER 03',dispatch='DISPATCH'}

local function color(c,alpha)
  g.setColor(c[1],c[2],c[3],alpha or c[4] or 1)
end
local function rect(c,x,y,w,h,alpha)
  color(c,alpha)
  g.rectangle('fill',math.floor(x),math.floor(y),math.floor(w),math.floor(h))
end
local function label(text,x,y,size,c)
  color(c or p.white)
  g.setFont(fonts[size or 12])
  g.print(tostring(text),math.floor(x),math.floor(y))
end
local function centered(text,y,size,c)
  color(c or p.white)
  g.setFont(fonts[size or 12])
  g.printf(tostring(text),0,y,640,'center')
end
local function wrapped(text,x,y,width,size,c,align)
  color(c or p.white)
  g.setFont(fonts[size or 12])
  g.printf(tostring(text),x,y,width,align or 'left')
end
local function panel(x,y,w,h,accent,selected)
  rect(p.ink,x+3,y+4,w,h,.7)
  rect(selected and {.055,.17,.20} or p.dark,x,y,w,h,.98)
  color(accent or p.muted,selected and 1 or .42)
  g.rectangle('line',x+.5,y+.5,w-1,h-1)
  rect(accent or p.cyan,x,y,3,h)
end
local function hash(a,b)
  return ((a*131+b*97+31)%997)/997
end

local function tree(x,y,seed)
  rect({.025,.065,.08},x+2,y+6,14,12)
  rect({.08,.19,.18},x-2,y,16,13)
  rect({.12,.29,.24},x,y-3,11,13)
  rect({.17,.37,.29},x+2,y-3,5,3)
  rect({.09,.12,.13},x+5,y+12,3,4)
end

local function building(b,i)
  local x,y,w,h=b.x,b.y,b.w,b.h
  local landmark=landmarkBuildings[i]
  local accent=landmark and landmark.color or ({p.cyan,p.amber,p.magenta,p.blue,p.green})[(i-1)%5+1]
  local shade=hash(i,3)*.035
  rect({.015,.029,.047},x+5,y+8,w,h,.8)
  rect({.10+shade,.12+shade,.17+shade},x,y,w,h)
  rect({.19+shade,.23+shade,.28+shade},x,y,w,3)
  rect({.07,.10,.145},x,y+h-8,w,8)
  rect({.24,.29,.34},x,y,3,h-8)
  rect({.14,.18,.235},x+6,y+6,w-12,h-19)
  -- Terracotta/waterproof roof segments, seams, and rain-slick highlights.
  for yy=y+11,y+h-19,11 do
    rect({.12,.155,.205},x+7,yy,w-14,1)
    if hash(i,yy)>.4 then rect({.20,.24,.28},x+10,yy+2,w*.32,1) end
  end
  for xx=x+8,x+w-10,12 do
    rect({.03,.06,.10},xx,y+h-7,8,5)
    if hash(i,xx)>.25 then
      rect(accent,xx+1,y+h-6,6,2,.65)
      rect(p.white,xx+2,y+h-6,2,1,.4)
    end
  end
  -- Vent units, ducts and narrow rooftop access stairwell.
  if w>36 and h>40 then
    local vx=x+9+(i%3)*7
    local vy=y+10+(i%2)*8
    rect({.06,.085,.12},vx+2,vy+2,18,14)
    rect({.25,.31,.37},vx,vy,18,13)
    for n=1,4 do rect({.095,.13,.18},vx+3,vy+n*2,12,1) end
    rect({.32,.37,.42},vx,vy,18,1)
    if w>70 then
      rect({.075,.11,.15},x+w-29,y+12,18,27)
      rect({.21,.27,.32},x+w-30,y+11,18,26)
      for n=1,6 do rect({.11,.15,.20},x+w-28,y+12+n*3,14,1) end
      rect({.34,.39,.40},x+w-34,y+34,27,2)
    end
  end
  if w>65 then
    rect({.23,.27,.29},x+12,y+h-22,w-24,2)
    rect({.06,.09,.12},x+12,y+h-20,w-24,1)
    local awningColor=({{.15,.35,.36},{.50,.31,.24},{.36,.20,.31}})[i%3+1]
    rect(awningColor,x+10,y+h-10,w-20,5)
    for xx=x+12,x+w-15,9 do rect(p.ink,xx,y+h-10,3,5,.3) end
  end
  -- Selective neon signs (custom pixel glyphs) and physical roof details.
  local signs={'ROOMS','LAUNDRY','VINYL','BAR','24H','HOTEL','REPAIR','TEA'}
  local sign=(landmark and landmark.sign) or (landmark and landmarkSigns[landmark.id]) or b.name or signs[(i-1)%#signs+1]
  if w>50 and h>50 and art.textWidth(sign,1)<w-10 then
    local sw=art.textWidth(sign,1)+8
    rect(p.ink,x+(w-sw)/2,y+h-33,sw,12)
    art.text(sign,x+(w-sw)/2+4,y+h-31,1,accent)
    rect(accent,x+(w-sw)/2,y+h-22,sw,1,.6)
  end
  if i%4==0 and w>65 then
    rect({.25,.28,.29},x+w/2,y+8,2,16)
    rect({.43,.45,.43},x+w/2-5,y+6,12,2)
    rect({.40,.45,.44},x+w/2-3,y+2,8,1)
  end
  -- Each landmark has a silhouette/detail that survives on the handheld view.
  if landmark and landmark.id=='noodle' then
    rect(p.ink,x+w/2-14,y+35,28,22)
    rect(p.amber,x+w/2-11,y+47,22,2)
    rect(p.amber,x+w/2-8,y+50,16,3)
    rect(p.amber,x+w/2-5,y+53,10,2)
    rect(p.white,x+w/2-5,y+38,2,6,.7)
    rect(p.white,x+w/2+3,y+35,2,8,.7)
    rect(p.magenta,x+8,y+h-16,w-16,2)
  elseif landmark and landmark.id=='garage' then
    rect({.06,.095,.13},x+12,y+h-27,w-24,17)
    for n=1,5 do rect({.26,.30,.32},x+14,y+h-27+n*3,w-28,1) end
    rect(p.amber,x+12,y+h-28,w-24,2)
    rect(p.amber,x+14,y+h-25,2,14)
    rect(p.amber,x+w-16,y+h-25,2,14)
  elseif landmark and landmark.id=='mart' then
    for xx=x+9,x+w-10,8 do rect(math.floor(xx/8)%2==0 and p.magenta or p.white,xx,y+h-11,7,4,.7) end
    art.text('24/7',x+w/2-11,y+37,1,p.magenta)
  elseif landmark and landmark.id=='dock' then
    for n=1,3 do
      rect({.32,.33,.27},x+7,y+14+n*15,w-14,12)
      rect({.48,.43,.31},x+7,y+14+n*15,w-14,2)
      for xx=x+11,x+w-11,9 do rect({.15,.21,.21},xx,y+16+n*15,1,8) end
    end
    rect(p.amber,x+6,y+h-15,w-12,4)
    for xx=x+7,x+w-7,9 do rect(p.ink,xx,y+h-15,4,4) end
  elseif landmark and landmark.id=='clinic' then
    rect(p.green,x+w/2-3,y+31,6,19)
    rect(p.green,x+w/2-9,y+37,18,6)
  elseif landmark and landmark.id=='substation' then
    for n=0,2 do
      rect({.26,.31,.34},x+10+n*24,y+30,17,27)
      rect({.48,.50,.44},x+12+n*24,y+31,13,3)
      for row=1,4 do rect(p.ink,x+12+n*24,y+35+row*4,13,1) end
    end
  end
end

local function drawCity(m)
  local theme=m.theme or {}
  local roadEnd=theme.roadEndX or m.w
  rect(p.dark,0,0,m.w,m.h)
  for y=0,m.h-1,8 do
    for x=0,m.w-1,8 do
      if hash(x,y)>.66 then rect({.12,.15,.18},x,y,1,1) end
    end
  end
  local hw=m.halfwidth or 28
  for _,x in ipairs(m.xs) do
    rect({.25,.28,.30},x-hw-5,0,hw*2+10,m.h)
    rect(p.asphalt,x-hw,0,hw*2,m.h)
    rect({.05,.07,.10},x-hw,0,2,m.h)
    rect({.16,.20,.24},x+hw-3,0,1,m.h)
    for y=10,m.h-10,20 do rect({.48,.42,.30},x,y,1,10,.55) end
  end
  for _,y in ipairs(m.ys) do
    rect({.25,.28,.30},0,y-hw-5,roadEnd,hw*2+10)
    rect(p.asphalt,0,y-hw,roadEnd,hw*2)
    rect({.05,.07,.10},0,y-hw,roadEnd,2)
    rect({.16,.20,.24},0,y+hw-3,roadEnd,1)
    for x=10,roadEnd-10,20 do rect({.48,.42,.30},x,y,10,1,.55) end
  end
  for _,x in ipairs(m.xs) do
    for _,y in ipairs(m.ys) do
      rect(p.asphalt,x-hw,y-hw,hw*2,hw*2)
      for n=-16,16,7 do
        rect({.46,.49,.48},x+n,y-hw+4,4,7,.7)
        rect({.46,.49,.48},x+n,y+hw-11,4,7,.7)
        rect({.46,.49,.48},x-hw+4,y+n,7,4,.7)
        rect({.46,.49,.48},x+hw-11,y+n,7,4,.7)
      end
      -- Pixel streetlight bases and colored wet pavement beneath them.
      rect({.08,.13,.16},x+hw+3,y-hw-3,5,7)
      rect(p.amber,x+hw+4,y-hw-3,3,2,.8)
      rect(p.amber,x+hw-12,y-hw+1,12,1,.22)
      rect(p.amber,x+hw-10,y-hw+4,10,1,.12)
    end
  end
  -- Sparse road wear and elongated wet-road reflections.
  for _,y in ipairs(m.ys) do
    for x=18,roadEnd-20,39 do
      local c=({p.cyan,p.magenta,p.amber,p.blue})[math.floor(hash(x,y)*4)+1]
      rect(c,x,y+15,13,1,.12)
      rect(c,x+4,y+18,21,1,.08)
      rect({.07,.095,.13},x-3,y-17,20,2)
      rect({.26,.31,.33},x-3,y-17,8,1,.3)
    end
  end
  for _,x in ipairs(m.xs) do
    for y=22,m.h-20,45 do
      rect({.055,.07,.10},x-23,y,4,8)
      for n=1,3 do rect({.20,.25,.29},x-23,y+n*2,4,1) end
      rect(p.blue,x+18,y+3,2,15,.12)
    end
  end
  -- Authored shortcuts use distinct narrow asphalt and dashed cyan curbs.
  for _,alley in ipairs(m.shortcuts or {}) do
    rect({.06,.09,.13},alley.x-12,alley.y,24,alley.h)
    rect({.17,.24,.28},alley.x-12,alley.y,2,alley.h)
    rect({.17,.24,.28},alley.x+10,alley.y,2,alley.h)
    for y=alley.y+9,alley.y+alley.h-10,20 do
      rect(p.cyan,alley.x-11,y,1,7,.35)
      rect(p.cyan,alley.x+10,y,1,7,.35)
    end
    if alley.label and alley.label[1] then
      art.text(alley.label[1],alley.x-8,alley.y+31,1,p.muted)
      art.text(alley.label[2] or '',alley.x-10,alley.y+41,1,p.muted)
    end
  end
  -- Coastal districts: water beyond the quay with restrained reflections and
  -- working waterfronts. Decorative only: no collision or mechanics.
  if theme.waterX then
    rect({.03,.06,.10},theme.waterX,0,m.w-theme.waterX,m.h)
    rect({.07,.13,.20},theme.waterX,0,m.w-theme.waterX,3,.5)
    for y=30,m.h-30,46 do
      rect(p.cyan,theme.waterX+4,y,26,1,.10)
      rect(p.cyan,theme.waterX+36,y+9,18,1,.07)
      rect({.10,.18,.26},theme.waterX+8,y+22,32,1,.16)
    end
    rect({.30,.32,.34},theme.quayX,0,3,m.h)
    rect({.16,.18,.21},theme.quayX+3,0,4,m.h)
    for n=-14,14,7 do rect(p.amber,theme.quayX+1,360+n*30,2,12,.5) end
    if theme.warehouses then
      for _,y in ipairs({96,432}) do
        rect({.09,.13,.18},theme.quayX+18,y,26,42)
        rect({.20,.26,.32},theme.quayX+18,y,26,3)
        rect({.24,.30,.36},theme.quayX+22,y+10,18,26)
        for n=0,3 do rect({.30,.36,.42},theme.quayX+24,y+13+n*6,14,2) end
        rect(p.amber,theme.quayX+23,y+2,4,4,.9)
        rect({.12,.16,.22},theme.quayX+6,y+52,40,6)
        for n=0,4 do rect(p.cyan,theme.quayX+9+n*8,y+54,5,2,.5) end
      end
      rect({.13,.17,.23},672,432,44,60)
      rect({.22,.28,.34},672,432,44,3)
      rect(p.amber,676,436,6,6,.8)
      for _,x in ipairs({678,700,706}) do rect({.10,.14,.20},x,470,4,22) end
      for n=0,2 do rect({.30,.34,.40},676+n*10,470,8,3) end
      rect(p.cyan,684,400,34,1,.14)
      rect(p.cyan,688,402,26,1,.10)
    end
  end
  for i,b in ipairs(m.buildings or {}) do building(b,i) end
  for i,b in ipairs(m.buildings or {}) do
    if i%3==0 then tree(b.x+b.w-9,b.y+b.h+3,i) end
    if i%5==0 then
      rect({.10,.19,.19},b.x-7,b.y+12,5,12)
      rect({.16,.31,.25},b.x-7,b.y+12,5,2)
      rect({.36,.39,.28},b.x-9,b.y+28,7,5)
      rect({.58,.51,.37},b.x-8,b.y+28,5,1)
    end
  end
  for i,loc in ipairs(m.locations or {}) do
    local c=({p.cyan,p.amber,p.green,p.magenta})[(i-1)%4+1]
    local short=landmarkSigns[loc.id] or loc.name or 'DISPATCH'
    c=loc.color or c
    if loc.sign then short=loc.sign end
    local sw=art.textWidth(short,1)+8
    local sx=math.max(1,math.min(m.w-sw-1,loc.x-sw/2))
    rect(p.ink,sx,loc.y-43,sw,13)
    art.text(short,sx+4,loc.y-40,1,c)
    rect(c,sx,loc.y-32,sw,1)
    rect(c,sx+4,loc.y-29,sw-8,1,.13)
    rect(c,sx+8,loc.y-26,sw-16,1,.08)
    rect(p.ink,loc.x-10,loc.y+24,20,8)
    art.text('ZONE',loc.x-9,loc.y+25,1,c)
  end
end

-- Select a district for the city cache. Assets and fonts load once; the city
-- canvas is rebuilt only when the selected map actually changes. A rejected or
-- unknown map never replaces a valid cache.
-- Associate the selected map's destinations with their intended buildings
-- (the building whose center is nearest the sign position beside the location).
local function associate(map_)
  landmarkBuildings={}
  for _,loc in ipairs(map_.locations or {}) do
    local tx=loc.x+(loc.x>map_.w-192 and -96 or 96)
    local ty=loc.y+(loc.y>map_.h-180 and -84 or 84)
    local nearest,distance
    for i,b in ipairs(map_.buildings or {}) do
      local d=(b.x+b.w/2-tx)^2+(b.y+b.h/2-ty)^2
      if not distance or d<distance then nearest,distance=i,d end
    end
    if nearest then landmarkBuildings[nearest]=loc end
  end
end

function render.setMap(m)
  if type(m)~='table' or not m.id or not m.locations then return false end
  if m~=current then
    current=m
    associate(m)
    render.rebuild()
  end
  return true
end

function render.load(m)
  art.load()
  fonts={}
  for _,size in ipairs({10,11,12,13,14,16,18,20,24,28,36}) do
    fonts[size]=g.newFont(size)
    fonts[size]:setFilter('nearest','nearest')
  end
  local chosen=m or map
  current=nil
  landmarkBuildings={}
  city=g.newCanvas(chosen.w,chosen.h)
  city:setFilter('nearest','nearest')
  render.setMap(chosen)
end

function render.rebuild()
  if not city or not current then return end
  local previous=g.getCanvas()
  g.push('all')
  g.origin()
  g.setScissor()
  g.setCanvas(city)
  g.clear(p.ink)
  drawCity(current)
  g.setCanvas(previous)
  g.pop()
  windowWidth,windowHeight=g.getDimensions()
end

local function cargoTarget(s,m)
  if s.cargo then return m.locations[s.cargo.destination],s.cargo.kind,true end
  local nearest,kind,distance
  for _,job in ipairs(s.jobs or {}) do
    local l=m.locations[job.location]
    if l then
      local d=(l.x-s.player.x)^2+(l.y-s.player.y)^2
      if not distance or d<distance then nearest,kind,distance=l,job.kind,d end
    end
  end
  return nearest,kind,false
end

local function drawZone(loc,kind,target,time,delivery)
  local c=cargoColors[kind] or p.cyan
  local pulse=.65+.22*math.sin(time*4)
  color(c,pulse)
  g.setLineWidth(1)
  local radius=target and 21 or 17
  if delivery then
    g.polygon('line',loc.x,loc.y-radius-4,loc.x+radius+4,loc.y,loc.x,loc.y+radius+4,loc.x-radius-4,loc.y)
    color(c,.09)
    g.polygon('fill',loc.x,loc.y-radius-4,loc.x+radius+4,loc.y,loc.x,loc.y+radius+4,loc.x-radius-4,loc.y)
    color(c,pulse)
  else g.circle('line',loc.x,loc.y,radius,20) end
  local a=radius+3
  for _,d in ipairs({-1,1}) do
    g.line(loc.x+d*a,loc.y-9,loc.x+d*a,loc.y+9)
    g.line(loc.x-9,loc.y+d*a,loc.x+9,loc.y+d*a)
  end
  if target then
    local bob=math.floor(math.sin(time*4)*2)
    color(p.ink)
    g.polygon('fill',loc.x-7,loc.y-34+bob,loc.x+7,loc.y-34+bob,loc.x,loc.y-26+bob)
    color(c)
    g.polygon('fill',loc.x-5,loc.y-33+bob,loc.x+5,loc.y-33+bob,loc.x,loc.y-28+bob)
  end
  art.icon(kind,loc.x-7,loc.y-7,1,c)
end

local function headlights(car,c)
  g.push()
  g.translate(math.floor(car.x),math.floor(car.y))
  g.rotate(car.angle or 0)
  color(c,.07)
  g.polygon('fill',9,-4,42,-16,42,1,9,-2)
  g.polygon('fill',9,2,42,-1,42,16,9,4)
  color(c,.06)
  g.polygon('fill',9,-4,25,-9,25,9,9,4)
  g.pop()
end

local function vehicle(car,index,time,player,effects)
  local sprite=player and art.courier or car.kind=='police' and art.police or art.traffic[(index-1)%#art.traffic+1]
  if effects then headlights(car,player and p.cyan or p.amber) end
  color(p.ink,.65)
  g.draw(sprite,math.floor(car.x)+2,math.floor(car.y)+3,car.angle or 0,1,1,12,8)
  color(p.white)
  g.draw(sprite,math.floor(car.x),math.floor(car.y),car.angle or 0,1,1,12,8)
  if car.kind=='police' and not car.withdrawing then
    g.push()
    g.translate(math.floor(car.x),math.floor(car.y))
    g.rotate(car.angle or 0)
    rect(math.floor(time*8)%2==0 and p.magenta or p.blue,-1,-4,2,4)
    rect(math.floor(time*8)%2==0 and p.blue or p.magenta,-1,0,2,4)
    g.pop()
  end
  if car.kind=='police' then
    -- Pursuit state remains readable with reduced effects or without color.
    local cue=car.withdrawing and 'RETURN' or '!'
    local width=art.textWidth(cue,1)
    rect(p.ink,car.x-width/2-2,car.y-22,width+4,10,.95)
    art.text(cue,car.x-width/2,car.y-20,1,car.withdrawing and p.muted or p.white)
  end
  if (car.stun or 0)>0 then
    color(p.cyan,.75)
    g.circle('line',car.x,car.y,15+math.sin(time*15)*2,12)
    art.text('Z',car.x+8,car.y-17,1,p.cyan)
  end
  if player then
    color(p.cyan,.4)
    g.line(car.x-3,car.y-14,car.x+3,car.y-14)
    if effects then
      local speed=math.sqrt((car.vx or 0)^2+(car.vy or 0)^2)
      if speed>20 then
        g.push()
        g.translate(car.x,car.y)
        g.rotate(car.angle or 0)
        color(p.blue,.27)
        for n=1,3 do g.line(-11-n*5,-7-n,-9-n*5,-6-n) g.line(-11-n*5,7+n,-9-n*5,6+n) end
        g.pop()
      end
      if car.boostActive then
        g.push()
        g.translate(car.x,car.y)
        g.rotate(car.angle or 0)
        color(p.amber)
        g.polygon('fill',-10,-4,-21-math.floor(time*40)%5,0,-10,4)
        color(p.white)
        g.polygon('fill',-10,-2,-16,0,-10,2)
        g.pop()
      end
    end
  end
end

local function visualEvent(event,time,effects)
  local life=event.life or .6
  local progress=math.max(0,1-life/.7)
  local radius=(event.radius or 35)*(.35+progress*.8)
  local c=event.kind=='explosion' and p.amber or event.kind=='delivery' and p.green or p.cyan
  color(c,math.min(1,life*1.8))
  g.setLineWidth(event.kind=='explosion' and 2 or 1)
  g.circle('line',event.x,event.y,radius,20)
  g.setLineWidth(1)
  if event.kind=='explosion' then
    color(p.amber,life*.6)
    g.circle('fill',event.x,event.y,radius*.55,12)
    color(p.white,life)
    g.rectangle('fill',event.x-2,event.y-radius*.5,4,radius)
    g.rectangle('fill',event.x-radius*.5,event.y-2,radius,4)
  elseif event.kind=='emp' then
    color(p.cyan,life)
    g.circle('line',event.x,event.y,radius*.8,16)
  end
  if effects then
    for n=1,8 do
      local a=n*math.pi/4+hash(n,event.x)*.25
      rect(c,event.x+math.cos(a)*radius,event.y+math.sin(a)*radius,2,2,life)
    end
  end
end

local function minimap(s,target,m)
  local x,y,w,h=16,347,112,84
  panel(x,y,w,h,p.muted,false)
  label(string.upper(m.label or 'DISTRICT 07'),x+7,y+4,10,p.muted)
  local ox,oy=x+14,y+20
  local scale=.087
  local roadEnd=(m.theme and m.theme.roadEndX) or m.w
  color({.21,.29,.34})
  for _,rx in ipairs(m.xs) do g.rectangle('fill',ox+rx*scale-1,oy,2,m.h*scale) end
  for _,ry in ipairs(m.ys) do g.rectangle('fill',ox,oy+ry*scale-1,roadEnd*scale,2) end
  if target then
    rect(p.amber,ox+target.x*scale-2,oy+target.y*scale-2,5,5)
    color(p.white)
    g.rectangle('line',ox+target.x*scale-3.5,oy+target.y*scale-3.5,7,7)
  end
  for _,job in ipairs(s.jobs or {}) do
    local l=m.locations[job.location]
    if l then rect(cargoColors[job.kind] or p.magenta,ox+l.x*scale-1,oy+l.y*scale-1,3,3) end
  end
  rect(p.cyan,ox+s.player.x*scale-2,oy+s.player.y*scale-2,4,4)
end

local function directionArrow(s,target)
  if not target then return end
  local x,y=(target.x-camera.x)*2,(target.y-camera.y)*2+64
  if x>24 and x<616 and y>92 and y<418 then return end
  local dx,dy=target.x-s.player.x,target.y-s.player.y
  local angle=math.atan2(dy,dx)
  local top=s.onboarding and s.time<18 and 137 or 99
  local vertical=dy<0 and 254-top or 404-254
  local amount=math.min(278/(math.abs(math.cos(angle))+.0001),vertical/(math.abs(math.sin(angle))+.0001))
  local ax,ay=320+math.cos(angle)*amount,254+math.sin(angle)*amount
  g.push()
  g.translate(math.floor(ax),math.floor(ay))
  g.rotate(angle)
  color(p.ink)
  g.polygon('fill',14,0,-8,-10,-4,0,-8,10)
  color(p.amber)
  g.polygon('fill',10,0,-6,-7,-2,0,-6,7)
  g.pop()
  local distance=math.floor(math.sqrt(dx*dx+dy*dy))
  label(distance..'m',math.max(4,math.min(590,ax-16)),ay+14,11,p.amber)
end

local function world(s,settings,backdrop)
  local m=current or map
  local time=s and s.time or love.timer.getTime()
  local start=m.start or {x=480,y=432}
  local player=s and s.player or {x=start.x+math.sin(time*.08)*160,y=start.y+math.cos(time*.07)*80,angle=-.15}
  camera.x,camera.y=m.camera(player.x,player.y)
  local effects=not settings or settings.effects~=false
  g.setScissor(0,64,640,380)
  g.push()
  g.translate(0,64)
  g.scale(2,2)
  local shake=s and (settings.shake~=false) and (s.shake or 0) or 0
  g.translate(-camera.x+math.floor(math.sin(time*59)*shake*2),-camera.y+math.floor(math.cos(time*67)*shake*2))
  color(p.white)
  g.draw(city,0,0)
  if s then
    local target,kind,isDelivery=cargoTarget(s,m)
    -- A restrained dotted street route guides without covering hazards.
    if target and m.route then
      local points=m.route(player.x,player.y,target.x,target.y)
      if points then
        color(p.amber,.28)
        for i=2,#points do
          local a,b=points[i-1],points[i]
          local ax,ay=a.x or a[1],a.y or a[2]
          local bx,by=b.x or b[1],b.y or b[2]
          local distance=math.sqrt((bx-ax)^2+(by-ay)^2)
          for d=0,distance,8 do
            local f=distance>0 and d/distance or 0
            g.rectangle('fill',math.floor(ax+(bx-ax)*f),math.floor(ay+(by-ay)*f),2,2)
          end
        end
      end
    end
    if isDelivery then drawZone(target,kind,true,time,true) else
      for _,job in ipairs(s.jobs or {}) do
        local loc=m.locations[job.location]
        if loc then drawZone(loc,job.kind,loc==target,time) end
      end
    end
    for i,car in ipairs(s.cars or {}) do vehicle(car,i,time,false,effects) end
    vehicle(player,1,time,true,effects)
    for _,particle in ipairs(s.particles or {}) do
      local c=particle.color or p.amber
      rect(c,particle.x,particle.y,particle.size or 2,particle.size or 2,particle.alpha or .8)
    end
    -- Event rings are actual gameplay feedback, independent of ornamental rain.
    for _,event in ipairs(s.visualEvents or {}) do visualEvent(event,time,effects) end
  end
  g.pop()
  if effects then
    color(p.blue,.18)
    for i=1,55 do
      local rx=(i*83+time*19)%660-10
      local ry=64+(i*47+time*160)%390
      g.line(math.floor(rx),math.floor(ry),math.floor(rx-3),math.floor(ry+8))
    end
  end
  g.setScissor()
  if s and not backdrop then
    local target=cargoTarget(s,current or map)
    minimap(s,target,m)
    directionArrow(s,target)
  end
end

local function bar(x,y,w,h,value,c)
  rect({.13,.17,.22},x,y,w,h)
  rect(c,x,y,math.max(0,math.min(w,w*value)),h)
  for n=1,4 do rect(p.ink,x+w*n/5,y,1,h,.5) end
end

local function hud(s,m)
  local target,kind,delivery=cargoTarget(s,m or current or map)
  rect(p.ink,0,0,640,64)
  rect(p.cyan,0,63,640,1,.4)
  label('HULL',16,9,10,p.muted)
  bar(16,24,96,6,(s.player.hp or 0)/(s.player.maxHp or 100),(s.player.hp or 100)<30 and p.red or p.cyan)
  label(math.ceil(s.player.hp or 0)..' / '..(s.player.maxHp or 100),16,35,11,p.white)
  label('BOOST',131,9,10,p.muted)
  bar(131,24,75,6,(s.player.boost or 100)/100,p.amber)
  local emp=s.player.empCooldown or 0
  label(emp<=0 and 'EMP READY' or ('EMP '..math.ceil(emp)..'s'),131,35,11,emp<=0 and p.cyan or p.muted)
  label('SHIFT',238,9,10,p.muted)
  local left=math.max(0,math.ceil((s.duration or 300)-s.time))
  art.text(string.format('%02d:%02d',math.floor(left/60),left%60),238,25,2,left<30 and p.amber or p.white)
  label('HEAT',338,9,10,p.muted)
  for n=1,5 do rect(n<=math.ceil(s.heat or 0) and p.magenta or {.15,.17,.23},338+(n-1)*14,25,10,10) end
  label('DELIVERIES '..(s.delivered or 0),338,43,10,p.white)
  label('SCORE',456,9,10,p.muted)
  art.text(string.format('%06d',s.score or 0),456,25,2,p.white)
  label('$'..(s.cash or 0),575,10,12,p.amber)
  label((s.upgradeProgress or 0)..'/'..(s.upgradeTarget or 3)..' UPG',575,35,10,p.muted)
  rect(p.ink,0,444,640,36)
  rect(p.cyan,0,444,640,1,.4)
  if kind then
    art.icon(kind,13,453,1.25)
    label(delivery and 'DELIVER' or 'PICK UP',40,450,10,p.muted)
    local name=target and target.name or 'DISPATCH'
    label(name,40,462,12,p.white)
    label(cargoNames[kind] or kind,235,450,11,cargoColors[kind])
    local protection=s.upgrades and s.upgrades.cargo or 0
    local hint=kind=='prototype' and '$260 / TEMPORARY HEAT +2'
      or kind=='medical' and ('$160 +$25/INTEGRITY / '..(3+protection)..' IMPACTS')
      or ('$230 / '..(38+8*protection)..'s / EXPIRY -26 HULL')
    if s.cargo then
      if kind=='medical' then hint='$160 +$25/INTEGRITY / '..(s.cargo.integrity or 0)..' LEFT' end
      if kind=='battery' then hint='$230 / EXPLODES IN '..math.max(0,math.ceil(s.cargo.remaining or 0))..'s / -26 HULL' end
    end
    label(hint,235,464,10,kind=='battery' and s.cargo and (s.cargo.remaining or 100)<10 and p.red or p.muted)
  end
  label('BOOST  SPACE / A',480,451,10,p.muted)
  label('EMP  X / B',480,464,10,p.muted)
  if s.notice and (s.noticeTime or 0)>0 then
    local width=math.min(440,fonts[13]:getWidth(s.notice)+36)
    panel(320-width/2,396,width,31,p.cyan,false)
    wrapped(s.notice,320-width/2+12,402,width-24,13,p.white,'center')
  end
  if s.onboarding and s.time<18 then
    panel(149,77,342,47,p.cyan,false)
    label('FOLLOW THE AMBER ROUTE',161,84,12,p.cyan)
    label(type(s.onboarding)=='string' and s.onboarding or 'Steer into a marked zone. Pickups are automatic.',161,102,11,p.white)
  end
end

local function menuItem(text,x,y,width,selected)
  if selected then
    rect({.08,.21,.24},x,y,width,32)
    rect(p.cyan,x,y,3,32)
    label('>',x+12,y+6,16,p.cyan)
  end
  label(text,x+35,y+7,14,selected and p.white or p.muted)
end

local function title(app)
  world(nil,app.settings,true)
  rect(p.ink,0,0,640,480,.77)
 label(string.upper((current or map).label)..'  /  '..(current or map).subtitle,54,31,11,p.cyan)
 art.text('NEON',55,59,5,p.cyan)
 art.text('COURIER',55,103,5,p.white)
 rect(p.magenta,54,155,148,3)
 label('One car. Dangerous cargo. Five minutes.',55,175,14,p.muted)
 local options={'START SHIFT','DISTRICT: '..string.upper((current or map).label),'SETTINGS','QUIT'}
 for i,text in ipairs(options) do menuItem(text,54,221+(i-1)*39,261,app.selection==i) end
  panel(354,211,232,155,p.magenta,false)
  label('THE NIGHT PAYS MORE',370,225,12,p.magenta)
  for i,kind in ipairs({'prototype','medical','battery'}) do
    art.icon(kind,371,252+(i-1)*35,1.25)
    label(cargoNames[kind],398,251+(i-1)*35,10,p.white)
    label(cargoHints[kind],398,266+(i-1)*35,10,p.muted)
  end
  color(p.white)
  g.draw(art.courier,522,130,-.16,4,4,12,8)
  label('STEER  WASD / ARROWS / STICK',54,393,11,p.muted)
  label('BOOST  SPACE / A     EMP  X / B     PAUSE  ESC / START',54,414,11,p.muted)
  local best=app.highscores and app.highscores[1]
  label('BEST SHIFT  '..(best and best.score or '---'),54,448,11,p.amber)
  label('CONFIRM  ENTER / A',426,448,11,p.cyan)
end

local function settings(app)
  -- settings opened from title preview the selected district without a shift;
  -- settings opened from pause retain the active simulation's world
  if app.settingsReturn=='paused' and app.sim then world(app.sim,app.settings,true)
  else world(nil,app.settings,true) end
  rect(p.ink,0,0,640,480,.88)
  art.text('SETTINGS',76,47,3,p.white)
  label('Tune the night to your screen and speakers.',76,82,12,p.muted)
  local s=app.settings
  local ps=math.max(1,math.min(4,math.floor(s.pixelSize or 1)))
  local values={math.floor((s.music or .6)*100)..'%',math.floor((s.sfx or .7)*100)..'%',s.mute and 'ON' or 'OFF',s.shake==false and 'OFF' or 'ON',s.effects==false and 'REDUCED' or 'FULL',ps..'X',s.fullscreen and 'ON' or 'OFF',''}
  local rows={'MUSIC','SOUND EFFECTS','MUTE','SCREEN SHAKE','ATMOSPHERE','PIXEL SIZE','FULLSCREEN','BACK'}
  for i,text in ipairs(rows) do
    menuItem(text,75,121+(i-1)*40,490,app.selection==i)
    label(values[i],466,129+(i-1)*40,12,app.selection==i and p.cyan or p.muted)
  end
  centered('LEFT / RIGHT TO ADJUST    ENTER / A TO TOGGLE    ESC / B TO RETURN',438,10,p.muted)
end

local function paused(app)
  world(app.sim,app.settings,true)
  hud(app.sim,current)
  rect(p.ink,0,64,640,380,.82)
  art.text('SHIFT PAUSED',175,123,3,p.white)
  centered('The city can wait a moment.',163,12,p.muted)
  for i,text in ipairs({'RESUME','SETTINGS','END SHIFT'}) do menuItem(text,190,217+(i-1)*40,260,app.selection==i) end
  centered('ESC / START TO RESUME',373,11,p.cyan)
end

local function upgrade(app)
  local s=app.sim
  world(s,app.settings,true)
  rect(p.ink,0,0,640,480,.9)
  art.text('MAKE IT THROUGH',58,36,3,p.white)
  label('DISPATCH REWARD / CHOOSE ONE SHIFT UPGRADE',58,75,11,p.cyan)
  for i,offer in ipairs(s.offers or {}) do
    local x=23+(i-1)*202
    local selected=app.selection==i
    panel(x,124,190,251,selected and p.cyan or p.muted,selected)
    art.text('0'..i,x+15,139,3,selected and p.cyan or p.muted)
    wrapped(offer.name or 'UPGRADE',x+15,184,160,18,p.white)
    rect(selected and p.cyan or p.muted,x+15,237,160,1,.45)
    wrapped(offer.description or '',x+15,254,160,12,p.muted)
    local level=(s.upgrades and s.upgrades[offer.id] or offer.level or 0)+1
    label('LEVEL '..level..' / '..(offer.max or 3),x+15,344,11,selected and p.cyan or p.muted)
    if selected then label('SELECTED',x+103,345,10,p.cyan) end
  end
  centered('LEFT / RIGHT TO CHOOSE     ENTER / A TO INSTALL',412,12,p.cyan)
  centered('Shift timer and traffic are paused while choosing.',438,11,p.muted)
end

local function results(app)
  local s=app.sim
  world(s,app.settings,true)
  rect(p.ink,0,0,640,480,.87)
  centered(s.endReason or 'SHIFT COMPLETE',35,14,s.endReason=='VEHICLE WRECKED' and p.red or p.cyan)
  local headline='NIGHT SETTLED'
  art.text(headline,320-art.textWidth(headline,3)/2,68,3,p.white)
  centered('YOUR SHIFT SCORE',111,11,p.muted)
  art.text(string.format('%06d',s.score or 0),320-art.textWidth(string.format('%06d',s.score or 0),5)/2,134,5,p.amber)
  local stats={{'DELIVERED',s.delivered or 0,p.cyan},{'LOST CARGO',s.failed or 0,p.magenta},{'CASH EARNED','$'..(s.cash or 0),p.amber}}
  for i,v in ipairs(stats) do
    local x=67+(i-1)*174
    panel(x,201,158,77,v[3],false)
    label(v[1],x+13,213,10,p.muted)
    label(v[2],x+13,237,24,v[3])
  end
  local elapsed=math.floor(s.time or 0)
  local bonus=s.stats and s.stats.bonus or 0
  local survival=s.stats and s.stats.survivalBonus or 0
  centered('BASE JOBS '..math.max(0,(s.cash or 0)-bonus)..' / CLEAN + INTEGRITY '..bonus..' / SURVIVAL '..survival,290,11,p.amber)
  centered(string.format('TIME %02d:%02d   /   DAMAGE %d   /   EMP HITS %d',math.floor(elapsed/60),elapsed%60,s.stats and s.stats.damage or 0,s.stats and s.stats.empHits or 0),312,11,p.muted)
  for i,text in ipairs({'RUN AGAIN','TITLE'}) do menuItem(text,190,341+(i-1)*39,260,app.selection==i) end
  centered('Every route is a fresh chance. Your best shifts are saved locally.',444,11,p.muted)
end

-- Title and settings opened from title preview the SELECTED district; playing,
-- paused, upgrades, results and settings opened from pause keep the ACTIVE
-- shift's map. A retained simulation never overrides a title preview, and an
-- unknown selection is rejected before it can replace a valid cache.
function render.draw(app)
  local w,h=g.getDimensions()
  if w~=windowWidth or h~=windowHeight then render.rebuild() end
  local preview=app.mode=='title' or (app.mode=='settings' and app.settingsReturn~='paused')
  local chosen
  if preview then
    chosen=map.get(app.selectedDistrictId or 'district07')
    -- an unknown selection is rejected: the valid cache is never replaced and a
    -- retained shift is never a preview fallback
    if not chosen then chosen=current end
  else
    chosen=app.sim and app.sim.map or nil
  end
  if chosen then render.setMap(chosen) end
  g.clear(p.ink)
  g.setBlendMode('alpha')
  if app.mode=='title' then title(app)
  elseif app.mode=='settings' then settings(app)
  elseif app.mode=='playing' then world(app.sim,app.settings,false) hud(app.sim,current)
  elseif app.mode=='paused' then paused(app)
  elseif app.mode=='upgrade' then upgrade(app)
  elseif app.mode=='results' then results(app)
  else title(app) end
  g.setScissor()
  color(p.white)
end

return render
