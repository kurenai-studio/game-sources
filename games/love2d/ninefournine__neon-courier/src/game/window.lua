-- Exact integer pixel scaling for LÖVE windows. Pure at require time so the
-- logic suites run it without LÖVE; LÖVE is only touched inside apply().
local window={base={640,480},max=4}
function window.size(size)
 local n=math.floor(tonumber(size) or 1)
 if n<1 then n=1 elseif n>window.max then n=window.max end
 return window.base[1]*n,window.base[2]*n
end
function window.step(size,direction)
 local n=math.floor(tonumber(size) or 1)+(direction==-1 and -1 or 1)
 if n<1 then n=1 elseif n>window.max then n=window.max end
 return n
end
local function fullscreen()
 if type(love)~='table' or not love.window then return false end
 local ok,fs=pcall(love.window.getFullscreen)
 return ok and fs==true
end
local function settled()
 if type(love)~='table' or not love.graphics then return nil end
 local ok,w,h=pcall(love.graphics.getDimensions)
 if not ok or type(w)~='number' or type(h)~='number' then return nil end
 return w,h
end
-- Returns true only when the requested integer multiple is actually in effect.
-- macOS may clamp an oversized window while updateMode still reports success,
-- so the settled size is verified in windowed mode; desktop fullscreen reports
-- the desktop size and cannot be verified here, so API success is trusted there.
function window.apply(settings)
 if type(love)~='table' or not love.window then return false end
 local w,h=window.size(settings and settings.pixelSize)
 local ok,result=pcall(love.window.updateMode,w,h,{resizable=true})
 if not ok or result~=true then return false end
 if fullscreen() then return true end
 local aw,ah=settled()
 if not aw then return true end
 return aw==w and ah==h
end
return window
