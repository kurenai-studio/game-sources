import './css/main.css'
import {
    createGameArea, getComponentByType
} from './utils'
import {
    colorMap
} from './utils/colorMap'

// canvas holder
const gameHolder = document.querySelector('#gameHolder')
const overlay = document.querySelector('#overlay')

/**
 * Game Object
 * @type {{canvas: HTMLElement, init: Game.init, start: Game.start, clear: Game.clear}}
 */
const Game = {
    canvas: null,
    animationFrameId: null,
    running: null,
    dropCounter: 0,
    level: 1,
    acceleration: 0.02,
    dropInterval: 1000,
    lastRefreshTime: 0,
    score: 0,
    area: null,
    piece: {
        matrix: null,
        offset: { x: 0, y: 0 }
    },
    init: function() {
        // create canvas and inject
        this.canvas = document.createElement('canvas')
        // set dimensions of canvas
        this.canvas.width = gameHolder.clientWidth
        this.canvas.height = gameHolder.clientHeight
        // insert canvas element
        gameHolder.insertAdjacentElement('afterbegin', this.canvas)
        // create game area grid
        this.area = createGameArea(20, 30)
    },
    start: function() {
        // init game
        this.init()
        // get context
        this.context = this.canvas.getContext('2d')
        // scale canvas context
        this.context.scale(20, 20)
        // reset piece to starting point
        this.resetGamePiece()
        // run animation loop
        animate()
        // set running flag to true
        this.running = true
        keyboardControler()
    },
    clear: function() {
        this.context.fillStyle = colorMap[0].bgColor
        this.context.fillRect(0, 0, this.canvas.width, this.canvas.height)
    },
    resetGamePiece() {
        const components = 'IJLOSTZ'
        this.piece.matrix = getComponentByType(components[components.length * Math.random() | 0])
        this.piece.offset.x = (this.area[0].length / 2 | 0) - (this.piece.matrix[0].length / 2 | 0)
        this.piece.offset.y = 0
        if (collide(this.area, this.piece)) {
            this.area.forEach(row => row.fill(0))
            // reset score
            this.score = 0
            this.level = 1
            this.dropInterval = 1000
        }
    }
}

// Definition
function areaSwipe() {
    const gameArea = Game.area
    let rowCount = 1
    outer: for (let y = gameArea.length - 1; y > 0; y--) {
        for (let x = 0; x < gameArea[y].length; x++) {
            if (gameArea[y][x] === 0) {
                continue outer
            }
        }

        let row = gameArea.splice(y, 1)[0].fill(0)
        gameArea.unshift(row)
        y++

        // set score
        Game.score += rowCount * 10
        rowCount *= 2

        // level up on score checkpoint
        if (Game.score > (Math.pow(Game.level, 2) * 1000)) {
            Game.level++
            Game.dropInterval -= Game.dropInterval * Game.acceleration
        }
    }
}

function drawScore(score, level) {
    Game.context.fillStyle = colorMap[0].textColor
    Game.context.textAlign = "end"
    Game.context.font = "0.05rem Arial"
    Game.context.fillText(`Score: ${score} `, 20, 1)
    Game.context.fillStyle = colorMap[0].levelTextColor
    Game.context.textAlign = "end"
    Game.context.font = "0.035rem Arial"
    Game.context.fillText(`Level: ${level} `, 20 , 2)
}

function drawComponent(matrix, offset) {
    matrix.forEach((row, y) => {
        row.forEach((value, x) => {
            if (value !== 0) {
                Game.context.fillStyle = colorMap[value]
                Game.context.fillRect(
                    x + offset.x,
                    y + offset.y,
                    1, 1
                )
            }
        })
    })
}

function collide(gameArea, gamePiece) {
    let { matrix, offset } = gamePiece
    for (let y = 0; y < matrix.length; y++) {
        for (let x = 0; x < matrix[y].length; x++) {
            if (
                matrix[y][x] !== 0 &&
                (gameArea[y + offset.y] &&
                gameArea[y + offset.y][x + offset.x]) !== 0
            ) {
                return true
            }
        }
    }
    return false
}

function merge(gameArea, gamePiece) {
    gamePiece.matrix.forEach((row, y) => {
        row.forEach((value, x) => {
            if (value !== 0) {
                gameArea[y + gamePiece.offset.y][x + gamePiece.offset.x] = value
            }
        })
    })
}

// component movement
function componentDrop() {
    Game.piece.offset.y++
    if (collide(Game.area, Game.piece)) {
        Game.piece.offset.y--
        merge(Game.area, Game.piece)
        Game.resetGamePiece()
        areaSwipe()
    }
    Game.dropCounter = 0
}

function componentMove(offset) {
    Game.piece.offset.x += offset
    if (collide(Game.area, Game.piece)) {
        Game.piece.offset.x -= offset
    }
}

// component rotation
function componentRotate(dir) {
    // current game piece
    let component = Game.piece
    // game grid
    let area = Game.area
    // cache position x on rotate
    let positionX = component.offset.x
    let offset = 1
    rotate(component.matrix, dir)
    while (collide(area, component)) {
        component.offset.x += offset
        offset = -(offset + (offset > 0 ? 1 : -1))
        if (offset > component.matrix[0].length) {
            rotate(component.matrix, -dir)
            component.offset.x = positionX
            return
        }
    }
}

function rotate(matrix, direction) {
    for (let y = 0; y < matrix.length; y++) {
        for (let x = 0; x < y; x++) {
            [
                matrix[x][y],
                matrix[y][x]
            ] = [
                matrix[y][x],
                matrix[x][y]
            ]
        }
    }
    // check direction and complete rotation
    if (direction > 0) {
        matrix.forEach(row => row.reverse())
    } else {
        matrix.reverse()
    }
}


// Implementation
function draw() {
    // clear game area
    Game.clear()


    // draw game area
    drawComponent(Game.area, { x: 0, y: 0 })
    // draw game components
    drawComponent(Game.piece.matrix, Game.piece.offset)

    // draw game score
    drawScore(Game.score, Game.level)

}

// Animation loop
function animate(time = 0) {
    let deltaTime = time - Game.lastRefreshTime
    Game.lastRefreshTime = time
    Game.dropCounter += deltaTime
    // if interval is passed drop down one
    if (Game.dropCounter > Game.dropInterval) {
        componentDrop()
    }

    // init game components and start loop
    draw()
    Game.animationFrameId = requestAnimationFrame(animate)
}


function keyboardControler() {
    // controler event handlers
    document.addEventListener('keydown', (e) => {
        switch (e.keyCode) {
            case 37: // left arrow
                componentMove(-1)
                break
            case 39: // right arrow
                componentMove(1)
                break
            case 40: // down arrow
                componentDrop()
                break
            case 38: // up arrow
                // rotate to right
                componentRotate(1)
                // rotate to left
                // componentRotate(-1)
                break
            case 32: // spacebar
                if (Game.running) {
                    cancelAnimationFrame(Game.animationFrameId)
                    overlay.classList.add('animate-overlay')
                    Game.running = false
                } else {
                    overlay.classList.remove('animate-overlay')
                    animate()
                    Game.running = true
                }
                break
        }
    })
}


document.addEventListener('DOMContentLoaded', () => {
    Game.start()
})
