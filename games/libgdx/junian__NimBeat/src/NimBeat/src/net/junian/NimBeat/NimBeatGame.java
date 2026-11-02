package net.junian.NimBeat;

import com.badlogic.gdx.ApplicationListener;
import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.audio.Music;
import com.badlogic.gdx.audio.Sound;
import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.GL10;
import com.badlogic.gdx.graphics.OrthographicCamera;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.math.Rectangle;
import com.badlogic.gdx.math.Vector3;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.TimeUtils;
import java.util.Iterator;

public class NimBeatGame implements ApplicationListener {

    boolean misere = true;
    Texture dropImage;
    Texture playerWin;
    Texture compWin;
    Texture blockNormal;
    Sound clickSound;
    Music bgmMusic;
    SpriteBatch batch;
    OrthographicCamera camera;
    Array<Rectangle> raindrops;
    long lastDropTime;
    Array< Array<Rectangle>> piles;
    Array<Rectangle> selectedPile = new Array<Rectangle>();
    Array<Rectangle> selectedIndex;
    boolean yourTurn = true;
    boolean isGameEnd = false;
    boolean gameReady = true;
    long playerStartWaitTime = 0;
    boolean aiAlreadyChose = false;
    long aiStartWaitTime = 0;

    @Override
    public void create() {
        dropImage = new Texture(Gdx.files.internal("droplet.png"));
        blockNormal = new Texture(Gdx.files.internal("block_normal.png"));
        playerWin = new Texture(Gdx.files.internal("playerwin.jpg"));
        compWin = new Texture(Gdx.files.internal("compwin.jpg"));

        clickSound = Gdx.audio.newSound(Gdx.files.internal("drop.wav"));
        bgmMusic = Gdx.audio.newMusic(Gdx.files.internal("nimgame-bgm.ogg"));

        //bgmMusic.setVolume(0.5f);
        bgmMusic.setLooping(true);
        bgmMusic.play();

        camera = new OrthographicCamera();
        camera.setToOrtho(false, 800, 480);

        batch = new SpriteBatch();

        raindrops = new Array<Rectangle>();
        spawnRaindrop();
        initBlocks();
    }

    private void initBlocks() {
        int indexNum = MathUtils.random(1, 8);
        piles = new Array< Array<Rectangle>>();
        for (int i = 0; i < indexNum; i++) {
            Array<Rectangle> pilesRandom = new Array<Rectangle>();
            int blockNum = MathUtils.random(1, 10);
            int xCoord = 800 / 2 - (indexNum * 64 + (indexNum - 1) * 32) / 2 + i * 64 + i * 32;
            for (int j = 0; j < blockNum; j++) {
                Rectangle b = createBlock();
                b.x = xCoord;
                b.y = 8 + j * 44;
                pilesRandom.add(b);
            }
            piles.add(pilesRandom);
        }
        yourTurn = true;
    }

    private Rectangle createBlock() {
        Rectangle block = new Rectangle();
        block.width = 64;
        block.height = 64;
        return block;
    }

    private void spawnRaindrop() {
        // TODO Auto-generated method stub
        Rectangle raindrop = new Rectangle();
        raindrop.x = MathUtils.random(0, 800 - 32);
        raindrop.y = 480;
        raindrop.width = 32;
        raindrop.height = 32;
        raindrops.add(raindrop);
        lastDropTime = TimeUtils.nanoTime();
    }

    /**
     * hapusssss
     */
    @Override
    public void dispose() {
        dropImage.dispose();
        clickSound.dispose();
        bgmMusic.dispose();
        batch.dispose();
        blockNormal.dispose();
        playerWin.dispose();
        compWin.dispose();
    }

    @Override
    public void render() {
        Gdx.gl.glClearColor(1.0f, 1.0f, 1.0f, 1);
        Gdx.gl.glClear(GL10.GL_COLOR_BUFFER_BIT);

        camera.update();

        batch.setProjectionMatrix(camera.combined);
        batch.begin();
        batch.setColor(Color.WHITE);
        if (isGameEnd) {
            Texture winTexture = null;
            if ((misere && yourTurn) || (!misere && !yourTurn)) {
                //System.out.println("Player 1 menang");
                winTexture = playerWin;
            } else {
                winTexture = compWin;
                //System.out.println("Player 2 menang");
            }
            batch.draw(winTexture, 800 / 2 - winTexture.getWidth() / 2, 480 / 2 - winTexture.getHeight() / 2);
        }

        for (Rectangle raindrop : raindrops) {
            batch.draw(dropImage, raindrop.x, raindrop.y);
        }

        for (Array<Rectangle> arr : piles) {
            for (Rectangle r : arr) {
                batch.draw(blockNormal, r.x, r.y);
            }
        }

        if (yourTurn) {
            batch.setColor(Color.PINK);
        } else {
            batch.setColor(Color.CYAN);
        }

        for (Rectangle r : selectedPile) {
            batch.draw(blockNormal, r.x, r.y);
        }

        batch.end();

        isGameEnd = true;
        for (Array<Rectangle> arr : piles) {
            //size = jumlah pile
            isGameEnd = (arr.size == 0) & isGameEnd;
        }

        if (Gdx.input.isTouched()) {
            if (!isGameEnd) {
                if (gameReady && yourTurn) {
                    //System.out.println(TimeUtils.nanoTime());
                    Vector3 touchPos = new Vector3();
                    touchPos.set(Gdx.input.getX(), Gdx.input.getY(), 0);
                    camera.unproject(touchPos);

                    boolean isSelected = false;
                    for (Array<Rectangle> arr : piles) {
                        for (int j = arr.size - 1; j >= 0; j--) {
                            if (arr.get(j).contains(touchPos.x, touchPos.y)) {
                                selectedPile = new Array<Rectangle>();
                                selectedIndex = arr;
                                for (int k = j; k < arr.size; k++) {
                                    selectedPile.add(arr.get(k));
                                    isSelected = true;
                                }
                                break;
                            }
                        }
                        if (isSelected) {
                            break;
                        }
                    }
                    if (!isSelected) {
                        selectedPile.clear();
                    }
                } else if (!gameReady && (TimeUtils.nanoTime() - playerStartWaitTime) > 250000000L) {
                    gameReady = true;
                }
            } else {
                initBlocks();
                gameReady = false;
                playerStartWaitTime = TimeUtils.nanoTime();
            }
        } else if (yourTurn && selectedPile.size > 0 && !isGameEnd) {
            //System.out.println("aaaa");
            for (Rectangle r : selectedPile) {
                selectedIndex.removeValue(r, false);
            }
            selectedPile.clear();
            clickSound.play();
            yourTurn = !yourTurn;
            aiAlreadyChose = false;
            aiStartWaitTime = TimeUtils.nanoTime();
        }
        if (!yourTurn && !isGameEnd) {
            if (!aiAlreadyChose && (TimeUtils.nanoTime() - aiStartWaitTime) > 250000000) {
                nimGameAiMisere();
                aiAlreadyChose = true;
                aiStartWaitTime = TimeUtils.nanoTime();
                //System.out.println(TimeUtils.nanoTime()-aiChoseTime);
            } else if (aiAlreadyChose && (TimeUtils.nanoTime() - aiStartWaitTime) > 600000000) {
                //System.out.println(TimeUtils.nanoTime()-aiChoseTime);
                for (Rectangle r : selectedPile) {
                    selectedIndex.removeValue(r, false);
                }
                selectedPile.clear();
                clickSound.play();
                yourTurn = !yourTurn;
                playerStartWaitTime = TimeUtils.nanoTime();
                gameReady = false;
            }
        }

        if (TimeUtils.nanoTime() - lastDropTime > 1000000000) {
            spawnRaindrop();
        }

        Iterator<Rectangle> iter = raindrops.iterator();
        while (iter.hasNext()) {
            Rectangle raindrop = iter.next();
            raindrop.y -= 200 * Gdx.graphics.getDeltaTime();
            if (raindrop.y + 32 < 0) {
                iter.remove();
            }
        }
    }

    private void nimGameAiMisere() {
        int xor = 0;

        for (Array<Rectangle> a : piles) {
            xor ^= a.size;
        }

        if (xor == 0) {
            for (Array<Rectangle> arr : piles) {
                if (arr.size > 0) {
                    selectedIndex = arr;
                    selectedPile.clear();
                    for (Rectangle rect : arr) {
                        selectedPile.add(rect);
                    }
                    //arr.clear();
                    break;
                }
            }
        } else {
            Array<Rectangle> chosenArr = null;
            for (Array<Rectangle> r : piles) {
                if ((r.size ^ xor) < r.size) {
                    chosenArr = r;
                    break;
                }
            }
            int pileSize = chosenArr.size - (chosenArr.size ^ xor);
            int twoMore = 0;
            for (Array<Rectangle> r : piles) {
                int n = (chosenArr == r) ? r.size - pileSize : r.size;
                if (n > 1) {
                    twoMore++;
                }
            }
            //kondisi endgame
            if (twoMore == 0) {
                int idmax = 0;
                int maxi = piles.get(0).size;
                for (int i = 1; i < piles.size; i++) {
                    if (piles.get(i).size > maxi) {
                        idmax = i;
                        maxi = piles.get(i).size;
                    }
                }
                chosenArr = piles.get(idmax);
                int heapOne = 0;
                for (Array<Rectangle> r : piles) {
                    if (r.size == 1) {
                        heapOne++;
                    }
                }

                pileSize = ((heapOne % 2 == 0) == misere) ? chosenArr.size - 1 : chosenArr.size;
            }
            selectedIndex = chosenArr;
            selectedPile.clear();
            while (pileSize > 0) {
                selectedPile.add(chosenArr.get(chosenArr.size - pileSize));
                //chosenArr.removeIndex(chosenArr.size - pileSize);
                pileSize--;
            }
        }
    }

    @Override
    public void resize(int width, int height) {
    }

    @Override
    public void pause() {
    }

    @Override
    public void resume() {
    }
}
