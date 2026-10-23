/**
 * Create empty grid for drawing game pieces
 * @param w Width of grid
 * @param h Heigth of grid
 * @returns {Array}
 */
export function createGameArea(w, h) {
    let grid = []
    while (h--) {
        grid.push(Array(w).fill(0))
    }

    return grid
}

/**
 * Returns drawing map of tetramino by type
 * @param type String letter of tetramino look
 * @returns {number[][]}
 */
export function getComponentByType(type) {
    switch (type) {
        case 'T':
            return [
                [0, 0, 0],
                [1, 1, 1],
                [0, 1, 0]
            ]
            break
        case 'O':
            return [
                [2, 2],
                [2, 2]
            ]
        case 'Z':
            return [
                [3, 3, 0],
                [0, 3, 3],
                [0, 0, 0]
            ]
        case 'S':
            return [
                [0, 4, 4],
                [4, 4, 0],
                [0, 0, 0]
            ]
        case 'I':
            return [
                [0, 5, 0, 0],
                [0, 5, 0, 0],
                [0, 5, 0, 0],
                [0, 5, 0, 0]
            ]
        case 'L':
            return [
                [0, 6, 0],
                [0, 6, 0],
                [0, 6, 6]
            ]
        case 'J':
            return [
                [0, 7, 0],
                [0, 7, 0],
                [7, 7, 0]
            ]
    }
}



/**
 * Returns random color from passed array of colors
 * @param colors Array of colors
 * @returns {String}
 */
/*
export function randomColor(colors) {
    return colors[Math.floor(Math.random() * colors.length)]
}

export function distance(x1, y1, x2, y2) {
// calculate points distance
const xDist = x2 - x1
const yDist = y2 - y1

// return distance(hypotenuse)
return Math.sqrt(Math.pow(xDist * 2) + Math.pow(yDist * 2))
}

export function randomNumber(min, max) {
return Math.floor(Math.random() * (max - min + 1) + min)
}
*/

