package com.devcariri.submax.algorithm;

import com.devcariri.submax.objects.Quadro;

import java.util.ArrayList;

/**
 * Created by RoNigga on 31/01/2017.
 */

public class SubConsecMax {

    /**Retorna maior elemento da lista **/
    public static int maxElem(ArrayList<Quadro> list){
        int sumMax = Integer.MIN_VALUE;

        for (Quadro quadro : list) {
            if (sumMax < quadro.getValor()) {
                sumMax = quadro.getValor();
            }
        }
        return sumMax;
    }

    /**Retorna subsequencia consecutiva máxima **/
    public static int getSubConMax(ArrayList<Quadro> list){
        int maxAtual = 0;
        int maxUltimo = 0;

        int tamanhoLista = list.size() + 1;

        for (int i = 1; i < tamanhoLista; i++) {
            maxUltimo = Math.max(0, maxUltimo + list.get(i-1).getValor());
            maxAtual = Math.max(maxAtual, maxUltimo);
        }

        if (maxAtual == 0){
            return maxElem(list);
        }
        return maxAtual;
    }
}
