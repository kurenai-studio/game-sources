-- Original pixel art. All sprites and glyphs are authored for NEON COURIER.
local art = {}

art.palette = {
  ink = {0.035, 0.051, 0.094}, dark = {0.063, 0.086, 0.137},
  asphalt = {0.091, 0.118, 0.161}, roof = {0.133, 0.169, 0.216},
  muted = {0.40, 0.51, 0.60}, white = {0.90, 0.95, 0.94},
  cyan = {0.22, 0.91, 0.92}, magenta = {0.98, 0.31, 0.59},
  amber = {1.0, 0.75, 0.35}, green = {0.48, 0.89, 0.67},
  red = {1.0, 0.36, 0.35}, blue = {0.35, 0.59, 0.91},
}

local glyphs = {
 A={'01110','10001','10001','11111','10001','10001','10001'},
 B={'11110','10001','10001','11110','10001','10001','11110'},
 C={'01111','10000','10000','10000','10000','10000','01111'},
 D={'11110','10001','10001','10001','10001','10001','11110'},
 E={'11111','10000','10000','11110','10000','10000','11111'},
 F={'11111','10000','10000','11110','10000','10000','10000'},
 G={'01111','10000','10000','10111','10001','10001','01110'},
 H={'10001','10001','10001','11111','10001','10001','10001'},
 I={'111','010','010','010','010','010','111'},
 J={'00111','00010','00010','00010','10010','10010','01100'},
 K={'10001','10010','10100','11000','10100','10010','10001'},
 L={'10000','10000','10000','10000','10000','10000','11111'},
 M={'10001','11011','10101','10101','10001','10001','10001'},
 N={'10001','11001','11001','10101','10011','10011','10001'},
 O={'01110','10001','10001','10001','10001','10001','01110'},
 P={'11110','10001','10001','11110','10000','10000','10000'},
 Q={'01110','10001','10001','10001','10101','10010','01101'},
 R={'11110','10001','10001','11110','10100','10010','10001'},
 S={'01111','10000','10000','01110','00001','00001','11110'},
 T={'11111','00100','00100','00100','00100','00100','00100'},
 U={'10001','10001','10001','10001','10001','10001','01110'},
 V={'10001','10001','10001','10001','10001','01010','00100'},
 W={'10001','10001','10001','10101','10101','10101','01010'},
 X={'10001','10001','01010','00100','01010','10001','10001'},
 Y={'10001','10001','01010','00100','00100','00100','00100'},
 Z={'11111','00001','00010','00100','01000','10000','11111'},
 ['0']={'01110','10001','10011','10101','11001','10001','01110'},
 ['1']={'010','110','010','010','010','010','111'},
 ['2']={'01110','10001','00001','00010','00100','01000','11111'},
 ['3']={'11110','00001','00001','01110','00001','00001','11110'},
 ['4']={'00010','00110','01010','10010','11111','00010','00010'},
 ['5']={'11111','10000','10000','11110','00001','00001','11110'},
 ['6']={'01110','10000','10000','11110','10001','10001','01110'},
 ['7']={'11111','00001','00010','00100','01000','01000','01000'},
 ['8']={'01110','10001','10001','01110','10001','10001','01110'},
 ['9']={'01110','10001','10001','01111','00001','00001','01110'},
 ['+']={'000','010','010','111','010','010','000'},
 ['-']={'000','000','000','111','000','000','000'},
 ['.']={'0','0','0','0','0','1','1'},
 [':']={'0','1','1','0','1','1','0'},
 ['/']={'00001','00001','00010','00100','01000','10000','10000'},
 ['!']={'1','1','1','1','1','0','1'},
 ['?']={'11110','00001','00001','00110','00100','00000','00100'},
 [' ']={'000','000','000','000','000','000','000'},
}

function art.textWidth(text, scale)
  local width = 0
  for letter in tostring(text):upper():gmatch('.') do
    width = width + #(glyphs[letter] or glyphs['?'])[1] + 1
  end
  return math.max(0,width-1) * (scale or 1)
end

function art.text(text, x, y, scale, color)
  scale = scale or 1
  love.graphics.setColor(color or art.palette.white)
  local cursor = math.floor(x)
  for letter in tostring(text):upper():gmatch('.') do
    local g = glyphs[letter] or glyphs['?']
    for row = 1,7 do
      for col = 1,#g[row] do
        if g[row]:sub(col,col) == '1' then
          love.graphics.rectangle('fill',cursor+(col-1)*scale,math.floor(y)+(row-1)*scale,scale,scale)
        end
      end
    end
    cursor = cursor + (#g[1]+1)*scale
  end
end

local function sprite(name)
  local img=love.graphics.newImage('assets/art/'..name..'.png')
  img:setFilter('nearest','nearest')
  return img
end

function art.load()
  art.courier=sprite('courier')
  art.police=sprite('police')
  art.traffic={sprite('traffic_rust'),sprite('traffic_slate'),sprite('traffic_taxi')}
end

function art.icon(kind,x,y,scale,color)
  scale=scale or 1
  local p=art.palette
  love.graphics.push()
  love.graphics.translate(math.floor(x),math.floor(y))
  love.graphics.scale(scale)
  love.graphics.setColor(p.ink)
  love.graphics.rectangle('fill',0,0,14,14)
  love.graphics.setColor(color or (kind=='prototype' and p.magenta or kind=='medical' and p.green or p.amber))
  if kind=='prototype' then
    love.graphics.rectangle('fill',3,3,8,8)
    for i=1,3 do
      love.graphics.rectangle('fill',1,i*3,1,1)
      love.graphics.rectangle('fill',12,i*3,1,1)
      love.graphics.rectangle('fill',i*3,1,1,1)
      love.graphics.rectangle('fill',i*3,12,1,1)
    end
    love.graphics.setColor(p.ink)
    love.graphics.rectangle('fill',5,5,4,4)
  elseif kind=='medical' then
    love.graphics.rectangle('line',1.5,3.5,11,9)
    love.graphics.rectangle('fill',5,1,4,2)
    love.graphics.rectangle('fill',6,5,2,6)
    love.graphics.rectangle('fill',4,7,6,2)
  else
    love.graphics.rectangle('line',2.5,3.5,9,9)
    love.graphics.rectangle('fill',5,1,4,2)
    love.graphics.polygon('fill',8,4,4,8,7,8,5,12,10,7,7,7)
  end
  love.graphics.pop()
end

return art
