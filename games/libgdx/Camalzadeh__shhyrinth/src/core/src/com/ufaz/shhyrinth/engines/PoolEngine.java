package com.ufaz.shhyrinth.engines;

import com.badlogic.gdx.graphics.g2d.SpriteBatch;
import com.badlogic.gdx.utils.Array;
import com.ufaz.shhyrinth.entities.Player;
import com.ufaz.shhyrinth.entities.enemies.Enemy;
import com.ufaz.shhyrinth.entities.spells.Spell;
import space.earlygrey.shapedrawer.ShapeDrawer;

public class PoolEngine {

    public Array<Spell> spells;
    public Array<Enemy> enemies;

    public PoolEngine() {
        spells = new Array<>();
        enemies = new Array<>();
    }

    public void add(Spell spell) {
        spells.add(spell);
    }

    public void add(Enemy enemy) {
        enemies.add(enemy);
    }

    public void renderSpells(SpriteBatch batch, float delta) {
        for (Spell s : spells) {
            if (!s.isAlive) {
                s.reset();
                s.release();
                spells.removeValue(s, true);
                continue;
            }
            s.render(batch, delta);
        }

    }

    public void renderEnemies(SpriteBatch batch, ShapeDrawer shaper, float delta, Player player, Array<Spell> spells) {
        int underAttackCont = 0;
        for (Enemy e : enemies) {
            if (!e.isAlive) {
                e.reset();
                e.release();
                enemies.removeValue(e, true);
                continue;
            }
            e.render(batch, shaper, delta, player, spells);
            if (e.readyToAttack) {
                underAttackCont++;
            }
        }
        Player.underAttack = underAttackCont > 0;
    }

    public void clear() {
        spells.clear();
    }
}
