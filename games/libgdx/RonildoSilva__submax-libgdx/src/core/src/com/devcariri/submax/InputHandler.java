package com.devcariri.submax;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Input;
import com.badlogic.gdx.InputProcessor;
import com.badlogic.gdx.math.Vector2;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class InputHandler implements InputProcessor {
    private int MAX_INPUT = 2;
    private int NUM_BUTTONS = 11;
    private boolean[] mState;
    private boolean[] mOldState;
    private boolean mLastPress, mCurrentPress;
    public char TypedChar;

    public Vector2 MousePos, LastMousePos;

    public boolean isTouched() {
        return mCurrentPress;
    }

    public InputHandler()
    {
        mState = new boolean[NUM_BUTTONS];
        for(int i = 0; i < NUM_BUTTONS; i++) mState[i] = false;
        mOldState = mState.clone();
        mLastPress = false;

        MousePos = new Vector2();
        LastMousePos = new Vector2();
    }

    public Vector2 getSmallScreenTouch(int pointer) {
        Vector2 v = new Vector2();
        float curX = Gdx.input.getX(pointer), curY = Gdx.graphics.getHeight() - Gdx.input.getY(pointer);
        v.x = (int)(Globals.VIRTUAL_W * (curX / Gdx.graphics.getWidth()));
        v.y = (int)(Globals.VIRTUAL_H * (curY / Gdx.graphics.getHeight()));
        return v;
    }


    public void process() {
        mLastPress = mCurrentPress;
        mCurrentPress = Gdx.input.isTouched();

        mOldState = mState.clone();
        for(int s = 0; s < NUM_BUTTONS; s++) mState[s] = false;

        if(Gdx.input.isKeyPressed(Input.Keys.W)) mState[0] = true;
        if(Gdx.input.isKeyPressed(Input.Keys.D)) mState[1] = true;
        if(Gdx.input.isKeyPressed(Input.Keys.S)) mState[2] = true;
        if(Gdx.input.isKeyPressed(Input.Keys.A)) mState[3] = true;

        for(int i = 0; i < MAX_INPUT; i++)
        {
            LastMousePos = MousePos;
            if(Gdx.input.isTouched())
                MousePos.set(getSmallScreenTouch(0));
            else
                MousePos.set(-100,-100);
			/*if(!Gdx.input.isTouched(i)) continue;
			int x = Gdx.input.getX(i), y = Gdx.graphics.getHeight() - Gdx.input.getY(i);
			for(int b = 0; b < NUM_BUTTONS; b++) if(Buttons[b].isPressed(x, y)){
				mState[b] = true;
				//Vibrate fix
				/*if(Globals.VIBRATE && isFirstDown(b))
					Gdx.input.vibrate(14);
			}*/
        }
    }

    public boolean touchDown(int x, int y, int pointer, int button)
    {
        return false;
    }

    public boolean touchUp(int x, int y, int pointer, int button)
    {
        return false;
    }

    public boolean touchDragged(int x, int y, int pointer)
    {
        return false;
    }

    public boolean keyTyped(char character)
    {
        int c = (int)character;
        if(c > 0)
            TypedChar = character;
        return false;
    }

    public boolean keyDown(int keycode)
    {
        return false;
    }

    public boolean keyUp(int keycode)
    {
        return false;
    }

    public boolean scrolled(int amount)
    {
        return false;
    }

    public boolean mouseMoved(int screenX, int screenY) {
        // TODO Auto-generated method stub
        return false;
    }
}
