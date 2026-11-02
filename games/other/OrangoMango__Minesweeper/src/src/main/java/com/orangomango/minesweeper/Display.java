package com.orangomango.minesweeper;

import javafx.scene.canvas.GraphicsContext;

public class Display{
	private double x, y;
	private DigitDisplay[] digits;

	public Display(double x, double y, int digits, int num){
		this.x = x;
		this.y = y;
		this.digits = new DigitDisplay[digits];

		if (num == -1){
			for (int i = 0; i < this.digits.length; i++){
				this.digits[i] = new DigitDisplay(-1);
			}
		} else {
			update(num);
		}
	}

	public void update(int num){
		if (num < 0){
			for (int i = 0; i < this.digits.length; i++){
				this.digits[i] = new DigitDisplay(-1);
			}
		} else {
			String numString = Integer.toString(num);
			if (numString.length() < this.digits.length){
				numString = "0".repeat(this.digits.length-numString.length())+numString;
			} else if (numString.length() > this.digits.length){
				this.digits = new DigitDisplay[numString.length()];
				for (int i = 0; i < numString.length(); i++){
					this.digits[i] = new DigitDisplay(-1);
				}
			}

			for (int i = 0; i < this.digits.length; i++){
				this.digits[i] = new DigitDisplay(Integer.parseInt(String.valueOf(numString.charAt(i))));
			}
		}
	}

	public void render(GraphicsContext gc){
		for (int i = 0; i < this.digits.length; i++){
			DigitDisplay display = this.digits[i];
			display.render(gc, this.x+(DigitDisplay.WIDTH+5)*i, this.y);
		}
	}
}