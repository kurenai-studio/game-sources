components {
  id: "arrow"
  component: "/main/components/arrow.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"arrow_right_normal\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/arrows.tilesource\"\n"
  "}\n"
  ""
  position {
    x: -16.0
    y: -16.0
    z: 0.05
  }
}
