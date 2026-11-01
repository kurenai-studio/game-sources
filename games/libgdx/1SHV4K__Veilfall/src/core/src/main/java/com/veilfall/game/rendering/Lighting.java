package com.veilfall.game.rendering;

import com.badlogic.gdx.graphics.g3d.Environment;
import com.badlogic.gdx.graphics.g3d.environment.DirectionalLight;
import com.badlogic.gdx.graphics.g3d.attributes.ColorAttribute;
import com.badlogic.gdx.graphics.Color;

public final class Lighting {
    private final Environment environment = new Environment();
    private final DirectionalLight sunLight = new DirectionalLight();

    public Lighting() {
        environment.set(new ColorAttribute(ColorAttribute.AmbientLight, 0.40f, 0.43f, 0.51f, 1f));
        environment.add(sunLight.set(0.88f, 0.84f, 0.92f, -0.5f, -1f, -0.35f));
    }

    public Environment getEnvironment() {
        return environment;
    }

    public void setBiome(String biome) {
        Color ambient;
        Color sun;
        switch (biome == null ? "MISTWOOD" : biome.toUpperCase()) {
            case "ASHEN" -> {
                ambient = new Color(0.47f, 0.34f, 0.31f, 1f);
                sun = new Color(1f, 0.58f, 0.39f, 1f);
            }
            case "DROWNED" -> {
                ambient = new Color(0.28f, 0.46f, 0.57f, 1f);
                sun = new Color(0.45f, 0.80f, 0.94f, 1f);
            }
            default -> {
                ambient = new Color(0.34f, 0.48f, 0.38f, 1f);
                sun = new Color(0.78f, 0.96f, 0.74f, 1f);
            }
        }
        environment.set(new ColorAttribute(ColorAttribute.AmbientLight, ambient));
        sunLight.set(sun.r, sun.g, sun.b, -0.5f, -1f, -0.35f);
    }
}
