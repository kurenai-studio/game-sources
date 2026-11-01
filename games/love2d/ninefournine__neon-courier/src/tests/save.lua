-- Save recovery and persistence regressions. Exercises the real game/save.lua
-- contract with an in-memory filesystem mock: missing, unreadable, malformed,
-- truncated and oversized saves, bounded settings/high scores, failed writes,
-- and store/load persistence across a simulated (encode/decode) restart.
-- A failed-write check uses a NON-MUTATING mock; it does not assert production
-- atomic-write or partial-failure behavior (out of this scope).
package.path='./?.lua;./?/init.lua;'..package.path
local Save=require('game.save')

love={filesystem={}}
local function setFiles(state)
 love.filesystem={
  getInfo=function(name)
   local v=state[name]
   if v==nil then return nil end
   if v=='__dir__' then return {type='directory',size=0} end
   return {type='file',size=#v}
  end,
  read=function(name)
   local v=state[name]
   if v==nil then error('file not found') end
   if v=='__dir__' then error('is a directory') end
   return v
  end,
  write=function(name,data)
   if state.__readonly__ then return false end
   state[name]=data;return true
  end,
 }
end

local count=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then print('FAIL '..name..': '..tostring(err));os.exit(1) end
 count=count+1;print('PASS '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end

test('missing save recovers to defaults',function()
 setFiles({})
 local s=Save.load()
 eq(s.settings.music,.6);eq(s.settings.pixelSize,1);eq(s.settings.fullscreen,false)
 eq(#s.highscores,0)
end)

test('unreadable save (read throws) recovers to defaults',function()
 setFiles({['dispatch.sav']='NEON1\nmusic=0.2\n'})
 local real=love.filesystem.read
 love.filesystem.read=function() error('permission denied') end
 local s=Save.load()
 love.filesystem.read=real
 eq(s.settings.music,.6)
end)

test('directory in place of the save recovers to defaults',function()
 setFiles({['dispatch.sav']='__dir__'})
 local s=Save.load()
 eq(s.settings.music,.6)
end)

test('unreadable save returning nil plus an error (LÖVE read IO contract) recovers to defaults',function()
 setFiles({['dispatch.sav']='NEON1\nmusic=0.2\n'})
 local real=love.filesystem.read
 love.filesystem.read=function() return nil,'io error' end
 local s=Save.load()
 love.filesystem.read=real
 eq(s.settings.music,.6);eq(s.settings.pixelSize,1)
end)

test('malformed headers recover to defaults',function()
 for _,text in ipairs({'','   ','NEON2\nmusic=0.2\n','return dumplib()\n','NEON1','garbage'}) do
  local s=Save.decode(text)
  eq(s.settings.music,.6);eq(s.settings.pixelSize,1);eq(#s.highscores,0)
 end
end)

test('oversized save (>8192) recovers to defaults',function()
 setFiles({['dispatch.sav']='NEON1\n'..string.rep('music=0.2\n',2000)})
 local s=Save.load()
 eq(s.settings.music,.6)
end)

test('truncated save keeps the valid prefix and defaults the rest',function()
 local s=Save.decode('NEON1\nmusic=0.2\nsfx=0.3\nmute=tr')
 eq(s.settings.music,.2);eq(s.settings.sfx,.3);eq(s.settings.mute,false)
 eq(s.settings.fullscreen,false);eq(s.settings.pixelSize,1)
end)

test('settings values are range and type bounded',function()
 local s=Save.decode('NEON1\nmusic=-5\nmusic=2\nmusic=nan\nmusic=1e999\nmusic=0.25\n')
 eq(s.settings.music,.25)
 local t=Save.decode('NEON1\nsfx=abc\n')
 eq(t.settings.sfx,.7)
 for _,bad in ipairs({'mute=1','mute=TRUE','mute=yes','mute='}) do
  local m=Save.decode('NEON1\n'..bad..'\n')
  eq(m.settings.mute,false)
 end
 local p=Save.decode('NEON1\npixelSize=0\n')
 eq(p.settings.pixelSize,1)
 local q=Save.decode('NEON1\npixelSize=9\n')
 eq(q.settings.pixelSize,1)
 local r=Save.decode('NEON1\npixelSize=abc\n')
 eq(r.settings.pixelSize,1)
 local f=Save.decode('NEON1\npixelSize=4\n')
 eq(f.settings.pixelSize,4)
end)

test('high scores stay bounded, sorted and type-checked',function()
 local d=Save.defaults()
 for i=1,25 do Save.record(d,{score=i,delivered=i}) end
 eq(#d.highscores,10);eq(d.highscores[1].score,25);eq(d.highscores[10].score,16)
 local s=Save.decode('NEON1\nscore=5,2\nscore=3,1\nscore=abc,def\nscore=9\nscore=0,0\nscore=-4,2\n')
 eq(#s.highscores,3);eq(s.highscores[1].score,5);eq(s.highscores[1].deliveries,2)
end)

test('store/load roundtrip is stable across a simulated restart (encode/decode, not a fresh process)',function()
 local state={}
 setFiles(state)
 local d=Save.defaults()
 d.settings.music=.3;d.settings.mute=true;d.settings.pixelSize=2;d.settings.fullscreen=true
 Save.record(d,{score=100,delivered=3});Save.record(d,{score=400,delivered=7})
 eq(Save.store(d),true)
 local s=Save.load()
 eq(s.settings.music,.3);eq(s.settings.mute,true);eq(s.settings.pixelSize,2);eq(s.settings.fullscreen,true)
 eq(#s.highscores,2);eq(s.highscores[1].score,400)
 -- a fresh process reads the same bytes and decodes identically
 local text=state['dispatch.sav']
 eq(Save.encode(s),text)
 eq(Save.decode(text).highscores[1].score,400)
end)

test('a non-mutating failed write reports failure and the mock keeps prior bytes',function()
 local state={}
 setFiles(state)
 local good=Save.defaults();good.settings.music=.4
 eq(Save.store(good),true)
 local before=state['dispatch.sav']
 state.__readonly__=true
 local bad=Save.defaults();bad.settings.music=1
 eq(Save.store(bad),false)
 state.__readonly__=nil
 eq(state['dispatch.sav'],before)
 eq(Save.load().settings.music,.4)
end)

test('store requires an actual true result per the LÖVE 11.5 write contract',function()
 local real=love.filesystem
 local function storeWith(write)
  love.filesystem={write=write}
  local ok=Save.store(Save.defaults())
  love.filesystem=real
  return ok
 end
 eq(storeWith(function() return true end),true)     -- success pushes true
 eq(storeWith(function() return false end),false)   -- explicit failure
 eq(storeWith(function() return nil,'disk full' end),false) -- nil + error string
 eq(storeWith(function() error('io error raised') end),false) -- throw (pcall-guarded)
 love.filesystem=real
end)

test('save text never carries executable content and decodes without side effects',function()
 local state={}
 setFiles(state)
 local d=Save.defaults();d.settings.music=.5
 Save.store(d)
 local text=state['dispatch.sav']
 assert(not text:match('return') and not text:match('load') and not text:match('dofile'),'unexpected code token')
 local s=Save.decode('NEON1\nmusic=return os.exit(1)\n')
 eq(s.settings.music,.6)
end)

print('ALL '..count..' SAVE TESTS PASSED')
