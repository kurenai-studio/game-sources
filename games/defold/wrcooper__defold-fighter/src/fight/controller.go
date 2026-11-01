components {
  id: "fight"
  component: "/fight/fight.script"
}
components {
  id: "hud"
  component: "/fight/hud.gui"
}
embedded_components {
  id: "fireball_factory"
  type: "factory"
  data: "prototype: \"/fight/fireball.go\"\n"
}
embedded_components {
  id: "fx_factory"
  type: "factory"
  data: "prototype: \"/fight/fx.go\"\n"
}
embedded_components {
  id: "box_factory"
  type: "factory"
  data: "prototype: \"/fight/box.go\"\n"
}
embedded_components {
  id: "sfx_block"
  type: "sound"
  data: "sound: \"/assets/sounds/block.wav\"\n"
}
embedded_components {
  id: "sfx_confirm"
  type: "sound"
  data: "sound: \"/assets/sounds/confirm.wav\"\n"
}
embedded_components {
  id: "sfx_fight"
  type: "sound"
  data: "sound: \"/assets/sounds/fight.wav\"\n"
}
embedded_components {
  id: "sfx_fireball"
  type: "sound"
  data: "sound: \"/assets/sounds/fireball.wav\"\n"
}
embedded_components {
  id: "sfx_hit_heavy"
  type: "sound"
  data: "sound: \"/assets/sounds/hit_heavy.wav\"\n"
}
embedded_components {
  id: "sfx_hit_light"
  type: "sound"
  data: "sound: \"/assets/sounds/hit_light.wav\"\n"
}
embedded_components {
  id: "sfx_jump"
  type: "sound"
  data: "sound: \"/assets/sounds/jump.wav\"\n"
}
embedded_components {
  id: "sfx_ko"
  type: "sound"
  data: "sound: \"/assets/sounds/ko.wav\"\n"
}
embedded_components {
  id: "sfx_select"
  type: "sound"
  data: "sound: \"/assets/sounds/select.wav\"\n"
}
embedded_components {
  id: "sfx_thud"
  type: "sound"
  data: "sound: \"/assets/sounds/thud.wav\"\n"
}
embedded_components {
  id: "sfx_whoosh"
  type: "sound"
  data: "sound: \"/assets/sounds/whoosh.wav\"\n"
}
