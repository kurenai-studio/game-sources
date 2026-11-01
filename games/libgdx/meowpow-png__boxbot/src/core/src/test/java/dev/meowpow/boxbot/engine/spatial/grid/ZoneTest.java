package dev.meowpow.boxbot.engine.spatial.grid;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class ZoneTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains valid values")
        void should_RetainValues_when_ValuesAreValid() {
            var min = new GridPos(1, 2);
            var max = new GridPos(3, 4);
            var zone = new Zone("A", min, max);

            assertThat(zone.name()).isEqualTo("A");
            assertThat(zone.min()).isEqualTo(min);
            assertThat(zone.max()).isEqualTo(max);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null name")
        void should_RejectName_when_NameIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Zone(
                    null,
                    new GridPos(0, 0),
                    new GridPos(0, 0)
            ));
        }

        @Test
        @DisplayName("Rejects a blank name")
        void should_RejectName_when_NameIsBlank() {
            assertThatIllegalArgumentException().isThrownBy(() -> new Zone(
                    " ",
                    new GridPos(0, 0),
                    new GridPos(0, 0)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null minimum corner")
        void should_RejectMin_when_MinIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Zone(
                    "A",
                    null,
                    new GridPos(0, 0)
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null maximum corner")
        void should_RejectMax_when_MaxIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new Zone(
                    "A",
                    new GridPos(0, 0),
                    null
            ));
        }

        @Test
        @DisplayName("Rejects a minimum x coordinate above the maximum")
        void should_RejectBounds_when_MinXExceedsMaxX() {
            assertThatIllegalArgumentException().isThrownBy(() -> new Zone(
                    "A",
                    new GridPos(1, 0),
                    new GridPos(0, 1)
            ));
        }

        @Test
        @DisplayName("Rejects a minimum y coordinate above the maximum")
        void should_RejectBounds_when_MinYExceedsMaxY() {
            assertThatIllegalArgumentException().isThrownBy(() -> new Zone(
                    "A",
                    new GridPos(0, 1),
                    new GridPos(1, 0)
            ));
        }
    }

    @Nested
    @DisplayName("contains")
    class ContainsMethodTests {

        @Test
        @DisplayName("Includes both bounds")
        void should_ReturnTrue_when_PositionIsOnABound() {
            var gridPos1 = new GridPos(1, 2);
            var gridPos2 = new GridPos(3, 4);
            var zone = new Zone("A", gridPos1, gridPos2);

            assertThat(zone.contains(gridPos1)).isTrue();
            assertThat(zone.contains(gridPos2)).isTrue();
        }

        @Test
        @DisplayName("Returns false for a position outside the bounds")
        void should_ReturnFalse_when_PositionIsOutsideBounds() {
            var zone = new Zone(
                    "A",
                    new GridPos(1, 2),
                    new GridPos(3, 4)
            );
            assertThat(zone.contains(new GridPos(0, 2))).isFalse();
            assertThat(zone.contains(new GridPos(1, 5))).isFalse();
        }
    }
}
