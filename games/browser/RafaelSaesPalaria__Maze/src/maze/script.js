import {Player} from "/entities.js";
import { addKeyEventListener } from "./keyboard.js";
import { move } from "./moviment.js";

let content = {
    canvas : document.querySelector("canvas"),
    c : document.querySelector("canvas").getContext("2d"),
    entities : []
}

content.canvas.width = 900
content.canvas.height = 700

init()
function init() {
    content.entities = []
    content.entities.push(new Player());

    animate()
}

function animate() {
    requestAnimationFrame(animate)
    content.entities.forEach(entity => {
        entity.update(content.c)
    })
}

let a = new addKeyEventListener()
a.add((e) => {move(e)})

