package com.balitechy.crashlanding.models;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.Texture.TextureFilter;
import com.badlogic.gdx.graphics.g2d.Batch;
import com.badlogic.gdx.math.Vector2;
import com.balitechy.crashlanding.GameAudio;

public class SpaceShip extends BaseObject {
	
	public static final float WIDTH = 50;
	public static final float HEIGHT = 70;
	public static enum EngineState {ON, OFF};
	
	private static final float ACCELERATING_SPEED = 5;
	private static final float FALLING_SPEED = 5;
	private static final float LANDING_MAX_SPEED = 50;
	
	private LandingPad landingpad;
	private FuelMeter fuelmeter;
	private EngineState engine_state = EngineState.OFF; //Default
	private float speed = 0;
	private boolean is_landing, is_crashed = false;
	private float fuelLevel = 1000; // Let say its 1000 of gallons :)
	private float fuelPerThrust = 200; // A factor of fuel consumption per thrust.
	
	public Texture jetTexture, landedTexture, crashTexture;

	public SpaceShip(Vector2 position, float width, float height) {
		super(position, width, height);
		
		texture = new Texture(Gdx.files.internal("data/ship.png"));
		texture.setFilter(TextureFilter.Linear, TextureFilter.Linear);
		
		jetTexture = new Texture(Gdx.files.internal("data/ship_fire.png"));
		jetTexture.setFilter(TextureFilter.Linear, TextureFilter.Linear);
		
		landedTexture = new Texture(Gdx.files.internal("data/ship_landed.png"));
		landedTexture.setFilter(TextureFilter.Linear, TextureFilter.Linear);
		
		crashTexture = new Texture(Gdx.files.internal("data/explode.png"));
		crashTexture.setFilter(TextureFilter.Linear, TextureFilter.Linear);
	}

	public void setEngineState(EngineState y_state) {
		this.engine_state = y_state;
	}
	
	public EngineState getEngineState() {
		return engine_state;
	}

	public float getFuelLevel() {
		return fuelLevel;
	}

	public void setLandingPad(LandingPad lp){
		landingpad = lp;
	}
	
	public void setFuelMeter(FuelMeter fm){
		fuelmeter = fm;
	}
	
	public boolean isLanding(){
		return is_landing;
	}
	
	public boolean isCrashed(){
		return is_crashed;
	}
	
	public void reset(){
		position = new Vector2(Gdx.graphics.getWidth()/2-WIDTH/2, Gdx.graphics.getHeight()-HEIGHT);
		speed = 0;
		is_landing = false;
		is_crashed = false;
	}
	
	private void update(float delta){
		//Update fuelMeter value
		if(fuelLevel >= 0){
			fuelmeter.setLevel(fuelLevel/1000);
		}else{
			fuelmeter.setLevel(0);
		}
		
		//Landed successfully
		if(speed >= -LANDING_MAX_SPEED &&
		  speed <= LANDING_MAX_SPEED &&
		  bounds.overlaps(landingpad.getBounds())){
			is_landing = true;
			GameAudio.landed.play();
		
		//Landed too fast
		}else if(bounds.overlaps(landingpad.getBounds()) &&
			(speed < -LANDING_MAX_SPEED || speed > LANDING_MAX_SPEED)){
			is_crashed = true;
			GameAudio.explode.play();
		
		//on the fly
		}else{
			switch(engine_state){
				case ON:
					
					//Acceleration only possible while ship has fuel.
					if(fuelLevel > 0){
						
						// Substract the fuelLevel and update the display value
						fuelLevel -= Gdx.graphics.getDeltaTime() * fuelPerThrust;

//						if(position.y >= Gdx.graphics.getHeight() - HEIGHT){
//							speed = 0;
//						}else{
//							speed += ACCELERATING_SPEED;
//						}
						speed += ACCELERATING_SPEED;
						position.y += speed * Gdx.graphics.getDeltaTime();
					
					//Stop The engine, and let it picked by the heaven.
					}else{
						engine_state = SpaceShip.EngineState.OFF;
					}
					
				break;
				
				case OFF:
//					if(position.y >= Gdx.graphics.getHeight() - HEIGHT){
//						speed = 0; //When it hit the ceiling in OFF mode, bounce back.
//						speed -= 20; //Bounce back speed when hit the ceiling
//					}else{
//						speed -= FALLING_SPEED;
//					}
					speed -= FALLING_SPEED;
					position.y += speed * Gdx.graphics.getDeltaTime();
				break;
			}
		}
	}
	
	@Override
	public void act(float delta) {
		if(!is_landing && !is_crashed){
			update(delta);
		}
		super.act(delta);
	}

	@Override
	public void draw(Batch batch, float parentAlpha) {		
		//Draw ship
		if(isLanding()){
			batch.draw(landedTexture, position.x, position.y, width, height);
		}else if(isCrashed()){
			batch.draw(crashTexture, position.x - crashTexture.getWidth()/3, position.y - crashTexture.getHeight()/3, crashTexture.getWidth(), crashTexture.getHeight());
		}else{
			batch.draw(texture, position.x, position.y, width, height);
			//Draw fire on engine state ON
			if(getEngineState() == SpaceShip.EngineState.ON)
				batch.draw(jetTexture, position.x, position.y-getHeight()+7, width, height);
		}
	}

	@Override
	public void dispose() {
		texture.dispose();
		jetTexture.dispose();
		landedTexture.dispose();
		crashTexture.dispose();
	}

}
