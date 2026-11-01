package com.veilfall.game.player;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.g3d.Material;
import com.badlogic.gdx.graphics.g3d.Model;
import com.badlogic.gdx.graphics.g3d.ModelInstance;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;
import com.veilfall.game.data.CharacterData;
import com.veilfall.game.data.WeaponData;
import com.veilfall.game.rendering.ModelAssets;

public final class Player implements Disposable {
    private static final long ATTRIBUTES = VertexAttributes.Usage.Position | VertexAttributes.Usage.Normal;
    private static final float ARENA_LIMIT = 24f;
    private static final Color ARMOR_COLOR = new Color(0.22f, 0.34f, 0.48f, 1f);
    private static final Color GUARD_COLOR = new Color(0.30f, 0.58f, 0.92f, 1f);
    private static final Color DODGE_COLOR = new Color(0.82f, 0.88f, 1f, 1f);

    private final CharacterData character;
    private final WeaponData weapon;
    private final int maxHealth;
    private final Array<Model> models = new Array<>();
    private final Array<ModelInstance> instances = new Array<>();
    private final Vector3 position = new Vector3(0f, 0f, 0f);
    private final Vector3 facing = new Vector3(1f, 0f, 0f);
    private final Vector3 dodgeDirection = new Vector3();
    private final Array<ModelInstance> weaponInstances = new Array<>();
    private final Color armorColor;
    private ModelInstance effectInstance;
    private int currentHealth;
    private float attackEffectRemaining;
    private float guardRemaining;
    private float invulnerabilityRemaining;
    private float dodgeMovementRemaining;
    private float dodgeDuration;

    public Player(CharacterData character, WeaponData weapon, ModelAssets modelAssets) {
        this.character = character;
        this.weapon = weapon;
        maxHealth = character.getHp();
        currentHealth = maxHealth;
        armorColor = character.getName().equalsIgnoreCase("Veil Archer")
                ? new Color(0.28f, 0.48f, 0.32f, 1f)
                : character.getName().equalsIgnoreCase("Ash Mage")
                ? new Color(0.48f, 0.29f, 0.58f, 1f) : new Color(ARMOR_COLOR);
        createModel(modelAssets);
        updateModel();
    }

    public CharacterData getCharacter() { return character; }
    public WeaponData getWeapon() { return weapon; }
    public int getCurrentHealth() { return currentHealth; }
    public int getMaxHealth() { return maxHealth; }
    public float getX() { return position.x; }
    public float getZ() { return position.z; }
    public Vector3 getPosition() { return position; }
    public boolean isDead() { return currentHealth <= 0; }
    public boolean isGuarding() { return guardRemaining > 0f; }
    public boolean isInvulnerable() { return invulnerabilityRemaining > 0f; }
    public boolean isDodging() { return dodgeMovementRemaining > 0f; }
    public float getGuardRemaining() { return guardRemaining; }
    public Vector3 getFacing() { return facing; }

    public Iterable<ModelInstance> getInstances() {
        return instances;
    }

    public void move(float x, float z) {
        if (isDodging()) return;
        if (x != 0f || z != 0f) {
            facing.set(x, 0f, z).nor();
        }
        position.x = MathUtils.clamp(position.x + x, -ARENA_LIMIT, ARENA_LIMIT);
        position.z = MathUtils.clamp(position.z + z, -ARENA_LIMIT, ARENA_LIMIT);
        updateModel();
    }

    public boolean moveToward(float targetX, float targetZ, float delta) {
        float dx = targetX - position.x;
        float dz = targetZ - position.z;
        float distance = (float) Math.sqrt(dx * dx + dz * dz);
        if (distance <= 0.12f) return true;
        float step = Math.min((float) character.getSpeed() * delta, distance);
        move(dx / distance * step, dz / distance * step);
        return distance <= step + 0.12f;
    }

    public void faceTowards(float targetX, float targetZ) {
        float dx = targetX - position.x;
        float dz = targetZ - position.z;
        if (dx * dx + dz * dz > 0.001f) {
            facing.set(dx, 0f, dz).nor();
            updateModel();
        }
    }

    public void knockbackFrom(float sourceX, float sourceZ, float distance) {
        float dx = position.x - sourceX;
        float dz = position.z - sourceZ;
        float length = (float) Math.sqrt(dx * dx + dz * dz);
        if (length < 0.001f) return;
        position.x = MathUtils.clamp(position.x + dx / length * distance, -ARENA_LIMIT, ARENA_LIMIT);
        position.z = MathUtils.clamp(position.z + dz / length * distance, -ARENA_LIMIT, ARENA_LIMIT);
        updateModel();
    }

    public void update(float delta) {
        attackEffectRemaining = Math.max(0f, attackEffectRemaining - delta);
        guardRemaining = Math.max(0f, guardRemaining - delta);
        invulnerabilityRemaining = Math.max(0f, invulnerabilityRemaining - delta);
        if (dodgeMovementRemaining > 0f) {
            float step = Math.min(2.8f * delta / dodgeDuration,
                    2.8f * dodgeMovementRemaining / dodgeDuration);
            position.x = MathUtils.clamp(position.x + dodgeDirection.x * step, -ARENA_LIMIT, ARENA_LIMIT);
            position.z = MathUtils.clamp(position.z + dodgeDirection.z * step, -ARENA_LIMIT, ARENA_LIMIT);
            dodgeMovementRemaining = Math.max(0f, dodgeMovementRemaining - delta);
        }
        updateModel();
    }

    public void triggerAttackEffect() {
        attackEffectRemaining = 0.18f;
        updateModel();
    }

    public void triggerBasicAttack() {
        triggerAttackEffect();
    }

    public void triggerAbilityEffect() {
        triggerAttackEffect();
    }

    public void activateGuard(float duration) {
        guardRemaining = duration;
    }

    public void startDodge(float directionX, float directionZ, float duration) {
        dodgeDirection.set(directionX, 0f, directionZ);
        if (dodgeDirection.isZero(0.001f)) {
            dodgeDirection.set(facing);
        } else {
            dodgeDirection.nor();
            facing.set(dodgeDirection);
        }
        dodgeMovementRemaining = duration;
        dodgeDuration = duration;
        invulnerabilityRemaining = 0.35f;
    }

    public boolean takeDamage(int rawDamage) {
        if (isDead() || isInvulnerable()) {
            return false;
        }
        float guardMultiplier = isGuarding() ? 0.25f : 1f;
        int guardedDamage = Math.max(1, Math.round(rawDamage * guardMultiplier));
        int mitigatedDamage = Math.max(1, guardedDamage - character.getDefense());
        currentHealth = MathUtils.clamp(currentHealth - mitigatedDamage, 0, maxHealth);
        updateModel();
        return true;
    }

    private void createModel(ModelAssets modelAssets) {
        ModelBuilder builder = new ModelBuilder();
        Model torso = box(builder, 0.75f, 1.05f, 0.42f, armorColor);
        Model head = box(builder, 0.48f, 0.48f, 0.48f, new Color(0.74f, 0.59f, 0.43f, 1f));
        Model limb = box(builder, 0.24f, 0.78f, 0.28f, new Color(0.25f, 0.29f, 0.34f, 1f));
        Model arm = box(builder, 0.23f, 0.72f, 0.25f, new Color(0.74f, 0.59f, 0.43f, 1f));
        Model effect = builder.createCylinder(2f, 0.06f, 2f, 20,
                new Material(ColorAttribute.createDiffuse(new Color(0.25f, 0.7f, 1f, 0.55f))),
                ATTRIBUTES);
        models.addAll(torso, head, limb, arm, effect);
        instances.add(new ModelInstance(torso));
        instances.add(new ModelInstance(head));
        instances.add(new ModelInstance(limb));
        instances.add(new ModelInstance(limb));
        instances.add(new ModelInstance(arm));
        instances.add(new ModelInstance(arm));
        String bodyMesh = character.getName().equalsIgnoreCase("Warden")
                ? "character-orc" : "character-human";
        ModelInstance characterMesh = new ModelInstance(modelAssets.get("kenney-mini-dungeon", bodyMesh));
        tintCharacterMesh(characterMesh, character.getName());
        instances.add(characterMesh);
        createWeaponModel(builder, modelAssets);
        effectInstance = new ModelInstance(effect);
        instances.add(effectInstance);
    }

    private void createWeaponModel(ModelBuilder builder, ModelAssets modelAssets) {
        if (isBowWeapon()) {
            boolean longshot = weapon.getName().equalsIgnoreCase("Longshot Recurve");
            Color wood = longshot ? new Color(0.66f, 0.43f, 0.19f, 1f)
                    : new Color(0.25f, 0.40f, 0.27f, 1f);
            Color string = longshot ? new Color(0.88f, 0.71f, 0.36f, 1f)
                    : new Color(0.76f, 0.88f, 0.83f, 1f);
            float bowHeight = longshot ? 0.74f : 0.62f;
            addWeaponPart(box(builder, 0.10f, bowHeight, 0.11f, wood));
            addWeaponPart(box(builder, 0.10f, bowHeight, 0.11f, wood));
            addWeaponPart(box(builder, 0.035f, bowHeight * 1.45f, 0.035f, string));
            addWeaponPart(box(builder, 0.055f, longshot ? 0.88f : 0.72f, 0.055f,
                    longshot ? new Color(0.92f, 0.79f, 0.43f, 1f) : new Color(0.75f, 0.78f, 0.83f, 1f)));
        } else if (isStaffWeapon()) {
            Model staff = builder.createCylinder(0.12f, 1.55f, 0.12f, 8,
                    new Material(ColorAttribute.createDiffuse(new Color(0.43f, 0.25f, 0.15f, 1f))), ATTRIBUTES);
            float crystalSize = weapon.getName().equalsIgnoreCase("Ember Rod") ? 0.48f : 0.38f;
            Color crystalColor = weapon.getName().equalsIgnoreCase("Ember Rod")
                    ? new Color(1f, 0.39f, 0.13f, 1f) : new Color(0.39f, 0.73f, 1f, 1f);
            Model crystal = builder.createSphere(crystalSize, crystalSize, crystalSize, 10, 10,
                    new Material(ColorAttribute.createDiffuse(crystalColor)), ATTRIBUTES);
            addWeaponPart(staff);
            addWeaponPart(crystal);
        } else if (isMaulWeapon()) {
            Model shaft = builder.createCylinder(0.13f, 1.35f, 0.13f, 8,
                    new Material(ColorAttribute.createDiffuse(new Color(0.35f, 0.22f, 0.15f, 1f))), ATTRIBUTES);
            boolean gravebreaker = weapon.getName().equalsIgnoreCase("Gravebreaker Maul");
            Model head = box(builder, gravebreaker ? 0.90f : 0.72f, gravebreaker ? 0.48f : 0.35f,
                    gravebreaker ? 0.46f : 0.35f, gravebreaker
                            ? new Color(0.27f, 0.48f, 0.67f, 1f) : new Color(0.48f, 0.40f, 0.27f, 1f));
            addWeaponPart(shaft);
            addWeaponPart(head);
        } else if (weapon.getName().equalsIgnoreCase("Rusted Sword")) {
            addSharedWeaponPart(modelAssets.get("kenney-mini-dungeon", "weapon-sword"));
        } else {
            addWeaponPart(box(builder, 0.12f, 0.95f, 0.12f, new Color(0.76f, 0.80f, 0.84f, 1f)));
        }
    }

    private void addWeaponPart(Model model) {
        models.add(model);
        ModelInstance instance = new ModelInstance(model);
        weaponInstances.add(instance);
        instances.add(instance);
    }

    private void addSharedWeaponPart(Model model) {
        ModelInstance instance = new ModelInstance(model);
        weaponInstances.add(instance);
        instances.add(instance);
    }

    private static Model box(ModelBuilder builder, float width, float height, float depth, Color color) {
        return builder.createBox(width, height, depth,
                new Material(ColorAttribute.createDiffuse(color)),
                ATTRIBUTES);
    }

    private void updateModel() {
        // Keep the class-colored proxy available for guard flashes while the CC0 mesh supplies the silhouette.
        for (int index = 0; index < 6; index++) {
            instances.get(index).transform.setToTranslation(position.x, -10f, position.z)
                    .scale(0.001f, 0.001f, 0.001f);
        }
        float facingAngle = MathUtils.radiansToDegrees * (float) Math.atan2(facing.x, facing.z);
        float bodyScale = 6.5f;
        instances.get(6).transform.setToTranslation(position.x - bodyScale * 0.08f,
                        position.y, position.z)
                .rotate(Vector3.Y, facingAngle).scale(bodyScale, bodyScale, bodyScale);
        float attackSwing = attackEffectRemaining > 0f ? 35f : 0f;
        for (int index = 0; index < weaponInstances.size; index++) {
            float localX = 0.72f;
            float localY = 1.45f;
            float localZ = -0.12f;
            if (isBowWeapon()) {
                localY = index == 0 ? 1.48f : index == 1 ? 1.05f : 1.26f;
                localZ = index == 3 ? 0.28f : 0f;
            } else if (isStaffWeapon()) {
                localY = index == 1 ? 1.85f : 1.15f;
            } else if (isMaulWeapon()) {
                localY = index == 1 ? 1.55f : 1.0f;
            } else if (weapon.getName().equalsIgnoreCase("Rusted Sword")) {
                localY = 0.95f;
                localZ = -0.05f;
            }
            weaponInstances.get(index).transform
                    .setToTranslation(position.x + facing.x * localX, position.y + localY,
                            position.z + facing.z * localX + localZ)
                    .rotate(Vector3.Y, facingAngle + attackSwing)
                    .scale(weapon.getName().equalsIgnoreCase("Rusted Sword") ? 2.8f : 1f,
                            weapon.getName().equalsIgnoreCase("Rusted Sword") ? 2.8f : 1f,
                            weapon.getName().equalsIgnoreCase("Rusted Sword") ? 2.8f : 1f);
        }
        float effectScale = isGuarding() ? 0.95f : isInvulnerable() ? 0.72f : 0.001f;
        effectInstance.transform.setToTranslation(position.x, 0.08f, position.z)
                .scale(effectScale, 1f, effectScale);
        setArmorColor(isGuarding()
                ? GUARD_COLOR
                : isInvulnerable() ? DODGE_COLOR : armorColor);
    }

    private static void tintCharacterMesh(ModelInstance instance, String characterName) {
        Color tint = characterName.equalsIgnoreCase("Warden") ? new Color(0.42f, 0.68f, 1f, 1f)
                : characterName.equalsIgnoreCase("Veil Archer") ? new Color(0.54f, 1f, 0.52f, 1f)
                : new Color(0.95f, 0.48f, 1f, 1f);
        for (Material material : instance.materials) {
            ColorAttribute diffuse = (ColorAttribute) material.get(ColorAttribute.Diffuse);
            if (diffuse != null) diffuse.color.set(tint);
        }
    }

    private boolean isBowWeapon() {
        return character.getName().equalsIgnoreCase("Veil Archer");
    }

    private boolean isStaffWeapon() {
        return character.getName().equalsIgnoreCase("Ash Mage");
    }

    private boolean isMaulWeapon() {
        return weapon.getName().toLowerCase().contains("maul");
    }

    private void setArmorColor(Color color) {
        ColorAttribute diffuse = (ColorAttribute) instances.get(0).materials.first()
                .get(ColorAttribute.Diffuse);
        diffuse.color.set(color);
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
