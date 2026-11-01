package com.veilfall.game.screens;

import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.ui.ScrollPane;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.GdxRuntimeException;
import com.veilfall.game.VeilfallGame;
import com.veilfall.game.data.CharacterData;
import com.veilfall.game.data.MobData;
import com.veilfall.game.data.PlayerData;
import com.veilfall.game.data.WeaponData;
import com.veilfall.game.player.CharacterKit;

import java.sql.SQLException;
import java.util.List;

public final class LobbyScreen extends AbstractGameScreen {
    private final Table content = new Table();
    private final Label playerLabel;
    private final Label characterLabel;
    private PlayerData player;
    private List<CharacterData> characters;
    private List<MobData> mobs;
    private List<WeaponData> weapons;

    public LobbyScreen(VeilfallGame game) {
        super(game);
        loadDatabaseData();

        Table root = new Table();
        root.setFillParent(true);
        root.pad(18f);
        stage.addActor(root);

        Label title = game.getUiTheme().label("VEILFALL — LOBBY");
        title.setFontScale(1.45f);
        root.add(title).left().expandX().row();
        playerLabel = game.getUiTheme().label("");
        characterLabel = game.getUiTheme().label("");
        root.add(playerLabel).left().padTop(12f).row();
        root.add(characterLabel).left().padTop(4f).row();

        Table navigation = new Table();
        addNavigationButton(navigation, "LOADOUT", this::showLoadout);
        addNavigationButton(navigation, "PROFILE", this::showProfile);
        addNavigationButton(navigation, "CHARACTERS", this::showCharacters);
        addNavigationButton(navigation, "ENEMIES", this::showMobs);
        addNavigationButton(navigation, "WEAPONS", this::showWeapons);
        addNavigationButton(navigation, "HISTORY", this::showHistory);
        addNavigationButton(navigation, "SETTINGS", game::showSettings);
        root.add(navigation).left().padTop(16f).row();

        content.top().left().pad(12f);
        ScrollPane contentScroll = new ScrollPane(content, new ScrollPane.ScrollPaneStyle());
        contentScroll.setFadeScrollBars(false);
        root.add(contentScroll).fill().expand().padTop(8f).row();
        TextButton startButton = game.getUiTheme().button("START");
        startButton.addListener(new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                game.showArenaSelect();
            }
        });
        root.add(startButton).right().width(150f).height(42f).padTop(8f);
        refreshHeader();
        showLoadout();
    }

    private void loadDatabaseData() {
        try {
            player = game.getPlayerRepository().getPlayerProfile()
                    .orElseThrow(() -> new SQLException("Player profile is missing"));
            characters = game.getCharacterRepository().getAll();
            mobs = game.getMobRepository().getAll();
            weapons = game.getWeaponRepository().getAll();
            if (characters.isEmpty()) {
                throw new SQLException("No characters are available");
            }
            if (game.getSelectedCharacter() == null
                    || characters.stream().noneMatch(character ->
                    character.getId() == game.getSelectedCharacter().getId())) {
                game.setSelectedCharacter(characters.getFirst());
            }
            if (game.getSelectedWeapon() == null || game.getSelectedWeapon().getCharacterId()
                    != game.getSelectedCharacter().getId()) {
                WeaponData defaultWeapon = weapons.stream()
                        .filter(weapon -> weapon.getCharacterId() == game.getSelectedCharacter().getId())
                        .findFirst()
                        .orElseThrow(() -> new SQLException("No weapon is assigned to the selected character"));
                game.setSelectedWeapon(defaultWeapon);
            }
        } catch (SQLException exception) {
            throw new GdxRuntimeException("Failed to load lobby data from SQLite", exception);
        }
    }

    private void refreshHeader() {
        CharacterData selected = game.getSelectedCharacter();
        playerLabel.setText("Player: " + player.getName() + "    Level: " + player.getLevel());
        characterLabel.setText("Selected character: " + selected.getName()
                + "    HP: " + selected.getHp() + "    Attack: " + selected.getAttack()
                + "    Weapon: " + (game.getSelectedWeapon() == null ? "None"
                : game.getSelectedWeapon().getName() + "  •  DMG " + game.getSelectedWeapon().getDamage()
                + "  •  " + game.getSelectedWeapon().getAttackSpeed() + "/s"));
    }

    private void addNavigationButton(Table navigation, String title, Runnable action) {
        TextButton button = game.getUiTheme().button(title);
        button.addListener(new ChangeListener() {
            @Override
            public void changed(ChangeEvent event, Actor actor) {
                action.run();
            }
        });
        navigation.add(button).width(112f).height(38f).padRight(8f);
    }

    private void showProfile() {
        content.clearChildren();
        addContentLine("PROFILE");
        addContentLine("Name: " + player.getName());
        addContentLine("Level: " + player.getLevel());
        addContentLine("Experience: " + player.getExperience());
        addContentLine("Wins: " + player.getWins() + "    Losses: " + player.getLosses()
                + "    Battles: " + player.getBattles());
        addContentLine("Enemies defeated: " + player.getEnemiesDefeated() + "    Bosses: "
                + player.getBossesDefeated() + "    Best wave: " + player.getBestWave());
    }

    private void showLoadout() {
        content.clearChildren();
        addContentLine("CHOOSE YOUR FIGHTER");
        Table characterCards = new Table();
        for (CharacterData character : characters) {
            boolean selected = character.getId() == game.getSelectedCharacter().getId();
            TextButton card = game.getUiTheme().button((selected ? "▶  " : "") + character.getName()
                    + "\nHP " + character.getHp() + "   DMG " + character.getAttack()
                    + "   SPD " + character.getSpeed());
            card.addListener(new ChangeListener() {
                @Override public void changed(ChangeEvent event, Actor actor) {
                    game.setSelectedCharacter(character);
                    weapons.stream().filter(weapon -> weapon.getCharacterId() == character.getId())
                            .findFirst().ifPresent(game::setSelectedWeapon);
                    refreshHeader();
                    showLoadout();
                }
            });
            characterCards.add(card).width(210f).height(66f).padRight(8f);
        }
        content.add(characterCards).left().padBottom(12f).row();

        CharacterData selected = game.getSelectedCharacter();
        CharacterKit kit = CharacterKit.forCharacter(selected);
        addContentLine(selected.getName() + " — " + kit.getDescription());
        addContentLine("BASIC: " + kit.getBasicAttack() + "   Q: " + kit.getAbilityQ()
                + "   E: " + kit.getAbilityE() + "   R: " + kit.getAbilityR());
        addContentLine("CHOOSE WEAPON — each weapon changes damage, attack speed, reach, and its model");
        addWeaponChoices(content, false);
    }

    private void addWeaponChoices(Table target, boolean includeAll) {
        for (WeaponData weapon : weapons) {
            if (!includeAll && weapon.getCharacterId() != game.getSelectedCharacter().getId()) continue;
            boolean equipped = game.getSelectedWeapon() != null
                    && weapon.getId() == game.getSelectedWeapon().getId();
            TextButton choice = game.getUiTheme().button((equipped ? "EQUIPPED  ▶  " : "EQUIP  •  ")
                    + weapon.getName() + "\nDamage " + weapon.getDamage() + "   Attack speed "
                    + weapon.getAttackSpeed() + "/s   Range " + weapon.getRange());
            choice.addListener(new ChangeListener() {
                @Override public void changed(ChangeEvent event, Actor actor) {
                    game.setSelectedWeapon(weapon);
                    refreshHeader();
                    if (includeAll) showWeapons(); else showLoadout();
                }
            });
            target.add(choice).left().width(520f).height(48f).padBottom(6f).row();
        }
    }

    private void showHistory() {
        content.clearChildren();
        addContentLine("MATCH HISTORY — latest 30 runs");
        try {
            var history = game.getMatchRepository().getMatchHistory();
            if (history.isEmpty()) addContentLine("No runs yet. Choose a loadout and enter an arena.");
            for (var match : history) {
                addContentLine(match.getResult() + " — " + match.getArenaName() + " — "
                        + match.getCharacterName() + " / " + match.getWeaponName());
                addContentLine("Wave " + match.getWavesReached() + " — " + match.getEnemiesDefeated()
                        + " defeats — " + match.getBossesDefeated() + " bosses — " + match.getPlayedAt());
            }
        } catch (SQLException exception) {
            throw new GdxRuntimeException("Failed to load match history", exception);
        }
    }

    private void showCharacters() {
        content.clearChildren();
        addContentLine("CHARACTERS — select one to use in battle");
        for (CharacterData character : characters) {
            TextButton button = game.getUiTheme().button(character.getName() + " — HP " + character.getHp()
                    + " — Attack " + character.getAttack());
            button.setChecked(character.getId() == game.getSelectedCharacter().getId());
            button.addListener(new ChangeListener() {
                @Override
                public void changed(ChangeEvent event, Actor actor) {
                    game.setSelectedCharacter(character);
                    weapons.stream().filter(weapon -> weapon.getCharacterId() == character.getId())
                            .findFirst().ifPresent(game::setSelectedWeapon);
                    refreshHeader();
                    showCharacters();
                }
            });
            content.add(button).left().width(340f).height(34f).padBottom(6f).row();
        }
        CharacterData selected = game.getSelectedCharacter();
        CharacterKit kit = CharacterKit.forCharacter(selected);
        addContentLine("");
        addContentLine(selected.getName() + " — " + kit.getDescription());
        addContentLine("HP " + selected.getHp() + "   Attack " + selected.getAttack()
                + "   Defense " + selected.getDefense() + "   Speed " + selected.getSpeed()
                + "   Range " + selected.getRange());
        weapons.stream().filter(weapon -> weapon.getCharacterId() == selected.getId()).findFirst()
                .ifPresent(weapon -> addContentLine("Weapon: " + weapon.getName() + " — Damage "
                        + weapon.getDamage() + " — Speed " + weapon.getAttackSpeed()
                        + " — Range " + weapon.getRange()));
        addContentLine("Basic attack: " + kit.getBasicAttack());
        addContentLine("Q: " + kit.getAbilityQ() + "    E: " + kit.getAbilityE()
                + "    R: " + kit.getAbilityR());
        addContentLine("");
        addContentLine("CHOOSE WEAPON");
        for (WeaponData weapon : weapons) {
            if (weapon.getCharacterId() != selected.getId()) continue;
            boolean equipped = game.getSelectedWeapon() != null
                    && weapon.getId() == game.getSelectedWeapon().getId();
            TextButton equip = game.getUiTheme().button((equipped ? "EQUIPPED — " : "EQUIP — ")
                    + weapon.getName() + " — Damage " + weapon.getDamage()
                    + " — Speed " + weapon.getAttackSpeed() + " — Range " + weapon.getRange());
            equip.addListener(new ChangeListener() {
                @Override
                public void changed(ChangeEvent event, Actor actor) {
                    game.setSelectedWeapon(weapon);
                    refreshHeader();
                    showCharacters();
                }
            });
            content.add(equip).left().width(540f).height(34f).padBottom(5f).row();
        }
    }

    private void showMobs() {
        content.clearChildren();
        addContentLine("ARENA ENEMY ROSTER");
        addContentLine("Enemy types come from each arena's wave plan. Open START to preview the wave roster and final boss.");
        for (MobData mob : mobs) {
            addContentLine(mob.getName() + " — " + mob.getType() + " — HP " + mob.getHp()
                    + " — Damage " + mob.getDamage());
        }
    }

    private void showWeapons() {
        content.clearChildren();
        addContentLine("WEAPON LOADOUT — equip a weapon for " + game.getSelectedCharacter().getName());
        addWeaponChoices(content, false);
    }

    private void addContentLine(String text) {
        Label label = game.getUiTheme().label(text);
        label.setAlignment(Align.left);
        content.add(label).left().padBottom(7f).row();
    }
}
