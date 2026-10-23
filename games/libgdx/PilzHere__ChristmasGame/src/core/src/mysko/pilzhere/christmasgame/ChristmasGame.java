package mysko.pilzhere.christmasgame;

import com.badlogic.gdx.Game;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g3d.ModelBatch;

import mysko.pilzhere.christmasgame.audio.Audio;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class ChristmasGame extends Game {

	/*
	 * TODO the theme is "The world is food!" and I have no idea what to do make...
	 * * Spinning planet/island? * Mode7ish race game? * Doom clone? * 2D
	 * platformer?
	 */

	private SpriteBatch batch;
	private ModelBatch mdlBatch;
	private AssetManager assMan;
	private Audio audio;

	public final int stdWindowWidth = 256;
	public final int stdWindowHeight = 144;
	public final float stdWindowScaleIncrement = 0.5f;
	public float windowScale = 1f;

	public float volume = 0.5f;

	public void setWindowScale(float windowScale) {
		if (windowScale >= 4) // Else some gui crops... Old: 1.
			this.windowScale = windowScale;
	}

	public float getWindowScale() {
		return windowScale;
	}

	@Override
	public void create() {
		assMan = new AssetManager();
		loadAssets();

		batch = new SpriteBatch();
		mdlBatch = new ModelBatch();

		audio = new Audio(assMan);

		setScreen(new GameScreen(this));
	}

	private void loadAssets() {
		assMan.load("island256.png", Texture.class);
		assMan.load("tree01.png", Texture.class);
		assMan.load("tree02.png", Texture.class);
		assMan.load("logs.png", Texture.class);
		assMan.load("candyCane.png", Texture.class);
//		assMan.load("comet.png", Texture.class);
		assMan.load("seaWave1.png", Texture.class);
		assMan.load("seaWave2.png", Texture.class);
		assMan.load("seaWave3.png", Texture.class);
		assMan.load("santaStandingDown.png", Texture.class);
		assMan.load("santaStandingUp.png", Texture.class);
		assMan.load("santaStandingLeft.png", Texture.class);
		assMan.load("santaStandingRight.png", Texture.class);
		assMan.load("santaWaterUp.png", Texture.class);
		assMan.load("santaWaterDown.png", Texture.class);
		assMan.load("santaWaterRight.png", Texture.class);
		assMan.load("yetiStandingDown.png", Texture.class);
		assMan.load("yetiStandingUp.png", Texture.class);
		assMan.load("yetiStandingLeft.png", Texture.class);
		assMan.load("yetiStandingRight.png", Texture.class);
		assMan.load("candy.png", Texture.class);
		assMan.load("shark.png", Texture.class);
		assMan.load("slade.png", Texture.class);
		assMan.load("sladeBroken.png", Texture.class);
		assMan.load("heartEmpty.png", Texture.class);
		assMan.load("heartHalf1.png", Texture.class);
		assMan.load("heartHalf2.png", Texture.class);

		assMan.load("santaWalkingDown1.png", Texture.class);
		assMan.load("santaWalkingDown3.png", Texture.class);
		assMan.load("santaWalkingUp1.png", Texture.class);
		assMan.load("santaWalkingUp3.png", Texture.class);

		assMan.load("santaWalkingRight1.png", Texture.class);
		assMan.load("santaWalkingRight2.png", Texture.class);
		assMan.load("santaWalkingRight3.png", Texture.class);
		assMan.load("santaWalkingRight4.png", Texture.class);
		assMan.load("santaWalkingRight5.png", Texture.class);
		assMan.load("santaWalkingRight6.png", Texture.class);
		assMan.load("santaWalkingRight7.png", Texture.class);
		assMan.load("santaWalkingRight8.png", Texture.class);

		assMan.load("yetiWalkingDown1.png", Texture.class);
		assMan.load("yetiWalkingDown3.png", Texture.class);
		assMan.load("yetiWalkingUp1.png", Texture.class);
		assMan.load("yetiWalkingUp3.png", Texture.class);

		assMan.load("yetiWalkingRight1.png", Texture.class);
		assMan.load("yetiWalkingRight2.png", Texture.class);
		assMan.load("yetiWalkingRight3.png", Texture.class);
		assMan.load("yetiWalkingRight4.png", Texture.class);
		assMan.load("yetiWalkingRight5.png", Texture.class);
		assMan.load("yetiWalkingRight6.png", Texture.class);
		assMan.load("yetiWalkingRight7.png", Texture.class);
		assMan.load("yetiWalkingRight8.png", Texture.class);

		assMan.load("santaChoppingDown1.png", Texture.class);
		assMan.load("santaChoppingDown2.png", Texture.class);
		assMan.load("santaChoppingUp1.png", Texture.class);
		assMan.load("santaChoppingUp2.png", Texture.class);
		assMan.load("santaChoppingRight1.png", Texture.class);
		assMan.load("santaChoppingRight2.png", Texture.class);

		assMan.load("title.png", Texture.class);

		assMan.load("fonts/font01_32.fnt", BitmapFont.class);
		assMan.load("fonts/font01_16.fnt", BitmapFont.class);

		assMan.load("sounds/accept.wav", Sound.class);
		assMan.load("sounds/choose.wav", Sound.class);
		assMan.load("sounds/playerHurt.wav", Sound.class);
		assMan.load("sounds/chop.wav", Sound.class);
		assMan.load("sounds/crash.wav", Sound.class);
		assMan.load("sounds/treeDisapear.wav", Sound.class);
		assMan.load("sounds/aggro.wav", Sound.class);
		assMan.load("sounds/pickup.wav", Sound.class);
		assMan.load("sounds/yetiHurt.wav", Sound.class);
		assMan.load("sounds/slade.wav", Sound.class);
		assMan.load("sounds/shark.wav", Sound.class);

		if (!assMan.isFinished())
			assMan.finishLoading();
	}

	@Override
	public void render() {
//		Gdx.graphics.setTitle("Santa's Crashing Christmas " + Gdx.graphics.getWidth() + " * " + Gdx.graphics.getHeight()); // 1024* 576

		Gdx.gl.glClearColor(48 / 255f, 96 / 255f, 130 / 255f, 1);
		Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT | GL20.GL_DEPTH_BUFFER_BIT);

		getScreen().render(Gdx.graphics.getDeltaTime());
	}

	@Override
	public void dispose() {
		getScreen().dispose();

		batch.dispose();
		mdlBatch.dispose();

		assMan.dispose();
	}

	public AssetManager getAssMan() {
		return assMan;
	}

	public ModelBatch getMdlBatch() {
		return mdlBatch;
	}

	public SpriteBatch getBatch() {
		return batch;
	}

	public Audio getAudio() {
		return audio;
	}
}
