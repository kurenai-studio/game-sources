package gatorhunt;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LevelUpBannerTest {

    private static final long SECOND = GameStats.NANOSECONDS_PER_SECOND;

    @Test
    void showsTheVeryFirstLevelSeen() {
        LevelUpBanner banner = new LevelUpBanner();

        banner.update(0, 0L);

        assertTrue(banner.isVisible(0L));
        assertEquals(0, banner.level());
    }

    @Test
    void hidesAfterTheDisplayDurationPasses() {
        LevelUpBanner banner = new LevelUpBanner();
        banner.update(0, 0L);

        assertTrue(banner.isVisible(SECOND));
        assertFalse(banner.isVisible(SECOND * 3));
    }

    @Test
    void reappearsWhenTheLevelChangesAgain() {
        LevelUpBanner banner = new LevelUpBanner();
        banner.update(0, 0L);
        banner.update(0, SECOND * 3); // same level, banner should have already hidden and stay hidden

        assertFalse(banner.isVisible(SECOND * 3));

        banner.update(1, SECOND * 60);

        assertTrue(banner.isVisible(SECOND * 60));
        assertEquals(1, banner.level());
    }

    @Test
    void doesNotResetTheTimerWhileTheLevelStaysTheSame() {
        LevelUpBanner banner = new LevelUpBanner();
        banner.update(0, 0L);
        banner.update(0, SECOND); // still level 0, shouldn't push the hide time back out

        assertFalse(banner.isVisible(SECOND * 3));
    }
}
