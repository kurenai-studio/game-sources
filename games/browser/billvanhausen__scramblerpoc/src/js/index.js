"use strict";

const game_board = document.getElementById("game_board");
const game_image = document.getElementById("game_image");
const game_size = 3;
let tiles = [];

class GameTile{
    index = 0;
    source = {x:0, y:0, width:0, height:0};
    destination = {x:0, y:0, width:0, height:0};
    position = {row: 0, column: 0};

    constructor(){
    }

    setSource(x, y, w, h){
        this.source.x = x;
        this.source.y = y;
        this.source.width = w;
        this.source.height = h;
    }

    setDestination(x, y, w, h){
        this.destination.x = x;
        this.destination.y = y;
        this.destination.width = w;
        this.destination.height = h;
    }

    setPosition(row, col){
        this.position.row = row;
        this.position.column = col;
    }
}

function drawBoard(){
    // console.log("Drawing Board");
    let context = game_board.getContext("2d");
    context.clearRect(0, 0, game_board.width, game_board.height);

    tiles.forEach((game_tile) => {
        context.drawImage(
            game_image, 
            game_tile.source.x, 
            game_tile.source.y, 
            game_tile.source.width, 
            game_tile.source.height, 
            game_tile.destination.x, 
            game_tile.destination.y, 
            game_tile.destination.width, 
            game_tile.destination.height);
    });
}

function swapTiles(target, empty){
    console.log(target.index);
    tiles[target.index].destination.x = empty.destination.x;
    tiles[target.index].destination.y = empty.destination.y;
    tiles[target.index].position.row = empty.position.row;
    tiles[target.index].position.column = empty.position.column;
    
    console.log(empty.index);
    tiles[empty.index].destination.x = target.destination.x;
    tiles[empty.index].destination.y = target.destination.y;
    tiles[empty.index].position.row = target.position.row;
    tiles[empty.index].position.column = target.position.column;

    console.log(tiles);

    drawBoard();
}

function handleClick(e, size){
    let rect = game_board.getBoundingClientRect();
    let targetX = Math.trunc(event.clientX - rect.left);
    let targetY = Math.trunc(event.clientY - rect.top);

    let row = Math.floor(targetY / size);
    let column = Math.floor(targetX / size);
    
    let target_tile = tiles.find(t => (t.position.row == row && t.position.column == column));
    let empty_tile = tiles.at(-1);

    let row_check = Math.abs(target_tile.position.row - empty_tile.position.row);
    let col_check = Math.abs(target_tile.position.column - empty_tile.position.column);

    // If you click the empty tile, do nothing
    if(row_check == 0 && col_check == 0){ return; }

    // If the tiles are next to each other, swap them
    if((row_check == 0 && col_check < 2) || (col_check == 0 && row_check < 2)){
        swapTiles(target_tile, empty_tile);
    }
}

// Game Manager
(function(doc){
    let img_size = Math.trunc(game_image.width/3);
    let tile_size = Math.trunc(game_board.width/3);
    let x,y,w,h;
    let i = 0;

    // Initialize tiles
    for(let rows = 0; rows < game_size; rows++){
        for(let cols = 0; cols < game_size; cols++){
            let t = new GameTile();
            t.index = i;
            x = rows * img_size;
            y = cols * img_size;
            w = img_size;
            h = img_size;
            t.setSource(x, y, w, h);
            
            x = rows * tile_size;
            y = cols * tile_size;
            w = tile_size;
            h = tile_size;
            t.setDestination(x, y, w, h);
            
            t.setPosition(rows, cols);

            tiles.push(t);
            i++;
        }
    }

    drawBoard();
    game_board.addEventListener("click", function(event){
        handleClick(event, tile_size);
    });

 })(document);