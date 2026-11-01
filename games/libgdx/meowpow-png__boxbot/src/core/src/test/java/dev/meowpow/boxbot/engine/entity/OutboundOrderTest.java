package dev.meowpow.boxbot.engine.entity;

import dev.meowpow.boxbot.engine.PackageColor;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class OutboundOrderTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null order id")
        void should_RejectId_when_OrderIdIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    new OutboundOrder(null, PackageColor.RED, 1)
            );
        }

        @Test
        @SuppressWarnings("DataFlowIssue")
        @DisplayName("Rejects a null color")
        void should_RejectColor_when_ColorIsNull() {
            assertThatNullPointerException().isThrownBy(() ->
                    new OutboundOrder(new OrderId(1), null, 1)
            );
        }

        @Test
        @DisplayName("Rejects a generic stock color")
        void should_RejectColor_when_ColorIsNone() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new OutboundOrder(new OrderId(1), PackageColor.NONE, 1)
            );
        }

        @Test
        @DisplayName("Rejects a negative deadline tick")
        void should_RejectDeadlineTick_when_DeadlineTickIsNegative() {
            assertThatIllegalArgumentException().isThrownBy(() ->
                    new OutboundOrder(new OrderId(1), PackageColor.RED, -1)
            );
        }

        @Test
        @DisplayName("Preserves valid order details")
        void should_PreserveOrderDetails_when_OrderIsValid() {
            var id = new OrderId(1);
            var order = new OutboundOrder(id, PackageColor.RED, 0);

            assertThat(order.id()).isEqualTo(id);
            assertThat(order.color()).isEqualTo(PackageColor.RED);
            assertThat(order.deadlineTick()).isZero();
        }
    }
}
