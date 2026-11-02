package com.orangomango.minesweeper;

import javafx.scene.canvas.GraphicsContext;
import javafx.scene.image.Image;

public class DigitDisplay{
	private int digit = -1;

	public static final double WIDTH = 40;
	private static final Image IMAGE = new Image(Cell.class.getResourceAsStream("/display.png"));

	public DigitDisplay(int num){
		this.digit = num;
	}

	public void render(GraphicsContext gc, double x, double y){
		int frameIndex = 0;

		if (digit != -1){
			frameIndex = this.digit+1;
		}

		gc.drawImage(IMAGE, 1+frameIndex*22, 1, 20, 40, x, y, WIDTH, 40*WIDTH/20);
	}
}