package com.devcariri.submax.objects;

import com.badlogic.gdx.Gdx;
import com.devcariri.submax.Globals;
import com.devcariri.submax.phases.Fase;
import com.devcariri.submax.phases.JsonToFase;
import com.devcariri.submax.phases.Slot;

import java.util.ArrayList;
import java.util.Random;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class QuadrosFactory {

    public QuadrosFactory(){ }

    public static ArrayList<Quadro> createOrb() {

        ArrayList<Quadro> colecaoQuadros;
        colecaoQuadros = new ArrayList<Quadro>();
        Quadro quadro;

        JsonToFase jsonToFase = new JsonToFase();

        /** Funcoes de carregamento de fases **/
        int l = 0;
        int c = 0;
        int mat[][] = new int[Globals.QUD_TILE_W][Globals.QUD_TILE_H];

        ArrayList<Fase>listaFases = jsonToFase.getFases();
        Random r = new Random();
            for (Slot s:jsonToFase.getFases().get(r.nextInt(listaFases.size())).getSlots()) {
                //Gdx.app.log(".","("+s.getX()+","+s.getY()+")\n");
                mat[s.getX()][s.getY()] = 1;
                Gdx.app.log("ALIGN",Globals.ALIGN_Y+"\n");
                Gdx.app.log("VIRTUAL H",Globals.VIRTUAL_H+"\n");
                Gdx.app.log("VIRTUAL H",Globals.LIM_H+"\n");
            }

        /**
        for (int i =0; i< Globals.QUD_TILE_W; i++){
            for (int j =0; j< Globals.QUD_TILE_H; j++){
                if(j == i){
                    mat[i][j] = 1;
                }else{
                    mat[i][j] = 0;
                }
            }
        }
         **/
        //i coluna
        //j linha

        float offset = Globals.TILE_SIZE/2;
        /** Funcoes de carregamento de fases **/
        /** Canto esquerdo inferior , percorre cada linha para a direita**/
        for (float y = Globals.ALIGN_Y+offset; y < Globals.ALIGN_Y + Globals.LIM_H; y+=(Globals.TILE_SIZE+Globals.OFFSET_TILE)){
            c = 0;
            for (float x = Globals.OFFSET_TILE; x < Globals.LIM_W; x+=(Globals.TILE_SIZE+Globals.OFFSET_TILE)) {

                if(mat[c][l] == 1) {
                    quadro = new Quadro();
                    quadro.setXY(x, y);
                    Gdx.app.log("displayed at:","("+x+","+y+")");
                    colecaoQuadros.add(quadro);
                }

                c++;
            }
            l++;
        }

        return colecaoQuadros;
    }
}
