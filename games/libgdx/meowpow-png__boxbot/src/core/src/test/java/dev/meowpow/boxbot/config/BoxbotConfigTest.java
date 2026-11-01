package dev.meowpow.boxbot.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

class BoxbotConfigTest {

    @Nested
    @DisplayName("constructor")
    class ConstructorTests {

        @Test
        @DisplayName("Retains all configuration categories")
        void should_RetainCategories_when_AllCategoriesAreProvided() {
            var timing = new TimingConfig(
                    0.125f,
                    0.75f,
                    0.5f,
                    0.5f
            );
            var warehouse = new WarehouseConfig(
                    100,
                    12
            );
            var demand = new DemandConfig(
                    0.25,
                    20,
                    30,
                    5,
                    40,
                    2,
                    5,
                    supply(),
                    demandCycle()
            );
            var input = new InputConfig(5);
            var ui = new UiConfig(0.5, 0.2);
            var config = new BoxbotConfig(
                    42L,
                    timing,
                    warehouse,
                    demand,
                    input,
                    ui
            );
            assertThat(config.timing()).isSameAs(timing);
            assertThat(config.warehouse()).isSameAs(warehouse);
            assertThat(config.demand()).isSameAs(demand);
            assertThat(config.input()).isSameAs(input);
            assertThat(config.ui()).isSameAs(ui);
        }

        @Test
        @DisplayName("Rejects a missing required category")
        void should_RejectConfiguration_when_ARequiredCategoryIsMissing() {
            assertThatNullPointerException().isThrownBy(() -> new BoxbotConfig(
                    42L,
                    null,
                    new WarehouseConfig(
                            100,
                            12
                    ),
                    new DemandConfig(
                            0.25,
                            20,
                            30,
                            5,
                            40,
                            2,
                            5,
                            supply(),
                            demandCycle()
                    ),
                    new InputConfig(5),
                    new UiConfig(0.5, 0.2)
            ));
        }
    }

    private static SupplyConfig supply() {
        return new SupplyConfig(2400, 0.35, 0.15);
    }

    private static DemandCycleConfig demandCycle() {
        return new DemandCycleConfig(800, 0.5, 1.5);
    }
}
