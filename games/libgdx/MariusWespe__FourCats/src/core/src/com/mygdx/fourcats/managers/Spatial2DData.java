package com.mygdx.fourcats.managers;

import java.util.ArrayList;

public class Spatial2DData
{
    public Spatial2DData()
    {
        X = new ArrayList<>();
        Y = new ArrayList<>();
    }

    private final ArrayList<Integer> X;
    private final ArrayList<Integer> Y;

    public int getXByIndex(int index)
    {
        return X.get(index);
    }

    public int getYByIndex(int index)
    {
        return Y.get(index);
    }

    public void setXByIndex(int index, int value)
    {
        X.set(index, value);
    }

    public void setYByIndex(int index, int value)
    {
        Y.set(index, value);
    }

    public void removeMouseByIndex(int index)
    {
        X.remove(index);
        Y.remove(index);
    }

    public void addMouse(int posX, int posY)
    {
        this.X.add(posX);
        this.Y.add(posY);
    }

    public int size()
    {
        return this.X.size();
    }
}
