components {
  id: "game"
  component: "/main/game.script"
}
embedded_components {
  id: "player_factory"
  type: "factory"
  data: "prototype: \"/main/player/player.go\"\n"
  ""
}
embedded_components {
  id: "box_factory"
  type: "factory"
  data: "prototype: \"/main/box/box.go\"\n"
  ""
}
embedded_components {
  id: "target_factory"
  type: "factory"
  data: "prototype: \"/main/target/target.go\"\n"
  ""
}
