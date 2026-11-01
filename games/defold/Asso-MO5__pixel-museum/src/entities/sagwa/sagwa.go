components {
  id: "sagwa"
  component: "/entities/sagwa/sagwa.script"
}
components {
  id: "hat"
  component: "/entities/sagwa/hat.sprite"
  position {
    x: 0.161057
    y: 0.027417
    z: 1.1
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"idle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/entities/sagwa/sagwa.tilesource\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "sagwacol"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"sagwa\"\n"
  "mask: \"ground\"\n"
  "mask: \"enemy\"\n"
  "mask: \"respawn\"\n"
  "mask: \"solid\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      y: -11.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 1\n"
  "    count: 3\n"
  "  }\n"
  "  data: 8.0\n"
  "  data: 5.3814387\n"
  "  data: 10.0\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
