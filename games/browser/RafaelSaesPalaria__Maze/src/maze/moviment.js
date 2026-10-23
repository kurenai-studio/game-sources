let keys = {
    up: "w",
    down: "s",
    left: "a",
    right: "d"
}
let directions = {
    up : false,
    down: false,
    left: false,
    right: false
}
export function move(e) {
    for (let key in keys) {
        if (e.key===keys[key]) {
            directions[key] = !(e.type==="keyup")
        }
    }
    
    let y = (directions.up - directions.down)
    let x = (directions.left- directions.right)
    
    console.log("X:"+x,"Y:"+y)
    return {x,y}
}