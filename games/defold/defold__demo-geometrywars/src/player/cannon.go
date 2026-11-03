components {
  id: "script"
  component: "/player/cannon.script"
}
embedded_components {
  id: "factory"
  type: "factory"
  data: "prototype: \"/player/bullet.go\"\n"
  ""
}
embedded_components {
  id: "sound"
  type: "sound"
  data: "sound: \"/player/Shot3.wav\"\n"
  ""
}
