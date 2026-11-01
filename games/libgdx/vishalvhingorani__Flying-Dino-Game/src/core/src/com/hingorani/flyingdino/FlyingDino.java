package com.hingorani.flyingdino;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Intersector;
import com.badlogic.gdx.math.Rectangle;

import java.util.ArrayList;
import java.util.Random;

public class FlyingDino extends ApplicationAdapter {
	SpriteBatch batch;
	Texture background;
	Texture[] man;
	Texture[] dead;
	Texture[] coinmap;
	Texture dizzy;
	int manstate = 0;

	int deadstate = 0;
	int pause = 0;
	boolean gameOver = false;
	float gravity = 0.4f;
	float velocity = 0f;
	int manY = 0;
	Random random;
	BitmapFont font;
	ArrayList<Integer> coinY = new ArrayList<>();
	ArrayList<Integer> coinX = new ArrayList<>();
	ArrayList<Rectangle> coinRectangles = new ArrayList<>();
	Texture coin;
	int coincount = 0;

	ArrayList<Integer>bombY = new ArrayList<>();
	ArrayList<Integer>bombX = new ArrayList<>();
	ArrayList<Rectangle> bombRectangles = new ArrayList<>();
	Texture bomb;
	int bombcount = 0;
	Rectangle manRectangle;

	int coinpause = 0;
	int score = 0;
	int gamestate = 0;

	@Override
	public void create () {
		batch = new SpriteBatch();
		background = new Texture("bg.png");
		man = new Texture[8];
		man[0] = new Texture("run-1.png");
		man[1] = new Texture("run-2.png");
		man[2] = new Texture("run-3.png");
		man[3] = new Texture("run-4.png");
		man[4] = new Texture("run-5.png");
		man[5] = new Texture("run-6.png");
		man[6] = new Texture("run-7.png");
		man[7] = new Texture("run-8.png");
		manY = Gdx.graphics.getHeight()/2;

		dead = new Texture[8];
		dead[0] = new Texture("dead-1.png");
		dead[1] = new Texture("dead-2.png");
		dead[2] = new Texture("dead-3.png");
		dead[3] = new Texture("dead-4.png");
		dead[4] = new Texture("dead-5.png");
		dead[5] = new Texture("dead-6.png");
		dead[6] = new Texture("dead-7.png");
		dead[7] = new Texture("dead-8.png");

		coinmap = new Texture[24];
		coinmap[0] = new Texture("coin-1.png");
		coinmap[1] = new Texture("coin-1.png");
		coinmap[2] = new Texture("coin-1.png");
		coinmap[3] = new Texture("coin-1.png");
		coinmap[4] = new Texture("coin-2.png");
		coinmap[5] = new Texture("coin-2.png");
		coinmap[6] = new Texture("coin-2.png");
		coinmap[7] = new Texture("coin-2.png");
		coinmap[8] = new Texture("coin-3.png");
		coinmap[9] = new Texture("coin-3.png");
		coinmap[10] = new Texture("coin-3.png");
		coinmap[11] = new Texture("coin-3.png");
		coinmap[12] = new Texture("coin-4.png");
		coinmap[13] = new Texture("coin-4.png");
		coinmap[14] = new Texture("coin-4.png");
		coinmap[15] = new Texture("coin-4.png");
		coinmap[16] = new Texture("coin-5.png");
		coinmap[17] = new Texture("coin-5.png");
		coinmap[18] = new Texture("coin-5.png");
		coinmap[19] = new Texture("coin-5.png");
		coinmap[20] = new Texture("coin-6.png");
		coinmap[21] = new Texture("coin-6.png");
		coinmap[22] = new Texture("coin-6.png");
		coinmap[23] = new Texture("coin-6.png");

		coin = new Texture("coin.png");
		bomb = new Texture("bomb.png");
		random = new Random();

		font = new BitmapFont();
		font.setColor(Color.WHITE);
		font.getData().setScale(10);


	}

	public void makecoin(){
		float height = random.nextFloat() * Gdx.graphics.getHeight();
		coinY.add((int) height);
		coinX.add(Gdx.graphics.getWidth());
	}

	public void makebomb(){
		float height = random.nextFloat() * Gdx.graphics.getHeight();
		bombY.add((int) height);
		bombX.add(Gdx.graphics.getWidth());
	}

	@Override
	public void render () {
		//This method operates in a loop and gets called over and over again
		Gdx.gl.glClearColor(1,1,1,1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
		batch.begin();
		batch.draw(background,0,0,Gdx.graphics.getWidth(),Gdx.graphics.getHeight());


		if(gamestate==1){
			if (bombcount < 200) {
				bombcount++;
			} else {
				bombcount = 0;
				makebomb();
			}
			bombRectangles.clear();
			for (int i=0;i < bombX.size();i++) {
				batch.draw(bomb, bombX.get(i), bombY.get(i));
				bombX.set(i, bombX.get(i) - 8);
				bombRectangles.add(new Rectangle(bombX.get(i), bombY.get(i), bomb.getWidth(), bomb.getHeight()));
			}


			if (coincount < 75) {
				coincount++;
			} else {
				coincount = 0;
				makecoin();
			}
			coinRectangles.clear();
			for (int i=0;i < coinX.size();i++) {
				if(coinpause==24){
					coinpause=0;
				}
				batch.draw(coinmap[coinpause], coinX.get(i), coinY.get(i));
				coinpause++;
				coinX.set(i, coinX.get(i) - 6);
				coinRectangles.add(new Rectangle(coinX.get(i), coinY.get(i), coin.getWidth(), coin.getHeight()));
			}

			if(Gdx.input.justTouched()){
				velocity = -14;
			}

			if (pause<4){
				pause++;
			}
			else {
				pause = 0;
				if(manstate<7){
					manstate++;
				}
				else {
					manstate = 0;
				}
			}
			velocity += gravity;
			manY -= velocity;

			if(manY<200){
				manY = 200;
			}
			else if(manY>(Gdx.graphics.getHeight()-(Gdx.graphics.getHeight()*0.1))){
				manY= (int) (Gdx.graphics.getHeight()-(Gdx.graphics.getHeight()*0.1));
			}
		}else if(gamestate == 0){
			if (Gdx.input.justTouched()){
				gamestate=1;
				score = 0;
			}
		}
		else if (gamestate == 2 && gameOver){
			manY = Gdx.graphics.getHeight()/2;
			velocity = 0;
			coinX.clear();
			coinY.clear();
			coinRectangles.clear();
			coincount = 0;
			bombX.clear();
			bombY.clear();
			bombRectangles.clear();
			bombcount = 0;
			if (Gdx.input.justTouched()){
				gamestate=1;
				score = 0;
				deadstate = 0;
				gameOver = false;
			}

		}

		if(gamestate == 2 && !gameOver){
			if(manY>240){
				manY-=40;
			}
			else{
				manY=200;
			}
			if (pause<4){
				pause++;
			}
			else {
				pause = 0;
				if(deadstate<7){
					deadstate++;
				}
			}
			if(deadstate == 7){
				gameOver = true;
			}

			batch.draw(dead[deadstate], 200, manY);
		}
		else {
			batch.draw(man[manstate],200, manY);
		}

		manRectangle = new Rectangle(200, manY,man[manstate].getWidth(),man[manstate].getHeight());

		for(int i=0;i<coinRectangles.size();i++)
		{
			if(Intersector.overlaps(manRectangle,coinRectangles.get(i))){
				score++;
				coinRectangles.remove(i);
				coinX.remove(i);
				coinY.remove(i);
				break;
			}
		}

		for(int i=0;i<bombRectangles.size();i++)
		{
			if(Intersector.overlaps(manRectangle,bombRectangles.get(i))){
				gamestate = 2;
			}
		}
		font.draw(batch,String.valueOf(score),100,200);
		batch.end();

	}


	@Override
	public void dispose () {
		batch.dispose();
	}
}
