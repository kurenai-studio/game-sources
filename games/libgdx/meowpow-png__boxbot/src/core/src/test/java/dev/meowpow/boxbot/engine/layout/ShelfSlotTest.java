package dev.meowpow.boxbot.engine.layout;

import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.spatial.grid.GridFixtures;
import dev.meowpow.boxbot.engine.spatial.grid.GridPos;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class ShelfSlotTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains valid values")
        void should_RetainValues_when_ValuesAreValid() {
            var id = new ShelfId(1);
            var pos = new GridPos(2, 3);
            var slot = new ShelfSlot(id, pos);

            assertThat(slot.id()).isEqualTo(id);
            assertThat(slot.pos()).isEqualTo(pos);
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null shelf identifier")
        void should_RejectId_when_IdIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new ShelfSlot(
                    null,
                    GridFixtures.origin()
            ));
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null grid position")
        void should_RejectPosition_when_PositionIsNull() {
            assertThatNullPointerException().isThrownBy(() -> new ShelfSlot(
                    new ShelfId(1),
                    null
            ));
        }
    }
}
