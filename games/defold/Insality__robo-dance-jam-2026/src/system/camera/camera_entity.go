components {
  id: "entity"
  component: "/decore/entity.script"
  properties {
    id: "prefab_id"
    value: "camera"
    type: PROPERTY_TYPE_HASH
  }
  properties {
    id: "size_x"
    value: "1920.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "size_y"
    value: "1080.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "camera"
  type: "camera"
  data: "aspect_ratio: 1.0\n"
  "fov: 1.0\n"
  "near_z: -300.0\n"
  "far_z: 300.0\n"
  "orthographic_projection: 1\n"
  ""
}
