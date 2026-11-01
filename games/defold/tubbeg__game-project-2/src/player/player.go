components {
  id: "player"
  component: "/player/player.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"banana\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 128.0\n"
  "  y: 128.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/player/player.atlas\"\n"
  "}\n"
  ""
  rotation {
    z: -0.5476839
    w: 0.83668536
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"heroes\"\n"
  "mask: \"enemies\"\n"
  "mask: \"bounds_x\"\n"
  "mask: \"bounds_y\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 10.0\n"
  "  data: 10.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "factory"
  type: "factory"
  data: "prototype: \"/bullet/bullet.go\"\n"
  ""
}
