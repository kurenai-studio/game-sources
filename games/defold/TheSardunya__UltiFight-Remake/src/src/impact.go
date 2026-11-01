components {
  id: "vfx"
  component: "/assets/scripts/vfx.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"CircleImpactFX\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/sprites/vfx.tilesource\"\n"
  "}\n"
  ""
  position {
    z: 0.999
  }
  scale {
    x: 0.9
    y: 0.9
  }
}
