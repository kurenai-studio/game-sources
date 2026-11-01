package com.badlogic.gdx.tools.texturepacker;

import com.badlogic.gdx.tools.texturepacker.MaxRectsPacker;
import com.badlogic.gdx.tools.texturepacker.TexturePacker;
import com.badlogic.gdx.utils.Array;

/**
 * Takes into account the order of rendering layers in tiled
 * @author buriningrain
 */
public class TiledLayerPacker implements TexturePacker.Packer {

    final TexturePacker.Settings settings;
    // Используем проверенный MaxRectsPacker для плотной упаковки порций данных
    final MaxRectsPacker delegatePacker;

    public TiledLayerPacker (TexturePacker.Settings settings) {
        this.settings = settings;
        this.delegatePacker = new MaxRectsPacker(settings);

        if (settings.minWidth > settings.maxWidth) throw new RuntimeException("Page min width cannot be higher than max width.");
        if (settings.minHeight > settings.maxHeight) throw new RuntimeException("Page min height cannot be higher than max height.");
    }

    @Override
    public Array<TexturePacker.Page> pack(Array<TexturePacker.Rect> inputRects) {
        return pack(null, inputRects);
    }

    @Override
    public Array<TexturePacker.Page> pack(TexturePacker.ProgressListener progress, Array<TexturePacker.Rect> inputRects) {
        Array<TexturePacker.Page> finalPages = new Array<>();
        if (inputRects.size == 0) return finalPages;

        Array<TexturePacker.Rect> currentBatch = new Array<>();
        int processedCount = 0;

        for (int i = 0; i < inputRects.size; i++) {
            TexturePacker.Rect rect = inputRects.get(i);
            currentBatch.add(rect);

            // Клонируем Rect-ы для теста, так как упаковщик модифицирует их x, y, rotated координаты
            Array<TexturePacker.Rect> testRects = cloneRects(currentBatch);

            // Пробуем упаковать текущую пачку через MaxRectsPacker
            Array<TexturePacker.Page> testPages = delegatePacker.pack(progress, testRects);

            // Проверяем, уложилась ли пачка в жесткие рамки ОДНОЙ страницы 2048x2048
            boolean fitsInSinglePage = testPages.size == 1
                && testPages.get(0).width <= settings.maxWidth
                && testPages.get(0).height <= settings.maxHeight;

            if (!fitsInSinglePage) {
                // Если не влезло, значит последний добавленный элемент лишний на этой странице.
                // Убираем его из текущей пачки
                currentBatch.pop();

                // Упаковываем утвержденную пачку (без лишнего элемента) набело
                if (currentBatch.size > 0) {
                    Array<TexturePacker.Page> approvedPages = delegatePacker.pack(progress, currentBatch);
                    finalPages.addAll(approvedPages);
                    processedCount += currentBatch.size;
                }

                // Очищаем пачку для следующей страницы и возвращаем "лишний" элемент обратно,
                // но уже как первый элемент нового листа
                currentBatch.clear();
                currentBatch.add(rect);
            }
        }

        // Упаковываем самый последний оставшийся кусочек (хвост)
        if (currentBatch.size > 0) {
            Array<TexturePacker.Page> approvedPages = delegatePacker.pack(progress, currentBatch);
            finalPages.addAll(approvedPages);
            processedCount += currentBatch.size;
        }

        return finalPages;
    }

    // Хелпер для глубокого копирования прямоугольников перед тестовой упаковкой
    private Array<TexturePacker.Rect> cloneRects(Array<TexturePacker.Rect> src) {
        Array<TexturePacker.Rect> dest = new Array<>(src.size);
        for (TexturePacker.Rect r : src) {
            TexturePacker.Rect copy = new TexturePacker.Rect();
            copy.name = r.name;
            copy.width = r.width;
            copy.height = r.height;
            copy.originalWidth = r.originalWidth;
            copy.originalHeight = r.originalHeight;
            copy.offsetX = r.offsetX;
            copy.offsetY = r.offsetY;
            copy.index = r.index;
            copy.rotated = r.rotated;
            copy.aliases = r.aliases;
            dest.add(copy);
        }
        return dest;
    }
}
