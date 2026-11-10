# Minesweeper
Simple minesweeper made with Lua on LOVE2D


tamanhoDoTabuleiro sets the n for our nxn board

numeroDeBombas sets the number of bombs

love.load() is called on initializaion

love.update(dt) and love.draw() are called on every frame

geraMatrizN() creates a n x n matrix. It returns a table with n^2 elements, each with a x and y coordinate, width, height, i and j index, and booleans specifying their usage in-game

alocaBombas() sets the bombs given on coordenadas

dentro() checks if the given i, j indices are valid for our matrix

geraBombas() creates bombs randomly

revelaZeros() revels all adjacent squares with number 0 when one is choosen

coletaInput1() and coletaInput2() checks for clicks with the left and right keys

encontraCasa() gives i and j indicies for a given (x, y) coordinate
