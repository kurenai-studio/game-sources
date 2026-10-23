// Core game logic for 2048

let boardSize = 4;
let board = [];
let score = 0;
let gameOver = false;

function startGame(newSize) {
    if (typeof newSize === 'number' && newSize !== boardSize) {
        boardSize = newSize;
    }
    board = Array(boardSize)
        .fill(0)
        .map(() => Array(boardSize).fill(0));
    score = 0;
    gameOver = false;
    document.getElementById('message').textContent = '';
    document.getElementById('score').textContent = '0';
    addRandomTile();
    addRandomTile();
    drawBoard();
}

function setBoardSize(size) {
    startGame(size);
}

function addRandomTile() {
    let empty = [];
    for (let r = 0; r < boardSize; r++) {
        for (let c = 0; c < boardSize; c++) {
            if (board[r][c] === 0) empty.push([r, c]);
        }
    }
    if (empty.length === 0) return;
    let [r, c] = empty[Math.floor(Math.random() * empty.length)];
    board[r][c] = Math.random() < 0.9 ? 2 : 4;
}

function slide(row) {
    let arr = row.filter(val => val);
    for (let i = 0; i < arr.length - 1; i++) {
        if (arr[i] === arr[i + 1]) {
            arr[i] *= 2;
            score += arr[i];
            document.getElementById('score').textContent = score;
            arr[i + 1] = 0;
        }
    }
    arr = arr.filter(val => val);
    while (arr.length < boardSize) arr.push(0);
    return arr;
}

function rotateLeft(matrix) {
    let res = Array(boardSize)
        .fill(0)
        .map(() => Array(boardSize).fill(0));
    for (let r = 0; r < boardSize; r++) {
        for (let c = 0; c < boardSize; c++) {
            res[boardSize - c - 1][r] = matrix[r][c];
        }
    }
    return res;
}

function handleMove(dir) {
    if (gameOver) return;
    
    // Store the original board state to check if anything changed
    let oldBoard = JSON.stringify(board);
    
    // Create a deep copy of the board to work with
    let tempBoard = JSON.parse(JSON.stringify(board));
    
    // Handle each direction specifically rather than using rotation
    switch(dir) {
        case 0: // Up
            // Transpose the board (swap rows with columns)
            for (let i = 0; i < boardSize; i++) {
                for (let j = 0; j < i; j++) {
                    let temp = tempBoard[i][j];
                    tempBoard[i][j] = tempBoard[j][i];
                    tempBoard[j][i] = temp;
                }
            }
            // Slide left (which is now up after transpose)
            for (let r = 0; r < boardSize; r++) {
                tempBoard[r] = slide(tempBoard[r]);
            }
            // Transpose back
            for (let i = 0; i < boardSize; i++) {
                for (let j = 0; j < i; j++) {
                    let temp = tempBoard[i][j];
                    tempBoard[i][j] = tempBoard[j][i];
                    tempBoard[j][i] = temp;
                }
            }
            break;
            
        case 1: // Right
            // Reverse each row and slide
            for (let r = 0; r < boardSize; r++) {
                tempBoard[r].reverse();
                tempBoard[r] = slide(tempBoard[r]);
                tempBoard[r].reverse();
            }
            break;
            
        case 2: // Down
            // Transpose the board
            for (let i = 0; i < boardSize; i++) {
                for (let j = 0; j < i; j++) {
                    let temp = tempBoard[i][j];
                    tempBoard[i][j] = tempBoard[j][i];
                    tempBoard[j][i] = temp;
                }
            }
            // Reverse each row, slide, then reverse back
            for (let r = 0; r < boardSize; r++) {
                tempBoard[r].reverse();
                tempBoard[r] = slide(tempBoard[r]);
                tempBoard[r].reverse();
            }
            // Transpose back
            for (let i = 0; i < boardSize; i++) {
                for (let j = 0; j < i; j++) {
                    let temp = tempBoard[i][j];
                    tempBoard[i][j] = tempBoard[j][i];
                    tempBoard[j][i] = temp;
                }
            }
            break;
            
        case 3: // Left
            // Just slide each row
            for (let r = 0; r < boardSize; r++) {
                tempBoard[r] = slide(tempBoard[r]);
            }
            break;
    }
    
    // Only update the actual board if something changed
    if (JSON.stringify(tempBoard) !== oldBoard) {
        board = tempBoard;
        addRandomTile();
        drawBoard();
        if (isGameOver()) {
            document.getElementById('message').textContent = 'Game Over!';
            gameOver = true;
        }
    }
}

function isGameOver() {
    for (let r = 0; r < boardSize; r++) {
        for (let c = 0; c < boardSize; c++) {
            if (board[r][c] === 0) return false; // Found empty cell
            if (c < boardSize - 1 && board[r][c] === board[r][c + 1]) return false; // Found horizontal match
            if (r < boardSize - 1 && board[r][c] === board[r + 1][c]) return false; // Found vertical match
        }
    }
    return true; // No moves left
}
