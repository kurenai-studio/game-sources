package dev.luchoc.littlespaceship.core.architecture;

/**
 * Searching Java sources for a token, as a whole word, outside comments and string/char literals.
 *
 * <p>The forbidden API checks are plain text searches, deliberately: they have to agree with the
 * grep a reviewer runs by hand. Whole words are one refinement, so that a field named threadCount
 * is not read as a use of the Thread class. {@link #strip(String)} is the other: a name spelled out
 * inside a comment or a string is not a call, and should not be able to turn the check red.
 */
final class JavaSource {

    private JavaSource() {
    }

    /**
     * Finds a token as a whole word, so a type whose name merely contains the token does not count.
     *
     * @param content the text to search
     * @param token the exact token to look for
     * @return true when the token appears on its own
     */
    static boolean containsToken(String content, String token) {
        int from = 0;
        while (true) {
            int at = content.indexOf(token, from);
            if (at < 0) {
                return false;
            }
            int end = at + token.length();
            boolean startsClean = at == 0
                || !Character.isJavaIdentifierPart(content.charAt(at - 1));
            boolean endsClean = end >= content.length()
                || !Character.isJavaIdentifierPart(content.charAt(end));
            if (startsClean && endsClean) {
                return true;
            }
            from = at + 1;
        }
    }

    /**
     * Replaces every {@code //} comment, {@code /* *}{@code /} comment and string or char literal
     * with a single space, so {@link #containsToken(String, String)} run on the result only sees
     * actual code.
     *
     * <p>What this handles: line comments, block comments (including one that never closes, which
     * is stripped to the end of the file rather than left to loop forever), string literals with
     * escaped characters ({@code \"}, {@code \\}, an escaped backslash immediately before the closing
     * quote included), and char literals such as {@code '"'} or {@code '\\''}.
     *
     * <p>What this deliberately does not handle: text blocks ({@code """}). No file under
     * {@code core/src/main} uses one today (checked by hand), so a naive triple-quote reader would
     * add risk — misreading the first two quotes of the opening delimiter as an empty string literal,
     * then racing ahead to the next unrelated quote — for a construct that is not actually present.
     * If a text block is ever added to core, this method needs to grow with it or it will misread the
     * source around it.
     *
     * @param content the source text
     * @return the same text with every comment and literal blanked out to a single space
     */
    static String strip(String content) {
        StringBuilder out = new StringBuilder(content.length());
        int n = content.length();
        int i = 0;
        while (i < n) {
            char c = content.charAt(i);
            if (c == '/' && i + 1 < n && content.charAt(i + 1) == '/') {
                i += 2;
                while (i < n && content.charAt(i) != '\n') {
                    i++;
                }
                out.append(' ');
                continue;
            }
            if (c == '/' && i + 1 < n && content.charAt(i + 1) == '*') {
                i += 2;
                while (i + 1 < n && !(content.charAt(i) == '*' && content.charAt(i + 1) == '/')) {
                    i++;
                }
                i = Math.min(i + 2, n);
                out.append(' ');
                continue;
            }
            if (c == '"') {
                i = skipLiteral(content, i, '"');
                out.append(' ');
                continue;
            }
            if (c == '\'') {
                i = skipLiteral(content, i, '\'');
                out.append(' ');
                continue;
            }
            out.append(c);
            i++;
        }
        return out.toString();
    }

    /**
     * Advances past a string or char literal starting at {@code from}, honouring {@code \}
     * escapes so an escaped closing quote, or an escaped backslash right before a real one, does
     * not end the literal early or late.
     */
    private static int skipLiteral(String content, int from, char quote) {
        int n = content.length();
        int i = from + 1;
        while (i < n) {
            char c = content.charAt(i);
            if (c == '\\' && i + 1 < n) {
                i += 2;
                continue;
            }
            if (c == quote) {
                return i + 1;
            }
            if (c == '\n') {
                return i;
            }
            i++;
        }
        return n;
    }
}
