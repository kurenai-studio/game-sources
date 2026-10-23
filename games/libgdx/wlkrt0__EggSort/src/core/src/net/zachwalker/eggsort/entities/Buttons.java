package net.zachwalker.eggsort.entities;


import com.badlogic.gdx.InputAdapter;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.viewport.Viewport;
import net.zachwalker.eggsort.EggSortScreen;
import net.zachwalker.eggsort.util.Assets;
import net.zachwalker.eggsort.util.Constants;
import net.zachwalker.eggsort.util.DrawingHelpers;
import net.zachwalker.eggsort.util.Enums;

public class Buttons extends InputAdapter  {

    private Viewport viewport;
    private Valve leftValve;
    private Valve rightValve;
    private EggSortScreen eggSortScreen;
    private Vector2 buttonRotateLeft;
    private Vector2 buttonRotateRight;
    private Vector2 buttonGotoLevel;
    private Vector2 buttonToggleMute;

    /*
    Note that Buttons must be initialized AFTER valves AND assets.
    Also note that we need to pass the viewport to the Buttons class since Buttons will be
        receiving touches and will need to unproject the touch input using the viewport.
    Also need to pass in BallSortScreen so Buttons can call gotoHighLevel() when its button is clicked.
    */

    public Buttons(EggSortScreen eggSortScreen, Viewport viewport, Valve leftValve, Valve rightValve) {

        this.eggSortScreen = eggSortScreen;
        this.viewport = viewport;
        this.leftValve = leftValve;
        this.rightValve = rightValve;
        buttonRotateLeft = new Vector2(Constants.BUTTON_ROTATE_LEFT_POSITION);
        buttonRotateRight = new Vector2(Constants.BUTTON_ROTATE_RIGHT_POSITION);
        buttonGotoLevel = new Vector2(Constants.BUTTON_GOTO_LEVEL_POSITION);
        buttonToggleMute = new Vector2(Constants.BUTTON_MUTE_POSITION);
}

    @Override
    public boolean touchDown(int screenX, int screenY, int pointer, int button) {
        //get the coordinates of the touchDown event in OUR world coords (not screen coords)
        Vector2 viewportPosition = viewport.unproject(new Vector2(screenX, screenY));

        //check the gotoLevel button to see if it was clicked
        float gotoLevelRadius = Assets.singleton.images.buttonGotoLevel.getRotatedPackedWidth() / 2.0f;
        Vector2 gotoLevelCenter = new Vector2(buttonGotoLevel.x + gotoLevelRadius, buttonGotoLevel.y + gotoLevelRadius);
        if (viewportPosition.dst(gotoLevelCenter) <= gotoLevelRadius) {
            Assets.singleton.sounds.playSound(Assets.singleton.sounds.button);
            eggSortScreen.gotoHighLevel();
        }

        //check the toggleMute button to see if it was clicked
        float toggleMuteRadius = Assets.singleton.images.buttonMute.getRotatedPackedWidth() / 2.0f;
        Vector2 toggleMuteCenter = new Vector2(buttonToggleMute.x + toggleMuteRadius, buttonToggleMute.y + toggleMuteRadius);
        if (viewportPosition.dst(toggleMuteCenter) <= toggleMuteRadius) {
            Assets.singleton.sounds.playSound(Assets.singleton.sounds.button);
            Assets.singleton.sounds.toggleMute();
        }

        //check the left "rotate valve" button to see if it was clicked
        float rotateLeftRadius = Assets.singleton.images.buttonWhiteDown.getRotatedPackedWidth() / 2.0f;
        Vector2 rotateLeftCenter = new Vector2(buttonRotateLeft.x + rotateLeftRadius, buttonRotateLeft.y + rotateLeftRadius);
        if (viewportPosition.dst(rotateLeftCenter) <= rotateLeftRadius) {
            leftValve.switchValveState();
            Assets.singleton.sounds.playSound(Assets.singleton.sounds.valve);
        }

        //check the right "rotate valve" button to see if it was clicked
        float rotateRightRadius = Assets.singleton.images.buttonBrownDown.getRotatedPackedWidth() / 2.0f;
        Vector2 rotateRightCenter = new Vector2(buttonRotateRight.x + rotateLeftRadius, buttonRotateRight.y + rotateRightRadius);
        if (viewportPosition.dst(rotateRightCenter) <= rotateRightRadius) {
            rightValve.switchValveState();
            Assets.singleton.sounds.playSound(Assets.singleton.sounds.valve);
        }

        return true;
    }

    //no update method on Buttons, since they don't move

    public void render(SpriteBatch batch) {

        //draw gotoLevel button
        DrawingHelpers.drawSprite(batch, Assets.singleton.images.buttonGotoLevel, buttonGotoLevel);

        //draw toggleMute button
        if (Assets.singleton.sounds.isMuted()) {
            DrawingHelpers.drawSprite(batch, Assets.singleton.images.buttonUnMute, buttonToggleMute);
        } else {
            DrawingHelpers.drawSprite(batch, Assets.singleton.images.buttonMute, buttonToggleMute);
        }

        //draw left "rotate valve" button
        if (leftValve.valveState == Enums.ValveState.OPEN) {
            DrawingHelpers.drawSprite(batch, Assets.singleton.images.buttonWhiteDown, buttonRotateLeft);
        } else {
            DrawingHelpers.drawSprite(batch, Assets.singleton.images.buttonWhiteRight, buttonRotateLeft);
        }

        //draw right "rotate valve" button
        if (rightValve.valveState == Enums.ValveState.OPEN) {
            DrawingHelpers.drawSprite(batch, Assets.singleton.images.buttonBrownDown, buttonRotateRight);
        } else {
            DrawingHelpers.drawSprite(batch, Assets.singleton.images.buttonBrownRight, buttonRotateRight);
        }

    }

}
