package com.devcariri.submax.phases;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.utils.Json;
import com.devcariri.submax.Assets;

import java.util.ArrayList;

/**
 * Created by ronildo.oliveira on 3/20/2017.
 */

public class JsonToFase {

    private ArrayList<Fase> fases;
    private Json json;

    public JsonToFase(){
        json = new Json();
        fases = Assets.FASES;
    }

    public ArrayList<Fase> getFases() {

        for (Fase f:fases) {
            Gdx.app.log("FASE",f.getName());
            for (Slot s: f.getSlots()){
                Gdx.app.log("SLT","("+s.getX()+","+s.getY()+")");
            }
        }

        return  fases;
    }

}