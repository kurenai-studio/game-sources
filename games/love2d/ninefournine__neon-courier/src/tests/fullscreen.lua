-- Rejected-fullscreen preference regressions. Loads the real main.lua with a
-- stubbed LÖVE environment (same technique as the session repro) and drives the
-- actual handlers plus love.load; no real window, files or audio are created.
-- The session bug: a failed fullscreen request must not leave the displayed or
-- saved fullscreen preference true. Rollback is based on observed native state.
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
  newFont=function() return {setFilter=function() end,getWidth=function() return 8 end} end,
  captureScreenshot=function() end,getDimensions=function() return 640,480 end,
  getDPIScale=function() return 1 end,getRendererInfo=function() return 'stub','stub','stub','stub' end,
 }
end

local function makeLove(opts)
 local files={}
 local calls={}
 if opts.stateful then
  local engaged=false
  opts.setFullscreen=function(enable) engaged=(enable==true);return true end
  opts.getFullscreen=function() return engaged end
 end
 local sim=opts.simulated and {fs=false,w=640,h=480} or nil
 if sim then
  opts.setFullscreen=function(enable) sim.fs=(enable==true);return true end
  opts.getFullscreen=function() return sim.fs end
  opts.updateMode=function(w,h)
   calls[#calls+1]='updateMode:'..w..'x'..h
   if not sim.fs then
    if w>opts.maxW then w=opts.maxW end
    if h>opts.maxH then h=opts.maxH end
    sim.w,sim.h=w,h
   end
   return true -- the real window manager also reports success while clamping
  end
 end
 local graphics=stubGraphics()
 if sim then
  graphics.getDimensions=function() if sim.fs then return opts.desktopW,opts.desktopH end return sim.w,sim.h end
 end
 local love={
  graphics=graphics,
  window={
   updateMode=function(w,h)
    calls[#calls+1]='updateMode:'..w..'x'..h
    if opts.updateMode==nil then return true end
    if opts.updateMode==false then return false end
    return opts.updateMode(w,h)
   end,
   setFullscreen=function(enable) calls[#calls+1]='setFullscreen:'..tostring(enable);return opts.setFullscreen(enable==true) end,
   getFullscreen=opts.getFullscreen,
   getDesktopDimensions=function() return 1512,982 end,
   getDisplayName=function() return 'stub' end,
  },
  filesystem={
   setIdentity=function() end,
   getInfo=function(name) return files[name] and {size=#files[name]} or nil end,
   read=function(name) return files[name] end,
   write=function(name,data) files[name]=data;return true end,
  },
  timer={getTime=function() return 1 end},
  keyboard={isDown=function() return false end},
  joystick={getJoysticks=function() return {} end},
  event={quit=function() end},
 }
 setmetatable(love,{__index=_G})
 _G.love=love -- required modules capture love.graphics at require time
 local ok,err=pcall(function() assert(loadfile('main.lua'))() end)
 if not ok then _G.love=nil;error('main.lua failed to load: '..tostring(err)) end
 return love,files,calls
end

local function findApp()
 for i=1,20 do
  local n,v=debug.getupvalue(_G.love.keypressed,i)
  if not n then break end
  if type(v)=='table' and rawget(v,'mode') and rawget(v,'accumulator') then return v end
 end
 return nil
end

local function seedSave(files,fullscreen,pixelSize)
 files['dispatch.sav']='NEON1\nmusic=0.6\nsfx=0.7\nmute=false\nshake=true\neffects=true\npixelSize='
  ..tostring(pixelSize or 1)..'\nfullscreen='..tostring(fullscreen)..'\n'
end


local function settle(love,frames)
 for _=1,(frames or 150) do love.update(1/60) end
end

local function savedFlag(files)
 return (files['dispatch.sav'] or ''):match('fullscreen=(%a+)')
end

local function savedPixel(files)
 return (files['dispatch.sav'] or ''):match('pixelSize=(%d+)')
end

local count=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then print('FAIL '..name..': '..tostring(err));os.exit(1) end
 count=count+1;print('PASS '..name)
end
local function eq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local const=function(v) return function() return v end end
-- navigate the real title menu to the Settings screen and down to settings row n
local function openSettingsAtRow(love,app,row)
 love.keypressed('down');love.update(1/60)
 eq(app.selection,2,'district row')
 love.keypressed('down');love.update(1/60)
 eq(app.selection,3,'settings row')
 love.keypressed('return');love.update(1/60)
 eq(app.mode,'settings')
 eq(app.selection,1)
 for _=2,row do love.keypressed('down');love.update(1/60) end
 eq(app.selection,row)
end

test('F11 keeps fullscreen false when setFullscreen returns false',function()
 local love,files=makeLove{setFullscreen=const(false),getFullscreen=const(false)}
 local app=assert(findApp())
 love.load({})
 love.keypressed('f11');love.update(1/60)
 eq(app.settings.fullscreen,false)
 settle(love);eq(app.settings.fullscreen,false)
 love.quit();eq(savedFlag(files),'false')
end)

test('F11 reverts when setFullscreen throws',function()
 local love,files=makeLove{setFullscreen=function() error('mock display failure') end,getFullscreen=const(false)}
 local app=assert(findApp())
 love.load({})
 love.keypressed('f11');love.update(1/60)
 eq(app.settings.fullscreen,false)
 settle(love);eq(app.settings.fullscreen,false)
 love.quit();eq(savedFlag(files),'false')
end)

test('F11 reverts at the deadline when the transition never engages',function()
 local love,files=makeLove{setFullscreen=const(true),getFullscreen=const(false)}
 local app=assert(findApp())
 love.load({})
 love.keypressed('f11');love.update(1/60)
 eq(app.settings.fullscreen,true) -- API accepted; transition allowed to settle
 settle(love,90);eq(app.settings.fullscreen,true) -- inside the settle window
 settle(love,60)
 eq(app.settings.fullscreen,false) -- still disengaged at the deadline
 love.quit();eq(savedFlag(files),'false')
end)

test('F11 accepts a delayed transition that engages inside the settle window',function()
 local engaged=false
 local love,files=makeLove{setFullscreen=function() return true end,getFullscreen=function() return engaged end}
 local app=assert(findApp())
 love.load({})
 love.keypressed('f11');love.update(1/60)
 settle(love,72)
 engaged=true -- the runtime engages later, still inside the window
 settle(love,60)
 eq(app.settings.fullscreen,true)
 love.quit();eq(savedFlag(files),'true')
end)

test('F11 off then on stays truthful with state-aware native flags',function()
 local love,files=makeLove{stateful=true}
 local app=assert(findApp())
 love.load({})
 love.keypressed('f11');love.update(1/60);settle(love,150)
 eq(app.settings.fullscreen,true)
 love.keypressed('f11');love.update(1/60)
 eq(app.settings.fullscreen,false) -- requested OFF immediately
 settle(love,150);eq(app.settings.fullscreen,false)
 love.quit();eq(savedFlag(files),'false')
end)

test('repeated F11 and Settings toggles track the observed native state',function()
 local love,files=makeLove{stateful=true}
 local app=assert(findApp())
 love.load({})
 love.keypressed('f11');love.update(1/60);settle(love,150)
 eq(app.settings.fullscreen,true)
 love.keypressed('f11');love.update(1/60);settle(love,150)
 eq(app.settings.fullscreen,false)
 openSettingsAtRow(love,app,7)
 love.keypressed('return');love.update(1/60);settle(love,150)
 eq(app.settings.fullscreen,true)
 love.keypressed('return');love.update(1/60);settle(love,150)
 eq(app.settings.fullscreen,false)
 love.quit();eq(savedFlag(files),'false')
end)

test('Settings Enter keeps fullscreen false when the request is rejected',function()
 local love,files=makeLove{setFullscreen=const(false),getFullscreen=const(false)}
 local app=assert(findApp())
 love.load({})
 openSettingsAtRow(love,app,7)
 love.keypressed('return');love.update(1/60)
 eq(app.settings.fullscreen,false)
 settle(love);eq(app.settings.fullscreen,false)
 love.quit();eq(savedFlag(files),'false')
end)

test('Settings Enter prefers the settled state on a working display',function()
 local love,files=makeLove{stateful=true}
 local app=assert(findApp())
 love.load({})
 openSettingsAtRow(love,app,7)
 love.keypressed('return');love.update(1/60)
 settle(love,150);eq(app.settings.fullscreen,true)
 love.quit();eq(savedFlag(files),'true')
end)

test('startup reverts a saved fullscreen preference the runtime rejects',function()
 local love,files=makeLove{setFullscreen=const(false),getFullscreen=const(false)}
 seedSave(files,true,1)
 local app=assert(findApp())
 love.load({})
 eq(app.settings.fullscreen,false) -- rollback uses observed native state, not the stored preference
 settle(love);eq(app.settings.fullscreen,false)
 love.quit();eq(savedFlag(files),'false')
end)

test('startup keeps a saved fullscreen preference the runtime honors',function()
 local love,files=makeLove{stateful=true}
 seedSave(files,true,1)
 local app=assert(findApp())
 love.load({})
 eq(app.settings.fullscreen,true)
 settle(love,150);eq(app.settings.fullscreen,true)
 love.quit();eq(savedFlag(files),'true')
end)

test('rejected pixel size and fullscreen together stay truthful at startup',function()
 local love,files=makeLove{setFullscreen=const(false),getFullscreen=const(false),updateMode=false}
 seedSave(files,true,3)
 local app=assert(findApp())
 love.load({})
 eq(app.settings.pixelSize,1);eq(app.settings.fullscreen,false)
 settle(love);eq(app.settings.pixelSize,1);eq(app.settings.fullscreen,false)
 love.quit();eq(savedFlag(files),'false')
 eq(savedPixel(files),'1')
end)

test('pixel size changed during fullscreen is revalidated and rolled back when it cannot fit',function()
 local love,files=makeLove{simulated=true,desktopW=1512,desktopH=982,maxW=1512,maxH=921}
 local app=assert(findApp())
 love.load({})
 love.keypressed('f11');love.update(1/60);settle(love,150) -- working desktop fullscreen
 eq(app.settings.fullscreen,true)
 app.mode='settings';app.selection=6
 love.keypressed('right');love.update(1/60) -- request 2X while fullscreen (trusted)
 eq(app.settings.pixelSize,2)
 love.keypressed('f11');love.update(1/60);settle(love,150) -- back to windowed; request clamps to 1280x921
 eq(app.settings.fullscreen,false)
 eq(app.settings.pixelSize,1) -- revalidated: the 2X claim cannot fit, rolled back to a truthful 1X
 love.quit();eq(savedPixel(files),'1');eq(savedFlag(files),'false')
end)

test('pixel size changed during fullscreen is kept when the window can realize it',function()
 local love,files=makeLove{simulated=true,desktopW=1512,desktopH=982,maxW=2560,maxH=1600}
 local app=assert(findApp())
 love.load({})
 love.keypressed('f11');love.update(1/60);settle(love,150)
 eq(app.settings.fullscreen,true)
 app.mode='settings';app.selection=6
 love.keypressed('right');love.update(1/60)
 eq(app.settings.pixelSize,2)
 love.keypressed('f11');love.update(1/60);settle(love,150)
 eq(app.settings.fullscreen,false)
 eq(app.settings.pixelSize,2) -- the 2X window fits and stays
 love.quit();eq(savedPixel(files),'2');eq(savedFlag(files),'false')
end)

test('a manually resized window survives a fullscreen toggle unchanged',function()
 local love,files=makeLove{simulated=true,desktopW=1512,desktopH=982,maxW=1512,maxH=921}
 local app=assert(findApp())
 love.load({})
 love.window.updateMode(1500,900) -- manual windowed resize; fits
 love.keypressed('f11');love.update(1/60);settle(love,150)
 love.keypressed('f11');love.update(1/60);settle(love,150)
 local w,h=love.graphics.getDimensions()
 eq(w,1500);eq(h,900) -- preserved, not forced back to the preference size
 eq(app.settings.pixelSize,1);eq(app.settings.fullscreen,false)
 love.quit();eq(savedFlag(files),'false');eq(savedPixel(files),'1')
end)

_G.love=nil
print('ALL '..count..' FULLSCREEN PREFERENCE TESTS PASSED')
