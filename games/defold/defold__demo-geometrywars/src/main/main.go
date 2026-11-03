components {
  id: "intro"
  component: "/gui/intro.gui"
}
components {
  id: "outro"
  component: "/gui/outro.gui"
}
components {
  id: "script"
  component: "/main/main.script"
}
embedded_components {
  id: "sound"
  type: "sound"
  data: "sound: \"/gui/Wall1.wav\"\n"
  "gain: 0.1\n"
  ""
}
embedded_components {
  id: "stage"
  type: "collectionproxy"
  data: "collection: \"/level/stage.collection\"\n"
  ""
}
