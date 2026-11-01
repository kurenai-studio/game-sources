package dev.meowpow.boxbot.config;

import com.badlogic.gdx.utils.JsonReader;
import com.badlogic.gdx.utils.JsonValue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

class ConfigParserTest {

    private static final String VALID_CONFIG_RESOURCE = "/config/valid-config.json";

    @Nested
    @DisplayName("parse")
    class ParseMethodTests {

        @Test
        @DisplayName("Maps the complete JSON tree to the configuration model")
        void should_MapCompleteTree_when_AllFieldsArePresent() {
            var timingConfig = new TimingConfig(
                    0.125f,
                    0.75f,
                    0.5f,
                    0.5f
            );
            var warehouseConfig = new WarehouseConfig(
                    100,
                    12
            );
            var demandConfig = new DemandConfig(
                    0.25,
                    20,
                    30,
                    5,
                    40,
                    2,
                    5,
                    new SupplyConfig(2400, 0.35, 0.15),
                    new DemandCycleConfig(800, 0.5, 1.5)
            );
            var inputConfig = new InputConfig(5);
            var uiConfig = new UiConfig(0.5, 0.2);
            var actual = ConfigParser.parse(validConfig());
            var expected = new BoxbotConfig(
                    4294967296L,
                    timingConfig,
                    warehouseConfig,
                    demandConfig,
                    inputConfig,
                    uiConfig
            );
            assertThat(actual).isEqualTo(expected);
        }

        @Test
        @DisplayName("Rejects a missing root category")
        void should_ThrowIllegalArgumentException_when_RootCategoryIsMissing() {
            var root = validConfig();

            root.remove("demand");

            assertThatIllegalArgumentException().isThrownBy(() ->
                    ConfigParser.parse(root)
            );
        }
    }

    private static JsonValue validConfig() {
        var input = ConfigParserTest.class.getResourceAsStream(VALID_CONFIG_RESOURCE);
        return new JsonReader().parse(input);
    }
}
