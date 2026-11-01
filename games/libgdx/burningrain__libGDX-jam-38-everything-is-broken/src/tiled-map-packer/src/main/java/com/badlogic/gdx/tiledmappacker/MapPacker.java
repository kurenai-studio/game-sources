package com.badlogic.gdx.tiledmappacker;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.backends.lwjgl.LwjglApplication;
import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.tools.texturepacker.TexturePacker;
import com.badlogic.gdx.tools.texturepacker.TiledLayerPacker;

import java.io.File;

public class MapPacker {

    private static class DummyApp extends ApplicationAdapter {
        private final Runnable packingTask;

        public DummyApp(Runnable packingTask) {
            this.packingTask = packingTask;
        }

        @Override
        public void create() {
            // Выполняем упаковку сразу после инициализации LibGDX
            packingTask.run();
            // Завершаем приложение после выполнения
            Gdx.app.exit();
        }
    }

    public static void main(String[] args) {
        // Настройки окна: размер 1x1, без визуализации
        LwjglApplicationConfiguration config = new LwjglApplicationConfiguration();
        LwjglApplicationConfiguration.disableAudio = true; // Добавьте эту строку
        config.width = 1;
        config.height = 1;
        config.resizable = false;
        config.forceExit = false;
        config.title = "TiledMapPacker Headless";

        // Важно: устанавливаем количество сэмплов в 0
        config.samples = 0;

        // Создаём задачу упаковки
        Runnable packTask = () -> {
            try {
                System.out.println("Начинаем упаковку карт...");

                TexturePacker.Settings settings = new TexturePacker.Settings();
                settings.combineSubdirectories = true;
                settings.fast = true;

                settings.maxWidth = 2048;
                settings.maxHeight = 2048;
                settings.paddingX = 2;
                settings.paddingY = 2;
                settings.duplicatePadding = true;
                settings.edgePadding = true;
                settings.filterMin = Texture.TextureFilter.Linear;
                settings.filterMag = Texture.TextureFilter.Linear;

                String inputDir = "D:/projects/libGDX-jam-36-thats-a-weapon/assets/tiled";
                String outputDir = "D:/projects/libGDX-jam-36-thats-a-weapon/assets/tiled-packed";

                deleteDirectoryContents(outputDir);

                CustomTiledMapPacker packer = new CustomTiledMapPacker() {
                    @Override
                    public TexturePacker newTexturePacker(TexturePacker.Settings texturePackerSettings) {
                        TexturePacker texturePacker = new TexturePacker(texturePackerSettings);
                        texturePacker.setPacker(new TiledLayerPacker(texturePackerSettings));

                        return texturePacker;
                    }
                };
                CustomTiledMapPacker.inputDir = new File(inputDir);
                CustomTiledMapPacker.outputDir = new File(outputDir);

                packer.processInputDir(settings);

                System.out.println("Упаковка завершена успешно!");

            } catch (Exception e) {
                System.err.println("Ошибка при упаковке:");
                e.printStackTrace();
            }
        };

        // Запускаем приложение с задачей упаковки
        new LwjglApplication(new DummyApp(packTask), config);
    }

    public static void deleteDirectoryContents(String outputDir) {
        File directory = new File(outputDir);

        if (directory.exists()) {
            deleteRecursively(directory);
            System.out.println("Directory contents deleted: " + outputDir);
        }
    }

    private static void deleteRecursively(File file) {
        if (file.isDirectory()) {
            File[] files = file.listFiles();
            if (files != null) {
                for (File child : files) {
                    deleteRecursively(child);
                }
            }
        }
        file.delete();
    }


}
