package com.veilfall.game.player;

import com.veilfall.game.data.SkillData;
import com.veilfall.game.enemies.EnemyManager;
import com.veilfall.game.audio.AudioDirector;

import java.util.List;

public final class PlayerCombat {
    private static final float DODGE_DURATION = 0.18f;
    private static final float ARCHER_DODGE_DURATION = 0.3f;
    private static final float DODGE_COOLDOWN = 1f;

    private final Player player;
    private final AudioDirector audio;
    private final CharacterKit kit;
    private final CombatEffects effects = new CombatEffects();
    private final float attackRange;
    private final float attackCooldown;
    private final int attackDamage;
    private final SkillData abilityQ;
    private final SkillData abilityE;
    private final SkillData abilityR;
    private float attackCooldownRemaining;
    private float cooldownQ;
    private float cooldownE;
    private float cooldownR;
    private float dodgeCooldownRemaining;

    public PlayerCombat(Player player, List<SkillData> skills, AudioDirector audio) {
        this.player = player;
        this.audio = audio;
        kit = CharacterKit.forCharacter(player.getCharacter());
        attackRange = (float) player.getWeapon().getRange();
        attackCooldown = 1f / (float) player.getWeapon().getAttackSpeed();
        attackDamage = player.getWeapon().getDamage();
        abilityQ = requiredSkill(skills, "Q", player);
        abilityE = requiredSkill(skills, "E", player);
        abilityR = requiredSkill(skills, "R", player);
    }

    public void update(float delta) {
        attackCooldownRemaining = Math.max(0f, attackCooldownRemaining - delta);
        cooldownQ = Math.max(0f, cooldownQ - delta);
        cooldownE = Math.max(0f, cooldownE - delta);
        cooldownR = Math.max(0f, cooldownR - delta);
        dodgeCooldownRemaining = Math.max(0f, dodgeCooldownRemaining - delta);
        player.update(delta);
        effects.update(delta);
    }

    public boolean attack(EnemyManager enemies) {
        if (attackCooldownRemaining > 0f || player.isDead()) return false;
        attackCooldownRemaining = attackCooldown;
        player.triggerBasicAttack();
        effects.basicAttack(kit, player);
        audio.playAttack(kit, false);
        if (kit == CharacterKit.WARDEN) {
            return enemies.damageInRange(player.getX(), player.getZ(), attackRange, attackDamage, 1f) > 0;
        }
        // Ranged basic attacks strike the closest enemy in the direction the character faces.
        return enemies.damageNearestInFront(player.getX(), player.getZ(), player.getFacing().x,
                player.getFacing().z, attackRange, attackDamage, kit == CharacterKit.ARCHER ? 1.2f : 0.4f);
    }

    public boolean abilityQ(EnemyManager enemies) {
        if (cooldownQ > 0f || player.isDead()) return false;
        cooldownQ = (float) abilityQ.getCooldown();
        player.triggerAbilityEffect();
        effects.abilityQ(kit, player);
        audio.playAttack(kit, true);
        return switch (kit) {
            case WARDEN -> enemies.damageInFront(player.getX(), player.getZ(), player.getFacing().x,
                    player.getFacing().z, Math.min(attackRange * 1.5f, 2.5f), abilityQ.getDamage(), 7f) > 0;
            case ARCHER -> enemies.damageNearestInFront(player.getX(), player.getZ(), player.getFacing().x,
                    player.getFacing().z, (float) player.getCharacter().getRange(), abilityQ.getDamage(), 2.5f);
            case MAGE -> enemies.damageNearestInFront(player.getX(), player.getZ(), player.getFacing().x,
                    player.getFacing().z, (float) player.getCharacter().getRange(), abilityQ.getDamage(), 1f);
        };
    }

    public boolean abilityE(EnemyManager enemies) {
        if (cooldownE > 0f || player.isDead()) return false;
        cooldownE = (float) abilityE.getCooldown();
        effects.abilityE(kit, player);
        audio.playAttack(kit, true);
        return switch (kit) {
            case WARDEN -> enemies.damageInRange(player.getX(), player.getZ(),
                    Math.max(attackRange * 2f, 3.25f), abilityE.getDamage(), 5f) > 0;
            case ARCHER -> enemies.damageInFront(player.getX(), player.getZ(), player.getFacing().x,
                    player.getFacing().z, (float) player.getCharacter().getRange(), abilityE.getDamage(), 2f) > 0;
            case MAGE -> enemies.damageInRange(player.getX(), player.getZ(), 4f,
                    abilityE.getDamage(), 4f) > 0;
        };
    }

    public boolean abilityR() {
        if (cooldownR > 0f || player.isDead()) return false;
        cooldownR = (float) abilityR.getCooldown();
        if (kit == CharacterKit.ARCHER) {
            player.startDodge(player.getFacing().x, player.getFacing().z, ARCHER_DODGE_DURATION);
        } else {
            player.activateGuard(kit == CharacterKit.WARDEN ? 3f : 4f);
        }
        effects.abilityR(kit, player);
        audio.playAttack(kit, true);
        return true;
    }

    public boolean dodge(float directionX, float directionZ) {
        if (dodgeCooldownRemaining > 0f || player.isDead()) return false;
        dodgeCooldownRemaining = DODGE_COOLDOWN;
        player.startDodge(directionX, directionZ, DODGE_DURATION);
        return true;
    }

    public CharacterKit getKit() { return kit; }
    public SkillData getAbilityQ() { return abilityQ; }
    public SkillData getAbilityE() { return abilityE; }
    public SkillData getAbilityR() { return abilityR; }
    public float getCooldownQ() { return cooldownQ; }
    public float getCooldownE() { return cooldownE; }
    public float getCooldownR() { return cooldownR; }
    public float getDodgeCooldownRemaining() { return dodgeCooldownRemaining; }

    public void appendEffectInstances(com.badlogic.gdx.utils.Array<com.badlogic.gdx.graphics.g3d.ModelInstance> destination) {
        effects.appendInstances(destination);
    }

    public void dispose() { effects.dispose(); }

    private static SkillData requiredSkill(List<SkillData> skills, String key, Player player) {
        return skills.stream()
                .filter(skill -> skill.getCharacterId() == player.getCharacter().getId())
                .filter(skill -> skill.getKeyBinding().equalsIgnoreCase(key))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Missing " + key + " ability for "
                        + player.getCharacter().getName()));
    }
}
