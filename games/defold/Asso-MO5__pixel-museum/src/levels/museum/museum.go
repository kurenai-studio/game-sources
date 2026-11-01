components {
  id: "museum"
  component: "/levels/museum/museum.tilemap"
  position {
    x: -0.035505507
    y: -1.1357208
  }
}
components {
  id: "museum1"
  component: "/levels/museum/museum.script"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "collision_shape: \"/levels/museum/museum.tilemap\"\n"
  "type: COLLISION_OBJECT_TYPE_STATIC\n"
  "mass: 0.0\n"
  "friction: 0.0\n"
  "restitution: 0.0\n"
  "group: \"\"\n"
  "mask: \"sagwa\"\n"
  ""
}
