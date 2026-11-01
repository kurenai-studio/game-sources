package com.dev.cariri.hitball.objects;

import com.dev.cariri.hitball.Globals;

import java.util.ArrayList;

/**
 * Created by Ronildo on 27/02/2018.
 */

public class VidasFactory {

    private static ArrayList<Vida> colecaoVidas;

    public VidasFactory() {
        colecaoVidas = new ArrayList<Vida>();
    }

    public static ArrayList<Vida> createVidas() {

        Vida vida1 = new Vida();
        vida1.setXY(0, Globals.VIRTUAL_H - 32);

        Vida vida2 = new Vida();
        vida2.setXY(32, Globals.VIRTUAL_H - 32);

        Vida vida3 = new Vida();
        vida3.setXY(64, Globals.VIRTUAL_H - 32);

        colecaoVidas.add(vida1);
        colecaoVidas.add(vida2);
        colecaoVidas.add(vida3);

        return colecaoVidas;
    }
}
