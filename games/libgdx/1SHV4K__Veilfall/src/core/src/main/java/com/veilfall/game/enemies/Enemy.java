package com.veilfall.game.enemies;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.g3d.Material;
import com.badlogic.gdx.graphics.g3d.Attribute;
import com.badlogic.gdx.graphics.g3d.Model;
import com.badlogic.gdx.graphics.g3d.ModelInstance;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;
import com.veilfall.game.data.MobData;
import com.veilfall.game.player.Player;
import com.veilfall.game.rendering.ModelAssets;

public final class Enemy implements Disposable {
    private static final long ATTRIBUTES = VertexAttributes.Usage.Position | VertexAttributes.Usage.Normal;
    private static final float ATTACK_COOLDOWN = 1.1f;
    private static final float DEATH_DURATION = 0.45f;
    private static final Color HIT_COLOR = new Color(1f, 0.78f, 0.68f, 1f);
    private static final Color WARNING_COLOR = new Color(1f, 0.2f, 0.12f, 1f);

    private final MobData data;
    private final int maxHealth;
    private final Vector3 position = new Vector3();
    private final Array<Model> models = new Array<>();
    private final Array<ModelInstance> instances = new Array<>();
    private int currentHealth;
    private float attackCooldown;
    private float hitFlash;
    private float deathTimer = -1f;
    private float knockbackRemaining;
    private float knockbackX;
    private float knockbackZ;
    private float bossWindupRemaining;
    private ModelInstance bossWarning;
    private ModelInstance stylizedBody;
    private final Color bodyColor;

    public Enemy(MobData data, float x, float z, ModelAssets modelAssets) {
        this.data = data;
        bodyColor = colorFor(data);
        maxHealth = data.getHp();
        currentHealth = maxHealth;
        position.set(x, 0f, z);
        createModel(modelAssets);
        updateModel();
    }

    public MobData getData() { return data; }
    public float getX() { return position.x; }
    public float getZ() { return position.z; }
    public int getCurrentHealth() { return currentHealth; }
    public int getMaxHealth() { return maxHealth; }
    public boolean isAlive() { return currentHealth > 0; }
    public boolean isRemoved() { return deathTimer >= DEATH_DURATION; }
    public Vector3 getPosition() { return position; }
    public float getAttackCooldown() { return attackCooldown; }
    public boolean canAttack() { return attackCooldown <= 0f && isAlive(); }
    public boolean isKnockedBack() { return knockbackRemaining > 0f; }
    public boolean isBossTelegraphing() { return bossWindupRemaining > 0f; }
    public String getBossAttackName() {
        String attack = switch (data.getType()) {
            case "BOSS_NOVA" -> "Cinder Nova";
            case "BOSS_SURGE" -> "Tidal Surge";
            default -> "Veil Cleave";
        };
        return currentHealth <= maxHealth / 2 ? "ENRAGED " + attack : attack;
    }

    public Iterable<ModelInstance> getInstances() {
        return instances;
    }

    public void updateTimers(float delta) {
        if (attackCooldown > 0f) attackCooldown -= delta;
        if (knockbackRemaining > 0f) {
            float step = Math.min(knockbackRemaining, delta);
            position.x += knockbackX * step;
            position.z += knockbackZ * step;
            knockbackRemaining = Math.max(0f, knockbackRemaining - delta);
            updateModel();
        }
        if (hitFlash > 0f) {
            hitFlash -= delta;
            if (hitFlash <= 0f) {
                setBodyColor(bodyColor);
            }
        }
        if (!isAlive() && deathTimer >= 0f) {
            deathTimer += delta;
            float scale = Math.max(0.02f, 1f - deathTimer / DEATH_DURATION);
            for (int i = 0; i < 2; i++) {
                instances.get(i).transform.setToTranslation(position.x, (i == 0 ? 0.75f : 1.38f) * scale,
                        position.z).scale(scale, scale, scale);
            }
            instances.get(2).transform.setToTranslation(position.x, 1.8f * scale, position.z)
                    .scale(scale, scale, scale);
            instances.get(3).transform.setToTranslation(position.x, 1.8f * scale, position.z)
                    .scale(scale, scale, scale);
        }
    }

    public void moveToward(float targetX, float targetZ, float delta) {
        if (!isAlive()) return;
        float dx = targetX - position.x;
        float dz = targetZ - position.z;
        float distance = (float) Math.sqrt(dx * dx + dz * dz);
        if (distance <= 0.001f) return;
        float step = Math.min((float) data.getSpeed() * delta, distance);
        position.x += dx / distance * step;
        position.z += dz / distance * step;
        updateModel();
    }

    public void takeDamage(int amount, float directionX, float directionZ, float knockbackForce) {
        if (!isAlive()) return;
        currentHealth = MathUtils.clamp(currentHealth - amount, 0, maxHealth);
        if (!isAlive()) {
            deathTimer = 0f;
        } else {
            hitFlash = 0.14f;
            setBodyColor(HIT_COLOR);
            float directionLength = (float) Math.sqrt(directionX * directionX + directionZ * directionZ);
            if (directionLength > 0.001f && knockbackForce > 0f) {
                knockbackX = directionX / directionLength * knockbackForce;
                knockbackZ = directionZ / directionLength * knockbackForce;
                knockbackRemaining = 0.12f;
            }
        }
        updateHealthBar();
        updateBossWarning();
    }

    public void attack(Player player) {
        if (!canAttack()) return;
        attackCooldown = ATTACK_COOLDOWN;
        player.takeDamage(data.getDamage());
    }

    public void updateBossCombat(Player player, float distance, float delta) {
        if (!data.isBoss() || !isAlive() || player.isDead() || isKnockedBack()) return;
        if (bossWindupRemaining > 0f) {
            bossWindupRemaining = Math.max(0f, bossWindupRemaining - delta);
            if (bossWindupRemaining <= 0f) {
                resolveBossAttack(player);
                attackCooldown = currentHealth <= maxHealth / 2 ? 1.55f
                        : data.getType().equals("BOSS_NOVA") ? 2.7f : 2.3f;
            }
            updateBossWarning();
            return;
        }
        float triggerRange = data.getType().equals("BOSS_NOVA") ? 9f
                : data.getType().equals("BOSS_SURGE") ? 7f : (float) data.getRange() + 1.6f;
        if (attackCooldown <= 0f && distance <= triggerRange) {
            bossWindupRemaining = currentHealth <= maxHealth / 2 ? 0.62f : 0.85f;
            updateBossWarning();
        }
    }

    private void resolveBossAttack(Player player) {
        float dx = player.getX() - position.x;
        float dz = player.getZ() - position.z;
        float distance = (float) Math.sqrt(dx * dx + dz * dz);
        float radius = data.getType().equals("BOSS_NOVA") ? 7.2f
                : data.getType().equals("BOSS_SURGE") ? 5.2f : (float) data.getRange() + 1.1f;
        if (distance <= radius) {
            int damage = currentHealth <= maxHealth / 2 ? Math.round(data.getDamage() * 1.3f) : data.getDamage();
            player.takeDamage(damage);
            if (data.getType().equals("BOSS_SURGE")) player.knockbackFrom(position.x, position.z, 2.4f);
        }
    }

    private void updateBossWarning() {
        if (bossWarning == null) return;
        float radius = data.getType().equals("BOSS_NOVA") ? 7.2f
                : data.getType().equals("BOSS_SURGE") ? 5.2f : (float) data.getRange() + 1.1f;
        float scale = bossWindupRemaining > 0f && isAlive() ? radius : 0.001f;
        bossWarning.transform.setToTranslation(position.x, 0.055f, position.z).scale(scale, 1f, scale);
    }

    private void createModel(ModelAssets modelAssets) {
        ModelBuilder builder = new ModelBuilder();
        Color enemyColor = new Color(bodyColor);
        models.add(builder.createBox(0.82f, 1.15f, 0.6f,
                new Material(ColorAttribute.createDiffuse(enemyColor)), ATTRIBUTES));
        models.add(builder.createBox(0.58f, 0.58f, 0.58f,
                new Material(ColorAttribute.createDiffuse(new Color(0.23f, 0.16f, 0.20f, 1f))), ATTRIBUTES));
        models.add(builder.createBox(1.05f, 0.12f, 0.12f,
                new Material(ColorAttribute.createDiffuse(new Color(0.12f, 0.12f, 0.14f, 1f))), ATTRIBUTES));
        models.add(builder.createBox(1f, 0.08f, 0.08f,
                new Material(ColorAttribute.createDiffuse(new Color(0.25f, 0.82f, 0.35f, 1f))), ATTRIBUTES));
        if (data.isBoss()) {
            models.add(builder.createCylinder(2f, 0.07f, 2f, 24,
                    new Material(ColorAttribute.createDiffuse(WARNING_COLOR)), ATTRIBUTES));
        }
        for (Model model : models) {
            instances.add(new ModelInstance(model));
        }
        if (data.isBoss()) bossWarning = instances.get(4);
        String bodyMesh = data.getType().equals("ELITE") || data.isBoss()
                ? "character-orc" : "character-human";
        stylizedBody = new ModelInstance(modelAssets.get("kenney-mini-dungeon", bodyMesh));
        for (Material material : stylizedBody.materials) {
            Attribute diffuseAttribute = material.get(ColorAttribute.Diffuse);
            if (diffuseAttribute instanceof ColorAttribute diffuse) diffuse.color.set(bodyColor);
        }
        instances.add(stylizedBody);
    }

    private void updateModel() {
        float bodyScale = data.isBoss() ? 2.2f : 1f;
        float headScale = data.isBoss() ? 1.7f : 1f;
        instances.get(0).transform.setToTranslation(position.x, -10f, position.z)
                .scale(0.001f, 0.001f, 0.001f);
        instances.get(1).transform.setToTranslation(position.x, -10f, position.z)
                .scale(0.001f, 0.001f, 0.001f);
        float meshScale = data.isBoss() ? 10.5f : data.getType().equals("ELITE") ? 8.2f : 6.8f;
        float facingAngle = MathUtils.radiansToDegrees * (float) Math.atan2(-position.x, -position.z);
        stylizedBody.transform.setToTranslation(position.x - meshScale * 0.08f, 0f, position.z)
                .rotate(Vector3.Y, facingAngle).scale(meshScale, meshScale, meshScale);
        updateHealthBar();
        updateBossWarning();
    }

    private void updateHealthBar() {
        float ratio = currentHealth / (float) maxHealth;
        float width = data.isBoss() ? 0f : 0.95f * ratio;
        float y = data.isBoss() ? 0f : 1.52f;
        instances.get(2).transform.setToTranslation(position.x, y, position.z)
                .scale(data.isBoss() ? 0.001f : 1f, 1f, 1f);
        instances.get(3).transform.setToTranslation(position.x - 0.475f + width * 0.5f,
                y, position.z + 0.01f).scale(width, 1f, 1f);
    }

    private void setBodyColor(Color color) {
        for (int i = 0; i < 2; i++) {
            ColorAttribute diffuse = (ColorAttribute) instances.get(i).materials.first().get(ColorAttribute.Diffuse);
            diffuse.color.set(color);
        }
        for (Material material : stylizedBody.materials) {
            Attribute diffuseAttribute = material.get(ColorAttribute.Diffuse);
            if (diffuseAttribute instanceof ColorAttribute diffuse) diffuse.color.set(color);
        }
    }

    private static Color colorFor(MobData mob) {
        return switch (mob.getType()) {
            case "BOSS_NOVA" -> new Color(1f, 0.33f, 0.10f, 1f);
            case "BOSS_SURGE" -> new Color(0.20f, 0.78f, 1f, 1f);
            case "BOSS" -> new Color(0.96f, 0.24f, 0.38f, 1f);
            case "ELITE" -> new Color(0.95f, 0.49f, 0.16f, 1f);
            default -> mob.getName().toLowerCase().contains("bone")
                    ? new Color(0.92f, 0.84f, 0.61f, 1f)
                    : new Color(0.50f, 0.92f, 0.47f, 1f);
        };
    }

    @Override
    public void dispose() {
        for (Model model : models) {
            model.dispose();
        }
        models.clear();
        instances.clear();
    }
}
