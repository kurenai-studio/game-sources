package dev.meowpow.boxbot.render.assets;

import com.badlogic.gdx.graphics.g2d.TextureRegion;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class EntitySpriteTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null texture region")
        void should_RejectRegion_when_RegionIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    new EntitySprite(null, 1f)
            );
        }

        @Test
        @DisplayName("Rejects a zero size ratio")
        void should_RejectSizeRatio_when_SizeRatioIsZero() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new EntitySprite(region(10), 0f)
            );
        }

        @Test
        @DisplayName("Rejects a negative size ratio")
        void should_RejectSizeRatio_when_SizeRatioIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new EntitySprite(region(10), -1f)
            );
        }

        @Test
        @DisplayName("Rejects a non-numeric size ratio")
        void should_RejectSizeRatio_when_SizeRatioIsNotANumber() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new EntitySprite(region(10), Float.NaN)
            );
        }
    }

    @Nested
    @DisplayName("size")
    class SizeMethodTests {

        @Test
        @DisplayName("Returns the region width scaled by the size ratio")
        void should_ReturnScaledRegionWidth_when_SizeRatioIsPositive() {
            var sprite = new EntitySprite(region(20), 0.75f);

            assertThat(sprite.size()).isEqualTo(15f);
        }
    }

    private static TextureRegion region(int width) {
        return new TestTextureRegion(width);
    }
}
