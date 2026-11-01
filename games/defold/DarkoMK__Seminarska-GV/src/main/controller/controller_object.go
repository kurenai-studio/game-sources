components {
  id: "controller_script"
  component: "/main/controller/controller.script"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "bg_sound"
  type: "sound"
  data: "sound: \"/main/sounds/random silly chip song.ogg\"\nlooping: 1\ngroup: \"master\"\ngain: 1.0\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "click_sound"
  type: "sound"
  data: "sound: \"/main/sounds/click.wav\"\nlooping: 0\ngroup: \"master\"\ngain: 1.0\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "collect_sound"
  type: "sound"
  data: "sound: \"/main/sounds/collect.wav\"\nlooping: 0\ngroup: \"master\"\ngain: 1.0\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "gameproxy"
  type: "collectionproxy"
  data: "collection: \"/main/main.collection\"\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "jump_sound"
  type: "sound"
  data: "sound: \"/main/sounds/jump.ogg\"\nlooping: 0\ngroup: \"master\"\ngain: 1.0\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "menuproxy"
  type: "collectionproxy"
  data: "collection: \"/main/menu/menu.collection\"\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "pcollect_sound"
  type: "sound"
  data: "sound: \"/main/sounds/pcollect.wav\"\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
