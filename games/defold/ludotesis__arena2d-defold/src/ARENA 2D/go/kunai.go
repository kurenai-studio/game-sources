components {
  id: "kunai"
  component: "/scripts/kunai.script"
  properties {
    id: "velocidad"
    value: "200.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"Kunai\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/atlas/jugador.atlas\"\n"
  "}\n"
  ""
  rotation {
    z: -0.38268343
    w: 0.9238795
  }
  scale {
    x: 0.5
    y: 0.5
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"armas\"\n"
  "mask: \"mapa\"\n"
  "mask: \"enemigo\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      x: 1.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 1.75\n"
  "}\n"
  ""
}
