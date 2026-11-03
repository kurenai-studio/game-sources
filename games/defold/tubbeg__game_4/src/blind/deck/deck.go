components {
  id: "deck"
  component: "/blind/deck/deck.script"
}
embedded_components {
  id: "factory"
  type: "factory"
  data: "prototype: \"/blind/card/card.go\"\n"
  ""
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
