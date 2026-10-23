# JavaScript and Canvas API Conway's Game of Life Implementation

This project is my personal implementation of the famous [Game of Life (read about it here)](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) cellular automaton created by mathematician John Conway.
In essence there are cells in a matrix with a binary state attached to them, alive, or dead. Cells that are alive and have less than two alive neighbors die of "loneliness". If the cell is alive and has two or three alive neighbors
then it lives. If an alive cell has more than three neighbors it dies of overcrowding, and if a dead cell has three neighbors it is born again.
It was written in Javascript and utilizes the canvas API to draw simple 2D graphics of the cells (canvas really simplifies this!). I made this after learning about the game of life on a wiki walk and thinking how **easy** and fun it would be to implement using 
canvas in the browser. Currently, the implementation has the following features:

## Features

* A pause/unpause button to temporarily stop the simulation or resume it
* A randomize button to randomly place alive/dead cells on the current gameboard
* A clear button to clear the gameboard of alive cells
* A slider to change the speed of the simulation (speed may vary on your own hardware)
* Grid to more easily denote dead and alive cells
* Draw alive cells on the gameboard while paused

## Planned Features

I plan on adding additional features as time goes on; however, this current version is stable
and works well from what I have tested. The following features are planned:

* ~~Render a background grid on the canvas so the division of the cells in the simulation is more apparent~~
* ~~Add a mode where you can paint cell patterns on the grid to change the initial state/currently paused state~~
* ~~Optimizations to the game logic by making the conditionals and loops for checking alive neighbor cells and boundary conditions into a series of simple adding operations~~
* ~~A clear button to get rid of all alive cells on the board~~
* ~~Beautify the webpage and make it easy on the eyes~~
* Give the observer the ability to change the color of the alive and dead cells on the grid
* Improve drawing functionality

## How To Install

You can either clone the repository by typing `git clone https://github.com/Neuro-mancer/canvas-game-of-life` or download the .js and .html files directly, making sure they are in the same directory. 
Then, open the .html file with your browser.

## How To Use

Currently the start/restart buttons initialize and populate the game board with a random selection of alive and dead cells. Once this has been pressed, you can then press pause/unpause to start the simulation.
The slider controls the speed of the simulation, although how fast you can go will largely depend on your computer's hardware.
