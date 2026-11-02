package com.bossfight.rendering;

import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.utils.Disposable;
import com.badlogic.gdx.utils.ObjectSet;

import java.awt.BasicStroke;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.Shape;
import java.awt.FontFormatException;
import java.awt.font.GlyphVector;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;
import java.util.EnumMap;

public class RetroTextFactory implements Disposable {
    private enum FontRole {
        TITLE("fonts/TitanOne-Regular.ttf"),
        UI("fonts/LilitaOne-Regular.ttf");

        private final String path;

        FontRole(String path) {
            this.path = path;
        }
    }

    private record TextStyle(
            FontRole fontRole,
            int fontSize,
            int strokeWidth,
            int fillRgb,
            int strokeRgb,
            int shadowRgb,
            int padding
    ) {
    }

    private record CartoonTextStyle(TextStyle textStyle, float tiltStep) {
    }

    private static final CartoonTextStyle TITLE_STYLE = cartoon(
            FontRole.TITLE, 92, 11, 0xffd64a, 0x672014, 0x050405, 16, 0.048f);
    private static final TextStyle SUBTITLE_STYLE = style(
            FontRole.UI, 34, 7, 0xf8eed2, 0x4b2018, 0x080707, 8);
    private static final CartoonTextStyle MENU_STYLE = cartoon(
            FontRole.UI, 34, 6, 0xf7e5b6, 0x3d2518, 0x130d0a, 9, 0.026f);
    private static final CartoonTextStyle SELECTED_MENU_STYLE = cartoon(
            FontRole.UI, 38, 7, 0xffd84a, 0x572012, 0x130d0a, 9, 0.038f);
    private static final CartoonTextStyle READY_STYLE = cartoon(
            FontRole.UI, 96, 12, 0xffef79, 0x612416, 0x060506, 18, 0.08f);
    private static final CartoonTextStyle GO_STYLE = cartoon(
            FontRole.UI, 96, 12, 0xffdc45, 0x612416, 0x060506, 18, 0.08f);
    private static final CartoonTextStyle KNOCKOUT_STYLE = cartoon(
            FontRole.UI, 88, 13, 0xffdd55, 0x5a1d12, 0x050405, 18, 0.055f);
    private static final CartoonTextStyle VICTORY_STYLE = cartoon(
            FontRole.UI, 92, 12, 0xffdf58, 0x5b2014, 0x050405, 18, 0.055f);
    private static final CartoonTextStyle DEFEAT_STYLE = cartoon(
            FontRole.UI, 92, 12, 0xf8efe1, 0x201815, 0x050405, 18, 0.055f);
    private static final TextStyle INSTRUCTION_STYLE = style(
            FontRole.UI, 28, 5, 0xf6e5b8, 0x312017, 0x050405, 8);
    private static final TextStyle INSTRUCTION_KEY_STYLE = style(
            FontRole.UI, 31, 6, 0xffd24a, 0x5b2014, 0x050405, 9);
    private static final TextStyle PLAYER_HEALTH_STYLE = style(
            FontRole.UI, 35, 5, 0xffdf55, 0x5a2118, 0x050405, 6);

    private final ObjectSet<Texture> textures = new ObjectSet<>();
    private final EnumMap<FontRole, Font> baseFonts = new EnumMap<>(FontRole.class);

    public Texture createTitle(String text) {
        return createCartoonText(text, TITLE_STYLE);
    }

    public Texture createSubtitle(String text) {
        return createText(text, SUBTITLE_STYLE);
    }

    public Texture createMenuOption(String text, boolean selected) {
        return createCartoonText(text, selected ? SELECTED_MENU_STYLE : MENU_STYLE);
    }

    public Texture createFightCue(String text, boolean goCue) {
        return createCartoonText(text, goCue ? GO_STYLE : READY_STYLE);
    }

    public Texture createKnockout(String text) {
        return createCartoonText(text, KNOCKOUT_STYLE);
    }

    public Texture createResultTitle(String text, boolean victory) {
        return createCartoonText(text, victory ? VICTORY_STYLE : DEFEAT_STYLE);
    }

    public Texture createPlayerHealthHud(int health) {
        return createPlayerHealthHudText("HP.", String.valueOf(health));
    }

    public Texture createInstruction(String text) {
        return createText(text, INSTRUCTION_STYLE);
    }

    public Texture createInstructionKey(String text) {
        return createText(text, INSTRUCTION_KEY_STYLE);
    }

    private Texture createText(String text, TextStyle style) {
        Font font = font(style.fontRole(), style.fontSize());
        BufferedImage probe = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
        Graphics2D probeGraphics = probe.createGraphics();
        applyHints(probeGraphics);
        FontMetrics metrics = probeGraphics.getFontMetrics(font);
        int width = Math.max(32,
                metrics.stringWidth(text) + style.padding() * 2 + style.strokeWidth() * 8);
        int height = Math.max(32,
                metrics.getHeight() + style.padding() * 2 + style.strokeWidth() * 8);
        probeGraphics.dispose();

        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = image.createGraphics();
        applyHints(graphics);
        graphics.setFont(font);

        GlyphVector glyphs = font.createGlyphVector(graphics.getFontRenderContext(), text);
        Shape outline = glyphs.getOutline(
                style.padding() + style.strokeWidth() * 4f,
                style.padding() + style.strokeWidth() * 4f + metrics.getAscent()
        );

        Shape shadow = AffineTransform.getTranslateInstance(
                        style.strokeWidth() * 1.3, style.strokeWidth() * 1.5)
                .createTransformedShape(outline);
        graphics.setColor(toAwtColor(style.shadowRgb(), 180));
        graphics.fill(shadow);

        graphics.setStroke(new BasicStroke(
                style.strokeWidth(), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        graphics.setColor(toAwtColor(style.strokeRgb(), 255));
        graphics.draw(outline);
        graphics.setColor(toAwtColor(style.fillRgb(), 255));
        graphics.fill(outline);

        Shape shine = AffineTransform.getTranslateInstance(0, -style.fontSize() * 0.08f)
                .createTransformedShape(outline);
        graphics.setColor(new java.awt.Color(255, 255, 255, 42));
        graphics.draw(shine);
        graphics.dispose();

        return registerTexture(image);
    }

    private Texture createPlayerHealthHudText(String label, String value) {
        int strokeWidth = PLAYER_HEALTH_STYLE.strokeWidth();
        int padding = PLAYER_HEALTH_STYLE.padding();
        int fontSize = PLAYER_HEALTH_STYLE.fontSize();
        int valueFontSize = 38;
        int gap = 4;
        int edge = padding + strokeWidth * 2;

        Font labelFont = font(PLAYER_HEALTH_STYLE.fontRole(), fontSize);
        Font valueFont = font(PLAYER_HEALTH_STYLE.fontRole(), valueFontSize);
        BufferedImage probe = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
        Graphics2D probeGraphics = probe.createGraphics();
        applyHints(probeGraphics);
        FontMetrics labelMetrics = probeGraphics.getFontMetrics(labelFont);
        FontMetrics valueMetrics = probeGraphics.getFontMetrics(valueFont);
        int width = Math.max(32, edge * 2 + labelMetrics.stringWidth(label) + gap
                + valueMetrics.stringWidth(value) + strokeWidth * 2);
        int height = Math.max(32, edge * 2 + Math.max(labelMetrics.getHeight(), valueMetrics.getHeight())
                + strokeWidth);
        probeGraphics.dispose();

        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = image.createGraphics();
        applyHints(graphics);

        float baseline = edge + Math.max(labelMetrics.getAscent(), valueMetrics.getAscent());
        float labelX = edge;
        Shape labelOutline = createTextOutline(graphics, labelFont, label, labelX, baseline);
        drawOutlinedText(graphics, labelOutline, PLAYER_HEALTH_STYLE, fontSize);

        float valueX = labelX + labelMetrics.stringWidth(label) + gap;
        Shape valueOutline = createTextOutline(graphics, valueFont, value, valueX, baseline - 1f);
        drawOutlinedText(graphics, valueOutline, PLAYER_HEALTH_STYLE, valueFontSize);
        graphics.dispose();

        return registerTexture(image);
    }

    private Shape createTextOutline(Graphics2D graphics, Font font, String text, float x, float baseline) {
        GlyphVector glyphs = font.createGlyphVector(graphics.getFontRenderContext(), text);
        return glyphs.getOutline(x, baseline);
    }

    private void drawOutlinedText(Graphics2D graphics, Shape outline, TextStyle style, int fontSize) {
        Shape shadow = AffineTransform.getTranslateInstance(
                        style.strokeWidth() * 1.3, style.strokeWidth() * 1.5)
                .createTransformedShape(outline);
        graphics.setColor(toAwtColor(style.shadowRgb(), 180));
        graphics.fill(shadow);

        graphics.setStroke(new BasicStroke(
                style.strokeWidth(), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        graphics.setColor(toAwtColor(style.strokeRgb(), 255));
        graphics.draw(outline);
        graphics.setColor(toAwtColor(style.fillRgb(), 255));
        graphics.fill(outline);

        Shape shine = AffineTransform.getTranslateInstance(0, -fontSize * 0.08f).createTransformedShape(outline);
        graphics.setColor(new java.awt.Color(255, 255, 255, 42));
        graphics.draw(shine);
    }

    private Texture createCartoonText(String text, CartoonTextStyle cartoonStyle) {
        TextStyle style = cartoonStyle.textStyle();
        Font font = font(style.fontRole(), style.fontSize());
        BufferedImage probe = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
        Graphics2D probeGraphics = probe.createGraphics();
        applyHints(probeGraphics);
        FontMetrics metrics = probeGraphics.getFontMetrics(font);
        int tracking = Math.max(2, style.fontSize() / 18);
        int textWidth = 0;
        for (int i = 0; i < text.length(); i++) {
            textWidth += metrics.charWidth(text.charAt(i)) + tracking;
        }
        int sidePadding = style.padding() + style.strokeWidth() * 7;
        int width = Math.max(32, textWidth + sidePadding * 2);
        int height = Math.max(32,
                metrics.getHeight() + style.padding() * 2 + style.strokeWidth() * 12);
        probeGraphics.dispose();

        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics = image.createGraphics();
        applyHints(graphics);
        graphics.setFont(font);

        float x = sidePadding;
        float baseline = style.padding() + style.strokeWidth() * 4f + metrics.getAscent();
        for (int i = 0; i < text.length(); i++) {
            String letter = String.valueOf(text.charAt(i));
            int advance = metrics.charWidth(text.charAt(i));
            if (letter.isBlank()) {
                x += advance + tracking;
                continue;
            }

            GlyphVector glyphs = font.createGlyphVector(graphics.getFontRenderContext(), letter);
            Shape outline = glyphs.getOutline();
            float bounce = (float) Math.sin(i * 1.71f) * style.fontSize() * 0.035f;
            float angle = ((i % 3) - 1) * cartoonStyle.tiltStep()
                    + (float) Math.sin(i * 0.9f) * cartoonStyle.tiltStep() * 0.35f;
            AffineTransform transform = new AffineTransform();
            transform.translate(x, baseline + bounce);
            transform.rotate(angle, advance * 0.5, -metrics.getAscent() * 0.45);
            Shape placed = transform.createTransformedShape(outline);

            Shape shadow = AffineTransform.getTranslateInstance(
                            style.strokeWidth() * 1.55, style.strokeWidth() * 1.75)
                    .createTransformedShape(placed);
            graphics.setColor(toAwtColor(style.shadowRgb(), 218));
            graphics.fill(shadow);

            graphics.setStroke(new BasicStroke(
                    style.strokeWidth(), BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
            graphics.setColor(toAwtColor(style.strokeRgb(), 255));
            graphics.draw(placed);
            graphics.setColor(toAwtColor(style.fillRgb(), 255));
            graphics.fill(placed);

            Shape shine = AffineTransform.getTranslateInstance(0, -style.fontSize() * 0.07f)
                    .createTransformedShape(placed);
            graphics.setStroke(new BasicStroke(Math.max(2f, style.strokeWidth() * 0.18f), BasicStroke.CAP_ROUND,
                    BasicStroke.JOIN_ROUND));
            graphics.setColor(new java.awt.Color(255, 255, 255, 58));
            graphics.draw(shine);

            x += advance + tracking;
        }
        graphics.dispose();

        return registerTexture(image);
    }

    private static TextStyle style(FontRole fontRole, int fontSize, int strokeWidth, int fillRgb,
                                   int strokeRgb, int shadowRgb, int padding) {
        return new TextStyle(fontRole, fontSize, strokeWidth, fillRgb, strokeRgb, shadowRgb, padding);
    }

    private static CartoonTextStyle cartoon(FontRole fontRole, int fontSize, int strokeWidth, int fillRgb,
                                             int strokeRgb, int shadowRgb, int padding, float tiltStep) {
        return new CartoonTextStyle(
                style(fontRole, fontSize, strokeWidth, fillRgb, strokeRgb, shadowRgb, padding),
                tiltStep);
    }

    private Texture registerTexture(BufferedImage image) {
        Texture texture = toTexture(image);
        texture.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
        textures.add(texture);
        return texture;
    }

    private Texture toTexture(BufferedImage image) {
        Pixmap pixmap = new Pixmap(image.getWidth(), image.getHeight(), Pixmap.Format.RGBA8888);
        for (int y = 0; y < image.getHeight(); y++) {
            for (int x = 0; x < image.getWidth(); x++) {
                int argb = image.getRGB(x, y);
                int alpha = (argb >>> 24) & 0xff;
                int red = (argb >>> 16) & 0xff;
                int green = (argb >>> 8) & 0xff;
                int blue = argb & 0xff;
                int rgba = (red << 24) | (green << 16) | (blue << 8) | alpha;
                pixmap.drawPixel(x, y, rgba);
            }
        }

        Texture texture = new Texture(pixmap);
        pixmap.dispose();
        return texture;
    }

    private void applyHints(Graphics2D graphics) {
        graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        graphics.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        graphics.setRenderingHint(RenderingHints.KEY_FRACTIONALMETRICS, RenderingHints.VALUE_FRACTIONALMETRICS_ON);
        graphics.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
    }

    private java.awt.Color toAwtColor(int rgb, int alpha) {
        return new java.awt.Color((rgb >> 16) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff, alpha);
    }

    Font font(int size) {
        return font(FontRole.UI, size);
    }

    private Font font(FontRole role, int size) {
        Font baseFont = baseFonts.get(role);
        if (baseFont == null) {
            baseFont = loadFont(role.path);
            baseFonts.put(role, baseFont);
        }
        return baseFont.deriveFont(Font.PLAIN, (float) size);
    }

    private Font loadFont(String path) {
        InputStream resource = RetroTextFactory.class.getClassLoader().getResourceAsStream(path);
        if (resource == null) {
            throw new IllegalStateException("Fonte incluída não encontrada: " + path);
        }
        try (InputStream input = resource) {
            return Font.createFont(Font.TRUETYPE_FONT, input);
        } catch (FontFormatException | IOException exception) {
            throw new IllegalStateException("Não foi possível carregar a fonte incluída: " + path, exception);
        }
    }

    @Override
    public void dispose() {
        for (Texture texture : textures) {
            texture.dispose();
        }
        textures.clear();
    }
}
