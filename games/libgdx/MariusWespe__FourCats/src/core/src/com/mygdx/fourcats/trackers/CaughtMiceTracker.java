package com.mygdx.fourcats.trackers;

import com.mygdx.fourcats.events.IMouseCaughtEventListener;
import com.mygdx.fourcats.events.MouseCaughtEvent;

public class CaughtMiceTracker implements IMouseCaughtEventListener
{
    int caughtMice;

    public CaughtMiceTracker()
    {
        caughtMice = 0;
    }
    @Override
    public void handleEvent(MouseCaughtEvent event)
    {
        caughtMice++;
    }

    public int getScore()
    {
        return caughtMice;
    }
}
