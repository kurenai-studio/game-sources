package dev.meowpow.boxbot;

import dev.meowpow.boxbot.config.BoxbotConfig;
import dev.meowpow.boxbot.config.ConfigLoader;
import dev.meowpow.boxbot.engine.PackageColor;
import dev.meowpow.boxbot.engine.entity.ShelfId;
import dev.meowpow.boxbot.engine.robot.AiRobotController;
import dev.meowpow.boxbot.engine.time.SimulationClock;
import dev.meowpow.boxbot.render.assets.AssetLoader;
import dev.meowpow.boxbot.testing.IntegrationTest;

import com.badlogic.gdx.maps.tiled.TiledMap;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@IntegrationTest
class ShelfPreseederIntegrationTest {

    @Test
    @DisplayName("Places the same package colors on the same shelves for a fixed seed")
    void should_PlaceSameColors_when_SeedIsFixed() {
        var assetLoader = new AssetLoader();
        var config = new ConfigLoader().config();
        var map = assetLoader.map();

        var firstRun = shelfColors(config, map);
        var secondRun = shelfColors(config, map);

        assertThat(secondRun).isEqualTo(firstRun);
    }

    @Test
    @DisplayName("Places different package colors on shelves for a different seed")
    void should_PlaceDifferentColors_when_SeedDiffers() {
        var assetLoader = new AssetLoader();
        var config = new ConfigLoader().config();
        var map = assetLoader.map();
        var otherConfig = new BoxbotConfig(
                config.seed() + 1,
                config.timing(),
                config.warehouse(),
                config.demand(),
                config.input(),
                config.ui()
        );
        var firstRun = shelfColors(config, map);
        var secondRun = shelfColors(otherConfig, map);

        assertThat(secondRun).isNotEqualTo(firstRun);
    }

    private Map<ShelfId, PackageColor> shelfColors(BoxbotConfig config, TiledMap map) {
        var simulation = SimulationFactory.build(
                config,
                map,
                AiRobotController::new,
                false,
                new SimulationClock()
        );
        var shelves = simulation.world().shelves();
        var colors = new HashMap<ShelfId, PackageColor>(shelves.size());
        for (int i = 0; i < shelves.size(); i++) {
            var shelf = shelves.get(i);
            var pkg = shelf.occupyingPackage();
            colors.put(shelf.id(), pkg == null ? PackageColor.NONE : pkg.color());
        }
        return colors;
    }
}
