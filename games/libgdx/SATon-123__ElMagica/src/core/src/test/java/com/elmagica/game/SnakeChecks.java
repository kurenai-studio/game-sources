package com.elmagica.game;

public class SnakeChecks {
    public static void run() {
        for (ElementType element : DamageSystem.ENEMY_ELEMENTS) {
            Enemy snake = Enemy.snake(element, 7, 6);
            Player player = new Player(ElementType.FIRE);
            player.x = snake.x + 200; player.y = snake.y;
            snake.update(0, player);
            require(snake.snakeCombat.isCharging() && player.getHp() == 20, "Charge starts without contact damage");
            snake.update(0.49f, player);
            require(!snake.snakeCombat.isDashing() && player.getHp() == 20, "Full warning before rush");
            snake.update(0.02f, player);
            require(snake.snakeCombat.isDashing(), "Rush starts after warning");
            snake.update(1, player);
            int hp = 20 - snake.attackDamage(element, player.element);
            require(player.getHp() == hp && snake.snakeCombat.isRecovering(), "Swept rush hits once by element");
            require(Math.abs(player.hurtX() - snake.x - snake.getSize() / 2 - Player.HURT_RADIUS - snake.getSize() / 2) < 0.01f, "Rush stops at circular player body");
            snake.update(0.5f, player);
            require(player.getHp() == hp, "Recovery cannot deal repeated damage");
            snake.update(0.8f, player);
            snake.update(0, player);
            require(snake.snakeCombat.isCharging(), "Snake can charge again after recovery");
            snake.takeDamage(20);
            require(!snake.snakeCombat.isCharging() && !snake.snakeCombat.isDashing(), "Death cancels rush");
            snake.reset();
            require(snake.getHp() == 20 && !snake.snakeCombat.isRecovering(), "Snake reset");
        }
        Enemy snake = Enemy.snake(ElementType.WATER, 7, 6);
        Player player = new Player(ElementType.FIRE);
        player.x = snake.x + 200; player.y = snake.y;
        snake.update(0, player);
        player.y += 120;
        snake.update(0.51f, player);
        snake.update(1, player);
        require(player.getHp() == 20, "Locked rush can be dodged sideways");
        require(snake.x >= 64 && snake.x + snake.getSize() <= 1216, "Rush stays inside walls");
        snake.reset(); snake.x = ElMagicaGame.WORLD_WIDTH - 180; snake.y = ElMagicaGame.WORLD_HEIGHT - 200;
        player.x = ElMagicaGame.WORLD_WIDTH - 124; player.y = ElMagicaGame.WORLD_HEIGHT - 124;
        snake.update(0, player);
        player.x = 64; player.y = 64;
        snake.update(0.51f, player);
        snake.update(1, player);
        require(snake.snakeCombat.isRecovering() && snake.x + snake.getSize() <= ElMagicaGame.WORLD_WIDTH - 64
            && snake.y + snake.getSize() <= ElMagicaGame.WORLD_HEIGHT - 64, "Wall stops dash and starts recovery");
        snake.reset(); snake.x = 322; snake.y = 322;
        player.x = 1000; player.y = 322;
        snake.update(0.5f, player);
        require(Math.abs(snake.x - 372) < 0.01f, "Snake approaches at 100 pixels per second");
        float x = snake.x;
        player.takeDamage(20);
        snake.update(1, player);
        require(snake.x == x, "Snake freezes after player death");
        System.out.println("Snake checks passed: four elements, warning, swept collision, dodge, recovery and walls");
    }

    private static void require(boolean condition, String message) { if (!condition) throw new AssertionError(message); }
}
