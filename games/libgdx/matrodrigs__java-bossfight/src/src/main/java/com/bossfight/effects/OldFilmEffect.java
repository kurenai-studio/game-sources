package com.bossfight.effects;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.graphics.glutils.FrameBuffer;
import com.badlogic.gdx.graphics.glutils.ShaderProgram;
import com.badlogic.gdx.math.Matrix4;

public class OldFilmEffect {
    private static final float FILM_INTENSITY = 0.72f;

    private static final String VERTEX_SHADER = """
            attribute vec4 a_position;
            attribute vec4 a_color;
            attribute vec2 a_texCoord0;

            uniform mat4 u_projTrans;

            varying vec4 v_color;
            varying vec2 v_texCoords;

            void main() {
                v_color = a_color;
                v_texCoords = a_texCoord0;
                gl_Position = u_projTrans * a_position;
            }
            """;

    private static final String FRAGMENT_SHADER = """
            #ifdef GL_ES
            precision mediump float;
            #endif

            varying vec4 v_color;
            varying vec2 v_texCoords;

            uniform sampler2D u_texture;
            uniform float u_time;
            uniform vec2 u_resolution;
            uniform float u_intensity;
            uniform float u_irisProgress;
            uniform vec2 u_irisCenter;
            uniform float u_irisSoftness;

            float hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
            }

            float lineMask(float value, float center, float width) {
                return 1.0 - smoothstep(0.0, width, abs(value - center));
            }

            float irisOutsideMask(vec2 uv) {
                float progress = clamp(u_irisProgress, 0.0, 1.0);
                float aspect = u_resolution.x / max(u_resolution.y, 1.0);
                vec2 centered = uv - u_irisCenter;
                centered.x *= aspect;

                vec2 farCorner = vec2(
                    max(u_irisCenter.x, 1.0 - u_irisCenter.x) * aspect,
                    max(u_irisCenter.y, 1.0 - u_irisCenter.y)
                );
                float maxRadius = length(farCorner) + 0.10;
                float radius = mix(-0.055, maxRadius, progress);

                return smoothstep(radius - u_irisSoftness, radius + u_irisSoftness,
                    length(centered));
            }

            float dustLayer(vec2 uv, vec2 grid, float frame, float threshold, float minSize, float maxSize) {
                vec2 cell = floor(uv * grid);
                vec2 local = fract(uv * grid);
                float seed = hash(cell + frame * vec2(19.37, 7.13));
                vec2 center = vec2(hash(cell + 12.0), hash(cell + 41.0));
                float radius = mix(minSize, maxSize, hash(cell + 73.0));
                float spot = 1.0 - smoothstep(radius * 0.32, radius, distance(local, center));
                return spot * step(threshold, seed);
            }

            void main() {
                vec2 baseUv = v_texCoords;
                vec3 source = texture2D(u_texture, baseUv).rgb;
                float frame = floor(u_time * 24.0);
                float slowFrame = floor(u_time * 10.0);

                float row = floor(baseUv.y * 88.0);
                float rowNoise = hash(vec2(row, frame));
                float jitter = (rowNoise - 0.5) * 0.00055;
                jitter += sin(baseUv.y * 136.0 + u_time * 7.0) * 0.00022;

                vec2 uv = baseUv + vec2(jitter, 0.0);
                float edgeDistance = distance(baseUv, vec2(0.5));
                float chroma = 0.00028 + edgeDistance * 0.00072;
                vec2 colorOffset = vec2(chroma + jitter * 0.18, 0.0);

                float red = texture2D(u_texture, uv + colorOffset).r;
                float green = texture2D(u_texture, uv).g;
                float blue = texture2D(u_texture, uv - colorOffset).b;
                vec3 color = vec3(red, green, blue);

                float luma = dot(color, vec3(0.299, 0.587, 0.114));
                color = mix(vec3(luma), color, 0.91);
                color = (color - 0.5) * 1.035 + 0.5;
                color *= vec3(1.035, 1.0, 0.94);

                float flicker = 0.985 + hash(vec2(frame, 4.2)) * 0.020 + sin(u_time * 17.0) * 0.004;
                color *= flicker;

                float pixelLine = baseUv.y * u_resolution.y;
                float scanline = 1.0 - step(0.55, fract(pixelLine * 0.5)) * 0.014;
                color *= scanline;

                float grainA = hash(floor(baseUv * u_resolution * 0.92) + frame * vec2(17.0, 31.0));
                float grainB = hash(floor(baseUv * u_resolution * 0.33) + frame * vec2(13.0, 7.0));
                color += ((grainA - 0.5) * 0.052 + (grainB - 0.5) * 0.018);

                float dust = dustLayer(baseUv, vec2(44.0, 26.0), floor(frame / 2.0), 0.990, 0.014, 0.055);
                float grit = dustLayer(baseUv, vec2(72.0, 40.0), frame, 0.997, 0.008, 0.026);
                float darkDust = dustLayer(baseUv + vec2(0.17, 0.31), vec2(34.0, 21.0), slowFrame, 0.994, 0.012, 0.050);
                color += dust * vec3(0.075, 0.068, 0.052);
                color += grit * vec3(0.045, 0.041, 0.034);
                color -= darkDust * vec3(0.050, 0.046, 0.038);

                float scratch = 0.0;
                float hair = 0.0;
                for (int i = 0; i < 5; i++) {
                    float index = float(i);
                    float seed = hash(vec2(index * 34.1, slowFrame));
                    float x = hash(vec2(seed, index + 2.7));
                    float drift = (hash(vec2(slowFrame, index + 8.0)) - 0.5) * 0.035;
                    float curve = sin(baseUv.y * mix(7.0, 18.0, seed) + seed * 6.2831) * 0.0025;
                    float width = mix(0.00055, 0.0018, hash(vec2(seed, 6.0)));
                    float fade = mix(0.28, 0.9, hash(vec2(baseUv.y * 40.0, seed)));
                    scratch += step(0.86, seed) * lineMask(baseUv.x, x + drift + curve, width) * fade;

                    float hairSeed = hash(vec2(index * 8.3, floor(u_time * 5.0)));
                    float hairX = hash(vec2(hairSeed, 11.0));
                    float hairCurve = sin(baseUv.y * 12.0 + hairSeed * 11.0) * 0.006;
                    hair += step(0.92, hairSeed) * lineMask(baseUv.x, hairX + hairCurve, 0.0008);
                }
                color += scratch * vec3(0.045, 0.041, 0.034);
                color -= hair * vec3(0.038, 0.034, 0.028);

                vec2 centered = baseUv - vec2(0.5);
                centered.x *= u_resolution.x / max(u_resolution.y, 1.0);
                float vignette = 1.0 - smoothstep(0.26, 1.05, dot(centered, centered));
                color *= mix(0.82, 1.0, vignette);

                float projectorLine = lineMask(fract(baseUv.y + u_time * 0.11), 0.52, 0.0035);
                color += projectorLine * vec3(0.014, 0.012, 0.009);

                color = mix(source, color, u_intensity);
                color = mix(color, vec3(0.0), irisOutsideMask(baseUv));
                gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0) * v_color;
            }
            """;

    private final SpriteBatch postBatch;
    private final Matrix4 screenProjection;
    private final ShaderProgram shader;
    private FrameBuffer frameBuffer;
    private TextureRegion frameRegion;
    private float elapsed;

    public OldFilmEffect() {
        postBatch = new SpriteBatch();
        screenProjection = new Matrix4();
        shader = new ShaderProgram(VERTEX_SHADER, FRAGMENT_SHADER);
        if (!shader.isCompiled()) {
            throw new IllegalStateException("Falha ao compilar o shader de filme antigo: " + shader.getLog());
        }
    }

    public void begin() {
        ensureFrameBuffer();
        frameBuffer.begin();
        Gdx.gl.glViewport(0, 0, frameBuffer.getWidth(), frameBuffer.getHeight());
    }

    public void renderToScreen(float delta, float irisProgress) {
        frameBuffer.end();
        elapsed += Math.min(delta, 1f / 20f);

        int width = Math.max(1, Gdx.graphics.getBackBufferWidth());
        int height = Math.max(1, Gdx.graphics.getBackBufferHeight());
        Gdx.gl.glViewport(0, 0, width, height);
        Gdx.gl.glDisable(GL20.GL_DEPTH_TEST);
        Gdx.gl.glClearColor(0f, 0f, 0f, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);

        screenProjection.setToOrtho2D(0f, 0f, width, height);
        postBatch.setProjectionMatrix(screenProjection);
        postBatch.setShader(shader);
        postBatch.setColor(Color.WHITE);
        postBatch.begin();
        shader.setUniformf("u_time", elapsed);
        shader.setUniformf("u_resolution", width, height);
        shader.setUniformf("u_intensity", FILM_INTENSITY);
        shader.setUniformf("u_irisProgress", clamp01(irisProgress));
        shader.setUniformf("u_irisCenter", 0.5f, 0.5f);
        shader.setUniformf("u_irisSoftness", 0.018f);
        postBatch.draw(frameRegion, 0f, 0f, width, height);
        postBatch.end();
        postBatch.setShader(null);
    }

    public void resize() {
        disposeFrameBuffer();
        ensureFrameBuffer();
    }

    public void dispose() {
        disposeFrameBuffer();
        shader.dispose();
        postBatch.dispose();
    }

    private void ensureFrameBuffer() {
        int width = Math.max(1, Gdx.graphics.getBackBufferWidth());
        int height = Math.max(1, Gdx.graphics.getBackBufferHeight());
        if (frameBuffer != null && frameBuffer.getWidth() == width && frameBuffer.getHeight() == height) {
            return;
        }

        disposeFrameBuffer();
        frameBuffer = new FrameBuffer(Pixmap.Format.RGBA8888, width, height, false);
        frameBuffer.getColorBufferTexture().setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
        frameRegion = new TextureRegion(frameBuffer.getColorBufferTexture());
        frameRegion.flip(false, true);
    }

    private float clamp01(float value) {
        return Math.max(0f, Math.min(1f, value));
    }

    private void disposeFrameBuffer() {
        if (frameBuffer != null) {
            frameBuffer.dispose();
            frameBuffer = null;
            frameRegion = null;
        }
    }
}
