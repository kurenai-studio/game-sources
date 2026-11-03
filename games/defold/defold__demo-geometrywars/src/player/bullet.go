components {
  id: "script"
  component: "/player/bullet.script"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"bullet\"\n"
  "mask: \"level\"\n"
  "mask: \"enemy\"\n"
  "mask: \"black_hole\"\n"
  "mask: \"force_field\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      x: -0.59210527\n"
  "      y: 0.15719143\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 5.263158\n"
  "  data: 7.629447\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "factory"
  type: "factory"
  data: "prototype: \"/player/bullet_impact.go\"\n"
  ""
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"anim\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/player/bullet.tilesource\"\n"
  "}\n"
  ""
  position {
    y: 4.0450764
  }
}
embedded_components {
  id: "sprite2"
  type: "sprite"
  data: "default_animation: \"anim\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/player/bullet.tilesource\"\n"
  "}\n"
  ""
  position {
    y: -4.600358
  }
}
