package mysko.pilzhere.christmasgame.audio;

import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.audio.Sound;

public class Audio {
	private final AssetManager assMan;

	public Sound sfxAccept;
	public Sound sfxChoose;
	public Sound sfxPlayerHurt;
	public Sound sfxChop;
	public Sound sfxCrash;
	public Sound sfxTreeDisapear;
	public Sound sfxAggro;
	public Sound sfxPickup;
	public Sound sfxYetiHurt;
	public Sound sfxSlade;
	public Sound sfxShark;

	public Audio(AssetManager assMan) {
		this.assMan = assMan;
		setSounds();
	}

	private void setSounds() {
		sfxAccept = assMan.get("sounds/accept.wav");
		sfxChoose = assMan.get("sounds/choose.wav");
		sfxPlayerHurt = assMan.get("sounds/playerHurt.wav");
		sfxChop = assMan.get("sounds/chop.wav");
		sfxCrash = assMan.get("sounds/crash.wav");
		sfxTreeDisapear = assMan.get("sounds/treeDisapear.wav");
		sfxAggro = assMan.get("sounds/aggro.wav");
		sfxPickup = assMan.get("sounds/pickup.wav");
		sfxYetiHurt = assMan.get("sounds/yetiHurt.wav");
		sfxSlade = assMan.get("sounds/slade.wav");
		sfxShark = assMan.get("sounds/shark.wav");
	}
}
