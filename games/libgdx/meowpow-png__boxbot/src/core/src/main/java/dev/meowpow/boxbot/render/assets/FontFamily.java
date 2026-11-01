package dev.meowpow.boxbot.render.assets;

/**
 * A loaded font source, identified by name.
 */
public enum FontFamily {

    ALLERTA_STENCIL("fonts/AllertaStencil-Regular.ttf"),
    OXANIUM("fonts/Oxanium-VariableFont_wght.ttf");

    private final String path;

    FontFamily(String path) {
        this.path = path;
    }

    /**
     * Returns the internal asset path to this font's TTF file.
     */
    public String path() {
        return path;
    }
}
