LiveObjects = {}
-- we have to use this since the length of LiveObjects fluctuates
LiveObjectID = 0

function addLiveObject(obj)
  if obj == nil then print('you forgot to pass an arg to addLiveObject') end
  LiveObjects[#LiveObjects + 1] = obj
  if obj.spawn ~= nil then obj:spawn() end

  obj.liveObjectIndex = LiveObjectID

  LiveObjectID = LiveObjectID + 1
end

function removeLiveObject(index)
  for i=1,#LiveObjects do
    local obj = LiveObjects[i]
    if obj.liveObjectIndex == index then
      if obj.die ~= nil then
        obj:die()
      end
      table.remove(LiveObjects,i)
      break
    end
  end
end
