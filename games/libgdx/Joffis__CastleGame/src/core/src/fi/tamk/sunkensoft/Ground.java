package fi.tamk.sunkensoft;

import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.badlogic.gdx.physics.box2d.FixtureDef;
import com.badlogic.gdx.physics.box2d.PolygonShape;

public class Ground {
    CastleGame game;
    Body groundBody;

    /**
     * Create box2d body this is the ground part of our game.
     *
     * @param gam is part of Screens and it's needed here to use variables
     *             from CastleGame class.
     */
    public Ground(CastleGame gam){
        game = gam;
        BodyDef groundBodyDef = new BodyDef();
        groundBodyDef.type = BodyDef.BodyType.StaticBody;
        groundBodyDef.position.set(game.WORLD_WIDTH/2, 850f);
        groundBody = GameScreen.world.createBody(groundBodyDef);

        FixtureDef groundFixtureDef = new FixtureDef();
        groundFixtureDef.density = 0f;
        groundFixtureDef.restitution = 0f;
        groundFixtureDef.friction = 0.5f;

        PolygonShape groundbox = new PolygonShape();
        groundbox.setAsBox(game.WORLD_WIDTH/2,0.25f);
        groundFixtureDef.shape = groundbox;
        groundBody.createFixture(groundFixtureDef);
        groundBody.setUserData("ground");
    }
}
