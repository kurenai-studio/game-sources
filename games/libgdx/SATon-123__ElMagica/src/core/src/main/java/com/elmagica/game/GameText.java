package com.elmagica.game;

import java.util.Arrays;
import java.util.Comparator;

public class GameText {
    public static boolean english;
    // Сначала переводим строку, потом считаем её ширину.
    private static final String DATA = """
Стартовый урон мага|Starting spell damage
Две стихии. База: 180 ХП|Two elements. Base: 180 HP
С этажами босс становится сильнее.|Bosses grow stronger on higher floors.
Врагов больше, но появляются частями.|More enemies, arriving in batches.
Всё выше|Climb higher
Вход снизу, выход сверху.|Enter below, leave through the top.
Победи всех — верхняя дверь откроется.|Defeat everyone to open the exit.
Убил одного — приходит следующий.|A kill frees a slot for the next enemy.
Запас: +1 враг каждые 3 этажа.|Enemy budget: +1 every 3 floors.
На экране: +1 каждые 10 этажей.|Active limit: +1 every 10 floors.
ХП, урон и темп врагов растут.|Enemy health, damage and pace grow.
Каждый 7-й этаж — босс без укрытий.|Every 7th floor: boss, no obstacles.
После зачистки скорость мага x1,8.|After clearing, movement speed x1.8.
Весь оставшийся лут летит к магу.|Remaining loot flies to the mage.
Находки и усиления|Loot and upgrades
Монеты: 50% — 1, 25% — 3, 25% — 0.|Coins: 50% one, 25% three, 25% none.
С босса всегда падает 10-20 монет.|Bosses always drop 10-20 coins.
Книга даёт случайное улучшение.|Books grant a random upgrade.
Зелье лечит; при полных ХП исчезает.|Potions are consumed even at full HP.
Босс даёт ап и полное лечение.|Boss victory: upgrade and full heal.
Растут скорость, урон, ХП или атака.|Improve speed, damage, HP or shooting.
Редко: способность или уклонение.|Rare rewards: ability or dodge.
Красный урон сильный, серый слабый.|Red damage is strong; gray is weak.
Белый обычный; зелёный — лечение.|White is normal; green is healing.
Передышка в башне|A break in the tower
Появляется только после 1-го босса.|Appears only after the first boss.
Один случайный этаж между боссами.|One random floor between bosses.
В 5% промежутков — два визита.|5% of intervals have two visits.
Два торговца никогда не идут подряд.|Merchant floors are never consecutive.
Здесь нет врагов, выход уже открыт.|No enemies here; the exit is open.
Можно уйти без покупок.|You can leave without buying.
Подойди к торговцу и нажми E.|Approach the merchant and press E.
Он поделится сомнительным советом.|He will share some dubious advice.
Три товара|Three items
Подойди к пьедесталу и нажми E.|Approach a pedestal and press E.
Каждый товар покупается один раз.|Each item can be bought only once.
Обычно: два улучшения и зелье.|Usually: two upgrades and a potion.
Иногда вместо зелья — третий ап.|Sometimes: three upgrades, no potion.
Редко: ап способности или щит.|Rare stock: an ability or shield card.
Щит повышает шанс уклониться.|The shield improves your dodge chance.
Чем выше стат, тем дороже его ап.|Upgrades cost more as the stat grows.
Цена зелья зависит от ХП и сложности.|Potion price scales with HP/difficulty.
Башня|Tower
Назад|Back
Ехала дальше|Keep going
Ехала|Let's go
Управление|Controls
Механики|Mechanics
Настройки|Settings
Музыка: |Music: 
Звуки: |Sound effects: 
Закрыть игру|Quit game
Главное меню|Main menu
Меню|Menu
Продолжить|Resume
Закончить сессию|End run
Закончить|End run
Сдался или устал?|Giving up or tired?
Прогресс этого захода будет потерян|This run's progress will be lost
Потрачено|Wasted
Новый заход — новый шанс|New run — new chance
Пройдено этажей: |Floors cleared: 
Этаж пройден. Выход наверху|Floor cleared. Exit above
Этаж с торговцем, проход открыт|Merchant floor, exit open
Этаж |Floor 
Монеты: |Coins: 
Арена стихий|Elemental arena
Выбери мага|Choose your mage
Один класс — четыре стихии|One class — four elements
20 ХП  /  2 выстрела в секунду  /  200 пикс/с|20 HP  /  2 shots per second  /  200 px/s
Нажми на карточку или выбери клавишей 1-4|Click a card or press 1-4
Взрыв при попадании|Explodes on impact
Задевает врагов рядом|Hits nearby enemies
Пробивает две цели|Pierces two targets
Лови врагов в линию|Line enemies up
Толкает и замедляет|Pushes and slows
Держи врагов подальше|Keep enemies away
Рикошет в соседа|Bounces to a neighbour
До двух целей за раз|Up to two targets
Параметры персонажа|Character stats
Включены|Enabled
Выключены|Disabled
ХП-бар над магом виден всегда|Mage's health bar is always visible
Размер ХУДа: |HUD size: 
Язык: Русский|Language: English
Персонаж|Character
Стихия: |Element: 
ХП: |HP: 
Скорость: |Speed: 
Стрельба: |Fire rate: 
КД стрельбы: |Shot cooldown: 
Пройдено: |Cleared: 
Урон: |Damage: 
Снаряд: |Projectile: 
Уклонение: |Dodge: 
Сложность: |Difficulty: 
Торговец|Merchant
Продано|Sold
 монет| coins
Подойди к товару или торговцу и нажми E|Approach an item or the merchant and press E
E — поговорить с торговцем|E — talk to the merchant
E — купить за |E — buy for 
Этот параметр уже на пределе|This stat is already at its limit
Улучшение способности|Ability upgrade
Магический щит|Magic shield
Зелье лечения|Healing potion
Базовый урон|Base damage
Максимум ХП|Max HP
КД атаки|Shot cooldown
Скорость снаряда|Projectile speed
Скорость движения|Move speed
Скорость|Speed
+10% к скорости|+10% move speed
+15% к базовому урону|+15% base damage
+4 максимальных ХП|+4 max HP
КД атаки меньше на 10%|10% shorter shot cooldown
Снаряды быстрее на 12%|12% faster projectiles
+12 к радиусу взрыва|+12 blast radius
+1 цель пробития|+1 pierced target
+1 рикошет|+1 bounce
Отбрасывание и замедление|Knockback and slow
+3% к шансу уклонения|+3% dodge chance
Здоровье уже полное|Health is already full
Книга заклинаний|Spellbook
Босс повержен|Boss defeated
Редкое улучшение|Rare upgrade
Маг стал сильнее|Mage grew stronger
Здоровье полностью восстановлено|Health fully restored
Враги станут сильнее|Enemies will grow stronger
Перезарядка атаки|Shot cooldown
Радиус взрыва|Blast radius
Целей за выстрел|Targets per shot
Количество рикошетов|Bounce count
Сила земли|Earth power
Шанс уклонения|Dodge chance
Уклонение|Dodged
 пикс / замедление | px / slow 
 выстр/с| shots/s
 пикс/с| px/s
 пикс| px
 ХП| HP
 с| s
Огонь|Fire
Вода|Water
Земля|Earth
Воздух|Air
Стрелок: |Shooter: 
Змея: |Snake: 
Паровой Чан|Steam Cauldron
Лавовый Голем|Lava Golem
Огненный Вихрь|Firestorm
Болотный Страж|Swamp Guardian
Штормовой Дух|Storm Spirit
Песчаный Титан|Sand Titan
Камень не уступает дорогу. Уступи ему сам.|Stone never steps aside. Perhaps you should.
У быстрых ног истории обычно длиннее.|Quick feet tend to have longer stories.
Вода помнит, куда торопился огонь.|Water remembers where fire was rushing.
Красная склянка не знает цену твоей гордости.|A red bottle knows nothing of your pride.
Когда лестница молчит, послушай комнату.|When the stairs fall silent, listen to the room.
Тот, кто смотрит только на врага, встретит стену.|Watch only your enemy and you will meet a wall.
Большой кошелёк не делает шляпу крепче.|A heavy purse does not make a tougher hat.
Чем выше башня, тем дороже привычки.|The higher the tower, the dearer your habits.
Иногда шаг в сторону полезнее красивого выстрела.|Sometimes a sidestep beats a splendid shot.
Пустой пьедестал редко становится полным дважды.|An empty pedestal rarely fills up twice.
Книга на полу ещё никого сама не подняла.|A book on the floor never picked itself up.
У семёрки тяжёлые шаги. Ты их услышишь.|Seven has heavy footsteps. You will hear them.
На этом камне товар уже закончился.|This stone has nothing left to offer.
Этот дар уже не поместится в твою шляпу.|There is no room for this gift in your hat.
Монеты любят вес. Твоему кошельку пока легко.|Coins favour weight. Your purse is still light.
Зелье куплено. Восстановлено ХП: |Potion bought. HP restored: 
Куплено: |Bought: 
Курсор|Cursor
ЛКМ|LMB
Мышь|Mouse
Движение мага|Move the mage
Направление заклинания|Aim your spell
Удерживать для автоатаки|Hold for automatic fire
Выбор стихии после старта|Choose element after starting
Меню паузы или назад|Pause menu or back
Кнопки и карточки меню|Menu buttons and cards
Купить товар или поговорить|Buy an item or talk
Вначале 2 выстрела в секунду. Улучшения ускоряют атаку.|Start at 2 shots per second. Upgrades boost fire rate.
Стихии|Elements
Заклинания|Spells
Враги|Enemies
Боссы|Bosses
Круг|Element
стихий|cycle
Кто кого бьёт|Who beats whom
По стрелке — сильный удар.|With the arrow — strong hit.
Против стрелки — слабый.|Against the arrow — weak hit.
Твои попадания|Your hits
Сильное: 20 урона|Strong: 20 damage
Нейтральное: 10 урона|Neutral: 10 damage
Слабое: 5 урона|Weak: 5 damage
По магу: урон зависит от врага.|Mage damage depends on the enemy.
Та же стихия и стихия напротив:|Same and opposite elements:
обычный удар. У босса два типа.|Neutral hit. Bosses have two types.
Взрывается при попадании.|Explodes on impact.
Задевает врагов рядом с целью.|Hits enemies near the target.
Хорош против толпы.|Good against crowds.
Проходит сквозь первого врага.|Passes through the first enemy.
Может задеть ещё одного за ним.|Can hit another enemy behind it.
Выстраивай врагов в линию.|Line your enemies up.
Отталкивает и ненадолго замедляет.|Pushes enemies back and slows them.
Помогает держать врагов подальше.|Helps keep enemies away.
Босса отталкивает слабее.|Bosses resist the knockback.
Перескакивает на соседнего врага.|Bounces to a nearby enemy.
Один выстрел — до двух целей.|One shot — up to two targets.
Хорош против врагов рядом.|Good against clustered enemies.
Слизни|Slimes
Змеи|Snakes
Стрелки|Shooters
30 ХП. Базовый урон: 2.|30 HP. Base damage: 2.
20 ХП. Базовый урон: 3.|20 HP. Base damage: 3.
12 ХП. Базовый урон: 4.|12 HP. Base damage: 4.
Кусают и отпрыгивают. Живучие.|Bite and jump back. Tough.
Атакуют рывком без линии-подсказки.|Dash attacks with no aim line.
После рывка змея ненадолго замирает.|Pause briefly after a dash.
Сильная стихия: урон x1,5.|Strong element: damage x1.5.
Слабая стихия: урон x0,5.|Weak element: damage x0.5.
Хрупкие, но больно стреляют.|Fragile, but their shots hurt.
Целятся молча, потом выпускают болт.|Aim silently, then fire a bolt.
Урон округляется до целого.|Damage rounds to a whole number.
Появление врагов|Enemy spawns
Этажи: 3-5 врагов, затем 4-6.|Floors: 3-5 enemies, then 4-6.
Число врагов растёт с этажами.|Enemy counts grow with floors.
Убил врага — приходит следующий.|Kill an enemy — another arrives.
Спавн не ближе двух клеток от мага.|Spawn at least two tiles away.
Препятствия не пропускают тела и пули.|Obstacles block bodies and shots.
Редко выпадает книга или зелье.|Rare drops: spellbooks or potions.
Подойди к предмету, чтобы подобрать.|Walk over an item to pick it up.
Две стихии, 180 ХП|Two elements, 180 HP
Каждый седьмой этаж — один босс.|One boss on every seventh floor.
Победа: улучшение и полное лечение.|Win: an upgrade and full healing.
Твой урон по двум стихиям|Damage against two elements
Сильный + обычный: 20|Strong + neutral: 20
Два обычных: 10|Two neutral: 10
Сильный + слабый: 10|Strong + weak: 10
Обычный + слабый: 5|Neutral + weak: 5
Базовый урон босса: 5|Boss base damage: 5
Касание: 8 / 5 / 3 по двум стихиям.|Touch: 8 / 5 / 3 by both elements.
ХП и урон врагов растут после босса.|Enemy HP and damage grow after bosses.
Атаки обеих стихий|Both elements attack
Земля: две волны на 4-5 клеток.|Earth: two waves over 4-5 tiles.
Вода: три залпа, в каждом три струи.|Water: three salvos of three jets.
Огонь: широкий конус с разворотом.|Fire: a wide sweeping cone.
Воздух: 12 быстрых встречных спиралей.|Air: 12 fast counter-spinning spirals.
На половине ХП — ярость|Enraged at half HP
Атаки быстрее. Выходи из зоны удара.|Faster attacks. Leave the danger zone.
За победу растёт случайный стат мага.|Victory boosts a random mage stat.
Редко: сильнее абилка или уклонение.|Rarely: ability or dodge upgrades.
Босс ускоряется, если ты далеко.|Bosses speed up when you are far away.
Древние руины|Ancient ruins
Заросший храм|Overgrown temple
Вулкан|Volcano
Ледяной склеп|Frozen crypt
""";
    private static final String[][] TRANSLATIONS = loadTranslations();
    private static String[][] loadTranslations() {
        String[] lines = DATA.split("\n");
        String[][] translations = new String[lines.length][];
        for (int i = 0; i < lines.length; i++) translations[i] = lines[i].split("\\|", -1);
        return translations;
    }
    static {
        // Возвращаем пробелы на концах переводов: text block их обрезает.
        for (String[] pair : TRANSLATIONS) if (pair[0].endsWith(" ")) pair[1] += " ";
        Arrays.sort(TRANSLATIONS, Comparator.comparingInt((String[] pair) -> pair[0].length()).reversed());
    }
    public static String tr(String text) {
        if (!english) return text;
        String result = text;
        for (String[] pair : TRANSLATIONS) result = result.replace(pair[0], pair[1]);
        return result.replaceAll("(\\d),(\\d)", "$1.$2");
    }
}
