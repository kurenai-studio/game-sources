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
import com.veilfall.game.enemies.EnemyManager;

/** Lightweight generated combat VFX, used until authored particle assets are integrated. */
public final class CombatEffects implements Disposable {
    private static final long ATTRIBUTES = VertexAttributes.Usage.Position | VertexAttributes.Usage.Normal;
    private final Array<Effect> effects = new Array<>();

    public void basicAttack(CharacterKit kit, Player player) {
        if (kit == CharacterKit.WARDEN) {
            slash(player, new Color(1f, 0.72f, 0.24f, 1f), 0.22f);
        } else {
            projectile(kit, player, false, 0f);
        }
    }

    public void abilityQ(CharacterKit kit, Player player) {
        if (kit == CharacterKit.WARDEN) {
            slash(player, new Color(0.55f, 0.85f, 1f, 1f), 0.3f);
        } else {
            projectile(kit, player, true, 0f);
        }
    }

    public void abilityE(CharacterKit kit, Player player) {
        if (kit == CharacterKit.ARCHER) {
            for (int arrow = -2; arrow <= 2; arrow++) projectile(kit, player, true, arrow * 9f);
        } else {
            Color color = kit == CharacterKit.WARDEN
                    ? new Color(1f, 0.56f, 0.16f, 1f) : new Color(0.78f, 0.36f, 1f, 1f);
            ring(player, color);
        }
    }

    public void abilityR(CharacterKit kit, Player player) {
        ring(player, kit == CharacterKit.ARCHER
                ? new Color(0.36f, 1f, 0.7f, 1f) : new Color(0.32f, 0.72f, 1f, 1f));
    }

    public void update(float delta) {
        for (int index = effects.size - 1; index >= 0; index--) {
            Effect effect = effects.get(index);
            effect.remaining -= delta;
            effect.position.mulAdd(effect.velocity, delta);
            if (effect.ring) {
                float progress = 1f - Math.max(0f, effect.remaining) / effect.duration;
                float scale = 0.45f + 2.15f * progress;
                effect.instance.transform.setToTranslation(effect.position)
                        .scale(scale, 1f, scale);
            } else {
                float angle = MathUtils.radiansToDegrees * (float) Math.atan2(effect.facing.x, effect.facing.z)
                        + effect.spreadDegrees;
                effect.instance.transform.setToTranslation(effect.position)
                        .rotate(Vector3.Y, angle);
            }
            if (effect.remaining <= 0f) {
                effect.model.dispose();
                effects.removeIndex(index);
            }
        }
    }

    public void appendInstances(Array<ModelInstance> destination) {
        for (Effect effect : effects) destination.add(effect.instance);
    }

    public void dispose() {
        for (Effect effect : effects) effect.model.dispose();
        effects.clear();
    }

    private void projectile(CharacterKit kit, Player player, boolean empowered, float spreadDegrees) {
        ModelBuilder builder = new ModelBuilder();
        Color color;
        Model model;
        float speed;
        if (kit == CharacterKit.ARCHER) {
            boolean longshot = player.getWeapon().getName().equalsIgnoreCase("Longshot Recurve");
            color = empowered ? new Color(1f, 0.82f, 0.36f, 1f)
                    : longshot ? new Color(0.95f, 0.70f, 0.28f, 1f)
                    : new Color(0.55f, 1f, 0.63f, 1f);
            model = builder.createBox(0.08f, 0.08f, empowered ? 1.4f : 1.1f,
                    new Material(ColorAttribute.createDiffuse(color)), ATTRIBUTES);
            speed = 24f;
        } else {
            boolean emberRod = player.getWeapon().getName().equalsIgnoreCase("Ember Rod");
            color = empowered ? new Color(0.95f, 0.47f, 1f, 1f)
                    : emberRod ? new Color(1f, 0.39f, 0.13f, 1f)
                    : new Color(0.45f, 0.78f, 1f, 1f);
            model = builder.createSphere(empowered ? 0.62f : 0.42f, empowered ? 0.62f : 0.42f,
                    empowered ? 0.62f : 0.42f, 12, 12,
                    new Material(ColorAttribute.createDiffuse(color)), ATTRIBUTES);
            speed = 14f;
        }
        Vector3 facing = new Vector3(player.getFacing());
        facing.rotate(Vector3.Y, spreadDegrees).nor();
        Vector3 start = new Vector3(player.getX() + facing.x * 0.9f, 1.45f,
                player.getZ() + facing.z * 0.9f);
        effects.add(new Effect(model, start, facing.scl(speed), facing, 0.65f, spreadDegrees, false));
    }

    private void slash(Player player, Color color, float duration) {
        ModelBuilder builder = new ModelBuilder();
        Model model = builder.createBox(0.18f, 1.35f, 0.16f,
                new Material(ColorAttribute.createDiffuse(color)), ATTRIBUTES);
        Vector3 facing = new Vector3(player.getFacing());
        Vector3 position = new Vector3(player.getX() + facing.x * 0.9f, 1.45f,
                player.getZ() + facing.z * 0.9f);
        effects.add(new Effect(model, position, new Vector3(), facing, duration, 0f, false));
    }

    private void ring(Player player, Color color) {
        ModelBuilder builder = new ModelBuilder();
        Model model = builder.createCylinder(2f, 0.08f, 2f, 24,
                new Material(ColorAttribute.createDiffuse(color)), ATTRIBUTES);
        effects.add(new Effect(model, new Vector3(player.getX(), 0.12f, player.getZ()),
                new Vector3(), new Vector3(Vector3.X), 0.42f, 0f, true));
    }

    private static final class Effect {
        private final Model model;
        private ModelInstance instance;
        private final Vector3 position;
        private final Vector3 velocity;
        private final Vector3 facing;
        private final float duration;
        private final float spreadDegrees;
        private final boolean ring;
        private float remaining;

        private Effect(Model model, Vector3 position, Vector3 velocity, Vector3 facing,
                       float duration, float spreadDegrees, boolean ring) {
            this.model = model;
            this.instance = new ModelInstance(model);
            this.position = position;
            this.velocity = velocity;
            this.facing = new Vector3(facing);
            this.duration = duration;
            this.remaining = duration;
            this.spreadDegrees = spreadDegrees;
            this.ring = ring;
            if (ring) {
                instance.transform.setToTranslation(position).scale(0.45f, 1f, 0.45f);
            } else {
                float angle = MathUtils.radiansToDegrees * (float) Math.atan2(facing.x, facing.z)
                        + spreadDegrees;
                instance.transform.setToTranslation(position).rotate(Vector3.Y, angle);
            }
        }
    }
}
