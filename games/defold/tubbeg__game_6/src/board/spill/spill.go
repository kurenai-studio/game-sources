components {
  id: "spill"
  component: "/board/spill/spill.script"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"spill\"\n"
  "mask: \"bone\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 164.70892\n"
  "}\n"
  ""
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"bone13\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/board/spill/spill.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 4.0
    y: 4.0
  }
}
