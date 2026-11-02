package com.orangomango.minesweeper;

import javafx.scene.canvas.GraphicsContext;

public class Map{
	private int w, h;
	private Cell[][] map;

	public Map(int w, int h){
		this.w = w;
		this.h = h;
		this.map = new Cell[this.w][this.h];

		for (int i = 0; i < this.w; i++){
			for (int j = 0; j < this.h; j++){
				this.map[i][j] = new Cell(i, j, false);
			}
		}
	}

	public int buildMines(int x, int y){
		int count = 0;
		for (int i = 0; i < this.w; i++){
			for (int j = 0; j < this.h; j++){
				if (!inArea(i, j, x, y)){
					this.map[i][j].setMine(Math.random() < 0.2);
					if (this.map[i][j].isMine()){
						count++;
					}
				}
			}
		}

		return count;
	}

	private boolean inArea(int x, int y, int ax, int ay){
		return x >= ax-1 && x <= ax+1 && y >= ay-1 && y <= ay+1;
	}

	public boolean isFinished(){
		for (int i = 0; i < this.w; i++){
			for (int j = 0; j < this.h; j++){
				Cell cell = this.map[i][j];
				if ((cell.getRevealed() == -1 && !cell.isMine()) || (cell.isMine() && !cell.isFlag())){
					return false;
				}
			}
		}

		return true;
	}

	public Cell getCellAt(int x, int y){
		if (x >= 0 && y >= 0 && x < this.w && y < this.h){
			return this.map[x][y];
		} else {
			return null;
		}
	}

	public void render(GraphicsContext gc, boolean showMines){
		for (int i = 0; i < this.w; i++){
			for (int j = 0; j < this.h; j++){
				Cell cell = this.map[i][j];
				cell.render(gc, showMines);
			}
		}
	}

	public int getWidth(){
		return this.w;
	}

	public int getHeight(){
		return this.h;
	}
}