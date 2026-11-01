package dev.meowpow.boxbot.engine;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PackageColorTest {

    @Nested
    @DisplayName("colored")
    class ColoredMethodTests {

        @Test
        @DisplayName("Returns every color except none")
        void should_ReturnEveryColorExceptNone_when_ColorsAreRequested() {
            List<PackageColor> expected = Arrays.stream(PackageColor.values())
                    .filter(color -> color != PackageColor.NONE)
                    .toList();

            assertThat(PackageColor.colored()).containsExactlyElementsOf(expected);
        }
    }
}
