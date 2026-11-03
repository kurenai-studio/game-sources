components {
  id: "StarSystem"
  component: "/main/Galaxy/StarSystem/StarSystem.script"
}
components {
  id: "Etoile"
  component: "/Sprites/Etoile.sprite"
}
components {
  id: "Etoile_proche"
  component: "/Sprites/Etoile_proche.sprite"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"StarSystem\"\n"
  "mask: \"Curseur\"\n"
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
  "  data: 16.0\n"
  "}\n"
  ""
}
