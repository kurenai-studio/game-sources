package com.elmagica.game;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Vector2;

public class Merchant {
    public static final float X = ElMagicaGame.WORLD_WIDTH / 2f;
    public static final float Y = ElMagicaGame.WORLD_HEIGHT / 2f + 176;
    public static final float ITEM_Y = Y - 192;
    public final MerchantItem[] items = new MerchantItem[3];
    private float messageTimer;
    private float talkTimer;
    public boolean isTalking() { return talkTimer > 0; }
    private float animationTime;
    private int advice;
    private String message = "";
    private static final String[] ADVICE = {
        "Камень не уступает дорогу. Уступи ему сам.",
        "У быстрых ног истории обычно длиннее.",
        "Вода помнит, куда торопился огонь.",
        "Красная склянка не знает цену твоей гордости.",
        "Когда лестница молчит, послушай комнату.",
        "Тот, кто смотрит только на врага, встретит стену.",
        "Большой кошелёк не делает шляпу крепче.",
        "Чем выше башня, тем дороже привычки.",
        "Иногда шаг в сторону полезнее красивого выстрела.",
        "Пустой пьедестал редко становится полным дважды.",
        "Книга на полу ещё никого сама не подняла.",
        "У семёрки тяжёлые шаги. Ты их услышишь."
    };

    public Merchant(Player player) { this(player, MathUtils.random(99)); }
    public Merchant(Player player, int roll) {
        int first = common(player, -1);
        int second = common(player, first);
        items[0] = new MerchantItem(first);
        items[1] = new MerchantItem(second);
        items[2] = new MerchantItem(MerchantItem.HEAL);
        if (roll >= 80 && roll < 95) items[2] = new MerchantItem(common(player, first, second));
        if (roll >= 95 && roll < 99 && PlayerUpgrade.canImprove(player, 5)) items[1] = new MerchantItem(5);
        if (roll >= 99 && PlayerUpgrade.canImprove(player, 6)) items[1] = new MerchantItem(6);
        advice = MathUtils.random(ADVICE.length - 1);
    }
    private int common(Player player, int... exclude) {
        int[] choices = new int[5]; int count = 0;
        for (int upgrade = 0; upgrade < 5; upgrade++) {
            boolean allowed = PlayerUpgrade.canImprove(player, upgrade);
            for (int previous : exclude) if (previous == upgrade) allowed = false;
            if (allowed) choices[count++] = upgrade;
        }
        // Если остальные статы упёрлись в потолок, остаются урон и ХП.
        return count == 0 ? 2 : choices[MathUtils.random(count - 1)];
    }
    public static float itemX(int index) { return X + (index - 1) * 256; }
    public int nearest(Player player) {
        if (!player.isAlive()) return -1;
        int target = -1; float closest = 88;
        for (int i = 0; i < 4; i++) {
            float x = i == 3 ? X : itemX(i), y = i == 3 ? Y : ITEM_Y;
            float distance = Vector2.dst(player.x + 30, player.y + 30, x, y);
            if (distance <= closest) { closest = distance; target = i; }
        }
        return target;
    }
    public void interact(Player player, CombatSession session) {
        int target = nearest(player);
        if (target == 3) {
            say(ADVICE[advice]); advice = (advice + 1) % ADVICE.length;
        } else if (target >= 0) buy(target, player, session);
    }
    public boolean buy(int index, Player player, CombatSession session) {
        if (!player.isAlive() || session.merchant != this || index < 0 || index >= 3
            || Vector2.dst(player.x + 30, player.y + 30, itemX(index), ITEM_Y) > 88) return false;
        MerchantItem item = items[index];
        if (item.sold) { say("На этом камне товар уже закончился."); return false; }
        if (!item.available(player)) { say("Этот дар уже не поместится в твою шляпу."); return false; }
        int price = item.price(player, session.getDifficulty());
        if (!session.spendCoins(price)) { say("Монеты любят вес. Твоему кошельку пока легко."); return false; }
        item.sold = true;
        GameAudio.play(GameAudio.Cue.BUY);
        if (item.upgrade == MerchantItem.HEAL) {
            int before = player.getHp(); player.heal(MerchantItem.healing(player));
            say("Зелье куплено. Восстановлено ХП: " + (player.getHp() - before));
        } else {
            session.pickupReward = PlayerUpgrade.apply(player, item.upgrade);
            say("Куплено: " + session.pickupReward.title + ". " + session.pickupReward.change);
        }
        return true;
    }
    private void say(String text) { message = text; messageTimer = 7; talkTimer = 2.5f; }
    public String getMessage() { return messageTimer > 0 ? GameText.tr(message) : ""; }
    public float getAnimationTime() { return animationTime; }
    public void update(float delta) {
        animationTime += delta;
        messageTimer = Math.max(0, messageTimer - delta);
        talkTimer = Math.max(0, talkTimer - delta);
    }
}
