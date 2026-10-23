package mysko.pilzhere.christmasgame.entities;

import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.TextureData;
import com.badlogic.gdx.graphics.VertexAttributes.Usage;
import com.badlogic.gdx.graphics.g3d.Material;
import com.badlogic.gdx.graphics.g3d.Model;
import com.badlogic.gdx.graphics.g3d.ModelBatch;
import com.badlogic.gdx.graphics.g3d.ModelInstance;
import com.badlogic.gdx.graphics.g3d.attributes.TextureAttribute;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.math.collision.BoundingBox;
import com.badlogic.gdx.utils.Disposable;

import mysko.pilzhere.christmasgame.screens.GameScreen;

public class Island extends Entity implements Disposable {
	private ModelBuilder mdlBuilder;

	private Texture texture;
	private TextureData texData;
	private Pixmap pixmap;
	private Model mdl;
	private ModelInstance mdlInstance;
	public BoundingBox bb;
	private final float size = 100;

	public Island(GameScreen screen, Vector3 position) {
		super(screen, position);

		texture = screen.assMan.get("island256.png", Texture.class);
		texData = texture.getTextureData();
		if (!texData.isPrepared())
			texData.prepare();
		pixmap = texData.consumePixmap();

		mdlBuilder = new ModelBuilder();
		mdl = mdlBuilder.createBox(size, 0, size, new Material(TextureAttribute.createDiffuse(texture)),
				Usage.Position | Usage.TextureCoordinates);
		mdlInstance = new ModelInstance(mdl);
		mdlInstance.transform.rotate(Vector3.Y, 90); // for reading pixels to match.

		bb = new BoundingBox();
		mdlInstance.calculateBoundingBox(bb).mul(mdlInstance.transform);
	}

	@Override
	public void tick(float delta) {
		bb.mul(mdlInstance.transform);
	}

	public int readPixels(Vector3 position) {
		position.x = position.x * (texture.getWidth() / size) + (texture.getWidth() / 2); // 256/100 + 128
		position.z = position.z * (texture.getHeight() / size) + (texture.getHeight() / 2);

		int positionColor = pixmap.getPixel(MathUtils.round(position.x), MathUtils.round(position.z));

		return positionColor;
	}

	@Override
	public void render3D(ModelBatch batch, float delta) {
		batch.render(mdlInstance);
	}

	@Override
	public void dispose() {
		pixmap.dispose();
		mdl.dispose();
	}

}
