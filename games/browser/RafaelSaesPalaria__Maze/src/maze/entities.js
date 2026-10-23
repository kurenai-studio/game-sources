class Entity {
    constructor() {
        this.color = "white"
        this.radius = 30
        this.pos = {
            x: 0,
            y: 0
        }
        this.velocity = {
            x : 0,
            y : 0
        }
    }
    draw(c) {
        c.beginPath()
        c.fillStyle = this.color
        c.arc(this.pos.x, this.pos.y, this.radius, 0,Math.PI*2,false)
        c.fill()
        c.strokeStyle = "black"
        c.closePath()
    }
    update(c) {
        this.draw(c)
    }
}

export class Player extends Entity{
    constructor() {
        super()
        this.color = "red"
    }
    update(c) {
        super.update(c)
    }
}