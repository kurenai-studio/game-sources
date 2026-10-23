package mysko.pilzhere.christmasgame.gui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.utils.Array;

import mysko.pilzhere.christmasgame.entities.Player;
import mysko.pilzhere.christmasgame.screens.GameScreen;

public class GUI {
	private final GameScreen screen;
	private final SpriteBatch batch;
	public final BitmapFont font01_32; // get-set
	public final BitmapFont font01_16; // get-set
	public BitmapFont currentFont; // get set

	private final Texture texTitle;

	private Player player;

	public Array<GUIEntity> guiEnts = new Array<GUIEntity>(); // get set

	public boolean showMenu = true;

	private HeartIcon hI1;
	private HeartIcon hI2;
	private HeartIcon hI3;
	private HeartIcon hI4;
	private HeartIcon hI5;

	public GUI(GameScreen screen) {
		this.screen = screen;
		this.batch = screen.game.getBatch();

		font01_32 = screen.assMan.get("fonts/font01_32.fnt");
		font01_16 = screen.assMan.get("fonts/font01_16.fnt");

		texTitle = screen.assMan.get("title.png");

		if (screen.game.windowScale > 3.5f) {
			currentFont = font01_32;
		} else {
			currentFont = font01_16;
		}

		player = screen.getPlayer();

		guiEnts.add(new LogsIcon(screen, this, new Vector2(8, 0)));
		guiEnts.add(new CandyIcon(screen, this, new Vector2(128, 0)));

		System.out.println(Gdx.graphics.getWidth() * screen.game.windowScale);

		hI1 = new HeartIcon(screen, this, new Vector2(Gdx.graphics.getWidth() / 2, 0));
		hI2 = new HeartIcon(screen, this, new Vector2(Gdx.graphics.getWidth() / 2, 0));
		hI2.offsetX = 5;
		hI3 = new HeartIcon(screen, this, new Vector2(Gdx.graphics.getWidth() / 2, 0));
		hI3.offsetX = 5 * 2;
		hI4 = new HeartIcon(screen, this, new Vector2(Gdx.graphics.getWidth() / 2, 0));
		hI4.offsetX = 5 * 3;
		hI5 = new HeartIcon(screen, this, new Vector2(Gdx.graphics.getWidth() / 2, 0));
		hI5.offsetX = 5 * 4;

		guiEnts.add(hI1);
		guiEnts.add(hI2);
		guiEnts.add(hI3);
		guiEnts.add(hI4);
		guiEnts.add(hI5);

		System.out.println("GUI added!");
	}

	public void tick(float delta) {
		player = screen.getPlayer();

		if (screen.game.windowScale > 3.5f) {
			currentFont = font01_32;
		} else {
			currentFont = font01_16;
		}

		if (player != null) {
			switch (player.hp) {
			case 0:
				hI1.drawLeft = false;
				hI1.drawRight = false;
				hI2.drawLeft = false;
				hI2.drawRight = false;
				hI3.drawLeft = false;
				hI3.drawRight = false;
				hI4.drawLeft = false;
				hI4.drawRight = false;
				hI5.drawLeft = false;
				hI5.drawRight = false;
				break;
			case 1:
				hI1.drawLeft = true;
				hI1.drawRight = true;
				hI2.drawLeft = false;
				hI2.drawRight = false;
				hI3.drawLeft = false;
				hI3.drawRight = false;
				hI4.drawLeft = false;
				hI4.drawRight = false;
				hI5.drawLeft = false;
				hI5.drawRight = false;
				break;
			case 2:
				hI1.drawLeft = true;
				hI1.drawRight = true;
				hI2.drawLeft = true;
				hI2.drawRight = true;
				hI3.drawLeft = false;
				hI3.drawRight = false;
				hI4.drawLeft = false;
				hI4.drawRight = false;
				hI5.drawLeft = false;
				hI5.drawRight = false;
				break;
			case 3:
				hI1.drawLeft = true;
				hI1.drawRight = true;
				hI2.drawLeft = true;
				hI2.drawRight = true;
				hI3.drawLeft = true;
				hI3.drawRight = true;
				hI4.drawLeft = false;
				hI4.drawRight = false;
				hI5.drawLeft = false;
				hI5.drawRight = false;
				break;
			case 4:
				hI1.drawLeft = true;
				hI1.drawRight = true;
				hI2.drawLeft = true;
				hI2.drawRight = true;
				hI3.drawLeft = true;
				hI3.drawRight = true;
				hI4.drawLeft = true;
				hI4.drawRight = true;
				hI5.drawLeft = false;
				hI5.drawRight = false;
				break;
			case 5:
				hI1.drawLeft = true;
				hI1.drawRight = true;
				hI2.drawLeft = true;
				hI2.drawRight = true;
				hI3.drawLeft = true;
				hI3.drawRight = true;
				hI4.drawLeft = true;
				hI4.drawRight = true;
				hI5.drawLeft = true;
				hI5.drawRight = true;
				break;
			}
		}

		for (GUIEntity guiEnt : guiEnts) {
			guiEnt.tick(delta);
		}
	}

	private final String strGameByPilz = "A game by Christian \"PilzHere\" Pilz";
	private final String strIfPaused1 = "-PAUSED-";
	private final String strIfPaused2 = "[ENTER] to continue";
	private final String strIfWon1 = "[ENTER] to restart";
	private final String strStart = "[ENTER] to start";
	private final String strQuit = "[ESCAPE] to quit";
	private final String strControls1 = "[WASD] to move";
	private final String strControls2 = "[E] to chop";
	private final String strControls3 = "[+ -] to change window size";
	private final String strYouWon = "YOU WON - Santa survived!";
	private final String strInfo = "Gather 100 logs to repair Santa's slade";
	private int offset;

	private float texTitlePosX;
	private float texTitlePosY;

	public void render2D(float delta) {
		if (currentFont == font01_32)
			offset = 24;
		else
			offset = 12;

		texTitlePosX = (Gdx.graphics.getWidth() / 2) - (texTitle.getWidth() / 2);
		texTitlePosY = (Gdx.graphics.getHeight() / 2) - (texTitle.getHeight() / 2);

		if (showMenu) {
			batch.draw(texTitle, texTitlePosX, texTitlePosY);

			currentFont.draw(batch, strGameByPilz, 0, Gdx.graphics.getHeight());

//			currentFont.draw(batch, "Cam zoom is: " + screen.cam.zoom, 0, Gdx.graphics.getHeight() - 40); // TEST

			if (screen.gameIsPaused) {
				if (!screen.playerWon) {
					currentFont.draw(batch, strIfPaused1, texTitlePosX + (texTitle.getWidth() / 3),
							texTitlePosY + 64 + offset);
					currentFont.draw(batch, strIfPaused2, texTitlePosX + (texTitle.getWidth() / 4), texTitlePosY + 64);
				}
				currentFont.draw(batch, strQuit, texTitlePosX + (texTitle.getWidth() / 4), texTitlePosY + 64 - offset);
				if (screen.playerWon) {
					currentFont.draw(batch, strYouWon, texTitlePosX + (texTitle.getWidth() / 12), texTitlePosY + 112);
					currentFont.draw(batch, strIfWon1, texTitlePosX + (texTitle.getWidth() / 4), texTitlePosY + 64);
				}
			} else {
				currentFont.draw(batch, strInfo, texTitlePosX + (texTitle.getWidth() / 4) - 196,
						texTitlePosY + 64 + offset * 4.5f);
				currentFont.draw(batch, strControls1, texTitlePosX + (texTitle.getWidth() / 4),
						texTitlePosY + 64 + offset * 2);
				currentFont.draw(batch, strControls2, texTitlePosX + (texTitle.getWidth() / 4),
						texTitlePosY + 64 + offset);
				currentFont.draw(batch, strControls3, texTitlePosX + (texTitle.getWidth() / 4), texTitlePosY + 64);
				currentFont.draw(batch, strStart, texTitlePosX + (texTitle.getWidth() / 4), texTitlePosY + 64 - offset); // 24
																															// is
																															// offset
				currentFont.draw(batch, strQuit, texTitlePosX + (texTitle.getWidth() / 4),
						texTitlePosY + 64 - offset * 2);
			}

		}

		for (GUIEntity guiEnt : guiEnts) {
			guiEnt.render2D(batch, delta);
		}
	}

	public void destroy() {
		guiEnts.clear();
	}
}
