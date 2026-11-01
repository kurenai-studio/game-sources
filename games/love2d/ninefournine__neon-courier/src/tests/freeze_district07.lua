-- One-shot baseline freezer for the UNMODIFIED District 07 modules.
-- Run before any refactor: luajit tests/freeze_district07.lua > fixture.lua
-- Emits a plain trusted Lua return table. Never regenerate after the refactor.
package.path='./?.lua;./?/init.lua;'..package.path
local Snapshot=require('tests.helpers.district_snapshot')
local Map=require('game.map')

local out={
 header={
  generated_by='luajit tests/freeze_district07.lua',
  source_commit='0b86429cc18848c178dd05ea7a160c6c013106e3',
  interpreter=(jit and jit.version or _VERSION),
  replay='input {x=1,y=0,boost=frame<=120,emp=frame==300}, dt=1/60, captures 0/60/300/1800',
  note='Frozen District 07 baseline generated from the pre-refactor modules.',
 },
 map=Snapshot.map(Map),
 replays={},
}
for _,seed in ipairs({72891,17,119,9001}) do out.replays[tostring(seed)]=Snapshot.replay(seed) end

local function ser(v,indent)
 local t=type(v)
 if t=='table' then
  local keys={}
  for k in pairs(v) do keys[#keys+1]=k end
  table.sort(keys,function(a,b)
   if type(a)~=type(b) then return type(a)<type(b) end
   return a<b
  end)
  io.write('{\n')
  for _,k in ipairs(keys) do
   io.write(indent..'  [')
   if type(k)=='number' then io.write(k) else io.write(string.format('%q',k)) end
   io.write(']=')
   ser(v[k],indent..'  ')
   io.write(',\n')
  end
  io.write(indent..'}')
 elseif t=='string' then io.write(string.format('%q',v))
 elseif t=='boolean' then io.write(tostring(v))
 elseif t=='number' then
  if v~=v then io.write('0/0')
  elseif v==math.huge then io.write('1/0')
  elseif v==-math.huge then io.write('-1/0')
  elseif math.floor(v)==v and math.abs(v)<2^31 then io.write(tostring(v))
  else io.write(string.format('%.17g',v)) end
 elseif t=='nil' then io.write('nil')
 else io.write(string.format('%q',tostring(v))) end
end

io.write('return ')
ser(out,'')
io.write('\n')
