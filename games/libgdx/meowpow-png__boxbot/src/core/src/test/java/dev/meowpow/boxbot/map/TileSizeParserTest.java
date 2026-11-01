package dev.meowpow.boxbot.map;

import com.badlogic.gdx.maps.tiled.TiledMap;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalStateException;

class TileSizeParserTest {

    @Nested
    @DisplayName("parse")
    class ParseMethodTests {

        @Test
        @DisplayName("Returns the size of square tiles")
        void should_ReturnTileSize_when_MapTilesAreSquare() {
            var map = mapWithTileDimensions(16, 16);

            var tileSize = TileSizeParser.parse(map);

            assertThat(tileSize.pixels()).isEqualTo(16);
        }

        @Test
        @DisplayName("Rejects non-square tiles")
        void should_RejectMap_when_MapTilesAreNotSquare() {
            var map = mapWithTileDimensions(16, 32);

            assertThatIllegalStateException().isThrownBy(() ->
                    TileSizeParser.parse(map)
            );
        }
    }

    @SuppressWarnings("SameParameterValue")
    private static TiledMap mapWithTileDimensions(int width, int height) {
        var map = new TiledMap();

        map.getProperties().put("tilewidth", width);
        map.getProperties().put("tileheight", height);

        return map;
    }
}
