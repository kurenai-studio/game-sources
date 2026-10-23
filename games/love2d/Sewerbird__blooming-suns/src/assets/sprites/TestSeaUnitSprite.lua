local sprite = {
  spritesheet = "units", --tileset reference
  sprite_name = "TestSeaUnit", --name of this sprite
  frame_duration = nil, --speed of animation
  scale_x = 1.0,
  scale_y = 1.0,
  animations = {  --arrays of quads
    idle = {
      {96, 40, 48, 40}
    },
    selected = {
      {96, 40, 48, 40},
      {0, 0, 1, 1}
    }
  }
}
return sprite
