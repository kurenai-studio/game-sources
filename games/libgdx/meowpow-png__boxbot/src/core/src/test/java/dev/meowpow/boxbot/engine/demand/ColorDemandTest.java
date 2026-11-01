package dev.meowpow.boxbot.engine.demand;

import dev.meowpow.boxbot.engine.PackageColor;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;

class ColorDemandTest {

    @Nested
    @DisplayName("sample")
    class SampleMethodTests {

        @Test
        @DisplayName("Never returns the no-color value")
        void should_NeverReturnNone_when_Sampling() {
            var demand = new ColorDemand(42L);
            var samples = samples(demand);

            assertThat(samples).doesNotContain(PackageColor.NONE);
        }

        @Test
        @DisplayName("Returns the same sample sequence for the same seed")
        void should_ReturnSameSequence_when_SeedIsTheSame() {
            var demandA = new ColorDemand(42L);
            var demandB = new ColorDemand(42L);

            var samplesA = samples(demandA);
            var samplesB = samples(demandB);

            assertThat(samplesA).isEqualTo(samplesB);
        }
    }

    private static List<PackageColor> samples(ColorDemand demand) {
        return IntStream.range(0, 100)
                .mapToObj(ignored -> demand.sample())
                .toList();
    }
}
