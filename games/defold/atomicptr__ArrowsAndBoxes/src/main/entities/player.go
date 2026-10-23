components {
  id: "player"
  component: "/main/components/player.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"idle_right\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/player.tilesource\"\n"
  "}\n"
  ""
  position {
    x: -16.0
    y: -8.0
    z: 0.05
  }
}
