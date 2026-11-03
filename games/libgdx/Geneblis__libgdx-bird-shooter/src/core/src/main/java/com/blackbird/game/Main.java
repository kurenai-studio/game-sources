package com.blackbird.game;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import com.badlogic.gdx.ApplicationAdapter;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.utils.ScreenUtils;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.graphics.g2d.Sprite;

@SuppressWarnings("unused")
public class Main extends ApplicationAdapter {
    private SpriteBatch batch;
    private Player player;
    private Controles controles;
    private List<Bala> balas;
    private List<Enemy> enemies;
    private int score; // Variável para armazenar a pontuação do jogador
    private boolean gameOver; // Flag para verificar se o jogo acabou
    private BitmapFont font; // Fonte para exibir "Game Over"
    private Random aleatorizador;
    private int posicaoinimiga;

    @Override
    public void create() {
        aleatorizador = new Random();
        batch = new SpriteBatch();
        balas = new ArrayList<>();
        enemies = new ArrayList<>();
        score = 0; // Inicializa a pontuação
        gameOver = false; // Inicializa a flag de Game Over

        // Inicializa a fonte
        font = new BitmapFont(); // Você pode personalizar a fonte se necessário

        // Spawn inicial de inimigos
        spawnEnemies(1, 0, Gdx.graphics.getHeight() / 2); // Spawn no canto esquerdo

        // player settings
        player = new Player();
        player.definirPosicao(550, 384);
        controles = new Controles(player, this);
    }

    private void aleatorizadorDePosicao() {
        // Gera uma posição aleatória dentro dos limites da tela
        float x = aleatorizador.nextInt(Gdx.graphics.getWidth() - 50);
        float y = aleatorizador.nextInt(Gdx.graphics.getHeight() - 50);
        spawnEnemies(1, x, y);
    }


    @Override
    public void render() {
        ScreenUtils.clear(0.15f, 0.15f, 0.2f, 1f);
        batch.begin();

        if (gameOver) {
            // Exibe a tela de Game Over
            font.draw(batch, "GAME OVER! Pressione espaço para reiniciar.", 550, Gdx.graphics.getHeight() / 2 + 30);
            font.draw(batch, "Sua pontuação total foi:", 550, Gdx.graphics.getHeight() / 2);
            font.draw(batch, String.valueOf(score), 550, Gdx.graphics.getHeight() / 2 - 30); 
            if (Gdx.input.isTouched() || Gdx.input.isKeyPressed(com.badlogic.gdx.Input.Keys.SPACE)) {
                restartGame(); // Reinicia o jogo
            }
        } else {
            player.update();
            player.draw(batch);
            controles.update();

            // Atualiza e desenha balas
            for (int i = 0; i < balas.size(); i++) {
                Bala bala = balas.get(i);
                bala.update();
                if (!bala.check(Gdx.graphics.getWidth(), Gdx.graphics.getHeight())) {
                    balas.remove(i);
                    i--;
                } else {
                    bala.draw(batch);
                }
            }

            // Atualiza e desenha inimigos
            for (int i = 0; i < enemies.size(); i++) {
                Enemy enemy = enemies.get(i);
                enemy.update(player); // Passa o jogador para o inimigo
                enemy.draw(batch);

                // Verifica colisão com balas
                for (int j = 0; j < balas.size(); j++) {
                    if (enemy.checkCollision(balas.get(j))) {
                        enemy.hit(this);
                        balas.remove(j);
                        j--;
                        aleatorizadorDePosicao();
                        break;
                    }
                }
                // Verifica colisão com o jogador
                if (enemy.checkPlayerCollision(player)) {
                    gameOver = true; // Define a flag de Game Over
                }

                // Remove inimigos mortos
                if (!enemy.isAlive()) {
                    enemies.remove(i);
                    i--;
                }
            }
        }

        batch.end();
    }

    public void atirar() {
        float offset = 5;
        float angle = player.getAngle();
        balas.add(Bala.atirar(player.getX(), player.getY(), angle, offset, 20, 10));
    }

    public void spawnEnemies(int count, float x, float y) {
        for (int i = 0; i < count; i++) {
            enemies.add(new Enemy(x, y, this)); // Passa a referência da classe Main
        }
    }

    public void addScore(int points) {
        score += points; // Atualiza a pontuação
        System.out.println("Pontuação: " + score); // Exibe a pontuação no console
    }

    public void restartGame() {
        score = 0; // Reinicia a pontuação
        gameOver = false; // Reseta a flag de Game Over
        balas.clear(); // Limpa as balas
        enemies.clear(); // Limpa os inimigos
        spawnEnemies(1, 0, Gdx.graphics.getHeight() / 2);
        player.definirPosicao(683, 384); // Reseta a posição do player
    }

    @Override
    public void dispose() {
        batch.dispose();
        player.dispose();
        for (Bala bala : balas) {
            bala.dispose();
        }
        balas.clear();
        for (Enemy enemy : enemies) {
            enemy.dispose();
        }
        enemies.clear();
        font.dispose();
    }
}