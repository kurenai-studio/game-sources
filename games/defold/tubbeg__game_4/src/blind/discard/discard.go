components {
  id: "discard"
  component: "/blind/discard/discard.gui"
}
components {
  id: "discard1"
  component: "/blind/discard/discard.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"back\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/blind/discard/discard.atlas\"\n"
  "}\n"
  ""
}
