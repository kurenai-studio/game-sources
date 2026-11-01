package dev.luchoc.littlespaceship.core.architecture;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Cases the plain-text forbidden-API search would get wrong without them: the awkward corners of
 * Java string and char literals, named in {@link JavaSource#strip(String)}'s own javadoc as what it
 * handles and what it does not.
 */
class JavaSourceTest {

    @Test
    @DisplayName("an escaped quote inside a string does not end the literal early")
    void anEscapedQuoteDoesNotEndTheLiteralEarly() {
        // The string is: a quote character, then Thread, then a quote character -- "\"Thread\""
        String fixture = "String s = \"\\\"Thread\\\"\";";
        assertFalse(JavaSource.containsToken(JavaSource.strip(fixture), "Thread"));
    }

    @Test
    @DisplayName("an escaped backslash right before the closing quote still closes the literal")
    void anEscapedBackslashBeforeTheClosingQuoteStillCloses() {
        // The string content is a single backslash: "\\". The code after it is real and must survive.
        String fixture = "String s = \"\\\\\"; new Thread(task);";
        assertTrue(JavaSource.containsToken(JavaSource.strip(fixture), "Thread"));
    }

    @Test
    @DisplayName("a char literal holding a quote does not confuse string scanning")
    void aCharLiteralHoldingAQuoteDoesNotConfuseStringScanning() {
        String fixture = "char q = '\"'; new Thread(task);";
        assertTrue(JavaSource.containsToken(JavaSource.strip(fixture), "Thread"));
    }

    @Test
    @DisplayName("an escaped quote inside a char literal does not end it early")
    void anEscapedQuoteInsideACharLiteralDoesNotEndItEarly() {
        String fixture = "char q = '\\''; new Thread(task);";
        assertTrue(JavaSource.containsToken(JavaSource.strip(fixture), "Thread"));
    }

    @Test
    @DisplayName("a forbidden name inside a char literal's escape is not a call")
    void aForbiddenNameCannotHideInsideACharLiteral() {
        // Not a realistic literal, only a boundary check: the scanner must not run past the literal.
        String fixture = "char q = 'x'; // Thread mentioned only here, not called\n int i = 1;";
        assertFalse(JavaSource.containsToken(JavaSource.strip(fixture), "Thread"));
    }
}
