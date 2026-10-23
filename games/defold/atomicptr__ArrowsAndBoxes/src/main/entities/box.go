components {
  id: "burnable"
  component: "/main/components/burnable.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"box_wood\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/boxes.tilesource\"\n"
  "}\n"
  ""
  position {
    x: -16.0
    y: -16.0
  }
}
embedded_components {
  id: "fire"
  type: "sprite"
  data: "default_animation: \"fire\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 32.0\n"
  "  y: 32.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/effects.tilesource\"\n"
  "}\n"
  ""
  position {
    x: -16.0
    y: -16.0
    z: 0.02
  }
}
