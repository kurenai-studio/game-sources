package com.veilfall.game.audio;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Preferences;
import com.badlogic.gdx.audio.Sound;
import com.veilfall.game.player.CharacterKit;
import com.badlogic.gdx.utils.Disposable;

/** Small CC0 combat sound layer; all files are loaded once and reused. */
public final class AudioDirector implements Disposable {
    private final Preferences preferences = Gdx.app.getPreferences("veilfall-audio");
    private final Sound metal = Gdx.audio.newSound(Gdx.files.internal("audio/combat/metal-impact.ogg"));
    private final Sound heavy = Gdx.audio.newSound(Gdx.files.internal("audio/combat/heavy-impact.ogg"));
    private final Sound slice = Gdx.audio.newSound(Gdx.files.internal("audio/combat/knife-slice.ogg"));

    public boolean isMuted() { return preferences.getBoolean("muted", false); }

    public void setMuted(boolean muted) {
        preferences.putBoolean("muted", muted);
        preferences.flush();
    }

    public void playAttack(CharacterKit kit, boolean ability) {
        if (isMuted()) return;
        switch (kit) {
            case WARDEN -> (ability ? heavy : metal).play(ability ? 0.72f : 0.52f);
            case ARCHER -> slice.play(ability ? 0.78f : 0.48f);
            case MAGE -> (ability ? heavy : slice).play(ability ? 0.48f : 0.32f);
        }
    }

    @Override public void dispose() {
        metal.dispose(); heavy.dispose(); slice.dispose();
    }
}
