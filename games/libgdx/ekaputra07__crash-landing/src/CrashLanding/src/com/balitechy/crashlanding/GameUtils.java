package com.balitechy.crashlanding;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.scenes.scene2d.ui.Label.LabelStyle;

public class GameUtils {
	
	private static BitmapFont font;
	
	public static float getScreenWidth(){
		return Gdx.graphics.getWidth();
	}
	
	public static float getScreenHeight(){
		return Gdx.graphics.getHeight();
	}
	
	public static String getScoreBoardText(long startTime, long currentTime){
		long deltaMilis = currentTime - startTime;
		long second = deltaMilis / 1000;
		long minute = second/60;
		String minute_text, second_text;
		
		if(minute < 10)
			minute_text = "0" + Long.toString(minute);
		else
			minute_text = Long.toString(minute);
		
		if(second%60 < 10)
			second_text = "0" + Long.toString(second%60);
		else
			second_text = Long.toString(second%60);
		
		return "Time : " + minute_text + ":" + second_text +":" + deltaMilis%1000/10;
	}
	
	public static LabelStyle labelStyle(){
		font = new BitmapFont(Gdx.files.internal("data/whitefont.fnt"), false);
		LabelStyle ls = new LabelStyle(font, Color.WHITE);
		return ls;
	}
}