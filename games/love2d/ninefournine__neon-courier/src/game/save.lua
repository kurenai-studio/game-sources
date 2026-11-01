local Save={}
function Save.defaults() return {settings={music=.6,sfx=.7,mute=false,shake=true,effects=true,pixelSize=1,fullscreen=false},highscores={}} end
local function number(s,a,b,default) local n=tonumber(s);if not n or n~=n or n<a or n>b then return default end;return n end
function Save.decode(text)
 local out=Save.defaults()
 if type(text)~='string' or #text>8192 or not text:match('^NEON1\n') then return out,false end
 for key,value in text:gmatch('([%w_]+)=([^\n]*)') do
  if key=='music' or key=='sfx' then out.settings[key]=number(value,0,1,out.settings[key])
  elseif key=='mute' or key=='shake' or key=='effects' or key=='fullscreen' then
   if value=='true' or value=='false' then out.settings[key]=value=='true' end
  elseif key=='pixelSize' then out.settings.pixelSize=number(value,1,4,out.settings.pixelSize)
  elseif key=='score' then
   local score,deliveries=value:match('^(%d+),(%d+)$')
   score=number(score,0,9999999,nil);deliveries=number(deliveries,0,1000,nil)
   if score and deliveries and #out.highscores<10 then out.highscores[#out.highscores+1]={score=score,deliveries=deliveries} end
  end
 end
 table.sort(out.highscores,function(a,b)return a.score>b.score end)
 return out,true
end
function Save.encode(data)
 local lines={'NEON1'}
 for _,k in ipairs({'music','sfx','mute','shake','effects','pixelSize','fullscreen'}) do lines[#lines+1]=k..'='..tostring(data.settings[k]) end
 for i,s in ipairs(data.highscores) do if i<=10 then lines[#lines+1]='score='..math.floor(s.score)..','..math.floor(s.deliveries) end end
 return table.concat(lines,'\n')..'\n'
end
function Save.load()
 if not love.filesystem.getInfo('dispatch.sav') then return Save.defaults() end
 local ok,text=pcall(love.filesystem.read,'dispatch.sav');if not ok then return Save.defaults() end
 return Save.decode(text)
end
function Save.store(data)
 local ok,result=pcall(love.filesystem.write,'dispatch.sav',Save.encode(data));return ok and result==true
end
function Save.record(data,s)
 data.highscores[#data.highscores+1]={score=s.score,deliveries=s.delivered}
 table.sort(data.highscores,function(a,b)return a.score>b.score end)
 while #data.highscores>10 do table.remove(data.highscores) end
end
return Save
