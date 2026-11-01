package com.elmagica.game;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.regex.Pattern;

public class LanguageChecks {
    public static void run() {
        boolean original = GameText.english;
        try {
            GameText.english = true;
            require(GameText.tr("Этаж 12").equals("Floor 12"), "Dynamic floor and space");
            require(GameText.tr("КД стрельбы: 0,50 с").equals("Shot cooldown: 0.50 s"), "English decimal and units");
            require(GameText.tr("Огонь").equals("Fire"), "Element name");
            Path source = Path.of("src/main/java/com/elmagica/game");
            if (!Files.isDirectory(source)) source = Path.of("core/src/main/java/com/elmagica/game");
            Pattern literal = Pattern.compile("\"([^\"\\r\\n]*)\"");
            Pattern russian = Pattern.compile("[А-Яа-яЁё]");
            try (var files = Files.list(source)) {
                for (Path file : files.toList()) {
                    if (file.getFileName().toString().equals("GameText.java") || file.getFileName().toString().equals("PixelText.java")) continue;
                    var matches = literal.matcher(Files.readString(file));
                    while (matches.find()) {
                        String text = matches.group(1);
                        if (russian.matcher(text).find()) require(!russian.matcher(GameText.tr(text)).find(), "Missing translation in " + file + ": " + text);
                    }
                }
            }
            Player player = new Player(ElementType.EARTH);
            for (int choice = 0; choice < 7; choice++) {
                PlayerUpgrade reward = PlayerUpgrade.apply(player, choice);
                require(!russian.matcher(GameText.tr(reward.title + " " + reward.change)).find(), "Dynamic upgrade");
            }
            GameText.english = false;
            require(GameText.tr("Этаж 12").equals("Этаж 12"), "Russian remains intact");
            System.out.println("Language checks passed: all UI literals, dynamic rewards, units and Russian fallback");
        } catch (java.io.IOException e) { throw new RuntimeException(e); }
        finally { GameText.english = original; }
    }
    private static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
}
