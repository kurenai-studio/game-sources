package com.elmagica.game;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.TextureRegion;
import com.badlogic.gdx.utils.Array;

public class MerchantArt {
    private final SpriteFiles files = new SpriteFiles();
    private final TextureRegion[] pictures = new TextureRegion[8];
    public MerchantArt() {
        String[] names = {"characters/npc/merchant", "shop/pedestal", "shop/stat-card", "shop/healing-potion",
            "shop/ability-card", "shop/shield-card", "items/coins/pile", "items/coins/single"};
        for (int i = 0; i < names.length; i++) pictures[i] = files.load(names[i]);
    }
    private void picture(SpriteBatch batch, int index, float x, float y, float size) {
        TextureRegion image = pictures[index];
        float scale = size / Math.max(image.getRegionWidth(), image.getRegionHeight());
        float width = image.getRegionWidth() * scale, height = image.getRegionHeight() * scale;
        batch.draw(image, x - width / 2, y - height / 2, width, height);
    }
    public void draw(SpriteBatch batch, Merchant merchant, Array<LootDrop> drops) {
        for (LootDrop drop : drops) if (drop.type == LootDrop.Type.COIN) {
            picture(batch, drop.amount == 1 ? 7 : 6, drop.x, drop.y, 26 * drop.getScale());
        }
    }
    public void drawMerchant(SpriteBatch batch, Merchant merchant) {
        TextureRegion image = pictures[0];
        float scale = 126f / Math.max(image.getRegionWidth(), image.getRegionHeight());
        float width = image.getRegionWidth() * scale, height = image.getRegionHeight() * scale;
        float time = merchant.getAnimationTime();
        float breath = (float) Math.sin(time * 2.5f) * 0.015f;
        float shake = merchant.isTalking() ? (float) Math.sin(time * 38) * 1.4f : 0;
        // Дышит и трясётся при разговоре, но ноги не съезжают.
        batch.draw(image, Merchant.X - width / 2 + shake, Merchant.Y + 18 - height / 2,
            width / 2, 0, width, height, 1 - breath * 0.4f, 1 + breath, shake * 0.5f);
    }
    public void drawPedestal(SpriteBatch batch, Merchant merchant, int i) {
            picture(batch, 1, Merchant.itemX(i), Merchant.ITEM_Y - 10, 74);
            MerchantItem item = merchant.items[i];
            if (item.sold) return;
            int image = item.upgrade == 7 ? 3 : item.upgrade == 5 ? 4 : item.upgrade == 6 ? 5 : 2;
            float lift = (float) Math.sin(merchant.getAnimationTime() * 3 + i) * 3;
            picture(batch, image, Merchant.itemX(i), Merchant.ITEM_Y + 30 + lift, 44);
    }
    public void dispose() { files.dispose(); }
}
