package com.veilfall.game.world;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.VertexAttributes;
import com.badlogic.gdx.graphics.g3d.Material;
import com.badlogic.gdx.graphics.g3d.Model;
import com.badlogic.gdx.graphics.g3d.ModelInstance;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.g3d.attributes.FloatAttribute;
import com.badlogic.gdx.graphics.g3d.utils.ModelBuilder;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.Disposable;

/** Open arena floor with small natural set dressing kept around the combat space. */
public class World implements Disposable {
    private static final long ATTRIBUTES = VertexAttributes.Usage.Position | VertexAttributes.Usage.Normal;
    private final Array<Model> models = new Array<>();
    private final Array<ModelInstance> instances = new Array<>();

    public World() { this("MISTWOOD"); }

    public World(String environment) {
        ModelBuilder builder = new ModelBuilder();
        String biome = environment == null ? "MISTWOOD" : environment.toUpperCase();
        Color ground = switch (biome) {
            case "ASHEN" -> color(0.18f, 0.14f, 0.13f);
            case "DROWNED" -> color(0.08f, 0.20f, 0.24f);
            default -> color(0.13f, 0.22f, 0.17f);
        };
        addBox(builder, 60f, 0.35f, 60f, ground, 0f, -0.2f, 0f);

        switch (biome) {
            case "ASHEN" -> addAshenNature(builder);
            case "DROWNED" -> addDrownedNature(builder);
            default -> addForestNature(builder);
        }
    }

    private void addForestNature(ModelBuilder builder) {
        Color bark = color(0.25f, 0.18f, 0.13f);
        Color canopy = color(0.10f, 0.29f, 0.19f);
        for (int[] point : new int[][]{{-26, -25}, {-26, 25}, {26, -25}, {26, 25},
                {-28, 0}, {28, 0}, {0, -28}, {0, 28}}) {
            addModel(builder.createCylinder(0.42f, 2.3f, 0.42f, 7,
                    material(bark), ATTRIBUTES), point[0], 1.1f, point[1]);
            addModel(builder.createSphere(2.5f, 3.2f, 2.5f, 8, 6,
                    material(canopy), ATTRIBUTES), point[0], 3.1f, point[1]);
            addModel(builder.createSphere(1.8f, 2.1f, 1.8f, 8, 6,
                    material(new Color(canopy).mul(0.82f)), ATTRIBUTES), point[0] + 0.25f, 4.5f, point[1]);
        }
        scatterRocks(builder, color(0.28f, 0.31f, 0.25f), new int[][]{
                {-24, -16}, {-24, 16}, {24, -16}, {24, 16}, {-16, -25}, {16, 25}
        });
    }

    private void addAshenNature(ModelBuilder builder) {
        Color basalt = color(0.20f, 0.16f, 0.16f);
        Color ember = color(0.68f, 0.24f, 0.10f);
        for (int[] point : new int[][]{{-25, -20}, {-25, 20}, {25, -20}, {25, 20},
                {-27, -4}, {27, 4}, {-4, 27}, {4, -27}}) {
            float height = 1.5f + Math.abs(point[0] + point[1]) % 3;
            addModel(builder.createSphere(2.4f, height, 2.1f, 7, 5,
                    material(basalt), ATTRIBUTES), point[0], height * 0.42f, point[1]);
            addModel(builder.createCone(1.3f, 2.4f, 1.3f, 6,
                    material(ember), ATTRIBUTES), point[0] + 1.1f, height + 0.9f, point[1] - 0.6f);
        }
        scatterRocks(builder, color(0.34f, 0.24f, 0.20f), new int[][]{
                {-22, -12}, {-22, 12}, {22, -12}, {22, 12}, {-14, 25}, {14, -25}
        });
    }

    private void addDrownedNature(ModelBuilder builder) {
        Color water = color(0.04f, 0.31f, 0.39f);
        Color deepWater = color(0.035f, 0.15f, 0.22f);
        for (int[] point : new int[][]{{-23, -22}, {-23, 22}, {23, -22}, {23, 22}}) {
            addModel(builder.createCylinder(4.8f, 0.04f, 4.8f, 32,
                    material(deepWater), ATTRIBUTES), point[0], 0.015f, point[1]);
            addModel(builder.createCylinder(3.8f, 0.05f, 3.8f, 32,
                    material(water), ATTRIBUTES), point[0] - 0.4f, 0.045f, point[1] + 0.2f);
        }
        scatterRocks(builder, color(0.22f, 0.34f, 0.36f), new int[][]{
                {-27, 0}, {27, 0}, {0, -27}, {0, 27}, {-18, -25}, {18, 25}
        });
    }

    private void scatterRocks(ModelBuilder builder, Color color, int[][] points) {
        for (int index = 0; index < points.length; index++) {
            float radius = 0.9f + (index % 3) * 0.45f;
            Model rock = builder.createSphere(radius * 1.4f, radius, radius,
                    7, 5, material(color), ATTRIBUTES);
            addModel(rock, points[index][0], radius * 0.32f, points[index][1]);
        }
    }

    private ModelInstance addModel(Model model, float x, float y, float z) {
        ModelInstance instance = new ModelInstance(model);
        instance.transform.setToTranslation(x, y, z);
        models.add(model);
        instances.add(instance);
        return instance;
    }

    public Iterable<ModelInstance> getInstances() { return instances; }

    private void addBox(ModelBuilder builder, float width, float height, float depth,
                        Color diffuse, float x, float y, float z) {
        addModel(builder.createBox(width, height, depth, material(diffuse), ATTRIBUTES), x, y, z);
    }

    private static Material material(Color diffuse) {
        return new Material(ColorAttribute.createDiffuse(diffuse), FloatAttribute.createShininess(6f));
    }

    private static Color color(float red, float green, float blue) {
        return new Color(red, green, blue, 1f);
    }

    @Override public void dispose() {
        for (Model model : models) model.dispose();
        models.clear();
        instances.clear();
    }
}
