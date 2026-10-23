// Main script for initialization, rendering, and input handling

function drawBoard() {
    const boardDiv = document.getElementById('game-board');
    boardDiv.innerHTML = '';
    const theme = themes[currentTheme];
    
    for (let r = 0; r < boardSize; r++) {
        for (let c = 0; c < boardSize; c++) {
            const value = board[r][c];
            const tile = document.createElement('div');
            tile.className = 'tile' + (value ? ' x' + value : '');
            
            if (value === 0) {
                // Empty tile
                tile.textContent = '';
            } else if (theme.type === 'color') {
                // Color-based theme
                tile.textContent = value;
                if (theme.values[value]) {
                    tile.style.backgroundColor = theme.values[value];
                }
            } else if (theme.type === 'image') {
                // Image-based theme
                tile.textContent = ''; // Clear the text
                
                if (theme.values[value]) {
                    if (theme.background) {
                        tile.style.backgroundColor = theme.background;
                    }
                    
                    const img = document.createElement('img');
                    const imagePath = (theme.path || 'images/') + theme.values[value];
                    img.src = imagePath;
                    img.alt = value.toString();
                    img.className = 'tile-image';
                    
                    tile.dataset.value = value;
                    
                    tile.appendChild(img);
                }
            }
            
            boardDiv.appendChild(tile);
        }
    }
}

// Handle keyboard input for moves
document.addEventListener('keydown', function(event) {
    if (gameOver) return;
    
    // Prevent default arrow key scrolling
    if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.key)) {
        event.preventDefault();
    }
    
    switch (event.key) {
        case 'ArrowUp':
            handleMove(0); // dir 0 = up
            break;
        case 'ArrowRight':
            handleMove(1); // dir 1 = right
            break;
        case 'ArrowDown':
            handleMove(2); // dir 2 = down
            break;
        case 'ArrowLeft':
            handleMove(3); // dir 3 = left
            break;
    }
});

// Board size radio event handler
function setupBoardSizeRadios() {
    const radios = document.querySelectorAll('input[name="board-size"]');
    radios.forEach(radio => {
        radio.addEventListener('change', function() {
            const size = parseInt(this.value, 10);
            setBoardSize(size);
            updateBoardGrid(size);
        });
    });
}

// Dynamically update the CSS grid for the board size
function updateBoardGrid(size) {
    // Fixed board size (in px)
    const BOARD_SIZE_PX = 600;
    const GAP = 5; // px, should match CSS
    const tileSize = Math.floor((BOARD_SIZE_PX - GAP * (size - 1)) / size);
    const boardDiv = document.getElementById('game-board');
    boardDiv.style.width = `${BOARD_SIZE_PX}px`;
    boardDiv.style.height = `${BOARD_SIZE_PX}px`;
    boardDiv.style.gridTemplateColumns = `repeat(${size}, ${tileSize}px)`;
    boardDiv.style.gridTemplateRows = `repeat(${size}, ${tileSize}px)`;
    // Set tile size via CSS variable for use in .tile
    boardDiv.style.setProperty('--tile-size', `${tileSize}px`);
}

// Dark mode toggle logic
function setupDarkModeToggle() {
    const toggleBtn = document.getElementById('dark-mode-toggle');
    const body = document.body;
    // Set initial mode from localStorage or system preference
    let darkMode = localStorage.getItem('darkMode');
    if (darkMode === null) {
        darkMode = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'true' : 'false';
    }
    if (darkMode === 'true') {
        body.classList.add('dark-mode');
        toggleBtn.textContent = '☀️ Light Mode';
    } else {
        body.classList.remove('dark-mode');
        toggleBtn.textContent = '🌙 Dark Mode';
    }
    toggleBtn.onclick = function() {
        body.classList.toggle('dark-mode');
        const isDark = body.classList.contains('dark-mode');
        toggleBtn.textContent = isDark ? '☀️ Light Mode' : '🌙 Dark Mode';
        localStorage.setItem('darkMode', isDark);
    };
}

// Initialize the game when the page loads
window.onload = function() {
    startGame();
    renderThemeButtons();
    setupDarkModeToggle();
    setupBoardSizeRadios();
    updateBoardGrid(boardSize);
};
