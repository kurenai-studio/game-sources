package dev.meowpow.boxbot;

import dev.meowpow.boxbot.testing.IntegrationHarness;
import dev.meowpow.boxbot.testing.IntegrationTest;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

@IntegrationTest
class BoxbotGameIntegrationTest {

    @Test
    @DisplayName("Reaches the main menu when the game boots")
    void should_ReachMainMenu_when_GameBoots(IntegrationHarness harness) {
        await().atMost(Duration.ofSeconds(2)).until(() ->
                harness.game().getScreen() instanceof MainMenuScreen
        );
        assertThat(harness.game().getScreen()).isInstanceOf(MainMenuScreen.class);
    }
}
