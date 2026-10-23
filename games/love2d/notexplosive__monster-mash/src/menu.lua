MENU = {
  x=152,y=50,
  selectedItem = 1
}

-- sprite component added in load

function MENU:draw()
  if not MENU_OPEN then return end
  scales = {1,1,1}
  if self.selectedItem ~= 0 then
    scales[self.selectedItem] = 1.1
  end
  self.sprite:renderFrame(1,self.x+16,self.y+16,scales[1])
  self.sprite:renderFrame(2,self.x+16+32,self.y+16,scales[2])
  self.sprite:renderFrame(3,self.x+16+64,self.y+16,scales[3])
end

addLiveObject(MENU)
