package dev.luchoc.littlespaceship.core.port;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * The simple content contracts fail loudly on malformed data instead of letting a null or an empty
 * collection surface as a {@code NullPointerException} somewhere else later.
 */
class ContentDefinitionsTest {

    @Test
    @DisplayName("an enemy definition needs an id and at least one component")
    void enemyDefinitionValidates() {
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleEnemyDefinition("", List.of(basicSprite())));
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleEnemyDefinition("enemy-basic", List.of()));
    }

    @Test
    @DisplayName("a trajectory needs an id")
    void trajectoryValidates() {
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleTrajectoryDefinition("", 0f, -20f));
    }

    @Test
    @DisplayName("a constant shape's vertical velocity never changes with elapsed time")
    void constantShapeIgnoresElapsedTime() {
        TrajectoryDefinition slowDescent = new SimpleTrajectoryDefinition("slow-descent", 0f, -18f);

        assertEquals(-18f, slowDescent.verticalVelocityAt(0f));
        assertEquals(-18f, slowDescent.verticalVelocityAt(4.07f));
        assertEquals(-18f, slowDescent.vy());
    }

    @Test
    @DisplayName("an arc trajectory needs an id and every parameter finite")
    void arcTrajectoryValidates() {
        assertThrows(IllegalArgumentException.class,
            () -> new ArcTrajectoryDefinition("", 0f, -110f, 27f));
        assertThrows(IllegalArgumentException.class,
            () -> new ArcTrajectoryDefinition("strike-run", Float.NaN, -110f, 27f));
        assertThrows(IllegalArgumentException.class,
            () -> new ArcTrajectoryDefinition("strike-run", 0f, Float.POSITIVE_INFINITY, 27f));
        assertThrows(IllegalArgumentException.class,
            () -> new ArcTrajectoryDefinition("strike-run", 0f, -110f, Float.NEGATIVE_INFINITY));
    }

    @Test
    @DisplayName("an arc's vertical velocity is vy plus ay times elapsed time, and it turns when that reaches zero")
    void arcShapeEvaluatesTheClosedForm() {
        // strike-run from the shape catalogue: vx 0, vy -110, ay 27 — turns at t = -vy / ay = 4.07s.
        TrajectoryDefinition strikeRun = new ArcTrajectoryDefinition("strike-run", 0f, -110f, 27f);

        assertEquals(-110f, strikeRun.verticalVelocityAt(0f));
        assertEquals(-110f, strikeRun.vy());
        assertEquals(-110f + 27f * 2f, strikeRun.verticalVelocityAt(2f));
        assertEquals(0f, strikeRun.verticalVelocityAt(-strikeRun.vy() / 27f), 1e-4f,
            "should be at rest, vertically, at its own turning point");
        assertTrue(strikeRun.verticalVelocityAt(8f) > 0f, "should be climbing well past the turn");
    }

    @Test
    @DisplayName("ay = 0 makes an arc behave like a constant, without being one")
    void zeroAccelerationArcDegeneratesToConstant() {
        TrajectoryDefinition flatArc = new ArcTrajectoryDefinition("flat", -10f, -40f, 0f);

        assertEquals(-40f, flatArc.verticalVelocityAt(0f));
        assertEquals(-40f, flatArc.verticalVelocityAt(100f));
    }

    @Test
    @DisplayName("a formation needs an id and at least one slot")
    void formationValidates() {
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleFormationDefinition("", List.of(new FormationSlot(0f, 0f))));
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleFormationDefinition("single", List.of()));
    }

    @Test
    @DisplayName("a formation slot's two-argument constructor has no delay, and a delay must be a finite, non-negative number")
    void formationSlotDelayValidates() {
        FormationSlot noDelay = new FormationSlot(10f, -5f);
        assertEquals(0f, noDelay.delaySeconds());

        assertThrows(IllegalArgumentException.class, () -> new FormationSlot(0f, 0f, -0.1f));
        assertThrows(IllegalArgumentException.class, () -> new FormationSlot(0f, 0f, Float.NaN));
        assertThrows(IllegalArgumentException.class,
            () -> new FormationSlot(0f, 0f, Float.POSITIVE_INFINITY));
    }

    @Test
    @DisplayName("a spawn event rejects a negative timestamp, a missing id and an anchor outside [0,1]")
    void spawnEventValidates() {
        assertThrows(IllegalArgumentException.class,
            () -> new SpawnEvent(-1f, "enemy-basic", "single", 0.5f, null));
        assertThrows(IllegalArgumentException.class,
            () -> new SpawnEvent(1f, "", "single", 0.5f, null));
        assertThrows(IllegalArgumentException.class,
            () -> new SpawnEvent(1f, "enemy-basic", "", 0.5f, null));
        assertThrows(IllegalArgumentException.class,
            () -> new SpawnEvent(1f, "enemy-basic", "single", 1.5f, null));
    }

    @Test
    @DisplayName("hasDrop is false for a null or empty drop id, true otherwise")
    void hasDropReadsTheDropId() {
        assertTrue(new SpawnEvent(1f, "enemy-basic", "single", 0f, "shield").hasDrop());
        assertEqualsFalse(new SpawnEvent(1f, "enemy-basic", "single", 0f, null).hasDrop());
        assertEqualsFalse(new SpawnEvent(1f, "enemy-basic", "single", 0f, "").hasDrop());
    }

    @Test
    @DisplayName("a wave timeline rejects an empty list and one out of order")
    void waveTimelineValidates() {
        assertThrows(IllegalArgumentException.class, () -> new SimpleWaveTimeline(List.of()));

        List<SpawnEvent> outOfOrder = List.of(
            new SpawnEvent(10f, "enemy-basic", "single", 0.5f, null),
            new SpawnEvent(5f, "enemy-light", "single", 0.5f, null));

        IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -> new SimpleWaveTimeline(outOfOrder));
        assertTrue(e.getMessage().contains("1"), "should name the offending index");
    }

    @Test
    @DisplayName("an attachment needs an id and a strictly positive durability")
    void attachmentDefinitionValidates() {
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleAttachmentDefinition("", 1));
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleAttachmentDefinition("attachment", 0));
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleAttachmentDefinition("attachment", -1));
    }

    @Test
    @DisplayName("a sorted timeline is accepted as-is")
    void sortedTimelineIsAccepted() {
        List<SpawnEvent> sorted = List.of(
            new SpawnEvent(5f, "enemy-basic", "single", 0.5f, null),
            new SpawnEvent(10f, "enemy-light", "single", 0.5f, null));

        WaveTimeline timeline = new SimpleWaveTimeline(sorted);

        assertEquals(2, timeline.events().size());
    }

    @Test
    @DisplayName("a fixed wave duration rejects zero, negative, NaN and infinite durations")
    void fixedDurationValidates() {
        assertThrows(IllegalArgumentException.class, () -> new WaveEndCondition.FixedDuration(0f));
        assertThrows(IllegalArgumentException.class, () -> new WaveEndCondition.FixedDuration(-1f));
        assertThrows(IllegalArgumentException.class,
            () -> new WaveEndCondition.FixedDuration(Float.NaN));
        assertThrows(IllegalArgumentException.class,
            () -> new WaveEndCondition.FixedDuration(Float.POSITIVE_INFINITY));
    }

    @Test
    @DisplayName("a wave definition needs an id, at least one spawn, spawns in order and an end condition")
    void waveDefinitionValidates() {
        List<SpawnEvent> oneSpawn = List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null));
        WaveEndCondition fixed = new WaveEndCondition.FixedDuration(3f);

        assertThrows(IllegalArgumentException.class,
            () -> new SimpleWaveDefinition("", oneSpawn, fixed));
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleWaveDefinition("wave-1", List.of(), fixed));
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleWaveDefinition("wave-1", oneSpawn, null));

        List<SpawnEvent> outOfOrder = List.of(
            new SpawnEvent(2f, "enemy-basic", "single", 0.5f, null),
            new SpawnEvent(1f, "enemy-light", "single", 0.5f, null));
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleWaveDefinition("wave-1", outOfOrder, fixed));
    }

    @Test
    @DisplayName("a placed pickup rejects a negative timestamp, a missing kind and a position outside [0,1]")
    void placedPickupValidates() {
        assertThrows(IllegalArgumentException.class,
            () -> new PlacedPickup(-1f, "shield", 0.5f, 0.5f));
        assertThrows(IllegalArgumentException.class,
            () -> new PlacedPickup(1f, "", 0.5f, 0.5f));
        assertThrows(IllegalArgumentException.class,
            () -> new PlacedPickup(1f, null, 0.5f, 0.5f));
        assertThrows(IllegalArgumentException.class,
            () -> new PlacedPickup(1f, "shield", 1.5f, 0.5f));
        assertThrows(IllegalArgumentException.class,
            () -> new PlacedPickup(1f, "shield", 0.5f, -0.1f));
    }

    @Test
    @DisplayName("a wave definition with no placed pickup defaults pickups() to empty")
    void waveDefinitionDefaultsToNoPlacedPickups() {
        List<SpawnEvent> oneSpawn = List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null));
        WaveDefinition wave =
            new SimpleWaveDefinition("wave-1", oneSpawn, new WaveEndCondition.FixedDuration(3f));

        assertEquals(List.of(), wave.pickups());
    }

    @Test
    @DisplayName("a wave definition rejects a null pickup list and one out of order")
    void waveDefinitionValidatesItsPickupList() {
        List<SpawnEvent> oneSpawn = List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null));
        WaveEndCondition fixed = new WaveEndCondition.FixedDuration(3f);

        assertThrows(IllegalArgumentException.class,
            () -> new SimpleWaveDefinition("wave-1", oneSpawn, null, fixed));

        List<PlacedPickup> outOfOrder = List.of(
            new PlacedPickup(2f, "shield", 0.5f, 0.5f),
            new PlacedPickup(1f, "shield", 0.5f, 0.5f));
        assertThrows(IllegalArgumentException.class,
            () -> new SimpleWaveDefinition("wave-1", oneSpawn, outOfOrder, fixed));

        List<PlacedPickup> sorted = List.of(
            new PlacedPickup(1f, "shield", 0.5f, 0.5f),
            new PlacedPickup(2f, "shield", 0.5f, 0.5f));
        WaveDefinition wave = new SimpleWaveDefinition("wave-1", oneSpawn, sorted, fixed);
        assertEquals(2, wave.pickups().size());
    }

    @Test
    @DisplayName("a wave placement needs a wave id and a finite offset, negative allowed to overlap")
    void wavePlacementValidates() {
        assertThrows(IllegalArgumentException.class, () -> new WavePlacement("", 0f));
        assertThrows(IllegalArgumentException.class, () -> new WavePlacement("wave-1", Float.NaN));
        assertThrows(IllegalArgumentException.class,
            () -> new WavePlacement("wave-1", Float.POSITIVE_INFINITY));

        WavePlacement overlapping = new WavePlacement("wave-1", -2f);

        assertEquals("wave-1", overlapping.waveId());
        assertEquals(-2f, overlapping.offsetSeconds());
    }

    @Test
    @DisplayName("the same wave id can back two different placements, unaffected by either")
    void waveDefinitionCarriesNoPlacementOfItsOwn() {
        List<SpawnEvent> oneSpawn = List.of(new SpawnEvent(0f, "enemy-basic", "single", 0.5f, null));
        WaveDefinition wave =
            new SimpleWaveDefinition("wave-1", oneSpawn, new WaveEndCondition.Cleared());

        WavePlacement first = new WavePlacement(wave.id(), 0f);
        WavePlacement second = new WavePlacement(wave.id(), -3f);

        assertEquals(wave.id(), first.waveId());
        assertEquals(wave.id(), second.waveId());
        assertEquals(0f, first.offsetSeconds());
        assertEquals(-3f, second.offsetSeconds());
    }

    private static void assertEqualsFalse(boolean value) {
        assertEquals(false, value);
    }

    private static ComponentSpec basicSprite() {
        return new MapComponentSpec("sprite", java.util.Map.of("id", "enemy-basic"));
    }
}
