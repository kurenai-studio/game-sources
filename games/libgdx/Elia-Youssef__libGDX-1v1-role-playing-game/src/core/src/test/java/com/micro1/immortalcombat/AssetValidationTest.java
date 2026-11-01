package com.micro1.immortalcombat;

import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import java.awt.image.BufferedImage;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AssetValidationTest {

    private static final String[] ACTIONS = {
        "idle", "punch", "kick", "forward", "backward", "jump", "crouch", "block"
    };

    @Test
    void everyActionHasThreeDistinctSquareFrames() throws Exception {
        Path assets = findAssetsDirectory();

        for (String action : ACTIONS) {
            Set<String> frameHashes = new HashSet<String>();
            for (int frame = 0; frame < PlayerController.FRAMES_PER_ACTION; frame++) {
                Path imagePath = assets.resolve(action + "_" + frame + ".png");
                assertTrue(Files.isRegularFile(imagePath), "Missing asset: " + imagePath);

                BufferedImage image = ImageIO.read(imagePath.toFile());
                assertNotNull(image, "Unreadable PNG: " + imagePath);
                assertEquals(256, image.getWidth(), "Unexpected width: " + imagePath);
                assertEquals(256, image.getHeight(), "Unexpected height: " + imagePath);

                int[] pixels = image.getRGB(0, 0, image.getWidth(), image.getHeight(), null, 0, image.getWidth());
                frameHashes.add(Integer.toString(Arrays.hashCode(pixels)));
            }
            assertEquals(3, frameHashes.size(), action + " frames must be visually distinct files");
        }
    }

    @Test
    void attackSoundIsAReadableWaveFile() throws Exception {
        Path soundPath = findAssetsDirectory().resolve("woosh.wav");
        assertTrue(Files.size(soundPath) > 0, "woosh.wav is empty");

        try (AudioInputStream stream = AudioSystem.getAudioInputStream(soundPath.toFile())) {
            assertTrue(stream.getFrameLength() > 0, "woosh.wav contains no audio frames");
        }
    }

    private static Path findAssetsDirectory() {
        Path direct = Paths.get("assets").toAbsolutePath().normalize();
        if (Files.isDirectory(direct)) {
            return direct;
        }

        Path fromCoreModule = Paths.get("..", "assets").toAbsolutePath().normalize();
        assertTrue(Files.isDirectory(fromCoreModule), "Could not locate the assets directory");
        return fromCoreModule;
    }
}
