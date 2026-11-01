package dev.luchoc.littlespaceship.core.architecture;

import static org.junit.jupiter.api.Assertions.assertTrue;

import dev.luchoc.littlespaceship.core.architecture.CoreSources.SourceFile;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * The dependency rule of the hexagonal architecture, checked instead of trusted.
 *
 * <p>Everything points inwards. The domain knows the ports it declares and nothing else; the ports
 * know no machinery; the application composes both. A single import in the wrong direction is
 * enough to lose the boundary, and it never announces itself.
 */
class LayerDependencyTest {

    private static final String ROOT = "dev.luchoc.littlespaceship";
    private static final String DOMAIN = ROOT + ".core.domain";
    private static final String APPLICATION = ROOT + ".core.application";
    private static final String PORT = ROOT + ".core.port";

    /**
     * The one part of the domain a port may legitimately name — the domain events, which are
     * immutable and exist precisely to be read from outside. Everything else under {@code
     * core.domain}, present today or added tomorrow, is machinery: a whitelist catches a new
     * package by construction, where a list of known offenders only catches the ones already on it.
     */
    private static final String DOMAIN_CONTRACT = DOMAIN + ".event";

    @Test
    @DisplayName("the domain does not know the application layer exists")
    void domainDoesNotDependOnApplication() {
        List<String> violations = new ArrayList<>();
        for (SourceFile file : CoreSources.all()) {
            if (!file.packageName().startsWith(DOMAIN)) {
                continue;
            }
            for (String imported : file.imports()) {
                if (imported.startsWith(APPLICATION)) {
                    violations.add(file.path() + " imports " + imported);
                }
            }
        }

        assertTrue(violations.isEmpty(),
            () -> "the domain must not point outwards:\n" + String.join("\n", violations));
    }

    @Test
    @DisplayName("the ports do not expose the machinery of the domain")
    void portsDoNotDependOnMachinery() {
        List<String> violations = new ArrayList<>();
        for (SourceFile file : CoreSources.all()) {
            if (!file.packageName().startsWith(PORT)) {
                continue;
            }
            for (String imported : file.imports()) {
                if (imported.startsWith(APPLICATION)) {
                    violations.add(file.path() + " imports " + imported);
                }
                if (imported.startsWith(DOMAIN) && !imported.startsWith(DOMAIN_CONTRACT + ".")) {
                    violations.add(file.path() + " imports " + imported);
                }
            }
        }

        assertTrue(violations.isEmpty(),
            () -> "a port may name domain contracts, never the ECS:\n"
                + String.join("\n", violations));
    }

    @Test
    @DisplayName("nothing in core imports another module of the project")
    void coreDependsOnNoOtherModule() {
        List<String> violations = new ArrayList<>();
        for (SourceFile file : CoreSources.all()) {
            for (String imported : file.imports()) {
                if (imported.startsWith(ROOT) && !imported.startsWith(ROOT + ".core.")) {
                    violations.add(file.path() + " imports " + imported);
                }
            }
        }

        assertTrue(violations.isEmpty(),
            () -> "core is the innermost module:\n" + String.join("\n", violations));
    }

    @Test
    @DisplayName("every source of core lives in one of the three layers")
    void everySourceBelongsToALayer() {
        List<String> strays = new ArrayList<>();
        for (SourceFile file : CoreSources.all()) {
            String packageName = file.packageName();
            boolean known = packageName.startsWith(DOMAIN)
                || packageName.startsWith(APPLICATION)
                || packageName.startsWith(PORT);
            if (!known) {
                strays.add(file.path());
            }
        }

        assertTrue(strays.isEmpty(),
            () -> "domain, application or port, nothing else:\n" + String.join("\n", strays));
    }
}
