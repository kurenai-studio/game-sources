package com.veilfall.game.player;

import com.veilfall.game.data.CharacterData;

import java.util.Locale;

/** Defines the combat identity and selection copy for each currently playable character. */
public enum CharacterKit {
    WARDEN("Warden", "Sword Slash", "Shield Bash", "Ground Slam", "Veil Guard",
            "A durable close-range fighter. Bash enemies ahead, slam nearby foes, and reduce incoming damage."),
    ARCHER("Veil Archer", "Bow Shot", "Piercing Shot", "Arrow Volley", "Veilstep",
            "A mobile ranged fighter. Fire a focused shot, sweep a volley across enemies, and dash through danger."),
    MAGE("Ash Mage", "Arcane Bolt", "Arcane Lance", "Veil Nova", "Aether Ward",
            "A fragile spellcaster. Launch a piercing bolt, blast nearby enemies, and ward against incoming damage.");

    private final String characterName;
    private final String basicAttack;
    private final String abilityQ;
    private final String abilityE;
    private final String abilityR;
    private final String description;

    CharacterKit(String characterName, String basicAttack, String abilityQ,
                 String abilityE, String abilityR, String description) {
        this.characterName = characterName;
        this.basicAttack = basicAttack;
        this.abilityQ = abilityQ;
        this.abilityE = abilityE;
        this.abilityR = abilityR;
        this.description = description;
    }

    public String getBasicAttack() { return basicAttack; }
    public String getAbilityQ() { return abilityQ; }
    public String getAbilityE() { return abilityE; }
    public String getAbilityR() { return abilityR; }
    public String getDescription() { return description; }

    public static CharacterKit forCharacter(CharacterData character) {
        String name = character.getName().toLowerCase(Locale.ROOT);
        for (CharacterKit kit : values()) {
            if (kit.characterName.toLowerCase(Locale.ROOT).equals(name)) return kit;
        }
        throw new IllegalArgumentException("No playable combat kit is configured for " + character.getName());
    }
}
