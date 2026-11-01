package com.veilfall.game;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.Game;
import com.badlogic.gdx.Screen;
import com.badlogic.gdx.utils.GdxRuntimeException;
import com.veilfall.game.data.ArenaData;
import com.veilfall.game.data.CharacterData;
import com.veilfall.game.data.WeaponData;
import com.veilfall.game.audio.AudioDirector;
import com.veilfall.game.data.MatchData;
import com.veilfall.game.data.ProgressionReward;
import com.veilfall.game.database.repository.MatchRepository;
import com.veilfall.game.database.repository.ArenaRepository;
import com.veilfall.game.database.repository.CharacterRepository;
import com.veilfall.game.database.repository.MobRepository;
import com.veilfall.game.database.repository.PlayerRepository;
import com.veilfall.game.database.repository.SkillRepository;
import com.veilfall.game.database.repository.WeaponRepository;
import com.veilfall.game.database.repository.WaveRepository;
import com.veilfall.game.database.DatabaseInitializer;
import com.veilfall.game.database.DatabaseManager;
import com.veilfall.game.rendering.Renderer;
import com.veilfall.game.rendering.ModelAssets;
import com.veilfall.game.screens.ArenaSelectScreen;
import com.veilfall.game.screens.BattleOutcome;
import com.veilfall.game.screens.BattleScreen;
import com.veilfall.game.screens.LobbyScreen;
import com.veilfall.game.screens.LoaderScreen;
import com.veilfall.game.screens.ResultScreen;
import com.veilfall.game.screens.SettingsScreen;
import com.veilfall.game.screens.UiTheme;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Objects;

/** {@link com.badlogic.gdx.ApplicationListener} implementation shared by all platforms. */
public class VeilfallGame extends Game {
	private Renderer renderer;
	private ModelAssets modelAssets;
	private DatabaseManager databaseManager;
	private UiTheme uiTheme;
	private AudioDirector audioDirector;
	private PlayerRepository playerRepository;
	private SkillRepository skillRepository;
	private WaveRepository waveRepository;
	private CharacterRepository characterRepository;
	private WeaponRepository weaponRepository;
	private MobRepository mobRepository;
	private ArenaRepository arenaRepository;
	private MatchRepository matchRepository;
	private CharacterData selectedCharacter;
	private WeaponData selectedWeapon;

	@Override
	public void create() {
		try {
			databaseManager = new DatabaseManager();
			new DatabaseInitializer(databaseManager).initialize();
		} catch (SQLException | IOException exception) {
			if (databaseManager != null) {
				try {
					databaseManager.close();
				} catch (SQLException closeException) {
					exception.addSuppressed(closeException);
				}
			}
			throw new GdxRuntimeException("Failed to initialize the local Veilfall database", exception);
		}

		renderer = new Renderer(Gdx.graphics.getWidth(), Gdx.graphics.getHeight());
		modelAssets = new ModelAssets();
		playerRepository = new PlayerRepository(databaseManager);
		skillRepository = new SkillRepository(databaseManager);
		waveRepository = new WaveRepository(databaseManager);
		characterRepository = new CharacterRepository(databaseManager);
		weaponRepository = new WeaponRepository(databaseManager);
		mobRepository = new MobRepository(databaseManager);
		arenaRepository = new ArenaRepository(databaseManager);
		matchRepository = new MatchRepository(databaseManager);
		uiTheme = new UiTheme();
		audioDirector = new AudioDirector();
		setScreen(new LoaderScreen(this));
	}

	@Override
	public void render() {
		super.render();
	}

	@Override
	public void resize(int width, int height) {
		super.resize(width, height);
		if (renderer != null) renderer.resize(width, height);
	}

	public Renderer getRenderer() { return renderer; }
	public ModelAssets getModelAssets() { return modelAssets; }
	public UiTheme getUiTheme() { return uiTheme; }
	public AudioDirector getAudioDirector() { return audioDirector; }
	public PlayerRepository getPlayerRepository() { return playerRepository; }
	public SkillRepository getSkillRepository() { return skillRepository; }
	public WaveRepository getWaveRepository() { return waveRepository; }
	public CharacterRepository getCharacterRepository() { return characterRepository; }
	public WeaponRepository getWeaponRepository() { return weaponRepository; }
	public MobRepository getMobRepository() { return mobRepository; }
	public ArenaRepository getArenaRepository() { return arenaRepository; }
	public MatchRepository getMatchRepository() { return matchRepository; }
	public CharacterData getSelectedCharacter() { return selectedCharacter; }
	public WeaponData getSelectedWeapon() { return selectedWeapon; }

	public void setSelectedCharacter(CharacterData character) {
		selectedCharacter = character;
		if (selectedWeapon != null && (character == null || selectedWeapon.getCharacterId() != character.getId())) {
			selectedWeapon = null;
		}
	}

	public void setSelectedWeapon(WeaponData weapon) {
		if (weapon != null && (selectedCharacter == null || weapon.getCharacterId() != selectedCharacter.getId())) {
			throw new IllegalArgumentException("Weapon does not belong to the selected character");
		}
		selectedWeapon = weapon;
	}

	public void showLobby() {
		transitionTo(new LobbyScreen(this));
	}

	public void showArenaSelect() {
		transitionTo(new ArenaSelectScreen(this));
	}

	public void showSettings() {
		transitionTo(new SettingsScreen(this));
	}

	public void startBattle(ArenaData arena) {
		Objects.requireNonNull(arena, "Selected arena must not be null");
		Objects.requireNonNull(selectedCharacter, "Select a character before starting a battle");
		Objects.requireNonNull(selectedWeapon, "Select a weapon before starting a battle");
		if (selectedWeapon.getCharacterId() != selectedCharacter.getId()) {
			throw new IllegalStateException("Selected weapon does not belong to the selected character");
		}
		renderer.setArenaEnvironment(arena.getEnvironment());
		transitionTo(new BattleScreen(this, arena, selectedCharacter, selectedWeapon));
	}

	public void showResult(BattleOutcome outcome) {
		try {
			ProgressionReward reward = matchRepository.completeMatch(new MatchData(0,
					outcome.victory() ? "WIN" : "LOSS", outcome.arenaId(), outcome.characterId(),
					outcome.weaponId(), outcome.wavesCompleted(), outcome.enemiesDefeated(),
					outcome.bossesDefeated(), outcome.durationSeconds(), null, outcome.arenaName(),
					outcome.characterName(), outcome.weaponName()));
			BattleOutcome awarded = new BattleOutcome(outcome.victory(), outcome.characterName(), outcome.arenaName(),
					outcome.wavesCompleted(), outcome.enemiesDefeated(), outcome.bossesDefeated(), outcome.durationSeconds(),
					outcome.arenaId(), outcome.characterId(), outcome.weaponId(), outcome.weaponName(),
					reward.experienceEarned(), reward.totalExperience(), reward.level(), reward.bestWave());
			transitionTo(new ResultScreen(this, awarded));
		} catch (SQLException exception) {
			throw new GdxRuntimeException("Failed to save the completed run", exception);
		}
	}

	private void transitionTo(Screen nextScreen) {
		Screen previousScreen = getScreen();
		setScreen(nextScreen);
		if (previousScreen != null) {
			previousScreen.dispose();
		}
	}

	@Override
	public void dispose() {
		super.dispose();
		if (renderer != null) renderer.dispose();
		if (modelAssets != null) modelAssets.dispose();
		if (uiTheme != null) uiTheme.dispose();
		if (audioDirector != null) audioDirector.dispose();
		if (databaseManager != null) {
			try {
				databaseManager.close();
			} catch (SQLException exception) {
				Gdx.app.error("VeilfallGame", "Failed to close the local Veilfall database", exception);
			}
		}
	}
}
